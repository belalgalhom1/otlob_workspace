import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/auth/presentation/login_screen.dart';
import 'package:vendor/features/auth/presentation/splash_screen.dart';
import 'package:vendor/features/auth/presentation/vendor_selection_screen.dart'
    as vendor_selection;
import 'package:vendor/features/dashboard/presentation/dashboard_screen.dart';

import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:core/core.dart';

import 'package:vendor/features/auth/presentation/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await EnvConfig.init();

  try {
    await Firebase.initializeApp();
    registerPushNotificationBackgroundHandler();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'packages/core/assets/translations',
        fallbackLocale: const Locale('en'),
        useOnlyLangCode: true,
        child: const OtlobAdminApp(),
      ),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.value ?? false;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';

      if (authState.isLoading || authState.hasError) return null;

      if (!isAuth && !isGoingToLogin && !isGoingToSplash) {
        return '/login';
      }
      
      if (isAuth && isGoingToLogin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/select-vendor',
        builder: (context, state) =>
            const vendor_selection.VendorSelectionScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});

class OtlobAdminApp extends ConsumerWidget {
  const OtlobAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Otlob Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    );
  }
}
