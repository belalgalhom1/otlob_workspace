import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

import 'driver_statistics_provider.dart';
import 'driver_statistics_screen.dart';

/// Combined statistics for every driver a manager is responsible for.
///
/// Unlike [DriverStatisticsScreen] (one driver), this screen answers "how is my
/// whole fleet doing?" and lets the manager drill into any single driver.
class AllDriversStatisticsScreen extends ConsumerStatefulWidget {
  const AllDriversStatisticsScreen({super.key});

  @override
  ConsumerState<AllDriversStatisticsScreen> createState() =>
      _AllDriversStatisticsScreenState();
}

class _AllDriversStatisticsScreenState
    extends ConsumerState<AllDriversStatisticsScreen> {
  static const _periods = ['DAILY', 'WEEKLY', 'MONTHLY'];
  String _period = 'DAILY';
  DateTimeRange? _customRange;
  bool _exporting = false;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _periodLabel(String period) {
    switch (period) {
      case 'WEEKLY':
        return _isArabic ? 'أسبوعي' : 'Weekly';
      case 'MONTHLY':
        return _isArabic ? 'شهري' : 'Monthly';
      default:
        return _isArabic ? 'يومي' : 'Daily';
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: _isArabic ? 'اختر الفترة الزمنية' : 'Select date range',
      saveText: _isArabic ? 'حفظ' : 'Save',
      initialDateRange:
          _customRange ?? DateTimeRange(start: DateTime(now.year), end: now),
      builder: AppDialogStyles.adaptivePickerTheme,
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  /// Query for the selected period. The backend turns [limit] into a look-back
  /// window, so keep it period-aware (30 days / 12 weeks / 12 months).
  ({String period, int limit, DateTime? from, DateTime? to}) get _query => (
    period: _period,
    limit: switch (_period) {
      'WEEKLY' => 12,
      'MONTHLY' => 12,
      _ => 30,
    },
    from: _customRange?.start,
    to: _customRange?.end,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final async = ref.watch(allManagedDriversStatsProvider(_query));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isArabic ? 'إحصائيات كل السائقين' : 'All Drivers Statistics',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isArabic ? 'تصدير التقرير (PDF/Excel)' : 'Export Report (PDF/Excel)',
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(LucideIcons.download, color: textColor),
            onPressed: _exporting ? null : () => _export(context),
          ),
          IconButton(
            tooltip: _isArabic ? 'تحديث' : 'Refresh',
            icon: Icon(LucideIcons.refreshCw, color: textColor),
            onPressed: () => ref.invalidate(
              allManagedDriversStatsProvider(_query),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                for (final period in _periods) ...[
                  Expanded(
                    child: _PeriodChip(
                      label: _periodLabel(period),
                      selected: _customRange == null && _period == period,
                      onTap: () => setState(() {
                        _customRange = null;
                        _period = period;
                      }),
                    ),
                  ),
                  if (period != _periods.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(LucideIcons.calendar, size: 14),
                  label: Text(
                    _isArabic ? 'فترة مخصصة' : 'Custom range',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_customRange != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${DateFormat('yyyy-MM-dd').format(_customRange!.start)}'
                              ' - '
                              '${DateFormat('yyyy-MM-dd').format(_customRange!.end)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.primary
                                    : const Color(0xFF92400E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _customRange = null),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                LucideIcons.x,
                                size: 14,
                                color: isDark
                                    ? AppColors.primary
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: '$error',
                isArabic: _isArabic,
                onRetry: () => ref.invalidate(
                  allManagedDriversStatsProvider(_query),
                ),
              ),
              data: (data) => _buildData(context, data, isDark, textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildData(
    BuildContext context,
    Map<String, dynamic> data,
    bool isDark,
    Color textColor,
  ) {
    final totals = data['totals'] is Map
        ? Map<String, dynamic>.from(data['totals'] as Map)
        : <String, dynamic>{};
    final drivers = data['drivers'] is List
        ? (data['drivers'] as List).whereType<Map>().map((e) {
            return Map<String, dynamic>.from(e);
          }).toList()
        : <Map<String, dynamic>>[];

    if (drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 52,
              color: textColor.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              _isArabic
                  ? 'لا توجد بيانات سائقين في هذه الفترة'
                  : 'No driver data for this period',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.45),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    final totalOrders = StatisticsFormat.intOf(totals['totalOrders']);
    final completed = StatisticsFormat.intOf(totals['completedOrders']);
    final cancelled = StatisticsFormat.intOf(totals['cancelledOrders']);
    final received = StatisticsFormat.intOf(totals['totalDispatchesReceived']);
    final accepted = StatisticsFormat.intOf(totals['dispatchesAccepted']);
    final acceptance = received > 0 ? (accepted * 100 / received).round() : 0;
    final earnings = StatisticsFormat.numOf(totals['totalEarnings']);
    final onlineHours = StatisticsFormat.numOf(totals['onlineHours']);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(
        allManagedDriversStatsProvider(_query),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            isArabic: _isArabic,
            earnings: earnings,
            orders: totalOrders,
            completed: completed,
            cancelled: cancelled,
            onlineHours: onlineHours,
            acceptance: acceptance,
            driverCount: drivers.length,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                _isArabic ? 'السائقون' : 'Drivers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                '${drivers.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _exporting ? null : () => _export(context),
                icon: const Icon(LucideIcons.download, size: 13),
                label: Text(
                  _isArabic ? 'تصدير' : 'Export',
                  style: const TextStyle(fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < drivers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DriverStatCard(
                rank: i + 1,
                driver: drivers[i],
                isArabic: _isArabic,
                isDark: isDark,
                textColor: textColor,
                onTap: () {
                  final id = drivers[i]['driverId']?.toString() ?? '';
                  if (id.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DriverStatisticsScreen(
                        driverId: id,
                        driverName: drivers[i]['name']?.toString(),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final data = await ref.read(allManagedDriversStatsProvider(_query).future);
      if (!context.mounted) return;

      final drivers = data['drivers'] is List
          ? (data['drivers'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      if (drivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? 'لا توجد بيانات متاحة للتصدير' : 'No data available to export',
            ),
          ),
        );
        return;
      }

      final totals = data['totals'] is Map
          ? Map<String, dynamic>.from(data['totals'] as Map)
          : <String, dynamic>{};

      final totalOrders = StatisticsFormat.intOf(totals['totalOrders']);
      final completed = StatisticsFormat.intOf(totals['completedOrders']);
      final cancelled = StatisticsFormat.intOf(totals['cancelledOrders']);
      final received = StatisticsFormat.intOf(totals['totalDispatchesReceived']);
      final accepted = StatisticsFormat.intOf(totals['dispatchesAccepted']);
      final rejected = StatisticsFormat.intOf(totals['dispatchesRejected']);
      final expired = StatisticsFormat.intOf(totals['dispatchesExpired']);
      final acceptance = received > 0 ? (accepted * 100 / received).round() : 0;
      final earnings = StatisticsFormat.numOf(totals['totalEarnings']);
      final onlineHours = StatisticsFormat.numOf(totals['onlineHours']);

      final isArabic = _isArabic;

      // Section 1: Fleet Totals Summary
      final s1Headers = [
        isArabic ? 'المؤشر' : 'Metric',
        isArabic ? 'القيمة' : 'Value',
      ];
      final s1Rows = [
        [
          isArabic ? 'إجمالي أرباح الفريق' : 'Total Fleet Earnings',
          '${earnings.toStringAsFixed(2)} EGP',
        ],
        [
          isArabic ? 'إجمالي الطلبات' : 'Total Orders',
          '$totalOrders',
        ],
        [
          isArabic ? 'الطلبات المكتملة' : 'Completed Orders',
          '$completed',
        ],
        [
          isArabic ? 'الطلبات الملغية' : 'Cancelled Orders',
          '$cancelled',
        ],
        [
          isArabic ? 'إجمالي ساعات العمل' : 'Total Online Hours',
          '${onlineHours.toStringAsFixed(1)} h',
        ],
        [
          isArabic ? 'متوسط نسبة القبول' : 'Overall Acceptance Rate',
          '$acceptance%',
        ],
        [
          isArabic ? 'عدد السائقين النشطين' : 'Active Fleet Drivers',
          '${drivers.length}',
        ],
        [
          isArabic ? 'الطلبات المعروضة' : 'Total Dispatches Received',
          '$received',
        ],
        [
          isArabic ? 'الطلبات المقبولة' : 'Dispatches Accepted',
          '$accepted',
        ],
        [
          isArabic ? 'الطلبات المرفوضة' : 'Dispatches Rejected',
          '$rejected',
        ],
        [
          isArabic ? 'الطلبات المنتهية' : 'Dispatches Expired',
          '$expired',
        ],
      ];

      // Section 2: Driver Performance Breakdown
      final s2Headers = [
        '#',
        isArabic ? 'السائق' : 'Driver',
        isArabic ? 'الهاتف' : 'Phone',
        isArabic ? 'الحالة' : 'Status',
        isArabic ? 'الأرباح' : 'Earnings',
        isArabic ? 'الطلبات' : 'Orders',
        isArabic ? 'المكتملة' : 'Completed',
        isArabic ? 'الملغية' : 'Cancelled',
        isArabic ? 'ساعات العمل' : 'Online Hours',
        isArabic ? 'القبول' : 'Acceptance',
      ];

      String translateDriverStatus(String status) {
        switch (status.toUpperCase()) {
          case 'ONLINE':
            return isArabic ? 'متصل' : 'Online';
          case 'ON_DELIVERY':
            return isArabic ? 'في رحلة توصيل' : 'On Delivery';
          case 'ON_BREAK':
            return isArabic ? 'في استراحة' : 'On Break';
          case 'OFFLINE':
            return isArabic ? 'غير متصل' : 'Offline';
          case 'SUSPENDED':
            return isArabic ? 'موقوف' : 'Suspended';
          default:
            return status;
        }
      }

      final s2Rows = <List<String>>[];
      for (var i = 0; i < drivers.length; i++) {
        final d = drivers[i];
        final name = (d['name']?.toString().trim().isNotEmpty ?? false)
            ? d['name'].toString().trim()
            : (isArabic ? 'سائق' : 'Driver');
        final phone = d['phone']?.toString().trim() ?? '';
        final status = d['status']?.toString() ?? 'OFFLINE';
        final dOrders = StatisticsFormat.intOf(d['totalOrders']);
        final dCompleted = StatisticsFormat.intOf(d['completedOrders']);
        final dCancelled = StatisticsFormat.intOf(d['cancelledOrders']);
        final dEarnings = StatisticsFormat.numOf(d['totalEarnings']);
        final dHours = StatisticsFormat.numOf(d['onlineHours']);
        final dReceived = StatisticsFormat.intOf(d['totalDispatchesReceived']);
        final dAccepted = StatisticsFormat.intOf(d['dispatchesAccepted']);
        final dAcceptance = dReceived > 0 ? (dAccepted * 100 / dReceived).round() : 0;

        s2Rows.add([
          '${i + 1}',
          name,
          phone.isNotEmpty ? phone : '-',
          translateDriverStatus(status),
          '${dEarnings.toStringAsFixed(2)} EGP',
          '$dOrders',
          '$dCompleted',
          '$dCancelled',
          '${dHours.toStringAsFixed(1)} h',
          '$dAcceptance%',
        ]);
      }

      final rangeSubtitle = _customRange != null
          ? '${DateFormat('yyyy-MM-dd').format(_customRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_customRange!.end)}'
          : isArabic
              ? 'تقرير ${_periodLabel(_period)} (${drivers.length} سائق)'
              : '${_periodLabel(_period)} Report (${drivers.length} drivers)';

      await DataExportService.showExportOptions(
        context,
        title: isArabic ? 'تقرير إحصائيات كل السائقين' : 'All Drivers Fleet Statistics',
        subtitle: rangeSubtitle,
        sections: [
          ExportSection(
            title: isArabic ? 'ملخص إجماليات الفريق' : 'Fleet Totals Summary',
            headers: s1Headers,
            rows: s1Rows,
          ),
          ExportSection(
            title: isArabic ? 'تفاصيل أداء السائقين' : 'Driver Performance Breakdown',
            headers: s2Headers,
            rows: s2Rows,
          ),
        ],
        headers: s2Headers,
        rows: s2Rows,
        filename: 'all_drivers_statistics_${_customRange != null ? 'custom' : _period.toLowerCase()}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic ? 'فشل التصدير: $e' : 'Export failed: $e',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : borderColor,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected
                    ? AppColors.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isArabic;
  final double earnings;
  final int orders;
  final int completed;
  final int cancelled;
  final double onlineHours;
  final int acceptance;
  final int driverCount;

  const _SummaryCard({
    required this.isArabic,
    required this.earnings,
    required this.orders,
    required this.completed,
    required this.cancelled,
    required this.onlineHours,
    required this.acceptance,
    required this.driverCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isArabic ? 'إجماليات الفريق' : 'Fleet Totals',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  isArabic ? '$driverCount سائق' : '$driverCount drivers',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: isArabic ? 'الأرباح' : 'Earnings',
                  value: '${earnings.toStringAsFixed(2)} EGP',
                  highlight: true,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: isArabic ? 'الطلبات' : 'Orders',
                  value: '$orders',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: isArabic ? 'المكتملة' : 'Completed',
                  value: '$completed',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: isArabic ? 'الملغية' : 'Cancelled',
                  value: '$cancelled',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: isArabic ? 'ساعات العمل' : 'Online Hours',
                  value: '${onlineHours.toStringAsFixed(1)} h',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: isArabic ? 'نسبة القبول' : 'Acceptance',
                  value: '$acceptance%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Metric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: highlight ? 17 : 15,
          ),
        ),
      ],
    );
  }
}

class _DriverStatCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> driver;
  final bool isArabic;
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;

  const _DriverStatCard({
    required this.rank,
    required this.driver,
    required this.isArabic,
    required this.isDark,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (driver['name']?.toString().trim().isNotEmpty ?? false)
        ? driver['name'].toString().trim()
        : (isArabic ? 'سائق' : 'Driver');
    final rawAvatar = driver['avatar']?.toString() ?? '';
    final avatarUrl =
        rawAvatar.isEmpty ? '' : ImageUtils.formatImageUrl(rawAvatar);
    final orders = StatisticsFormat.intOf(driver['totalOrders']);
    final completed = StatisticsFormat.intOf(driver['completedOrders']);
    final earnings = StatisticsFormat.numOf(driver['totalEarnings']);
    final hours = StatisticsFormat.numOf(driver['onlineHours']);
    final received = StatisticsFormat.intOf(driver['totalDispatchesReceived']);
    final accepted = StatisticsFormat.intOf(driver['dispatchesAccepted']);
    final acceptance = received > 0 ? (accepted * 100 / received).round() : 0;
    final status = driver['status']?.toString() ?? 'OFFLINE';

    final statusColor = switch (status) {
      'ONLINE' => AppColors.success,
      'ON_DELIVERY' => Colors.blue,
      'ON_BREAK' => AppColors.warning,
      'SUSPENDED' => AppColors.error,
      _ => Colors.grey,
    };

    final theme = Theme.of(context);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final earningsColor = isDark ? AppColors.success : const Color(0xFF047857);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rank <= 3
                            ? (isDark ? AppColors.primary : const Color(0xFF92400E))
                            : textColor.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 21,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage:
                        avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArabic
                              ? '$orders طلب · $acceptance% قبول'
                              : '$orders orders · $acceptance% acceptance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textColor.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        earnings.toStringAsFixed(2),
                        style: TextStyle(
                          color: earningsColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        isArabic ? 'جنيه' : 'EGP',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isArabic
                        ? LucideIcons.chevronLeft
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(
                    icon: LucideIcons.checkCircle2,
                    text: isArabic
                        ? 'مكتملة $completed'
                        : 'Completed $completed',
                  ),
                  _Chip(
                    icon: LucideIcons.clock3,
                    text: '${hours.toStringAsFixed(1)} h',
                  ),
                  _Chip(
                    icon: LucideIcons.truck,
                    text: isArabic ? 'طلبات $orders' : 'Orders $orders',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDark ? AppColors.primary : const Color(0xFF92400E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isArabic;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.isArabic,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.triangleAlert,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'تعذر تحميل الإحصائيات' : 'Could not load statistics',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
