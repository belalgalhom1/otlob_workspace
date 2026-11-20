import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/auth/presentation/pages/login_screen.dart';
import 'package:driver/features/splash/presentation/pages/splash_screen.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeDriverSplash extends Splash {
  @override
  Future<AppStartupState> build() async => AppStartupState.unauthenticated;
}

class _FakeDriverAuth extends Auth {
  @override
  AsyncValue<bool> build() => const AsyncValue.data(false);
}

class _FakeDriverAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<bool> isLoggedIn() async => false;
}

void main() {
  tearDown(OtlobLoginEntranceCoordinator.reset);

  for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets(
        'Driver Splash -> Spin -> Hero Transition -> Welcome Celebration inside Login (${locale.languageCode}, ${themeMode.name})',
        (tester) async {
          final router = GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
              GoRoute(
                path: '/login',
                pageBuilder: (context, state) {
                  if (OtlobLoginEntranceCoordinator.isPendingFromSplash) {
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
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const Scaffold(body: Text('DASHBOARD')),
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
                splashProvider.overrideWith(_FakeDriverSplash.new),
                authProvider.overrideWith(_FakeDriverAuth.new),
                sharedAuthRepositoryProvider
                    .overrideWithValue(_FakeDriverAuthRepo()),
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

          // Complete splash spin + Hero flight + Welcome Celebration inside Login
          await tester.pumpAndSettle(const Duration(seconds: 1));

          expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
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
                ? 'assets/logo_delivery_dark.png'
                : 'assets/logo_delivery.png',
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

          expect(find.byType(PrimaryButton), findsOneWidget);
          expect(find.byType(SocialAuthButton), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
