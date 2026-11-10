import 'package:driver/features/legal/presentation/pages/terms_acceptance_gate_screen.dart';
import 'package:driver/features/legal/presentation/pages/legal_document_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:driver/features/auth/presentation/pages/login_screen.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/features/dashboard/presentation/dashboard_screen.dart';
import 'package:driver/features/splash/presentation/pages/splash_screen.dart';
import 'package:driver/features/profile/presentation/pages/suspended_screen.dart';
import 'package:driver/features/order_execution/presentation/pages/order_execution_screen.dart';
import 'package:driver/features/shifts/presentation/pages/shifts_screen.dart';
import 'package:driver/features/chat/presentation/pages/chat_screen.dart';
import 'package:driver/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:driver/features/inbox/presentation/pages/inbox_screen.dart';
import 'package:driver/features/profile/presentation/pages/identity_screen.dart';
import 'package:driver/features/splash/presentation/pages/maintenance_screen.dart';
import 'package:driver/features/splash/presentation/pages/update_required_screen.dart';
import 'package:driver/features/profile/presentation/pages/vehicle_screen.dart';
import 'package:driver/features/orders/presentation/pages/deliveries_history_screen.dart';
import 'package:driver/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:driver/features/breaks/presentation/pages/driver_breaks_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // App-status gates and legal documents manage themselves; never redirect away from them.
      if (state.matchedLocation == '/maintenance' ||
          state.matchedLocation == '/update-required' ||
          state.matchedLocation.startsWith('/legal-document')) {
        return null;
      }

      final splashState = ref.read(splashProvider);
      
      // If splash is still loading, don't redirect, let splash handle it
      if (splashState.isLoading || !splashState.hasValue) return null;
      
      final appState = splashState.value!;
      final isGoingToLogin = state.matchedLocation == '/login';
      if (appState == AppStartupState.unauthenticated && !isGoingToLogin) {
        return '/login';
      }

      if (appState == AppStartupState.needsTerms && state.matchedLocation != '/terms-acceptance') {
        return '/terms-acceptance';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenancePage(),
      ),
      GoRoute(
        path: '/update-required',
        builder: (context, state) => const UpdateRequiredPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/suspended',
        builder: (context, state) => const SuspendedScreen(),
      ),
      GoRoute(
        path: '/order-execution',
        builder: (context, state) => const OrderExecutionScreen(),
      ),
      GoRoute(
        path: '/shifts',
        builder: (context, state) => const ShiftsScreen(),
      ),
      GoRoute(
        path: '/chat/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderChatScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/identity',
        builder: (context, state) => const IdentityScreen(),
      ),
      GoRoute(
        path: '/profile/vehicle',
        builder: (context, state) => const VehicleScreen(),
      ),
      GoRoute(
        path: '/deliveries',
        builder: (context, state) => const DeliveriesHistoryScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/breaks',
        builder: (context, state) => const DriverBreaksScreen(),
      ),
      GoRoute(
        path: '/terms-acceptance',
        builder: (context, state) => const TermsAcceptanceGateScreen(),
      ),
      GoRoute(
        path: '/legal-document',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final queryType = state.uri.queryParameters['type'];
          final queryTitle = state.uri.queryParameters['title'];
          return LegalDocumentViewerPage(
            type: extra['type']?.toString() ?? queryType ?? 'TERMS_OF_USE',
            initialTitle: extra['title']?.toString() ?? queryTitle,
          );
        },
      ),
    ],
  );
}
