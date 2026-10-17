import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'notifications_provider.dart';
import '../../chat/presentation/inbox_counts_provider.dart';
import '../../chat/presentation/pages/admin_chat_screen.dart';

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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (state.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.checkCheck),
              tooltip: l10n.markAllRead,
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
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  )
                : state.notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.bellRing,
                                size: 48,
                                color: AppColors.primary.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.noNotificationsYet,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.notifications.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final n = state.notifications[index];
                          final id = n['id'] as String;
                          final title = n['title'] ?? '';
                          final body = n['body'] ?? '';
                          final isRead = n['isRead'] == true;
                          final type = n['type'] as String?;
                          final createdAt = n['createdAt'] as String?;

                          IconData iconData = LucideIcons.bell;
                          Color iconColor = AppColors.primary;

                          if (type == 'ORDER_UPDATE') {
                            iconData = LucideIcons.shoppingBag;
                            iconColor = Colors.orange;
                          } else if (type == 'CHAT_MESSAGE') {
                            iconData = LucideIcons.messageSquare;
                            iconColor = Colors.blue;
                          } else if (type == 'PROMOTION') {
                            iconData = LucideIcons.megaphone;
                            iconColor = Colors.red;
                          } else if (type == 'SYSTEM') {
                            iconData = LucideIcons.settings;
                            iconColor = Colors.grey;
                          } else if (type == 'PAYMENT') {
                            iconData = LucideIcons.wallet;
                            iconColor = Colors.green;
                          }

                          String timeStr = '';
                          if (createdAt != null) {
                            try {
                              timeStr = TimeFormatter.formatTimeAgo(
                                context,
                                DateTime.parse(createdAt).toLocal(),
                              );
                            } catch (_) {}
                          }

                          final bgColor = isRead
                              ? (isDark ? const Color(0xFF252525) : Colors.white)
                              : (isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.05));
                              
                          final borderColor = isRead
                              ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))
                              : AppColors.primary.withValues(alpha: 0.3);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (!isRead) {
                                    ref.read(notificationsProvider.notifier).markAsRead(id).then((_) {
                                      ref.read(inboxCountsProvider.notifier).refresh();
                                    });
                                  }
                                  
                                  // Handle deep links
                                  if (type == 'ORDER_UPDATE' && n['data'] != null && n['data']['orderId'] != null) {
                                    // Could open order details
                                  } else if (type == 'CHAT_MESSAGE' && n['data'] != null) {
                                    final convoId = n['data']['conversationId'] ?? n['data']['conversation_id'];
                                    if (convoId != null) {
                                      final chatType = n['data']['chatType'] ?? n['data']['chat_type'] ?? 'SUPPORT';
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => AdminChatScreen(
                                            conversationId: convoId.toString(),
                                            title: title,
                                            type: chatType.toString().toUpperCase(),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              iconColor.withValues(alpha: 0.22),
                                              iconColor.withValues(alpha: 0.06),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: iconColor.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(iconData, color: iconColor, size: 24),
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
                                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Theme.of(context).colorScheme.onSurface,
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
                                            const SizedBox(height: 6),
                                            Text(
                                              body,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                                                fontSize: 14,
                                                height: 1.45,
                                              ),
                                            ),
                                            if (timeStr.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.clock,
                                                    size: 12,
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
