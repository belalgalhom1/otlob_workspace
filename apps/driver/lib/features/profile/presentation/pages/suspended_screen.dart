import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountSuspended),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              LucideIcons.ban,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.accountSuspendedMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.accountSuspendedDetails,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: AppLocalizations.of(context)!.contactSupport,
              onPressed: () async {
                final url = Uri.parse('mailto:support@otlob-egy.online?subject=Account Suspended');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: Text(AppLocalizations.of(context)!.logout),
            ),
          ],
        ),
      ),
    );
  }
}
