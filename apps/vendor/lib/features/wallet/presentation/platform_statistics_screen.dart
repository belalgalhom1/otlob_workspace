import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../data/wallet_localization.dart';
import 'platform_statistics_provider.dart';

class PlatformStatisticsScreen extends ConsumerWidget {
  const PlatformStatisticsScreen({super.key});

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
        titleAr: 'إحصائيات المنصة',
        titleEn: 'Platform Statistics',
        chartTitleAr: 'اتجاه أرباح المنصة',
        chartTitleEn: 'Admin Revenue Trend',
        tooltipSuffix: cur(),
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
            value: (rows) => intFmt.format(
              rows.fold<int>(
                0,
                (s, r) => s + StatisticsFormat.intOf(r['totalOrders']),
              ),
            ),
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي أرباح المنصة',
            labelEn: 'Total Admin Revenue',
            icon: Icons.trending_up,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalAdminRevenue'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي رسوم التوصيل',
            labelEn: 'Total Delivery Fees',
            icon: Icons.local_shipping_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalDeliveryFees'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي الربح من رسوم التوصيل',
            labelEn: 'Delivery Fees Profit',
            icon: Icons.savings_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalDeliveryProfit'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي ربح السائقين',
            labelEn: 'Drivers Earnings',
            icon: Icons.delivery_dining_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalDriverEarnings'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي ربح مسؤولي السائقين',
            labelEn: 'Driver Managers Earnings',
            icon: Icons.supervisor_account_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalDriverManagerEarnings'])))} ${cur()}',
          ),
          StatisticSummaryItem(
            labelAr: 'إجمالي العمولات من المتاجر',
            labelEn: 'Vendor Commissions',
            icon: Icons.storefront_outlined,
            value: (rows) =>
                '${moneyFmt.format(rows.fold<double>(0, (s, r) => s + StatisticsFormat.numOf(r['totalVendorCommissions'])))} ${cur()}',
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
          StatisticExportColumn(
            labelAr: 'ربح التوصيل',
            labelEn: 'Delivery Profit',
            value: (row) => StatisticsFormat.numOf(row['totalDeliveryProfit'])
                .toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'ربح السائقين',
            labelEn: 'Drivers Earnings',
            value: (row) => StatisticsFormat.numOf(row['totalDriverEarnings'])
                .toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'ربح مسؤولي السائقين',
            labelEn: 'Managers Earnings',
            value: (row) =>
                StatisticsFormat.numOf(row['totalDriverManagerEarnings'])
                    .toStringAsFixed(2),
          ),
          StatisticExportColumn(
            labelAr: 'عمولات المتاجر',
            labelEn: 'Vendor Commissions',
            value: (row) =>
                StatisticsFormat.numOf(row['totalVendorCommissions'])
                    .toStringAsFixed(2),
          ),
        ],
        rowDetails: (row) {
          final orders = intFmt.format(StatisticsFormat.intOf(row['totalOrders']));
          final deliveryProfit = moneyFmt.format(
            StatisticsFormat.numOf(row['totalDeliveryProfit']),
          );
          final driverEarnings = moneyFmt.format(
            StatisticsFormat.numOf(row['totalDriverEarnings']),
          );
          final managerEarnings = moneyFmt.format(
            StatisticsFormat.numOf(row['totalDriverManagerEarnings']),
          );
          final vendorCommissions = moneyFmt.format(
            StatisticsFormat.numOf(row['totalVendorCommissions']),
          );
          final currency = cur();
          return [
            isArabic() ? '$orders طلب' : '$orders orders',
            isArabic()
                ? 'ربح التوصيل $deliveryProfit $currency'
                : 'Delivery profit $deliveryProfit $currency',
            isArabic()
                ? 'ربح السائقين $driverEarnings $currency'
                : 'Drivers $driverEarnings $currency',
            isArabic()
                ? 'مسؤولو السائقين $managerEarnings $currency'
                : 'Managers $managerEarnings $currency',
            isArabic()
                ? 'عمولات المتاجر $vendorCommissions $currency'
                : 'Vendor comm. $vendorCommissions $currency',
          ];
        },
      ),
    );
  }
}