import 'package:api/api.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor/features/drivers/data/driver_providers.dart';
import 'package:vendor/features/drivers/presentation/driver_ranking_admin_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeSharedAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<String?> getUserRole() async => 'SUPER_ADMIN';
}

class _FakeDriversNotifier extends DriversNotifier {
  @override
  Future<DriversState> build() async => DriversState(isLoading: false);

  @override
  Future<void> refresh() async {}
}

class _FakeRankingRepo extends Fake implements AdminDriverRankingRepository {
  String? lastSearchQuery;
  DriverTier? lastTierFilter;
  int previewCallCount = 0;

  static DriverMetricsSnapshotDto _snapshot() => DriverMetricsSnapshotDto(
        (b) => b
          ..acceptedDispatches = 10
          ..rejectedDispatches = 0
          ..expiredDispatches = 0
          ..eligibleDispatches = 10
          ..cancelledDispatches = 0
          ..completedOrders = 9
          ..driverFaultFailures = 0
          ..driverResponsibleOrders = 9
          ..excludedIncidents.replace(
            ExcludedIncidentsSummaryDto(
              (e) => e
                ..customer = 0
                ..vendor = 0
                ..externalOrSystem = 0
                ..underReview = 0,
            ),
          )
          ..onTimeShifts = 5
          ..lateShifts = 0
          ..missedShifts = 0
          ..eligibleShifts = 5
          ..cancelledShifts = 0
          ..excusedShifts = 0
          ..acceptanceRate = 100.0
          ..completionRate = 100.0
          ..shiftPunctualityRate = 100.0
          ..applicableMetricsCount = 3
          ..cappedDueToNoOrders = false
          ..explanations.replace(BuiltList<String>([
            'Capped at SILVER: attended shift(s) with zero eligible dispatch/order activity',
          ])),
      );

  @override
  Future<DriverRankingScheduleStatusDto> getScheduleStatus() async {
    final w = RankingWeekWindowDto(
      (b) => b
        ..periodKey = '2026-W46'
        ..periodStart = DateTime.utc(2026, 11, 16)
        ..periodEnd = DateTime.utc(2026, 11, 22),
    );
    return DriverRankingScheduleStatusDto(
      (b) => b
        ..enabled = true
        ..evalTime = '00:05'
        ..frequency = 'WEEKLY'
        ..evaluationDay = 'MONDAY'
        ..timezone = 'Africa/Cairo'
        ..goldThreshold = 95
        ..silverThreshold = 85
        ..nextEvaluationAt = DateTime.utc(2026, 11, 23, 0, 5)
        ..currentWeek.replace(w)
        ..lastCompletedWeek.replace(w),
    );
  }

  @override
  Future<DriverRankingPreviewResponseDto> previewEvaluation({
    int page = 1,
    int limit = 50,
    String? search,
    DriverTier? tier,
  }) async {
    previewCallCount++;
    lastSearchQuery = search;
    lastTierFilter = tier;

    final allDrivers = [
      DriverRankingPreviewItemDto(
        (b) => b
          ..driverId = 'drv-1'
          ..driverName = 'test'
          ..previousTier = DriverTier.GOLD
          ..newTier = DriverTier.SILVER
          ..changeReason = DriverRankChangeReason.WEEKLY_EVALUATION
          ..outcome = DriverRankingOutcome.CAPPED_SILVER
          ..performancePercentage = 100.0
          ..acceptanceRate = 100.0
          ..completionRate = 100.0
          ..shiftPunctualityRate = 100.0
          ..metricsSnapshot.replace(_snapshot())
          ..explanations.replace(BuiltList<String>([
            'Capped at SILVER: attended shift(s) with zero eligible dispatch/order activity',
          ])),
      ),
      DriverRankingPreviewItemDto(
        (b) => b
          ..driverId = 'drv-2'
          ..driverName = 'Kareem'
          ..previousTier = DriverTier.SILVER
          ..newTier = DriverTier.GOLD
          ..changeReason = DriverRankChangeReason.WEEKLY_EVALUATION
          ..outcome = DriverRankingOutcome.PROMOTED
          ..performancePercentage = 97.5
          ..acceptanceRate = 98.0
          ..completionRate = 100.0
          ..shiftPunctualityRate = 95.0
          ..metricsSnapshot.replace(_snapshot())
          ..explanations.replace(BuiltList<String>(const [])),
      ),
    ];

    final filtered = allDrivers.where((d) {
      final matchesSearch = search == null ||
          search.trim().isEmpty ||
          d.driverName.toLowerCase().contains(search.trim().toLowerCase());
      final matchesTier = tier == null || d.previousTier == tier;
      return matchesSearch && matchesTier;
    }).toList();

    return DriverRankingPreviewResponseDto(
      (b) => b
        ..week.replace(
          RankingWeekWindowDto(
            (w) => w
              ..periodKey = '2026-W46'
              ..periodStart = DateTime.utc(2026, 11, 16)
              ..periodEnd = DateTime.utc(2026, 11, 22),
          ),
        )
        ..goldThreshold = 95
        ..silverThreshold = 85
        ..alreadyExecuted = false
        ..totalDrivers = filtered.length
        ..promotedCount = filtered
            .where((d) => d.outcome == DriverRankingOutcome.PROMOTED)
            .length
        ..demotedCount = 0
        ..unchangedCount = 0
        ..inactiveCount = 0
        ..drivers.replace(BuiltList<DriverRankingPreviewItemDto>(filtered))
        ..meta.replace(
          DriverRankingPaginationMetaDto(
            (m) => m
              ..total = filtered.length
              ..page = 1
              ..limit = limit
              ..totalPages = 1,
          ),
        ),
    );
  }

  @override
  Future<PaginatedRankingRunsResponseDto> listRuns({
    int page = 1,
    int limit = 20,
  }) async =>
      PaginatedRankingRunsResponseDto(
        (b) => b
          ..data.replace(BuiltList<DriverRankingEvaluationRunDto>(const []))
          ..meta.replace(
            DriverRankingPaginationMetaDto(
              (m) => m
                ..total = 0
                ..page = 1
                ..limit = limit
                ..totalPages = 1,
            ),
          ),
      );

  @override
  Future<PaginatedDeliveryIncidentsResponseDto> listIncidents({
    int page = 1,
    int limit = 20,
    DeliveryIncidentResponsibility? responsibility,
    String? driverId,
  }) async =>
      PaginatedDeliveryIncidentsResponseDto(
        (b) => b
          ..data.replace(BuiltList<DriverDeliveryIncidentDto>(const []))
          ..meta.replace(
            DriverRankingPaginationMetaDto(
              (m) => m
                ..total = 0
                ..page = 1
                ..limit = limit
                ..totalPages = 1,
            ),
          ),
      );

  @override
  Future<PaginatedDriverRankHistoryResponseDto> getDriverHistory(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) async {
    return PaginatedDriverRankHistoryResponseDto(
      (b) => b
        ..data.replace(
          BuiltList<DriverRankHistoryEntryDto>([
            DriverRankHistoryEntryDto(
              (h) => h
                ..id = 'hist-1'
                ..driverId = driverId
                ..driverName = JsonObject('test')
                ..periodKey = JsonObject('2026-W45')
                ..evaluatedAt = DateTime.utc(2026, 11, 16)
                ..performancePercentage = 96.4
                ..metricsSnapshot.replace(_snapshot())
                ..previousTier = DriverTier.SILVER
                ..newTier = DriverTier.GOLD
                ..changeReason = DriverRankChangeReason.WEEKLY_EVALUATION
                ..overrideReason = JsonObject('Strong weekly streak')
                ..createdAt = DateTime.utc(2026, 11, 16),
            ),
          ]),
        )
        ..meta.replace(
          DriverRankingPaginationMetaDto(
            (m) => m
              ..total = 1
              ..page = 1
              ..limit = limit
              ..totalPages = 1,
          ),
        ),
    );
  }
}

void main() {
  testWidgets(
    'DriverRankingAdminScreen renders full search bar, unclipped tabs, and non-overflowing card actions at 320px and 360px in EN/AR',
    (tester) async {
      for (final config in [
        (size: const Size(360, 740), scale: 1.0, locale: const Locale('en')),
        (size: const Size(320, 640), scale: 1.3, locale: const Locale('en')),
        (size: const Size(360, 740), scale: 1.3, locale: const Locale('ar')),
      ]) {
        await tester.binding.setSurfaceSize(config.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fakeRepo = _FakeRankingRepo();
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(config),
            overrides: [
              sharedAuthRepositoryProvider
                  .overrideWithValue(_FakeSharedAuthRepo()),
              adminDriverRankingRepositoryProvider.overrideWithValue(fakeRepo),
              driversProvider.overrideWith(_FakeDriversNotifier.new),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: config.locale,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(config.scale),
                ),
                child: child!,
              ),
              home: const DriverRankingAdminScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Scroll TabBar & Search bar into view on compact viewports (e.g. 320x640 @ 1.3x)
        final isAr = config.locale.languageCode == 'ar';
        while (find.byType(TabBar).evaluate().isEmpty) {
          await tester.drag(
            find.byType(NestedScrollView),
            const Offset(0, -180),
          );
          await tester.pumpAndSettle();
        }

        // Verify TabBar headers do not truncate or overflow
        expect(find.byType(Tab), findsNWidgets(3));
        if (!isAr) {
          expect(
            find.descendant(
              of: find.byType(TabBar),
              matching: find.text('Dry-Run Preview'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(TabBar),
              matching: find.text('Evaluation Runs'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(TabBar),
              matching: find.text('Delivery Incidents'),
            ),
            findsOneWidget,
          );
        }
        for (final element in find
            .descendant(of: find.byType(TabBar), matching: find.byType(Text))
            .evaluate()) {
          final renderParagraph = element.renderObject! as RenderParagraph;
          expect(renderParagraph.didExceedMaxLines, isFalse);
        }

        while (find.byType(TextField).evaluate().isEmpty) {
          await tester.drag(
            find.byType(NestedScrollView),
            const Offset(0, -160),
          );
          await tester.pumpAndSettle();
        }

        // Search bar has usable full width (never collapsed into a 48x48 icon)
        final searchFieldFinder = find.byType(TextField);
        expect(searchFieldFinder, findsOneWidget);
        final searchBoxSize = tester.getSize(searchFieldFinder);
        expect(searchBoxSize.width, greaterThan(200));

        // 2. Typing in search filters results cleanly via debounced API search
        await tester.enterText(searchFieldFinder, 'Kareem');
        await tester.pump(const Duration(milliseconds: 420));
        await tester.pumpAndSettle();
        expect(fakeRepo.lastSearchQuery, 'Kareem');
        final kareemCardText = find.byWidgetPredicate(
          (w) => w is Text && w.data == 'Kareem',
        );
        var scrolledForCard = 0;
        while (kareemCardText.evaluate().isEmpty && scrolledForCard < 3) {
          await tester.drag(
            find.byType(NestedScrollView),
            const Offset(0, -140),
          );
          await tester.pumpAndSettle();
          scrolledForCard++;
        }
        expect(kareemCardText, findsOneWidget);

        // Clear search (bring search bar back into view if we scrolled to inspect card)
        while (find.byType(TextField).evaluate().isEmpty) {
          await tester.drag(
            find.byType(NestedScrollView),
            const Offset(0, 140),
          );
          await tester.pumpAndSettle();
        }
        await tester.enterText(searchFieldFinder, '');
        await tester.pump(const Duration(milliseconds: 420));
        await tester.pumpAndSettle();

        // 3. Scroll down to card buttons (needed on compact 320x640 @ 1.3x) and verify zero horizontal cutoff
        final historyText = isAr ? 'السجل' : 'History';
        final overrideText = isAr ? 'تعديل الشارة' : 'Override';
        await tester.drag(find.byType(NestedScrollView), const Offset(0, -260));
        await tester.pumpAndSettle();
        if (find.text(historyText).evaluate().isEmpty) {
          await tester.drag(
            find.byType(NestedScrollView),
            const Offset(0, -260),
          );
          await tester.pumpAndSettle();
        }
        expect(find.text(historyText), findsWidgets);
        expect(find.text(overrideText), findsWidgets);

        final screenWidth = config.size.width;
        for (final finder in [
          find.text(overrideText).first,
          find.text(historyText).first,
        ]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(screenWidth));
        }

        // 4. Open History Dialog and verify title never wraps char-by-char
        await tester.tap(find.text(historyText).first);
        await tester.pumpAndSettle();

        final dialogTitleText = isAr
            ? 'سجل الشارة والتصنيف الأسبوعي'
            : 'Weekly Badge & Rank History';
        final dialogTitle = find.text(dialogTitleText);
        expect(dialogTitle, findsOneWidget);
        // Word-wrapped multi-word title (never 1-char-per-line > 400px), even at 320px @ 1.3x
        expect(tester.getSize(dialogTitle).height, lessThan(200));
        expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.text(isAr ? 'تعديل الشارة' : 'Override Badge'),
          ),
          findsOneWidget,
        );
        final closeButton = find.descendant(
          of: find.byType(Dialog),
          matching: find.text(isAr ? 'إغلاق' : 'Close'),
        );
        expect(closeButton, findsOneWidget);

        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    },
  );
}
