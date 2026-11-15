import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';

class UpdateRequiredPage extends ConsumerWidget {
  const UpdateRequiredPage({super.key});

  Future<void> _openStore(BuildContext context, WidgetRef ref) async {
    final url = (ref.read(updateStoreUrlProvider) ?? '').trim();
    if (url.isNotEmpty) {
      await ExternalActionLauncher.openWebUrl(url, context: context);
    }
    if (context.mounted) {
      ref.invalidate(splashProvider);
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ForceUpdateScreen(
      title: l10n.updateRequiredTitle,
      message: l10n.updateRequiredMessage,
      updateLabel: l10n.updateNow,
      onUpdate: () => _openStore(context, ref),
    );
  }
}
