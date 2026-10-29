import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import 'driver_statistics_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';

class DriverStatisticsScreen extends ConsumerWidget {
  const DriverStatisticsScreen({super.key});

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

    final profile = ref.watch(driverProfileProvider).asData?.value;
    String driverName = '';
    if (profile != null) {
      if (profile is Map) {
        driverName = (profile['user']?['name'] ?? profile['name'] ?? '').toString();
      } else {
        try {
          driverName = (profile.user?.name ?? profile.name ?? '').toString();
        } catch (_) {}
      }
    }
    driverName = driverName.trim();

    return StatisticsScreen(
      config: StatisticsConfig(
        titleAr: driverName.isNotEmpty
            ? (isArabic() ? 'إحصائيات السائق: $driverName' : 'Driver Statistics: $driverName')
            : (isArabic() ? 'إحصائيات السائق' : 'Driver Statistics'),
        titleEn: driverName.isNotEmpty
            ? 'Driver Statistics: $driverName'
            : 'Driver Statistics',
        entityName: driverName.isNotEmpty ? driverName : null,
        chartTitleAr: 'اتجاه الأرباح',
        chartTitleEn: 'Earnings Trend',
        tooltipSuffix: 'EGP',
        filenamePrefix: 'driver_statistics',
        fetch: (period, {from, to}) => ref.read(
            driverStatsProvider((
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
        exportSections: [
          StatisticExportSection(
            titleAr: 'البيانات المالية والأرباح',
            titleEn: 'Financial & Earnings Summary',
            columns: [
              StatisticExportColumn(
                labelAr: 'الأرباح',
                labelEn: 'Earnings',
                value: (row) =>
                    '${StatisticsFormat.numOf(row['totalEarnings']).toStringAsFixed(2)} EGP',
              ),
              StatisticExportColumn(
                labelAr: 'رسوم التوصيل',
                labelEn: 'Delivery Fee',
                value: (row) {
                  final del = row['deliveryFee'] != null
                      ? StatisticsFormat.numOf(row['deliveryFee'])
                      : StatisticsFormat.numOf(row['totalEarnings']) * 1.25;
                  return '${del.toStringAsFixed(2)} EGP';
                },
              ),
            ],
          ),
          StatisticExportSection(
            titleAr: 'إحصائيات الطلبات وساعات العمل',
            titleEn: 'Orders & Operations Breakdown',
            columns: [
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
                    '${StatisticsFormat.numOf(row['onlineHours']).toStringAsFixed(1)} h',
              ),
              StatisticExportColumn(
                labelAr: 'القبول (مقبول/مستلم)',
                labelEn: 'Acceptance Rate',
                value: (row) =>
                    '${acceptance(row)}% (${StatisticsFormat.intOf(row['dispatchesAccepted'])}/${StatisticsFormat.intOf(row['totalDispatchesReceived'])})',
              ),
              StatisticExportColumn(
                labelAr: 'مرفوضة / منتهية',
                labelEn: 'Rejected / Expired',
                value: (row) =>
                    '${StatisticsFormat.intOf(row['dispatchesRejected'])} / ${StatisticsFormat.intOf(row['dispatchesExpired'])}',
              ),
            ],
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