import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart' hide tokenServiceProvider, TokenService;
import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otlob_customer/core/providers/app_settings_provider.dart';
import 'package:otlob_customer/core/router/route_paths.dart';
import 'package:otlob_customer/core/services/token_service.dart';
import 'package:otlob_customer/features/auth/presentation/pages/login_screen.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, dynamic> loginResponse = {
    'access_token': 'fake-access',
    'refresh_token': 'fake-refresh',
    'user': {
      'id': 'u1',
      'email': 'customer@example.com',
      'phone': '+201000000000',
      'role': 'CUSTOMER',
    },
  };

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<dynamic> login(
    String email,
    String password, {
    String? appType,
  }) async =>
      loginResponse;

  @override
  Future<void> logout({
    String? fcmToken,
    Duration timeout = const Duration(seconds: 4),
  }) async {}
}

class _FakeLegalDocsRepo extends Fake implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getAcceptanceStatus() async => {
        'needsAcceptance': false,
      };
}

class _FakeAddressesRepo extends Fake implements CustomerAddressesRepository {
  @override
  Future<dynamic> getAddresses() async => [
        {'id': 'addr-1'},
      ];
}

class _FakeUserRepo extends Fake implements SharedUserRepository {
  int getUserCalls = 0;

  @override
  Future<dynamic> getUser() async {
    getUserCalls++;
    return {
      'user': {'phone': '+201000000000'},
    };
  }
}

class _HangingPushService extends Fake implements PushNotificationService {
  final Completer<void> initCompleter = Completer<void>();
  int initCalls = 0;

  @override
  Future<void> initialize() {
    initCalls++;
    return initCompleter.future;
  }

  @override
  Future<void> subscribeToRoleTopics(String role) async {}
}

class _FakeTokenService extends Fake implements TokenService {
  @override
  Future<Map<String, String>?> getSavedProfile() async => null;

  @override
  Future<void> clearTokens() async {}
}

class _TestAuthController extends AuthController {
  int loginCalls = 0;
  int googleCalls = 0;
  Future<bool> Function()? onGoogleSignIn;

  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> login(String email, String password) async {
    loginCalls++;
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleCalls++;
    if (onGoogleSignIn != null) {
      return onGoogleSignIn!();
    }
    return false;
  }
}

class _AuthStatusListenable extends ChangeNotifier {
  AuthStatus current = AuthStatus.unauthenticated;

  void update(AuthStatus next) {
    if (current != next) {
      current = next;
      notifyListeners();
    }
  }
}

Future<({
  _TestAuthController authController,
  GoRouter router,
})> _pumpLoginScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  _TestAuthController? controller,
}) async {
  SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
  await EasyLocalization.ensureInitialized();

  final authController = controller ?? _TestAuthController();
  final authListenable = _AuthStatusListenable();

  final router = GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: authListenable,
    redirect: (context, state) {
      if (authListenable.current == AuthStatus.initial) {
        return RoutePaths.splash;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('SPLASH_SENTINEL')),
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('HOME_SENTINEL')),
        ),
      ),
    ],
  );

  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    router.dispose();
    authListenable.dispose();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => authController),
        tokenServiceProvider.overrideWithValue(_FakeTokenService()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          ref.listen<AuthStatus>(
            authControllerProvider,
            (_, next) => authListenable.update(next),
          );
          return EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'unused',
            fallbackLocale: const Locale('ar'),
            startLocale: locale,
            useOnlyLangCode: true,
            assetLoader: const _CatalogAssetLoader(),
            child: Builder(
              builder: (localizedContext) => MaterialApp.router(
                localizationsDelegates: localizedContext.localizationDelegates,
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

  return (authController: authController, router: router);
}

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'LoginScreen renders matching Google and UI-only Continue with Apple buttons (${locale.languageCode.toUpperCase()})',
      (tester) async {
        final harness = await _pumpLoginScreen(tester, locale: locale);
        final isAr = locale.languageCode == 'ar';

        final googleLabel = isAr ? 'المتابعة عبر Google' : 'Continue with Google';
        final appleLabel =
            isAr ? 'المتابعة عبر Apple' : 'Continue with Apple';
        final appleNotice = isAr
            ? 'المتابعة عبر Apple ستتوفر قريباً.'
            : 'Continue with Apple will be available soon.';

        final googleButton = find.ancestor(
          of: find.text(googleLabel),
          matching: find.byType(OutlinedButton),
        );
        final appleButton = find.ancestor(
          of: find.text(appleLabel),
          matching: find.byType(OutlinedButton),
        );

        expect(googleButton, findsOneWidget);
        expect(appleButton, findsOneWidget);
        expect(find.byIcon(Icons.apple), findsOneWidget);

        final googleSize = tester.getSize(googleButton);
        final appleSize = tester.getSize(appleButton);
        expect(appleSize.height, equals(50.0));
        expect(appleSize.height, equals(googleSize.height));

        await tester.ensureVisible(appleButton);
        await tester.tap(appleButton);
        await tester.pump();

        expect(find.text(appleNotice), findsOneWidget);
        expect(harness.authController.loginCalls, 0);
        expect(harness.authController.googleCalls, 0);
      },
    );
  }

  testWidgets(
    'Clicking Google Sign-In stays on LoginScreen without bouncing to splash',
    (tester) async {
      final completer = Completer<bool>();
      final controller = _TestAuthController()
        ..onGoogleSignIn = () => completer.future;

      final harness = await _pumpLoginScreen(tester, controller: controller);

      final googleButton = find.ancestor(
        of: find.text('Continue with Google'),
        matching: find.byType(OutlinedButton),
      );
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pump();

      expect(controller.googleCalls, 1);
      expect(find.text('SPLASH_SENTINEL'), findsNothing);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        RoutePaths.login,
      );

      // Even while Google selection is pending, Apple button stays safely disabled.
      final appleButton = find.byWidgetPredicate(
        (w) => w is OutlinedButton && w.onPressed == null,
      );
      expect(appleButton, findsNWidgets(2));

      // Simulate cancellation returning false: stays on LoginScreen cleanly.
      completer.complete(false);
      await tester.pumpAndSettle();

      expect(find.text('SPLASH_SENTINEL'), findsNothing);
      expect(find.text('HOME_SENTINEL'), findsNothing);
      expect(
        harness.router.routeInformationProvider.value.uri.path,
        RoutePaths.login,
      );
    },
  );

  test(
    'Real AuthController.signInWithGoogle never resets AuthStatus back to initial',
    () async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          data_providers.sharedAuthRepositoryProvider.overrideWithValue(
            _FakeAuthRepo(),
          ),
          tokenServiceProvider.overrideWithValue(_FakeTokenService()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).checkAuthStatus();
      expect(container.read(authControllerProvider), AuthStatus.unauthenticated);

      final emittedStatuses = <AuthStatus>[];
      container.listen<AuthStatus>(
        authControllerProvider,
        (_, next) => emittedStatuses.add(next),
      );

      try {
        await container.read(authControllerProvider.notifier).signInWithGoogle();
      } catch (_) {
        // Headless test has no native GoogleSignIn channel; we care only about status transitions.
      }

      expect(emittedStatuses.contains(AuthStatus.initial), isFalse);
      expect(container.read(authControllerProvider), AuthStatus.unauthenticated);
    },
  );

  test(
    'Real AuthController.login completes immediately even when PushNotificationService.initialize hangs',
    () async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
      final prefs = await SharedPreferences.getInstance();
      final fakeUserRepo = _FakeUserRepo();
      final hangingPush = _HangingPushService();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          data_providers.sharedAuthRepositoryProvider.overrideWithValue(
            _FakeAuthRepo(),
          ),
          data_providers.sharedLegalDocumentsRepositoryProvider
              .overrideWithValue(_FakeLegalDocsRepo()),
          data_providers.customerAddressesRepositoryProvider
              .overrideWithValue(_FakeAddressesRepo()),
          data_providers.sharedUserRepositoryProvider
              .overrideWithValue(fakeUserRepo),
          pushNotificationServiceProvider.overrideWithValue(hangingPush),
          tokenServiceProvider.overrideWithValue(_FakeTokenService()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .login('customer@example.com', 'password123');

      expect(container.read(authControllerProvider), AuthStatus.authenticated);
      expect(container.read(needsTermsProvider), isFalse);
      expect(container.read(needsPhoneProvider), isFalse);
      expect(container.read(needsAddressProvider), isFalse);
      // Phone was extracted directly from login payload without redundant GET /users/profile
      expect(fakeUserRepo.getUserCalls, 0);
      expect(hangingPush.initCalls, 1);
    },
  );
}
