import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:intl/intl.dart';
import 'vendor_wallet_provider.dart';
import 'vendor_finance_statistics_screen.dart';
import 'vendor_product_sales_screen.dart';

class VendorWalletScreen extends ConsumerStatefulWidget {
  const VendorWalletScreen({super.key});

  @override
  ConsumerState<VendorWalletScreen> createState() => _VendorWalletScreenState();
}

class _VendorWalletScreenState extends ConsumerState<VendorWalletScreen> {
  static const _transactionTypes = <String>[
    'ORDER_REVENUE',
    'COMMISSION_DEDUCTION',
    'CASH_COLLECTED',
    'PAYOUT',
    'REFUND',
    'ADJUSTMENT',
  ];

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(vendorWalletDataProvider);
    final notifier = ref.read(vendorWalletDataProvider.notifier);
    final theme = Theme.of(context);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              ErrorUtils.translate(context, err),
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(vendorWalletDataProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Text(
              _isArabic ? 'لم يتم اختيار متجر' : 'No vendor selected or found.',
            ),
          );
        }

        final balanceData = data['balance'] is Map
            ? data['balance'] as Map<String, dynamic>
            : <String, dynamic>{};
        final balance =
            double.tryParse(
              (balanceData['walletBalance'] ?? balanceData['balance'] ?? '0')
                  .toString(),
            ) ??
            0.0;
        final transactions = data['transactions'] as List<dynamic>;
        final hasMore = data['hasMore'] == true;

        return RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildBalanceCard(context, balance, theme),
              const SizedBox(height: 16),
              _buildFilterBar(context, notifier, theme),
              const SizedBox(height: 20),
              _buildSummary(context, data, theme),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    _isArabic ? 'المعاملات' : 'Transactions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (transactions.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _exportTransactions(
                            context,
                            balance,
                            transactions,
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(_isArabic ? 'تصدير' : 'Export'),
                        ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VendorProductSalesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.package, size: 18),
                        label: Text(
                          _isArabic ? 'المنتجات المباعة' : 'Products sold',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const VendorFinanceStatisticsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          LucideIcons.chartNoAxesCombined,
                          size: 18,
                        ),
                        label: Text(_isArabic ? 'الإحصائيات' : 'Statistics'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.receipt,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isArabic ? 'لا توجد معاملات' : 'No transactions yet',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ...transactions.map(
                  (tx) => _buildTransactionCard(context, tx, theme),
                ),
                if (hasMore)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: notifier.loadMore,
                        icon: const Icon(LucideIcons.chevronDown, size: 18),
                        label: Text(_isArabic ? 'تحميل المزيد' : 'Load more'),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    VendorWalletData notifier,
    ThemeData theme,
  ) {
    final selectedType = notifier.selectedType;
    final from = notifier.fromDate;
    final to = notifier.toDate;
    final hasFilters = selectedType != null || from != null || to != null;

    final dateLabel = from == null && to == null
        ? (_isArabic ? 'كل التواريخ' : 'All dates')
        : '${from != null ? DateFormat('yyyy-MM-dd').format(from) : '...'}'
              ' - '
              '${to != null ? DateFormat('yyyy-MM-dd').format(to) : '...'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _isArabic ? 'نوع المعاملة' : 'Transaction type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(_isArabic ? 'كل الأنواع' : 'All types'),
                    ),
                    ..._transactionTypes.map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    ),
                  ],
                  onChanged: notifier.setType,
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: now,
                initialDateRange: from != null && to != null
                    ? DateTimeRange(start: from, end: to)
                    : null,
              );
              if (range != null) {
                await notifier.setDateRange(range.start, range.end);
              }
            },
            icon: const Icon(LucideIcons.calendar, size: 18),
            label: Text(dateLabel),
          ),
          if (hasFilters)
            TextButton.icon(
              onPressed: notifier.clearFilters,
              icon: const Icon(LucideIcons.x, size: 18),
              label: Text(_isArabic ? 'مسح الفلاتر' : 'Clear filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    Map<String, dynamic> data,
    ThemeData theme,
  ) {
    final summary = data['summary'] is Map
        ? data['summary'] as Map<String, dynamic>
        : <String, dynamic>{};
    if (summary.isEmpty) return const SizedBox.shrink();

    final credits =
        double.tryParse(summary['totalCredits']?.toString() ?? '0') ?? 0;
    final debits =
        double.tryParse(summary['totalDebits']?.toString() ?? '0') ?? 0;
    final net = double.tryParse(summary['netChange']?.toString() ?? '0') ?? 0;
    final count = summary['transactionCount'] ?? 0;

    final byType = summary['byType'];
    final hasByType = byType is List && byType.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                theme,
                label: _isArabic ? 'إجمالي الداخل' : 'Total credits',
                value: '+${credits.toStringAsFixed(2)} EGP',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                theme,
                label: _isArabic ? 'إجمالي الخارج' : 'Total debits',
                value: '-${debits.toStringAsFixed(2)} EGP',
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                theme,
                label: _isArabic ? 'صافي التغير' : 'Net change',
                value: '${net >= 0 ? '+' : ''}${net.toStringAsFixed(2)} EGP',
                color: net >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                theme,
                label: _isArabic ? 'عدد المعاملات' : 'Transactions',
                value: '$count',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        if (hasByType) ...[
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'تفصيل حسب النوع' : 'Breakdown by type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in byType)
                if (entry is Map) ...[
                  _typeChip(
                    context,
                    theme,
                    '${_typeLabel(entry['type']?.toString() ?? '')}: '
                    '${(double.tryParse(entry['total']?.toString() ?? '0') ?? 0).toStringAsFixed(2)} EGP',
                    (double.tryParse(entry['total']?.toString() ?? '0') ?? 0)
                            .isNegative
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _typeChip(
    BuildContext context,
    ThemeData theme,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _exportTransactions(
    BuildContext context,
    double balance,
    List<dynamic> transactions,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final headers = [
      isArabic ? 'التاريخ' : 'Date',
      isArabic ? 'النوع' : 'Type',
      isArabic ? 'الوصف' : 'Description',
      isArabic ? 'المبلغ' : 'Amount',
      isArabic ? 'الرصيد بعد' : 'Balance After',
    ];
    final rows = [
      for (final tx in transactions)
        [
          tx['createdAt'] != null
              ? dateFormat.format(
                  DateTime.parse(tx['createdAt'].toString()).toLocal(),
                )
              : '',
          _typeLabel(tx['type']?.toString() ?? ''),
          tx['description']?.toString() ?? '',
          '${(double.tryParse(tx['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)} EGP',
          tx['balanceAfter'] != null
              ? '${(double.tryParse(tx['balanceAfter'].toString()) ?? 0).toStringAsFixed(2)} EGP'
              : '',
        ],
    ];

    await DataExportService.showExportOptions(
      context,
      title: isArabic ? 'كشف حساب المعاملات المالية' : 'Financial Transactions',
      subtitle: isArabic
          ? 'الرصيد المتاح: ${balance.toStringAsFixed(2)} EGP'
          : 'Available balance: ${balance.toStringAsFixed(2)} EGP',
      headers: headers,
      rows: rows,
      filename: 'financial_transactions',
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isArabic ? 'الرصيد المتاح' : 'Available Balance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balance >= 0
                          ? (_isArabic
                                ? 'رصيدك متاح للسحب'
                                : 'Available for withdrawal')
                          : (_isArabic ? 'رصيد سلبي' : 'Negative balance'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Text(
                '${balance.toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  balance >= 0 ? 'EGP' : 'EGP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    dynamic tx,
    ThemeData theme,
  ) {
    final type = tx['type'] ?? 'UNKNOWN';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final date = tx['createdAt'] != null
        ? DateTime.parse(tx['createdAt'].toString()).toLocal()
        : DateTime.now();
    final description = tx['description'] as String? ?? '';

    final isCredit = amount >= 0;
    final color = isCredit ? AppColors.success : AppColors.error;
    final icon = isCredit
        ? LucideIcons.arrowDownLeft
        : LucideIcons.arrowUpRight;
    final sign = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(type.toString()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${amount.abs().toStringAsFixed(2)} EGP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
