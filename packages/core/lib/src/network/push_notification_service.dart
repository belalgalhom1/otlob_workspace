import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:api/api.dart';
import 'package:firebase_core/firebase_core.dart';

class PushNotificationService {
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
    // Request permission (iOS specifically, Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted permission for push notifications');
    }

    if (!kIsWeb && Platform.isIOS) {
      // Allow iOS to present APNs banners with sound natively in the foreground
      // so taps reliably route through FirebaseMessaging.onMessageOpenedApp.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (!_listenersInitialized) {
      // Initialize local notifications for foreground display and tap routing
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      );

      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _pendingInitialLocalMessage =
            _decodeLocalPayload(launchDetails?.notificationResponse?.payload);
      }

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description:
              'Used for important delivery requests and order updates.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
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

      await _devicesApi.devicesControllerRegister(registerDeviceDto: dto);
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
        await _devicesApi.devicesControllerRemove(token: resolvedToken);
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
      'high_importance_channel', // channel id
      'High Importance Notifications', // channel name
      importance: Importance.max,
      priority: Priority.high,
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
      await _messaging.subscribeToTopic('topic_all');
      debugPrint('FCM: Subscribed to topic_all');
      
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
      
      if (specificTopic != null) {
        await _messaging.subscribeToTopic(specificTopic);
        debugPrint('FCM: Subscribed to $specificTopic');
      }
    } catch (e) {
      debugPrint('FCM: Failed to subscribe to topics: $e');
    }
  }

  Future<String?> getToken({bool waitForApns = true}) async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (waitForApns && apnsToken == null) {
          // Wait briefly for iOS APNs registration during cold startup.
          for (var i = 0; i < 3 && apnsToken == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            apnsToken = await _messaging.getAPNSToken();
          }
        }
        if (apnsToken == null) {
          debugPrint('FCM: APNs token not yet available on iOS; deferring to onTokenRefresh.');
          return null;
        }
      }
      return await _messaging.getToken();
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

