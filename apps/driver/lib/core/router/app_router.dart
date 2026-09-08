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
import 'package:driver/features/profile/presentation/pages/vehicle_screen.dart';
import 'package:driver/features/orders/presentation/pages/deliveries_history_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final splashState = ref.read(splashProvider);
      
      // If splash is still loading, don't redirect, let splash handle it
      if (splashState.isLoading || !splashState.hasValue) return null;
      
      final appState = splashState.value!;
      final isGoingToLogin = state.matchedLocation == '/login';
      if (appState == AppStartupState.unauthenticated && !isGoingToLogin) {
        return '/login';
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
    ],
  );
}
