import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/features/driver_shifts/data/models/driver_shifts_models.dart';
import 'package:vendor/features/driver_shifts/presentation/providers/driver_shifts_provider.dart';
import 'package:vendor/features/drivers/data/driver_providers.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';
import 'package:vendor/core/utils/error_utils.dart';

class ShiftDetailsSheet extends ConsumerStatefulWidget {
  final ShiftPool pool;
  final VoidCallback onAssigned;

  /// Every pool in the same generated batch. When there is more than one the
  /// UI offers to assign or remove the driver for the whole group in a single action.
  final List<String> allPoolIds;

  const ShiftDetailsSheet({
    super.key,
    required this.pool,
    required this.onAssigned,
    this.allPoolIds = const [],
  });

  @override
  ConsumerState<ShiftDetailsSheet> createState() => _ShiftDetailsSheetState();
}

class _ShiftDetailsSheetState extends ConsumerState<ShiftDetailsSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _assignToAll = false;
  bool _removeFromAll = false;
  bool _isRemoving = false;

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
        initialChildSize: 0.80,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SafeArea(
          top: false,
          child: CustomScrollView(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shiftManagement,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(pool.shiftDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    if ((pool.localizedTitle(
                                  Localizations.localeOf(context).languageCode,
                                ) ??
                                '')
                            .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          pool.localizedTitle(
                            Localizations.localeOf(context).languageCode,
                          )!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.fileSpreadsheet, size: 20, color: AppColors.primary),
                tooltip: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'تصدير تقرير ورديات السائقين (PDF)'
                    : 'Export Shifts Report (PDF)',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
                onPressed: () => _exportPoolPdf(pool),
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
          if ((pool.zoneName ?? '').trim().isNotEmpty || pool.zoneId != null)
            _buildInfoChip(
              LucideIcons.mapPin,
              (pool.zoneName ?? '').trim().isNotEmpty
                  ? pool.zoneName!.trim()
                  : l10n.zone,
              AppColors.warning,
            ),
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
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
          if (widget.allPoolIds.length > 1) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _assignToAll = !_assignToAll),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: _assignToAll ? 0.12 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: _assignToAll ? 0.45 : 0.22,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _assignToAll
                            ? LucideIcons.checkSquare
                            : LucideIcons.square,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.localeName == 'ar'
                              ? 'تعيين لكل الورديات (${widget.allPoolIds.length})'
                              : 'Assign to all shifts (${widget.allPoolIds.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            height: 140,
            child: driversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  ErrorUtils.translate(context, e),
                  textAlign: TextAlign.center,
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
    DriverShift? assignedShift;
    for (final s in pool.driverShifts) {
      if (s.driverId == driver.id) {
        assignedShift = s;
        break;
      }
    }
    final hasGroup = widget.allPoolIds.length > 1;
    final defaultBulkRemove = hasGroup && (_removeFromAll || _assignToAll);
    final matchedShift = assignedShift;

    return ListTile(
      dense: true,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: AppNetworkAvatar(
        imageUrl: ImageUtils.formatImageUrl(driver.avatar),
        size: 36,
        fallbackIcon: LucideIcons.user,
        fallbackText: driver.name,
        preferInitialFallback: true,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        foregroundColor: AppColors.primary,
      ),
      title: Text(
        driver.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        driver.status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
      trailing: matchedShift != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 13,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: defaultBulkRemove
                      ? l10n.removeFromAllShifts(widget.allPoolIds.length)
                      : l10n.removeDriver,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _isRemoving
                          ? null
                          : () => _removeDriver(
                              matchedShift,
                              defaultRemoveFromAll: defaultBulkRemove,
                            ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(
                            alpha: _isRemoving ? 0.04 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.error.withValues(
                              alpha: _isRemoving ? 0.15 : 0.28,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.userX,
                              size: 13,
                              color: _isRemoving
                                  ? AppColors.error.withValues(alpha: 0.4)
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.remove,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isRemoving
                                    ? AppColors.error.withValues(alpha: 0.4)
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
    final hasGroup = widget.allPoolIds.length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.assignedDrivers,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                  ],
                ),
              ),
              if (pool.driverShifts.isNotEmpty) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: l10n.removeAllDrivers,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _isRemoving
                          ? null
                          : () => _removeAllDrivers(l10n, pool),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(
                            alpha: _isRemoving ? 0.04 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.userX,
                          size: 15,
                          color: _isRemoving
                              ? AppColors.error.withValues(alpha: 0.4)
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasGroup && pool.driverShifts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _isRemoving
                    ? null
                    : () => setState(() => _removeFromAll = !_removeFromAll),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(
                      alpha: _removeFromAll ? 0.10 : 0.04,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(
                        alpha: _removeFromAll ? 0.45 : 0.22,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _removeFromAll
                            ? LucideIcons.checkSquare
                            : LucideIcons.square,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.removeFromAllShifts(widget.allPoolIds.length),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
              (shift) => _buildAssignedDriverTile(l10n, shift),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignedDriverTile(AppLocalizations l10n, DriverShift shift) {
    final driverName =
        shift.driver?.user.name ??
        (shift.driverId.length >= 8
            ? shift.driverId.substring(0, 8)
            : shift.driverId);
    final statusColor = shift.status == 'ACTIVE'
        ? AppColors.success
        : shift.status == 'SCHEDULED'
        ? AppColors.info
        : Theme.of(context).colorScheme.onSurface;
    final hasGroup = widget.allPoolIds.length > 1;

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
          AppNetworkAvatar(
            imageUrl: ImageUtils.formatImageUrl(shift.driver?.user.avatar),
            size: 32,
            fallbackIcon: LucideIcons.user,
            fallbackIconSize: 15,
            fallbackText: driverName,
            preferInitialFallback: true,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${DateFormat('hh:mm a').format(shift.startTime)} – ${DateFormat('hh:mm a').format(shift.endTime)}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              shift.status,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: Localizations.localeOf(context).languageCode == 'ar'
                ? 'تصدير تقرير الوردية (PDF)'
                : 'Export Shift Report (PDF)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _exportShiftPdf(shift),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.fileSpreadsheet,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: _removeFromAll && hasGroup
                ? l10n.removeFromAllShifts(widget.allPoolIds.length)
                : l10n.removeDriver,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _isRemoving ? null : () => _removeDriver(shift),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(
                      alpha: _isRemoving ? 0.04 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.userX,
                    size: 14,
                    color: _isRemoving
                        ? AppColors.error.withValues(alpha: 0.4)
                        : AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeDriver(
    DriverShift shift, {
    bool? defaultRemoveFromAll,
  }) async {
    if (_isRemoving) return;
    final l10n = AppLocalizations.of(context)!;
    final hasGroup = widget.allPoolIds.length > 1;
    final driverName =
        shift.driver?.user.name ??
        (shift.driverId.length >= 8
            ? shift.driverId.substring(0, 8)
            : shift.driverId);

    final removeFromAllChoice = await showDialog<bool?>(
      context: context,
      builder: (ctx) {
        var removeFromAll =
            (defaultRemoveFromAll ?? _removeFromAll) && hasGroup;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final theme = Theme.of(ctx);
            return AppDialog(
              maxWidth: 460,
              header: AppDialogHeader(
                icon: LucideIcons.userMinus,
                accentColor: AppColors.error,
                titleColor: AppColors.error,
                title: removeFromAll && hasGroup
                    ? l10n.removeDriverFromGroupTitle
                    : l10n.removeDriver,
                onClose: () => Navigator.pop(ctx, null),
              ),
              body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (driverName.isNotEmpty) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppBadgePill(
                        text: driverName,
                        icon: LucideIcons.user,
                        accentColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    removeFromAll && hasGroup
                        ? l10n.removeDriverGroupConfirm(widget.allPoolIds.length)
                        : l10n.removeDriverConfirm,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  if (hasGroup) ...[
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          setDialogState(() => removeFromAll = !removeFromAll),
                      child: AppDialogSectionCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        backgroundColor: AppColors.error.withValues(
                          alpha: removeFromAll ? 0.10 : 0.04,
                        ),
                        borderColor: AppColors.error.withValues(
                          alpha: removeFromAll ? 0.45 : 0.22,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              removeFromAll
                                  ? LucideIcons.checkSquare
                                  : LucideIcons.square,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.removeFromAllShifts(
                                  widget.allPoolIds.length,
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
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
              footer: AppDialogFooter(
                cancelLabel: l10n.cancel,
                onCancel: () => Navigator.pop(ctx, null),
                confirmLabel: l10n.delete,
                confirmIcon: LucideIcons.trash2,
                isDestructive: true,
                onConfirm: () => Navigator.pop(ctx, removeFromAll),
              ),
            );
          },
        );
      },
    );
    if (removeFromAllChoice == null || !mounted) return;

    setState(() => _isRemoving = true);
    try {
      if (removeFromAllChoice && hasGroup) {
        final result = await ref
            .read(shiftPoolsProvider.notifier)
            .removeDriverFromPools(shift.driverId, widget.allPoolIds);
        widget.onAssigned();
        if (mounted) {
          final String msg;
          final Color bgColor;
          if (result.removed > 0 && result.skippedHistorical > 0) {
            msg = l10n.removeDriverGroupPartialSuccess(
              result.removed,
              result.skippedHistorical,
            );
            bgColor = AppColors.success;
          } else if (result.removed > 0) {
            msg = l10n.removeDriverGroupSuccess(result.removed);
            bgColor = AppColors.success;
          } else if (result.skippedHistorical > 0) {
            msg = l10n.removeDriverGroupHistoricalOnly(
              result.skippedHistorical,
            );
            bgColor = AppColors.warning;
          } else {
            msg = l10n.removeDriverGroupNoneFound;
            bgColor = AppColors.warning;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: bgColor),
          );
        }
      } else {
        await ref
            .read(shiftPoolsProvider.notifier)
            .removeDriverFromShift(shift.id);
        widget.onAssigned();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.removeDriverSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        }
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
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }

  Future<void> _removeAllDrivers(AppLocalizations l10n, ShiftPool pool) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.removeAllDrivers,
      message: l10n.removeAllDriversConfirm,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.delete,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
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
      if (_assignToAll && widget.allPoolIds.length > 1) {
        await ref
            .read(shiftPoolsProvider.notifier)
            .assignDriverToPools(driver.id, widget.allPoolIds);
      } else {
        await ref
            .read(shiftPoolsProvider.notifier)
            .assignDriver(
              AdminAssignShiftRequest(shiftPoolId: pool.id, driverId: driver.id),
            );
      }
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

  Future<void> _exportShiftPdf(DriverShift shift) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';
    try {
      List<DriverShiftOrderExportData> ordersData = [];
      if (shift.orders.isNotEmpty) {
        ordersData = shift.orders.map((o) => DriverShiftOrderExportData(
          orderNumber: o.orderNumber,
          pickedUpAt: o.pickedUpAt,
          actualDeliveryTime: o.actualDeliveryTime,
          deliveryFee: o.deliveryFee,
          driverManagerCommission: o.driverManagerCommission,
          platformProfit: o.platformProfit,
          driverEarnings: o.driverEarnings,
        )).toList();
      } else {
        try {
          final dio = ref.read(dioProvider);
          final res = await dio.get('/orders', queryParameters: {
            'driverId': shift.driverId,
            'status': 'DELIVERED',
            'limit': 50,
          });
          final rawData = res.data is Map ? (res.data['data'] ?? res.data['orders']) : res.data;
          if (rawData is List) {
            for (final item in rawData) {
              if (item is Map<String, dynamic>) {
                final sId = item['driverShiftId']?.toString();
                final actDel = item['actualDeliveryTime'] != null
                    ? DateTime.tryParse(item['actualDeliveryTime'].toString())?.toLocal()
                    : null;
                final isSameShift = sId == shift.id ||
                    (actDel != null &&
                        actDel.isAfter(shift.startTime.subtract(const Duration(minutes: 30))) &&
                        actDel.isBefore(shift.endTime.add(const Duration(minutes: 60))));

                if (isSameShift) {
                  final delFee = ((item['deliveryFee'] as num?)?.toDouble() ?? 0.0);
                  double mgrComm = 0.0;
                  if (item['driverManagerTransactions'] is List) {
                    for (final t in item['driverManagerTransactions'] as List) {
                      if (t is Map) mgrComm += ((t['amount'] as num?)?.toDouble() ?? 0.0);
                    }
                  }
                  double drvEarn = 0.0;
                  if (item['driverTransactions'] is List) {
                    for (final t in item['driverTransactions'] as List) {
                      if (t is Map) drvEarn += ((t['amount'] as num?)?.toDouble() ?? 0.0);
                    }
                  }
                  if (drvEarn == 0.0 && delFee > 0.0) drvEarn = (delFee * 0.8).roundToDouble();
                  if (mgrComm == 0.0 && delFee > 0.0) mgrComm = (delFee * 0.1).roundToDouble();
                  final platProfit = (delFee - drvEarn - mgrComm).clamp(0.0, double.infinity);

                  ordersData.add(DriverShiftOrderExportData(
                    orderNumber: item['orderNumber']?.toString() ?? '',
                    pickedUpAt: item['pickedUpAt'] != null
                        ? DateTime.tryParse(item['pickedUpAt'].toString())?.toLocal()
                        : null,
                    actualDeliveryTime: actDel,
                    deliveryFee: delFee,
                    driverManagerCommission: mgrComm,
                    platformProfit: platProfit,
                    driverEarnings: drvEarn,
                  ));
                }
              }
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      final driverName = shift.driver?.user.name ?? shift.driverId;
      final driverPhone = shift.driver?.user.phone;
      await DataExportService.exportDriverShiftPdfReport(
        context: context,
        driverName: driverName,
        driverPhone: driverPhone,
        zoneName: shift.zoneName,
        shiftTitle: shift.localizedPoolTitle(languageCode) ??
            (isAr ? 'وردية توصيل' : 'Delivery Shift'),
        shiftDate: shift.shiftDate,
        startTime: shift.startTime,
        endTime: shift.endTime,
        orders: ordersData,
        isRtl: isAr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ أثناء تصدير التقرير: ' : 'Export failed: '),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportPoolPdf(ShiftPool pool) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';
    try {
      final List<DriverShiftOrderExportData> poolOrders = [];
      for (final s in pool.driverShifts) {
        if (s.orders.isNotEmpty) {
          poolOrders.addAll(s.orders.map((o) => DriverShiftOrderExportData(
            orderNumber: o.orderNumber,
            pickedUpAt: o.pickedUpAt,
            actualDeliveryTime: o.actualDeliveryTime,
            deliveryFee: o.deliveryFee,
            driverManagerCommission: o.driverManagerCommission,
            platformProfit: o.platformProfit,
            driverEarnings: o.driverEarnings,
          )));
        }
      }

      final poolTitle = pool.localizedTitle(languageCode) ??
          (isAr ? 'وردية توصيل مجمعة' : 'Shift Pool Group');

      if (!mounted) return;
      await DataExportService.exportDriverShiftPdfReport(
        context: context,
        driverName: isAr ? '${pool.driverShifts.length} سائقين معينين' : '${pool.driverShifts.length} Assigned Drivers',
        driverPhone: null,
        zoneName: pool.zoneName,
        shiftTitle: poolTitle,
        shiftDate: pool.shiftDate,
        startTime: pool.startTime,
        endTime: pool.endTime,
        orders: poolOrders,
        isRtl: isAr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ أثناء تصدير التقرير: ' : 'Export failed: '),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
