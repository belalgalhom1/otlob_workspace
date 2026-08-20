import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:api/api.dart';
import 'package:firebase_core/firebase_core.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DevicesPushNotificationsApi _devicesApi;

  PushNotificationService(this._devicesApi);

  Future<void> initialize() async {
    // Request permission (iOS specifically, Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for push notifications');
    }

    // Initialize local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(settings: initSettings);

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _registerToken(token);
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token refreshed: $newToken');
      await _registerToken(newToken);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _handleRemoteMessage(message);
    });

    // Background / Terminated state clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked! Routing to payload: ${message.data}');
      // Handle routing via external callback if needed
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      final platform = kIsWeb 
          ? RegisterDeviceDtoPlatformEnum.WEB 
          : (Platform.isIOS ? RegisterDeviceDtoPlatformEnum.IOS : RegisterDeviceDtoPlatformEnum.ANDROID);

      final dto = RegisterDeviceDto((b) => b
        ..token = token
        ..platform = platform
      );

      await _devicesApi.devicesControllerRegister(registerDeviceDto: dto);
      debugPrint('FCM Token registered with backend successfully');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  void showLocalNotification({required String title, required String body, int? id}) {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // channel id
      'High Importance Notifications', // channel name
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotifications.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    showLocalNotification(
      title: notification.title ?? '',
      body: notification.body ?? '',
      id: notification.hashCode,
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
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

void registerPushNotificationBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

