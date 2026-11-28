import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/wallet/presentation/platform_statistics_provider.dart';
import 'package:vendor/features/wallet/presentation/platform_statistics_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

Widget _buildHarness({
  required Locale locale,
  required List<Map<String, dynamic>> rows,
}) {
  return ProviderScope(
    overrides: [
      platformStatisticsProvider.overrideWith((ref, args) async => rows),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const PlatformStatisticsScreen(),
    ),
  );
}

void main() {
  final sampleRows = <Map<String, dynamic>>[
    {
      'period': 'DAILY',
      'startDate': '2026-11-26T00:00:00.000Z',
      'endDate': '2026-11-26T23:59:59.999Z',
      'totalOrders': 14,
      'totalAdminRevenue': 1520,
      'totalDeliveryFees': 980,
      'totalDeliveryProfit': 310,
      'totalDriverEarnings': 545,
      'totalDriverManagerEarnings': 125,
      'totalVendorCommissions': 1150,
    },
    {
      'period': 'DAILY',
      'startDate': '2026-11-27T00:00:00.000Z',
      'endDate': '2026-11-27T23:59:59.999Z',
      'totalOrders': 9,
      'totalAdminRevenue': 840,
      'totalDeliveryFees': 620,
      'totalDeliveryProfit': 190,
      'totalDriverEarnings': 355,
      'totalDriverManagerEarnings': 75,
      'totalVendorCommissions': 600,
    },
  ];

  testWidgets(
    'renders all 7 period totals in Arabic RTL at 360px width without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildHarness(locale: const Locale('ar'), rows: sampleRows),
      );
      await tester.pumpAndSettle();

      expect(find.text('إحصائيات المنصة'), findsOneWidget);
      expect(find.text('إجمالي الطلبات'), findsOneWidget);
      expect(find.text('إجمالي أرباح المنصة'), findsOneWidget);
      expect(find.text('إجمالي رسوم التوصيل'), findsOneWidget);
      expect(find.text('إجمالي الربح من رسوم التوصيل'), findsOneWidget);
      expect(find.text('إجمالي ربح السائقين'), findsOneWidget);
      expect(find.text('إجمالي ربح مسؤولي السائقين'), findsOneWidget);
      expect(find.text('إجمالي العمولات من المتاجر'), findsOneWidget);

      expect(find.text('23'), findsOneWidget);
      expect(find.text('2,360.00 ج.م'), findsOneWidget);
      expect(find.text('1,600.00 ج.م'), findsOneWidget);
      expect(find.text('500.00 ج.م'), findsOneWidget);
      expect(find.text('900.00 ج.م'), findsOneWidget);
      expect(find.text('200.00 ج.م'), findsOneWidget);
      expect(find.text('1,750.00 ج.م'), findsOneWidget);

      // Scroll down to verify per-period breakdown chips also render cleanly
      await tester.scrollUntilVisible(
        find.text('عمولات المتاجر 1,150.00 ج.م'),
        200,
      );
      expect(find.text('ربح التوصيل 310.00 ج.م'), findsOneWidget);
      expect(find.text('ربح السائقين 545.00 ج.م'), findsOneWidget);
      expect(find.text('مسؤولو السائقين 125.00 ج.م'), findsOneWidget);
      expect(find.text('عمولات المتاجر 1,150.00 ج.م'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders all 7 period totals in English LTR without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _buildHarness(locale: const Locale('en'), rows: sampleRows),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platform Statistics'), findsOneWidget);
      expect(find.text('Total Orders'), findsOneWidget);
      expect(find.text('Total Admin Revenue'), findsOneWidget);
      expect(find.text('Total Delivery Fees'), findsOneWidget);
      expect(find.text('Delivery Fees Profit'), findsOneWidget);
      expect(find.text('Drivers Earnings'), findsOneWidget);
      expect(find.text('Driver Managers Earnings'), findsOneWidget);
      expect(find.text('Vendor Commissions'), findsOneWidget);

      expect(find.text('500.00 EGP'), findsOneWidget);
      expect(find.text('900.00 EGP'), findsOneWidget);
      expect(find.text('200.00 EGP'), findsOneWidget);
      expect(find.text('1,750.00 EGP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'gracefully defaults missing new breakdown fields to 0.00',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          locale: const Locale('ar'),
          rows: [
            {
              'period': 'DAILY',
              'startDate': '2026-11-27T00:00:00.000Z',
              'endDate': '2026-11-27T23:59:59.999Z',
              'totalOrders': 2,
              'totalAdminRevenue': 100,
              'totalDeliveryFees': 50,
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إجمالي الربح من رسوم التوصيل'), findsOneWidget);
      expect(find.text('إجمالي ربح السائقين'), findsOneWidget);
      expect(find.text('إجمالي ربح مسؤولي السائقين'), findsOneWidget);
      expect(find.text('إجمالي العمولات من المتاجر'), findsOneWidget);
      expect(find.text('0.00 ج.م'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    },
  );
}
