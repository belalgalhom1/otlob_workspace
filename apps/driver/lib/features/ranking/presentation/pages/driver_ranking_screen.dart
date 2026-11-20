import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:driver/features/ranking/presentation/driver_ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

class DriverRankingScreen extends ConsumerWidget {
  const DriverRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(driverRankingSummaryProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'الشارة والتصنيف الأسبوعي' : 'Weekly Badge & Ranking',
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'تحديث' : 'Refresh',
            onPressed: () => ref.invalidate(driverRankingSummaryProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.circleAlert,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  ErrorUtils.translate(context, err),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(driverRankingSummaryProvider),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverRankingSummaryProvider);
            await ref.read(driverRankingSummaryProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _HeroBadgeCard(summary: summary, isAr: isAr),
              const SizedBox(height: 16),
              _TierThresholdsLegendCard(
                currentTier: summary.currentTier,
                isAr: isAr,
              ),
              const SizedBox(height: 20),
              if (summary.currentWeekProgress != null) ...[
                _CurrentWeekProgressSection(
                  week: summary.currentWeek,
                  progress: summary.currentWeekProgress!,
                  isAr: isAr,
                ),
                const SizedBox(height: 24),
              ],
              _RecentHistorySection(
                history: summary.recentHistory.toList(),
                isAr: isAr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverTierVisuals {
  final Color primary;
  final Color background;
  final Color border;
  final IconData icon;
  final String labelEn;
  final String labelAr;
  final String rangeLabel;

  const DriverTierVisuals({
    required this.primary,
    required this.background,
    required this.border,
    required this.icon,
    required this.labelEn,
    required this.labelAr,
    required this.rangeLabel,
  });

  String label(bool isAr) => isAr ? labelAr : labelEn;

  static DriverTierVisuals of(DriverTier tier, {bool isDark = false}) {
    if (tier == DriverTier.GOLD) {
      return DriverTierVisuals(
        primary: const Color(0xFFD4920E),
        background: const Color(0xFFD4920E).withValues(alpha: isDark ? 0.18 : 0.12),
        border: const Color(0xFFD4920E).withValues(alpha: 0.45),
        icon: LucideIcons.trophy,
        labelEn: 'Gold Badge',
        labelAr: 'الشارة الذهبية',
        rangeLabel: '≥ 95%',
      );
    }
    if (tier == DriverTier.SILVER) {
      return DriverTierVisuals(
        primary: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        background: const Color(0xFF64748B).withValues(alpha: isDark ? 0.22 : 0.12),
        border: const Color(0xFF64748B).withValues(alpha: 0.45),
        icon: LucideIcons.award,
        labelEn: 'Silver Badge',
        labelAr: 'الشارة الفضية',
        rangeLabel: '85% – 94.99%',
      );
    }
    return DriverTierVisuals(
      primary: const Color(0xFFB45309),
      background: const Color(0xFFB45309).withValues(alpha: isDark ? 0.20 : 0.12),
      border: const Color(0xFFB45309).withValues(alpha: 0.45),
      icon: LucideIcons.shield,
      labelEn: 'Bronze Badge',
      labelAr: 'الشارة البرونزية',
      rangeLabel: '< 85%',
    );
  }
}

class _HeroBadgeCard extends StatelessWidget {
  final DriverMyRankSummaryResponseDto summary;
  final bool isAr;

  const _HeroBadgeCard({required this.summary, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visuals = DriverTierVisuals.of(summary.currentTier, isDark: isDark);
    final nextEvalLocal = summary.nextEvaluationAt.toLocal();
    final nextEvalFormatted = DateFormat(
      'EEEE, d MMM • h:mm a',
      isAr ? 'ar' : 'en',
    ).format(nextEvalLocal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: visuals.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: visuals.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: visuals.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: visuals.border, width: 1.5),
                ),
                child: Icon(visuals.icon, color: visuals.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'شارتك الأسبوعية الحالية' : 'Your Current Weekly Badge',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      visuals.label(isAr),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: visuals.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: visuals.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: visuals.border),
                ),
                child: Text(
                  summary.currentTier.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: visuals.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                LucideIcons.calendarClock,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'التقييم الأسبوعي القادم: $nextEvalFormatted'
                      : 'Next Weekly Evaluation: $nextEvalFormatted',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierThresholdsLegendCard extends StatelessWidget {
  final DriverTier currentTier;
  final bool isAr;

  const _TierThresholdsLegendCard({
    required this.currentTier,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tiers = [DriverTier.GOLD, DriverTier.SILVER, DriverTier.BRONZE];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.sparkles,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'مستويات التصنيف الأسبوعي (متوسط 3 مؤشرات متساوية)'
                      : 'Weekly Badge Thresholds (Equal Average of 3 KPIs)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < tiers.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final tier = tiers[i];
                      final v = DriverTierVisuals.of(tier, isDark: isDark);
                      final isCurrent = tier == currentTier;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? v.background
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? v.primary
                                : Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.3),
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(v.icon, size: 18, color: v.primary),
                            const SizedBox(height: 6),
                            Text(
                              v.label(isAr),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: v.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v.rangeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentWeekProgressSection extends StatelessWidget {
  final RankingWeekWindowDto week;
  final DriverRankingPreviewItemDto progress;
  final bool isAr;

  const _CurrentWeekProgressSection({
    required this.week,
    required this.progress,
    required this.isAr,
  });

  String _outcomeLabel(DriverRankingOutcome outcome) {
    if (outcome == DriverRankingOutcome.PROMOTED) {
      return isAr ? 'ترقية متوقعة' : 'Projected Promotion';
    }
    if (outcome == DriverRankingOutcome.DEMOTED) {
      return isAr ? 'تراجع متوقع' : 'Projected Demotion';
    }
    if (outcome == DriverRankingOutcome.INACTIVE_SILVER) {
      return isAr ? 'لا يوجد نشاط بعد (فضية)' : 'No Activity Yet (Silver)';
    }
    if (outcome == DriverRankingOutcome.CAPPED_SILVER) {
      return isAr
          ? 'حد أقصى فضية (بدون طلبات مكتملة)'
          : 'Capped at Silver (No Orders)';
    }
    return isAr ? 'ثبات في التصنيف' : 'Maintaining Tier';
  }

  Color _outcomeColor(DriverRankingOutcome outcome) {
    if (outcome == DriverRankingOutcome.PROMOTED) return AppColors.success;
    if (outcome == DriverRankingOutcome.DEMOTED) return AppColors.error;
    if (outcome == DriverRankingOutcome.CAPPED_SILVER ||
        outcome == DriverRankingOutcome.INACTIVE_SILVER) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectedVisuals = DriverTierVisuals.of(
      progress.newTier,
      isDark: isDark,
    );
    final outcomeCol = _outcomeColor(progress.outcome);
    final snap = progress.metricsSnapshot;
    final scoreText = progress.performancePercentage != null
        ? '${progress.performancePercentage!.toStringAsFixed(1)}%'
        : (isAr ? 'لا يوجد نشاط' : 'No activity');

    final excludedNonFaultCount =
        snap.excludedIncidents.customer.toInt() +
        snap.excludedIncidents.vendor.toInt() +
        snap.excludedIncidents.externalOrSystem.toInt() +
        snap.excludedIncidents.underReview.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isAr
                    ? 'أداء الأسبوع الحالي (${week.periodKey})'
                    : 'Current Week Progress (${week.periodKey})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${DateFormat('d MMM', isAr ? 'ar' : 'en').format(week.periodStart.toLocal())} → ${DateFormat('d MMM', isAr ? 'ar' : 'en').format(week.periodEnd.toLocal())}',
              style: TextStyle(
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? 'إجمالي نسبة الأداء الأسبوعي'
                              : 'Overall Weekly Performance Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scoreText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: projectedVisuals.background,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: projectedVisuals.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              projectedVisuals.icon,
                              size: 14,
                              color: projectedVisuals.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              projectedVisuals.label(isAr),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: projectedVisuals.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: outcomeCol.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _outcomeLabel(progress.outcome),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: outcomeCol,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _KpiMetricCard(
                icon: LucideIcons.bellRing,
                title: isAr
                    ? '1. معدل قبول الطلبات الموجهة'
                    : '1. Dispatch Acceptance Rate',
                subtitle: isAr
                    ? 'الطلبات المقبولة ÷ (المقبولة + المرفوضة + المنتهية)'
                    : 'Accepted ÷ (Accepted + Rejected + Expired)',
                rate: progress.acceptanceRate?.toDouble(),
                chips: [
                  _MetricChipData(
                    label: isAr ? 'مقبولة' : 'Accepted',
                    value: '${snap.acceptedDispatches.toInt()}',
                    color: AppColors.success,
                  ),
                  _MetricChipData(
                    label: isAr ? 'مرفوضة' : 'Rejected',
                    value: '${snap.rejectedDispatches.toInt()}',
                    color: AppColors.error,
                  ),
                  _MetricChipData(
                    label: isAr ? 'منتهية' : 'Expired',
                    value: '${snap.expiredDispatches.toInt()}',
                    color: AppColors.warning,
                  ),
                  if (snap.cancelledDispatches > 0)
                    _MetricChipData(
                      label: isAr ? 'ملغاة (مستبعدة)' : 'Cancelled (Excluded)',
                      value: '${snap.cancelledDispatches.toInt()}',
                      color: Colors.grey,
                    ),
                ],
                isAr: isAr,
              ),
              const SizedBox(height: 12),
              _KpiMetricCard(
                icon: LucideIcons.packageCheck,
                title: isAr
                    ? '2. معدل إتمام الطلبات المسندة'
                    : '2. Order Completion Rate',
                subtitle: isAr
                    ? 'المكتملة ÷ (المكتملة + إخفاقات بسبب السائق)'
                    : 'Completed ÷ (Completed + Driver-Fault Failures)',
                rate: progress.completionRate?.toDouble(),
                chips: [
                  _MetricChipData(
                    label: isAr ? 'مكتملة' : 'Completed',
                    value: '${snap.completedOrders.toInt()}',
                    color: AppColors.success,
                  ),
                  _MetricChipData(
                    label: isAr ? 'بسبب السائق' : 'Driver Fault',
                    value: '${snap.driverFaultFailures.toInt()}',
                    color: AppColors.error,
                  ),
                  if (excludedNonFaultCount > 0)
                    _MetricChipData(
                      label: isAr
                          ? 'مستبعدة (عميل/متجر/نظام)'
                          : 'Excluded (Customer/Vendor/System)',
                      value: '$excludedNonFaultCount',
                      color: Colors.teal,
                    ),
                ],
                isAr: isAr,
              ),
              const SizedBox(height: 12),
              _KpiMetricCard(
                icon: LucideIcons.clockCheck,
                title: isAr
                    ? '3. معدل الانضباط في الورديات'
                    : '3. Shift Punctuality Rate',
                subtitle: isAr
                    ? 'الالتزام بالموعد (سماحية 10 دقائق) ÷ الورديات المحتسبة'
                    : 'On-Time (10m grace) ÷ Eligible Shifts',
                rate: progress.shiftPunctualityRate?.toDouble(),
                chips: [
                  _MetricChipData(
                    label: isAr ? 'في الموعد' : 'On-Time',
                    value: '${snap.onTimeShifts.toInt()}',
                    color: AppColors.success,
                  ),
                  _MetricChipData(
                    label: isAr ? 'متأخرة (>10 د)' : 'Late (>10m)',
                    value: '${snap.lateShifts.toInt()}',
                    color: AppColors.warning,
                  ),
                  _MetricChipData(
                    label: isAr ? 'فائتة' : 'Missed',
                    value: '${snap.missedShifts.toInt()}',
                    color: AppColors.error,
                  ),
                  if (snap.excusedShifts > 0)
                    _MetricChipData(
                      label: isAr ? 'معذورة (مستبعدة)' : 'Excused (Excluded)',
                      value: '${snap.excusedShifts.toInt()}',
                      color: Colors.teal,
                    ),
                ],
                isAr: isAr,
              ),
              if (progress.explanations.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'ملاحظات احتساب التقييم' : 'Evaluation Details',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final exp in progress.explanations)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '• $exp',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChipData {
  final String label;
  final String value;
  final Color color;

  const _MetricChipData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _KpiMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double? rate;
  final List<_MetricChipData> chips;
  final bool isAr;

  const _KpiMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rate,
    required this.chips,
    required this.isAr,
  });

  Color _rateColor(double? r) {
    if (r == null) return Colors.grey;
    if (r >= 95) return const Color(0xFFD4920E);
    if (r >= 85) return AppColors.success;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _rateColor(rate);
    final rateLabel = rate != null
        ? '${rate!.toStringAsFixed(1)}%'
        : (isAr ? 'غير محتسب' : 'N/A');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (rate != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (rate! / 100.0).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: Theme.of(
                  context,
                ).dividerColor.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final chip in chips)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chip.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: chip.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${chip.label}: ${chip.value}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: chip.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentHistorySection extends StatelessWidget {
  final List<DriverRankHistoryEntryDto> history;
  final bool isAr;

  const _RecentHistorySection({required this.history, required this.isAr});

  String _reasonLabel(DriverRankChangeReason reason) {
    if (reason == DriverRankChangeReason.ADMIN_OVERRIDE) {
      return isAr ? 'تعديل إداري' : 'Admin Override';
    }
    if (reason == DriverRankChangeReason.INACTIVE_DRIVER) {
      return isAr ? 'عدم وجود نشاط أسبوعي' : 'Inactive Week';
    }
    return isAr ? 'تقييم أسبوعي' : 'Weekly Evaluation';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'سجل التقييمات السابقة' : 'Evaluation & Badge History',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.history,
                  size: 36,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 10),
                Text(
                  isAr
                      ? 'لا توجد تقييمات أسبوعية سابقة بعد'
                      : 'No weekly evaluation history yet',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in history) ...[
            Builder(
              builder: (context) {
                final prevVisual = DriverTierVisuals.of(
                  item.previousTier,
                  isDark: isDark,
                );
                final newVisual = DriverTierVisuals.of(
                  item.newTier,
                  isDark: isDark,
                );
                final periodKey = item.periodKey.asStringOrNull;
                final overrideNote = item.overrideReason.asStringOrNull;
                final dateStr = DateFormat(
                  'd MMM yyyy • h:mm a',
                  isAr ? 'ar' : 'en',
                ).format(item.evaluatedAt.toLocal());

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            newVisual.icon,
                            size: 18,
                            color: newVisual.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              periodKey != null
                                  ? '${_reasonLabel(item.changeReason)} ($periodKey)'
                                  : _reasonLabel(item.changeReason),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.performancePercentage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.performancePercentage!.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: prevVisual.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prevVisual.label(isAr),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: prevVisual.primary,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(LucideIcons.arrowRight, size: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: newVisual.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: newVisual.border),
                            ),
                            child: Text(
                              newVisual.label(isAr),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: newVisual.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                      if (overrideNote != null && overrideNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          isAr ? 'السبب: $overrideNote' : 'Reason: $overrideNote',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
      ],
    );
  }
}
