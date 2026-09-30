import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import 'platform_statistics_provider.dart';

class PlatformStatisticsScreen extends ConsumerWidget {
  const PlatformStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isArabic() =>
        Localizations.localeOf(context).languageCode == 'ar';

    return StatisticsScreen(
      config: StatisticsConfig(
        titleAr: 'إحصائيات المنصة',
        titleEn: 'Platform Statistics',
        chartTitleAr: 'اتجاه أرباح المنصة',
        chartTitleEn: 'Admin Revenue Trend',
        tooltipSuffix: 'EGP',
        filenamePrefix: 'platform_statistics',
        fetch: (period, {from, to}) => ref.read(
            platformStatisticsProvider((
              period: period,
              from: from,
              to: to,
            )).future),
        amount: (row) => StatisticsFormat.numOf(row['totalAdminRevenue']),
        summary: [
          StatisticSummaryItem(
            labelAr: 'إجمالي الطلبات',
            labelEn: 'Total Orders',
            icon: Icons.shopping_bag_outlined,
            value: (rows) =>
                '${rows.fold<int>(0, (s, r) => s + StatisticsFormat.intOf(r['totalOrders']))}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي أرباح المنصة',
            labelEn: 'Total Admin Revenue',
            icon: Icons.trending_up,
            value: (rows) =>
                '${rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalAdminRevenue'])).toStringAsFixed(2)} EGP',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي رسوم التوصيل',
            labelEn: 'Total Delivery Fees',
            icon: Icons.local_shipping_outlined,
            value: (rows) =>
                '${rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalDeliveryFees'])).toStringAsFixed(2)} EGP',
          ),
        ],
        exportColumns: [
          StatisticExportColumn(
            labelAr: 'الطلبات',
            labelEn: 'Orders',
            value: (row) => '${StatisticsFormat.intOf(row['totalOrders'])}',
          ),
          StatisticExportColumn(
            labelAr: 'أرباح المنصة',
            labelEn: 'Admin Revenue',
            value: (row) => StatisticsFormat.numOf(row['totalAdminRevenue'])
                .toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'رسوم التوصيل',
            labelEn: 'Delivery Fees',
            value: (row) => StatisticsFormat.numOf(row['totalDeliveryFees'])
                .toStringAsFixed(2),
          ),
        ],
        rowDetails: (row) => [
          isArabic()
              ? '${row['totalOrders'] ?? 0} طلب'
              : '${row['totalOrders'] ?? 0} orders',
        ],
      ),
    );
  }
}