import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';

import 'driver_statistics_provider.dart';

class DriverStatisticsScreen extends ConsumerWidget {
  final String driverId;
  final String? driverName;

  const DriverStatisticsScreen({
    super.key,
    required this.driverId,
    this.driverName,
  });

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

    final resolvedDriverName = (driverName ?? '').trim();

    return StatisticsScreen(
      config: StatisticsConfig(
        titleAr: resolvedDriverName.isNotEmpty
            ? (isArabic() ? 'إحصائيات السائق: $resolvedDriverName' : 'Driver Statistics: $resolvedDriverName')
            : (isArabic() ? 'إحصائيات السائق' : 'Driver Statistics'),
        titleEn: resolvedDriverName.isNotEmpty
            ? 'Driver Statistics: $resolvedDriverName'
            : 'Driver Statistics',
        entityName: resolvedDriverName.isNotEmpty ? resolvedDriverName : null,
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
            labelAr: 'رسوم التوصيل',
            labelEn: 'Delivery Fees',
            icon: Icons.local_shipping_outlined,
            value: (rows) {
              final total = rows.fold<double>(0, (s, r) {
                final del = r['deliveryFee'] != null
                    ? StatisticsFormat.numOf(r['deliveryFee'])
                    : StatisticsFormat.numOf(r['totalEarnings']) * 1.25;
                return s + del;
              });
              return '${total.toStringAsFixed(2)} EGP';
            },
          ),
          StatisticSummaryItem(
            labelAr: 'مسؤول السائقين',
            labelEn: 'Manager Cut',
            icon: Icons.badge_outlined,
            value: (rows) {
              final total = rows.fold<double>(0, (s, r) {
                final del = r['deliveryFee'] != null
                    ? StatisticsFormat.numOf(r['deliveryFee'])
                    : StatisticsFormat.numOf(r['totalEarnings']) * 1.25;
                final mgr = r['driverManagerCommission'] != null
                    ? StatisticsFormat.numOf(r['driverManagerCommission'])
                    : del * 0.1;
                return s + mgr;
              });
              return '${total.toStringAsFixed(2)} EGP';
            },
          ),
          StatisticSummaryItem(
            labelAr: 'أرباح المنصة',
            labelEn: 'Platform Profit',
            icon: Icons.account_balance_outlined,
            value: (rows) {
              final total = rows.fold<double>(0, (s, r) {
                final earn = StatisticsFormat.numOf(r['totalEarnings']);
                final del = r['deliveryFee'] != null
                    ? StatisticsFormat.numOf(r['deliveryFee'])
                    : earn * 1.25;
                final mgr = r['driverManagerCommission'] != null
                    ? StatisticsFormat.numOf(r['driverManagerCommission'])
                    : del * 0.1;
                final plat = r['platformProfit'] != null
                    ? StatisticsFormat.numOf(r['platformProfit'])
                    : (del - earn - mgr).clamp(0.0, double.infinity);
                return s + plat;
              });
              return '${total.toStringAsFixed(2)} EGP';
            },
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
                labelAr: 'أرباح السائق',
                labelEn: 'Driver Earnings',
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
              StatisticExportColumn(
                labelAr: 'نسبة مسؤول السائقين',
                labelEn: 'Manager Cut',
                value: (row) {
                  final del = row['deliveryFee'] != null
                      ? StatisticsFormat.numOf(row['deliveryFee'])
                      : StatisticsFormat.numOf(row['totalEarnings']) * 1.25;
                  final mgr = row['driverManagerCommission'] != null
                      ? StatisticsFormat.numOf(row['driverManagerCommission'])
                      : del * 0.1;
                  return '${mgr.toStringAsFixed(2)} EGP';
                },
              ),
              StatisticExportColumn(
                labelAr: 'أرباح المنصة',
                labelEn: 'Platform Profit',
                value: (row) {
                  final earn = StatisticsFormat.numOf(row['totalEarnings']);
                  final del = row['deliveryFee'] != null
                      ? StatisticsFormat.numOf(row['deliveryFee'])
                      : earn * 1.25;
                  final mgr = row['driverManagerCommission'] != null
                      ? StatisticsFormat.numOf(row['driverManagerCommission'])
                      : del * 0.1;
                  final plat = row['platformProfit'] != null
                      ? StatisticsFormat.numOf(row['platformProfit'])
                      : (del - earn - mgr).clamp(0.0, double.infinity);
                  return '${plat.toStringAsFixed(2)} EGP';
                },
              ),
            ],
          ),
          StatisticExportSection(
            titleAr: 'إحصائيات الطلبات وساعات العمل',
            titleEn: 'Orders & Operations Breakdown',
            columns: [
              StatisticExportColumn(
                labelAr: 'إجمالي الطلبات',
                labelEn: 'Total Orders',
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
            labelAr: 'رسوم التوصيل',
            labelEn: 'Delivery Fee',
            value: (row) {
              final del = row['deliveryFee'] != null
                  ? StatisticsFormat.numOf(row['deliveryFee'])
                  : StatisticsFormat.numOf(row['totalEarnings']) * 1.25;
              return del.toStringAsFixed(2);
            },
          ),
          StatisticExportColumn(
            labelAr: 'نسبة مسؤول السائقين',
            labelEn: 'Manager Share',
            value: (row) {
              final del = row['deliveryFee'] != null
                  ? StatisticsFormat.numOf(row['deliveryFee'])
                  : StatisticsFormat.numOf(row['totalEarnings']) * 1.25;
              final mgr = row['driverManagerCommission'] != null
                  ? StatisticsFormat.numOf(row['driverManagerCommission'])
                  : del * 0.1;
              return mgr.toStringAsFixed(2);
            },
          ),
          StatisticExportColumn(
            labelAr: 'أرباح المنصة',
            labelEn: 'Platform Profit',
            value: (row) {
              final earn = StatisticsFormat.numOf(row['totalEarnings']);
              final del = row['deliveryFee'] != null
                  ? StatisticsFormat.numOf(row['deliveryFee'])
                  : earn * 1.25;
              final mgr = row['driverManagerCommission'] != null
                  ? StatisticsFormat.numOf(row['driverManagerCommission'])
                  : del * 0.1;
              final plat = row['platformProfit'] != null
                  ? StatisticsFormat.numOf(row['platformProfit'])
                  : (del - earn - mgr).clamp(0.0, double.infinity);
              return plat.toStringAsFixed(2);
            },
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