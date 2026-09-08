import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/providers.dart' hide inboxCountsProvider;
import '../providers/inbox_counts_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(sharedInboxProvider.notifier).loadMore();
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
    final inboxState = ref.watch(sharedInboxProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'الرسائل' : 'Inbox',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(sharedInboxProvider.notifier).refresh();
        },
        child: inboxState.isLoading && inboxState.conversations.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : inboxState.error != null && inboxState.conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'فشل تحميل الرسائل' : 'Failed to load inbox',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(sharedInboxProvider.notifier).refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              )
            : inboxState.conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.grey.withValues(alpha: 0.3),
                      size: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'لا توجد رسائل بعد' : 'No messages yet',
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
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount:
                    inboxState.conversations.length +
                    (inboxState.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == inboxState.conversations.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  final convo = inboxState.conversations[index];
                  return _buildConversationItem(context, convo);
                },
              ),
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Map<String, dynamic> convo,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final id = convo['id'] as String;
    final type = convo['type'] as String? ?? 'UNKNOWN';
    final unreadCount = convo['unreadCount'] as int? ?? 0;
    final lastMessage = convo['lastMessage'] as Map<String, dynamic>?;

    String title = isAr ? 'محادثة' : 'Conversation';
    IconData icon = Icons.chat_rounded;
    Color iconColor = AppColors.primary;

    if (type == 'SUPPORT') {
      title = isAr ? 'الدعم الفني' : 'Support';
      icon = Icons.support_agent_rounded;
      iconColor = Colors.blue;
    } else if (type == 'ORDER') {
      final orderNumStr =
          convo['order']?['orderNumber'] ??
          convo['orderId']?.toString().substring(0, 8) ??
          '';
      title = isAr ? 'طلب #$orderNumStr' : 'Order #$orderNumStr';
      icon = Icons.receipt_long_rounded;
      iconColor = Colors.orange;
    } else if (type == 'VENDOR') {
      title = convo['vendor']?['name'] ?? (isAr ? 'متجر' : 'Store');
      icon = Icons.storefront_rounded;
      iconColor = Colors.green;
    }

    String subtitle = isAr ? 'لا توجد رسائل' : 'No messages';
    String timeStr = '';

    if (lastMessage != null) {
      final text = lastMessage['text'];
      subtitle = (text != null && text.toString().isNotEmpty)
          ? text.toString()
          : (isAr ? 'مرفق' : 'Attachment');
      final dateStr = lastMessage['createdAt'] as String?;
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr).toLocal();
          final now = DateTime.now();
          if (now.difference(date).inDays == 0 && now.day == date.day) {
            timeStr = DateFormat.jm().format(date);
          } else if (now.difference(date).inDays < 7) {
            timeStr = DateFormat('EEE').format(date);
          } else {
            timeStr = DateFormat('MMM d').format(date);
          }
        } catch (_) {}
      }
    }

    return InboxConversationTile(
      title: title,
      lastMessageContent: subtitle,
      timeStr: timeStr,
      unreadCount: unreadCount,
      icon: icon,
      iconColor: iconColor,
      isSupport: type == 'SUPPORT',
      onTap: () async {
        final targetId = (type == 'ORDER' && convo['orderId'] != null)
            ? convo['orderId']
            : id;
        await context.push(
          '/chat/${type.toLowerCase()}/$targetId',
          extra: {'title': title},
        );
        ref.read(inboxCountsProvider.notifier).refresh();
      },
    );
  }
}
