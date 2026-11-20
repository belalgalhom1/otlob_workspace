import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'Vendor Splash -> Spin -> Hero Transition -> Welcome Celebration inside Login (${locale.languageCode})',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
            GoRoute(
              path: '/login',
              pageBuilder: (context, state) {
                if (OtlobLoginEntranceCoordinator.isPendingFromSplash) {
                  return CustomTransitionPage<void>(
                    key: state.pageKey,
                    transitionDuration:
                        OtlobSplashToLoginTransition.effectiveDuration(context),
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
              routerConfig: router,
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(OtlobSplashSpinLogo), findsOneWidget);

        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text('WELCOME TO OTLOB'), findsOneWidget);
        expect(find.text('Otlob Admin'), findsWidgets);
        expect(find.byType(SocialAuthButton), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
