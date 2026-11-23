import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart' hide AppTheme;
import 'package:core/core.dart';

import 'core/providers/app_settings_provider.dart'; 
import 'core/providers/global_message_listener.dart';
import 'core/providers/global_order_listener.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final appSettings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);
    
    // Initialize global listeners
    ref.watch(globalMessageListenerProvider);
    ref.watch(globalOrderListenerProvider);

    return MaterialApp.router(
      title: 'OTLOB',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: AppTextInteractionScope.applySelectionTheme(AppTheme.lightTheme),
      darkTheme: AppTextInteractionScope.applySelectionTheme(AppTheme.darkTheme),
      themeMode: appSettings.themeMode,
      scrollBehavior: const AppScrollBehavior(),

      builder: (context, child) {
        return AppWindowConstraintGuard(
          minWidth: 360.0,
          minHeight: 600.0,
          minTextScaleFactor: 0.85,
          maxTextScaleFactor: 1.3,
          child: LocationRequiredGate(
            title: context.tr('location_required_title'),
            message: context.tr('location_required_message'),
            buttonLabel: context.tr('location_required_button'),
            child: AppTextInteractionScope(
              child: Column(
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final isOnlineAsync = ref.watch(isOnlineStreamProvider);
                      final isOnline = isOnlineAsync.asData?.value ?? true;
                      return OfflineStatusBanner(isOnline: isOnline);
                    },
                  ),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        );
      },

      routerConfig: router,
    );
  }
}
