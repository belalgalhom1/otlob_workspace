import 'dart:async';

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
import 'package:vendor/features/auth/presentation/maintenance_screen.dart';
import 'package:vendor/features/auth/presentation/update_required_screen.dart';
import 'package:vendor/core/providers/global_order_listener.dart';
import 'package:vendor/core/providers/notification_router.dart';

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
  // Re-run redirects whenever auth changes so a mid-session expiry (the
  // unauthenticated event) actually routes the user to login.
  final authRefresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => authRefresh.value++);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      if (state.matchedLocation == '/maintenance' ||
          state.matchedLocation == '/update-required') {
        return null;
      }

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
        path: '/maintenance',
        builder: (context, state) => const MaintenancePage(),
      ),
      GoRoute(
        path: '/update-required',
        builder: (context, state) => const UpdateRequiredPage(),
      ),
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

    // Instant order updates regardless of the visible tab / app focus
    ref.watch(globalOrderListenerProvider);

    return _NotificationTapListener(
      child: MaterialApp.router(
        title: 'Otlob Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...context.localizationDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
      ),
    );
  }
}

/// Catches notification taps from background AND terminated states and banks
/// them in [notificationRouterProvider]. The dashboard consumes the pending
/// route (switching tabs / pushing screens) once it is visible — which also
/// covers cold starts where the tap arrives before login.
class _NotificationTapListener extends ConsumerStatefulWidget {
  final Widget child;

  const _NotificationTapListener({required this.child});

  @override
  ConsumerState<_NotificationTapListener> createState() =>
      _NotificationTapListenerState();
}

class _NotificationTapListenerState
    extends ConsumerState<_NotificationTapListener> {
  StreamSubscription<dynamic>? _openedAppSub;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      try {
        final push = ref.read(pushNotificationServiceProvider);
        _openedAppSub = push.onMessageOpenedApp.listen((message) {
          ref
              .read(notificationRouterProvider.notifier)
              .handleTap(Map<String, String>.from(message.data));
        });
        push.getInitialMessage().then((message) {
          if (message != null && mounted) {
            ref
                .read(notificationRouterProvider.notifier)
                .handleTap(Map<String, String>.from(message.data));
          }
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _openedAppSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
