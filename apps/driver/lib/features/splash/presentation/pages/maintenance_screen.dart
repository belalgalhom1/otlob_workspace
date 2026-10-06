import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';

class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return MaintenanceScreen(
      title: l10n.maintenanceTitle,
      message: l10n.maintenanceMessage,
      retryLabel: l10n.retry,
      onRetry: () {
        ref.invalidate(splashProvider);
        context.go('/');
      },
    );
  }
}
