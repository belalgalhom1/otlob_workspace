import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/features/auth/presentation/login_screen.dart';
import 'package:vendor/features/auth/presentation/splash_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeVendorAuth extends AuthNotifier {
  @override
  AsyncValue<bool> build() => const AsyncValue.data(false);

  @override
  Future<void> checkAuth() async {
    state = const AsyncValue.data(false);
  }
}

class _FakeVendorPlatformRepo extends Fake
    implements SharedPlatformSettingsRepository {
  @override
  Future<dynamic> checkAppVersion(dynamic dto) async => {
        'isMaintenanceMode': false,
        'mustUpdate': false,
        'shouldUpdate': false,
      };
}

void main() {
  tearDown(OtlobLoginEntranceCoordinator.reset);

  for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets(
        'Vendor Splash -> Spin -> Hero Transition -> Welcome Celebration inside Login (${locale.languageCode}, ${themeMode.name})',
        (tester) async {
          final router = GoRouter(
            initialLocation: '/splash',
            routes: [
              GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
              GoRoute(
                path: '/login',
                pageBuilder: (context, state) {
                  if (OtlobLoginEntranceCoordinator.shouldUseTransitionForPage(
                    state.pageKey,
                  )) {
                    return CustomTransitionPage<void>(
                      key: state.pageKey,
                      transitionDuration:
                          OtlobSplashToLoginTransition.effectiveDuration(
                              context),
                      reverseTransitionDuration: Duration.zero,
                      transitionsBuilder:
                          OtlobSplashToLoginTransition.buildPageTransition,
                      child: const LoginScreen(),
                    );
                  }
                  return MaterialPage<void>(
                    key: state.pageKey,
                    child: const LoginScreen(),
                  );
                },
              ),
            ],
          );

          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            router.dispose();
          });

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authProvider.overrideWith(_FakeVendorAuth.new),
                sharedPlatformSettingsRepositoryProvider
                    .overrideWithValue(_FakeVendorPlatformRepo()),
              ],
              child: MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                routerConfig: router,
              ),
            ),
          );

          await tester.pump();
          expect(find.byType(OtlobSplashSpinLogo), findsOneWidget);

          // At 2 seconds, Splash must still be spinning and NOT yet navigated to Login.
          await tester.pump(const Duration(seconds: 2));
          expect(find.byType(OtlobSplashSpinLogo), findsOneWidget);
          expect(find.byType(LoginScreen), findsNothing);

          await tester.pump(const Duration(milliseconds: 2100));
          await tester.pump(const Duration(milliseconds: 900));
          expect(find.byType(LoginScreen), findsOneWidget);

          await tester.pump(const Duration(milliseconds: 900));
          final overlayState = tester.state<OtlobLoginWelcomeOverlayState>(
            find.byType(OtlobLoginWelcomeOverlay),
          );
          expect(overlayState.effectsController.isAnimating, isTrue);

          await tester.pumpAndSettle(const Duration(seconds: 1));

          expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
          expect(find.text('Otlob Admin'), findsWidgets);
          expect(find.byIcon(LucideIcons.package), findsNothing);

          final logoFinder = find.descendant(
            of: find.byType(OtlobBrandHeroLogo),
            matching: find.byType(Image),
          );
          expect(logoFinder, findsOneWidget);
          final logoImage = tester.widget<Image>(logoFinder);
          expect(
            (logoImage.image as AssetImage).assetName,
            themeMode == ThemeMode.dark
                ? 'assets/logo_dark.png'
                : 'assets/logo_without_background.png',
          );

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

          expect(find.byType(SocialAuthButton), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
