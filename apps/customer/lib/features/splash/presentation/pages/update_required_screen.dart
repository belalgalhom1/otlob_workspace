import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';

class UpdateRequiredPage extends ConsumerWidget {
  final String? storeUrl;

  const UpdateRequiredPage({super.key, this.storeUrl});

  Future<void> _openStore(BuildContext context) async {
    final url = (storeUrl ?? '').trim();
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (context.mounted) context.go(RoutePaths.splash);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    return ForceUpdateScreen(
      title: s.updateRequiredTitle,
      message: s.updateRequiredMessage,
      updateLabel: s.updateNow,
      onUpdate: () => _openStore(context),
    );
  }
}
