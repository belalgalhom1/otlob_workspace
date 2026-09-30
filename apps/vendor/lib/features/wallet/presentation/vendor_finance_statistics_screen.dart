import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import 'vendor_finance_statistics_provider.dart';

class VendorFinanceStatisticsScreen extends ConsumerWidget {
  final String? vendorId;

  const VendorFinanceStatisticsScreen({super.key, this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isArabic() =>
        Localizations.localeOf(context).languageCode == 'ar';

    return StatisticsScreen(
      config: StatisticsConfig(
        titleAr: 'الإحصائيات المالية',
        titleEn: 'Finance Statistics',
        chartTitleAr: 'اتجاه الإيرادات',
        chartTitleEn: 'Revenue Trend',
        tooltipSuffix: 'EGP',
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
                '${rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalRevenue'])).toStringAsFixed(2)} EGP',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي الطلبات',
            labelEn: 'Total Orders',
            icon: Icons.shopping_bag_outlined,
            value: (rows) =>
                '${rows.fold<int>(0, (s, r) => s + StatisticsFormat.intOf(r['totalOrders']))}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي العمولة',
            labelEn: 'Total Commission',
            icon: Icons.account_balance_wallet_outlined,
            value: (rows) =>
                '${rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalCommission'])).toStringAsFixed(2)} EGP',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي الضريبة',
            labelEn: 'Total Tax',
            icon: Icons.receipt_long_outlined,
            value: (rows) =>
                '${rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalTax'])).toStringAsFixed(2)} EGP',
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
        rowDetails: (row) => [
          isArabic()
              ? '${row['totalOrders'] ?? 0} طلب'
              : '${row['totalOrders'] ?? 0} orders',
          isArabic()
              ? 'عمولة ${row['totalCommission'] ?? 0}'
              : 'Commission ${row['totalCommission'] ?? 0}',
          isArabic()
              ? 'ضريبة ${row['totalTax'] ?? 0}'
              : 'Tax ${row['totalTax'] ?? 0}',
        ],
      ),
    );
  }
}