import 'package:intl/intl.dart';

/// Shared locale-aware, BiDi-safe date and time formatters for Driver Shifts.
class DriverShiftsFormatters {
  DriverShiftsFormatters._();

  static String formatTimeRange(
    DateTime start,
    DateTime end, {
    required String langCode,
  }) {
    final isArabic = langCode == 'ar';
    final locale = isArabic ? 'ar' : 'en';
    final startStr = DateFormat('hh:mm a', locale).format(start);
    final endStr = DateFormat('hh:mm a', locale).format(end);
    if (isArabic) {
      return 'من $startStr إلى $endStr';
    }
    return '$startStr – $endStr';
  }

  static String formatDateRange(
    DateTime start,
    DateTime end, {
    required String langCode,
  }) {
    final isArabic = langCode == 'ar';
    final locale = isArabic ? 'ar' : 'en';
    final startStr = DateFormat('d MMM', locale).format(start);
    final endStr = DateFormat('d MMM', locale).format(end);
    if (isArabic) {
      return 'من $startStr إلى $endStr';
    }
    return '$startStr – $endStr';
  }

  static String formatSingleDay(
    DateTime date, {
    required String langCode,
  }) {
    final isArabic = langCode == 'ar';
    final formatted = DateFormat(
      isArabic ? 'EEE، d MMM' : 'EEE, d MMM',
      isArabic ? 'ar' : 'en',
    ).format(date);
    return formatted;
  }

  static String formatDaysCount(int count, {required bool isArabic}) {
    if (!isArabic) {
      return count == 1 ? '1 day' : '$count days';
    }
    if (count == 1) return 'يوم واحد';
    if (count == 2) return 'يومان';
    if (count >= 3 && count <= 10) return '$count أيام';
    return '$count يوم';
  }
}
