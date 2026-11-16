import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/features/auth/presentation/login_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeVendorAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<String?> getUserRole() async => 'VENDOR_MEMBER';

  @override
  Future<List<dynamic>> getVendorMemberships() async => [
        {'vendorId': 'v-1'},
      ];

  @override
  Future<dynamic> login(
    String email,
    String password, {
    String? appType,
  }) async =>
      {
        'access_token': 'fake-access',
        'refresh_token': 'fake-refresh',
      };
}

class _FakeVendorLegalRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getAcceptanceStatus() async =>
      {'needsAcceptance': false};
}

class _FakePlatformSettingsRepo extends Fake
    implements SharedPlatformSettingsRepository {
  @override
  Future<dynamic> checkAppVersion(dynamic dto) async =>
      {'isMaintenanceMode': false, 'mustUpdate': false, 'shouldUpdate': false};
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

class _TestActiveVendor extends ActiveVendor {
  @override
  String? build() => null;

  @override
  Future<void> setActiveVendor(String vendorId) async {
    state = vendorId;
  }
}

class _TestAuthNotifier extends AuthNotifier {
  final AsyncValue<bool> initialState;
  int loginCalls = 0;
  int googleCalls = 0;

  _TestAuthNotifier({this.initialState = const AsyncValue.data(false)});

  @override
  AsyncValue<bool> build() => initialState;

  @override
  Future<void> login(String email, String password) async {
    loginCalls++;
  }

  @override
  Future<void> loginWithGoogle() async {
    googleCalls++;
  }
}

class _TestLocaleNotifier extends LocaleNotifier {
  final Locale initialLocale;

  _TestLocaleNotifier(this.initialLocale);

  @override
  Locale build() => initialLocale;
}

class _TestThemeNotifier extends ThemeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}

Future<_TestAuthNotifier> _pumpVendorLoginScreen(
  WidgetTester tester, {
  required Locale locale,
  AsyncValue<bool> authState = const AsyncValue.data(false),
}) async {
  final testAuth = _TestAuthNotifier(initialState: authState);

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => testAuth),
        localeProvider.overrideWith(() => _TestLocaleNotifier(locale)),
        themeProvider.overrideWith(_TestThemeNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const LoginScreen(),
      ),
    ),
  );
  if (authState.isLoading) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  } else {
    await tester.pumpAndSettle();
  }
  return testAuth;
}

void main() {
  for (final entry in [
    (
      locale: const Locale('en'),
      googleLabel: 'Continue with Google',
      appleLabel: 'Continue with Apple',
      comingSoon: 'Continue with Apple will be available soon.',
    ),
    (
      locale: const Locale('ar'),
      googleLabel: 'المتابعة عبر Google',
      appleLabel: 'المتابعة عبر Apple',
      comingSoon: 'المتابعة عبر Apple ستتوفر قريباً.',
    ),
  ]) {
    testWidgets(
      'Vendor LoginScreen renders matching Google and UI-only Apple buttons (${entry.locale.languageCode.toUpperCase()})',
      (tester) async {
        final testAuth = await _pumpVendorLoginScreen(
          tester,
          locale: entry.locale,
        );

        final googleFinder = find.text(entry.googleLabel);
        final appleFinder = find.text(entry.appleLabel);

        expect(googleFinder, findsOneWidget);
        expect(appleFinder, findsOneWidget);
        expect(find.byIcon(Icons.apple), findsOneWidget);
        expect(find.byType(SocialAuthButton), findsNWidgets(2));

        final googleBox = find.ancestor(
          of: googleFinder,
          matching: find.byType(SocialAuthButton),
        );
        final appleBox = find.ancestor(
          of: appleFinder,
          matching: find.byType(SocialAuthButton),
        );

        final googleSize = tester.getSize(googleBox);
        final appleSize = tester.getSize(appleBox);
        expect(googleSize.height, 56);
        expect(appleSize.height, 56);
        expect(appleSize.width, googleSize.width);

        await tester.ensureVisible(appleBox);
        await tester.tap(appleBox);
        await tester.pump();

        expect(find.text(entry.comingSoon), findsOneWidget);
        expect(testAuth.loginCalls, 0);
        expect(testAuth.googleCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Vendor LoginScreen disables both social buttons while authProvider is loading',
    (tester) async {
      final testAuth = await _pumpVendorLoginScreen(
        tester,
        locale: const Locale('en'),
        authState: const AsyncValue.loading(),
      );

      final socialButtons = find.byType(SocialAuthButton);
      expect(socialButtons, findsNWidgets(2));

      for (final buttonWidget in tester.widgetList<SocialAuthButton>(socialButtons)) {
        expect(buttonWidget.onPressed, isNull);
      }

      final appleBox = find.ancestor(
        of: find.byIcon(Icons.apple),
        matching: find.byType(SocialAuthButton),
      );
      await tester.ensureVisible(appleBox);
      await tester.tap(appleBox);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(testAuth.loginCalls, 0);
      expect(testAuth.googleCalls, 0);
    },
  );

  test(
    'Real Vendor AuthNotifier.login completes immediately without blocking on hanging PushNotificationService.initialize',
    () async {
      final hangingPush = _HangingPushService();

      final container = ProviderContainer(
        overrides: [
          sharedAuthRepositoryProvider.overrideWithValue(_FakeVendorAuthRepo()),
          sharedLegalDocumentsRepositoryProvider
              .overrideWithValue(_FakeVendorLegalRepo()),
          sharedPlatformSettingsRepositoryProvider
              .overrideWithValue(_FakePlatformSettingsRepo()),
          activeVendorProvider.overrideWith(_TestActiveVendor.new),
          pushNotificationServiceProvider.overrideWithValue(hangingPush),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .login('vendor@example.com', 'password123');

      final authState = container.read(authProvider);
      expect(authState.isLoading, isFalse);
      expect(authState.value, isTrue);
      expect(container.read(activeVendorProvider), 'v-1');
      expect(container.read(vendorPostAuthRouteProvider), '/dashboard');
      expect(hangingPush.initCalls, 1);
    },
  );
}
