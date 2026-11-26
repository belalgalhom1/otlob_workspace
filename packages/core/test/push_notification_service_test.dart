import 'dart:async';
import 'dart:convert';

import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test/test.dart';

class _FakeDevicesPushNotificationsApi implements DevicesPushNotificationsApi {
  final List<RegisterDeviceDto> registeredDevices = [];
  final List<String> removedTokens = [];
  bool failRegister = false;

  @override
  Future<Response<ApiControllerRoot200Response>> devicesControllerRegister({
    required RegisterDeviceDto registerDeviceDto,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (failRegister) {
      throw DioException(
        requestOptions: RequestOptions(path: '/devices'),
        type: DioExceptionType.connectionError,
        message: 'Simulated network failure',
      );
    }
    registeredDevices.add(registerDeviceDto);
    return Response<ApiControllerRoot200Response>(
      requestOptions: RequestOptions(path: '/devices'),
      statusCode: 201,
    );
  }

  @override
  Future<Response<ApiControllerRoot200Response>> devicesControllerRemove({
    required String token,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    removedTokens.add(token);
    return Response<ApiControllerRoot200Response>(
      requestOptions: RequestOptions(path: '/devices/$token'),
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseMessaging implements FirebaseMessaging {
  String? currentToken;
  String? currentApnsToken;
  RemoteMessage? initialMessage;
  final StreamController<String> tokenRefreshController =
      StreamController<String>.broadcast();
  final List<String> subscribedTopics = [];
  final List<String> unsubscribedTopics = [];
  int permissionRequests = 0;

  @override
  Future<String?> getToken({
    String? serviceWorkerScriptPath,
    String? vapidKey,
  }) async => currentToken;

  @override
  Future<String?> getAPNSToken() async => currentApnsToken;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Stream<String> get onTokenRefresh => tokenRefreshController.stream;

  @override
  Future<void> subscribeToTopic(String topic) async {
    subscribedTopics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    unsubscribedTopics.add(topic);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #requestPermission) {
      permissionRequests++;
      return Future<NotificationSettings>.value(
        const NotificationSettings(
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.notSupported,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.notSupported,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          timeSensitive: AppleNotificationSetting.notSupported,
          criticalAlert: AppleNotificationSetting.disabled,
          sound: AppleNotificationSetting.enabled,
          authorizationStatus: AuthorizationStatus.authorized,
          providesAppNotificationSettings: AppleNotificationSetting.disabled,
        ),
      );
    }
    if (invocation.memberName == #setForegroundNotificationPresentationOptions ||
        invocation.memberName == #deleteToken) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeLocalNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  void Function(NotificationResponse)? onTap;
  NotificationAppLaunchDetails? launchDetails;
  final List<Map<String, dynamic>> shown = [];
  int initializeCalls = 0;

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async =>
      launchDetails;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #initialize) {
      initializeCalls++;
      onTap =
          invocation.namedArguments[#onDidReceiveNotificationResponse]
              as void Function(NotificationResponse)?;
      return Future<bool?>.value(true);
    }
    if (invocation.memberName == #resolvePlatformSpecificImplementation) {
      return null;
    }
    if (invocation.memberName == #show) {
      shown.add({
        'id': invocation.namedArguments[#id],
        'title': invocation.namedArguments[#title],
        'body': invocation.namedArguments[#body],
        'payload': invocation.namedArguments[#payload],
      });
      return Future<void>.value();
    }
    return Future<void>.value();
  }
}

void main() {
  group('PushNotificationService', () {
    late _FakeDevicesPushNotificationsApi api;
    late _FakeFirebaseMessaging messaging;
    late _FakeLocalNotificationsPlugin localNotifications;
    late StreamController<RemoteMessage> onMessageController;
    late StreamController<RemoteMessage> onMessageOpenedAppController;
    late StreamController<bool> connectivityController;
    late PushNotificationService service;

    setUp(() {
      api = _FakeDevicesPushNotificationsApi();
      messaging = _FakeFirebaseMessaging();
      localNotifications = _FakeLocalNotificationsPlugin();
      onMessageController = StreamController<RemoteMessage>.broadcast();
      onMessageOpenedAppController =
          StreamController<RemoteMessage>.broadcast();
      connectivityController = StreamController<bool>.broadcast();

      service = PushNotificationService(
        api,
        messaging: messaging,
        localNotifications: localNotifications,
        onMessageStream: onMessageController.stream,
        onMessageOpenedAppStream: onMessageOpenedAppController.stream,
        connectivityChanges: connectivityController.stream,
      );
    });

    tearDown(() async {
      service.dispose();
      await onMessageController.close();
      await onMessageOpenedAppController.close();
      await connectivityController.close();
      await messaging.tokenRefreshController.close();
    });

    test(
      'ensureTapListenersInitialized attaches background and local tap listeners once without duplicates',
      () async {
        final received = <RemoteMessage>[];
        final sub = service.onMessageOpenedApp.listen(received.add);
        addTearDown(sub.cancel);

        await service.ensureTapListenersInitialized();
        await service.ensureTapListenersInitialized();

        expect(localNotifications.initializeCalls, 1);
        expect(localNotifications.onTap, isNotNull);

        onMessageOpenedAppController.add(
          const RemoteMessage(
            messageId: 'msg-fcm-tap',
            data: {'kind': 'wallet_topup', 'route': '/wallet'},
          ),
        );
        await Future<void>.delayed(Duration.zero);

        localNotifications.onTap!(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: jsonEncode({'kind': 'wallet_topup', 'topUpId': 'topup-1'}),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(received, hasLength(2));
        expect(received[0].data['route'], '/wallet');
        expect(received[1].data['topUpId'], 'topup-1');
      },
    );

    test(
      'initialize attaches tokenRefresh listener and re-registers/re-subscribes pending role on refresh',
      () async {
        // Delayed token scenario: role registered before token exists.
        messaging.currentToken = null;
        await service.subscribeToRoleTopics('DRIVER');
        await service.initialize();
        expect(messaging.permissionRequests, 1);
        expect(api.registeredDevices, isEmpty);

        messaging.subscribedTopics.clear();

        // Later token refresh (e.g., delayed APNs / FCM rotation) registers and re-subscribes.
        messaging.currentToken = 'fcm-token-delayed-123';
        messaging.tokenRefreshController.add('fcm-token-delayed-123');
        await Future<void>.delayed(Duration.zero);

        expect(api.registeredDevices, hasLength(1));
        expect(api.registeredDevices.first.token, 'fcm-token-delayed-123');
        expect(messaging.subscribedTopics, containsAll(['topic_all', 'topic_drivers']));
      },
    );

    test(
      'ensureTokenRegistered and connectivity recovery retry failed backend registration',
      () async {
        messaging.currentToken = 'fcm-token-retry';
        api.failRegister = true;

        await service.initialize();
        await service.subscribeToRoleTopics('SUPER_ADMIN');
        await service.ensureTokenRegistered(role: 'SUPER_ADMIN');

        // Registration failed while offline, so no registered device yet.
        expect(api.registeredDevices, isEmpty);

        // Connectivity recovery resets failure and retries registration.
        api.failRegister = false;
        messaging.subscribedTopics.clear();
        connectivityController.add(true);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(api.registeredDevices, hasLength(1));
        expect(api.registeredDevices.first.token, 'fcm-token-retry');
        // Since subscribeToRoleTopics succeeded initially on non-iOS, topic stays subscribed.
        expect(messaging.subscribedTopics, isEmpty);

        // When topic state was cleared, ensureTokenRegistered re-subscribes too.
        messaging.currentToken = 'fcm-token-retry-2';
        await service.unsubscribeFromRoleTopics('SUPER_ADMIN');
        await service.ensureTokenRegistered(role: 'SUPER_ADMIN');
        expect(api.registeredDevices, hasLength(2));
        expect(messaging.subscribedTopics, containsAll(['topic_all', 'topic_admin']));
      },
    );

    test(
      'getInitialMessage prefers FCM initialMessage and falls back to local launch payload on cold start',
      () async {
        localNotifications.launchDetails = NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: jsonEncode({
              'kind': 'wallet_topup',
              'route': '/wallet',
              'requestId': 'req-42',
            }),
          ),
        );

        final localInitial = await service.getInitialMessage();
        expect(localInitial, isNotNull);
        expect(localInitial!.data['kind'], 'wallet_topup');
        expect(localInitial.data['requestId'], 'req-42');

        messaging.initialMessage = const RemoteMessage(
          messageId: 'fcm-initial',
          data: {'kind': 'wallet_topup', 'topUpId': 'req-99'},
        );
        final fcmInitial = await service.getInitialMessage();
        expect(fcmInitial, isNotNull);
        expect(fcmInitial!.data['topUpId'], 'req-99');
      },
    );

    test(
      'unsubscribeFromRoleTopics clears pending topic state so token refresh does not re-subscribe old role',
      () async {
        messaging.currentToken = 'token-1';
        await service.initialize();
        await service.subscribeToRoleTopics('DRIVER');
        messaging.subscribedTopics.clear();

        await service.unsubscribeFromRoleTopics('DRIVER');
        expect(messaging.unsubscribedTopics, containsAll(['topic_all', 'topic_drivers']));

        messaging.tokenRefreshController.add('token-2');
        await Future<void>.delayed(Duration.zero);

        expect(messaging.subscribedTopics, isEmpty);
      },
    );
  });
}
