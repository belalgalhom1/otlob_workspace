import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:api/api.dart';
import 'package:core/core.dart' as core;
import 'package:core/core.dart' hide tokenServiceProvider, TokenService;
import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/providers/app_settings_provider.dart';
import 'package:otlob_customer/core/router/app_router.dart';
import 'package:otlob_customer/core/services/socket_service.dart';
import 'package:otlob_customer/core/services/token_service.dart' as app_tokens;
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/auth/presentation/providers/login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart'
    show OtlobBrandHeroLogo, OtlobLoginEntranceCoordinator;

String _makeJwt({required DateTime exp, bool verified = true}) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.${b64({
    'sub': 'user-cust-1',
    'sid': 'sess-1',
    'role': 'CUSTOMER',
    'verified': verified,
    'exp': exp.millisecondsSinceEpoch ~/ 1000,
  })}.sig';
}

class _CatalogAssetLoader extends AssetLoader {
  const _CatalogAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final code = locale.languageCode;
    final p1 = '../../packages/core/assets/translations/$code.json';
    final p2 = 'packages/core/assets/translations/$code.json';
    final file = File(File(p1).existsSync() ? p1 : p2);
    if (!file.existsSync()) return {};
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

class _FakeAuthApi extends Fake implements AuthenticationApi {
  Future<Response<ApiControllerRoot200Response>> Function()? onLogin;
  Future<Response<ApiControllerRoot200Response>> Function()? onRefresh;
  int refreshCalls = 0;

  @override
  Future<Response<ApiControllerRoot200Response>> authControllerLogin({
    required LoginDto loginDto,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return onLogin!();
  }

  @override
  Future<Response<ApiControllerRoot200Response>> authControllerRefreshTokens({
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    refreshCalls++;
    return onRefresh!();
  }

  @override
  Future<Response<ApiControllerRoot200Response>> authControllerLogout({
    required LogoutDto logoutDto,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return Response<ApiControllerRoot200Response>(
      requestOptions: RequestOptions(path: '/auth/logout'),
      statusCode: 200,
    );
  }
}

class _FakeApiClient extends Fake implements Api {
  final _FakeAuthApi _authApi;
  _FakeApiClient(this._authApi);

  @override
  AuthenticationApi getAuthenticationApi() => _authApi;
}

class _FakeLegalRepo extends Fake implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getAcceptanceStatus() async =>
      {'needsAcceptance': false};
}

class _FakeAddressesRepo extends Fake implements CustomerAddressesRepository {
  @override
  Future<dynamic> getAddresses() async => [
        {'id': 'addr-1'},
      ];
}

class _FakeUserRepo extends Fake implements SharedUserRepository {
  @override
  Future<dynamic> getUser() async => {
        'user': {
          'id': 'user-cust-1',
          'name': 'Salma Adel',
          'email': 'salma@otlob.test',
          'phone': '+201001234567',
        },
      };
}

class _FakePushService extends Fake implements PushNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> subscribeToRoleTopics(String role) async {}

  @override
  Future<void> unsubscribeFromRoleTopics(String? role) async {}

  @override
  Future<String?> getToken({bool waitForApns = true}) async => 'fcm-1';
}

class _FakeSocketService extends Fake implements SocketService {
  @override
  void disconnect() {}
}

class _FakePlatformRepo extends Fake
    implements SharedPlatformSettingsRepository {
  @override
  Future<dynamic> checkAppVersion(dynamic dto) async => {
        'isMaintenanceMode': false,
        'mustUpdate': false,
        'shouldUpdate': false,
      };
}

Response<ApiControllerRoot200Response> _authOkResponse({
  required String access,
  required String refresh,
}) {
  final dto = standardSerializers.deserializeWith(
    ApiControllerRoot200Response.serializer,
    <String, dynamic>{
      'success': true,
      'statusCode': 200,
      'message': 'common.success.operation_success',
      'timestamp': '2026-11-20T00:00:00.000Z',
      'data': <String, dynamic>{
        'access_token': access,
        'refresh_token': refresh,
        'user': <String, dynamic>{
          'id': 'user-cust-1',
          'name': 'Salma Adel',
          'email': 'salma@otlob.test',
          'phone': '+201001234567',
          'role': 'CUSTOMER',
        },
      },
    },
  );
  return Response<ApiControllerRoot200Response>(
    requestOptions: RequestOptions(path: '/auth/login'),
    statusCode: 200,
    data: dto,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_URL=https://api.otlob.test\nWS_URL=wss://api.otlob.test',
    );
  });

  tearDown(() {
    OtlobLoginEntranceCoordinator.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  const storageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  void installMemoryStorage(
    Map<String, String> backingStore, {
    bool failTokenReads = false,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
      final args = call.arguments is Map
          ? Map<String, dynamic>.from(call.arguments as Map)
          : <String, dynamic>{};
      final key = args['key']?.toString();
      switch (call.method) {
        case 'read':
          if (failTokenReads &&
              (key == 'access_token' || key == 'refresh_token')) {
            return null;
          }
          return key != null ? backingStore[key] : null;
        case 'write':
          if (key != null) {
            final value = args['value']?.toString();
            if (value == null) {
              backingStore.remove(key);
            } else {
              backingStore[key] = value;
            }
          }
          return null;
        case 'delete':
          if (key != null) backingStore.remove(key);
          return null;
        case 'deleteAll':
          backingStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(backingStore);
        case 'containsKey':
          return key != null && backingStore.containsKey(key);
        default:
          return null;
      }
    });
  }

  Future<ProviderContainer> createContainer({
    required _FakeAuthApi authApi,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    final apiClient = _FakeApiClient(authApi);
    final coreTokenService = core.TokenService(apiClient, storage);
    final appTokenService = app_tokens.TokenService(storage);
    final authRepo = SharedAuthRepository(authApi, coreTokenService);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        data_providers.sharedAuthRepositoryProvider.overrideWithValue(authRepo),
        app_tokens.tokenServiceProvider.overrideWithValue(appTokenService),
        data_providers.sharedLegalDocumentsRepositoryProvider
            .overrideWithValue(_FakeLegalRepo()),
        data_providers.customerAddressesRepositoryProvider
            .overrideWithValue(_FakeAddressesRepo()),
        data_providers.sharedUserRepositoryProvider
            .overrideWithValue(_FakeUserRepo()),
        pushNotificationServiceProvider.overrideWithValue(_FakePushService()),
        socketServiceProvider.overrideWithValue(_FakeSocketService()),
        coreSocketServiceProvider.overrideWithValue(
          CoreSocketService(
            isTokenExpired: () async => false,
            refreshToken: () async => 't',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Part 1 — Customer First-Time Login & Session Verification', () {
    test(
      '1-5: Fresh install -> first login persists tokens, saves profile only after session succeeds, restores session on restart, and clears on logout',
      () async {
        final store = <String, String>{};
        installMemoryStorage(store);
        final authApi = _FakeAuthApi();
        final validAccess =
            _makeJwt(exp: DateTime.now().add(const Duration(minutes: 15)));
        final validRefresh =
            _makeJwt(exp: DateTime.now().add(const Duration(days: 7)));

        authApi.onLogin = () async =>
            _authOkResponse(access: validAccess, refresh: validRefresh);

        // Container 1 (Fresh Install)
        final c1 = await createContainer(authApi: authApi);
        await c1.read(authControllerProvider.notifier).checkAuthStatus();
        expect(c1.read(authControllerProvider), AuthStatus.unauthenticated);

        final ok = await c1.read(loginControllerProvider.notifier).login(
              email: 'salma@otlob.test',
              password: 'Password123!',
              rememberMe: true,
            );
        expect(ok, isTrue);
        expect(c1.read(authControllerProvider), AuthStatus.authenticated);
        expect(store['access_token'], validAccess);
        expect(store['refresh_token'], validRefresh);
        expect(store['user_email'], 'salma@otlob.test');
        expect(store['saved_email'], 'salma@otlob.test');

        // Container 2 (Cold Restart using same persistent storage)
        final c2 = await createContainer(authApi: authApi);
        await c2.read(authControllerProvider.notifier).checkAuthStatus();
        expect(c2.read(authControllerProvider), AuthStatus.authenticated);

        // Logout clears session tokens & reverts AuthStatus to unauthenticated
        await c2.read(authControllerProvider.notifier).logout();
        expect(c2.read(authControllerProvider), AuthStatus.unauthenticated);
        expect(store['access_token'], isNull);
        expect(store['refresh_token'], isNull);

        // Subsequent re-login succeeds cleanly
        final okAgain = await c2.read(loginControllerProvider.notifier).login(
              email: 'salma@otlob.test',
              password: 'Password123!',
              rememberMe: true,
            );
        expect(okAgain, isTrue);
        expect(c2.read(authControllerProvider), AuthStatus.authenticated);
      },
    );

    test(
      '6-8: Invalid credentials, network failure, and secure storage failure never create false sessions or save local profile',
      () async {
        final store = <String, String>{};
        installMemoryStorage(store);
        final authApi = _FakeAuthApi();

        // 401 Invalid credentials
        authApi.onLogin = () async => throw DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              response: Response(
                requestOptions: RequestOptions(path: '/auth/login'),
                statusCode: 401,
                data: {'message': 'auth.error.invalid_credentials'},
              ),
            );
        final c1 = await createContainer(authApi: authApi);
        final badCreds = await c1.read(loginControllerProvider.notifier).login(
              email: 'salma@otlob.test',
              password: 'wrong',
              rememberMe: true,
            );
        expect(badCreds, isFalse);
        expect(c1.read(authControllerProvider), AuthStatus.unauthenticated);
        expect(store.isEmpty, isTrue);

        // Network interruption
        authApi.onLogin = () async => throw DioException.connectionError(
              requestOptions: RequestOptions(path: '/auth/login'),
              reason: 'Offline',
            );
        final netFail = await c1.read(loginControllerProvider.notifier).login(
              email: 'salma@otlob.test',
              password: 'Password123!',
              rememberMe: true,
            );
        expect(netFail, isFalse);
        expect(c1.read(authControllerProvider), AuthStatus.unauthenticated);
        expect(store['saved_email'], isNull);

        // Storage write/readback failure
        installMemoryStorage(store, failTokenReads: true);
        final validAccess =
            _makeJwt(exp: DateTime.now().add(const Duration(minutes: 15)));
        final validRefresh =
            _makeJwt(exp: DateTime.now().add(const Duration(days: 7)));
        authApi.onLogin = () async =>
            _authOkResponse(access: validAccess, refresh: validRefresh);
        final storageFail = await c1
            .read(loginControllerProvider.notifier)
            .login(
              email: 'salma@otlob.test',
              password: 'Password123!',
              rememberMe: true,
            );
        expect(storageFail, isFalse);
        expect(c1.read(authControllerProvider), AuthStatus.unauthenticated);
        expect(store['saved_email'], isNull);
        expect(store['user_email'], isNull);
      },
    );

    test(
      '9-10: Locally saved profile WITHOUT valid tokens is never treated as authenticated, and expired access token refreshes cleanly',
      () async {
        final store = <String, String>{
          'saved_email': 'salma@otlob.test',
          'saved_name': 'Salma',
          'user_email': 'salma@otlob.test',
          'user_name': 'Salma',
        };
        installMemoryStorage(store);
        final authApi = _FakeAuthApi();

        final c1 = await createContainer(authApi: authApi);
        await c1.read(authControllerProvider.notifier).checkAuthStatus();
        expect(c1.read(authControllerProvider), AuthStatus.unauthenticated);

        // Seed expired access_token + valid refresh_token -> checkAuthStatus refreshes
        final expiredAccess =
            _makeJwt(exp: DateTime.now().subtract(const Duration(minutes: 5)));
        final freshAccess =
            _makeJwt(exp: DateTime.now().add(const Duration(minutes: 15)));
        final validRefresh =
            _makeJwt(exp: DateTime.now().add(const Duration(days: 7)));
        final rotatedRefresh =
            _makeJwt(exp: DateTime.now().add(const Duration(days: 7)));
        store['access_token'] = expiredAccess;
        store['refresh_token'] = validRefresh;
        authApi.onRefresh = () async =>
            _authOkResponse(access: freshAccess, refresh: rotatedRefresh);

        final c2 = await createContainer(authApi: authApi);
        await c2.read(authControllerProvider.notifier).checkAuthStatus();
        expect(authApi.refreshCalls, 1);
        expect(c2.read(authControllerProvider), AuthStatus.authenticated);
        expect(store['access_token'], freshAccess);
        expect(store['refresh_token'], rotatedRefresh);
      },
    );
  });

  group('Part 2 — Customer Splash-to-Login Flow & Welcome Celebration', () {
    testWidgets(
      'Unauthenticated Customer launch plays Splash spin -> transitions smoothly into Login -> displays WELCOME TO OTLOB celebration & interactive form',
      (tester) async {
        final store = <String, String>{};
        installMemoryStorage(store);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await EasyLocalization.ensureInitialized();

        final authApi = _FakeAuthApi();
        const storage = FlutterSecureStorage();
        final appTokenService = app_tokens.TokenService(storage);
        final coreTokenService =
            core.TokenService(_FakeApiClient(authApi), storage);
        final authRepo = SharedAuthRepository(authApi, coreTokenService);

        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              data_providers.sharedAuthRepositoryProvider
                  .overrideWithValue(authRepo),
              app_tokens.tokenServiceProvider
                  .overrideWithValue(appTokenService),
              data_providers.sharedPlatformSettingsRepositoryProvider
                  .overrideWithValue(_FakePlatformRepo()),
              pushNotificationServiceProvider
                  .overrideWithValue(_FakePushService()),
              socketServiceProvider.overrideWithValue(_FakeSocketService()),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                final router = ref.watch(appRouterProvider);
                return EasyLocalization(
                  supportedLocales: const [Locale('ar'), Locale('en')],
                  path: 'unused',
                  fallbackLocale: const Locale('en'),
                  startLocale: const Locale('en'),
                  useOnlyLangCode: true,
                  assetLoader: const _CatalogAssetLoader(),
                  child: Builder(
                    builder: (localizedContext) => MaterialApp.router(
                      localizationsDelegates:
                          localizedContext.localizationDelegates,
                      supportedLocales: localizedContext.supportedLocales,
                      locale: localizedContext.locale,
                      routerConfig: router,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pump();
        expect(find.text('OTLOB'), findsOneWidget);

        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
        expect(find.byType(OtlobBrandHeroLogo), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Continue as Guest'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
