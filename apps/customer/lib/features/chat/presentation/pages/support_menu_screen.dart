import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:data/providers.dart' hide inboxCountsProvider;
import 'package:ui_kit/ui_kit.dart' show AppAdaptiveChevron, AppDialog, AppNetworkAvatar;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/image_utils.dart';
import '../providers/inbox_counts_provider.dart';
import '../providers/support_ticket_provider.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';

class SupportMenuScreen extends ConsumerStatefulWidget {
  const SupportMenuScreen({super.key});

  @override
  ConsumerState<SupportMenuScreen> createState() => _SupportMenuScreenState();
}

enum _SupportStep { category, orderPicker, subCategory }

class _SupportMenuScreenState extends ConsumerState<SupportMenuScreen> {
  _SupportStep _step = _SupportStep.category;

  String? _selectedCategory; // Arabic category key
  Map<String, dynamic>? _selectedOrder; // Full order map selected by user

  List<Map<String, dynamic>> _orders = [];
  bool _loadingOrders = false;

  List<Map<String, dynamic>> _tickets = [];
  bool _loadingTickets = false;

  // ───────── Category / SubCategory data ─────────

  final Map<String, List<String>> _categoriesAr = {
    'مشكلة في التوصيل': [
      'تأخير في التوصيل',
      'الكابتن مش بيرد',
      'الكابتن مش لاقي المكان',
      'الطلب اتسلم لحد تاني',
      'شكوى على الكابتن',
    ],
    'مشكلة في متجر / محتويات الطلب': [
      'الطلب ناقص أو غلط',
      'جودة المنتجات سيئة',
      'المتجر مغلق وهو ظاهر مفتوح',
      'السعر غلط',
    ],
    'مشكلة في الدفع': [
      'دفع InstaPay',
      'دفع فودافون كاش',
    ],
    'مشكلة في الحساب والتطبيق': [
      'مشكلة حساب/دخول',
    ],
    'طلب استرجاع/شكوى عامة': [
      'طلب استرجاع',
    ],
    'مش لاقي مشكلتي': [],
  };

  final Map<String, String> _categoryEnMapping = {
    'مشكلة في التوصيل': 'Delivery Issue',
    'مشكلة في متجر / محتويات الطلب': 'Vendor/Order Contents Issue',
    'مشكلة في الدفع': 'Payment Issue',
    'مشكلة في الحساب والتطبيق': 'Account/App Issue',
    'طلب استرجاع/شكوى عامة': 'Return/Complaint',
    'مش لاقي مشكلتي': 'Other',
  };

  final Map<String, String> _subCategoryEnMapping = {
    'تأخير في التوصيل': 'Delayed delivery',
    'الكابتن مش بيرد': 'Courier not responding',
    'الكابتن مش لاقي المكان': 'Courier lost',
    'الطلب اتسلم لحد تاني': 'Order delivered to wrong person',
    'شكوى على الكابتن': 'Courier complaint',
    'الطلب ناقص أو غلط': 'Missing or wrong items',
    'جودة المنتجات سيئة': 'Poor product quality',
    'المتجر مغلق وهو ظاهر مفتوح': 'Store closed but showing open',
    'السعر غلط': 'Wrong price',
    'دفع InstaPay': 'InstaPay Payment',
    'دفع فودافون كاش': 'Vodafone Cash Payment',
    'مشكلة حساب/دخول': 'Account/Login issue',
    'طلب استرجاع': 'Return request',
  };

  // Categories that require an order to be selected
  final Set<String> _orderRequiredCategories = {
    'مشكلة في التوصيل',
    'مشكلة في متجر / محتويات الطلب',
    'طلب استرجاع/شكوى عامة',
  };

  // ───────── Lifecycle ─────────

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTickets);
  }

  /// A ticket counts as "active" when it is neither CLOSED nor RESOLVED
  /// and still has a conversation attached.
  bool _isTicketChatActive(dynamic t) {
    if (t is! Map) return false;
    final status = (t['status']?.toString() ?? '').toUpperCase();
    if (status.isEmpty || status == 'CLOSED' || status == 'RESOLVED') {
      return false;
    }
    final convoId = t['conversationId']?.toString() ?? '';
    if (convoId.isEmpty || convoId == 'null') return false;
    return true;
  }

  Future<void> _loadTickets() async {
    if (!mounted) return;
    setState(() => _loadingTickets = true);
    try {
      final result = await ref.read(supportTicketProvider.notifier).getTickets();
      if (!mounted) return;
      setState(() {
        _tickets = result
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _tickets = []);
    } finally {
      if (mounted) setState(() => _loadingTickets = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/orders/my');
      if (!mounted) return;
      final raw = response.data['data'];
      final list = (raw is Map ? raw['orders'] : raw) as List? ?? [];
      setState(() {
        _orders = list
            .whereType<Map<String, dynamic>>()
            .where((o) {
              final t = o['type']?.toString().toUpperCase();
              return t != 'CUSTOM_DELIVERY' && t != 'RIDE';
            })
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _orders = []);
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  // ───────── Navigation helpers ─────────

  void _onCategoryTapped(String categoryAr) {
    setState(() => _selectedCategory = categoryAr);

    final subList = _categoriesAr[categoryAr] ?? [];

    if (_orderRequiredCategories.contains(categoryAr)) {
      // Go to order picker first
      setState(() => _step = _SupportStep.orderPicker);
      _loadOrders();
    } else if (subList.isEmpty) {
      // No sub-categories and no order needed → create directly
      _createTicket(categoryAr, null);
    } else {
      setState(() => _step = _SupportStep.subCategory);
    }
  }

  void _onOrderSelected(Map<String, dynamic> order) {
    setState(() {
      _selectedOrder = order;
      final subList = _categoriesAr[_selectedCategory!] ?? [];
      if (subList.isNotEmpty) {
        _step = _SupportStep.subCategory;
      }
    });

    final subList = _categoriesAr[_selectedCategory!] ?? [];
    if (subList.isEmpty) {
      _createTicket(_selectedCategory!, null);
    }
  }

  void _onSubCategoryTapped(String subAr) {
    _createTicket(_selectedCategory!, subAr);
  }

  void _goBack() {
    setState(() {
      if (_step == _SupportStep.subCategory) {
        if (_orderRequiredCategories.contains(_selectedCategory)) {
          _step = _SupportStep.orderPicker;
        } else {
          _step = _SupportStep.category;
          _selectedCategory = null;
        }
      } else if (_step == _SupportStep.orderPicker) {
        _step = _SupportStep.category;
        _selectedCategory = null;
        _selectedOrder = null;
      }
    });
  }

  String _formatTicketNumber(dynamic rawNum) {
    if (rawNum == null) return '';
    return 'A${rawNum.toString().padLeft(5, '0')}';
  }

  String _buildTicketChatTitle(Map<String, dynamic> ticket, bool isAr) {
    final numStr = _formatTicketNumber(ticket['ticketNumber']);
    final subject = ticket['subject']?.toString().trim() ?? '';
    if (numStr.isNotEmpty && subject.isNotEmpty) {
      return '#$numStr • $subject';
    }
    if (subject.isNotEmpty) return subject;
    if (numStr.isNotEmpty) {
      return isAr ? 'تذكرة #$numStr' : 'Ticket #$numStr';
    }
    return isAr ? 'الدعم الفني' : 'Technical Support';
  }

  Future<void> _openTicketConversation(
    Map<String, dynamic> ticket,
    bool isAr,
  ) async {
    final convoId = ticket['conversationId']?.toString() ?? '';
    if (convoId.isEmpty || convoId == 'null') return;
    final title = _buildTicketChatTitle(ticket, isAr);
    final orderId = (ticket['orderId'] ?? ticket['order']?['id'])?.toString();
    await context.push(
      '/chat/support/$convoId',
      extra: {
        'title': title,
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      },
    );
    if (mounted) {
      _loadTickets();
      ref.read(sharedInboxProvider.notifier).refresh();
      ref.read(inboxCountsProvider.notifier).refresh();
    }
  }

  // ───────── Ticket creation ─────────

  Future<void> _createTicket(String categoryAr, String? subAr) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    String categoryEnum;
    switch (categoryAr) {
      case 'مشكلة في التوصيل':
        categoryEnum = 'DELIVERY';
        break;
      case 'مشكلة في متجر / محتويات الطلب':
        categoryEnum = 'VENDOR';
        break;
      case 'مشكلة في الدفع':
        categoryEnum = 'PAYMENT';
        break;
      case 'مشكلة في الحساب والتطبيق':
        categoryEnum = 'ACCOUNT';
        break;
      case 'طلب استرجاع/شكوى عامة':
        categoryEnum = 'VENDOR';
        break;
      default:
        categoryEnum = 'OTHER';
    }

    final subCategory =
        subAr != null ? (_subCategoryEnMapping[subAr] ?? subAr) : null;
    final subject = isAr
        ? (subAr ?? categoryAr)
        : (subCategory ?? _categoryEnMapping[categoryAr] ?? categoryAr);

    // Extract orderId & vendorId from the selected order
    final orderId = _selectedOrder?['id']?.toString();
    final vendorId = _selectedOrder?['vendorId']?.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        maxWidth: 320,
        canPop: false,
        showDividers: false,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isAr ? 'جاري فتح تذكرة الدعم...' : 'Creating support ticket...',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final tickets = await ref.read(supportTicketProvider.notifier).getTickets();
      if (!mounted) return;
      for (final t in tickets) {
        if (_isTicketChatActive(t) && t is Map) {
          final existingId = t['id']?.toString();
          if (existingId != null && existingId.isNotEmpty) {
            await ref.read(supportTicketProvider.notifier).closeTicket(existingId);
            if (!mounted) return;
          }
        }
      }

      final ticket = await ref.read(supportTicketProvider.notifier).createTicket(
            subject: subject,
            category: categoryEnum,
            subCategory: subAr ?? subCategory,
            orderId: orderId,
            vendorId: vendorId,
          );
      if (!mounted) return;

      // Ensure Conversations List and unread counts reflect the new ticket conversation
      ref.read(sharedInboxProvider.notifier).refresh();
      ref.read(inboxCountsProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        final convoId = ticket['conversationId']?.toString() ?? '';
        final chatTitle = _buildTicketChatTitle(
          {...ticket, 'subject': ticket['subject'] ?? subject},
          isAr,
        );
        if (convoId.isNotEmpty && convoId != 'null') {
          context.pushReplacement(
            '/chat/support/$convoId',
            extra: {
              'title': chatTitle,
              if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
            },
          );
        } else {
          await _loadTickets();
          if (!mounted) return;
          setState(() {
            _step = _SupportStep.category;
            _selectedCategory = null;
            _selectedOrder = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ───────── Build ─────────

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: _step != _SupportStep.category
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _goBack,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
        title: Text(
          _stepTitle(isAr),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildStepProgress(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _buildStep(isAr, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(bool isAr) {
    switch (_step) {
      case _SupportStep.category:
        return isAr ? 'الدعم الفني' : 'Technical Support';
      case _SupportStep.orderPicker:
        return isAr ? 'اختار الطلب' : 'Select Order';
      case _SupportStep.subCategory:
        return isAr ? 'تفاصيل المشكلة' : 'Issue Details';
    }
  }

  Widget _buildStepProgress() {
    final bool needsOrder = _selectedCategory == null ||
        _orderRequiredCategories.contains(_selectedCategory);
    final int totalSteps = needsOrder ? 3 : 2;

    final int currentIdx;
    switch (_step) {
      case _SupportStep.category:
        currentIdx = 0;
        break;
      case _SupportStep.orderPicker:
        currentIdx = 1;
        break;
      case _SupportStep.subCategory:
        currentIdx = needsOrder ? 2 : 1;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final segIdx = i ~/ 2;
            final segDone = segIdx < currentIdx;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color: segDone
                    ? AppColors.primary
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }

          final dotIdx = i ~/ 2;
          final isDoneOrCurrent = dotIdx <= currentIdx;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDoneOrCurrent ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isDoneOrCurrent
                    ? AppColors.primary
                    : Colors.grey.withValues(alpha: 0.35),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: isDoneOrCurrent
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                : null,
          );
        }),
      ),
    );
  }

  Widget _buildStep(bool isAr, bool isDark) {
    switch (_step) {
      case _SupportStep.category:
        return _buildCategoryStep(isAr, isDark);
      case _SupportStep.orderPicker:
        return _buildOrderPickerStep(isAr, isDark);
      case _SupportStep.subCategory:
        return _buildSubCategoryStep(isAr, isDark);
    }
  }

  // ── Step 1: Category + Active Ticket + Ticket History ──

  Widget _buildCategoryStep(bool isAr, bool isDark) {
    final activeTickets =
        _tickets.where((t) => _isTicketChatActive(t)).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadTickets,
      child: ListView(
        key: const ValueKey('category'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (activeTickets.isNotEmpty) ...[
            _buildActiveTicketBanner(activeTickets.first, isAr, isDark),
            const SizedBox(height: 20),
          ],
          _buildStepHeader(
            icon: LucideIcons.helpCircle,
            title: isAr
                ? 'أهلاً! كيف يمكننا مساعدتك؟'
                : 'Hello! How can we help you?',
            subtitle: isAr
                ? 'اختار نوع المشكلة لفتح تذكرة دعم جديدة'
                : 'Select your issue type to open a support ticket',
          ),
          ..._categoriesAr.keys.map((catAr) {
            final catEn = _categoryEnMapping[catAr] ?? catAr;
            return _buildTile(
              title: isAr ? catAr : catEn,
              icon: _getCategoryIcon(catAr),
              onTap: () => _onCategoryTapped(catAr),
              trailing: _orderRequiredCategories.contains(catAr)
                  ? _buildBadge(
                      isAr ? 'يحتاج طلب' : 'Needs order',
                      AppColors.primary,
                    )
                  : null,
            );
          }),
          if (_loadingTickets && _tickets.isEmpty) ...[
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ] else if (_tickets.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'تذاكر الدعم السابقة والحالية' : 'My Support Tickets',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${_tickets.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._tickets.map((t) => _buildTicketHistoryTile(t, isAr, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTicketBanner(
    Map<String, dynamic> ticket,
    bool isAr,
    bool isDark,
  ) {
    final numStr = _formatTicketNumber(ticket['ticketNumber']);
    final subject = ticket['subject']?.toString() ??
        (isAr ? 'تذكرة دعم نشطة' : 'Active Support Ticket');
    final status = (ticket['status']?.toString() ?? 'OPEN').toUpperCase();
    final statusColor = _ticketStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'تذكرة دعم نشطة ${numStr.isNotEmpty ? "#$numStr" : ""}'
                          : 'Active Ticket ${numStr.isNotEmpty ? "#$numStr" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildBadge(_ticketStatusLabel(status, isAr), statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openTicketConversation(ticket, isAr),
                icon: const Icon(LucideIcons.messageSquare, size: 16),
                label: Text(isAr ? 'فتح المحادثة' : 'Open Conversation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showTicketDetailsSheet(ticket, isAr, isDark),
                icon: const Icon(LucideIcons.info, size: 16),
                label: Text(isAr ? 'تفاصيل التذكرة' : 'Ticket Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHistoryTile(
    Map<String, dynamic> ticket,
    bool isAr,
    bool isDark,
  ) {
    final numStr = _formatTicketNumber(ticket['ticketNumber']);
    final subject = ticket['subject']?.toString() ??
        (isAr ? 'تذكرة دعم' : 'Support Ticket');
    final status = (ticket['status']?.toString() ?? 'OPEN').toUpperCase();
    final isActive = _isTicketChatActive(ticket);
    final statusColor = _ticketStatusColor(status);
    final createdAtStr = ticket['createdAt']?.toString();
    String dateLabel = '';
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        dateLabel = DateFormat('yyyy/MM/dd • hh:mm a')
            .format(DateTime.parse(createdAtStr).toLocal());
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showTicketDetailsSheet(ticket, isAr, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.grey.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          numStr.isNotEmpty ? '#$numStr' : subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(_ticketStatusLabel(status, isAr), statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetailsSheet(
    Map<String, dynamic> ticket,
    bool isAr,
    bool isDark,
  ) {
    final numStr = _formatTicketNumber(ticket['ticketNumber']);
    final subject = ticket['subject']?.toString() ?? '';
    final category = ticket['category']?.toString() ?? '';
    final subCategory = ticket['subCategory']?.toString() ?? '';
    final status = (ticket['status']?.toString() ?? 'OPEN').toUpperCase();
    final isActive = _isTicketChatActive(ticket);
    final orderNum = ticket['order']?['orderNumber']?.toString();
    final createdAtStr = ticket['createdAt']?.toString();
    String dateLabel = '';
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        dateLabel = DateFormat('yyyy/MM/dd • hh:mm a')
            .format(DateTime.parse(createdAtStr).toLocal());
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      numStr.isNotEmpty
                          ? (isAr ? 'تذكرة #$numStr' : 'Ticket #$numStr')
                          : (isAr ? 'تفاصيل التذكرة' : 'Ticket Details'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _buildBadge(
                    _ticketStatusLabel(status, isAr),
                    _ticketStatusColor(status),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                isAr ? 'الموضوع' : 'Subject',
                subject,
              ),
              if (category.isNotEmpty)
                _buildDetailRow(
                  isAr ? 'التصنيف' : 'Category',
                  category,
                ),
              if (subCategory.isNotEmpty && subCategory != subject)
                _buildDetailRow(
                  isAr ? 'التفاصيل' : 'Subcategory',
                  subCategory,
                ),
              if (orderNum != null && orderNum.isNotEmpty)
                _buildDetailRow(
                  isAr ? 'رقم الطلب' : 'Order Number',
                  '#$orderNum',
                ),
              if (dateLabel.isNotEmpty)
                _buildDetailRow(
                  isAr ? 'تاريخ الإنشاء' : 'Created At',
                  dateLabel,
                ),
              const SizedBox(height: 20),
              if (isActive)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openTicketConversation(ticket, isAr);
                        },
                        icon: const Icon(LucideIcons.messageSquare, size: 18),
                        label: Text(
                          isAr ? 'فتح المحادثة' : 'Open Conversation',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ticketStatusLabel(String status, bool isAr) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return isAr ? 'مفتوحة' : 'Open';
      case 'IN_PROGRESS':
        return isAr ? 'قيد المراجعة' : 'In Progress';
      case 'WAITING_ON_USER':
        return isAr ? 'بانتظار ردك' : 'Waiting on You';
      case 'ESCALATED':
        return isAr ? 'تم التصعيد' : 'Escalated';
      case 'RESOLVED':
        return isAr ? 'تم الحل' : 'Resolved';
      case 'CLOSED':
        return isAr ? 'مغلقة' : 'Closed';
      default:
        return status;
    }
  }

  Color _ticketStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
      case 'WAITING_ON_USER':
        return Colors.orange;
      case 'ESCALATED':
        return Colors.purple;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  // ── Step 2: Order picker ──

  Widget _buildOrderPickerStep(bool isAr, bool isDark) {
    if (_loadingOrders) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        key: const ValueKey('no-orders'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.shoppingBag,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'لا توجد طلبات سابقة' : 'No previous orders found',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'يجب أن تكون لديك طلبات سابقة لفتح تذكرة دعم'
                    : 'You need previous orders to open a support ticket',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      key: const ValueKey('order-picker'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _buildStepHeader(
          icon: LucideIcons.receipt,
          title: isAr
              ? 'اختار الطلب المتعلق بالمشكلة'
              : 'Select the related order',
          subtitle: isAr
              ? 'سيتم إرسال التذكرة مع تفاصيل طلبك'
              : 'The ticket will be sent with your order details',
        ),
        ..._orders.map((order) => _buildOrderTile(order, isAr, isDark)),
      ],
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order, bool isAr, bool isDark) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final vendorName = order['vendorName']?.toString() ??
        order['vendor']?['storeName']?.toString() ??
        (isAr ? 'متجر' : 'Store');
    final status = order['status']?.toString() ?? '';
    final orderId = order['id']?.toString() ?? '';
    final shortId =
        order['orderNumber'] ?? orderId.split('-').last.toUpperCase();

    final isSelected = _selectedOrder?['id'] == order['id'];
    final vendorLogo = (order['vendorLogo'] ??
            (order['vendor'] is Map
                ? (order['vendor']['logo'] ?? order['vendor']['logoUrl'])
                : null))
        ?.toString();

    return GestureDetector(
      onTap: () => _onOrderSelected(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            AppNetworkAvatar(
              imageUrl: ImageUtils.formatImageUrl(vendorLogo),
              size: 44,
              borderRadius: 12,
              fallbackIcon: LucideIcons.shoppingBag,
              fallbackIconSize: 20,
              backgroundColor: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${isAr ? 'طلب' : 'Order'} #$shortId • ${items.length} ${isAr ? 'عناصر' : 'items'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Sub-category ──

  Widget _buildSubCategoryStep(bool isAr, bool isDark) {
    final subList = _categoriesAr[_selectedCategory!] ?? [];
    final catEn = _categoryEnMapping[_selectedCategory!] ?? '';

    return ListView(
      key: const ValueKey('sub-category'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (_selectedOrder != null)
          _buildSelectedOrderSummary(_selectedOrder!, isAr, isDark),
        _buildStepHeader(
          icon: LucideIcons.listChecks,
          title: isAr ? 'ما هي المشكلة تحديداً؟' : 'What is the specific issue?',
          subtitle: isAr ? _selectedCategory! : catEn,
        ),
        ...subList.map((subAr) {
          final subEn = _subCategoryEnMapping[subAr] ?? subAr;
          return _buildTile(
            title: isAr ? subAr : subEn,
            icon: Icons.chevron_right_rounded,
            onTap: () => _onSubCategoryTapped(subAr),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedOrderSummary(
    Map<String, dynamic> order,
    bool isAr,
    bool isDark,
  ) {
    final vendorName = order['vendorName']?.toString() ??
        order['vendor']?['storeName']?.toString() ??
        (isAr ? 'متجر' : 'Store');
    final orderId = order['id']?.toString() ?? '';
    final shortId =
        order['orderNumber'] ?? orderId.split('-').last.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.receipt, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${isAr ? 'الطلب المختار' : 'Selected Order'}: $vendorName – #$shortId',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── Reusable widgets ─────────

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Flexible(fit: FlexFit.loose, child: trailing),
            ],
            const SizedBox(width: 4),
            const AppAdaptiveChevron(size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryAr) {
    switch (categoryAr) {
      case 'مشكلة في التوصيل':
        return LucideIcons.truck;
      case 'مشكلة في متجر / محتويات الطلب':
        return LucideIcons.store;
      case 'مشكلة في الدفع':
        return LucideIcons.creditCard;
      case 'مشكلة في الحساب والتطبيق':
        return LucideIcons.user;
      case 'طلب استرجاع/شكوى عامة':
        return LucideIcons.messageSquare;
      default:
        return LucideIcons.helpCircle;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      case 'PREPARING':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }
}

