import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/features/driver_shifts/data/models/driver_shifts_models.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';
import 'package:vendor/core/utils/error_utils.dart';

class DriverShiftsDialog extends ConsumerStatefulWidget {
  final DriverProfile driver;

  const DriverShiftsDialog({super.key, required this.driver});

  @override
  ConsumerState<DriverShiftsDialog> createState() => _DriverShiftsDialogState();
}

class _ShiftListItem {
  final bool isWeekly;
  final List<DriverShift> shifts;
  _ShiftListItem.weekly(this.shifts) : isWeekly = true;
  _ShiftListItem.standalone(DriverShift shift)
    : isWeekly = false,
      shifts = [shift];
}

class _DriverShiftsDialogState extends ConsumerState<DriverShiftsDialog> {
  bool _isLoading = true;
  String? _error;
  List<DriverShift> _shifts = [];

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/drivers/${widget.driver.id}/shifts');

      final data = response.data is Map ? response.data['data'] : response.data;
      if (data is List) {
        final shifts = data
            .map((item) => DriverShift.fromJson(item as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _shifts = shifts;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiErrorMapper.fromError(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return DialogScaffold(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 24,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.4
                      : 0.1,
                ),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.calendarClock,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.driverShiftsEnabled,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(widget.driver.name, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '${AppLocalizations.of(context)!.failedToLoadShifts}:\n${ErrorUtils.translate(context, _error)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchShifts();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendarX,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noShiftsFound,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.driverNoScheduledShifts,
              style: const TextStyle(),
            ),
            const SizedBox(height: 24),
            _buildBookWeekButton(context, l10n),
          ],
        ),
      );
    }

    // Group shifts by batchId for weekly shifts
    final groups = <String, List<DriverShift>>{};
    final groupOrder = <String>[];
    final standalone = <DriverShift>[];
    for (final shift in _shifts) {
      if (shift.batchId != null && shift.batchId!.isNotEmpty) {
        if (!groups.containsKey(shift.batchId)) {
          groups[shift.batchId!] = [];
          groupOrder.add(shift.batchId!);
        }
        groups[shift.batchId!]!.add(shift);
      } else {
        standalone.add(shift);
      }
    }
    // Sort each group by shiftDate/startTime
    for (final key in groups.keys) {
      groups[key]!.sort((a, b) {
        final d = a.shiftDate.compareTo(b.shiftDate);
        if (d != 0) return d;
        return a.startTime.compareTo(b.startTime);
      });
    }
    standalone.sort((a, b) {
      final d = a.shiftDate.compareTo(b.shiftDate);
      if (d != 0) return d;
      return a.startTime.compareTo(b.startTime);
    });

    final items = <_ShiftListItem>[];
    for (final bid in groupOrder) {
      final list = groups[bid]!;
      items.add(_ShiftListItem.weekly(list));
    }
    for (final s in standalone) {
      items.add(_ShiftListItem.standalone(s));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: _buildBookWeekButton(context, l10n),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.isWeekly) {
                return _buildWeeklyShiftCard(context, item.shifts);
              }
              return _buildShiftCard(context, item.shifts.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookWeekButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          _showBookWeekDialog(context, l10n);
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(LucideIcons.calendarPlus, size: 18),
        label: Text(
          l10n.localeName == 'ar' ? 'حجز وردية أسبوعية' : 'Book Weekly Shift',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _showBookWeekDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    // Fetch available shift pools
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get('/driver-shifts/admin/pools');
      final raw = response.data is Map ? response.data['data'] : response.data;
      final list = raw is List
          ? raw
          : (raw is Map && raw['items'] is List ? raw['items'] as List : null);
      if (list == null || list.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.localeName == 'ar'
                    ? 'لا توجد ورديات متاحة'
                    : 'No available shifts',
              ),
            ),
          );
        }
        return;
      }

      // Group pools by batchId
      final groups = <String, List<Map<String, dynamic>>>{};
      final groupOrder = <String>[];
      for (final item in list) {
        final pool = item as Map<String, dynamic>;
        if (pool['type'] != 'WEEKLY') continue;
        final batchId = (pool['batchId'] ?? pool['id'] ?? '').toString();
        if (!groups.containsKey(batchId)) {
          groups[batchId] = [];
          groupOrder.add(batchId);
        }
        groups[batchId]!.add(pool);
      }

      if (groups.isEmpty || !context.mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.localeName == 'ar'
                    ? 'لا توجد ورديات متاحة'
                    : 'No available shifts',
              ),
            ),
          );
        }
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => DialogScaffold(
          child: AlertDialog(
            title: Text(
              l10n.localeName == 'ar'
                  ? 'حجز وردية أسبوعية'
                  : 'Book Weekly Shift',
            ),
            content: SizedBox(
              width: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groupOrder.length,
                itemBuilder: (ctx, idx) {
                  final batchId = groupOrder[idx];
                  final pools = groups[batchId]!;
                  final title =
                      pools.first['title']?.toString() ??
                      pools.first['titleAr']?.toString() ??
                      '';
                  final zoneName =
                      pools.first['zone']?['name']?.toString() ?? '';
                  final spanLabel = pools.length > 1
                      ? '${pools.length} days'
                      : '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isNotEmpty ? title : zoneName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (spanLabel.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              spanLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  final poolIds = pools
                                      .map((p) => p['id']?.toString() ?? '')
                                      .where((id) => id.isNotEmpty)
                                      .toList();
                                  final dio = ref.read(dioProvider);
                                  await dio.post(
                                    '/driver-shifts/admin/book-week',
                                    data: {
                                      'driverId': widget.driver.id,
                                      'shiftPoolIds': poolIds,
                                    },
                                  );
                                  await _fetchShifts();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.common_success_operation,
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ErrorUtils.translate(context, e),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                l10n.localeName == 'ar' ? 'حجز' : 'Book',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildWeeklyShiftCard(BuildContext context, List<DriverShift> shifts) {
    if (shifts.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final first = shifts.first;
    final locale = l10n.localeName;
    final title =
        first.localizedPoolTitle(locale) ??
        (locale == 'ar' ? 'الوردية الأسبوعية' : 'Weekly Shift');
    final zone = first.zoneName ?? '';
    final dateFormat = DateFormat('EEE, dd/MM', locale);
    final timeFormat = DateFormat('HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.calendarRange,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (zone.isNotEmpty)
                Text(
                  zone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              Text(
                locale == 'ar'
                    ? '${shifts.length} أيام'
                    : '${shifts.length} days',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...shifts.map((shift) {
              final status = shift.status;
              Color statusColor = Colors.grey;
              String statusText = status;
              if (status == 'ACTIVE') {
                statusColor = Colors.green;
                statusText = locale == 'ar' ? 'نشطة' : 'Active';
              } else if (status == 'COMPLETED') {
                statusColor = Colors.blue;
                statusText = locale == 'ar' ? 'مكتملة' : 'Completed';
              } else if (status == 'SCHEDULED') {
                statusColor = Colors.orange;
                statusText = locale == 'ar' ? 'مجدولة' : 'Scheduled';
              } else if (status == 'MISSED') {
                statusColor = Colors.red;
                statusText = locale == 'ar' ? 'فائتة' : 'Missed';
              } else if (status == 'CANCELLED') {
                statusColor = Colors.grey;
                statusText = locale == 'ar' ? 'ملغاة' : 'Cancelled';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(shift.shiftDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${timeFormat.format(shift.startTime)} - ${timeFormat.format(shift.endTime)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, DriverShift shift) {
    final statusColor = _getStatusColor(shift.status);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  shift.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              if (shift.zoneName != null)
                Text(
                  shift.zoneName!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _confirmDelete(context, shift),
                tooltip: AppLocalizations.of(context)!.deleteShift,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 17,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.date,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(shift.shiftDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.time,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (shift.totalDeliveries != null || shift.totalEarnings != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                if (shift.totalDeliveries != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.package,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${shift.totalDeliveries} ${AppLocalizations.of(context)!.deliveries}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (shift.totalEarnings != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.coins,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${shift.totalEarnings} ${AppLocalizations.of(context)!.egp}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (shift.startPhotoUrl != null &&
              shift.startPhotoUrl!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(
                  LucideIcons.camera,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  isAr ? 'صورة بدء الوردية' : 'Shift start photo',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showPhoto(context, shift.startPhotoUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: ImageUtils.formatImageUrl(shift.startPhotoUrl),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    height: 180,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 180,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.imageOff,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: ImageUtils.formatImageUrl(url),
            fit: BoxFit.contain,
            placeholder: (_, _) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (_, _, _) => const Icon(
              LucideIcons.imageOff,
              color: AppColors.textMuted,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DriverShift shift) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteShiftConfirmTitle),
        content: Text(l10n.deleteShiftConfirmMessage),
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
                await ref
                    .read(dioProvider)
                    .delete('/driver-shifts/admin/shifts/${shift.id}');
                await _fetchShifts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.shiftRemovedSuccessfully),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SCHEDULED':
        return Colors.blue;
      case 'ACTIVE':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.primary;
      case 'CANCELLED':
        return AppColors.error;
      case 'MISSED':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }
}
