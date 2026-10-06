import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';

class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    return MaintenanceScreen(
      title: s.maintenanceTitle,
      message: s.maintenanceMessage,
      retryLabel: s.retry,
      onRetry: () => context.go(RoutePaths.splash),
    );
  }
}
