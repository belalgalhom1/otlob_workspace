import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationSettingsDialog extends ConsumerWidget {
  const NotificationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(sharedNotificationSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return DialogScaffold(child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bell, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Notification Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            settingsAsync.when(
              data: (settingsData) {
                final settings = settingsData is Map && settingsData.containsKey('data') 
                    ? settingsData['data'] 
                    : (settingsData ?? {});
                    
                final pushEnabled = settings['pushEnabled'] == true;
                final orderUpdates = settings['orderUpdates'] == true;
                final chatMessages = settings['chatMessages'] == true;

                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Enable or disable all push notifications'),
                      value: pushEnabled,
                      onChanged: (val) {
                        ref.read(sharedNotificationSettingsProvider.notifier).updateNotificationSetting(pushEnabled: val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Order Updates'),
                      subtitle: const Text('Receive alerts when order statuses change'),
                      value: orderUpdates,
                      onChanged: pushEnabled ? (val) {
                        ref.read(sharedNotificationSettingsProvider.notifier).updateNotificationSetting(orderUpdates: val);
                      } : null,
                    ),
                    SwitchListTile(
                      title: const Text('Chat Messages'),
                      subtitle: const Text('Receive alerts for new incoming chat messages'),
                      value: chatMessages,
                      onChanged: pushEnabled ? (val) {
                        ref.read(sharedNotificationSettingsProvider.notifier).updateNotificationSetting(chatMessages: val);
                      } : null,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load settings: $e', style: TextStyle(color: Theme.of(context).colorScheme.error))),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
