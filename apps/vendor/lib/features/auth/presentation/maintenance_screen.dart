import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        MaintenanceScreen(
          title: l10n.maintenanceTitle,
          message: l10n.maintenanceMessage,
          retryLabel: l10n.retry,
          onRetry: () => context.go('/splash'),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(l10n.adminLogin),
            ),
          ),
        ),
      ],
    );
  }
}
