import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';

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

  static final _moneyFmt = NumberFormat('#,##0.00', 'en_US');
  static final _intFmt = NumberFormat('#,##0', 'en_US');

  String? _type;
  DateTime? _from;
  DateTime? _to;
  int _page = 1;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  Color _borderColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.borderDark
      : AppColors.borderLight;

  Color _positiveTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? AppColors.success
      : const Color(0xFF047857);

  Color _negativeTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? AppColors.error
      : const Color(0xFFB91C1C);

  Color _amberTextColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.primary
      : const Color(0xFF92400E);

  Widget _scaledMoneyText(
    String text,
    TextStyle style, {
    AlignmentDirectional alignment = AlignmentDirectional.centerStart,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          text,
          maxLines: 1,
          style: style.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final borderColor = _borderColor(theme);
    final async = ref.watch(adminVendorWalletProvider(_args));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${_isArabic ? 'محفظة' : 'Wallet'}'
          '${widget.vendorName != null ? ' - ${widget.vendorName}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  ErrorUtils.translate(context, err),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _negativeTextColor(theme)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(adminVendorWalletProvider(_args)),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final balanceData = data['balance'] is Map
              ? data['balance'] as Map<String, dynamic>
              : <String, dynamic>{};
          final balance =
              double.tryParse(
                (balanceData['walletBalance'] ?? balanceData['balance'] ?? '0')
                    .toString(),
              ) ??
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
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              children: [
                _balanceCard(context, theme, balance, isMobile),
                const SizedBox(height: 16),
                _filters(context, theme),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _summary(context, theme, summary),
                ],
                const SizedBox(height: 24),
                Text(
                  _isArabic ? 'المعاملات' : 'Transactions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.receipt,
                          size: 44,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isArabic ? 'لا توجد معاملات' : 'No transactions yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
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
    final hasFilters = _type != null || _from != null || _to != null;
    final dateLabel = _from == null && _to == null
        ? (_isArabic ? 'كل التواريخ' : 'All dates')
        : '${_from != null ? DateFormat('yyyy-MM-dd').format(_from!) : '...'}'
              ' - '
              '${_to != null ? DateFormat('yyyy-MM-dd').format(_to!) : '...'}';

    final typeDropdown = InputDecorator(
      decoration: InputDecoration(
        labelText: _isArabic ? 'نوع المعاملة' : 'Transaction type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _type,
          isExpanded: true,
          isDense: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                _isArabic ? 'كل الأنواع' : 'All types',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ..._types.map(
              (type) => DropdownMenuItem<String>(
                value: type,
                child: Text(
                  _typeLabel(type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() {
            _type = value;
            _page = 1;
          }),
        ),
      ),
    );

    final dateButton = OutlinedButton.icon(
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
      icon: const Icon(LucideIcons.calendar, size: 17),
      label: Directionality(
        textDirection: (_from != null || _to != null)
            ? TextDirection.ltr
            : Directionality.of(context),
        child: Text(dateLabel),
      ),
    );

    final clearButton = hasFilters
        ? TextButton.icon(
            onPressed: () => setState(() {
              _type = null;
              _from = null;
              _to = null;
              _page = 1;
            }),
            icon: const Icon(LucideIcons.x, size: 17),
            label: Text(_isArabic ? 'مسح الفلاتر' : 'Clear filters'),
            style: TextButton.styleFrom(
              foregroundColor: _negativeTextColor(theme),
            ),
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(theme)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                typeDropdown,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [dateButton, if (clearButton != null) clearButton],
                ),
              ],
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 210, child: typeDropdown),
              dateButton,
              if (clearButton != null) clearButton,
            ],
          );
        },
      ),
    );
  }

  Widget _pager(ThemeData theme, int currentPage, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              onPressed: currentPage > 1 ? () => setState(() => _page--) : null,
              tooltip: _isArabic ? 'السابق' : 'Previous',
              icon: Icon(
                isRtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                size: 18,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isArabic
                    ? 'صفحة $currentPage من $totalPages'
                    : 'Page $currentPage of $totalPages',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton.outlined(
              onPressed: currentPage < totalPages
                  ? () => setState(() => _page++)
                  : null,
              tooltip: _isArabic ? 'التالي' : 'Next',
              icon: AppAdaptiveChevron(
                size: 18,
                color: currentPage < totalPages
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(
    BuildContext context,
    ThemeData theme,
    double balance,
    bool isMobile,
  ) {
    final isNegative = balance < 0;
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isArabic ? 'الرصيد المتاح' : 'Available Balance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: _isArabic ? null : 0.2,
                      ),
                    ),
                    if (isNegative) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isArabic ? 'رصيد سلبي' : 'Negative balance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: _scaledMoneyText(
                  '${isNegative ? '-' : ''}${_moneyFmt.format(balance.abs())}',
                  TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: isMobile ? 32 : 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.onPrimary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'EGP',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> summary,
  ) {
    final credits =
        double.tryParse(summary['totalCredits']?.toString() ?? '0') ?? 0;
    final debits =
        double.tryParse(summary['totalDebits']?.toString() ?? '0') ?? 0;
    final net = double.tryParse(summary['netChange']?.toString() ?? '0') ?? 0;
    final count =
        int.tryParse(
          (summary['transactionCount'] ?? 0).toString().split('.').first,
        ) ??
        0;
    final byType = summary['byType'];
    final hasByType = byType is List && byType.isNotEmpty;

    Widget card(String label, String value, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor(theme)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _scaledMoneyText(
                value,
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                _isArabic ? 'إجمالي الداخل' : 'Total credits',
                '+${_moneyFmt.format(credits)} EGP',
                _positiveTextColor(theme),
              ),
              const SizedBox(width: 12),
              card(
                _isArabic ? 'إجمالي الخارج' : 'Total debits',
                '-${_moneyFmt.format(debits.abs())} EGP',
                _negativeTextColor(theme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                _isArabic ? 'صافي التغير' : 'Net change',
                '${net > 0 ? '+' : net < 0 ? '-' : ''}${_moneyFmt.format(net.abs())} EGP',
                net >= 0
                    ? _positiveTextColor(theme)
                    : _negativeTextColor(theme),
              ),
              const SizedBox(width: 12),
              card(
                _isArabic ? 'عدد المعاملات' : 'Transactions',
                _intFmt.format(count),
                _amberTextColor(theme),
              ),
            ],
          ),
        ),
        if (hasByType) ...[
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'تفصيل حسب النوع' : 'Breakdown by type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in byType)
                if (entry is Map)
                  () {
                    final total =
                        double.tryParse(entry['total']?.toString() ?? '0') ?? 0;
                    final sign = total > 0
                        ? '+'
                        : total < 0
                        ? '-'
                        : '';
                    final baseColor = total.isNegative
                        ? AppColors.error
                        : AppColors.success;
                    final textColor = total.isNegative
                        ? _negativeTextColor(theme)
                        : _positiveTextColor(theme);
                    return _typeChip(
                      _typeLabel(entry['type']?.toString() ?? ''),
                      '$sign${_moneyFmt.format(total.abs())} EGP',
                      baseColor,
                      textColor,
                    );
                  }(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _typeChip(
    String label,
    String amountText,
    Color baseColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: baseColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '$label:',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              amountText,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txCard(BuildContext context, ThemeData theme, dynamic tx) {
    if (tx is! Map) return const SizedBox.shrink();
    final type = tx['type']?.toString() ?? 'UNKNOWN';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final hasBalanceAfter = tx['balanceAfter'] != null;
    final balanceAfter = hasBalanceAfter
        ? (double.tryParse(tx['balanceAfter'].toString()) ?? 0.0)
        : 0.0;
    final date =
        DateTime.tryParse(tx['createdAt']?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    final description = tx['description']?.toString() ?? '';
    final orderObj = tx['order'] is Map ? tx['order'] as Map : null;
    final orderNumber = orderObj?['orderNumber']?.toString() ?? '';

    final isCredit = amount >= 0;
    final iconBgColor = isCredit ? AppColors.success : AppColors.error;
    final amountTextColor = isCredit
        ? _positiveTextColor(theme)
        : _negativeTextColor(theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(theme)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                color: amountTextColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _typeLabel(type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (orderNumber.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$orderNumber',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _amberTextColor(theme),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _scaledMoneyText(
                    '${isCredit ? '+' : '-'}${_moneyFmt.format(amount.abs())} EGP',
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: amountTextColor,
                    ),
                    alignment: AlignmentDirectional.centerEnd,
                  ),
                  if (hasBalanceAfter) ...[
                    const SizedBox(height: 3),
                    _scaledMoneyText(
                      '${_isArabic ? 'الرصيد: ' : 'Bal: '}${balanceAfter < 0 ? '-' : ''}${_moneyFmt.format(balanceAfter.abs())}',
                      TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      alignment: AlignmentDirectional.centerEnd,
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
}
