import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import 'driver_statistics_provider.dart';

class DriverStatisticsScreen extends ConsumerWidget {
  final String driverId;

  const DriverStatisticsScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isArabic() =>
        Localizations.localeOf(context).languageCode == 'ar';
    int acceptance(dynamic row) {
      final received =
          StatisticsFormat.intOf(row['totalDispatchesReceived']);
      final accepted = StatisticsFormat.intOf(row['dispatchesAccepted']);
      return received > 0 ? (accepted * 100 / received).round() : 0;
    }

    return StatisticsScreen(
      config: StatisticsConfig(
        titleAr: 'إحصائيات السائق',
        titleEn: 'Driver Statistics',
        chartTitleAr: 'اتجاه الأرباح',
        chartTitleEn: 'Earnings Trend',
        tooltipSuffix: 'EGP',
        filenamePrefix: 'driver_statistics',
        fetch: (period, {from, to}) => ref.read(
            adminDriverStatsProvider((
              driverId: driverId,
              period: period,
              from: from,
              to: to,
            )).future),
        amount: (row) => StatisticsFormat.numOf(row['totalEarnings']),
        summary: [
          StatisticSummaryItem(
            labelAr: 'إجمالي الأرباح',
            labelEn: 'Total Earnings',
            icon: Icons.trending_up,
            value: (rows) =>
                '${rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalEarnings'])).toStringAsFixed(2)} EGP',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي الطلبات',
            labelEn: 'Total Orders',
            icon: Icons.shopping_bag_outlined,
            value: (rows) =>
                '${rows.fold<int>(0, (s, r) => s + StatisticsFormat.intOf(r['totalOrders']))}',
          ),
          StatisticSummaryItem(
            labelAr: 'المكتملة',
            labelEn: 'Completed',
            icon: Icons.check_circle_outline,
            value: (rows) =>
                '${rows.fold<int>(0, (s, r) => s + StatisticsFormat.intOf(r['completedOrders']))}',
          ),
          StatisticSummaryItem(
            labelAr: 'الملغية',
            labelEn: 'Cancelled',
            icon: Icons.cancel_outlined,
            value: (rows) =>
                '${rows.fold<int>(0, (s, r) => s + StatisticsFormat.intOf(r['cancelledOrders']))}',
          ),
          StatisticSummaryItem(
            labelAr: 'ساعات العمل',
            labelEn: 'Online Hours',
            icon: Icons.timer_outlined,
            value: (rows) =>
                '${rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['onlineHours'])).toStringAsFixed(1)} h',
          ),
        ],
        exportColumns: [
          StatisticExportColumn(
            labelAr: 'الأرباح',
            labelEn: 'Earnings',
            value: (row) =>
                StatisticsFormat.numOf(row['totalEarnings']).toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'الطلبات',
            labelEn: 'Orders',
            value: (row) => '${StatisticsFormat.intOf(row['totalOrders'])}',
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
          StatisticExportColumn(
            labelAr: 'ساعات العمل',
            labelEn: 'Online Hours',
            value: (row) =>
                StatisticsFormat.numOf(row['onlineHours']).toStringAsFixed(1),
          ),
          StatisticExportColumn(
            labelAr: 'مقبولة',
            labelEn: 'Accepted',
            value: (row) => '${StatisticsFormat.intOf(row['dispatchesAccepted'])}',
          ),
          StatisticExportColumn(
            labelAr: 'مرفوضة',
            labelEn: 'Rejected',
            value: (row) => '${StatisticsFormat.intOf(row['dispatchesRejected'])}',
          ),
          StatisticExportColumn(
            labelAr: 'منتهية',
            labelEn: 'Expired',
            value: (row) => '${StatisticsFormat.intOf(row['dispatchesExpired'])}',
          ),
        ],
        rowDetails: (row) => [
          isArabic()
              ? '${row['totalOrders'] ?? 0} طلب'
              : '${row['totalOrders'] ?? 0} orders',
          isArabic()
              ? 'مكتمل ${row['completedOrders'] ?? 0}'
              : 'Completed ${row['completedOrders'] ?? 0}',
          isArabic()
              ? 'مقبول ${acceptance(row)}%'
              : 'Acceptance ${acceptance(row)}%',
        ],
      ),
    );
  }
}