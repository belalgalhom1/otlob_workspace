import 'dart:async';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:driver/core/providers/app_preferences_provider.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/auth/presentation/pages/login_screen.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeDriverAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<String?> getUserRole() async => 'DRIVER';

  @override
  Future<dynamic> login(
    String email,
    String password, {
    String? appType,
  }) async =>
      {
        'access_token': 'fake-access',
        'refresh_token': 'fake-refresh',
        'user': {
          'id': 'd1',
          'role': 'DRIVER',
          'driver': {
            'id': 'drv1',
            'status': 'OFFLINE',
            'isApproved': true,
          },
        },
      };
}

class _FakeDriverProfileRepo extends Fake implements DriverProfileRepository {
  int getMyProfileCalls = 0;

  @override
  Future<Map<String, dynamic>?> getMyProfile() async {
    getMyProfileCalls++;
    return {'id': 'drv1', 'status': 'OFFLINE', 'isApproved': true};
  }
}

class _FakeDriverLegalRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getAcceptanceStatus() async =>
      {'needsAcceptance': false};
}

class _FakeDriverOrdersRepo extends Fake implements DriverOrdersRepository {
  @override
  Future<dynamic> getActiveDriverOrder({String? orderId}) async => {'data': null};
}

class _FakeCoreSocketService extends Fake implements CoreSocketService {
  @override
  Future<void> init({String? forceToken, bool autoConnect = true}) async {}
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

class _TestAuth extends Auth {
  final AsyncValue<bool> initialState;
  int loginCalls = 0;
  int googleCalls = 0;

  _TestAuth({this.initialState = const AsyncValue.data(false)});

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

class _TestAppPreferences extends AppPreferences {
  final Locale locale;

  _TestAppPreferences(this.locale);

  @override
  AppPreferencesState build() => AppPreferencesState(
        themeMode: ThemeMode.light,
        locale: locale,
      );
}

Future<_TestAuth> _pumpDriverLoginScreen(
  WidgetTester tester, {
  required Locale locale,
  AsyncValue<bool> authState = const AsyncValue.data(false),
}) async {
  final testAuth = _TestAuth(initialState: authState);

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
        appPreferencesProvider.overrideWith(() => _TestAppPreferences(locale)),
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
      'Driver LoginScreen renders matching Google and UI-only Apple buttons (${entry.locale.languageCode.toUpperCase()})',
      (tester) async {
        final testAuth = await _pumpDriverLoginScreen(
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
    'Driver LoginScreen disables both social buttons while authProvider is loading',
    (tester) async {
      final testAuth = await _pumpDriverLoginScreen(
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
    'Real Driver Auth.login completes immediately without blocking on hanging PushNotificationService.initialize',
    () async {
      final fakeProfileRepo = _FakeDriverProfileRepo();
      final hangingPush = _HangingPushService();

      final container = ProviderContainer(
        overrides: [
          sharedAuthRepositoryProvider.overrideWithValue(_FakeDriverAuthRepo()),
          driverProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
          sharedLegalDocumentsRepositoryProvider
              .overrideWithValue(_FakeDriverLegalRepo()),
          driverOrdersRepositoryProvider
              .overrideWithValue(_FakeDriverOrdersRepo()),
          coreSocketServiceProvider
              .overrideWithValue(_FakeCoreSocketService()),
          pushNotificationServiceProvider.overrideWithValue(hangingPush),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .login('driver@example.com', 'password123');

      final authState = container.read(authProvider);
      expect(authState.isLoading, isFalse);
      expect(authState.value, isTrue);
      expect(
        container.read(driverPostLoginStateProvider),
        AppStartupState.dashboard,
      );
      // Driver status and approval were extracted from login payload without redundant GET /drivers/me
      expect(fakeProfileRepo.getMyProfileCalls, 0);
      expect(hangingPush.initCalls, 1);
    },
  );

  testWidgets(
    'Driver LoginScreen shows delivery brand logo below WELCOME TO OTLOB at 320x568 with 1.3x TextScaler',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _TestAuth()),
            appPreferencesProvider
                .overrideWith(() => _TestAppPreferences(const Locale('ar'))),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 568),
                padding: EdgeInsets.only(top: 44, bottom: 34),
                textScaler: TextScaler.linear(1.3),
              ),
              child: LoginScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signRect = tester.getRect(
        find
            .ancestor(
              of: find.text('WELCOME TO OTLOB'),
              matching: find.byType(Container),
            )
            .first,
      );
      final logoRect = tester.getRect(find.byType(OtlobBrandHeroLogo));
      expect(signRect.bottom, lessThanOrEqualTo(logoRect.top));
      expect(
        find.descendant(
          of: find.byType(OtlobBrandHeroLogo),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
