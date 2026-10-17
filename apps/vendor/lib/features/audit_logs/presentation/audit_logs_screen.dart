import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'dart:convert';
import '../data/audit_logs_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  /// Server-side action filter (null = all).
  String? _actionFilter;
  /// Client-side text query (name / email / action / entity).
  String _query = '';
  /// Client-side date window in days (null = all time).
  int? _dateDays;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditLogsProvider.notifier).loadMore();
    }
  }

  void _onActionFilterChanged(String? value) {
    setState(() => _actionFilter = value);
    ref.read(auditLogsProvider.notifier).filter(actionType: value);
  }

  /// Display name for a log's actor. Backend joins {id, name, email} —
  /// there are no firstName/lastName keys (old code always fell to email).
  static String userDisplayName(dynamic log) {
    final userRaw = log is Map ? log['user'] : null;
    final userMap = userRaw is Map ? Map<String, dynamic>.from(userRaw) : null;
    if (userMap != null) {
      final name = (userMap['name']?.toString() ?? '').trim();
      if (name.isNotEmpty) return name;
      final email = (userMap['email']?.toString() ?? '').trim();
      if (email.isNotEmpty) return email;
    }
    if (log is Map) {
      final id = (log['userId'] ?? '').toString();
      if (id.isNotEmpty) return id;
    }
    return '—';
  }

  /// Client-side text + date filtering over the loaded page(s).
  /// (Backend only supports action/entity/user filters + pagination.)
  List<dynamic> _applyLocalFilters(List<dynamic> logs) {
    final q = _query.trim().toLowerCase();
    final now = DateTime.now();
    return logs.where((log) {
      if (log is! Map) return false;
      if (q.isNotEmpty) {
        final haystack = [
          log['actionType'],
          log['entityType'],
          log['entityId'],
          log['action'],
          log['details'],
          userDisplayName(log),
          (log['user'] is Map ? (log['user'] as Map)['email'] : null),
        ].where((e) => e != null).map((e) => e.toString().toLowerCase()).join(' ');
        if (!haystack.contains(q)) return false;
      }
      if (_dateDays != null) {
        try {
          final d = DateTime.parse(log['createdAt'].toString()).toLocal();
          if (now.difference(d).inDays > _dateDays!) return false;
        } catch (_) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(auditLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.auditLogs,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.auditLogsSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCcw, size: 20),
                  tooltip: l10n.refresh,
                  onPressed: () => ref.read(auditLogsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
          // Filters (action = server-side, text + date = client-side)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'بحث بالاسم أو البريد أو الإجراء...'
                              : 'Search name, email, action...',
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(LucideIcons.x, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _actionFilter,
                        decoration: InputDecoration(
                          labelText: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'الإجراء'
                              : 'Action',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.filterAll),
                          ),
                          ...['CREATE', 'UPDATE', 'DELETE', 'OTHER'].map(
                            (a) => DropdownMenuItem<String?>(
                              value: a,
                              child: Text(
                                _actionLabel(context, l10n, a),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: _onActionFilterChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _dateChip(context, null,
                          Localizations.localeOf(context).languageCode == 'ar' ? 'الكل' : 'All'),
                      const SizedBox(width: 8),
                      _dateChip(context, 0,
                          Localizations.localeOf(context).languageCode == 'ar' ? 'اليوم' : 'Today'),
                      const SizedBox(width: 8),
                      _dateChip(context, 7,
                          Localizations.localeOf(context).languageCode == 'ar' ? 'آخر ٧ أيام' : 'Last 7 days'),
                      const SizedBox(width: 8),
                      _dateChip(context, 30,
                          Localizations.localeOf(context).languageCode == 'ar' ? 'آخر ٣٠ يوم' : 'Last 30 days'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: state.when(
              data: (data) {
                final visibleLogs = _applyLocalFilters(data.logs);
                if (visibleLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.clipboardList,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAuditLogsFound,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleLogs.length + (data.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == visibleLogs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildLogCard(context, visibleLogs[index], l10n, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(ErrorUtils.translate(context, e), style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(auditLogsProvider.notifier).refresh(),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(l10n.refresh),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    dynamic log,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return _AuditLogCard(log: log, l10n: l10n, theme: theme);
  }

  /// Localized action label for the filter dropdown (mirrors card colors).
  String _actionLabel(BuildContext context, AppLocalizations l10n, String action) {
    switch (action) {
      case 'CREATE':
        return l10n.actionCreate;
      case 'UPDATE':
        return l10n.actionUpdate;
      case 'DELETE':
        return l10n.actionDelete;
      default:
        return action;
    }
  }

  Widget _dateChip(BuildContext context, int? days, String label) {
    final selected = _dateDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _dateDays = days),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: selected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
      ),
    );
  }
}

class _AuditLogCard extends StatefulWidget {
  final dynamic log;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _AuditLogCard({required this.log, required this.l10n, required this.theme});

  @override
  State<_AuditLogCard> createState() => _AuditLogCardState();
}

class _AuditLogCardState extends State<_AuditLogCard> {
  bool _isExpanded = false;

  /// Turns backend entity names into readable labels, handling both
  /// controller-class names ("DriverShifts" -> "Driver Shifts") and raw
  /// URL paths ("/driver-shifts/admin/pools" -> "Driver Shifts Pools").
  /// UUIDs/ids are always stripped out.
  static String _prettifyEntity(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'unknown') return '';
    if (value.startsWith('/')) {
      final segments = value.split('/').where((s) =>
          s.isNotEmpty &&
          s != 'api' &&
          s != 'v1' &&
          s != 'admin' &&
          s != 'vendor' &&
          !RegExp(r'[0-9a-fA-F-]{10,}').hasMatch(s)).toList();
      if (segments.isEmpty) return '';
      return segments.map((s) {
        final cleaned = s.replaceAll(RegExp(r'[-_]'), ' ');
        if (cleaned.isEmpty) return '';
        return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
      }).join(' ');
    }
    // CamelCase controller name, e.g. DriverShifts, DriverBreak, VendorMember.
    final spaced = value
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
          (_) => ' ',
        )
        .trim();
    return spaced.isEmpty ? value : spaced;
  }

  /// Translated field labels (backend keys are English identifiers).
  static String _fieldLabel(String key, bool isArabic) {
    const labels = <String, List<String>>{
      'name': ['Name', 'الاسم'],
      'namear': ['Arabic name', 'الاسم بالعربية'],
      'title': ['Title', 'العنوان'],
      'titlear': ['Arabic title', 'العنوان بالعربية'],
      'subject': ['Subject', 'الموضوع'],
      'description': ['Description', 'الوصف'],
      'descriptionar': ['Arabic description', 'الوصف بالعربية'],
      'stock': ['Stock', 'المخزون'],
      'price': ['Price', 'السعر'],
      'baseprice': ['Price', 'السعر'],
      'compareprice': ['Compare price', 'سعر المقارنة'],
      'offerprice': ['Offer price', 'سعر العرض'],
      'originalprice': ['Original price', 'السعر الأصلي'],
      'amount': ['Amount', 'المبلغ'],
      'total': ['Total', 'الإجمالي'],
      'grandtotal': ['Total', 'الإجمالي'],
      'subtotal': ['Subtotal', 'المجموع الفرعي'],
      'tax': ['Tax', 'الضريبة'],
      'discount': ['Discount', 'الخصم'],
      'deliveryfee': ['Delivery fee', 'رسوم التوصيل'],
      'servicefee': ['Service fee', 'رسوم الخدمة'],
      'status': ['Status', 'الحالة'],
      'phone': ['Phone', 'الهاتف'],
      'email': ['Email', 'البريد'],
      'address': ['Address', 'العنوان'],
      'role': ['Role', 'الدور'],
      'category': ['Category', 'الفئة'],
      'categoryid': ['Category', 'الفئة'],
      'zone': ['Zone', 'المنطقة'],
      'zoneid': ['Zone', 'المنطقة'],
      'vendor': ['Vendor', 'المتجر'],
      'vendorid': ['Vendor', 'المتجر'],
      'product': ['Product', 'المنتج'],
      'productid': ['Product', 'المنتج'],
      'driver': ['Driver', 'السائق'],
      'driverid': ['Driver', 'السائق'],
      'order': ['Order', 'الطلب'],
      'orderid': ['Order', 'الطلب'],
      'ordernumber': ['Order number', 'رقم الطلب'],
      'branch': ['Branch', 'الفرع'],
      'branchid': ['Branch', 'الفرع'],
      'customer': ['Customer', 'العميل'],
      'customerid': ['Customer', 'العميل'],
      'user': ['User', 'المستخدم'],
      'userid': ['User', 'المستخدم'],
      'member': ['Member', 'العضو'],
      'ticket': ['Ticket', 'التذكرة'],
      'ticketnumber': ['Ticket number', 'رقم التذكرة'],
      'paymentmethod': ['Payment method', 'طريقة الدفع'],
      'paymentstatus': ['Payment status', 'حالة الدفع'],
      'starttime': ['Start time', 'وقت البداية'],
      'endtime': ['End time', 'وقت النهاية'],
      'shiftdate': ['Shift date', 'تاريخ الوردية'],
      'maxdrivers': ['Max drivers', 'الحد الأقصى للسائقين'],
      'isactive': ['Active', 'نشط'],
      'isfeatured': ['Featured', 'مميز'],
      'isopen': ['Open', 'مفتوح'],
      'canorder': ['Can order', 'يمكنه الطلب'],
      'isapproved': ['Approved', 'معتمد'],
      'isread': ['Read', 'مقروء'],
      'isbanned': ['Banned', 'محظور'],
      'hasvariants': ['Has variants', 'له أصناف'],
      'sellbystrip': ['Sell by strip', 'بيع بالشريط'],
      'tracksstock': ['Tracks stock', 'تتبع المخزون'],
      'stripsperpackage': ['Strips per package', 'شرائط للعبوة'],
      'sku': ['SKU', 'الكود'],
      'vehicletype': ['Vehicle type', 'نوع المركبة'],
      'vehicleplate': ['Plate number', 'رقم اللوحة'],
      'nationalid': ['National ID', 'الرقم القومي'],
      'licensenumber': ['License number', 'رقم الرخصة'],
      'walletbalance': ['Wallet balance', 'رصيد المحفظة'],
      'balanceafter': ['Balance after', 'الرصيد بعد'],
      'commissionrate': ['Commission', 'العمولة'],
      'rating': ['Rating', 'التقييم'],
      'sortorder': ['Sort order', 'ترتيب العرض'],
      'imageurl': ['Image', 'الصورة'],
      'iconurl': ['Icon', 'الأيقونة'],
      'logo': ['Logo', 'الشعار'],
      'coverimage': ['Cover', 'الغلاف'],
      'createdat': ['Date', 'التاريخ'],
      'updatedat': ['Updated at', 'آخر تحديث'],
      'priority': ['Priority', 'الأولوية'],
      'assigneeid': ['Assignee', 'المسؤول'],
      'type': ['Type', 'النوع'],
      'number': ['Number', 'الرقم'],
      'message': ['Message', 'الرسالة'],
      'text': ['Text', 'النص'],
    };
    final hit = labels[key.toLowerCase()];
    if (hit != null) return isArabic ? hit[1] : hit[0];
    // Fallback: camelCase/snake_case -> words.
    final words = key
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
          (_) => ' ',
        )
        .replaceAll('_', ' ')
        .trim();
    if (words.isEmpty) return key;
    return words[0].toUpperCase() + words.substring(1);
  }

  /// Display value for a diff row: `*Id` UUIDs resolve to the backend
  /// fact name when available (Category, Zone, ...) and shrink to a short
  /// id otherwise — never a 3-line UUID dump.
  static String _displayDiffValue(
    String key,
    dynamic value,
    Map<String, dynamic> facts,
    bool isAr,
  ) {
    if (value == null) return 'null';
    final str = value.toString();
    final lowerKey = key.toLowerCase();
    if ((lowerKey.endsWith('id') || lowerKey == 'id') &&
        RegExp(r'[0-9a-fA-F-]{10,}').hasMatch(str)) {
      var base = lowerKey.endsWith('id')
          ? lowerKey.substring(0, lowerKey.length - 2)
          : lowerKey;
      const aliases = {
        'user': 'Name',
        'customer': 'Name',
        'category': 'Category',
        'zone': 'Zone',
        'vendor': 'Vendor',
        'product': 'Product',
        'driver': 'Driver',
        'order': 'Order',
        'branch': 'Branch',
        'member': 'Member',
        'ticket': 'Ticket',
        'promotion': 'Promotion',
      };
      final wanted = aliases[base] ?? base;
      for (final entry in facts.entries) {
        if (entry.key.toLowerCase() == wanted.toLowerCase() &&
            entry.value != null &&
            entry.value.toString().isNotEmpty &&
            entry.value.toString() != '—') {
          return _factValue(entry.value, isAr);
        }
      }
      return str.length > 8 ? '${str.substring(0, 8)}…' : str;
    }
    return _prettyDiffValue(value, isAr);
  }

  /// Readable scalar for diff values: nested objects collapse to their
  /// display name instead of dumping `{id: ..., ...}` maps.
  static String _prettyDiffValue(dynamic value, bool isAr) {
    if (value == null) return 'null';
    final bi = _biText(value, isAr);
    if (bi != null) return bi;
    if (value is Map) {
      for (final key in [
        'name',
        'title',
        'storeName',
        'orderNumber',
        'ticketNumber',
        'email',
      ]) {
        final candidate = value[key];
        if (candidate != null && candidate.toString().isNotEmpty) {
          return candidate.toString();
        }
      }
      return value.toString();
    }
    if (value is List) {
      return value.length <= 3
          ? value.map((e) => _prettyDiffValue(e, isAr)).join(', ')
          : '${value.length} items';
    }
    if (value is bool) {
      if (isAr) return value ? 'نعم' : 'لا';
      return value ? 'Yes' : 'No';
    }
    final text = value.toString();
    if (isAr) {
      final localized = _enumLabel(text);
      if (localized != null) return localized;
    }
    return text;
  }

  /// Localized entity-type name for the badge + summary. Entity types come
  /// from controller class names (English); map the common ones to Arabic.
  static String _entityLabel(String pretty, bool isAr) {
    if (!isAr) return pretty;
    final normalized = pretty.trim().toLowerCase();
    const map = <String, String>{
      'products': 'المنتجات',
      'product': 'المنتج',
      'vendors': 'المتاجر',
      'vendor': 'المتجر',
      'drivers': 'السائقون',
      'driver': 'السائق',
      'driver shifts': 'ورديات السائقين',
      'driver shift': 'وردية السائق',
      'driver shifts pools': 'تجمعات ورديات السائقين',
      'orders': 'الطلبات',
      'order': 'الطلب',
      'users': 'المستخدمون',
      'user': 'المستخدم',
      'customers': 'العملاء',
      'customer': 'العميل',
      'menu categories': 'تصنيفات القائمة',
      'menu category': 'تصنيف القائمة',
      'categories': 'التصنيفات',
      'category': 'التصنيف',
      'vendor branches': 'فروع المتاجر',
      'vendor branch': 'فرع المتجر',
      'branches': 'الفروع',
      'branch': 'الفرع',
      'vendor members': 'أعضاء المتجر',
      'vendor member': 'عضو المتجر',
      'members': 'الأعضاء',
      'member': 'العضو',
      'vendor wallet': 'محفظة المتجر',
      'wallet': 'المحفظة',
      'vendor verticals': 'قطاعات المتاجر',
      'verticals': 'القطاعات',
      'vertical': 'القطاع',
      'promotions': 'العروض',
      'promotion': 'العرض',
      'zones': 'المناطق',
      'zone': 'المنطقة',
      'tickets': 'التذاكر',
      'ticket': 'التذكرة',
      'platform settings': 'إعدادات المنصة',
      'conversations': 'المحادثات',
      'conversation': 'المحادثة',
      'messages': 'الرسائل',
      'message': 'الرسالة',
      'notifications': 'الإشعارات',
      'notification': 'الإشعار',
      'support': 'الدعم',
      'vendorwallet': 'محفظة المتجر',
      'vendormembers': 'أعضاء المتجر',
      'vendorbranches': 'فروع المتاجر',
      'vendorverticals': 'قطاعات المتاجر',
      'menucategories': 'تصنيفات القائمة',
      'drivershifts': 'ورديات السائقين',
      'platformsettings': 'إعدادات المنصة',
    };
    return map[normalized] ?? pretty;
  }

  /// Localized label for an enriched fact key coming from the backend
  /// (keys are English display names like "Wallet balance").
  static String _factLabel(String key, bool isAr) {
    if (!isAr) return key;
    final normalized =
        key.trim().toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
    const map = <String, String>{
      'product': 'المنتج',
      'variant': 'الصنف',
      'vendor': 'المتجر',
      'store': 'المتجر',
      'category': 'التصنيف',
      'price': 'السعر',
      'branch': 'الفرع',
      'zone': 'المنطقة',
      'address': 'العنوان',
      'open': 'مفتوح',
      'approved': 'معتمد',
      'status': 'الحالة',
      'phone': 'الهاتف',
      'email': 'البريد',
      'role': 'الدور',
      'name': 'الاسم',
      'order': 'الطلب',
      'total': 'الإجمالي',
      'subtotal': 'المجموع الفرعي',
      'tax': 'الضريبة',
      'discount': 'الخصم',
      'payment': 'الدفع',
      'paymentmethod': 'طريقة الدفع',
      'paymentstatus': 'حالة الدفع',
      'walletbalance': 'رصيد المحفظة',
      'balanceafter': 'الرصيد بعد',
      'wallet': 'المحفظة',
      'maxdrivers': 'الحد الأقصى للسائقين',
      'assigneddrivers': 'السائقون المعينون',
      'date': 'التاريخ',
      'window': 'الفترة',
      'driver': 'السائق',
      'message': 'الرسالة',
      'type': 'النوع',
      'subject': 'الموضوع',
      'ticket': 'التذكرة',
      'member': 'العضو',
      'vertical': 'القطاع',
      'promotion': 'العرض',
      'amount': 'المبلغ',
      'canorder': 'يمكنه الطلب',
      'title': 'العنوان',
      'vehicle': 'المركبة',
      'stock': 'المخزون',
      'commission': 'العمولة',
      'rating': 'التقييم',
      'priority': 'الأولوية',
      'number': 'الرقم',
      'ordernumber': 'رقم الطلب',
      'ticketnumber': 'رقم التذكرة',
    };
    final hit = map[normalized];
    if (hit != null) return hit;
    return _fieldLabel(key.toLowerCase(), true);
  }

  /// Picks the right side of a bilingual `{en, ar}` value, or null when the
  /// value is not bilingual.
  static String? _biText(dynamic value, bool isAr) {
    if (value is Map && (value.containsKey('en') || value.containsKey('ar'))) {
      final en = value['en']?.toString() ?? '';
      final ar = value['ar']?.toString() ?? '';
      if (isAr) return ar.isNotEmpty ? ar : en;
      return en.isNotEmpty ? en : ar;
    }
    return null;
  }

  /// Localized fact value (backend stores booleans as "Yes"/"No", enums in
  /// upper-case English, and names as bilingual `{en, ar}`).
  static String _factValue(dynamic raw, bool isAr) {
    final value = _biText(raw, isAr) ?? (raw?.toString() ?? '—');
    if (!isAr) return value;
    final v = value.trim();
    if (v == 'Yes') return 'نعم';
    if (v == 'No') return 'لا';
    return _enumLabel(v) ?? value;
  }

  /// Arabic label for a known enum/status token, or null when not one.
  static String? _enumLabel(String value) {
    const map = <String, String>{
      // Driver / shift / order statuses
      'ONLINE': 'متصل',
      'OFFLINE': 'غير متصل',
      'ON_DELIVERY': 'في توصيلة',
      'ON_BREAK': 'في استراحة',
      'SUSPENDED': 'موقوف',
      'BUSY': 'مشغول',
      'PENDING': 'قيد الانتظار',
      'APPROVED': 'معتمد',
      'REJECTED': 'مرفوض',
      'ACTIVE': 'نشط',
      'INACTIVE': 'غير نشط',
      'CANCELLED': 'ملغي',
      'CANCELED': 'ملغي',
      'DELIVERED': 'تم التوصيل',
      'PREPARING': 'قيد التحضير',
      'READY': 'جاهز',
      'PICKED_UP': 'تم الاستلام',
      'CONFIRMED': 'مؤكد',
      'COMPLETED': 'مكتمل',
      // Payment
      'CASH_ON_DELIVERY': 'الدفع عند الاستلام',
      'MOBILE_WALLET': 'محفظة إلكترونية',
      'WALLET': 'المحفظة',
      'CARD': 'بطاقة',
      'INSTAPAY': 'إنستا باي',
      'CASH': 'نقدي',
      // Roles
      'SUPER_ADMIN': 'مدير عام',
      'ADMIN': 'مدير',
      'VENDOR_MEMBER': 'عضو متجر',
      'VENDOR': 'متجر',
      'DRIVER': 'سائق',
      'CUSTOMER': 'عميل',
      // Support / conversation
      'OPEN': 'مفتوح',
      'CLOSED': 'مغلق',
      'RESOLVED': 'تم الحل',
      'IN_PROGRESS': 'قيد المعالجة',
    };
    return map[value.trim().toUpperCase()];
  }

  /// Locale-aware timestamp. Arabic is built manually so it works without
  /// intl locale data being initialised.
  static String _formatLogDate(String raw, bool isAr) {
    try {
      final date = DateTime.parse(raw).toLocal();
      if (!isAr) return DateFormat('dd MMM yyyy – hh:mm a').format(date);
      const months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final period = date.hour < 12 ? 'ص' : 'م';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]} ${date.year} – $hour12:$minute $period';
    } catch (_) {
      return raw;
    }
  }

  /// First UUID-like token inside a raw method-plus-path action string.
  static String _extractShortId(String rawAction) {
    final match = RegExp(r'[0-9a-fA-F-]{10,}').firstMatch(rawAction);
    if (match == null) return '';
    final id = match.group(0)!;
    return id.length > 8 ? '${id.substring(0, 8)}…' : id;
  }

  /// One-line human summary of what was done, e.g.
  /// "Deleted Driver Shifts Pools" plus a short id chip.
  /// Old-vs-new field diffs (when the backend stored a body) still render
  /// below this via the regular change list.
  Widget _buildActionSummary(BuildContext context, String entityType) {
    final isAr =
        Localizations.localeOf(context).languageCode == 'ar';
    final rawAction = (widget.log is Map
            ? (widget.log as Map)['action']?.toString()
            : null) ??
        '';
    final method = rawAction.split(' ').first.toUpperCase();
    String verb;
    switch (method) {
      case 'POST':
        verb = isAr ? 'أنشأ' : 'Created';
        break;
      case 'PUT':
      case 'PATCH':
        verb = isAr ? 'عدّل' : 'Updated';
        break;
      case 'DELETE':
        verb = isAr ? 'حذف' : 'Deleted';
        break;
      default:
        verb = method.isEmpty ? (isAr ? 'إجراء' : 'Action') : method;
    }
    final entity =
        entityType.isNotEmpty ? entityType : (isAr ? 'عنصر' : 'item');
    final shortId = _extractShortId(rawAction);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text(
            '$verb $entity',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (shortId.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '#$shortId',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final l10n = widget.l10n;
    final theme = widget.theme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final String userDisplay = _AuditLogsScreenState.userDisplayName(log);

    final actionTypeRaw = (log['actionType'] ?? 'OTHER').toString();
    final String entityType = _prettifyEntity((log['entityType'] ?? '').toString());
    final String entityLabel =
        entityType.isEmpty ? '' : _entityLabel(entityType, isAr);

    // Map HTTP verbs to CRUD actions
    String actionType = actionTypeRaw.toUpperCase();
    if (actionType == 'POST') actionType = 'CREATE';
    if (actionType == 'PUT' || actionType == 'PATCH') actionType = 'UPDATE';
    if (actionType == 'GET') actionType = 'READ';

    final createdAtRaw = (log['createdAt'] ?? '').toString();
    final String createdAt = _formatLogDate(createdAtRaw, isAr);

    Map<String, dynamic> oldMap = {};
    Map<String, dynamic> newMap = {};

    if (log['oldValues'] != null) {
      if (log['oldValues'] is Map) {
        oldMap = Map<String, dynamic>.from(log['oldValues']);
      } else if (log['oldValues'] is String && log['oldValues'].toString().isNotEmpty) {
        try {
          oldMap = Map<String, dynamic>.from(jsonDecode(log['oldValues']));
        } catch (_) {}
      }
    }

    if (log['newValues'] != null) {
      if (log['newValues'] is Map) {
        newMap = Map<String, dynamic>.from(log['newValues']);
      } else if (log['newValues'] is String && log['newValues'].toString().isNotEmpty) {
        try {
          newMap = Map<String, dynamic>.from(jsonDecode(log['newValues']));
        } catch (_) {}
      }
    }

    List<Widget> changeWidgets = [];

    // Human summary instead of the raw "DELETE /driver-shifts/.../<uuid>"
    // stored by the backend: localized verb + friendly entity + short id.
    changeWidgets.add(_buildActionSummary(context, entityLabel));

    // Enriched snapshot facts from the backend (zone, driver, totals...):
    // reserved `_`-prefixed keys, shown as a professional fact list —
    // never as raw diff rows.
    if (newMap['_facts'] is Map) {
      final facts = Map<String, dynamic>.from(newMap['_facts'] as Map);
      for (final entry in facts.entries) {
        changeWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _factLabel(entry.key.toString(), isAr),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      _factValue(entry.value, isAr),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Pair up the keys to show exactly what changed (old → new).
    // Reserved `_`-prefixed keys (like `_facts`) are display-only.
    final factsMap = newMap['_facts'] is Map
        ? Map<String, dynamic>.from(newMap['_facts'] as Map)
        : <String, dynamic>{};
    final allKeys = {...oldMap.keys, ...newMap.keys}
        .where((k) => !k.toString().startsWith('_'))
        .toSet();
    for (final key in allKeys) {
      final oldVal = oldMap[key];
      final newVal = newMap[key];

      if (oldVal == newVal && oldMap.containsKey(key) && newMap.containsKey(key)) continue;

      changeWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _fieldLabel(key.toString(), isAr),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (oldMap.containsKey(key)) ...[
                        TextSpan(
                          text: _displayDiffValue(
                              key.toString(), oldVal, factsMap, isAr),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const TextSpan(text: '  →  '),
                      ],
                      if (newMap.containsKey(key))
                        TextSpan(
                          text: _displayDiffValue(
                              key.toString(), newVal, factsMap, isAr),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback for details if they exist natively but old/new don't
    if (changeWidgets.isEmpty && log['details'] != null && log['details'].toString().isNotEmpty) {
       changeWidgets.add(Text(log['details'].toString(), style: const TextStyle(fontSize: 12)));
    }

    // Action config
    Color actionColor;
    IconData actionIcon;
    String actionLabel;
    switch (actionType) {
      case 'CREATE':
        actionColor = AppColors.success;
        actionIcon = LucideIcons.plusCircle;
        actionLabel = l10n.actionCreate;
        break;
      case 'UPDATE':
        actionColor = AppColors.warning;
        actionIcon = LucideIcons.edit;
        actionLabel = l10n.actionUpdate;
        break;
      case 'DELETE':
        actionColor = AppColors.error;
        actionIcon = LucideIcons.trash2;
        actionLabel = l10n.actionDelete;
        break;
      case 'LOGIN':
        actionColor = AppColors.info;
        actionIcon = LucideIcons.logIn;
        actionLabel = l10n.actionLogin;
        break;
      case 'LOGOUT':
        actionColor = Colors.grey;
        actionIcon = LucideIcons.logOut;
        actionLabel = l10n.actionLogout;
        break;
      default:
        actionColor = AppColors.primary;
        actionIcon = LucideIcons.activity;
        actionLabel = actionType;
    }
    
    return GestureDetector(
      onTap: changeWidgets.isNotEmpty ? () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: actionColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(actionIcon, color: actionColor, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    actionLabel,
                                    style: TextStyle(
                                      color: actionColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (entityLabel.isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        entityLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                if (changeWidgets.isNotEmpty)
                                  Icon(
                                    _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(LucideIcons.user, size: 13,
                                    color: theme.colorScheme.onSurface),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${l10n.by} $userDisplay',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.clock, size: 13,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                                const SizedBox(width: 5),
                                Text(
                                  createdAt,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            if (_isExpanded && changeWidgets.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: changeWidgets,
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
            ],
          ),
        ),
      ),
    );
  }
}
