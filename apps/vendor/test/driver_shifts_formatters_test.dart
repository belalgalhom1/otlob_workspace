import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vendor/features/driver_shifts/presentation/driver_shifts_formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  group('DriverShiftsFormatters', () {
    test('formats overnight shift time range clearly in Arabic and English', () {
      final start = DateTime(2026, 11, 23, 23, 55);
      final end = DateTime(2026, 11, 24, 6, 0);

      expect(
        DriverShiftsFormatters.formatTimeRange(start, end, langCode: 'ar'),
        'من 11:55 م إلى 06:00 ص',
      );
      expect(
        DriverShiftsFormatters.formatTimeRange(start, end, langCode: 'en'),
        '11:55 PM – 06:00 AM',
      );
    });

    test('formats multi-day date range with Arabic months and clear direction', () {
      final start = DateTime(2026, 11, 23);
      final end = DateTime(2026, 11, 29);

      expect(
        DriverShiftsFormatters.formatDateRange(start, end, langCode: 'ar'),
        'من 23 نوفمبر إلى 29 نوفمبر',
      );
      expect(
        DriverShiftsFormatters.formatDateRange(start, end, langCode: 'en'),
        '23 Nov – 29 Nov',
      );
    });

    test('formats Arabic and English days count properly', () {
      expect(DriverShiftsFormatters.formatDaysCount(1, isArabic: true), 'يوم واحد');
      expect(DriverShiftsFormatters.formatDaysCount(2, isArabic: true), 'يومان');
      expect(DriverShiftsFormatters.formatDaysCount(5, isArabic: true), '5 أيام');
      expect(DriverShiftsFormatters.formatDaysCount(14, isArabic: true), '14 يوم');

      expect(DriverShiftsFormatters.formatDaysCount(1, isArabic: false), '1 day');
      expect(DriverShiftsFormatters.formatDaysCount(5, isArabic: false), '5 days');
    });
  });
}
