import 'package:data/data.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:pdf/widgets.dart' as pw;
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/analytics/presentation/pages/analytics_screen.dart';
import 'package:vendor/features/analytics/presentation/widgets/vendor_rank_table.dart';
import 'package:vendor/features/analytics/providers/analytics_provider.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_URL=https://api.otlob-egy.online');
  });

  test('AnalyticsVendor.fromJson parses totalCommission, commissionRate, and isContracted', () {
    final vendor = AnalyticsVendor.fromJson({
      'id': 'v-1',
      'storeName': 'Test Store',
      'storeNameAr': 'متجر تجريبي',
      'walletBalance': 341,
      'totalOrders': 2,
      'totalRevenue': 180,
      'totalCommission': 18,
      'commissionRate': 10,
      'isContracted': true,
    });

    expect(vendor.totalCommission, 18);
    expect(vendor.commissionRate, 10);
    expect(vendor.isContracted, isTrue);
  });

  test('AnalyticsScreen.buildVendorsExportSection includes Commission column in Arabic and English and sorts by commission', () async {
    final vendors = [
      AnalyticsVendor(
        id: 'v-1',
        storeName: 'Store Alpha',
        storeNameAr: 'متجر ألفا',
        walletBalance: 341,
        totalOrders: 2,
        totalRevenue: 180,
        totalCommission: 18,
        topProduct: AnalyticsTopProduct(
          name: 'Panadol',
          nameAr: 'بنادول',
          totalOrders: 2,
        ),
      ),
      AnalyticsVendor(
        id: 'v-2',
        storeName: 'Store Beta',
        storeNameAr: 'متجر بيتا',
        walletBalance: 1269,
        totalOrders: 1,
        totalRevenue: 400,
        totalCommission: 60,
        topProduct: AnalyticsTopProduct(
          name: 'Item B',
          nameAr: 'صنف ب',
          totalOrders: 1,
        ),
      ),
    ];

    final arSection = AnalyticsScreen.buildVendorsExportSection(
      vendors,
      query: '',
      sortBy: 'commission',
      ar: true,
    );
    expect(arSection.headers, [
      'الترتيب',
      'المتجر',
      'الطلبات',
      'الإيرادات',
      'العمولة',
      'رصيد المحفظة',
      'أفضل منتج',
      'طلبات أفضل منتج',
    ]);
    expect(arSection.rows.first[1], 'متجر بيتا');
    expect(arSection.rows.first[3], '400.00');
    expect(arSection.rows.first[4], '60.00');
    expect(arSection.rows.last[4], '18.00');

    final enSection = AnalyticsScreen.buildVendorsExportSection(
      vendors,
      query: '',
      sortBy: 'orders',
      ar: false,
    );
    expect(enSection.headers, [
      'Rank',
      'Store',
      'Orders',
      'Revenue',
      'Commission',
      'Wallet Balance',
      'Top Product',
      'Top Product Orders',
    ]);
    expect(enSection.rows.first[1], 'Store Alpha');
    expect(enSection.rows.first[4], '18.00');

    final pdfBytes = await DataExportService.buildSectionsPdfBytes(
      title: 'Analytics Report (27/11/2026 - 27/11/2026)',
      sections: [enSection],
      isRtl: false,
      baseFont: pw.Font.helvetica(),
      boldFontOverride: pw.Font.helveticaBold(),
    );
    expect(pdfBytes.length, greaterThan(500));
    expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
  });

  testWidgets('VendorRankTable renders Commission metric pill in Arabic and English without overflow', (tester) async {
    final vendor = AnalyticsVendor(
      id: 'v-1',
      storeName: 'Burger King',
      storeNameAr: 'برجر كينج',
      walletBalance: 1143,
      totalOrders: 12,
      totalRevenue: 1270,
      totalCommission: 127,
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topVendorsProvider.overrideWith((ref) async => [vendor]),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: VendorRankTable()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('العمولة: 127.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
