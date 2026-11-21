import 'dart:async';

import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:vendor/features/drivers/data/driver_providers.dart';
import 'package:vendor/features/drivers/presentation/widgets/driver_rank_history_dialog.dart';

class DriverRankingAdminScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const DriverRankingAdminScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<DriverRankingAdminScreen> createState() =>
      _DriverRankingAdminScreenState();
}

class _DriverRankingAdminScreenState
    extends ConsumerState<DriverRankingAdminScreen> {
  bool _isDriverManager = false;
  bool _isAdminOrSuperAdmin = false;

  // Schedule status
  DriverRankingScheduleStatusDto? _schedule;
  bool _scheduleLoading = true;
  bool _runningEvaluation = false;

  // Tab 1: Dry-Run Preview state
  DriverRankingPreviewResponseDto? _preview;
  bool _previewLoading = true;
  String? _previewError;
  int _previewPage = 1;
  DriverTier? _previewTierFilter;
  final _previewSearchController = TextEditingController();
  Timer? _searchDebounce;

  // Tab 2: Evaluation Runs state
  PaginatedRankingRunsResponseDto? _runs;
  bool _runsLoading = true;
  String? _runsError;
  int _runsPage = 1;
  String? _retryingRunId;

  // Tab 3: Delivery Incidents state
  PaginatedDeliveryIncidentsResponseDto? _incidents;
  bool _incidentsLoading = true;
  String? _incidentsError;
  int _incidentsPage = 1;
  DeliveryIncidentResponsibility? _incidentRespFilter;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _previewSearchController.dispose();
    super.dispose();
  }

  void _onPreviewSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadPreview(page: 1);
    });
  }

  Future<void> _initScreen() async {
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    if (mounted) {
      setState(() {
        _isDriverManager = role == 'DRIVER_MANAGER';
        _isAdminOrSuperAdmin = role == 'SUPER_ADMIN' || role == 'ADMIN';
      });
    }
    await Future.wait([
      _loadSchedule(),
      _loadPreview(page: 1),
      _loadRuns(page: 1),
      _loadIncidents(page: 1),
    ]);
  }

  Future<void> _loadSchedule() async {
    setState(() => _scheduleLoading = true);
    try {
      final res = await ref
          .read(adminDriverRankingRepositoryProvider)
          .getScheduleStatus();
      if (mounted) {
        setState(() {
          _schedule = res;
          _scheduleLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _scheduleLoading = false);
      }
    }
  }

  Future<void> _loadPreview({int page = 1}) async {
    setState(() {
      _previewLoading = true;
      _previewError = null;
    });
    try {
      final res = await ref
          .read(adminDriverRankingRepositoryProvider)
          .previewEvaluation(
            page: page,
            limit: 25,
            search: _previewSearchController.text,
            tier: _previewTierFilter,
          );
      if (mounted) {
        setState(() {
          _preview = res;
          _previewPage = page;
          _previewLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _previewError = ErrorUtils.translate(context, e);
          _previewLoading = false;
        });
      }
    }
  }

  Future<void> _loadRuns({int page = 1}) async {
    setState(() {
      _runsLoading = true;
      _runsError = null;
    });
    try {
      final res = await ref
          .read(adminDriverRankingRepositoryProvider)
          .listRuns(page: page, limit: 15);
      if (mounted) {
        setState(() {
          _runs = res;
          _runsPage = page;
          _runsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _runsError = ErrorUtils.translate(context, e);
          _runsLoading = false;
        });
      }
    }
  }

  Future<void> _loadIncidents({int page = 1}) async {
    setState(() {
      _incidentsLoading = true;
      _incidentsError = null;
    });
    try {
      final res = await ref
          .read(adminDriverRankingRepositoryProvider)
          .listIncidents(
            page: page,
            limit: 15,
            responsibility: _incidentRespFilter,
          );
      if (mounted) {
        setState(() {
          _incidents = res;
          _incidentsPage = page;
          _incidentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _incidentsError = ErrorUtils.translate(context, e);
          _incidentsLoading = false;
        });
      }
    }
  }

  Future<void> _runEvaluationNow() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final periodKey =
        _preview?.week.periodKey ??
        _schedule?.lastCompletedWeek.periodKey ??
        '';
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isAr
          ? 'تنفيذ التقييم الأسبوعي الآن'
          : 'Run Weekly Evaluation Now',
      message: isAr
          ? 'سيتم تقييم أداء جميع السائقين للأسبوع المنتهي ($periodKey) وتحديث شاراتهم وإرسال إشعارات لهم فوراً. هل تريد المتابعة؟'
          : 'This will evaluate all drivers for completed week ($periodKey), update their badges, and notify them immediately. Proceed?',
      confirmLabel: isAr ? 'تنفيذ التقييم' : 'Run Evaluation',
      cancelLabel: isAr ? 'إلغاء' : 'Cancel',
      icon: LucideIcons.play,
      confirmIcon: LucideIcons.play,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _runningEvaluation = true);
    try {
      await ref.read(adminDriverRankingRepositoryProvider).runEvaluationNow();
      ref.read(driversProvider.notifier).refresh();
      await Future.wait([
        _loadSchedule(),
        _loadPreview(page: _previewPage),
        _loadRuns(page: 1),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم تنفيذ التقييم الأسبوعي بنجاح'
                  : 'Weekly ranking evaluation completed successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _runningEvaluation = false);
    }
  }

  Future<void> _retryFailedRun(String runId) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _retryingRunId = runId);
    try {
      await ref
          .read(adminDriverRankingRepositoryProvider)
          .retryFailedRun(runId);
      ref.read(driversProvider.notifier).refresh();
      await Future.wait([
        _loadSchedule(),
        _loadPreview(page: _previewPage),
        _loadRuns(page: _runsPage),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم استكمال التقييم الأسبوعي بنجاح'
                  : 'Failed evaluation run resumed and completed successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _retryingRunId = null);
    }
  }

  Future<void> _openScheduleSettingsDialog() async {
    final schedule = _schedule;
    if (schedule == null) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _ScheduleSettingsDialog(
        initialEnabled: schedule.enabled,
        initialEvalTime: schedule.evalTime,
        initialGoldThreshold: schedule.goldThreshold.toInt(),
        initialSilverThreshold: schedule.silverThreshold.toInt(),
      ),
    );
    if (updated == true && mounted) {
      await _loadSchedule();
      await _loadPreview(page: _previewPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isCompactTabs = MediaQuery.sizeOf(context).width < 720;

    final content = DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildScheduleHeader(context, isAr),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                ),
              ),
              child: TabBar(
                isScrollable: isCompactTabs,
                tabAlignment:
                    isCompactTabs ? TabAlignment.start : TabAlignment.fill,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
                tabs: [
                  Tab(
                    text: isAr
                        ? 'معاينة التقييم الأسبوعي'
                        : 'Dry-Run Preview',
                  ),
                  Tab(
                    text: isAr
                        ? 'سجل التشغيلات الأسبوعية'
                        : 'Evaluation Runs',
                  ),
                  Tab(
                    text: isAr
                        ? 'حوادث ومسؤولية التوصيل'
                        : 'Delivery Incidents',
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TabBarView(
            children: [
              _buildPreviewTab(context, isAr),
              _buildRunsTab(context, isAr),
              _buildIncidentsTab(context, isAr),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr
              ? 'نظام التصنيف الأسبوعي للسائقين'
              : 'Weekly Driver Ranking System',
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'تحديث' : 'Refresh',
            onPressed: _initScreen,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildScheduleHeader(BuildContext context, bool isAr) {
    final schedule = _schedule;
    final alreadyExecuted =
        (_preview?.alreadyExecuted == true) ||
        (schedule?.lastCompletedWeekRun?.status ==
            DriverRankingRunStatus.COMPLETED);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: _scheduleLoading && schedule == null
          ? const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            )
          : Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.trophy,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isAr
                                      ? 'جدولة التقييم الأسبوعي للسائقين'
                                      : 'Weekly Driver Ranking Schedule',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (schedule != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (schedule.enabled
                                                ? AppColors.success
                                                : Colors.grey)
                                            .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    schedule.enabled
                                        ? (isAr ? 'تلقائي مفعّل' : 'Auto Enabled')
                                        : (isAr ? 'تلقائي متوقف' : 'Auto Paused'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: schedule.enabled
                                          ? AppColors.success
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (schedule != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              isAr
                                  ? 'كل يوم إثنين الساعة ${schedule.evalTime} (${schedule.timezone}) • القادم: ${DateFormat('EEE d MMM • h:mm a', 'ar').format(schedule.nextEvaluationAt.toLocal())} • الذهبية: ≥ ${schedule.goldThreshold.toInt()}% • الفضية: ≥ ${schedule.silverThreshold.toInt()}%'
                                  : 'Every Monday at ${schedule.evalTime} (${schedule.timezone}) • Next: ${DateFormat('EEE d MMM • h:mm a', 'en').format(schedule.nextEvaluationAt.toLocal())} • Gold: ≥ ${schedule.goldThreshold.toInt()}% • Silver: ≥ ${schedule.silverThreshold.toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isAdminOrSuperAdmin && !_isDriverManager)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _schedule == null
                            ? null
                            : _openScheduleSettingsDialog,
                        icon: const Icon(LucideIcons.clock, size: 15),
                        label: Text(
                          isAr ? 'إعدادات الجدولة' : 'Schedule Settings',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: (_runningEvaluation || alreadyExecuted)
                            ? null
                            : _runEvaluationNow,
                        icon: _runningEvaluation
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                alreadyExecuted
                                    ? LucideIcons.check
                                    : LucideIcons.play,
                                size: 15,
                              ),
                        label: Text(
                          alreadyExecuted
                              ? (isAr
                                    ? 'تم تقييم الأسبوع المنتهي'
                                    : 'Week Already Evaluated')
                              : (isAr
                                    ? 'تنفيذ التقييم الآن'
                                    : 'Run Evaluation Now'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _buildPreviewTab(BuildContext context, bool isAr) {
    final preview = _preview;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (preview != null) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SummaryStatPill(
                        label: isAr ? 'الأسبوع المستهدف' : 'Target Week',
                        value: preview.week.periodKey,
                        color: AppColors.primary,
                        icon: LucideIcons.calendar,
                      ),
                      const SizedBox(width: 8),
                      _SummaryStatPill(
                        label: isAr ? 'إجمالي السائقين' : 'Total Drivers',
                        value: '${preview.totalDrivers.toInt()}',
                        color: AppColors.info,
                        icon: LucideIcons.users,
                      ),
                      const SizedBox(width: 8),
                      _SummaryStatPill(
                        label: isAr ? 'ترقية' : 'Promoted',
                        value: '${preview.promotedCount.toInt()}',
                        color: AppColors.success,
                        icon: LucideIcons.trendingUp,
                      ),
                      const SizedBox(width: 8),
                      _SummaryStatPill(
                        label: isAr ? 'تراجع' : 'Demoted',
                        value: '${preview.demotedCount.toInt()}',
                        color: AppColors.error,
                        icon: LucideIcons.trendingDown,
                      ),
                      const SizedBox(width: 8),
                      _SummaryStatPill(
                        label: isAr ? 'ثابت' : 'Unchanged',
                        value: '${preview.unchangedCount.toInt()}',
                        color: Colors.blueGrey,
                        icon: LucideIcons.minus,
                      ),
                      const SizedBox(width: 8),
                      _SummaryStatPill(
                        label: isAr ? 'غير نشط' : 'Inactive',
                        value: '${preview.inactiveCount.toInt()}',
                        color: AppColors.warning,
                        icon: LucideIcons.moon,
                      ),
                      const SizedBox(width: 8),
                      _SummaryStatPill(
                        label: isAr ? 'الحد الذهبي' : 'Gold Tier',
                        value: '≥ ${preview.goldThreshold.toInt()}%',
                        color: const Color(0xFFD4920E),
                        icon: LucideIcons.trophy,
                      ),
                      const SizedBox(width: 8),
                      _SummaryStatPill(
                        label: isAr ? 'الحد الفضي' : 'Silver Tier',
                        value: '≥ ${preview.silverThreshold.toInt()}%',
                        color: const Color(0xFF64748B),
                        icon: LucideIcons.award,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              DashboardSearchBar(
                controller: _previewSearchController,
                onChanged: _onPreviewSearchChanged,
                onClear: () {
                  _searchDebounce?.cancel();
                  _loadPreview(page: 1);
                },
                hintText: isAr
                    ? 'ابحث باسم السائق أو رقم الهاتف...'
                    : 'Search driver by name or phone...',
                height: 46,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tier in <DriverTier?>[
                      null,
                      DriverTier.GOLD,
                      DriverTier.SILVER,
                      DriverTier.BRONZE,
                    ])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(
                            tier == null
                                ? (isAr ? 'الكل' : 'All')
                                : AdminDriverTierVisuals.of(tier).label(isAr),
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _previewTierFilter == tier,
                          onSelected: (_) {
                            setState(() => _previewTierFilter = tier);
                            _loadPreview(page: 1);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        if (_previewLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_previewError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildErrorView(
              _previewError!,
              () => _loadPreview(page: _previewPage),
              isAr,
            ),
          )
        else if (preview == null || preview.drivers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isAr
                      ? 'لا يوجد سائقون مطابقون للبحث'
                      : 'No matching drivers found',
                ),
              ),
            ),
          )
        else ...[
          SliverList.separated(
            itemCount: preview.drivers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = preview.drivers[index];
              return _PreviewDriverCard(
                item: item,
                isAr: isAr,
                canOverride: _isAdminOrSuperAdmin && !_isDriverManager,
                onUpdated: () {
                  _loadPreview(page: _previewPage);
                  ref.read(driversProvider.notifier).refresh();
                },
              );
            },
          ),
          if (preview.meta.totalPages > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildPaginationBar(
                  page: _previewPage,
                  totalPages: preview.meta.totalPages.toInt(),
                  onPageChanged: (p) => _loadPreview(page: p),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRunsTab(BuildContext context, bool isAr) {
    final runs = _runs;

    if (_runsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_runsError != null) {
      return _buildErrorView(
        _runsError!,
        () => _loadRuns(page: _runsPage),
        isAr,
      );
    }
    if (runs == null || runs.data.isEmpty) {
      return Center(
        child: Text(
          isAr
              ? 'لم يتم تسجيل أي تشغيلات تقييم أسبوعية بعد'
              : 'No weekly evaluation runs recorded yet',
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: runs.data.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final run = runs.data[index];
              final statusCol = run.status == DriverRankingRunStatus.COMPLETED
                  ? AppColors.success
                  : (run.status == DriverRankingRunStatus.FAILED
                        ? AppColors.error
                        : AppColors.warning);
              final errMsg = run.errorMessage.asStringOrNull;
              final dateStr = DateFormat(
                'd MMM yyyy • h:mm a',
                isAr ? 'ar' : 'en',
              ).format((run.executedAt ?? run.scheduledFor).toLocal());

              return Container(
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
                        const Icon(
                          LucideIcons.calendarCheck,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                isAr
                                    ? 'تقييم الأسبوع ${run.periodKey}'
                                    : 'Week ${run.periodKey} Evaluation',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusCol.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  run.status.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusCol,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  run.triggerSource ==
                                          DriverRankingTriggerSource.MANUAL
                                      ? (isAr ? 'يدوي' : 'MANUAL')
                                      : (isAr ? 'تلقائي' : 'SCHEDULED'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniStatBadge(
                          label: isAr ? 'الإجمالي' : 'Total',
                          count: run.totalDrivers.toInt(),
                          color: AppColors.info,
                        ),
                        _MiniStatBadge(
                          label: isAr ? 'ترقية' : 'Promoted',
                          count: run.promotedCount.toInt(),
                          color: AppColors.success,
                        ),
                        _MiniStatBadge(
                          label: isAr ? 'تراجع' : 'Demoted',
                          count: run.demotedCount.toInt(),
                          color: AppColors.error,
                        ),
                        _MiniStatBadge(
                          label: isAr ? 'ثابت' : 'Unchanged',
                          count: run.unchangedCount.toInt(),
                          color: Colors.blueGrey,
                        ),
                        _MiniStatBadge(
                          label: isAr ? 'غير نشط' : 'Inactive',
                          count: run.inactiveCount.toInt(),
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    if (errMsg != null && errMsg.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $errMsg',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (run.status == DriverRankingRunStatus.FAILED &&
                              _isAdminOrSuperAdmin &&
                              !_isDriverManager)
                            FilledButton.icon(
                              onPressed: _retryingRunId == run.id
                                  ? null
                                  : () => _retryFailedRun(run.id),
                              icon: _retryingRunId == run.id
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(LucideIcons.rotateCcw, size: 14),
                              label: Text(
                                isAr ? 'إعادة المحاولة' : 'Retry Failed Run',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => _RunDetailsDialog(
                                  runId: run.id,
                                  periodKey: run.periodKey,
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.listOrdered, size: 14),
                            label: Text(
                              isAr
                                  ? 'عرض نتائج السائقين'
                                  : 'View Driver Entries',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (runs.meta.totalPages > 1)
          _buildPaginationBar(
            page: _runsPage,
            totalPages: runs.meta.totalPages.toInt(),
            onPageChanged: (p) => _loadRuns(page: p),
          ),
      ],
    );
  }

  Widget _buildIncidentsTab(BuildContext context, bool isAr) {
    final incidents = _incidents;
    final filters = <DeliveryIncidentResponsibility?>[
      null,
      DeliveryIncidentResponsibility.UNDER_REVIEW,
      DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
      DeliveryIncidentResponsibility.CUSTOMER,
      DeliveryIncidentResponsibility.VENDOR,
      DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final resp in filters)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      resp == null
                          ? (isAr ? 'الكل' : 'All')
                          : _responsibilityLabel(resp, isAr),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _incidentRespFilter == resp,
                    onSelected: (_) {
                      setState(() => _incidentRespFilter = resp);
                      _loadIncidents(page: 1);
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _incidentsLoading
              ? const Center(child: CircularProgressIndicator())
              : _incidentsError != null
              ? _buildErrorView(
                  _incidentsError!,
                  () => _loadIncidents(page: _incidentsPage),
                  isAr,
                )
              : (incidents == null || incidents.data.isEmpty)
              ? Center(
                  child: Text(
                    isAr
                        ? 'لا توجد حوادث إلغاء أو إعادة تعيين توصيل مسجلة'
                        : 'No delivery cancellation or reassignment incidents found',
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: incidents.data.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final inc = incidents.data[index];
                          final orderNum =
                              inc.orderNumber.asStringOrNull ??
                              inc.orderId.substring(
                                0,
                                inc.orderId.length > 8 ? 8 : inc.orderId.length,
                              );
                          final drvName =
                              inc.driverName.asStringOrNull ?? inc.driverId;
                          final reason = inc.reason.asStringOrNull;
                          final reviewNote = inc.reviewNote.asStringOrNull;
                          final respColor = _responsibilityColor(
                            inc.responsibility,
                          );
                          final dateStr = DateFormat(
                            'd MMM yyyy • h:mm a',
                            isAr ? 'ar' : 'en',
                          ).format(inc.occurredAt.toLocal());

                          return Container(
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
                                    const Icon(
                                      LucideIcons.shieldAlert,
                                      size: 17,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        alignment:
                                            WrapAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '#$orderNum • $drvName',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: respColor.withValues(
                                                alpha: 0.14,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _responsibilityLabel(
                                                inc.responsibility,
                                                isAr,
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: respColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        _incidentTypeLabel(
                                          inc.incidentType,
                                          isAr,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (reason != null && reason.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    isAr ? 'السبب: $reason' : 'Reason: $reason',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                                if (reviewNote != null &&
                                    reviewNote.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr
                                        ? 'ملاحظة المراجعة: $reviewNote'
                                        : 'Review note: $reviewNote',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                                if (_isAdminOrSuperAdmin &&
                                    !_isDriverManager) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final updated = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => _ReviewIncidentDialog(
                                            incident: inc,
                                          ),
                                        );
                                        if (updated == true && mounted) {
                                          _loadIncidents(page: _incidentsPage);
                                          _loadPreview(page: _previewPage);
                                        }
                                      },
                                      icon: const Icon(
                                        LucideIcons.checkCircle2,
                                        size: 14,
                                      ),
                                      label: Text(
                                        isAr
                                            ? 'تحديد المسؤولية'
                                            : 'Classify Responsibility',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (incidents.meta.totalPages > 1)
                      _buildPaginationBar(
                        page: _incidentsPage,
                        totalPages: incidents.meta.totalPages.toInt(),
                        onPageChanged: (p) => _loadIncidents(page: p),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry, bool isAr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.error, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 15),
            label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar({
    required int page,
    required int totalPages,
    required ValueChanged<int> onPageChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 18),
          ),
          Text(
            '$page / $totalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(LucideIcons.chevronRight, size: 18),
          ),
        ],
      ),
    );
  }

  static String _responsibilityLabel(
    DeliveryIncidentResponsibility resp,
    bool isAr,
  ) {
    if (resp == DeliveryIncidentResponsibility.DRIVER_AT_FAULT) {
      return isAr ? 'خطأ السائق' : 'Driver At Fault';
    }
    if (resp == DeliveryIncidentResponsibility.CUSTOMER) {
      return isAr ? 'بسبب العميل' : 'Customer';
    }
    if (resp == DeliveryIncidentResponsibility.VENDOR) {
      return isAr ? 'بسبب المتجر' : 'Vendor';
    }
    if (resp == DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM) {
      return isAr ? 'ظرف خارجي / نظام' : 'External / System';
    }
    return isAr ? 'قيد المراجعة' : 'Under Review';
  }

  static Color _responsibilityColor(DeliveryIncidentResponsibility resp) {
    if (resp == DeliveryIncidentResponsibility.DRIVER_AT_FAULT) {
      return AppColors.error;
    }
    if (resp == DeliveryIncidentResponsibility.UNDER_REVIEW) {
      return AppColors.warning;
    }
    return Colors.teal;
  }

  static String _incidentTypeLabel(DeliveryIncidentType type, bool isAr) {
    if (type == DeliveryIncidentType.ORDER_CANCELLED) {
      return isAr ? 'إلغاء طلب بعد التعيين' : 'Order Cancelled After Assignment';
    }
    if (type == DeliveryIncidentType.DRIVER_REASSIGNED) {
      return isAr ? 'إعادة تعيين سائق آخر' : 'Driver Reassigned';
    }
    if (type == DeliveryIncidentType.DRIVER_UNASSIGNED) {
      return isAr ? 'سحب التوصيل من السائق' : 'Driver Unassigned';
    }
    return isAr ? 'إخفاق توصيل' : 'Delivery Failure';
  }
}

class _SummaryStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryStatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MiniStatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _PreviewDriverCard extends StatelessWidget {
  final DriverRankingPreviewItemDto item;
  final bool isAr;
  final bool canOverride;
  final VoidCallback onUpdated;

  const _PreviewDriverCard({
    required this.item,
    required this.isAr,
    required this.canOverride,
    required this.onUpdated,
  });

  String _outcomeLabel(DriverRankingOutcome outcome) {
    if (outcome == DriverRankingOutcome.PROMOTED) {
      return isAr ? 'ترقية' : 'Promoted';
    }
    if (outcome == DriverRankingOutcome.DEMOTED) {
      return isAr ? 'تراجع' : 'Demoted';
    }
    if (outcome == DriverRankingOutcome.INACTIVE_SILVER) {
      return isAr ? 'غير نشط → فضية' : 'Inactive → Silver';
    }
    if (outcome == DriverRankingOutcome.CAPPED_SILVER) {
      return isAr ? 'سقف فضية (بدون طلبات)' : 'Capped Silver (No Orders)';
    }
    return isAr ? 'ثابت' : 'Unchanged';
  }

  Color _outcomeColor(DriverRankingOutcome outcome) {
    if (outcome == DriverRankingOutcome.PROMOTED) return AppColors.success;
    if (outcome == DriverRankingOutcome.DEMOTED) return AppColors.error;
    if (outcome == DriverRankingOutcome.INACTIVE_SILVER ||
        outcome == DriverRankingOutcome.CAPPED_SILVER) {
      return AppColors.warning;
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final snap = item.metricsSnapshot;
    final outcomeCol = _outcomeColor(item.outcome);
    final scoreStr = item.performancePercentage != null
        ? '${item.performancePercentage!.toStringAsFixed(1)}%'
        : (isAr ? 'بلا نشاط' : 'Inactive');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: outcomeCol.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _outcomeLabel(item.outcome),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: outcomeCol,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scoreStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DriverTierBadgePill(tier: item.previousTier, compact: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        isAr ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                        size: 14,
                      ),
                    ),
                    DriverTierBadgePill(tier: item.newTier, compact: true),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => DriverRankHistoryDialog(
                            driverId: item.driverId,
                            driverName: item.driverName,
                            initialTier: item.previousTier,
                            canOverride: canOverride,
                          ),
                        ).then((_) => onUpdated());
                      },
                      icon: const Icon(LucideIcons.history, size: 14),
                      label: Text(
                        isAr ? 'السجل' : 'History',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (canOverride)
                      FilledButton.icon(
                        onPressed: () async {
                          final newTier = await showDialog<DriverTier>(
                            context: context,
                            builder: (_) => OverrideDriverTierDialog(
                              driverId: item.driverId,
                              driverName: item.driverName,
                              currentTier: item.previousTier,
                            ),
                          );
                          if (newTier != null) onUpdated();
                        },
                        icon: const Icon(LucideIcons.award, size: 14),
                        label: Text(
                          isAr ? 'تعديل الشارة' : 'Override',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.16,
                          ),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _KpiSummaryChip(
                label: isAr ? 'القبول' : 'Acceptance',
                rate: item.acceptanceRate?.toDouble(),
                counts:
                    '${snap.acceptedDispatches.toInt()}/${snap.eligibleDispatches.toInt()}',
              ),
              _KpiSummaryChip(
                label: isAr ? 'الإتمام' : 'Completion',
                rate: item.completionRate?.toDouble(),
                counts:
                    '${snap.completedOrders.toInt()}/${snap.driverResponsibleOrders.toInt()}',
              ),
              _KpiSummaryChip(
                label: isAr ? 'الانضباط' : 'Punctuality',
                rate: item.shiftPunctualityRate?.toDouble(),
                counts:
                    '${snap.onTimeShifts.toInt()}/${snap.eligibleShifts.toInt()}',
              ),
              if (snap.excusedShifts > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAr
                        ? 'ورديات معذورة: ${snap.excusedShifts.toInt()}'
                        : 'Excused shifts: ${snap.excusedShifts.toInt()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
            ],
          ),
          if (item.explanations.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final exp in item.explanations)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $exp',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _KpiSummaryChip extends StatelessWidget {
  final String label;
  final double? rate;
  final String counts;

  const _KpiSummaryChip({
    required this.label,
    required this.rate,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final rateStr = rate != null ? '${rate!.toStringAsFixed(1)}%' : 'N/A';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $rateStr ($counts)',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ScheduleSettingsDialog extends ConsumerStatefulWidget {
  final bool initialEnabled;
  final String initialEvalTime;
  final int? initialGoldThreshold;
  final int? initialSilverThreshold;

  const _ScheduleSettingsDialog({
    required this.initialEnabled,
    required this.initialEvalTime,
    this.initialGoldThreshold,
    this.initialSilverThreshold,
  });

  @override
  ConsumerState<_ScheduleSettingsDialog> createState() =>
      _ScheduleSettingsDialogState();
}

class _ScheduleSettingsDialogState
    extends ConsumerState<_ScheduleSettingsDialog> {
  late bool _enabled;
  late TextEditingController _timeController;
  late TextEditingController _goldController;
  late TextEditingController _silverController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _timeController = TextEditingController(text: widget.initialEvalTime);
    _goldController = TextEditingController(
      text: '${widget.initialGoldThreshold ?? 95}',
    );
    _silverController = TextEditingController(
      text: '${widget.initialSilverThreshold ?? 85}',
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final timeStr = _timeController.text.trim();
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(timeStr)) {
      setState(() {
        _error = isAr
            ? 'يجب أن يكون وقت التقييم بصيغة 24 ساعة HH:mm (مثال: 00:05).'
            : 'Evaluation time must be in 24-hour HH:mm format (e.g. 00:05).';
      });
      return;
    }

    final gold = int.tryParse(_goldController.text.trim());
    final silver = int.tryParse(_silverController.text.trim());
    if (gold == null || gold < 1 || gold > 100) {
      setState(() {
        _error = isAr
            ? 'الحد الأدنى للشارة الذهبية يجب أن يكون بين 1 و 100.'
            : 'Gold tier threshold must be between 1 and 100.';
      });
      return;
    }
    if (silver == null || silver < 0 || silver > 99) {
      setState(() {
        _error = isAr
            ? 'الحد الأدنى للشارة الفضية يجب أن يكون بين 0 و 99.'
            : 'Silver tier threshold must be between 0 and 99.';
      });
      return;
    }
    if (gold <= silver) {
      setState(() {
        _error = isAr
            ? 'يجب أن يكون الحد الأدنى للشارة الذهبية أكبر من الحد الأدنى للشارة الفضية.'
            : 'Gold tier threshold must be greater than Silver tier threshold.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminPlatformSettingsRepositoryProvider)
          .platformSettingsUpdate(
            updatePlatformSettingsDto: UpdatePlatformSettingsDto(
              (b) => b
                ..driverRankingAutoEvalEnabled = _enabled
                ..driverRankingEvalTime = timeStr
                ..driverRankingGoldThreshold = gold
                ..driverRankingSilverThreshold = silver,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorUtils.translate(context, e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AppDialog(
      maxWidth: 440,
      canPop: !_saving,
      header: AppDialogHeader(
        icon: LucideIcons.clock,
        title: isAr
            ? 'إعدادات جدولة التقييم الأسبوعي'
            : 'Weekly Evaluation Schedule Settings',
        isCloseDisabled: _saving,
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AppDialogErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              isAr
                  ? 'التقييم التلقائي يوم الإثنين'
                  : 'Automatic Monday Evaluation',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              isAr
                  ? 'تحديث شارات السائقين تلقائياً كل يوم إثنين للأسبوع المنتهي'
                  : 'Automatically evaluate and update driver badges every Monday',
              style: const TextStyle(fontSize: 12),
            ),
            value: _enabled,
            onChanged: _saving ? null : (v) => setState(() => _enabled = v),
            activeThumbColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          AppFieldLabel(
            label: isAr
                ? 'وقت التنفيذ بتوقيت القاهرة (HH:mm)'
                : 'Execution Time in Cairo Timezone (HH:mm)',
            isRequired: true,
          ),
          TextField(
            controller: _timeController,
            enabled: !_saving,
            textDirection: TextDirection.ltr,
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: '00:05',
              icon: LucideIcons.clock,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppFieldLabel(
                      label: isAr ? 'الحد الذهبي (%)' : 'Gold Tier (%)',
                      isRequired: true,
                    ),
                    TextField(
                      controller: _goldController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: AppDialogStyles.inputDecoration(
                        context,
                        hintText: '95',
                        icon: LucideIcons.trophy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppFieldLabel(
                      label: isAr ? 'الحد الفضي (%)' : 'Silver Tier (%)',
                      isRequired: true,
                    ),
                    TextField(
                      controller: _silverController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: AppDialogStyles.inputDecoration(
                        context,
                        hintText: '85',
                        icon: LucideIcons.award,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إلغاء' : 'Cancel',
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: isAr ? 'حفظ' : 'Save',
        confirmIcon: LucideIcons.save,
        isLoading: _saving,
        onConfirm: _save,
      ),
    );
  }
}

class _RunDetailsDialog extends ConsumerStatefulWidget {
  final String runId;
  final String periodKey;

  const _RunDetailsDialog({required this.runId, required this.periodKey});

  @override
  ConsumerState<_RunDetailsDialog> createState() => _RunDetailsDialogState();
}

class _RunDetailsDialogState extends ConsumerState<_RunDetailsDialog> {
  DriverRankingRunDetailsResponseDto? _details;
  bool _loading = true;
  String? _error;
  int _page = 1;
  DriverTier? _tierFilter;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _load(page: 1);
    });
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(adminDriverRankingRepositoryProvider)
          .getRunDetails(
            widget.runId,
            page: page,
            limit: 25,
            search: _searchController.text,
            tier: _tierFilter,
          );
      if (mounted) {
        setState(() {
          _details = res;
          _page = page;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorUtils.translate(context, e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final details = _details;

    return AppDialog(
      maxWidth: 680,
      maxHeight: 740,
      scrollableBody: false,
      expandBody: true,
      bodyPadding: const EdgeInsets.all(16),
      header: AppDialogHeader(
        icon: LucideIcons.listOrdered,
        title: isAr
            ? 'نتائج تقييم الأسبوع ${widget.periodKey}'
            : 'Week ${widget.periodKey} Evaluation Entries',
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          DashboardSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchDebounce?.cancel();
              _load(page: 1);
            },
            hintText: isAr ? 'بحث باسم السائق...' : 'Search driver...',
            height: 44,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: DropdownButton<DriverTier?>(
              value: _tierFilter,
              hint: Text(isAr ? 'الكل' : 'All'),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(isAr ? 'الكل' : 'All'),
                ),
                for (final t in [
                  DriverTier.GOLD,
                  DriverTier.SILVER,
                  DriverTier.BRONZE,
                ])
                  DropdownMenuItem(
                    value: t,
                    child: Text(AdminDriverTierVisuals.of(t).label(isAr)),
                  ),
              ],
              onChanged: (val) {
                setState(() => _tierFilter = val);
                _load(page: 1);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : (details == null || details.entries.isEmpty)
                ? Center(
                    child: Text(
                      isAr ? 'لا توجد نتائج مطابقة' : 'No entries found',
                    ),
                  )
                : ListView.separated(
                    itemCount: details.entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = details.entries[index];
                      final drvName =
                          entry.driverName.asStringOrNull ?? entry.driverId;
                      final pct = entry.performancePercentage != null
                          ? '${entry.performancePercentage!.toStringAsFixed(1)}%'
                          : (isAr ? 'غير نشط' : 'Inactive');
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppDialogStyles.subtleSurfaceColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppDialogStyles.borderColor(context),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                drvName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DriverTierBadgePill(
                                    tier: entry.previousTier,
                                    compact: true,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      isAr
                                          ? LucideIcons.arrowLeft
                                          : LucideIcons.arrowRight,
                                      size: 13,
                                    ),
                                  ),
                                  DriverTierBadgePill(
                                    tier: entry.newTier,
                                    compact: true,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    pct,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (details != null && details.meta.totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                  icon: const Icon(LucideIcons.chevronLeft, size: 18),
                ),
                Text('$_page / ${details.meta.totalPages.toInt()}'),
                IconButton(
                  onPressed: _page < details.meta.totalPages
                      ? () => _load(page: _page + 1)
                      : null,
                  icon: const Icon(LucideIcons.chevronRight, size: 18),
                ),
              ],
            ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إغلاق' : 'Close',
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _ReviewIncidentDialog extends ConsumerStatefulWidget {
  final DriverDeliveryIncidentDto incident;

  const _ReviewIncidentDialog({required this.incident});

  @override
  ConsumerState<_ReviewIncidentDialog> createState() =>
      _ReviewIncidentDialogState();
}

class _ReviewIncidentDialogState extends ConsumerState<_ReviewIncidentDialog> {
  late DeliveryIncidentResponsibility _selected;
  late TextEditingController _noteController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.incident.responsibility;
    _noteController = TextEditingController(
      text: widget.incident.reviewNote.asStringOrNull ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(adminDriverRankingRepositoryProvider)
          .reviewIncident(
            widget.incident.id,
            responsibility: _selected,
            reviewNote: _noteController.text,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorUtils.translate(context, e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final options = [
      DeliveryIncidentResponsibility.DRIVER_AT_FAULT,
      DeliveryIncidentResponsibility.CUSTOMER,
      DeliveryIncidentResponsibility.VENDOR,
      DeliveryIncidentResponsibility.EXTERNAL_OR_SYSTEM,
      DeliveryIncidentResponsibility.UNDER_REVIEW,
    ];

    return AppDialog(
      maxWidth: 460,
      canPop: !_saving,
      header: AppDialogHeader(
        icon: LucideIcons.shieldCheck,
        title: isAr
            ? 'مراجعة وتصنيف مسؤولية الحادثة'
            : 'Classify Delivery Incident Responsibility',
        subtitle: widget.incident.driverName.asStringOrNull,
        isCloseDisabled: _saving,
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AppDialogErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          AppFieldLabel(
            label: isAr ? 'المسؤولية' : 'Responsibility Classification',
            isRequired: true,
          ),
          DropdownButtonFormField<DeliveryIncidentResponsibility>(
            initialValue: _selected,
            decoration: AppDialogStyles.inputDecoration(
              context,
              icon: LucideIcons.shieldAlert,
            ),
            items: options
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(
                      _DriverRankingAdminScreenState._responsibilityLabel(
                        r,
                        isAr,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (v) {
                    if (v != null) setState(() => _selected = v);
                  },
          ),
          const SizedBox(height: 14),
          AppFieldLabel(
            label: isAr ? 'ملاحظة المراجعة (اختياري)' : 'Review Note (Optional)',
          ),
          TextField(
            controller: _noteController,
            enabled: !_saving,
            maxLines: 3,
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: isAr
                  ? 'أضف ملاحظة توضيحية لقرار المراجعة...'
                  : 'Add an optional audit note...',
              icon: LucideIcons.fileText,
              isMultiline: true,
            ),
          ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إلغاء' : 'Cancel',
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: isAr ? 'حفظ' : 'Save',
        confirmIcon: LucideIcons.check,
        isLoading: _saving,
        onConfirm: _submit,
      ),
    );
  }
}
