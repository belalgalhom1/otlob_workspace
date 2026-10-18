import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/driver_shifts/data/models/driver_shifts_models.dart';
import 'package:vendor/features/driver_shifts/presentation/providers/driver_shifts_provider.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:vendor/features/driver_shifts/presentation/widgets/generate_shifts_dialog.dart';
import 'package:vendor/features/driver_shifts/presentation/widgets/shift_details_sheet.dart';
import 'package:vendor/core/utils/error_utils.dart';

enum _OccupancyFilter { all, hasSpots, full, empty }

enum _AssignmentFilter { all, assigned, unassigned }

enum _SortOption { soonest, latest, mostFull, leastFull }

class DriverShiftsScreen extends ConsumerStatefulWidget {
  const DriverShiftsScreen({super.key});

  @override
  ConsumerState<DriverShiftsScreen> createState() => _DriverShiftsScreenState();
}

class _DriverShiftsScreenState extends ConsumerState<DriverShiftsScreen> {
  DateRangePreset _datePreset = DateRangePreset.all;
  DateTimeRange? _customRange;
  String? _selectedZoneId;
  _OccupancyFilter _occupancy = _OccupancyFilter.all;
  _AssignmentFilter _assignment = _AssignmentFilter.all;
  _SortOption _sort = _SortOption.soonest;
  String _driverQuery = '';
  final TextEditingController _driverSearchController = TextEditingController();
  final Set<String> _expandedGroups = {};

  DateTimeRange? get _range =>
      resolveDateRangePreset(_datePreset, custom: _customRange);

  int get _activeFilterCount {
    var count = 0;
    if (_datePreset != DateRangePreset.all) count++;
    if (_selectedZoneId != null) count++;
    if (_occupancy != _OccupancyFilter.all) count++;
    if (_assignment != _AssignmentFilter.all) count++;
    if (_sort != _SortOption.soonest) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shiftPoolsProvider.notifier).filter();
      ref.read(zoneProvider.notifier).fetchZones();
    });
  }

  @override
  void dispose() {
    _driverSearchController.dispose();
    super.dispose();
  }

  static String? _fmtDay(DateTime? date) =>
      date == null ? null : DateFormat('yyyy-MM-dd').format(date);

  void _applyServerFilter() {
    final range = _range;
    ref.read(shiftPoolsProvider.notifier).filter(
          startDate: _fmtDay(range?.start),
          endDate: _fmtDay(range?.end),
          zoneId: _selectedZoneId,
        );
  }

  bool _matchesOccupancy(ShiftPool pool) {
    final assigned = pool.driverShifts.length;
    switch (_occupancy) {
      case _OccupancyFilter.all:
        return true;
      case _OccupancyFilter.hasSpots:
        return assigned < pool.maxDrivers;
      case _OccupancyFilter.full:
        return pool.maxDrivers > 0 && assigned >= pool.maxDrivers;
      case _OccupancyFilter.empty:
        return assigned == 0;
    }
  }

  bool _matchesAssignment(ShiftPool pool) {
    final hasDrivers = pool.driverShifts.isNotEmpty;
    switch (_assignment) {
      case _AssignmentFilter.all:
        return true;
      case _AssignmentFilter.assigned:
        return hasDrivers;
      case _AssignmentFilter.unassigned:
        return !hasDrivers;
    }
  }

  List<ShiftPool> _applyLocalShiftFilters(List<ShiftPool> pools) {
    final q = _driverQuery.trim().toLowerCase();
    return pools.where((pool) {
      if (!_matchesOccupancy(pool)) return false;
      if (!_matchesAssignment(pool)) return false;
      if (q.isEmpty) return true;
      final haystack = <String>[
        pool.title ?? '',
        pool.titleAr ?? '',
        pool.zoneName ?? '',
        DateFormat('EEE, MMM d').format(pool.shiftDate),
        DateFormat('yyyy-MM-dd').format(pool.shiftDate),
        '${DateFormat('hh:mm a').format(pool.startTime)} - ${DateFormat('hh:mm a').format(pool.endTime)}',
        ...pool.driverShifts.map((s) => s.driver?.user.name ?? ''),
        ...pool.driverShifts.map((s) => s.driver?.user.phone ?? ''),
        ...pool.driverShifts.map((s) => s.zoneName ?? ''),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final poolsAsync = ref.watch(shiftPoolsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFiltersBar(l10n),
        const SizedBox(height: 16),
        Expanded(
          child: poolsAsync.when(
            loading: () => _buildLoading(),
            error: (e, _) => _buildError(l10n, e),
            data: (pools) {
              final filtered = _applyLocalShiftFilters(pools);
              return filtered.isEmpty
                  ? _buildEmpty(l10n)
                  : _buildPoolGrid(l10n, filtered);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersBar(AppLocalizations l10n) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AppFilterBarButton(
                  label: l10n.filterAction,
                  activeCount: _activeFilterCount,
                  onTap: _openFilterSheet,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showGenerateDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: Text(l10n.generateShifts),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                          label: _chipLabelFor(l10n, preset, _datePreset, _customRange),
                          selected: _datePreset == preset,
                          onSelected: (_) => _selectPreset(preset),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _driverSearchController,
              decoration: InputDecoration(
                hintText: isArabic ? 'بحث بالاسم أو الوردية...' : 'Search name or shift title...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                suffixIcon: _driverQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _driverSearchController.clear();
                          setState(() => _driverQuery = '');
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _driverQuery = v),
            ),
          ],
        ),
      ),
    );
  }

  static const List<DateRangePreset> _datePresets = [
    DateRangePreset.all,
    DateRangePreset.today,
    DateRangePreset.tomorrow,
    DateRangePreset.thisWeek,
    DateRangePreset.nextWeek,
    DateRangePreset.thisMonth,
    DateRangePreset.custom,
  ];

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
      _applyServerFilter();
      return;
    }
    setState(() => _datePreset = preset);
    _applyServerFilter();
  }

  Future<void> _openFilterSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final zones = ref.read(zoneProvider).value?.zones ?? const [];

    var preset = _datePreset;
    DateTimeRange? custom = _customRange;
    String? zoneId = _selectedZoneId;
    var occupancy = _occupancy;
    var assignment = _assignment;
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
            zoneId = null;
            occupancy = _OccupancyFilter.all;
            assignment = _AssignmentFilter.all;
            sort = _SortOption.soonest;
          }),
          onApply: () {
            setState(() {
              _datePreset = preset;
              _customRange = custom;
              _selectedZoneId = zoneId;
              _occupancy = occupancy;
              _assignment = assignment;
              _sort = sort;
            });
            Navigator.pop(ctx);
            _applyServerFilter();
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
              title: l10n.zone,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppFilterChip(
                    label: l10n.allZones,
                    selected: zoneId == null,
                    onSelected: (_) => setSheet(() => zoneId = null),
                  ),
                  for (final z in zones)
                    AppFilterChip(
                      label: (z['name'] ?? '').toString(),
                      selected: zoneId == z['id'].toString(),
                      onSelected: (_) => setSheet(() => zoneId = z['id'].toString()),
                    ),
                ],
              ),
            ),
            AppFilterSection(
              title: l10n.occupancyLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppFilterChip(
                    label: l10n.filterAll,
                    selected: occupancy == _OccupancyFilter.all,
                    onSelected: (_) => setSheet(() => occupancy = _OccupancyFilter.all),
                  ),
                  AppFilterChip(
                    label: l10n.occupancyHasSpots,
                    selected: occupancy == _OccupancyFilter.hasSpots,
                    onSelected: (_) => setSheet(() => occupancy = _OccupancyFilter.hasSpots),
                  ),
                  AppFilterChip(
                    label: l10n.occupancyFull,
                    selected: occupancy == _OccupancyFilter.full,
                    onSelected: (_) => setSheet(() => occupancy = _OccupancyFilter.full),
                  ),
                  AppFilterChip(
                    label: l10n.occupancyEmpty,
                    selected: occupancy == _OccupancyFilter.empty,
                    onSelected: (_) => setSheet(() => occupancy = _OccupancyFilter.empty),
                  ),
                ],
              ),
            ),
            AppFilterSection(
              title: l10n.assignmentLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppFilterChip(
                    label: l10n.filterAll,
                    selected: assignment == _AssignmentFilter.all,
                    onSelected: (_) => setSheet(() => assignment = _AssignmentFilter.all),
                  ),
                  AppFilterChip(
                    label: l10n.assignmentAssigned,
                    selected: assignment == _AssignmentFilter.assigned,
                    onSelected: (_) => setSheet(() => assignment = _AssignmentFilter.assigned),
                  ),
                  AppFilterChip(
                    label: l10n.assignmentUnassigned,
                    selected: assignment == _AssignmentFilter.unassigned,
                    onSelected: (_) => setSheet(() => assignment = _AssignmentFilter.unassigned),
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
                    selected: sort == _SortOption.soonest,
                    onSelected: (_) => setSheet(() => sort = _SortOption.soonest),
                  ),
                  AppFilterChip(
                    label: l10n.sortLatest,
                    selected: sort == _SortOption.latest,
                    onSelected: (_) => setSheet(() => sort = _SortOption.latest),
                  ),
                  AppFilterChip(
                    label: l10n.sortMostFull,
                    selected: sort == _SortOption.mostFull,
                    onSelected: (_) => setSheet(() => sort = _SortOption.mostFull),
                  ),
                  AppFilterChip(
                    label: l10n.sortLeastFull,
                    selected: sort == _SortOption.leastFull,
                    onSelected: (_) => setSheet(() => sort = _SortOption.leastFull),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 20),
          Text(
            ErrorUtils.translate(context, error),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ref.read(shiftPoolsProvider.notifier).refresh(),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(l10n.retry),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.calendarX2, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noShiftsFound,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.generateShifts,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _showGenerateDialog(context),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(l10n.generateShifts),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Pools generated in a single action share a [ShiftPool.batchId]; legacy or
  /// manually-created pools fall back to being their own single-day group.
  List<List<ShiftPool>> _groupPools(List<ShiftPool> pools) {
    final map = <String, List<ShiftPool>>{};
    final order = <String>[];
    for (final pool in pools) {
      final key = _groupKey(pool);
      if (!map.containsKey(key)) {
        map[key] = <ShiftPool>[];
        order.add(key);
      }
      map[key]!.add(pool);
    }
    return order.map((key) => map[key]!).toList();
  }

  String _groupKey(ShiftPool pool) => (pool.batchId ?? '').isNotEmpty
      ? 'batch:${pool.batchId}'
      : 'single:${pool.id}';

  Widget _buildPoolGrid(AppLocalizations l10n, List<ShiftPool> pools) {
    final groups = _groupPools(pools)..sort(_compareGroups);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, index) => _buildGroupCard(l10n, groups[index]),
    );
  }

  int _compareGroups(List<ShiftPool> a, List<ShiftPool> b) {
    switch (_sort) {
      case _SortOption.soonest:
        return _earliestDate(a).compareTo(_earliestDate(b));
      case _SortOption.latest:
        return _earliestDate(b).compareTo(_earliestDate(a));
      case _SortOption.mostFull:
        return _groupOccupancy(b).compareTo(_groupOccupancy(a));
      case _SortOption.leastFull:
        return _groupOccupancy(a).compareTo(_groupOccupancy(b));
    }
  }

  int _earliestDate(List<ShiftPool> group) => group
      .map((p) => p.shiftDate)
      .reduce((a, b) => a.isBefore(b) ? a : b)
      .millisecondsSinceEpoch;

  double _groupOccupancy(List<ShiftPool> group) {
    final assigned = group.fold<int>(0, (sum, p) => sum + p.driverShifts.length);
    final capacity = group.fold<int>(0, (sum, p) => sum + p.maxDrivers);
    return capacity > 0 ? assigned / capacity : 0.0;
  }

  Widget _buildGroupCard(AppLocalizations l10n, List<ShiftPool> pools) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isArabic = langCode == 'ar';
    final first = pools.first;
    final sorted = [...pools]..sort((a, b) => a.shiftDate.compareTo(b.shiftDate));
    final key = _groupKey(first);
    final isExpanded = _expandedGroups.contains(key);
    final title = first.localizedTitle(langCode) ?? (isArabic ? 'وردية' : 'Shift');
    final zoneLabel = (first.zoneName ?? '').trim();
    final totalAssigned = sorted.fold<int>(0, (sum, p) => sum + p.driverShifts.length);
    final totalCapacity = sorted.fold<int>(0, (sum, p) => sum + p.maxDrivers);
    final occupancyRatio = totalCapacity > 0 ? totalAssigned / totalCapacity : 0.0;
    final occupancyColor = occupancyRatio >= 1.0
        ? AppColors.error
        : occupancyRatio >= 0.75
            ? AppColors.warning
            : AppColors.success;
    final timeLabel =
        '${DateFormat('hh:mm a').format(first.startTime)} – ${DateFormat('hh:mm a').format(first.endTime)}';
    final spanLabel = sorted.length == 1
        ? DateFormat('EEE, MMM d').format(sorted.first.shiftDate)
        : '${DateFormat('dd MMM').format(sorted.first.shiftDate)} – ${DateFormat('dd MMM').format(sorted.last.shiftDate)}';
    final daysLabel = isArabic ? '${sorted.length} يوم' : '${sorted.length} days';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedGroups.remove(key);
              } else {
                _expandedGroups.add(key);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.calendarDays, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$spanLabel · $daysLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildMetaChip(LucideIcons.timer, timeLabel, AppColors.info),
                      _buildMetaChip(
                        LucideIcons.mapPin,
                        zoneLabel.isNotEmpty ? zoneLabel : (isArabic ? 'كل المناطق' : 'All zones'),
                        AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$totalAssigned / $totalCapacity ${l10n.assignedDrivers}',
                    style: TextStyle(fontSize: 12, color: occupancyColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: occupancyRatio.clamp(0.0, 1.0),
                      backgroundColor: occupancyColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: Column(
                children: sorted.map((pool) => _buildPoolDayRow(l10n, pool)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPoolDayRow(AppLocalizations l10n, ShiftPool pool) {
    final assignedCount = pool.driverShifts.length;
    final occupancyRatio = pool.maxDrivers > 0 ? assignedCount / pool.maxDrivers : 0.0;
    final occupancyColor = occupancyRatio >= 1.0
        ? AppColors.error
        : occupancyRatio >= 0.75
            ? AppColors.warning
            : AppColors.success;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showShiftDetails(pool),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('EEE, d MMM').format(pool.shiftDate),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: occupancyRatio.clamp(0.0, 1.0),
                  backgroundColor: occupancyColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(occupancyColor),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$assignedCount/${pool.maxDrivers}',
              style: TextStyle(fontSize: 12, color: occupancyColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _confirmDelete(pool),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(LucideIcons.trash2, size: 13, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => GenerateShiftsDialog(
        onSuccess: () => ref.read(shiftPoolsProvider.notifier).refresh(),
      ),
    );
  }

  void _showShiftDetails(ShiftPool pool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShiftDetailsSheet(
        pool: pool,
        onAssigned: () => ref.read(shiftPoolsProvider.notifier).refresh(),
      ),
    );
  }

  void _confirmDelete(ShiftPool pool) {
    final l10n = AppLocalizations.of(context)!;
    final hasAssignedDrivers = pool.driverShifts.any(
      (s) => s.status == 'SCHEDULED' || s.status == 'ACTIVE',
    );
    if (hasAssignedDrivers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteShiftPoolHasDrivers),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteShiftPool),
        content: Text(l10n.deleteShiftPoolConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final deleted = await ref
                    .read(shiftPoolsProvider.notifier)
                    .deleteShiftPool(pool.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        deleted
                            ? l10n.shiftDeletedSuccessfully
                            : l10n.shiftPoolDisabledDueToHistory,
                      ),
                      backgroundColor:
                          deleted ? AppColors.success : AppColors.error,
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
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
