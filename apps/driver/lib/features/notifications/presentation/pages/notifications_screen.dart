import 'dart:convert';
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/notifications/presentation/notifications_provider.dart';
import 'package:driver/core/providers/driver_dispatch_coordinator.dart';
import 'package:driver/core/providers/notification_router.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';

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
            ErrorUtils.translate(context, error),
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
                    timeStr = DateFormat.MMMd(isArabic ? 'ar' : 'en').add_jm().format(dt);
                  } catch (_) {}
                }

                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bellAccent = isDark ? AppColors.primary : const Color(0xFF92400E);
                final titleText = title.toString();
                final titleDir = RegExp(r'[\u0600-\u06FF]').hasMatch(titleText)
                    ? ui.TextDirection.rtl
                    : (RegExp(r'[A-Za-z]').hasMatch(titleText)
                        ? ui.TextDirection.ltr
                        : null);
                final bodyText = body.toString();
                final bodyDir = RegExp(r'[\u0600-\u06FF]').hasMatch(bodyText)
                    ? ui.TextDirection.rtl
                    : (RegExp(r'[A-Za-z]').hasMatch(bodyText)
                        ? ui.TextDirection.ltr
                        : null);

                return ListTile(
                  tileColor: isRead
                      ? Theme.of(context).colorScheme.surface
                      : AppColors.primary.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(LucideIcons.bell, color: bellAccent),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          titleText,
                          textDirection: titleDir,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: bodyText.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            bodyText,
                            textDirection: bodyDir,
                          ),
                        )
                      : null,
                  onTap: () async {
                    final notifId = notification['id']?.toString();
                    if (!isRead && notifId != null && notifId.isNotEmpty) {
                      ref
                          .read(driverNotificationsProvider.notifier)
                          .markAsRead(notifId);
                    }
                    final coordinator =
                        ref.read(driverDispatchCoordinatorProvider);
                    final dispatchTap = await coordinator.handleNotificationTap(
                      context,
                      notification,
                    );
                    if (!context.mounted) return;
                    if (dispatchTap == DispatchTapResult.pending) {
                      return;
                    }
                    // Never push order-execution blindly: only when there is
                    // actually an active order, otherwise the screen bounces
                    // straight back to the dashboard.
                    final rawData = notification['data'];
                    Map<String, dynamic>? data;
                    if (rawData is Map) {
                      data = Map<String, dynamic>.from(rawData);
                    } else if (rawData is String && rawData.isNotEmpty) {
                      try {
                        final decoded = jsonDecode(rawData);
                        if (decoded is Map) {
                          data = Map<String, dynamic>.from(decoded);
                        }
                      } catch (_) {}
                    }
                    final notifType = notification['type']?.toString();
                    final isWalletNotification =
                        (data != null &&
                            DriverNotificationRouter.isWalletPayload(data)) ||
                        (notifType == 'PAYMENT' &&
                            (data?['route']?.toString() == '/wallet' ||
                                data?['kind']?.toString() == 'wallet_topup' ||
                                data?['topUpId'] != null ||
                                data?['requestId'] != null));
                    if (isWalletNotification) {
                      ref.invalidate(driverWalletProvider);
                      ref.invalidate(driverProfileProvider);
                      context.push('/wallet');
                    } else if (data != null && data['orderId'] != null) {
                      if (notifType == 'CHAT_MESSAGE') {
                        context.push('/chat/${data['orderId']}');
                      } else if (ref.read(orderExecutionProvider).value !=
                          null) {
                        context.push('/order-execution');
                      }
                    } else if (notifType?.contains('SHIFT') == true) {
                      context.push('/shifts');
                    } else if (data != null && data['kind'] == 'break') {
                      context.push('/breaks');
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
