import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/driver_shifts/data/models/driver_shifts_models.dart';
import 'package:vendor/features/driver_shifts/presentation/providers/driver_shifts_provider.dart';
import 'package:vendor/features/drivers/data/driver_providers.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';
import 'package:vendor/core/utils/error_utils.dart';

class ShiftDetailsSheet extends ConsumerStatefulWidget {
  final ShiftPool pool;
  final VoidCallback onAssigned;

  const ShiftDetailsSheet({
    super.key,
    required this.pool,
    required this.onAssigned,
  });

  @override
  ConsumerState<ShiftDetailsSheet> createState() => _ShiftDetailsSheetState();
}

class _ShiftDetailsSheetState extends ConsumerState<ShiftDetailsSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driversProvider.notifier).filter();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final poolsAsync = ref.watch(shiftPoolsProvider);
    final pool = poolsAsync.maybeWhen(
      data: (pools) => pools.firstWhere(
        (p) => p.id == widget.pool.id,
        orElse: () => widget.pool,
      ),
      orElse: () => widget.pool,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(l10n, pool)),
            SliverToBoxAdapter(child: _buildInfoRow(l10n, pool)),
            SliverToBoxAdapter(child: _buildAssignSection(l10n, pool)),
            SliverToBoxAdapter(child: _buildAssignedDriversList(l10n, pool)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, ShiftPool pool) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.calendarDays,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shiftManagement,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(pool.shiftDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(AppLocalizations l10n, ShiftPool pool) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _buildInfoChip(
            LucideIcons.timer,
            '${DateFormat('hh:mm a').format(pool.startTime)} – ${DateFormat('hh:mm a').format(pool.endTime)}',
            AppColors.info,
          ),
          _buildInfoChip(
            LucideIcons.users,
            '${pool.driverShifts.length} / ${pool.maxDrivers} ${l10n.capacity}',
            pool.driverShifts.length >= pool.maxDrivers
                ? AppColors.error
                : AppColors.success,
          ),
          if (pool.zoneId != null)
            _buildInfoChip(LucideIcons.mapPin, l10n.zone, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignSection(AppLocalizations l10n, ShiftPool pool) {
    final driversAsync = ref.watch(driversProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.assignDriver,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (q) {
              ref
                  .read(driversProvider.notifier)
                  .filter(search: q.trim().isEmpty ? null : q.trim());
            },
            decoration: InputDecoration(
              hintText: l10n.searchDriver,
              prefixIcon: Icon(
                LucideIcons.search,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: driversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  ErrorUtils.translate(context, e),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (state) => state.drivers.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noDriversFound,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.drivers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) =>
                          _buildDriverAssignTile(l10n, state.drivers[i], pool),
                    ),
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildDriverAssignTile(
    AppLocalizations l10n,
    DriverProfile driver,
    ShiftPool pool,
  ) {
    final isAlreadyAssigned = pool.driverShifts.any(
      (s) => s.driverId == driver.id,
    );
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        driver.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        driver.status,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isAlreadyAssigned
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                LucideIcons.check,
                size: 14,
                color: AppColors.success,
              ),
            )
          : TextButton(
              onPressed: () => _assignDriver(l10n, driver, pool),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
              ),
              child: Text(
                l10n.assignDriver,
                style: const TextStyle(fontSize: 12),
              ),
            ),
    );
  }

  Widget _buildAssignedDriversList(AppLocalizations l10n, ShiftPool pool) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.assignedDrivers,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pool.driverShifts.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (pool.driverShifts.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _removeAllDrivers(l10n, pool),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Tooltip(
                      message: l10n.removeAllDrivers,
                      child: const Icon(
                        LucideIcons.userX,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (pool.driverShifts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    LucideIcons.userX,
                    size: 32,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.assignedDrivers,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...pool.driverShifts.map(
              (shift) => _buildAssignedDriverTile(shift),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignedDriverTile(DriverShift shift) {
    final driverName =
        shift.driver?.user.name ?? shift.driverId.substring(0, 8);
    final statusColor = shift.status == 'ACTIVE'
        ? AppColors.success
        : shift.status == 'SCHEDULED'
        ? AppColors.info
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${DateFormat('hh:mm a').format(shift.startTime)} – ${DateFormat('hh:mm a').format(shift.endTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              shift.status,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _removeDriver(shift),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(LucideIcons.userX, size: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeDriver(DriverShift shift) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.removeDriver),
        content: Text(l10n.removeDriverConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(shiftPoolsProvider.notifier).removeDriverFromShift(shift.id);
      widget.onAssigned();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.removeDriverSuccess),
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
    }
  }

  Future<void> _removeAllDrivers(AppLocalizations l10n, ShiftPool pool) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.removeAllDrivers),
        content: Text(l10n.removeAllDriversConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(shiftPoolsProvider.notifier).removeAllDriversFromPool(pool.id);
      widget.onAssigned();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.removeAllDriversSuccess),
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
    }
  }

  Future<void> _assignDriver(
    AppLocalizations l10n,
    DriverProfile driver,
    ShiftPool pool,
  ) async {
    try {
      await ref
          .read(shiftPoolsProvider.notifier)
          .assignDriver(
            AdminAssignShiftRequest(shiftPoolId: pool.id, driverId: driver.id),
          );
      widget.onAssigned();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.driverAssignedSuccessfully),
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
    }
  }
}
