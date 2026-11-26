import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:api/api.dart';
import 'package:firebase_core/firebase_core.dart';

class PushNotificationService {
  static const String defaultAndroidChannelId = 'otlob_notifications_v2';
  static const String defaultAndroidChannelName = 'Otlob Notifications';
  static const String defaultAndroidChannelDescription =
      'Used for order updates, delivery requests, chat messages, and important alerts.';
  static const String _legacyAndroidChannelId = 'high_importance_channel';

  static const AndroidNotificationChannel defaultAndroidChannel =
      AndroidNotificationChannel(
    defaultAndroidChannelId,
    defaultAndroidChannelName,
    description: defaultAndroidChannelDescription,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.notification,
  );

  final FirebaseMessaging? _messagingOverride;
  final FlutterLocalNotificationsPlugin? _localNotificationsOverride;
  final Stream<RemoteMessage>? _onMessageOverride;
  final Stream<RemoteMessage>? _onMessageOpenedAppOverride;
  FlutterLocalNotificationsPlugin? _localNotificationsLazy;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _localNotifications =>
      _localNotificationsOverride ??
      (_localNotificationsLazy ??= FlutterLocalNotificationsPlugin());

  final DevicesPushNotificationsApi _devicesApi;
  final StreamController<RemoteMessage> _openedAppController =
      StreamController<RemoteMessage>.broadcast();
  bool _initialized = false;
  bool _tapListenersInitialized = false;
  bool _listenersInitialized = false;
  bool _topicsSubscribed = false;
  RemoteMessage? _pendingInitialLocalMessage;
  String? _registeredToken;
  String? _pendingTopicRole;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<bool>? _connectivitySub;

  PushNotificationService(
    this._devicesApi, {
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    Stream<RemoteMessage>? onMessageStream,
    Stream<RemoteMessage>? onMessageOpenedAppStream,
    Stream<bool>? connectivityChanges,
  })  : _messagingOverride = messaging,
        _localNotificationsOverride = localNotifications,
        _onMessageOverride = onMessageStream,
        _onMessageOpenedAppOverride = onMessageOpenedAppStream {
    if (connectivityChanges != null) {
      _connectivitySub = connectivityChanges.listen((isOnline) {
        if (isOnline && _initialized) {
          unawaited(ensureTokenRegistered());
        }
      });
    }
  }

  /// Attaches notification tap listeners (background onMessageOpenedApp and local
  /// notification launch payloads) early without prompting for OS permissions.
  Future<void> ensureTapListenersInitialized() async {
    if (_tapListenersInitialized) return;
    _tapListenersInitialized = true;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications
          .initialize(
            settings: initSettings,
            onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
          )
          .timeout(const Duration(seconds: 3));

      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (launchDetails?.didNotificationLaunchApp == true) {
        _pendingInitialLocalMessage ??=
            _decodeLocalPayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('FCM: Local notification tap setup warning: $e');
    }

    try {
      final openedStream =
          _onMessageOpenedAppOverride ?? FirebaseMessaging.onMessageOpenedApp;
      _openedAppSub ??= openedStream.listen((RemoteMessage message) {
        debugPrint('Message clicked! Routing to payload: ${message.data}');
        _openedAppController.add(message);
      });
    } catch (e) {
      debugPrint('FCM: onMessageOpenedApp listener warning: $e');
    }
  }

  Future<void> initialize() async {
    _initialized = true;
    try {
      // Request permission (iOS specifically, Android 13+)
      final settings = await _messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 5));

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted permission for push notifications');
      }
    } catch (e) {
      debugPrint('FCM: Permission request skipped or timed out: $e');
    }

    if (!kIsWeb && Platform.isIOS) {
      try {
        // Allow iOS to present APNs banners with sound natively in the foreground
        // so taps reliably route through FirebaseMessaging.onMessageOpenedApp.
        await _messaging
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            )
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('FCM: Failed to set iOS foreground presentation options: $e');
      }
    }

    await ensureTapListenersInitialized();

    if (!_listenersInitialized) {
      try {
        await _createAndroidNotificationChannel(_localNotifications);
      } catch (e) {
        debugPrint('FCM: Android notification channel warning: $e');
      }

      // Attach listeners before fetching token so delayed APNs registration
      // on iOS never prevents token refresh, registration, or topic subscription.
      _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        _topicsSubscribed = false;
        await _registerToken(newToken);
        final role = _pendingTopicRole;
        if (role != null) {
          await subscribeToRoleTopics(role);
        }
      });

      final msgStream = _onMessageOverride ?? FirebaseMessaging.onMessage;
      _foregroundMessageSub ??= msgStream.listen((RemoteMessage message) {
        debugPrint(
            'Received foreground message: ${message.notification?.title}');
        _handleRemoteMessage(message);
      });

      _listenersInitialized = true;
    }

    final token = await getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _registerToken(token);
    }
  }

  /// Retries FCM token registration and pending role topic subscription if a
  /// previous attempt failed or iOS APNs registration completed later.
  Future<void> ensureTokenRegistered({String? role}) async {
    if (role != null && role.trim().isNotEmpty) {
      _pendingTopicRole = role;
    }
    final token = await getToken(waitForApns: false);
    if (token != null && _registeredToken != token) {
      await _registerToken(token);
    }
    final pendingRole = _pendingTopicRole;
    if (pendingRole != null && !_topicsSubscribed) {
      await subscribeToRoleTopics(pendingRole);
    }
  }

  Stream<RemoteMessage> get onMessage =>
      _onMessageOverride ?? FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp => _openedAppController.stream;

  Future<RemoteMessage?> getInitialMessage() async {
    try {
      final fcmInitial = await _messaging.getInitialMessage();
      if (fcmInitial != null) return fcmInitial;
    } catch (e) {
      debugPrint('FCM: getInitialMessage warning: $e');
    }

    final pendingLocal = _pendingInitialLocalMessage;
    _pendingInitialLocalMessage = null;
    if (pendingLocal != null) return pendingLocal;

    try {
      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        return _decodeLocalPayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (_) {}
    return null;
  }

  void _handleLocalNotificationResponse(NotificationResponse response) {
    final message = _decodeLocalPayload(response.payload);
    if (message != null) {
      _openedAppController.add(message);
    }
  }

  RemoteMessage? _decodeLocalPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return RemoteMessage(data: decoded);
      }
      if (decoded is Map) {
        return RemoteMessage(
          data: decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (e) {
      debugPrint('Failed to decode local notification payload: $e');
    }
    return null;
  }

  Future<bool> _registerToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return false;
    try {
      final platform = kIsWeb
          ? RegisterDeviceDtoPlatformEnum.WEB
          : (Platform.isIOS
              ? RegisterDeviceDtoPlatformEnum.IOS
              : RegisterDeviceDtoPlatformEnum.ANDROID);

      final dto = RegisterDeviceDto((b) => b
        ..token = trimmed
        ..platform = platform);

      await _devicesApi
          .devicesControllerRegister(registerDeviceDto: dto)
          .timeout(const Duration(seconds: 5));
      _registeredToken = trimmed;
      debugPrint('FCM Token registered with backend successfully ($platform)');
      return true;
    } catch (e) {
      _registeredToken = null;
      debugPrint('Failed to register FCM token: $e');
      return false;
    }
  }

  Future<void> unregisterToken({
    String? token,
    bool waitForApns = true,
  }) async {
    try {
      final resolvedToken = token ?? await getToken(waitForApns: waitForApns);
      if (resolvedToken != null) {
        await _devicesApi
            .devicesControllerRemove(token: resolvedToken)
            .timeout(const Duration(seconds: 3));
        _registeredToken = null;
        debugPrint('FCM Token removed from backend successfully');
      }
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  void showLocalNotification({
    required String title,
    required String body,
    int? id,
    Map<String, dynamic>? data,
  }) {
    const androidDetails = AndroidNotificationDetails(
      defaultAndroidChannelId,
      defaultAndroidChannelName,
      channelDescription: defaultAndroidChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotifications.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
      payload: data != null && data.isNotEmpty ? jsonEncode(data) : null,
    );
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    // On iOS, foreground alert/badge/sound presentation is handled by APNs via
    // setForegroundNotificationPresentationOptions to prevent duplicate banners.
    if (!kIsWeb && Platform.isIOS) return;

    showLocalNotification(
      title: notification.title ?? '',
      body: notification.body ?? '',
      id: message.messageId?.hashCode ?? notification.hashCode,
      data: message.data,
    );
  }

  /// Subscribes the device to the global 'topic_all' and a role-specific topic.
  /// Allowed roles: 'CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN'.
  Future<void> subscribeToRoleTopics(String role) async {
    _pendingTopicRole = role;
    try {
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _messaging
            .getAPNSToken()
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
        if (apnsToken == null) {
          for (var i = 0; i < 2 && apnsToken == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            apnsToken = await _messaging
                .getAPNSToken()
                .timeout(const Duration(seconds: 2), onTimeout: () => null);
          }
        }
        if (apnsToken == null) {
          _topicsSubscribed = false;
          debugPrint(
            'FCM: APNs token not yet available on iOS; deferring topic subscription ($role) to token refresh.',
          );
          return;
        }
      }

      String? specificTopic;
      switch (role.toUpperCase()) {
        case 'CUSTOMER':
          specificTopic = 'topic_customers';
          break;
        case 'DRIVER':
          specificTopic = 'topic_drivers';
          break;
        case 'VENDOR':
        case 'VENDOR_MEMBER':
        case 'VENDOR_OWNER':
          specificTopic = 'topic_vendors';
          break;
        case 'ADMIN':
        case 'SUPER_ADMIN':
        case 'DRIVER_MANAGER':
          specificTopic = 'topic_admin'; // Optional: if backend ever targets admins
          break;
      }

      final subscriptions = <Future<void>>[
        _messaging.subscribeToTopic('topic_all'),
        if (specificTopic != null) _messaging.subscribeToTopic(specificTopic),
      ];

      await Future.wait(subscriptions).timeout(const Duration(seconds: 5));
      _topicsSubscribed = true;
      debugPrint(
        specificTopic != null
            ? 'FCM: Subscribed to topic_all and $specificTopic'
            : 'FCM: Subscribed to topic_all',
      );
    } catch (e) {
      _topicsSubscribed = false;
      debugPrint('FCM: Failed to subscribe to topics: $e');
    }
  }

  Future<String?> getToken({bool waitForApns = true}) async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _messaging
            .getAPNSToken()
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
        if (waitForApns && apnsToken == null) {
          // Wait briefly for iOS APNs registration during cold startup.
          for (var i = 0; i < 3 && apnsToken == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            apnsToken = await _messaging
                .getAPNSToken()
                .timeout(const Duration(seconds: 2), onTimeout: () => null);
          }
        }
        if (apnsToken == null) {
          debugPrint('FCM: APNs token not yet available on iOS; deferring to onTokenRefresh.');
          return null;
        }
      }
      return await _messaging
          .getToken()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
    } catch (e) {
      debugPrint('FCM: Failed to retrieve token: $e');
      return null;
    }
  }

  Future<void> unsubscribeFromRoleTopics(String? role) async {
    _pendingTopicRole = null;
    _topicsSubscribed = false;
    _registeredToken = null;
    try {
      final unsubscribes = <Future<void>>[
        _messaging.unsubscribeFromTopic('topic_all'),
      ];

      String? specificTopic;
      if (role != null) {
        switch (role.toUpperCase()) {
          case 'CUSTOMER':
            specificTopic = 'topic_customers';
            break;
          case 'DRIVER':
            specificTopic = 'topic_drivers';
            break;
          case 'VENDOR':
          case 'VENDOR_MEMBER':
          case 'VENDOR_OWNER':
            specificTopic = 'topic_vendors';
            break;
          case 'ADMIN':
          case 'SUPER_ADMIN':
          case 'DRIVER_MANAGER':
            specificTopic = 'topic_admin';
            break;
        }
      }

      if (specificTopic != null) {
        unsubscribes.add(_messaging.unsubscribeFromTopic(specificTopic));
      }

      await Future.wait(unsubscribes).timeout(const Duration(seconds: 2));
      debugPrint(
        specificTopic != null
            ? 'FCM: Unsubscribed from topic_all and $specificTopic'
            : 'FCM: Unsubscribed from topic_all',
      );
    } catch (e) {
      debugPrint('FCM: Failed to unsubscribe from topics: $e');
    }
  }

  void dispose() {
    unawaited(_tokenRefreshSub?.cancel());
    unawaited(_foregroundMessageSub?.cancel());
    unawaited(_openedAppSub?.cancel());
    unawaited(_connectivitySub?.cancel());
    unawaited(_openedAppController.close());
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Background Firebase initialization warning: $e');
  }
  debugPrint('Handling a background message: ${message.messageId}');
}

void registerPushNotificationBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> _createAndroidNotificationChannel(
  FlutterLocalNotificationsPlugin plugin,
) async {
  if (kIsWeb || !Platform.isAndroid) return;
  final androidPlugin = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin == null) return;

  await androidPlugin
      .createNotificationChannel(PushNotificationService.defaultAndroidChannel)
      .timeout(const Duration(seconds: 2));

  try {
    await androidPlugin
        .deleteNotificationChannel(
          channelId: PushNotificationService._legacyAndroidChannelId,
        )
        .timeout(const Duration(seconds: 2));
  } catch (_) {}
}

/// Ensures the default high-importance Android notification channel (with
/// device default sound & vibration enabled) is created before any background
/// FCM notification arrives.
Future<void> ensurePushNotificationChannel() async {
  try {
    await _createAndroidNotificationChannel(FlutterLocalNotificationsPlugin());
  } catch (e) {
    debugPrint('FCM: Notification channel setup warning: $e');
  }
}

