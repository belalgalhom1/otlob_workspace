import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/features/driver_shifts/data/models/driver_shifts_models.dart';
import 'package:vendor/features/driver_shifts/presentation/providers/driver_shifts_provider.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/providers.dart';

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
  bool _isBulkRemoving = false;
  bool _canExcuseShifts = false;
  String? _error;
  List<DriverShift> _shifts = [];

  @override
  void initState() {
    super.initState();
    _checkRole();
    _fetchShifts();
  }

  Future<void> _checkRole() async {
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    if (mounted) {
      setState(() {
        _canExcuseShifts = role == 'SUPER_ADMIN' || role == 'ADMIN';
      });
    }
  }

  Future<void> _showExcuseShiftDialog(
    BuildContext context,
    DriverShift shift,
    bool isAr,
  ) async {
    final reasonController = TextEditingController(
      text: shift.excuseReason ?? '',
    );
    bool isExcused = !shift.isExcused;
    bool saving = false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AppDialog(
          maxWidth: 440,
          canPop: !saving,
          header: AppDialogHeader(
            icon: LucideIcons.shieldCheck,
            title: isAr
                ? 'إعفاء الوردية من تقييم الانضباط'
                : 'Excuse Shift from Punctuality Ranking',
            subtitle: widget.driver.name,
            isCloseDisabled: saving,
            onClose: () => Navigator.pop(ctx),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isAr ? 'وردية معذورة (Excused)' : 'Mark Shift as Excused',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  isAr
                      ? 'الورديات المعذورة لا تؤثر سلباً على معدل الانضباط الأسبوعي للسائق'
                      : 'Excused shifts are excluded from the driver\'s weekly punctuality penalty',
                  style: const TextStyle(fontSize: 12),
                ),
                value: isExcused,
                onChanged: saving
                    ? null
                    : (v) => setDialogState(() => isExcused = v),
                activeThumbColor: Colors.teal,
              ),
              if (isExcused) ...[
                const SizedBox(height: 12),
                AppFieldLabel(
                  label: isAr
                      ? 'سبب الإعفاء (اختياري)'
                      : 'Excuse Reason (Optional)',
                ),
                TextField(
                  controller: reasonController,
                  enabled: !saving,
                  maxLines: 2,
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: isAr
                        ? 'مثال: عطل مركبة أو ظرف طارئ...'
                        : 'e.g. Vehicle breakdown or emergency...',
                    icon: LucideIcons.fileText,
                    isMultiline: true,
                  ),
                ),
              ],
            ],
          ),
          footer: AppDialogFooter(
            cancelLabel: isAr ? 'إلغاء' : 'Cancel',
            onCancel: () => Navigator.pop(ctx),
            confirmLabel: isAr ? 'حفظ' : 'Save',
            confirmIcon: LucideIcons.check,
            isLoading: saving,
            onConfirm: () async {
              setDialogState(() => saving = true);
              try {
                await ref
                    .read(adminDriverShiftsRepositoryProvider)
                    .excuseShift(
                      shift.id,
                      isExcused: isExcused,
                      excuseReason: isExcused ? reasonController.text : null,
                    );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                setDialogState(() => saving = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(ErrorUtils.translate(ctx, e)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
    reasonController.dispose();
    if (updated == true && mounted) {
      await _fetchShifts();
    }
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
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';

    return AppDialog(
      maxWidth: 640,
      maxHeight: 780,
      scrollableBody: false,
      expandBody: true,
      bodyPadding: EdgeInsets.zero,
      header: AppDialogHeader(
        icon: LucideIcons.calendarClock,
        title: l10n.driverShiftsEnabled,
        subtitle: widget.driver.name,
        actions: [
          IconButton(
            onPressed: _shifts.isEmpty ? null : () => _exportAllShiftsPdf(),
            icon: const Icon(LucideIcons.fileSpreadsheet, size: 19),
            tooltip: isAr
                ? 'تصدير تقرير الورديات الشامل (PDF)'
                : 'Export Shifts Report (PDF)',
          ),
        ],
        onClose: () => Navigator.pop(context),
      ),
      body: _buildContent(context),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إغلاق' : 'Close',
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = AppDialogStyles.isMobile(context);
    final hPad = isMobile ? 16.0 : 24.0;
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
                '${l10n.failedToLoadShifts}:\n${ErrorUtils.translate(context, _error)}',
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
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_shifts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                l10n.noShiftsFound,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.driverNoScheduledShifts,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildBookWeekButton(context, l10n),
            ],
          ),
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
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
          child: _buildBookWeekButton(context, l10n),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
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
          foregroundColor: AppColors.onPrimary,
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
    final isAr = l10n.localeName == 'ar';
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
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'لا توجد ورديات متاحة' : 'No available shifts',
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
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'لا توجد ورديات متاحة' : 'No available shifts',
              ),
            ),
          );
        }
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final isMobile = AppDialogStyles.isMobile(ctx);
          return AppDialog(
            maxWidth: 480,
            maxHeight: 560,
            scrollableBody: false,
            expandBody: true,
            bodyPadding: EdgeInsets.all(isMobile ? 16 : 20),
            header: AppDialogHeader(
              icon: LucideIcons.calendarPlus,
              title: isAr ? 'حجز وردية أسبوعية' : 'Book Weekly Shift',
              subtitle: widget.driver.name,
              onClose: () => Navigator.pop(ctx),
            ),
            body: ListView.separated(
              itemCount: groupOrder.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                    ? (isAr ? '${pools.length} أيام' : '${pools.length} days')
                    : '';
                return AppDialogSectionCard(
                  padding: const EdgeInsets.all(14),
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
                      if (spanLabel.isNotEmpty || (title.isNotEmpty && zoneName.isNotEmpty)) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (title.isNotEmpty && zoneName.isNotEmpty)
                              AppBadgePill(text: zoneName),
                            if (spanLabel.isNotEmpty)
                              Text(
                                spanLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
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
                                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.common_success_operation,
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ErrorUtils.translate(context, e),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(LucideIcons.check, size: 15),
                          label: Text(
                            isAr ? 'حجز' : 'Book',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            footer: AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.pop(ctx),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.translate(context, e)),
          backgroundColor: AppColors.error,
        ),
      );
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

    final isAr = locale == 'ar';
    final removablePoolIds = shifts
        .where(
          (s) =>
              (s.status == 'SCHEDULED' ||
                  s.status == 'ACTIVE' ||
                  s.status == 'CANCELLED') &&
              (s.shiftPoolId ?? '').isNotEmpty,
        )
        .map((s) => s.shiftPoolId!)
        .toSet()
        .toList();

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (zone.isNotEmpty)
                Text(
                  zone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              Text(
                isAr
                    ? '${shifts.length} أيام مسجلة'
                    : '${shifts.length} recorded days',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _exportWeeklyBatchPdf(shifts, title),
                icon: const Icon(LucideIcons.fileSpreadsheet, size: 18, color: AppColors.primary),
                tooltip: isAr ? 'تصدير تقرير الأسبوع (PDF)' : 'Export Week Report (PDF)',
                visualDensity: VisualDensity.compact,
              ),
              const Icon(LucideIcons.chevronDown, size: 18),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'تقرير الأداء الإجمالي للأسبوع' : 'Weekly Aggregated Performance',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr
                        ? 'إجمالي ${shifts.length} ورديات مسجلة'
                        : 'Total ${shifts.length} scheduled shifts',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isBulkRemoving
                            ? null
                            : () => _exportWeeklyBatchPdf(shifts, title),
                        icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                        label: Text(
                          isAr ? 'تصدير الأسبوع (PDF)' : 'Export Week (PDF)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      if (removablePoolIds.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _isBulkRemoving
                              ? null
                              : () => _confirmRemoveGroup(removablePoolIds),
                          icon: _isBulkRemoving
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.error,
                                  ),
                                )
                              : const Icon(LucideIcons.trash2, size: 14),
                          label: Text(
                            l10n.removeDriverFromGroupAction(removablePoolIds.length),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ...shifts.map((shift) {
              final status = shift.status;
              Color statusColor = Colors.grey;
              String statusText = status;
              if (status == 'ACTIVE') {
                statusColor = Colors.green;
                statusText = isAr ? 'نشطة' : 'Active';
              } else if (status == 'COMPLETED') {
                statusColor = Colors.blue;
                statusText = isAr ? 'مكتملة' : 'Completed';
              } else if (status == 'SCHEDULED') {
                statusColor = Colors.orange;
                statusText = isAr ? 'مجدولة' : 'Scheduled';
              } else if (status == 'MISSED') {
                statusColor = Colors.red;
                statusText = isAr ? 'فائتة' : 'Missed';
              } else if (status == 'CANCELLED') {
                statusColor = Colors.grey;
                statusText = isAr ? 'ملغاة' : 'Cancelled';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
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
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
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
                          if (shift.isExcused) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.teal.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                isAr ? 'معذور' : 'Excused',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    dateFormat.format(shift.shiftDate),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      '${timeFormat.format(shift.startTime)} - ${timeFormat.format(shift.endTime)}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_canExcuseShifts)
                            IconButton(
                              onPressed: _isBulkRemoving
                                  ? null
                                  : () => _showExcuseShiftDialog(
                                      context,
                                      shift,
                                      isAr,
                                    ),
                              tooltip: isAr
                                  ? (shift.isExcused
                                        ? 'تعديل/إلغاء إعفاء الوردية'
                                        : 'إعفاء الوردية')
                                  : (shift.isExcused
                                        ? 'Edit/Unexcuse Shift'
                                        : 'Excuse Shift'),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                LucideIcons.shieldCheck,
                                size: 16,
                                color: shift.isExcused
                                    ? Colors.teal
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                              ),
                            ),
                          IconButton(
                            onPressed: _isBulkRemoving
                                ? null
                                : () => _confirmDelete(context, shift),
                            tooltip: AppLocalizations.of(context)!.deleteShift,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      if (shift.totalDeliveries != null || shift.totalEarnings != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (shift.totalDeliveries != null)
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.package,
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Text(
                                          '${NumberFormat('#,##0', 'en_US').format(shift.totalDeliveries)} ${AppLocalizations.of(context)!.deliveries}',
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (shift.totalDeliveries != null && shift.totalEarnings != null)
                              const SizedBox(width: 12),
                            if (shift.totalEarnings != null)
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.coins,
                                      size: 13,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            '${NumberFormat('#,##0.##', 'en_US').format(shift.totalEarnings)} ${AppLocalizations.of(context)!.egp}',
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (shift.startPhotoUrl != null && shift.startPhotoUrl!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showPhoto(context, shift.startPhotoUrl!),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: ImageUtils.formatImageUrl(shift.startPhotoUrl),
                                  height: 38,
                                  width: 38,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => Container(
                                    width: 38,
                                    height: 38,
                                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                  ),
                                  errorWidget: (_, _, _) => const Icon(LucideIcons.imageOff, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAr ? 'صورة بدء الوردية (اضغط للعرض)' : 'Shift start photo (tap to view)',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _exportShiftPdf(shift),
                          icon: const Icon(LucideIcons.fileSpreadsheet, size: 15),
                          label: Text(
                            isAr ? 'تصدير تقرير الوردية (PDF)' : 'Export Shift Report (PDF)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                            ),
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
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';

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
              if (shift.isExcused) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.teal.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    isAr ? 'معذور' : 'Excused',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: shift.zoneName != null
                    ? Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          shift.zoneName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 4),
              if (_canExcuseShifts)
                IconButton(
                  onPressed: _isBulkRemoving
                      ? null
                      : () => _showExcuseShiftDialog(context, shift, isAr),
                  tooltip: isAr
                      ? (shift.isExcused
                            ? 'تعديل/إلغاء إعفاء الوردية'
                            : 'إعفاء الوردية')
                      : (shift.isExcused
                            ? 'Edit/Unexcuse Shift'
                            : 'Excuse Shift'),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    LucideIcons.shieldCheck,
                    size: 17,
                    color: shift.isExcused
                        ? Colors.teal
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              IconButton(
                onPressed: _isBulkRemoving
                    ? null
                    : () => _confirmDelete(context, shift),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(shift.shiftDate),
                        maxLines: 1,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                    Text(
                      AppLocalizations.of(context)!.time,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
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
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${NumberFormat('#,##0', 'en_US').format(shift.totalDeliveries)} ${AppLocalizations.of(context)!.deliveries}',
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (shift.totalDeliveries != null && shift.totalEarnings != null)
                  const SizedBox(width: 12),
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
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${NumberFormat('#,##0.##', 'en_US').format(shift.totalEarnings)} ${AppLocalizations.of(context)!.egp}',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _exportShiftPdf(shift),
              icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
              label: Text(
                isAr ? 'تصدير تقرير الوردية (PDF)' : 'Export Shift Report (PDF)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        maxWidth: 680,
        maxHeight: 680,
        scrollableBody: false,
        expandBody: true,
        bodyPadding: const EdgeInsets.all(16),
        header: AppDialogHeader(
          icon: LucideIcons.image,
          title: l10n.pickupPhoto,
          onClose: () => Navigator.pop(ctx),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: AppDialogStyles.subtleSurfaceColor(ctx),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppDialogStyles.borderColor(ctx)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: ImageUtils.formatImageUrl(url),
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (_, _, _) => Center(
                  child: Icon(
                    LucideIcons.imageOff,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        footer: AppDialogFooter(
          cancelLabel: l10n.closeAction,
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DriverShift shift) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.deleteShiftConfirmTitle,
      message: l10n.deleteShiftConfirmMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(dioProvider)
          .delete('/driver-shifts/admin/shifts/${shift.id}');
      await _fetchShifts();
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(l10n.shiftRemovedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.translate(context, e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmRemoveGroup(List<String> poolIds) async {
    final uniquePoolIds = poolIds.where((id) => id.isNotEmpty).toSet().toList();
    if (_isBulkRemoving || uniquePoolIds.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.removeDriverFromGroupTitle,
      message: l10n.removeDriverGroupConfirm(uniquePoolIds.length),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBulkRemoving = true);
    try {
      final response = await ref.read(dioProvider).post(
        '/driver-shifts/admin/remove-bulk',
        data: {
          'driverId': widget.driver.id,
          'shiftPoolIds': uniquePoolIds,
        },
      );
      final raw = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final result = BulkRemoveShiftsResult.fromJson(raw);
      if (result.removed > 0) {
        ref.invalidate(shiftPoolsProvider);
      }
      await _fetchShifts();
      if (!mounted) return;

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
        msg = l10n.removeDriverGroupHistoricalOnly(result.skippedHistorical);
        bgColor = AppColors.warning;
      } else {
        msg = l10n.removeDriverGroupNoneFound;
        bgColor = AppColors.warning;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: bgColor),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.translate(context, e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBulkRemoving = false);
      }
    }
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
            'driverId': widget.driver.id,
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
      await DataExportService.exportDriverShiftPdfReport(
        context: context,
        driverName: widget.driver.name,
        driverPhone: widget.driver.phone,
        zoneName: shift.zoneName ?? widget.driver.zoneName,
        shiftTitle: shift.localizedPoolTitle(languageCode) ??
            (isAr ? 'وردية توصيل' : 'Delivery Shift'),
        shiftDate: shift.shiftDate,
        startTime: shift.startTime,
        endTime: shift.endTime,
        orders: ordersData,
        isRtl: isAr,
      );
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ أثناء تصدير التقرير: ' : 'Export failed: '),
            backgroundColor: AppColors.error,
          ),
        );
      
    }
  }

  Future<void> _exportWeeklyBatchPdf(
    List<DriverShift> shifts,
    String title,
  ) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';
    try {
      final List<DriverShiftOrderExportData> batchOrders = [];
      for (final s in shifts) {
        if (s.orders.isNotEmpty) {
          batchOrders.addAll(s.orders.map((o) => DriverShiftOrderExportData(
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

      if (batchOrders.isEmpty && shifts.isNotEmpty) {
        try {
          final dio = ref.read(dioProvider);
          final res = await dio.get('/orders', queryParameters: {
            'driverId': widget.driver.id,
            'status': 'DELIVERED',
            'limit': 100,
          });
          final rawData = res.data is Map ? (res.data['data'] ?? res.data['orders']) : res.data;
          if (rawData is List) {
            final shiftIds = shifts.map((s) => s.id).toSet();
            final minStart = shifts.map((s) => s.startTime).reduce((a, b) => a.isBefore(b) ? a : b).subtract(const Duration(minutes: 60));
            final maxEnd = shifts.map((s) => s.endTime).reduce((a, b) => a.isAfter(b) ? a : b).add(const Duration(minutes: 60));

            for (final item in rawData) {
              if (item is Map<String, dynamic>) {
                final sId = item['driverShiftId']?.toString();
                final actDel = item['actualDeliveryTime'] != null
                    ? DateTime.tryParse(item['actualDeliveryTime'].toString())?.toLocal()
                    : null;
                final inBatch = (sId != null && shiftIds.contains(sId)) ||
                    (actDel != null && actDel.isAfter(minStart) && actDel.isBefore(maxEnd));

                if (inBatch) {
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

                  batchOrders.add(DriverShiftOrderExportData(
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
      await DataExportService.exportDriverShiftPdfReport(
        context: context,
        driverName: widget.driver.name,
        driverPhone: widget.driver.phone,
        zoneName: shifts.first.zoneName ?? widget.driver.zoneName,
        shiftTitle: '$title (${shifts.length} ${isAr ? 'أيام' : 'days'})',
        shiftDate: shifts.first.shiftDate,
        startTime: shifts.first.startTime,
        endTime: shifts.last.endTime,
        orders: batchOrders,
        isRtl: isAr,
      );
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ أثناء تصدير التقرير: ' : 'Export failed: '),
            backgroundColor: AppColors.error,
          ),
        );
      
    }
  }

  Future<void> _exportAllShiftsPdf() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';
    try {
      final List<DriverShiftOrderExportData> allOrders = [];
      for (final shift in _shifts) {
        if (shift.orders.isNotEmpty) {
          allOrders.addAll(shift.orders.map((o) => DriverShiftOrderExportData(
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

      if (allOrders.isEmpty && _shifts.isNotEmpty) {
        try {
          final dio = ref.read(dioProvider);
          final res = await dio.get('/orders', queryParameters: {
            'driverId': widget.driver.id,
            'status': 'DELIVERED',
            'limit': 150,
          });
          final rawData = res.data is Map ? (res.data['data'] ?? res.data['orders']) : res.data;
          if (rawData is List) {
            for (final item in rawData) {
              if (item is Map<String, dynamic>) {
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

                allOrders.add(DriverShiftOrderExportData(
                  orderNumber: item['orderNumber']?.toString() ?? '',
                  pickedUpAt: item['pickedUpAt'] != null
                      ? DateTime.tryParse(item['pickedUpAt'].toString())?.toLocal()
                      : null,
                  actualDeliveryTime: item['actualDeliveryTime'] != null
                      ? DateTime.tryParse(item['actualDeliveryTime'].toString())?.toLocal()
                      : null,
                  deliveryFee: delFee,
                  driverManagerCommission: mgrComm,
                  platformProfit: platProfit,
                  driverEarnings: drvEarn,
                ));
              }
            }
          }
        } catch (_) {}
      }

      final firstDate = _shifts.isNotEmpty ? _shifts.first.shiftDate : DateTime.now();

      if (!mounted) return;
      await DataExportService.exportDriverShiftPdfReport(
        context: context,
        driverName: widget.driver.name,
        driverPhone: widget.driver.phone,
        zoneName: widget.driver.zoneName,
        shiftTitle: isAr ? 'تقرير كافة الورديات والعمليات' : 'All Shifts & Operations Summary',
        shiftDate: firstDate,
        orders: allOrders,
        isRtl: isAr,
      );
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'حدث خطأ أثناء تصدير التقرير: ' : 'Export failed: '),
            backgroundColor: AppColors.error,
          ),
        );
      
    }
  }
}
