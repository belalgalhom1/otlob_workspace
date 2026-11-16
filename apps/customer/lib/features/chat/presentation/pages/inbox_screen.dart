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
  String _selectedFilter = 'ALL';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'المحادثات' : 'Conversations',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildFilterChips(context, isAr, inboxState.conversations),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(sharedInboxProvider.notifier).refresh();
                  await ref.read(inboxCountsProvider.notifier).refresh();
                },
                child: _buildBodyContent(context, inboxState, isDark, isAr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    bool isAr,
    List<dynamic> allConvos,
  ) {
    final hasOtherTypes = allConvos.any((c) {
      if (c is! Map) return false;
      final t = (c['type'] as String?)?.toUpperCase() ?? '';
      return t.isNotEmpty && t != 'ORDER' && t != 'SUPPORT';
    });

    final filters = [
      {'key': 'ALL', 'label': isAr ? 'الكل' : 'All'},
      {'key': 'ORDER', 'label': isAr ? 'الطلبات' : 'Orders'},
      {'key': 'SUPPORT', 'label': isAr ? 'تذاكر الدعم' : 'Support Tickets'},
      if (hasOtherTypes)
        {'key': 'OTHER', 'label': isAr ? 'المتاجر وأخرى' : 'Stores & Other'},
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return ChoiceChip(
            label: Text(f['label']!),
            selected: isSelected,
            onSelected: (val) {
              if (val) setState(() => _selectedFilter = f['key']!);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    dynamic inboxState,
    bool isDark,
    bool isAr,
  ) {
    final allConvos = inboxState.conversations as List<dynamic>;
    final convos = _selectedFilter == 'ALL'
        ? allConvos
        : allConvos.where((c) {
            final t = (c['type'] as String?)?.toUpperCase() ?? '';
            if (_selectedFilter == 'OTHER') {
              return t != 'ORDER' && t != 'SUPPORT';
            }
            return t == _selectedFilter;
          }).toList();

    if (inboxState.isLoading && allConvos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (inboxState.error != null && allConvos.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
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
                    isAr ? 'فشل تحميل المحادثات' : 'Failed to load conversations',
                    textAlign: TextAlign.center,
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
            ),
          ),
        ),
      );
    }
    if (allConvos.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.grey.withValues(alpha: 0.3),
                    size: 84,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'لا توجد محادثات بعد' : 'No conversations yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (convos.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_off_rounded,
                    color: Colors.grey.withValues(alpha: 0.3),
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? 'لا توجد محادثات مطابقة للتصفية'
                        : 'No conversations in this filter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _selectedFilter = 'ALL'),
                    child: Text(isAr ? 'عرض الكل' : 'Show All'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount:
          convos.length +
          (_selectedFilter == 'ALL' && inboxState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == convos.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }
        final convo = Map<String, dynamic>.from(convos[index] as Map);
        return _buildConversationItem(context, convo);
      },
    );
  }

  String? _resolveParticipantName(Map<String, dynamic> convo, String type, bool isAr) {
    final participants = convo['participants'];
    final List<String> names = [];

    if (type == 'SUPPORT') {
      final assignee = convo['assignee'];
      if (assignee is Map && assignee['name'] != null && assignee['name'].toString().trim().isNotEmpty) {
        names.add(assignee['name'].toString().trim());
      } else if (participants is List) {
        for (final p in participants) {
          if (p is! Map) continue;
          final role = (p['role'] ?? p['user']?['role'])?.toString().toUpperCase() ?? '';
          final name = (p['name'] ?? p['user']?['name'])?.toString().trim() ?? '';
          if (role != 'CUSTOMER' && name.isNotEmpty) {
            names.add(name);
            break;
          }
        }
      }
      if (names.isEmpty) {
        names.add(isAr ? 'فريق الدعم الفني' : 'Support Team');
      }
      final orderNum = convo['order']?['orderNumber']?.toString();
      if (orderNum != null && orderNum.isNotEmpty) {
        names.add(isAr ? 'طلب #$orderNum' : 'Order #$orderNum');
      }
      return names.join(' • ');
    }

    if (type == 'ORDER') {
      final vendorName = isAr
          ? (convo['vendorNameAr'] ??
              convo['vendorName'] ??
              convo['order']?['vendor']?['storeNameAr'] ??
              convo['order']?['vendor']?['storeName'] ??
              convo['vendor']?['name'])
          : (convo['vendorName'] ??
              convo['vendorNameAr'] ??
              convo['order']?['vendor']?['storeName'] ??
              convo['vendor']?['name']);
      if (vendorName != null && vendorName.toString().trim().isNotEmpty) {
        names.add(vendorName.toString().trim());
      }

      if (participants is List) {
        for (final p in participants) {
          if (p is! Map) continue;
          final role = (p['role'] ?? p['user']?['role'])?.toString().toUpperCase() ?? '';
          final name = (p['name'] ?? p['user']?['name'])?.toString().trim() ?? '';
          if (role != 'CUSTOMER' && name.isNotEmpty && !names.contains(name)) {
            names.add(name);
          }
        }
      }
      return names.isNotEmpty ? names.join(' • ') : null;
    }

    if (participants is List) {
      for (final p in participants) {
        if (p is! Map) continue;
        final role = (p['role'] ?? p['user']?['role'])?.toString().toUpperCase() ?? '';
        final name = (p['name'] ?? p['user']?['name'])?.toString().trim() ?? '';
        if (role != 'CUSTOMER' && name.isNotEmpty && !names.contains(name)) {
          names.add(name);
        }
      }
    }
    return names.isNotEmpty ? names.join(' • ') : null;
  }

  String _formatTimestamp(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (now.difference(date).inDays == 0 && now.day == date.day) {
        return DateFormat.jm().format(date);
      } else if (now.difference(date).inDays < 7) {
        return DateFormat('EEE').format(date);
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  Widget _buildConversationItem(
    BuildContext context,
    Map<String, dynamic> convo,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final id = convo['id']?.toString() ?? '';
    final type = (convo['type'] as String? ?? 'UNKNOWN').toUpperCase();
    final unreadCount = (convo['unreadCount'] as num?)?.toInt() ?? 0;
    final lastMessage = convo['lastMessage'] is Map
        ? Map<String, dynamic>.from(convo['lastMessage'] as Map)
        : null;

    String title = isAr ? 'محادثة' : 'Conversation';
    String typeLabel = isAr ? 'محادثة' : 'Chat';
    IconData icon = Icons.chat_rounded;
    Color iconColor = AppColors.primary;

    if (type == 'SUPPORT') {
      typeLabel = isAr ? 'تذكرة دعم فني' : 'Support Ticket';
      final rawTicketNum = convo['ticketNumber'];
      final ticketNumStr = rawTicketNum != null
          ? 'A${rawTicketNum.toString().padLeft(5, '0')}'
          : null;
      final subject = convo['subject']?.toString().trim();
      if (ticketNumStr != null && subject != null && subject.isNotEmpty) {
        title = '#$ticketNumStr • $subject';
      } else if (subject != null && subject.isNotEmpty) {
        title = subject;
      } else if (ticketNumStr != null) {
        title = isAr ? 'تذكرة #$ticketNumStr' : 'Ticket #$ticketNumStr';
      } else {
        title = isAr ? 'الدعم الفني' : 'Technical Support';
      }
      icon = Icons.support_agent_rounded;
      iconColor = Colors.blue;
    } else if (type == 'ORDER') {
      typeLabel = isAr ? 'محادثة طلب' : 'Order Conversation';
      final rawOrderNum = convo['order']?['orderNumber'];
      final fallbackOrderId = convo['orderId']?.toString() ?? '';
      final orderNumStr = rawOrderNum != null
          ? rawOrderNum.toString()
          : (fallbackOrderId.length >= 8
              ? fallbackOrderId.substring(0, 8)
              : fallbackOrderId);
      title = orderNumStr.isNotEmpty
          ? (isAr ? 'طلب #$orderNumStr' : 'Order #$orderNumStr')
          : (isAr ? 'محادثة طلب' : 'Order Conversation');
      icon = Icons.receipt_long_rounded;
      iconColor = Colors.orange;
    } else if (type == 'VENDOR') {
      typeLabel = isAr ? 'محادثة متجر' : 'Store Conversation';
      final vendorName = isAr
          ? (convo['vendorNameAr'] ??
              convo['vendorName'] ??
              convo['vendor']?['storeNameAr'] ??
              convo['vendor']?['storeName'] ??
              convo['vendor']?['name'])
          : (convo['vendorName'] ??
              convo['vendorNameAr'] ??
              convo['vendor']?['storeName'] ??
              convo['vendor']?['name']);
      title = vendorName?.toString() ?? (isAr ? 'متجر' : 'Store');
      icon = Icons.storefront_rounded;
      iconColor = Colors.green;
    } else {
      typeLabel = isAr ? 'محادثة مباشرة' : 'Direct Conversation';
    }

    final participantName = _resolveParticipantName(convo, type, isAr);

    String subtitle = isAr ? 'لا توجد رسائل' : 'No messages';
    String timeStr = '';

    if (lastMessage != null) {
      final text = lastMessage['text'];
      subtitle = (text != null && text.toString().isNotEmpty)
          ? text.toString()
          : (isAr ? 'مرفق' : 'Attachment');
      timeStr = _formatTimestamp(lastMessage['createdAt']?.toString());
    } else {
      timeStr = _formatTimestamp(
        (convo['updatedAt'] ?? convo['createdAt'])?.toString(),
      );
    }

    return InboxConversationTile(
      key: ValueKey('convo_$id'),
      title: title,
      typeLabel: typeLabel,
      participantName: participantName,
      lastMessageContent: subtitle,
      timeStr: timeStr,
      unreadCount: unreadCount,
      icon: icon,
      iconColor: iconColor,
      isSupport: type == 'SUPPORT',
      onTap: () async {
        final routeType = type.toLowerCase();
        await context.push(
          '/chat/$routeType/$id',
          extra: {
            'title': title,
            'orderId': convo['orderId'] ?? convo['order']?['id'],
          },
        );
        if (mounted) {
          ref.read(sharedInboxProvider.notifier).refresh();
          ref.read(inboxCountsProvider.notifier).refresh();
        }
      },
    );
  }
}

