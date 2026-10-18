import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';
import 'core/router/app_router.dart';
import 'core/providers/global_message_listener.dart';
import 'core/providers/app_preferences_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(globalMessageListenerProvider);
    final router = ref.watch(appRouterProvider);
    final appPreferences = ref.watch(appPreferencesProvider);

    return MaterialApp.router(
      title: 'OTLOB Driver',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...context.localizationDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appPreferences.locale,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appPreferences.themeMode,

      builder: (context, child) {
        final l10n = AppLocalizations.of(context)!;
        return LocationRequiredGate(
          title: l10n.locationRequiredTitle,
          message: l10n.locationRequiredMessage,
          buttonLabel: l10n.locationRequiredButton,
          child: child ?? const SizedBox.shrink(),
        );
      },

      routerConfig: router,
    );
  }
}
