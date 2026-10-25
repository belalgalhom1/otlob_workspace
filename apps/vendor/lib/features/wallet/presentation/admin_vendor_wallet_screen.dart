import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import 'package:vendor/core/providers.dart';

typedef AdminVendorWalletArgs = ({
  String vendorId,
  String? type,
  String? from,
  String? to,
  int page,
});

const int _adminVendorWalletPageSize = 20;

final adminVendorWalletProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, AdminVendorWalletArgs>((ref, args) async {
  final repo = ref.watch(adminVendorWalletRepositoryProvider);

  final results = await Future.wait<dynamic>([
    repo.vendorWalletAdminGetBalance(args.vendorId),
    repo.vendorWalletAdminListTransactions(
      args.vendorId,
      type: args.type,
      from: args.from,
      to: args.to,
      page: args.page,
      limit: _adminVendorWalletPageSize,
    ),
    repo.vendorWalletAdminGetSummary(
      args.vendorId,
      type: args.type,
      from: args.from,
      to: args.to,
    ),
  ]);

  final balance = results[0];
  final transactions = results[1];
  final summary = results[2];

  final list = transactions is Map && transactions['transactions'] is List
      ? transactions['transactions'] as List
      : transactions is List
          ? transactions
          : const [];

  final totalPages = transactions is Map &&
          transactions['totalPages'] is num
      ? (transactions['totalPages'] as num).toInt()
      : 1;
  final page = transactions is Map && transactions['page'] is num
      ? (transactions['page'] as num).toInt()
      : args.page;
  final total = transactions is Map && transactions['total'] is num
      ? (transactions['total'] as num).toInt()
      : list.length;

  return {
    'balance': balance is Map
        ? balance
        : {'walletBalance': balance ?? 0},
    'summary': summary is Map ? summary : <String, dynamic>{},
    'transactions': list,
    'page': page,
    'totalPages': totalPages,
    'total': total,
  };
});

class AdminVendorWalletScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String? vendorName;

  const AdminVendorWalletScreen({
    super.key,
    required this.vendorId,
    this.vendorName,
  });

  @override
  ConsumerState<AdminVendorWalletScreen> createState() =>
      _AdminVendorWalletScreenState();
}

class _AdminVendorWalletScreenState
    extends ConsumerState<AdminVendorWalletScreen> {
  static const _types = <String>[
    'ORDER_REVENUE',
    'COMMISSION_DEDUCTION',
    'CASH_COLLECTED',
    'PAYOUT',
    'REFUND',
    'ADJUSTMENT',
  ];

  String? _type;
  DateTime? _from;
  DateTime? _to;
  int _page = 1;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _typeLabel(String type) {
    switch (type) {
      case 'ORDER_REVENUE':
        return _isArabic ? 'إيراد طلب' : 'Order Revenue';
      case 'COMMISSION_DEDUCTION':
        return _isArabic ? 'خصم عمولة' : 'Commission';
      case 'CASH_COLLECTED':
        return _isArabic ? 'تحصيل نقدي' : 'Cash Collected';
      case 'PAYOUT':
        return _isArabic ? 'مدفوعات' : 'Payout';
      case 'REFUND':
        return _isArabic ? 'استرداد' : 'Refund';
      case 'ADJUSTMENT':
        return _isArabic ? 'تسوية' : 'Adjustment';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String? _dateParam(DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  AdminVendorWalletArgs get _args => (
        vendorId: widget.vendorId,
        type: _type,
        from: _dateParam(_from),
        to: _dateParam(_to),
        page: _page,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(adminVendorWalletProvider(_args));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '${_isArabic ? 'محفظة' : 'Wallet'}'
          '${widget.vendorName != null ? ' - ${widget.vendorName}' : ''}',
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('$err', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(adminVendorWalletProvider(_args)),
                child: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final balanceData = data['balance'] is Map
              ? data['balance'] as Map<String, dynamic>
              : <String, dynamic>{};
          final balance = double.tryParse(
                  (balanceData['walletBalance'] ??
                          balanceData['balance'] ??
                          '0')
                      .toString()) ??
              0;
          final summary = data['summary'] is Map
              ? data['summary'] as Map<String, dynamic>
              : <String, dynamic>{};
          final transactions = data['transactions'] as List;
          final currentPage = (data['page'] as num?)?.toInt() ?? _page;
          final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminVendorWalletProvider(_args)),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _balanceCard(context, theme, balance),
                const SizedBox(height: 16),
                _filters(context, theme),
                const SizedBox(height: 16),
                if (summary.isNotEmpty) _summary(context, theme, summary),
                const SizedBox(height: 24),
                Text(
                  _isArabic ? 'المعاملات' : 'Transactions',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _isArabic ? 'لا توجد معاملات' : 'No transactions yet',
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  )
                else ...[
                  ...transactions.map((tx) => _txCard(context, theme, tx)),
                  _pager(theme, currentPage, totalPages),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters(BuildContext context, ThemeData theme) {
    final dateLabel = _from == null && _to == null
        ? (_isArabic ? 'كل التواريخ' : 'All dates')
        : '${_from != null ? DateFormat('yyyy-MM-dd').format(_from!) : '...'}'
            ' - '
            '${_to != null ? DateFormat('yyyy-MM-dd').format(_to!) : '...'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 210,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _isArabic ? 'نوع المعاملة' : 'Transaction type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _type,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(_isArabic ? 'كل الأنواع' : 'All types'),
                    ),
                    ..._types.map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _page = 1;
                  }),
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _from != null && _to != null
                    ? DateTimeRange(start: _from!, end: _to!)
                    : null,
              );
              if (range != null) {
                setState(() {
                  _from = range.start;
                  _to = range.end;
                  _page = 1;
                });
              }
            },
            icon: const Icon(LucideIcons.calendar, size: 18),
            label: Text(dateLabel),
          ),
          if (_type != null || _from != null || _to != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _type = null;
                _from = null;
                _to = null;
                _page = 1;
              }),
              icon: const Icon(LucideIcons.x, size: 18),
              label: Text(_isArabic ? 'مسح الفلاتر' : 'Clear filters'),
            ),
        ],
      ),
    );
  }

  Widget _pager(ThemeData theme, int currentPage, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              onPressed:
                  currentPage > 1 ? () => setState(() => _page--) : null,
              tooltip: _isArabic ? 'السابق' : 'Previous',
              icon: const Icon(LucideIcons.chevronLeft, size: 18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isArabic
                    ? 'صفحة $currentPage من $totalPages'
                    : 'Page $currentPage of $totalPages',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            IconButton.outlined(
              onPressed:
                  currentPage < totalPages ? () => setState(() => _page++) : null,
              tooltip: _isArabic ? 'التالي' : 'Next',
              icon: const Icon(LucideIcons.chevronRight, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(BuildContext context, ThemeData theme, double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isArabic ? 'الرصيد المتاح' : 'Available Balance',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            '${balance.toStringAsFixed(2)} EGP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
      BuildContext context, ThemeData theme, Map<String, dynamic> summary) {
    final credits =
        double.tryParse(summary['totalCredits']?.toString() ?? '0') ?? 0;
    final debits =
        double.tryParse(summary['totalDebits']?.toString() ?? '0') ?? 0;
    final net = double.tryParse(summary['netChange']?.toString() ?? '0') ?? 0;
    final count = summary['transactionCount'] ?? 0;

    Widget card(String label, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
                const SizedBox(height: 8),
                Text(value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            card(_isArabic ? 'إجمالي الداخل' : 'Total credits',
                '+${credits.toStringAsFixed(2)} EGP', AppColors.success),
            const SizedBox(width: 12),
            card(_isArabic ? 'إجمالي الخارج' : 'Total debits',
                '-${debits.toStringAsFixed(2)} EGP', AppColors.error),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            card(
                _isArabic ? 'صافي التغير' : 'Net change',
                '${net >= 0 ? '+' : ''}${net.toStringAsFixed(2)} EGP',
                net >= 0 ? AppColors.success : AppColors.error),
            const SizedBox(width: 12),
            card(_isArabic ? 'عدد المعاملات' : 'Transactions', '$count',
                AppColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _txCard(BuildContext context, ThemeData theme, dynamic tx) {
    final type = tx['type']?.toString() ?? 'UNKNOWN';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final date = tx['createdAt'] != null
        ? DateTime.parse(tx['createdAt'].toString()).toLocal()
        : DateTime.now();
    final description = tx['description']?.toString() ?? '';
    final isCredit = amount >= 0;
    final color = isCredit ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_typeLabel(type),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${amount.abs().toStringAsFixed(2)} EGP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
