import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/data.dart';
import 'package:data/providers.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';

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
    Future.microtask(() {
      if (mounted) {
        ref.read(sharedInboxProvider.notifier).refresh();
      }
    });
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.inbox,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(sharedInboxProvider.notifier).refresh();
          },
          child: inboxState.isLoading && inboxState.conversations.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : inboxState.error != null && inboxState.conversations.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
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
                              ErrorUtils.translate(context, inboxState.error),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(sharedInboxProvider.notifier)
                                  .refresh(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : inboxState.conversations.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2),
                              size: 84,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.inboxEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    return _buildConversationItem(context, convo, l10n);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Map<String, dynamic> convo,
    AppLocalizations l10n,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final id = convo['id']?.toString() ?? '';
    final type = (convo['type']?.toString() ?? 'UNKNOWN').toUpperCase();
    final unreadCount = (convo['unreadCount'] as num?)?.toInt() ?? 0;
    final lastMessage = convo['lastMessage'] as Map<String, dynamic>?;

    String title = isAr ? 'محادثة' : 'Conversation';
    String typeLabel = isAr ? 'محادثة' : 'Chat';
    IconData icon = Icons.chat_rounded;
    Color iconColor = AppColors.primary;
    String? rawAvatar;
    bool isStore = false;

    if (type == 'SUPPORT') {
      typeLabel = isAr ? 'تذكرة دعم فني' : 'Support Ticket';
      title = convo['subject']?.toString() ?? (isAr ? 'الدعم الفني' : 'Support');
      icon = Icons.support_agent_rounded;
      iconColor = Colors.blue;
      rawAvatar = (convo['assignee'] is Map
              ? convo['assignee']['avatar']
              : null)
          ?.toString();
    } else if (type == 'ORDER') {
      typeLabel = isAr ? 'محادثة طلب' : 'Order Conversation';
      final orderIdStr = convo['orderId']?.toString() ?? '';
      final orderNumStr =
          convo['order']?['orderNumber']?.toString() ??
          (orderIdStr.length > 8 ? orderIdStr.substring(0, 8) : orderIdStr);
      title = isAr ? 'طلب #$orderNumStr' : 'Order #$orderNumStr';
      icon = Icons.receipt_long_rounded;
      iconColor = Colors.orange;
      rawAvatar = (convo['order']?['customer']?['user']?['avatar'] ??
              convo['order']?['vendor']?['logo'])
          ?.toString();
      if (rawAvatar == null || rawAvatar.isEmpty) {
        final vLogo = convo['order']?['vendor']?['logo']?.toString();
        if (vLogo != null && vLogo.isNotEmpty) {
          rawAvatar = vLogo;
          isStore = true;
        }
      }
    } else if (type == 'VENDOR') {
      typeLabel = isAr ? 'محادثة متجر' : 'Store Conversation';
      title = convo['vendor']?['name'] ?? (isAr ? 'متجر' : 'Store');
      icon = Icons.storefront_rounded;
      iconColor = Colors.green;
      rawAvatar =
          (convo['vendor']?['logo'] ?? convo['vendor']?['logoUrl'])?.toString();
      isStore = rawAvatar != null && rawAvatar.isNotEmpty;
    }

    if (rawAvatar == null || rawAvatar.isEmpty) {
      final participants = convo['participants'];
      if (participants is List) {
        for (final p in participants) {
          if (p is! Map) continue;
          final av = (p['avatar'] ?? p['user']?['avatar'])?.toString();
          if (av != null && av.trim().isNotEmpty) {
            rawAvatar = av.trim();
            break;
          }
        }
      }
    }
    final resolvedAvatar = ImageUtils.formatImageUrl(rawAvatar);

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
      key: ValueKey('driver_convo_$id'),
      title: title,
      typeLabel: typeLabel,
      avatarUrl: resolvedAvatar.isNotEmpty ? resolvedAvatar : null,
      isStore: isStore,
      lastMessageContent: subtitle,
      timeStr: timeStr,
      unreadCount: unreadCount,
      icon: icon,
      iconColor: iconColor,
      isSupport: type == 'SUPPORT',
      onTap: () async {
        if (type == 'ORDER') {
          await context.push('/chat/${convo['orderId'] ?? id}');
        } else {
          await context.push('/chat/$id', extra: {'title': title});
        }
        if (mounted) {
          ref.read(sharedInboxProvider.notifier).refresh();
        }
      },
    );
  }
}
