import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationSettingsDialog extends ConsumerWidget {
  const NotificationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(sharedNotificationSettingsProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return AppDialog(
      maxWidth: 480,
      header: AppDialogHeader(
        icon: LucideIcons.bell,
        title: isAr ? 'إعدادات الإشعارات' : 'Notification Settings',
        subtitle: isAr
            ? 'تحكم في تنبيهات الطلبات والمحادثات الواردة'
            : 'Manage push, order update, and chat alert preferences',
        onClose: () => Navigator.pop(context),
      ),
      body: settingsAsync.when(
        data: (settingsData) {
          final settings = settingsData is Map && settingsData.containsKey('data')
              ? settingsData['data']
              : (settingsData ?? {});

          final pushEnabled = settings['pushEnabled'] == true;
          final orderUpdates = settings['orderUpdates'] == true;
          final chatMessages = settings['chatMessages'] == true;

          return AppDialogSectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    isAr ? 'الإشعارات الفورية' : 'Push Notifications',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    isAr
                        ? 'تفعيل أو إيقاف جميع الإشعارات الفورية'
                        : 'Enable or disable all push notifications',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: pushEnabled,
                  onChanged: (val) {
                    ref
                        .read(sharedNotificationSettingsProvider.notifier)
                        .updateNotificationSetting(pushEnabled: val);
                  },
                ),
                Divider(height: 1, color: AppDialogStyles.borderColor(context)),
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    isAr ? 'تحديثات الطلبات' : 'Order Updates',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    isAr
                        ? 'تلقي تنبيهات عند تغير حالة الطلبات'
                        : 'Receive alerts when order statuses change',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: orderUpdates,
                  onChanged: pushEnabled
                      ? (val) {
                          ref
                              .read(sharedNotificationSettingsProvider.notifier)
                              .updateNotificationSetting(orderUpdates: val);
                        }
                      : null,
                ),
                Divider(height: 1, color: AppDialogStyles.borderColor(context)),
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    isAr ? 'رسائل المحادثة' : 'Chat Messages',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    isAr
                        ? 'تلقي تنبيهات عند وصول رسائل محادثة جديدة'
                        : 'Receive alerts for new incoming chat messages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: chatMessages,
                  onChanged: pushEnabled
                      ? (val) {
                          ref
                              .read(sharedNotificationSettingsProvider.notifier)
                              .updateNotificationSetting(chatMessages: val);
                        }
                      : null,
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => AppDialogErrorBanner(
          message: ErrorUtils.translate(context, e),
        ),
      ),
      footer: AppDialogFooter(
        confirmLabel: isAr ? 'إغلاق' : 'Close',
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }
}
