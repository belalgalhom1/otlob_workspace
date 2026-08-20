import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';
import '../../../chat/presentation/providers/inbox_counts_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(notificationsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الإشعارات' : 'Notifications', style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          if (state.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: isAr ? 'تحديد الكل كمقروء' : 'Mark all as read',
              onPressed: () async {
                await ref.read(notificationsProvider.notifier).markAllAsRead();
                ref.read(inboxCountsProvider.notifier).refresh();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(notificationsProvider.notifier).refresh();
        },
        child: state.isLoading && state.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.error != null && state.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          isAr ? 'فشل تحميل الإشعارات' : 'Failed to load notifications',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  )
                : state.notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, color: Colors.grey.withValues(alpha: 0.3), size: 100),
                            const SizedBox(height: 16),
                            Text(
                              isAr ? 'لا توجد إشعارات' : 'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.notifications.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            );
                          }
                          final n = state.notifications[index];
                          return _buildNotificationItem(context, n);
                        },
                      ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final id = n['id'] as String;
    final type = n['type'] as String? ?? '';
    final title = (isAr ? n['titleAr'] : n['title']) ?? n['title'] ?? '';
    final body = (isAr ? n['bodyAr'] : n['body']) ?? n['body'] ?? '';
    final isRead = n['isRead'] as bool? ?? true;
    final dateStr = n['createdAt'] as String?;

    IconData icon = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;
    
    if (type == 'ORDER_UPDATE') {
      icon = Icons.local_shipping_rounded;
      iconColor = Colors.orange;
    } else if (type == 'CHAT_MESSAGE') {
      icon = Icons.chat_rounded;
      iconColor = Colors.blue;
    } else if (type == 'PROMOTION') {
      icon = Icons.local_offer_rounded;
      iconColor = Colors.green;
    } else if (type == 'PAYMENT') {
      icon = Icons.payment_rounded;
      iconColor = Colors.teal;
    } else if (type == 'ANNOUNCEMENT') {
      icon = Icons.campaign_rounded;
      iconColor = Colors.purple;
    }

    String timeStr = '';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr).toLocal();
        timeStr = DateFormat('MMM d, h:mm a').format(date);
      } catch (_) {}
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        ref.read(notificationsProvider.notifier).deleteNotification(id);
      },
      child: InkWell(
        onTap: () {
          if (!isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(id).then((_) {
              ref.read(inboxCountsProvider.notifier).refresh();
            });
          }
          // Deep link based on type if possible
          if (type == 'ORDER_UPDATE' && n['data'] != null && n['data']['orderId'] != null) {
            final orderStatus = n['data']['status'] ?? '';
            if (orderStatus != 'CANCELLED' && orderStatus != 'REJECTED') {
              context.push('/order-tracking/${n['data']['orderId']}');
            }
          } else if (type == 'CHAT_MESSAGE' && n['data'] != null) {
            final convoId = n['data']['conversationId'] ?? n['data']['conversation_id'];
            if (convoId != null) {
              final chatType = n['data']['chatType'] ?? n['data']['chat_type'] ?? 'direct';
              context.push('/chat/${chatType.toString().toLowerCase()}/$convoId');
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: !isRead 
                ? (isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.05))
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: !isRead 
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? Colors.white12 : Colors.grey.shade100),
            ),
            boxShadow: [
              if (!isDark && isRead)
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: !isRead ? FontWeight.w800 : FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: !isRead ? FontWeight.w500 : FontWeight.w400,
                        color: !isRead ? (isDark ? Colors.white70 : Colors.black87) : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
