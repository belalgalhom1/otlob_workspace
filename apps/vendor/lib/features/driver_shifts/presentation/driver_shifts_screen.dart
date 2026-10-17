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

class DriverShiftsScreen extends ConsumerStatefulWidget {
  const DriverShiftsScreen({super.key});

  @override
  ConsumerState<DriverShiftsScreen> createState() => _DriverShiftsScreenState();
}

class _DriverShiftsScreenState extends ConsumerState<DriverShiftsScreen> {
  DateTime? _selectedDate;
  String? _selectedZoneId;
  String _driverQuery = '';
  final TextEditingController _driverSearchController = TextEditingController();

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

  void _applyServerFilter() {
    ref.read(shiftPoolsProvider.notifier).filter(
          date: _selectedDate == null
              ? null
              : DateFormat('yyyy-MM-dd').format(_selectedDate!),
          zoneId: _selectedZoneId,
        );
  }

  List<ShiftPool> _applyLocalShiftFilters(List<ShiftPool> pools) {
    final q = _driverQuery.trim().toLowerCase();
    if (q.isEmpty) return pools;
    return pools.where((pool) {
      final haystack = <String>[
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
    final zones = ref.watch(zoneProvider);
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                          _applyServerFilter();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedDate != null
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedDate != null
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 15,
                              color: _selectedDate != null
                                  ? AppColors.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                  : l10n.shiftDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedDate != null
                                    ? AppColors.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() => _selectedDate = null);
                          _applyServerFilter();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.x, size: 14, color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: FilledButton.icon(
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _selectedZoneId,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'المنطقة' : 'Zone',
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 16),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(isArabic ? 'كل المناطق' : 'All Zones',
                            overflow: TextOverflow.ellipsis),
                      ),
                      ...?zones.value?.zones.map(
                        (z) => DropdownMenuItem<String?>(
                          value: z['id'].toString(),
                          child: Text(
                            (z['name'] ?? '').toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedZoneId = v);
                      _applyServerFilter();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _driverSearchController,
                    decoration: InputDecoration(
                      hintText: isArabic ? 'بحث باسم السائق...' : 'Search driver...',
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
                ),
              ],
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

  Widget _buildPoolGrid(AppLocalizations l10n, List<ShiftPool> pools) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.65,
          ),
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: pools.length,
          itemBuilder: (context, index) => _buildPoolCard(l10n, pools[index]),
        );
      },
    );
  }

  Widget _buildPoolCard(AppLocalizations l10n, ShiftPool pool) {
    final assignedCount = pool.driverShifts.length;
    final occupancyRatio = pool.maxDrivers > 0 ? assignedCount / pool.maxDrivers : 0.0;
    final occupancyColor = occupancyRatio >= 1.0
        ? AppColors.error
        : occupancyRatio >= 0.75
            ? AppColors.warning
            : AppColors.success;

    return GestureDetector(
      onTap: () => _showShiftDetails(pool),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
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
                  child: const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEE, MMM d').format(pool.shiftDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(LucideIcons.timer, size: 13, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('hh:mm a').format(pool.startTime)} – ${DateFormat('hh:mm a').format(pool.endTime)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$assignedCount / ${pool.maxDrivers} ${l10n.assignedDrivers}',
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
