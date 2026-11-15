import 'package:driver/core/providers/app_preferences_provider.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/auth/presentation/pages/login_screen.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

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
}
