import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/features/auth/presentation/login_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

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
}
