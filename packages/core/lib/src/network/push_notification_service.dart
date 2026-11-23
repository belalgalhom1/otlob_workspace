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

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DevicesPushNotificationsApi _devicesApi;
  final StreamController<RemoteMessage> _openedAppController =
      StreamController<RemoteMessage>.broadcast();

  bool _listenersInitialized = false;
  RemoteMessage? _pendingInitialLocalMessage;

  PushNotificationService(this._devicesApi);

  Future<void> initialize() async {
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

    if (!_listenersInitialized) {
      try {
        // Initialize local notifications for foreground display and tap routing
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
          _pendingInitialLocalMessage =
              _decodeLocalPayload(launchDetails?.notificationResponse?.payload);
        }

        await _createAndroidNotificationChannel(_localNotifications);
      } catch (e) {
        debugPrint('FCM: Local notifications initialization warning: $e');
      }

      // Attach listeners before fetching token so delayed APNs registration
      // on iOS never prevents token refresh or foreground message delivery.
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        await _registerToken(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            'Received foreground message: ${message.notification?.title}');
        _handleRemoteMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message clicked! Routing to payload: ${message.data}');
        _openedAppController.add(message);
      });

      _listenersInitialized = true;
    }

    final token = await getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _registerToken(token);
    }
  }

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp => _openedAppController.stream;

  Future<RemoteMessage?> getInitialMessage() async {
    final fcmInitial = await _messaging.getInitialMessage();
    if (fcmInitial != null) return fcmInitial;

    final pendingLocal = _pendingInitialLocalMessage;
    _pendingInitialLocalMessage = null;
    if (pendingLocal != null) return pendingLocal;

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      return _decodeLocalPayload(launchDetails?.notificationResponse?.payload);
    }
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

  Future<void> _registerToken(String token) async {
    try {
      final platform = kIsWeb
          ? RegisterDeviceDtoPlatformEnum.WEB
          : (Platform.isIOS
              ? RegisterDeviceDtoPlatformEnum.IOS
              : RegisterDeviceDtoPlatformEnum.ANDROID);

      final dto = RegisterDeviceDto((b) => b
        ..token = token
        ..platform = platform);

      await _devicesApi
          .devicesControllerRegister(registerDeviceDto: dto)
          .timeout(const Duration(seconds: 5));
      debugPrint('FCM Token registered with backend successfully');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
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
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apnsToken = await _messaging
            .getAPNSToken()
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
        if (apnsToken == null) {
          debugPrint('FCM: APNs token not available on iOS; skipping topic subscription.');
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
      debugPrint(
        specificTopic != null
            ? 'FCM: Subscribed to topic_all and $specificTopic'
            : 'FCM: Subscribed to topic_all',
      );
    } catch (e) {
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

