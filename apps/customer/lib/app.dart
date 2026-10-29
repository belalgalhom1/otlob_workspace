import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart' hide AppTheme;

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

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appSettings.themeMode,

      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: LocationRequiredGate(
            title: context.tr('location_required_title'),
            message: context.tr('location_required_message'),
            buttonLabel: context.tr('location_required_button'),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      routerConfig: router,
    );
  }
}
