import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/wallet/data/wallet_localization.dart';
import 'package:vendor/features/wallet/presentation/admin_vendor_wallet_screen.dart';
import 'package:vendor/features/wallet/presentation/vendor_product_sales_provider.dart';
import 'package:vendor/features/wallet/presentation/vendor_product_sales_screen.dart';
import 'package:vendor/features/wallet/presentation/vendor_wallet_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeActiveVendor extends ActiveVendorNotifier {
  @override
  String? build() => 'vendor-1';
}

class _FakeVendorWalletRepo extends Fake implements VendorWalletRepository {
  @override
  Future<dynamic> vendorWalletGetBalance(String vendorId) async => {
        'walletBalance': 90.0,
      };

  @override
  Future<dynamic> vendorWalletGetSummary(
    String vendorId, {
    String? type,
    String? branchId,
    String? from,
    String? to,
  }) async =>
      {
        'totalCredits': 100.0,
        'totalDebits': -10.0,
        'netChange': 90.0,
        'transactionCount': 2,
        'byType': [
          {'type': 'COMMISSION', 'total': -10.0},
          {'type': 'ORDER_REVENUE', 'total': 100.0},
        ],
      };

  @override
  Future<dynamic> vendorWalletGetTransactions(
    String vendorId, {
    String? type,
    String? branchId,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async =>
      {
        'transactions': [
          {
            'id': 'tx-comm-1',
            'type': 'COMMISSION',
            'amount': -10.0,
            'balanceAfter': 90.0,
            'description': 'Commission for order ORD-000004 (Abu zabaal )',
            'createdAt': '2026-11-16T01:04:00',
            'order': {'id': 'ord-4', 'orderNumber': 'ORD-000004'},
            'fulfillment': {
              'vendorBranch': {
                'id': 'br-1',
                'name': 'Abu zabaal',
                'nameAr': 'أبو زعبل',
              },
            },
          },
          {
            'id': 'tx-rev-1',
            'type': 'ORDER_REVENUE',
            'amount': 100.0,
            'balanceAfter': 100.0,
            'description': 'Order ORD-000004 (Abu zabaal ) revenue',
            'createdAt': '2026-11-16T01:04:00',
            'order': {'id': 'ord-4', 'orderNumber': 'ORD-000004'},
            'fulfillment': {
              'vendorBranch': {
                'id': 'br-1',
                'name': 'Abu zabaal',
                'nameAr': 'أبو زعبل',
              },
            },
          },
        ],
        'total': 2,
        'page': 1,
        'totalPages': 1,
      };
}

class _FakeVendorBranchesRepo extends Fake implements VendorBranchesRepository {
  @override
  Future<dynamic> getBranches(String vendorId) async => [
        {
          'id': 'br-1',
          'name': 'Abu zabaal',
          'nameAr': 'أبو زعبل',
        },
      ];
}

class _FakeAdminVendorWalletRepo extends Fake
    implements AdminVendorWalletRepository {
  @override
  Future<dynamic> vendorWalletAdminGetBalance(String vendorId) async => {
        'walletBalance': 90.0,
      };

  @override
  Future<dynamic> vendorWalletAdminGetSummary(
    String vendorId, {
    String? type,
    String? from,
    String? to,
  }) async =>
      {
        'totalCredits': 100.0,
        'totalDebits': -10.0,
        'netChange': 90.0,
        'transactionCount': 2,
        'byType': [
          {'type': 'COMMISSION', 'total': -10.0},
          {'type': 'ORDER_REVENUE', 'total': 100.0},
        ],
      };

  @override
  Future<dynamic> vendorWalletAdminListTransactions(
    String vendorId, {
    String? type,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  }) async =>
      {
        'transactions': [
          {
            'id': 'tx-comm-adm',
            'type': 'COMMISSION',
            'amount': -10.0,
            'balanceAfter': 90.0,
            'description': 'Commission for order ORD-000004 (Abu zabaal)',
            'createdAt': '2026-11-16T01:04:00',
          },
          {
            'id': 'tx-rev-adm',
            'type': 'ORDER_REVENUE',
            'amount': 100.0,
            'balanceAfter': 100.0,
            'description': 'Order ORD-000004 (Abu zabaal) revenue',
            'createdAt': '2026-11-16T01:04:00',
          },
        ],
        'total': 2,
        'page': 1,
        'totalPages': 1,
      };
}

Future<void> _pumpWalletWidget(
  WidgetTester tester, {
  required Widget child,
  required Locale locale,
  Size viewport = const Size(320, 640),
  TextScaler textScaler = const TextScaler.linear(1.4),
  List<dynamic> overrides = const [],
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: viewport,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            textScaler: textScaler,
          ),
          child: AppWindowConstraintGuard(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _assertNoCustomTextEllipsis(WidgetTester tester, {bool forbidEnglishTerms = false}) {
  final inputDecoratorTexts = find.descendant(
    of: find.byType(InputDecorator),
    matching: find.byType(Text),
  );
  final excludedElements = inputDecoratorTexts.evaluate().toSet();

  for (final element in find.byType(Text).evaluate()) {
    if (excludedElements.contains(element)) continue;
    final textWidget = element.widget as Text;
    final raw = textWidget.data ?? '';
    expect(
      textWidget.overflow,
      isNot(TextOverflow.ellipsis),
      reason: 'Text "$raw" should never be truncated with ellipsis',
    );
    if (forbidEnglishTerms) {
      expect(raw.contains('EGP'), isFalse, reason: 'Found untranslated EGP in "$raw"');
      expect(
        raw.contains('Commission'),
        isFalse,
        reason: 'Found untranslated Commission in "$raw"',
      );
      expect(
        raw.contains('Order '),
        isFalse,
        reason: 'Found untranslated Order in "$raw"',
      );
    }
  }
}

void main() {
  group('WalletLocalization unit tests', () {
    test('translates currency, types, descriptions, order numbers and Arabic dates', () {
      expect(WalletLocalization.currency(true), 'ج.م');
      expect(WalletLocalization.currency(false), 'EGP');

      expect(
        WalletLocalization.typeLabel('COMMISSION', isArabic: true),
        'خصم عمولة',
      );
      expect(
        WalletLocalization.typeLabel('ORDER_REVENUE', isArabic: true),
        'إيراد طلب',
      );
      expect(
        WalletLocalization.typeLabel('COMMISSION', isArabic: false),
        'Commission',
      );

      final commTx = {
        'type': 'COMMISSION',
        'description': 'Commission for order ORD-000004 (Abu zabaal )',
        'order': {'orderNumber': 'ORD-000004'},
        'fulfillment': {
          'vendorBranch': {'name': 'Abu zabaal', 'nameAr': 'أبو زعبل'},
        },
      };
      expect(
        WalletLocalization.localizeDescription(commTx, isArabic: true),
        'عمولة الطلب ORD-000004 (أبو زعبل)',
      );

      final revFallbackTx = {
        'type': 'ORDER_REVENUE',
        'description': 'Order ORD-000004 (Abu zabaal ) revenue',
      };
      expect(WalletLocalization.extractOrderNumber(revFallbackTx), 'ORD-000004');
      expect(
        WalletLocalization.localizeDescription(revFallbackTx, isArabic: true),
        'إيراد الطلب ORD-000004 (Abu zabaal)',
      );

      final shareTx = {
        'type': 'DELIVERY_SHARE',
        'description': 'Delivery manager share for order ORD-000112',
      };
      expect(
        WalletLocalization.localizeDescription(shareTx, isArabic: true),
        'نسبة إدارة التوصيل للطلب ORD-000112',
      );

      final customTx = {
        'type': 'ADJUSTMENT',
        'description': 'Special Ramadan adjustment note',
      };
      expect(
        WalletLocalization.localizeDescription(customTx, isArabic: true),
        'Special Ramadan adjustment note',
      );

      final sampleDt = DateTime(2026, 11, 16, 1, 4);
      expect(
        WalletLocalization.formatDateTime(sampleDt, isArabic: true),
        '16 نوفمبر 2026 - 1:04 ص',
      );
      expect(
        WalletLocalization.formatDateTime(sampleDt, isArabic: false),
        'Nov 16, 2026 - 01:04 AM',
      );
    });
  });

  testWidgets(
    'VendorWalletScreen translates all Commission/Order/EGP/date strings to Arabic and avoids ellipsis truncation at 320x640 @ 1.4x',
    (tester) async {
      await _pumpWalletWidget(
        tester,
        locale: const Locale('ar'),
        viewport: const Size(320, 640),
        textScaler: const TextScaler.linear(1.4),
        overrides: [
          activeVendorProvider.overrideWith(_FakeActiveVendor.new),
          vendorWalletRepositoryProvider.overrideWithValue(
            _FakeVendorWalletRepo(),
          ),
          vendorBranchesRepositoryProvider.overrideWithValue(
            _FakeVendorBranchesRepo(),
          ),
        ],
        child: const Scaffold(body: SafeArea(child: VendorWalletScreen())),
      );

      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester, forbidEnglishTerms: true);

      expect(find.textContaining('خصم عمولة'), findsWidgets);
      expect(find.textContaining('إيراد طلب'), findsWidgets);
      expect(find.text('ج.م'), findsWidgets);

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('عمولة الطلب ORD-000004 (أبو زعبل)'),
        250,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester, forbidEnglishTerms: true);
      expect(
        find.text('عمولة الطلب ORD-000004 (أبو زعبل)'),
        findsOneWidget,
      );
      expect(find.textContaining('نوفمبر'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('إيراد الطلب ORD-000004 (أبو زعبل)'),
        250,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester, forbidEnglishTerms: true);
      expect(
        find.text('إيراد الطلب ORD-000004 (أبو زعبل)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'VendorWalletScreen renders complete labels without ellipsis in English at 320x640 @ 1.4x',
    (tester) async {
      await _pumpWalletWidget(
        tester,
        locale: const Locale('en'),
        viewport: const Size(320, 640),
        textScaler: const TextScaler.linear(1.4),
        overrides: [
          activeVendorProvider.overrideWith(_FakeActiveVendor.new),
          vendorWalletRepositoryProvider.overrideWithValue(
            _FakeVendorWalletRepo(),
          ),
          vendorBranchesRepositoryProvider.overrideWithValue(
            _FakeVendorBranchesRepo(),
          ),
        ],
        child: const Scaffold(body: SafeArea(child: VendorWalletScreen())),
      );

      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester);
      expect(find.text('EGP'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Commission'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester);
      expect(find.text('Commission'), findsWidgets);
      expect(find.text('Order Revenue'), findsWidgets);
    },
  );

  testWidgets(
    'AdminVendorWalletScreen translates all terms/dates/currency to Arabic with zero ellipsis truncation at 320x640 @ 1.4x',
    (tester) async {
      await _pumpWalletWidget(
        tester,
        locale: const Locale('ar'),
        viewport: const Size(320, 640),
        textScaler: const TextScaler.linear(1.4),
        overrides: [
          adminVendorWalletRepositoryProvider.overrideWithValue(
            _FakeAdminVendorWalletRepo(),
          ),
        ],
        child: const AdminVendorWalletScreen(
          vendorId: 'vendor-1',
          vendorName: 'متجر أبو زعبل',
        ),
      );

      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester, forbidEnglishTerms: true);

      expect(find.text('ج.م'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('عمولة الطلب ORD-000004 (Abu zabaal)'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester, forbidEnglishTerms: true);
      expect(
        find.text('عمولة الطلب ORD-000004 (Abu zabaal)'),
        findsOneWidget,
      );
      expect(find.textContaining('نوفمبر'), findsWidgets);
    },
  );

  testWidgets(
    'VendorProductSalesScreen uses localized Arabic currency and wraps all text without ellipsis at 320x640 @ 1.3x',
    (tester) async {
      await _pumpWalletWidget(
        tester,
        locale: const Locale('ar'),
        viewport: const Size(320, 640),
        textScaler: const TextScaler.linear(1.3),
        overrides: [
          vendorProductSalesProvider.overrideWith(
            (ref, args) async => {
              'products': [
                {
                  'productId': 'p1',
                  'productName': 'Family Burger Meal',
                  'productNameAr': 'وجبة برجر عائلية كبيرة جداً مع بطاطس',
                  'quantitySold': 12,
                  'ordersCount': 6,
                  'grossRevenue': 1200.0,
                  'commission': 120.0,
                  'netRevenue': 1080.0,
                },
              ],
              'totals': {
                'productCount': 1,
                'quantitySold': 12,
                'ordersCount': 6,
                'grossRevenue': 1200.0,
                'commission': 120.0,
                'netRevenue': 1080.0,
              },
              'page': 1,
              'totalPages': 1,
            },
          ),
        ],
        child: const VendorProductSalesScreen(
          vendorId: 'v1',
          vendorName: 'متجر تجربة',
        ),
      );

      expect(tester.takeException(), isNull);
      _assertNoCustomTextEllipsis(tester, forbidEnglishTerms: true);
      expect(find.textContaining('ج.م'), findsWidgets);
    },
  );
}
