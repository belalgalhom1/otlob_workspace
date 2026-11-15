import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart' hide tokenServiceProvider, TokenService;
import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otlob_customer/core/providers/app_settings_provider.dart';
import 'package:otlob_customer/core/router/route_paths.dart';
import 'package:otlob_customer/core/services/navigation_service.dart';
import 'package:otlob_customer/core/services/socket_service.dart';
import 'package:otlob_customer/core/services/token_service.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/profile/presentation/pages/profile_screen.dart';
import 'package:otlob_customer/features/profile/presentation/providers/coin_history_provider.dart';
import 'package:otlob_customer/features/profile/presentation/providers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart' show AppConfirmDialog;

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

class _FakeAuthRepo extends Fake implements SharedAuthRepository {
  bool loggedIn;
  bool throwOnLogout;
  int logoutCalls = 0;
  int clearLocalSessionCalls = 0;
  String? lastFcmToken;
  Duration? lastTimeout;

  _FakeAuthRepo({
    this.loggedIn = true,
    this.throwOnLogout = false,
  });

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<void> logout({
    String? fcmToken,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    logoutCalls++;
    lastFcmToken = fcmToken;
    lastTimeout = timeout;
    if (throwOnLogout) {
      throw Exception('network_timeout');
    }
  }

  @override
  Future<void> clearLocalSession() async {
    clearLocalSessionCalls++;
  }
}

class _FakeTokenService extends Fake implements TokenService {
  bool throwOnClearTokens;
  int clearTokensCalls = 0;

  _FakeTokenService({this.throwOnClearTokens = false});

  @override
  Future<String?> getAccessToken() async => 'fake-access-token';

  @override
  Future<void> clearTokens() async {
    clearTokensCalls++;
    if (throwOnClearTokens) {
      throw PlatformException(code: 'keychain_error', message: '-34018');
    }
  }
}

class _FakePushNotificationService extends Fake
    implements PushNotificationService {
  int getTokenCalls = 0;
  bool? lastWaitForApns;
  final List<String?> unsubscribedRoles = [];

  @override
  Future<String?> getToken({bool waitForApns = true}) async {
    getTokenCalls++;
    lastWaitForApns = waitForApns;
    return 'fcm-test-token';
  }

  @override
  Future<void> unsubscribeFromRoleTopics(String? role) async {
    unsubscribedRoles.add(role);
  }
}

class _FakeSocketService extends Fake implements SocketService {
  int disconnectCalls = 0;

  @override
  void disconnect() {
    disconnectCalls++;
  }
}

class _FakeCoreSocketService extends Fake implements CoreSocketService {
  int disconnectCalls = 0;

  @override
  void disconnect() {
    disconnectCalls++;
  }
}

class _RealLogoutAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}

class _StubProfile extends Profile {
  @override
  ProfileState build() => const ProfileState(
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+201000000000',
        avatar: '',
        isArabic: false,
      );
}

class _StubCoinHistory extends CoinHistory {
  @override
  CoinHistoryState build() => CoinHistoryState(currentBalance: 42);
}

class _StubCart extends Cart {
  @override
  CartState build() => const CartState(vendorBaskets: {});
}

class _StubNotificationSettings extends data_providers.SharedNotificationSettings {
  @override
  AsyncValue<dynamic> build() => const AsyncValue.data({
        'data': {'pushEnabled': true},
      });
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer App logout', () {
    test(
      'AuthController.logout() flips state to unauthenticated BEFORE clearing user providers even when repo/storage fail',
      () async {
        final fakeRepo = _FakeAuthRepo(loggedIn: true, throwOnLogout: true);
        final fakeTokens = _FakeTokenService(throwOnClearTokens: true);
        final fakePush = _FakePushNotificationService();
        final fakeSocket = _FakeSocketService();
        final fakeCoreSocket = _FakeCoreSocketService();

        final events = <String>[];
        AuthStatus? latestObservedAuth;

        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(_RealLogoutAuthController.new),
            sharedAuthRepositoryProvider.overrideWithValue(fakeRepo),
            tokenServiceProvider.overrideWithValue(fakeTokens),
            pushNotificationServiceProvider.overrideWithValue(fakePush),
            socketServiceProvider.overrideWithValue(fakeSocket),
            coreSocketServiceProvider.overrideWithValue(fakeCoreSocket),
            accessTokenProvider.overrideWith((ref) {
              events.add('accessToken:build:$latestObservedAuth');
              ref.onDispose(() {
                events.add('accessToken:dispose:$latestObservedAuth');
              });
              return 'fake-access-token';
            }),
          ],
        );
        addTearDown(container.dispose);

        container.listen<AuthStatus>(
          authControllerProvider,
          (_, next) {
            latestObservedAuth = next;
            events.add('auth:$next');
          },
          fireImmediately: true,
        );
        container.listen<AsyncValue<String?>>(
          accessTokenProvider,
          (_, _) {},
          fireImmediately: true,
        );
        await container.read(accessTokenProvider.future);

        await container.read(authControllerProvider.notifier).logout();

        expect(container.read(authControllerProvider), AuthStatus.unauthenticated);
        expect(fakeSocket.disconnectCalls, 1);
        expect(fakeCoreSocket.disconnectCalls, 1);
        expect(fakePush.getTokenCalls, 1);
        expect(fakePush.lastWaitForApns, isFalse);
        expect(fakePush.unsubscribedRoles, ['CUSTOMER']);
        expect(fakeRepo.logoutCalls, 1);
        expect(fakeRepo.lastFcmToken, 'fcm-test-token');
        expect(fakeRepo.lastTimeout, const Duration(seconds: 3));
        expect(fakeTokens.clearTokensCalls, 1);
        expect(fakeRepo.clearLocalSessionCalls, 1);

        final unauthIndex = events.indexOf('auth:AuthStatus.unauthenticated');
        final disposeIndex = events.indexOf(
          'accessToken:dispose:AuthStatus.unauthenticated',
        );
        expect(unauthIndex, isNot(-1));
        expect(disposeIndex, isNot(-1));
        expect(disposeIndex, greaterThan(unauthIndex));
      },
    );

    testWidgets(
      'ProfileScreen Logout navigates to /login (not /home and not /login?redirect=/profile)',
      (tester) async {
        dotenv.loadFromString(envString: 'API_URL=https://example.invalid');
        SharedPreferences.setMockInitialValues({
          'has_seen_onboarding': true,
          'language_code': 'en',
        });
        await EasyLocalization.ensureInitialized();
        final prefs = await SharedPreferences.getInstance();

        final fakeRepo = _FakeAuthRepo(loggedIn: true);
        final fakeTokens = _FakeTokenService();
        final fakePush = _FakePushNotificationService();
        final fakeSocket = _FakeSocketService();
        final fakeCoreSocket = _FakeCoreSocketService();

        final navService = NavigationService();
        final refreshNotifier = _RouterRefreshNotifier();
        AuthStatus latestAuth = AuthStatus.authenticated;

        final router = GoRouter(
          navigatorKey: navService.navigatorKey,
          initialLocation: '/profile',
          refreshListenable: refreshNotifier,
          redirect: (context, state) {
            final path = state.uri.path;
            final isAuthRoute = path == RoutePaths.login;
            final isPublicRoute = path == RoutePaths.home;
            if (latestAuth == AuthStatus.unauthenticated &&
                !isAuthRoute &&
                !isPublicRoute) {
              return '${RoutePaths.login}?redirect=$path';
            }
            return null;
          },
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
            ),
            GoRoute(
              path: RoutePaths.login,
              builder: (_, _) => const Scaffold(
                body: Center(child: Text('LOGIN_SENTINEL')),
              ),
            ),
            GoRoute(
              path: RoutePaths.home,
              builder: (_, _) => const Scaffold(
                body: Center(child: Text('HOME_SENTINEL')),
              ),
            ),
          ],
        );

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          router.dispose();
          refreshNotifier.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              navigationServiceProvider.overrideWithValue(navService),
              authControllerProvider.overrideWith(_RealLogoutAuthController.new),
              sharedAuthRepositoryProvider.overrideWithValue(fakeRepo),
              tokenServiceProvider.overrideWithValue(fakeTokens),
              pushNotificationServiceProvider.overrideWithValue(fakePush),
              socketServiceProvider.overrideWithValue(fakeSocket),
              coreSocketServiceProvider.overrideWithValue(fakeCoreSocket),
              profileProvider.overrideWith(_StubProfile.new),
              coinHistoryProvider.overrideWith(_StubCoinHistory.new),
              cartProvider.overrideWith(_StubCart.new),
              data_providers.sharedNotificationSettingsProvider
                  .overrideWith(_StubNotificationSettings.new),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                ref.listen<AuthStatus>(authControllerProvider, (_, next) {
                  latestAuth = next;
                  refreshNotifier.trigger();
                });
                return EasyLocalization(
                  supportedLocales: const [Locale('ar'), Locale('en')],
                  path: 'unused',
                  fallbackLocale: const Locale('ar'),
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
        await tester.pumpAndSettle();

        final logoutButtonFinder = find.byIcon(Icons.logout_rounded);
        await tester.scrollUntilVisible(
          logoutButtonFinder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(logoutButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(AppConfirmDialog), findsOneWidget);
        final confirmButton = find
            .descendant(
              of: find.byType(AppConfirmDialog),
              matching: find.byWidgetPredicate((w) => w is ElevatedButton),
            )
            .last;
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        expect(latestAuth, AuthStatus.unauthenticated);
        expect(fakeRepo.logoutCalls, 1);
        expect(fakeTokens.clearTokensCalls, 1);
        expect(fakeRepo.clearLocalSessionCalls, 1);
        expect(find.text('LOGIN_SENTINEL'), findsOneWidget);
        expect(find.text('HOME_SENTINEL'), findsNothing);
        expect(
          router.routeInformationProvider.value.uri.toString(),
          RoutePaths.login,
        );
      },
    );
  });
}
