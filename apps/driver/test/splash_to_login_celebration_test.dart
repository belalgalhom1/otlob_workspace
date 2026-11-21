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

class _FakeStaleDriverAuth extends Auth {
  @override
  AsyncValue<bool> build() => const AsyncValue.data(true);
}

class _FakeDriverSplashAuthenticated extends Splash {
  @override
  Future<AppStartupState> build() async => AppStartupState.dashboard;
}

class _FakeDriverAuthAuthenticated extends Auth {
  @override
  AsyncValue<bool> build() => const AsyncValue.data(true);
}

void main() {
  tearDown(OtlobLoginEntranceCoordinator.reset);

  for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets(
        'Driver Splash -> ~4s Spin -> Hero Transition -> Welcome Celebration & Confetti/Sparkles inside Login (${locale.languageCode}, ${themeMode.name})',
        (tester) async {
          final router = GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
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

          // At 2 seconds, Splash must still be spinning and NOT yet navigated to Login.
          await tester.pump(const Duration(seconds: 2));
          expect(find.byType(OtlobSplashSpinLogo), findsOneWidget);
          expect(find.byType(LoginScreen), findsNothing);

          // Finish remaining ~1.9s spin + 800ms Hero transition -> enters Login.
          await tester.pump(const Duration(milliseconds: 2100));
          await tester.pump(const Duration(milliseconds: 900));
          expect(find.byType(LoginScreen), findsOneWidget);

          // Entrance (900ms) starts after Hero and triggers 10s confetti/sparkles at 0.72.
          await tester.pump(const Duration(milliseconds: 900));
          final overlayState = tester.state<OtlobLoginWelcomeOverlayState>(
            find.byType(OtlobLoginWelcomeOverlay),
          );
          expect(overlayState.effectsController.isAnimating, isTrue);

          await tester.pumpAndSettle(const Duration(seconds: 1));

          final expectedWelcome = locale.languageCode == 'ar'
              ? 'مرحباً بك في أطلب'
              : 'WELCOME TO OTLOB';
          expect(find.text(expectedWelcome), findsOneWidget);
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
                  of: find.text(expectedWelcome),
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

  testWidgets(
    'Driver Splash stays on ~4s spin before navigating to dashboard when authenticated',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
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
            splashProvider.overrideWith(_FakeDriverSplashAuthenticated.new),
            authProvider.overrideWith(_FakeDriverAuthAuthenticated.new),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(OtlobSplashSpinLogo), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(OtlobSplashSpinLogo), findsOneWidget);
      expect(find.text('DASHBOARD'), findsNothing);

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pumpAndSettle();
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Driver Splash clears stale authProvider == true when unauthenticated so celebration still plays on Login',
    (tester) async {
      GoRouter? router;
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        router?.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            splashProvider.overrideWith(_FakeDriverSplash.new),
            authProvider.overrideWith(_FakeStaleDriverAuth.new),
            sharedAuthRepositoryProvider
                .overrideWithValue(_FakeDriverAuthRepo()),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              router ??= GoRouter(
                initialLocation: '/',
                redirect: (context, state) {
                  final auth = ref.read(authProvider);
                  final isAuthenticated =
                      !auth.isLoading && auth.hasValue && auth.value == true;
                  if (isAuthenticated && state.matchedLocation == '/login') {
                    return '/dashboard';
                  }
                  return null;
                },
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
                  GoRoute(
                    path: '/dashboard',
                    builder: (_, _) => const Scaffold(body: Text('DASHBOARD')),
                  ),
                  GoRoute(
                    path: '/login',
                    pageBuilder: (context, state) {
                      if (OtlobLoginEntranceCoordinator
                          .shouldUseTransitionForPage(state.pageKey)) {
                        return CustomTransitionPage<void>(
                          key: state.pageKey,
                          transitionDuration:
                              OtlobSplashToLoginTransition.effectiveDuration(
                            context,
                          ),
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
              return MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('ar'),
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.dark,
                routerConfig: router!,
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 4100));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 900));

      final overlayState = tester.state<OtlobLoginWelcomeOverlayState>(
        find.byType(OtlobLoginWelcomeOverlay),
      );
      expect(overlayState.effectsController.isAnimating, isTrue);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('مرحباً بك في أطلب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
