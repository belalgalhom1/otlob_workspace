import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/vendors/presentation/widgets/branch_working_hours_editor.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

void main() {
  group('BranchWorkingHoursEditor static helpers', () {
    test('parseWorkingHours decodes JSON string and sorts Saturday to Friday', () {
      const raw = '[{"day":5,"openTime":"14:00","closeTime":"23:00","isClosed":false},'
          '{"day":6,"openTime":"09:00","closeTime":"22:00","isClosed":false},'
          '{"day":0,"openTime":"10:00","closeTime":"20:00","isClosed":true}]';

      final parsed = BranchWorkingHoursEditor.parseWorkingHours(raw);
      expect(parsed.length, 3);
      expect(parsed.map((e) => e['day']).toList(), [6, 0, 5]);
      expect(parsed[1]['isClosed'], true);
      expect(parsed[2]['openTime'], '14:00');
    });

    test('buildScheduleSummary formats 24h, today hours, and day off in EN and AR', () {
      expect(
        BranchWorkingHoursEditor.buildScheduleSummary(
          is24Hours: true,
          rawWorkingHours: null,
          isArabic: false,
        ),
        '24 Hours',
      );
      expect(
        BranchWorkingHoursEditor.buildScheduleSummary(
          is24Hours: true,
          rawWorkingHours: null,
          isArabic: true,
        ),
        '24 ساعة',
      );

      // 2026-01-15 is Thursday (weekday 4 == JS day 4)
      final thu = DateTime(2026, 1, 15, 12, 0);
      expect(
        BranchWorkingHoursEditor.buildScheduleSummary(
          is24Hours: false,
          rawWorkingHours: [
            {'day': 4, 'openTime': '09:00', 'closeTime': '22:00', 'isClosed': false},
          ],
          isArabic: false,
          now: thu,
        ),
        '09:00 AM - 10:00 PM',
      );

      expect(
        BranchWorkingHoursEditor.buildScheduleSummary(
          is24Hours: false,
          rawWorkingHours: [
            {'day': 4, 'openTime': '09:00', 'closeTime': '22:00', 'isClosed': true},
          ],
          isArabic: true,
          now: thu,
        ),
        'اليوم: إجازة',
      );
    });
  });

  group('BranchWorkingHoursEditor widget', () {
    Widget buildHarness({
      required Locale locale,
      required bool initial24h,
      required List<Map<String, dynamic>> initialHours,
      required void Function(bool, bool, List<Map<String, dynamic>>) onStateChanged,
    }) {
      var is24h = initial24h;
      var isScheduleActive = true;
      var hours = initialHours;

      return MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return BranchWorkingHoursEditor(
                    is24Hours: is24h,
                    isScheduleActive: isScheduleActive,
                    workingHours: hours,
                    onIs24HoursChanged: (val) {
                      setState(() => is24h = val);
                      onStateChanged(is24h, isScheduleActive, hours);
                    },
                    onIsScheduleActiveChanged: (val) {
                      setState(() => isScheduleActive = val);
                      onStateChanged(is24h, isScheduleActive, hours);
                    },
                    onWorkingHoursChanged: (updated) {
                      setState(() => hours = updated);
                      onStateChanged(is24h, isScheduleActive, hours);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('adds all 7 days, applies first day to all, and switches to 24h without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var latest24h = false;
      var latestHours = <Map<String, dynamic>>[];

      await tester.pumpWidget(
        buildHarness(
          locale: const Locale('en'),
          initial24h: false,
          initialHours: const [],
          onStateChanged: (is24, _, hours) {
            latest24h = is24;
            latestHours = hours;
          },
        ),
      );

      expect(find.text('Branch Weekly Working Hours'), findsOneWidget);
      expect(find.text('Add All Days'), findsOneWidget);

      await tester.tap(find.text('Add All Days'));
      await tester.pumpAndSettle();

      expect(latestHours.length, 7);
      expect(find.text('Apply First to All'), findsOneWidget);

      // Toggle 24 Hours on
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(latest24h, true);
      expect(
        find.text('This branch operates 24 hours a day, 7 days a week.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in Arabic RTL without layout overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildHarness(
          locale: const Locale('ar'),
          initial24h: false,
          initialHours: [
            {'day': 6, 'openTime': '09:00', 'closeTime': '23:00', 'isClosed': false},
            {'day': 5, 'openTime': '14:00', 'closeTime': '23:30', 'isClosed': true},
          ],
          onStateChanged: (_, _, _) {},
        ),
      );

      expect(find.text('ساعات عمل الفرع الأسبوعية'), findsOneWidget);
      expect(find.text('السبت'), findsOneWidget);
      expect(find.text('الجمعة'), findsOneWidget);
      expect(find.text('إجازة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
