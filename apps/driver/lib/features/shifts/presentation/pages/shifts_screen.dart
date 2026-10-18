import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/shifts/presentation/shifts_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core/core.dart';

import 'package:driver/features/shifts/presentation/widgets/available_shifts_tab.dart';
import 'package:driver/features/shifts/presentation/widgets/swap_board_tab.dart';
import 'package:driver/core/providers/configuration_provider.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(configurationProvider);

    if (config.hasValue && config.value?['driverShiftsEnabled'] == false) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myShiftsTitle)),
        body: EmptyStateWidget(
          icon: LucideIcons.calendarOff,
          title: l10n.shiftsDisabledTitle,
          subtitle: l10n.shiftsDisabledSubtitle,
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myShiftsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.myShiftsTab),
              Tab(text: l10n.availableShiftsTab),
              Tab(text: l10n.swapBoardTab),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        body: const TabBarView(
          children: [
            _MyShiftsTab(),
            AvailableShiftsTab(),
            SwapBoardTab(),
          ],
        ),
      ),
    );
  }
}

class _MyShiftsTab extends ConsumerStatefulWidget {
  const _MyShiftsTab();

  @override
  ConsumerState<_MyShiftsTab> createState() => _MyShiftsTabState();
}

enum _ShiftStatusFilter { all, upcoming, active, completed, missed }

class _MyShiftsTabState extends ConsumerState<_MyShiftsTab> {
  String? _startingShiftId;

  _ShiftStatusFilter _statusFilter = _ShiftStatusFilter.all;
  DateRangePreset _datePreset = DateRangePreset.all;
  DateTimeRange? _customRange;
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
    if (_statusFilter != _ShiftStatusFilter.all) count++;
    if (_datePreset != DateRangePreset.all) count++;
    return count;
  }

  String _resolveMediaUrl(String path) {
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    if (path.startsWith('http')) return path;
    return '$cleanBaseUrl$cleanPath';
  }

  void _viewPhoto(String url, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    _resolveMediaUrl(url),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      LucideIcons.imageOff,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(LucideIcons.x, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selfie + GPS start flow: capture a front-camera selfie, confirm it,
  /// then start. The backend requires the photo and verifies the driver
  /// is inside the shift zone; on success the driver goes ONLINE.
  Future<void> _startShiftWithSelfie(
    Map<String, dynamic> shift,
    AppLocalizations l10n,
  ) async {
    final isAr = l10n.localeName == 'ar';
    final shiftId = shift['id']?.toString() ?? '';
    if (shiftId.isEmpty) return;
    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (_) {
      photo = null;
    }
    if (photo == null || !mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(photo!.path),
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'سيتم إرسال هذه الصورة مع موقعك لبدء الوردية. يجب أن تكون داخل منطقة الوردية.'
                  : 'This photo and your location will start the shift. You must be inside the shift zone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(isAr ? 'إعادة الالتقاط' : 'Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.startShift),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      // Retake: restart the flow.
      if (mounted) _startShiftWithSelfie(shift, l10n);
      return;
    }

    setState(() => _startingShiftId = shiftId);
    try {
      final position = await _ensureLocationFix(isAr);
      if (position == null) {
        if (mounted) setState(() => _startingShiftId = null);
        return;
      }

      await ref.read(driverShiftsProvider.notifier).startShift(
            shiftId,
            photoPath: photo.path,
            latitude: position.latitude,
            longitude: position.longitude,
          );
      ref.invalidate(driverProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'بدأت الوردية، أنت الآن متصل' : 'Shift started — you are now online'),
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
      if (mounted) setState(() => _startingShiftId = null);
    }
  }

  /// Resolves a GPS fix for the shift start, guiding the driver through every
  /// failure mode instead of letting the backend answer with a misleading
  /// "not in shift zone". Keeps prompting until location services and the
  /// permission are enabled and a fix is obtained, or the driver cancels.
  Future<Position?> _ensureLocationFix(bool isAr) async {
    while (true) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        final go = await _showLocationPrompt(
          isAr,
          title: isAr ? 'خدمة الموقع مغلقة' : 'Location is off',
          body: isAr
              ? 'فعّل خدمة الموقع (GPS) من إعدادات الجهاز ثم عد للتطبيق.'
              : 'Turn on location services (GPS) in your device settings, then come back.',
          actionLabel: isAr ? 'فتح الإعدادات' : 'Open settings',
        );
        if (go != true) return null;
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        final go = await _showLocationPrompt(
          isAr,
          title: isAr ? 'إذن الموقع مرفوض' : 'Location permission denied',
          body: isAr
              ? 'افتح إعدادات التطبيق وامنح إذن الموقع (أثناء استخدام التطبيق) ثم عد.'
              : 'Open the app settings, allow location (while using the app), then come back.',
          actionLabel: isAr ? 'فتح الإعدادات' : 'Open settings',
        );
        if (go != true) return null;
        await Geolocator.openAppSettings();
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      if (permission == LocationPermission.denied) {
        final retry = await _showLocationPrompt(
          isAr,
          title: isAr ? 'الموقع مطلوب' : 'Location required',
          body: isAr
              ? 'لا يمكن بدء الوردية بدون إذن الموقع.'
              : 'You cannot start a shift without location permission.',
          actionLabel: isAr ? 'المحاولة مرة أخرى' : 'Try again',
        );
        if (retry != true) return null;
        continue;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 20));
      } on TimeoutException {
        final retry = await _showLocationPrompt(
          isAr,
          title: isAr ? 'تعذّر تحديد الموقع' : "Couldn't get your location",
          body: isAr
              ? 'تأكد من تشغيل GPS ووجودك في مكان مفتوح ثم أعد المحاولة.'
              : 'Make sure GPS is on and you have a clear view of the sky, then retry.',
          actionLabel: isAr ? 'إعادة المحاولة' : 'Retry',
        );
        if (retry != true) return null;
      } catch (_) {
        return null;
      }
    }
  }

  Future<bool?> _showLocationPrompt(
    bool isAr, {
    required String title,
    required String body,
    required String actionLabel,
  }) {
    if (!mounted) return Future.value(null);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
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

  Future<void> _openFilterSheet() async {
    final l10n = AppLocalizations.of(context)!;
    var status = _statusFilter;
    var preset = _datePreset;
    DateTimeRange? custom = _customRange;

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
            status = _ShiftStatusFilter.all;
            preset = DateRangePreset.all;
            custom = null;
          }),
          onApply: () {
            setState(() {
              _statusFilter = status;
              _datePreset = preset;
              _customRange = custom;
            });
            Navigator.pop(ctx);
          },
          children: [
            AppFilterSection(
              title: l10n.shiftStatusLabel,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in const [
                    _ShiftStatusFilter.all,
                    _ShiftStatusFilter.upcoming,
                    _ShiftStatusFilter.active,
                    _ShiftStatusFilter.completed,
                    _ShiftStatusFilter.missed,
                  ])
                    AppFilterChip(
                      label: _statusLabel(l10n, entry),
                      selected: status == entry,
                      onSelected: (_) => setSheet(() => status = entry),
                    ),
                ],
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, _ShiftStatusFilter status) {
    switch (status) {
      case _ShiftStatusFilter.all:
        return l10n.statusAll;
      case _ShiftStatusFilter.upcoming:
        return l10n.statusUpcoming;
      case _ShiftStatusFilter.active:
        return l10n.statusActive;
      case _ShiftStatusFilter.completed:
        return l10n.statusCompleted;
      case _ShiftStatusFilter.missed:
        return l10n.statusMissed;
    }
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
                onTap: _openFilterSheet,
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        label: _chipLabelFor(l10n, preset, _datePreset, _customRange),
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

  List<Map<String, dynamic>> _applyFilters(List<dynamic> shifts) {
    final range = resolveDateRangePreset(_datePreset, custom: _customRange);
    final q = _query.trim().toLowerCase();
    return shifts.map((e) => e as Map<String, dynamic>).where((shift) {
      if (_statusFilter != _ShiftStatusFilter.all) {
        final status = (shift['status'] ?? '').toString();
        final matches = switch (_statusFilter) {
          _ShiftStatusFilter.upcoming => status == 'SCHEDULED',
          _ShiftStatusFilter.active => status == 'ACTIVE',
          _ShiftStatusFilter.completed => status == 'COMPLETED',
          _ShiftStatusFilter.missed => status == 'MISSED' || status == 'CANCELLED',
          _ShiftStatusFilter.all => true,
        };
        if (!matches) return false;
      }
      if (range != null) {
        final raw = shift['startTime'] ?? shift['shiftPool']?['startTime'];
        final date = raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
        if (date == null) return false;
        final day = DateTime(date.year, date.month, date.day);
        final start = DateTime(range.start.year, range.start.month, range.start.day);
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }
      if (q.isNotEmpty) {
        final pool = shift['shiftPool'];
        final haystack = [
          pool is Map ? pool['title'] : null,
          pool is Map ? pool['titleAr'] : null,
          shift['zone']?['name'],
          shift['status'],
        ].map((x) => (x ?? '').toString().toLowerCase()).join(' ');
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shiftsState = ref.watch(driverShiftsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildFilterBar(l10n),
        Expanded(
          child: shiftsState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, _) {
              if (error.toString().toLowerCase().contains('shifts_disabled')) {
                return EmptyStateWidget(
                  icon: LucideIcons.calendarOff,
                  title: l10n.shiftsDisabledTitle,
                  subtitle: l10n.shiftsDisabledSubtitle,
                );
              }
              return Center(child: Text(ErrorUtils.translate(context, error)));
            },
            data: (shifts) {
              if (shifts.isEmpty) {
                return EmptyStateWidget(
                  icon: LucideIcons.calendar,
                  title: l10n.noShiftsScheduled,
                  subtitle: l10n.noUpcomingShifts,
                );
              }

              final filtered = _applyFilters(shifts);
              if (filtered.isEmpty) {
                return EmptyStateWidget(
                  icon: LucideIcons.search,
                  title: l10n.noShiftsScheduled,
                  subtitle: l10n.noUpcomingShifts,
                );
              }

              final groups = _groupShifts(filtered);
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(driverShiftsProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final headerTitle = _groupTitle(group, l10n);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (group.length > 1 || headerTitle.isNotEmpty) ...[
                          _buildGroupHeader(context, group, l10n),
                          const SizedBox(height: 10),
                        ],
                        for (int i = 0; i < group.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          _buildShiftItem(context, ref, group[i], l10n),
                        ],
                      ],
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

  Widget _buildShiftItem(BuildContext context, WidgetRef ref, Map<String, dynamic> shift, AppLocalizations l10n) {
    final status = shift['status'] ?? 'UNKNOWN';
    String startTime = shift['startTime'] ?? shift['shiftPool']?['startTime'] ?? '';
    String endTime = shift['endTime'] ?? shift['shiftPool']?['endTime'] ?? '';
    String dayLabel = '';

    try {
      final rawStart = shift['startTime'] ?? shift['shiftPool']?['startTime'] ?? '';
      if (rawStart.toString().isNotEmpty) {
        final d = DateTime.parse(rawStart.toString()).toLocal();
        try {
          dayLabel = DateFormat('EEEE, MMM d', l10n.localeName).format(d);
        } catch (_) {
          dayLabel = DateFormat('EEEE, MMM d').format(d);
        }
      }
      if (startTime.isNotEmpty) {
        final d = DateTime.parse(startTime).toLocal();
        startTime = DateFormat.jm().format(d);
      }
      if (endTime.isNotEmpty) {
        final d = DateTime.parse(endTime).toLocal();
        endTime = DateFormat.jm().format(d);
      }
    } catch (_) {}

    final zoneName = shift['zone']?['name'] ?? shift['shiftPool']?['zone']?['name'] ?? l10n.assignedZone;
    final isAr = l10n.localeName == 'ar';
    final poolData = shift['shiftPool'];
    final poolTitleAr = poolData is Map ? poolData['titleAr']?.toString().trim() : null;
    final poolTitleEn = poolData is Map ? poolData['title']?.toString().trim() : null;
    final shiftTitle = isAr
        ? ((poolTitleAr?.isNotEmpty ?? false) ? poolTitleAr! : (poolTitleEn ?? ''))
        : ((poolTitleEn?.isNotEmpty ?? false) ? poolTitleEn! : (poolTitleAr ?? ''));
    final heading = shiftTitle.isNotEmpty ? shiftTitle : zoneName;

    final isUpcoming = status == 'SCHEDULED';
    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
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
            children: [
              Expanded(
                child: Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withValues(alpha: 0.2) : (isUpcoming ? AppColors.warning.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : (isUpcoming ? AppColors.warning : Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (shiftTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zoneName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (dayLabel.isNotEmpty) ...[
            Row(
              children: [
                Icon(LucideIcons.calendarDays, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(LucideIcons.clock, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                '$startTime - $endTime',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ((shift['startPhotoUrl']?.toString().isNotEmpty ?? false)) ...[
            GestureDetector(
              onTap: () => _viewPhoto(shift['startPhotoUrl'].toString(), l10n),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _resolveMediaUrl(
                          shift['startPhotoUrl'].toString(),
                        ),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: Theme.of(context).dividerColor,
                          child: const Icon(
                            LucideIcons.imageOff,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.localeName == 'ar'
                            ? 'صورة بدء الوردية — اضغط للتكبير'
                            : 'Shift start photo — tap to enlarge',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.zoomIn, size: 18),
                  ],
                ),
              ),
            ),
          ],
          if (isUpcoming) ...[
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: l10n.startShift,
                    isLoading: _startingShiftId == shift['id']?.toString(),
                    onPressed: _startingShiftId != null
                        ? null
                        : () => _startShiftWithSelfie(
                              Map<String, dynamic>.from(shift),
                              l10n,
                            ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showOfferSwapDialog(context, ref, shift['id'], l10n);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.offerSwap, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () =>
                    _cancelShift(shift['id']?.toString() ?? '', l10n),
                icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                label: Text(
                  l10n.cancelShift,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (isActive)
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: l10n.endShift,
                isLoading: _startingShiftId == shift['id']?.toString(),
                onPressed: _startingShiftId != null
                    ? null
                    : () => _endShift(shift['id']?.toString() ?? '', l10n),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _endShift(String shiftId, AppLocalizations l10n) async {
    if (shiftId.isEmpty) return;
    final confirmed = await _confirmAction(
      title: l10n.endShiftConfirmTitle,
      message: l10n.endShiftConfirmMessage,
      confirmLabel: l10n.confirmAction,
      l10n: l10n,
    );
    if (confirmed != true) return;

    setState(() => _startingShiftId = shiftId);
    try {
      await ref.read(driverShiftsProvider.notifier).endShift(shiftId);
      ref.invalidate(driverProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.endShiftSuccess),
          backgroundColor: AppColors.success,
        ),
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
      if (mounted) setState(() => _startingShiftId = null);
    }
  }

  Future<void> _cancelShift(String shiftId, AppLocalizations l10n) async {
    if (shiftId.isEmpty) return;
    final confirmed = await _confirmAction(
      title: l10n.deleteShiftTitle,
      message: l10n.deleteShiftMessage,
      confirmLabel: l10n.deleteShift,
      l10n: l10n,
    );
    if (confirmed != true) return;

    try {
      await ref.read(driverShiftsProvider.notifier).deleteShift(shiftId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shiftCancelledSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.translate(context, e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required AppLocalizations l10n,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Booked shifts sharing a pool's [batchId] render under one header so a
  /// multi-day generation reads as a single group; legacy shifts stand alone.
  List<List<Map<String, dynamic>>> _groupShifts(List<dynamic> shifts) {
    final map = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    for (final raw in shifts) {
      final shift = raw as Map<String, dynamic>;
      final pool = shift['shiftPool'];
      final batchId = (pool is Map ? pool['batchId'] : null)?.toString() ?? '';
      final key = batchId.isNotEmpty ? 'batch:$batchId' : 'single:${shift['id']}';
      if (!map.containsKey(key)) {
        map[key] = <Map<String, dynamic>>[];
        order.add(key);
      }
      map[key]!.add(shift);
    }
    return order.map((key) => map[key]!).toList();
  }

  String _groupTitle(List<Map<String, dynamic>> group, AppLocalizations l10n) {
    final pool = group.first['shiftPool'];
    if (pool is! Map) return '';
    final isAr = l10n.localeName == 'ar';
    return ((isAr ? pool['titleAr'] : pool['title']) ??
                (isAr ? pool['title'] : pool['titleAr']) ??
                '')
            .toString()
            .trim();
  }

  String _formatDate(DateTime date, String pattern) {
    try {
      return DateFormat(pattern).format(date);
    } catch (_) {
      return '';
    }
  }

  String _groupSpan(List<Map<String, dynamic>> group) {
    DateTime? firstDt;
    DateTime? lastDt;
    for (final shift in group) {
      final raw = shift['startTime'];
      if (raw == null) continue;
      final date = DateTime.tryParse(raw.toString())?.toLocal();
      if (date == null) continue;
      if (firstDt == null || date.isBefore(firstDt)) firstDt = date;
      if (lastDt == null || date.isAfter(lastDt)) lastDt = date;
    }
    if (firstDt == null) return '';
    if (lastDt == null || firstDt.isAtSameMomentAs(lastDt)) {
      return _formatDate(firstDt, 'EEEE, MMM d');
    }
    return '${_formatDate(firstDt, 'dd MMM')} – ${_formatDate(lastDt, 'dd MMM')}';
  }

  Widget _buildGroupHeader(
    BuildContext context,
    List<Map<String, dynamic>> group,
    AppLocalizations l10n,
  ) {
    final first = group.first;
    final zoneName = first['zone']?['name'] ?? l10n.assignedZone;
    final title = _groupTitle(group, l10n);
    final heading = title.isNotEmpty ? title : zoneName;
    final span = _groupSpan(group);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.calendarDays, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (span.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    span,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(
              LucideIcons.mapPin,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              zoneName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showOfferSwapDialog(BuildContext context, WidgetRef ref, String shiftId, AppLocalizations l10n) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return DialogScaffold(child: AlertDialog(
          title: Text(l10n.offerSwap),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: l10n.reasonOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelAction),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(driverShiftsProvider.notifier).offerSwap(shiftId, reasonController.text);
                Navigator.pop(context);
              },
              child: Text(l10n.offerSwapAction),
            ),
          ],
        ));
      },
    );
  }
}
