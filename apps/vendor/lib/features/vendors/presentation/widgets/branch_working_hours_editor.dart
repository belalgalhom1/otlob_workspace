import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

/// Reusable weekly working hours editor for a vendor branch.
///
/// Mirrors the backend `VendorBranch` schedule schema:
/// - `is24Hours`: branch operates 24/7
/// - `isScheduleActive`: automatic schedule sync is active
/// - `workingHours`: list of `{day, openTime, closeTime, isClosed}` entries
///   where `day` uses JS weekday numbering (`0` = Sunday .. `6` = Saturday).
class BranchWorkingHoursEditor extends StatelessWidget {
  final bool is24Hours;
  final bool isScheduleActive;
  final List<Map<String, dynamic>> workingHours;
  final bool enabled;
  final ValueChanged<bool> onIs24HoursChanged;
  final ValueChanged<bool> onIsScheduleActiveChanged;
  final ValueChanged<List<Map<String, dynamic>>> onWorkingHoursChanged;

  const BranchWorkingHoursEditor({
    super.key,
    required this.is24Hours,
    required this.isScheduleActive,
    required this.workingHours,
    required this.onIs24HoursChanged,
    required this.onIsScheduleActiveChanged,
    required this.onWorkingHoursChanged,
    this.enabled = true,
  });

  /// Display week order starting Saturday (Egypt business week).
  static const List<int> orderedDays = [6, 0, 1, 2, 3, 4, 5];

  static int daySortValue(int day) {
    final idx = orderedDays.indexOf(day);
    return idx == -1 ? 99 : idx;
  }

  /// Parses raw backend `workingHours` (JSON string or List) into a sorted
  /// list of mutable day-schedule maps.
  static List<Map<String, dynamic>> parseWorkingHours(dynamic rawHours) {
    dynamic decoded = rawHours;
    if (decoded is String && decoded.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        decoded = null;
      }
    }
    if (decoded is! List || decoded.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final parsed = <Map<String, dynamic>>[];
    for (final entry in decoded) {
      if (entry is Map) {
        final dayVal = entry['day'];
        final day = dayVal is int ? dayVal : int.tryParse(dayVal.toString());
        if (day == null || day < 0 || day > 6) continue;
        parsed.add({
          'day': day,
          'openTime': (entry['openTime'] ?? '09:00').toString(),
          'closeTime': (entry['closeTime'] ?? '22:00').toString(),
          'isClosed': entry['isClosed'] == true,
        });
      }
    }
    parsed.sort(
      (a, b) => daySortValue(a['day'] as int)
          .compareTo(daySortValue(b['day'] as int)),
    );
    return parsed;
  }

  static String getDayName(int day, bool isArabic) {
    switch (day) {
      case 0:
        return isArabic ? 'الأحد' : 'Sunday';
      case 1:
        return isArabic ? 'الإثنين' : 'Monday';
      case 2:
        return isArabic ? 'الثلاثاء' : 'Tuesday';
      case 3:
        return isArabic ? 'الأربعاء' : 'Wednesday';
      case 4:
        return isArabic ? 'الخميس' : 'Thursday';
      case 5:
        return isArabic ? 'الجمعة' : 'Friday';
      case 6:
        return isArabic ? 'السبت' : 'Saturday';
      default:
        return '';
    }
  }

  static String formatTimeTo12Hour(String timeStr, bool isArabic) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      final hour = int.tryParse(parts[0]) ?? 0;
      final min = int.tryParse(parts[1]) ?? 0;

      final period = hour >= 12
          ? (isArabic ? 'م' : 'PM')
          : (isArabic ? 'ص' : 'AM');
      var displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;

      final minStr = min.toString().padLeft(2, '0');
      final hourStr = displayHour.toString().padLeft(2, '0');
      return '$hourStr:$minStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  /// Concise summary label for branch list cards (24h, today's hours, or day count).
  static String? buildScheduleSummary({
    required bool is24Hours,
    required dynamic rawWorkingHours,
    required bool isArabic,
    DateTime? now,
  }) {
    if (is24Hours) {
      return isArabic ? '24 ساعة' : '24 Hours';
    }
    final hours = parseWorkingHours(rawWorkingHours);
    if (hours.isEmpty) return null;

    final refNow = now ?? DateTime.now();
    final todayJs = refNow.weekday == DateTime.sunday ? 0 : refNow.weekday;
    final todayEntry = hours.where((h) => h['day'] == todayJs).firstOrNull;
    if (todayEntry != null) {
      if (todayEntry['isClosed'] == true) {
        return isArabic ? 'اليوم: إجازة' : 'Today: Day Off';
      }
      final open = formatTimeTo12Hour(
        todayEntry['openTime']?.toString() ?? '09:00',
        isArabic,
      );
      final close = formatTimeTo12Hour(
        todayEntry['closeTime']?.toString() ?? '22:00',
        isArabic,
      );
      return '$open - $close';
    }

    final openDays = hours.where((h) => h['isClosed'] != true).length;
    return isArabic ? '$openDays أيام عمل' : '$openDays open days';
  }

  List<Map<String, dynamic>> _cloneHours() =>
      workingHours.map((e) => Map<String, dynamic>.from(e)).toList();

  void _addAllDays() {
    final existing = {for (final h in workingHours) h['day'] as int};
    final updated = _cloneHours();
    for (final day in orderedDays) {
      if (!existing.contains(day)) {
        updated.add({
          'day': day,
          'openTime': '09:00',
          'closeTime': '22:00',
          'isClosed': false,
        });
      }
    }
    updated.sort(
      (a, b) => daySortValue(a['day'] as int)
          .compareTo(daySortValue(b['day'] as int)),
    );
    onWorkingHoursChanged(updated);
    onIsScheduleActiveChanged(true);
  }

  void _applyFirstDayToAll() {
    if (workingHours.isEmpty) return;
    final updated = _cloneHours();
    final first = updated.first;
    for (var i = 1; i < updated.length; i++) {
      updated[i]['openTime'] = first['openTime'];
      updated[i]['closeTime'] = first['closeTime'];
      updated[i]['isClosed'] = first['isClosed'];
    }
    onWorkingHoursChanged(updated);
    onIsScheduleActiveChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = theme.brightness == Brightness.dark;
    final accentTextColor =
        isDark ? Colors.amber.shade300 : const Color(0xFFB45309);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.calendarClock,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic
                    ? 'ساعات عمل الفرع الأسبوعية'
                    : 'Branch Weekly Working Hours',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildTogglePill(
              context,
              label: isArabic ? '24 ساعة' : '24 Hours',
              value: is24Hours,
              onChanged: enabled ? onIs24HoursChanged : null,
            ),
            if (!is24Hours)
              _buildTogglePill(
                context,
                label: isArabic ? 'تلقائي' : 'Auto-Sync',
                value: isScheduleActive,
                onChanged: enabled ? onIsScheduleActiveChanged : null,
              ),
            if (!is24Hours && workingHours.length < 7)
              TextButton.icon(
                onPressed: enabled ? _addAllDays : null,
                icon: Icon(
                  LucideIcons.calendarPlus,
                  size: 14,
                  color: accentTextColor,
                ),
                label: Text(
                  isArabic ? 'إضافة كل الأيام' : 'Add All Days',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentTextColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: accentTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            if (!is24Hours && workingHours.length > 1)
              TextButton.icon(
                onPressed: enabled ? _applyFirstDayToAll : null,
                icon: Icon(LucideIcons.copy, size: 14, color: accentTextColor),
                label: Text(
                  isArabic ? 'تطبيق الأول على الكل' : 'Apply First to All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentTextColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: accentTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (is24Hours)
          AppDialogSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            backgroundColor: AppColors.success.withValues(alpha: 0.08),
            borderColor: AppColors.success.withValues(alpha: 0.25),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'هذا الفرع يعمل على مدار 24 ساعة طوال أيام الأسبوع.'
                        : 'This branch operates 24 hours a day, 7 days a week.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (workingHours.length < 7) ...[
            Text(
              isArabic
                  ? 'اضغط على اليوم لإضافته لمواعيد العمل:'
                  : 'Tap a day to add to working hours:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: orderedDays.map((day) {
                final isAdded = workingHours.any((h) => h['day'] == day);
                if (isAdded) return const SizedBox.shrink();
                return ActionChip(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    width: 1,
                  ),
                  label: Text(
                    getDayName(day, isArabic),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accentTextColor,
                    ),
                  ),
                  onPressed: enabled
                      ? () {
                          final updated = _cloneHours()
                            ..add({
                              'day': day,
                              'openTime': '09:00',
                              'closeTime': '22:00',
                              'isClosed': false,
                            })
                            ..sort(
                              (a, b) => daySortValue(a['day'] as int)
                                  .compareTo(daySortValue(b['day'] as int)),
                            );
                          onWorkingHoursChanged(updated);
                          onIsScheduleActiveChanged(true);
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          ...List.generate(workingHours.length, (index) {
            final schedule = workingHours[index];
            final dayNum = schedule['day'] as int;
            final isClosed = schedule['isClosed'] as bool? ?? false;
            final openTime = schedule['openTime'] as String? ?? '09:00';
            final closeTime = schedule['closeTime'] as String? ?? '22:00';

            return AppDialogSectionCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: isClosed
                  ? AppDialogStyles.subtleSurfaceColor(context)
                  : AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.05),
              borderColor: isClosed
                  ? AppDialogStyles.borderColor(context)
                  : AppColors.primary.withValues(alpha: 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: isClosed
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          getDayName(dayNum, isArabic),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isClosed
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      AppBadgePill(
                        text: isClosed
                            ? (isArabic ? 'إجازة' : 'Day Off')
                            : (isArabic ? 'مفتوح' : 'Open'),
                        accentColor:
                            isClosed ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: !isClosed,
                        activeThumbColor: AppColors.primary,
                        onChanged: enabled
                            ? (val) {
                                final updated = _cloneHours();
                                updated[index]['isClosed'] = !val;
                                onWorkingHoursChanged(updated);
                                onIsScheduleActiveChanged(true);
                              }
                            : null,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: AppColors.error,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: enabled
                            ? () {
                                final updated = _cloneHours()..removeAt(index);
                                onWorkingHoursChanged(updated);
                                onIsScheduleActiveChanged(true);
                              }
                            : null,
                      ),
                    ],
                  ),
                  if (!isClosed) ...[
                    const SizedBox(height: 8),
                    Divider(
                      color: AppDialogStyles.borderColor(context),
                      height: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _timePickerButton(
                            context,
                            timeStr: openTime,
                            label: isArabic ? 'من' : 'From',
                            enabled: enabled,
                            onTimeSelected: (newTime) {
                              final updated = _cloneHours();
                              updated[index]['openTime'] = newTime;
                              onWorkingHoursChanged(updated);
                              onIsScheduleActiveChanged(true);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isArabic
                              ? LucideIcons.arrowLeft
                              : LucideIcons.arrowRight,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _timePickerButton(
                            context,
                            timeStr: closeTime,
                            label: isArabic ? 'إلى' : 'To',
                            enabled: enabled,
                            onTimeSelected: (newTime) {
                              final updated = _cloneHours();
                              updated[index]['closeTime'] = newTime;
                              onWorkingHoursChanged(updated);
                              onIsScheduleActiveChanged(true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      isArabic ? 'مغلق طوال اليوم' : 'Closed all day',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTogglePill(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppDialogStyles.subtleSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppDialogStyles.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 26,
            width: 42,
            child: Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timePickerButton(
    BuildContext context, {
    required String timeStr,
    required String label,
    required bool enabled,
    required ValueChanged<String> onTimeSelected,
  }) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled
          ? () async {
              final parts = timeStr.split(':');
              final currentHour = int.tryParse(parts[0]) ?? 9;
              final currentMin =
                  parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

              final selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: currentHour, minute: currentMin),
                builder: AppDialogStyles.adaptivePickerTheme,
              );

              if (selectedTime != null) {
                final hh = selectedTime.hour.toString().padLeft(2, '0');
                final mm = selectedTime.minute.toString().padLeft(2, '0');
                onTimeSelected('$hh:$mm');
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppDialogStyles.backgroundColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppDialogStyles.borderColor(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Flexible(
              child: Text(
                formatTimeTo12Hour(timeStr, isAr),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
