import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../data/wallet_localization.dart';
import 'vendor_finance_statistics_provider.dart';

class VendorFinanceStatisticsScreen extends ConsumerWidget {
  final String? vendorId;

  const VendorFinanceStatisticsScreen({super.key, this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isArabic() =>
        Localizations.localeOf(context).languageCode == 'ar';
    String cur() => WalletLocalization.currency(isArabic());
    final moneyFmt = NumberFormat('#,##0.00', 'en_US');
    final intFmt = NumberFormat('#,##0', 'en_US');

    return StatisticsScreen(
      config: StatisticsConfig(
        backgroundColor: Theme.of(context).colorScheme.surface,
        titleAr: 'الإحصائيات المالية',
        titleEn: 'Finance Statistics',
        chartTitleAr: 'اتجاه الإيرادات',
        chartTitleEn: 'Revenue Trend',
        tooltipSuffix: cur(),
        filenamePrefix: 'vendor_finance_statistics',
        fetch: (period, {from, to}) => ref.read(
            vendorFinanceStatsProvider((
              vendorId: vendorId,
              period: period,
              from: from,
              to: to,
            )).future),
        amount: (row) => StatisticsFormat.numOf(row['totalRevenue']),
        summary: [
          StatisticSummaryItem(
            labelAr: 'إجمالي الإيرادات',
            labelEn: 'Total Revenue',
            icon: Icons.trending_up,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalRevenue'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي الطلبات',
            labelEn: 'Total Orders',
            icon: Icons.shopping_bag_outlined,
            value: (rows) => intFmt.format(
              rows.fold<int>(
                0,
                (s, r) => s + StatisticsFormat.intOf(r['totalOrders']),
              ),
            ),
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي العمولة',
            labelEn: 'Total Commission',
            icon: Icons.account_balance_wallet_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalCommission'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي الضريبة',
            labelEn: 'Total Tax',
            icon: Icons.receipt_long_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalTax'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'صافي الربح',
            labelEn: 'Net Profit',
            icon: Icons.savings_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalRevenue']) - StatisticsFormat.numOf(r['totalCommission'])))} ${cur()}',
          ),
        ],
        exportColumns: [
          StatisticExportColumn(
            labelAr: 'الطلبات',
            labelEn: 'Orders',
            value: (row) => '${StatisticsFormat.intOf(row['totalOrders'])}',
          ),
          StatisticExportColumn(
            labelAr: 'الإيرادات',
            labelEn: 'Revenue',
            value: (row) =>
                StatisticsFormat.numOf(row['totalRevenue']).toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'العمولة',
            labelEn: 'Commission',
            value: (row) =>
                StatisticsFormat.numOf(row['totalCommission']).toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'الضريبة',
            labelEn: 'Tax',
            value: (row) =>
                StatisticsFormat.numOf(row['totalTax']).toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'صافي الربح',
            labelEn: 'Net Profit',
            value: (row) =>
                (StatisticsFormat.numOf(row['totalRevenue']) -
                        StatisticsFormat.numOf(row['totalCommission']))
                    .toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'المكتملة',
            labelEn: 'Completed',
            value: (row) => '${StatisticsFormat.intOf(row['completedOrders'])}',
          ),
          StatisticExportColumn(
            labelAr: 'الملغية',
            labelEn: 'Cancelled',
            value: (row) => '${StatisticsFormat.intOf(row['cancelledOrders'])}',
          ),
        ],
        rowDetails: (row) {
          final orders = intFmt.format(StatisticsFormat.intOf(row['totalOrders']));
          final commission =
              moneyFmt.format(StatisticsFormat.numOf(row['totalCommission']));
          final tax = moneyFmt.format(StatisticsFormat.numOf(row['totalTax']));
          return [
            isArabic() ? '$orders طلب' : '$orders orders',
            isArabic()
                ? 'عمولة $commission ${cur()}'
                : 'Commission $commission ${cur()}',
            isArabic()
                ? 'ضريبة $tax ${cur()}'
                : 'Tax $tax ${cur()}',
          ];
        },
      ),
    );
  }
}