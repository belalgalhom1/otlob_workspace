import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../data/wallet_localization.dart';
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

  static final _moneyFmt = NumberFormat('#,##0.00', 'en_US');
  static final _intFmt = NumberFormat('#,##0', 'en_US');

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
    bool includeCurrency = true,
  }) {
    return WalletLocalization.buildMoneyText(
      text,
      style,
      isArabic: _isArabic,
      includeCurrency: includeCurrency,
      alignment: alignment,
    );
  }

  String _typeLabel(String type) {
    return WalletLocalization.typeLabel(type, isArabic: _isArabic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(vendorWalletDataProvider);
    final notifier = ref.read(vendorWalletDataProvider.notifier);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final borderColor = _borderColor(theme);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                textAlign: TextAlign.center,
                style: TextStyle(color: _negativeTextColor(theme)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(vendorWalletDataProvider),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(l10n.retry),
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
        if (data.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _isArabic
                    ? 'لم يتم اختيار متجر'
                    : 'No vendor selected or found.',
                textAlign: TextAlign.center,
              ),
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
        final branches = (data['branches'] as List<dynamic>?) ?? const [];
        final hasMore = data['hasMore'] == true;

        return RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 8 : 12,
              isMobile ? 16 : 24,
              24,
            ),
            children: [
              _buildBalanceCard(context, balance, theme, isMobile),
              const SizedBox(height: 16),
              _buildFilterBar(context, notifier, theme, branches),
              const SizedBox(height: 16),
              _buildSummary(context, data, theme),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    Text(
                      _isArabic ? 'المعاملات' : 'Transactions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (transactions.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _exportTransactions(
                              context,
                              balance,
                              transactions,
                            ),
                            icon: const Icon(Icons.download, size: 16),
                            label: Text(_isArabic ? 'تصدير' : 'Export'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface,
                              side: BorderSide(color: borderColor),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const VendorProductSalesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.package, size: 16),
                          label: Text(
                            _isArabic ? 'المنتجات المباعة' : 'Products sold',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: borderColor),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
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
                            size: 16,
                          ),
                          label: Text(
                            _isArabic ? 'الإحصائيات' : 'Statistics',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: borderColor),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
    List<dynamic> branches,
  ) {
    final selectedType = notifier.selectedType;
    final selectedBranchId = notifier.selectedBranchId;
    final from = notifier.fromDate;
    final to = notifier.toDate;
    final hasFilters =
        selectedType != null ||
        selectedBranchId != null ||
        from != null ||
        to != null;

    final dateLabel = from == null && to == null
        ? (_isArabic ? 'كل التواريخ' : 'All dates')
        : '${from != null ? DateFormat('yyyy-MM-dd').format(from) : '...'}'
              ' - '
              '${to != null ? DateFormat('yyyy-MM-dd').format(to) : '...'}';

    final typeDropdown = InputDecorator(
      decoration: InputDecoration(
        labelText: _isArabic ? 'نوع المعاملة' : 'Transaction type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          isDense: true,
          itemHeight: null,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                _isArabic ? 'كل الأنواع' : 'All types',
                softWrap: true,
              ),
            ),
            ..._transactionTypes.map(
              (type) => DropdownMenuItem<String>(
                value: type,
                child: Text(
                  _typeLabel(type),
                  softWrap: true,
                ),
              ),
            ),
          ],
          onChanged: notifier.setType,
        ),
      ),
    );

    final branchDropdown = InputDecorator(
      decoration: InputDecoration(
        labelText: _isArabic ? 'الفرع' : 'Branch',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:
              branches.any(
                (b) => b is Map && b['id']?.toString() == selectedBranchId,
              )
              ? selectedBranchId
              : null,
          isExpanded: true,
          isDense: true,
          itemHeight: null,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                _isArabic ? 'كل الفروع' : 'All branches',
                softWrap: true,
              ),
            ),
            ...branches.whereType<Map>().map((b) {
              final id = b['id']?.toString() ?? '';
              final name = _isArabic
                  ? (b['nameAr'] ?? b['name'] ?? id).toString()
                  : (b['name'] ?? b['nameAr'] ?? id).toString();
              return DropdownMenuItem<String>(
                value: id,
                child: Text(
                  name,
                  softWrap: true,
                ),
              );
            }),
          ],
          onChanged: notifier.setBranch,
        ),
      ),
    );

    final dateButton = OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
          builder: AppDialogStyles.adaptivePickerTheme,
          initialDateRange: from != null && to != null
              ? DateTimeRange(start: from, end: to)
              : null,
        );
        if (range != null) {
          await notifier.setDateRange(range.start, range.end);
        }
      },
      icon: const Icon(LucideIcons.calendar, size: 17),
      label: Directionality(
        textDirection: (from != null || to != null)
            ? TextDirection.ltr
            : Directionality.of(context),
        child: Text(dateLabel),
      ),
    );

    final clearButton = hasFilters
        ? TextButton.icon(
            onPressed: notifier.clearFilters,
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
                if (branches.length > 1) ...[
                  const SizedBox(height: 12),
                  branchDropdown,
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [dateButton, ?clearButton],
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
              if (branches.length > 1)
                SizedBox(width: 210, child: branchDropdown),
              dateButton,
              ?clearButton,
            ],
          );
        },
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
    final count =
        int.tryParse(
          (summary['transactionCount'] ?? 0).toString().split('.').first,
        ) ??
        0;

    final byType = summary['byType'];
    final hasByType = byType is List && byType.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final scaledFont = MediaQuery.textScalerOf(context).scale(14);
            final singleColumn = constraints.maxWidth < 300 || scaledFont > 19;
            final creditsCard = _summaryCard(
              theme,
              label: _isArabic ? 'إجمالي الداخل' : 'Total credits',
              value: '+${_moneyFmt.format(credits)}',
              includeCurrency: true,
              color: _positiveTextColor(theme),
            );
            final debitsCard = _summaryCard(
              theme,
              label: _isArabic ? 'إجمالي الخارج' : 'Total debits',
              value: '-${_moneyFmt.format(debits.abs())}',
              includeCurrency: true,
              color: _negativeTextColor(theme),
            );
            final netCard = _summaryCard(
              theme,
              label: _isArabic ? 'صافي التغير' : 'Net change',
              value:
                  '${net > 0 ? '+' : net < 0 ? '-' : ''}${_moneyFmt.format(net.abs())}',
              includeCurrency: true,
              color: net >= 0
                  ? _positiveTextColor(theme)
                  : _negativeTextColor(theme),
            );
            final countCard = _summaryCard(
              theme,
              label: _isArabic ? 'عدد المعاملات' : 'Transactions',
              value: _intFmt.format(count),
              includeCurrency: false,
              color: _amberTextColor(theme),
            );

            if (singleColumn) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  creditsCard,
                  const SizedBox(height: 12),
                  debitsCard,
                  const SizedBox(height: 12),
                  netCard,
                  const SizedBox(height: 12),
                  countCard,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: creditsCard),
                      const SizedBox(width: 12),
                      Expanded(child: debitsCard),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: netCard),
                      const SizedBox(width: 12),
                      Expanded(child: countCard),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (hasByType) ...[
          const SizedBox(height: 16),
          Text(
            _isArabic ? 'تفصيل حسب النوع' : 'Breakdown by type',
            softWrap: true,
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
                if (entry is Map) ...[
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
                      '$sign${_moneyFmt.format(total.abs())}',
                      baseColor,
                      textColor,
                    );
                  }(),
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
    required bool includeCurrency,
    required Color color,
  }) {
    return Container(
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
            softWrap: true,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: WalletLocalization.buildMoneyText(
              value,
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              isArabic: _isArabic,
              includeCurrency: includeCurrency,
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(
    String label,
    String amountText,
    Color baseColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: baseColor.withValues(alpha: 0.28)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$label:',
            softWrap: true,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          WalletLocalization.buildMoneyText(
            amountText,
            TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            isArabic: _isArabic,
            includeCurrency: true,
            alignment: AlignmentDirectional.centerStart,
          ),
        ],
      ),
    );
  }

  Future<void> _exportTransactions(
    BuildContext context,
    double balance,
    List<dynamic> transactions,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currency = WalletLocalization.currency(isArabic);
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
          WalletLocalization.formatDateTime(
            tx['createdAt'],
            isArabic: isArabic,
          ),
          _typeLabel(tx['type']?.toString() ?? ''),
          tx is Map
              ? WalletLocalization.localizeDescription(tx, isArabic: isArabic)
              : (tx['description']?.toString() ?? ''),
          '${_moneyFmt.format(double.tryParse(tx['amount']?.toString() ?? '0') ?? 0)} $currency',
          tx['balanceAfter'] != null
              ? '${_moneyFmt.format(double.tryParse(tx['balanceAfter'].toString()) ?? 0)} $currency'
              : '',
        ],
    ];

    await DataExportService.showExportOptions(
      context,
      title: isArabic ? 'كشف حساب المعاملات المالية' : 'Financial Transactions',
      subtitle: isArabic
          ? 'الرصيد المتاح: ${_moneyFmt.format(balance)} $currency'
          : 'Available balance: ${_moneyFmt.format(balance)} $currency',
      headers: headers,
      rows: rows,
      filename: 'financial_transactions',
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    ThemeData theme,
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
                      softWrap: true,
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: _isArabic ? null : 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isNegative)
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
                      )
                    else
                      Text(
                        _isArabic
                            ? 'رصيدك متاح للسحب'
                            : 'Available for withdrawal',
                        softWrap: true,
                        style: TextStyle(
                          color: AppColors.onPrimary.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                  includeCurrency: false,
                  alignment: AlignmentDirectional.centerStart,
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
                child: Text(
                  WalletLocalization.currency(_isArabic),
                  style: const TextStyle(
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

  Widget _buildTransactionCard(
    BuildContext context,
    dynamic tx,
    ThemeData theme,
  ) {
    final txMap = tx is Map ? tx : <String, dynamic>{};
    final type = txMap['type'] ?? 'UNKNOWN';
    final amount = double.tryParse(txMap['amount']?.toString() ?? '0') ?? 0.0;
    final hasBalanceAfter = txMap['balanceAfter'] != null;
    final balanceAfter = hasBalanceAfter
        ? (double.tryParse(txMap['balanceAfter'].toString()) ?? 0.0)
        : 0.0;
    final localizedDescription = WalletLocalization.localizeDescription(
      txMap,
      isArabic: _isArabic,
    );
    final formattedDate = WalletLocalization.formatDateTime(
      txMap['createdAt'] ?? DateTime.now(),
      isArabic: _isArabic,
    );
    final orderNumber = WalletLocalization.extractOrderNumber(txMap);

    final isCredit = amount >= 0;
    final iconBgColor = isCredit ? AppColors.success : AppColors.error;
    final amountTextColor = isCredit
        ? _positiveTextColor(theme)
        : _negativeTextColor(theme);
    final icon = isCredit
        ? LucideIcons.arrowDownLeft
        : LucideIcons.arrowUpRight;
    final sign = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(theme)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: amountTextColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _typeLabel(type.toString()),
                        softWrap: true,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (orderNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
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
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.42,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _scaledMoneyText(
                        '$sign${_moneyFmt.format(amount.abs())}',
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: amountTextColor,
                          fontSize: 15,
                        ),
                        includeCurrency: true,
                        alignment: AlignmentDirectional.centerEnd,
                      ),
                      if (hasBalanceAfter) ...[
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isArabic ? 'الرصيد: ' : 'Bal: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              _scaledMoneyText(
                                '${balanceAfter < 0 ? '-' : ''}${_moneyFmt.format(balanceAfter.abs())}',
                                TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                                includeCurrency: true,
                                alignment: AlignmentDirectional.centerEnd,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (localizedDescription.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                localizedDescription,
                softWrap: true,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (formattedDate.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                formattedDate,
                softWrap: true,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 11.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
