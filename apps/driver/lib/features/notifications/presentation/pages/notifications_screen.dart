import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/notifications/presentation/notifications_provider.dart';
import 'package:driver/l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(driverNotificationsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            onPressed: () {
              ref.read(driverNotificationsProvider.notifier).markAllAsRead();
            },
            tooltip: l10n.markAllRead,
          ),
        ],
      ),
      body: notificationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            AppLocalizations.of(context)!.errorOccurred(error.toString()),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(child: Text(l10n.noNotificationsYet));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(driverNotificationsProvider);
            },
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['isRead'] == true;

                final title = isArabic
                    ? (notification['titleAr'] ?? notification['title'] ?? l10n.notificationsTitle)
                    : (notification['title'] ?? notification['titleAr'] ?? l10n.notificationsTitle);

                final body = isArabic
                    ? (notification['bodyAr'] ?? notification['body'] ?? '')
                    : (notification['body'] ?? notification['bodyAr'] ?? '');

                String timeStr = '';
                if (notification['createdAt'] != null) {
                  try {
                    final dt = DateTime.parse(notification['createdAt'].toString()).toLocal();
                    timeStr = DateFormat.MMMd().add_jm().format(dt);
                  } catch (_) {}
                }

                return ListTile(
                  tileColor: isRead
                      ? Theme.of(context).colorScheme.surface
                      : AppColors.primary.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(LucideIcons.bell, color: AppColors.primary),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                  subtitle: body.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(body),
                        )
                      : null,
                  onTap: () {
                    if (!isRead) {
                      ref
                          .read(driverNotificationsProvider.notifier)
                          .markAsRead(notification['id']);
                    }
                    final data = notification['data'] as Map<String, dynamic>?;
                    final notifType = notification['type']?.toString();
                    if (data != null && data['orderId'] != null) {
                      if (notifType == 'CHAT_MESSAGE') {
                        context.push('/chat/${data['orderId']}');
                      } else {
                        context.push('/order-execution');
                      }
                    } else if (notifType?.contains('SHIFT') == true) {
                      context.push('/shifts');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
