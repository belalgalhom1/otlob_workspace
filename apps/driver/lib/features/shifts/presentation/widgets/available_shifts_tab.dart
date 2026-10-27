import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/shifts/presentation/shifts_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:intl/intl.dart';

class AvailableShiftsTab extends ConsumerStatefulWidget {
  const AvailableShiftsTab({super.key});

  @override
  ConsumerState<AvailableShiftsTab> createState() => _AvailableShiftsTabState();
}

enum _AvailableSort { soonest, latest }

class _AvailableShiftsTabState extends ConsumerState<AvailableShiftsTab> {
  DateRangePreset _datePreset = DateRangePreset.all;
  DateTimeRange? _customRange;
  _AvailableSort _sort = _AvailableSort.soonest;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<DateRangePreset> _datePresets = [
    DateRangePreset.all,
    DateRangePreset.today,
    DateRangePreset.tomorrow,
    DateRangePreset.thisWeek,
    DateRangePreset.nextWeek,
    DateRangePreset.thisMonth,
    DateRangePreset.custom,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    var count = 0;
    if (_datePreset != DateRangePreset.all) count++;
    if (_sort != _AvailableSort.soonest) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(driverProfileProvider);
    String zoneId = '';

    if (profileState.hasValue && profileState.value != null) {
      final profileData = profileState.value;
      final data =
          profileData is Map &&
              profileData.containsKey('data') &&
              profileData['data'] is Map
          ? profileData['data']
          : (profileData ?? {});
      zoneId =
          data['zoneId']?.toString() ?? data['zone']?['id']?.toString() ?? '';
    }

    final availableState = ref.watch(availablePoolsProvider(zoneId));
    final l10n = AppLocalizations.of(context)!;

    if (profileState.isLoading && zoneId.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Column(
      children: [
        _buildFilterBar(l10n),
        Expanded(
          child: availableState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, _) {
              if (error.toString().toLowerCase().contains('shifts_disabled')) {
                return EmptyStateWidget(
                  icon: LucideIcons.calendarOff,
                  title: l10n.shiftsDisabledTitle,
                  subtitle: l10n.shiftsDisabledAvailableSubtitle,
                );
              }
              return Center(child: Text(ErrorUtils.translate(context, error)));
            },
            data: (pools) {
              if (pools.isEmpty) {
                return EmptyStateWidget(
                  icon: LucideIcons.calendarX,
                  title: l10n.noAvailableShifts,
                  subtitle: l10n.noAvailableShiftsSubtitle,
                );
              }

              final filtered = _applyFilters(pools);
              if (filtered.isEmpty) {
                return EmptyStateWidget(
                  icon: LucideIcons.search,
                  title: l10n.noAvailableShifts,
                  subtitle: l10n.noAvailableShiftsSubtitle,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(availablePoolsProvider(zoneId));
                },
                child: Builder(
                  builder: (context) {
                    final groups = _groupPools(filtered)..sort(_compareGroups);
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: groups.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildPoolGroup(
                        context,
                        ref,
                        groups[index],
                        l10n,
                        zoneId,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _presetLabel(AppLocalizations l10n, DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.all:
        return l10n.presetAllDates;
      case DateRangePreset.today:
        return l10n.presetToday;
      case DateRangePreset.tomorrow:
        return l10n.presetTomorrow;
      case DateRangePreset.thisWeek:
        return l10n.presetThisWeek;
      case DateRangePreset.nextWeek:
        return l10n.presetNextWeek;
      case DateRangePreset.thisMonth:
        return l10n.presetThisMonth;
      case DateRangePreset.custom:
        return l10n.presetCustom;
    }
  }

  String _customRangeLabel(DateTimeRange range) =>
      '${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM').format(range.end)}';

  String _chipLabelFor(
    AppLocalizations l10n,
    DateRangePreset preset,
    DateRangePreset current,
    DateTimeRange? custom,
  ) {
    if (preset == DateRangePreset.custom &&
        current == DateRangePreset.custom &&
        custom != null) {
      return _customRangeLabel(custom);
    }
    return _presetLabel(l10n, preset);
  }

  Future<void> _selectPreset(DateRangePreset preset) async {
    if (preset == DateRangePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime(2030),
        initialDateRange: _customRange,
      );
      if (picked == null) return;
      setState(() {
        _customRange = picked;
        _datePreset = DateRangePreset.custom;
      });
      return;
    }
    setState(() => _datePreset = preset);
  }

  Future<void> _openFilterSheet(AppLocalizations l10n) async {
    var preset = _datePreset;
    DateTimeRange? custom = _customRange;
    var sort = _sort;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AppFilterSheet(
          title: l10n.filtersTitle,
          resetLabel: l10n.resetFilters,
          applyLabel: l10n.applyFilters,
          onReset: () => setSheet(() {
            preset = DateRangePreset.all;
            custom = null;
            sort = _AvailableSort.soonest;
          }),
          onApply: () {
            setState(() {
              _datePreset = preset;
              _customRange = custom;
              _sort = sort;
            });
            Navigator.pop(ctx);
          },
          children: [
            AppFilterSection(
              title: l10n.dateRange,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _datePresets)
                    AppFilterChip(
                      label: _chipLabelFor(l10n, p, preset, custom),
                      selected: preset == p,
                      onSelected: (_) async {
                        if (p == DateRangePreset.custom) {
                          final picked = await showDateRangePicker(
                            context: ctx,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                            initialDateRange: custom,
                          );
                          if (picked == null) return;
                          setSheet(() {
                            custom = picked;
                            preset = DateRangePreset.custom;
                          });
                        } else {
                          setSheet(() => preset = p);
                        }
                      },
                    ),
                ],
              ),
            ),
            AppFilterSection(
              title: l10n.sortBy,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppFilterChip(
                    label: l10n.sortSoonest,
                    selected: sort == _AvailableSort.soonest,
                    onSelected: (_) =>
                        setSheet(() => sort = _AvailableSort.soonest),
                  ),
                  AppFilterChip(
                    label: l10n.sortLatest,
                    selected: sort == _AvailableSort.latest,
                    onSelected: (_) =>
                        setSheet(() => sort = _AvailableSort.latest),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              AppFilterBarButton(
                label: l10n.filterAction,
                activeCount: _activeFilterCount,
                onTap: () => _openFilterSheet(l10n),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchShiftsHint,
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final preset in _datePresets)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Center(
                      child: AppFilterChip(
                        label: _chipLabelFor(
                          l10n,
                          preset,
                          _datePreset,
                          _customRange,
                        ),
                        selected: _datePreset == preset,
                        onSelected: (_) => _selectPreset(preset),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<dynamic> pools) {
    final range = resolveDateRangePreset(_datePreset, custom: _customRange);
    final q = _query.trim().toLowerCase();
    return pools.map((e) => e as Map<String, dynamic>).where((pool) {
      if (range != null) {
        final raw = pool['shiftDate'] ?? pool['startTime'];
        final date = raw == null
            ? null
            : DateTime.tryParse(raw.toString())?.toLocal();
        if (date == null) return false;
        final day = DateTime(date.year, date.month, date.day);
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }
      if (q.isNotEmpty) {
        final haystack = [
          pool['title'],
          pool['titleAr'],
          pool['zone']?['name'],
        ].map((x) => (x ?? '').toString().toLowerCase()).join(' ');
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  int _compareGroups(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    final aStart = _earliestStart(a);
    final bStart = _earliestStart(b);
    return _sort == _AvailableSort.soonest
        ? aStart.compareTo(bStart)
        : bStart.compareTo(aStart);
  }

  String _earliestStart(List<Map<String, dynamic>> group) {
    var earliest = '${group.first['startTime']}';
    for (final pool in group) {
      final value = '${pool['startTime']}';
      if (value.compareTo(earliest) < 0) earliest = value;
    }
    return earliest;
  }

  /// Pools generated in one action share a [batchId]; legacy pools each stand
  /// alone. Order is preserved from the server (soonest first).
  List<List<Map<String, dynamic>>> _groupPools(List<dynamic> pools) {
    final map = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    for (final raw in pools) {
      final pool = raw as Map<String, dynamic>;
      final batchId = (pool['batchId'] ?? '').toString();
      final key = batchId.isNotEmpty
          ? 'batch:$batchId'
          : 'single:${pool['id']}';
      if (!map.containsKey(key)) {
        map[key] = <Map<String, dynamic>>[];
        order.add(key);
      }
      map[key]!.add(pool);
    }
    return order.map((key) => map[key]!).toList();
  }

  String _format(DateTime date, String pattern) {
    try {
      return DateFormat(pattern).format(date);
    } catch (_) {
      return '';
    }
  }

  String _spanLabel(List<Map<String, dynamic>> pools) {
    DateTime? firstDt;
    DateTime? lastDt;
    for (final pool in pools) {
      final raw = pool['shiftDate'] ?? pool['startTime'];
      if (raw == null) continue;
      final date = DateTime.tryParse(raw.toString())?.toLocal();
      if (date == null) continue;
      if (firstDt == null || date.isBefore(firstDt)) firstDt = date;
      if (lastDt == null || date.isAfter(lastDt)) lastDt = date;
    }
    if (firstDt == null) return '';
    if (lastDt == null || firstDt.isAtSameMomentAs(lastDt)) {
      return _format(firstDt, 'EEEE, MMM d');
    }
    return '${_format(firstDt, 'dd MMM')} – ${_format(lastDt, 'dd MMM')}';
  }

  Widget _buildPoolGroup(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> pools,
    AppLocalizations l10n,
    String currentZoneId,
  ) {
    final isAr = l10n.localeName == 'ar';
    final sorted = [...pools]
      ..sort((a, b) => '${a['startTime']}'.compareTo('${b['startTime']}'));
    final first = sorted.first;
    final zoneName = first['zone']?['name'] ?? l10n.assignedZone;
    final title =
        ((isAr ? first['titleAr'] : first['title']) ??
                (isAr ? first['title'] : first['titleAr']) ??
                '')
            .toString()
            .trim();
    final heading = title.isNotEmpty ? title : zoneName;
    final isWeekly = first['type'] == 'WEEKLY';
    final spanLabel = _spanLabel(sorted);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isWeekly ? l10n.weeklyShift : l10n.overtimeShift,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zoneName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (spanLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.calendarDays,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    spanLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (isWeekly)
            _buildWeeklyBookButton(context, ref, sorted, l10n, currentZoneId)
          else
            ...sorted.map(
              (pool) =>
                  _buildPoolDayRow(context, ref, pool, l10n, currentZoneId),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBookButton(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> pools,
    AppLocalizations l10n,
    String currentZoneId,
  ) {
    final poolIds = pools
        .map((p) => p['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: poolIds.length == 6
              ? () {
                  ref
                      .read(availablePoolsProvider(currentZoneId).notifier)
                      .bookWeeklyShifts(poolIds);
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(LucideIcons.calendarCheck, size: 18),
          label: Text(
            l10n.bookShift,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPoolDayRow(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> pool,
    AppLocalizations l10n,
    String currentZoneId,
  ) {
    final rawStart = pool['startTime'] ?? '';
    final startDate = DateTime.tryParse(rawStart.toString())?.toLocal();
    final dayLabel = startDate == null ? '' : _format(startDate, 'EEEE, MMM d');
    final startTime = startDate == null
        ? ''
        : DateFormat.jm().format(startDate);
    final rawEnd = pool['endTime'];
    final endDate = rawEnd == null
        ? null
        : DateTime.tryParse(rawEnd.toString())?.toLocal();
    final endTime = endDate == null ? '' : DateFormat.jm().format(endDate);
    final isWeekly = pool['type'] == 'WEEKLY';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dayLabel.isNotEmpty)
                  Text(
                    dayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              if (isWeekly) {
                ref
                    .read(availablePoolsProvider(currentZoneId).notifier)
                    .bookWeeklyShifts([pool['id']]);
              } else {
                ref
                    .read(availablePoolsProvider(currentZoneId).notifier)
                    .bookOvertimeShift(pool['id']);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.bookShift,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
