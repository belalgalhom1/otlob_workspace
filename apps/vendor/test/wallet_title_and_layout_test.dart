import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/legal/presentation/legal_documents_provider.dart';
import 'package:vendor/features/legal/presentation/legal_documents_screen.dart';
import 'package:vendor/features/legal/presentation/terms_acceptance_gate_screen.dart';
import 'package:vendor/features/wallet/presentation/vendor_product_sales_provider.dart';
import 'package:vendor/features/wallet/presentation/vendor_product_sales_screen.dart';
import 'package:vendor/features/wallet/presentation/wallet_dashboard_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeAdminWalletRepository extends Fake implements AdminWalletRepository {
  @override
  Future<dynamic> walletGetPendingTopUps() async => [];

  @override
  Future<dynamic> walletGetAllPlatformWallets() async => [];
}

class _FakeAdminStatisticsRepository extends Fake
    implements AdminStatisticsRepository {
  @override
  Future<dynamic> getAppStats({
    String? period,
    int? limit = 30,
    DateTime? from,
    DateTime? to,
  }) async => [];
}

class _FailingLegalDocsRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getActiveDocument(String type) async {
    throw Exception('network error');
  }
}

Future<void> _pumpVendorWidget(
  WidgetTester tester, {
  required Widget child,
  required Locale locale,
  Size viewport = const Size(360, 640),
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  TextScaler textScaler = const TextScaler.linear(1.3),
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: viewport,
            padding: padding,
            textScaler: textScaler,
          ),
          child: AppWindowConstraintGuard(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final caseData in [
    (
      locale: const Locale('en'),
      title: 'Wallet & Financials',
      viewport: const Size(360, 640),
    ),
    (
      locale: const Locale('en'),
      title: 'Wallet & Financials',
      viewport: const Size(320, 640),
    ),
    (
      locale: const Locale('ar'),
      title: 'المحفظة والمالية',
      viewport: const Size(360, 640),
    ),
    (
      locale: const Locale('ar'),
      title: 'المحفظة والمالية',
      viewport: const Size(320, 640),
    ),
  ]) {
    testWidgets(
      'WalletDashboardScreen keeps "${caseData.title}" strictly single-line with SafeArea & 1.3x scale on ${caseData.viewport.width.toInt()}px (${caseData.locale.languageCode})',
      (tester) async {
        await _pumpVendorWidget(
          tester,
          locale: caseData.locale,
          viewport: caseData.viewport,
          overrides: [
            adminWalletRepositoryProvider.overrideWithValue(
              _FakeAdminWalletRepository(),
            ),
            adminStatisticsRepositoryProvider.overrideWithValue(
              _FakeAdminStatisticsRepository(),
            ),
          ],
          child: const WalletDashboardScreen(
            userRole: 'ADMIN',
            canManageFinance: true,
            canViewStatistics: true,
          ),
        );

        expect(tester.takeException(), isNull);

        final titleFinder = find.text(caseData.title);
        expect(titleFinder, findsOneWidget);

        final titleWidget = tester.widget<Text>(titleFinder);
        expect(titleWidget.maxLines, 1);
        expect(titleWidget.softWrap, isFalse);

        final fittedBoxFinder = find.ancestor(
          of: titleFinder,
          matching: find.byType(FittedBox),
        ).first;
        expect(fittedBoxFinder, findsOneWidget);

        final fittedBox = tester.widget<FittedBox>(fittedBoxFinder);
        expect(fittedBox.fit, BoxFit.scaleDown);
        expect(fittedBox.alignment, AlignmentDirectional.centerStart);

        // Single-line verification: rendered FittedBox height stays bounded to a single line
        final titleRect = tester.getRect(titleFinder);
        final cardColumnFinder = find.ancestor(
          of: fittedBoxFinder,
          matching: find.byType(Container),
        );
        final headerBoxRect = tester.getRect(cardColumnFinder.first);
        expect(titleRect.top, greaterThanOrEqualTo(47.0));
        expect(titleRect.height, lessThan(44.0));
        expect(titleRect.left, greaterThanOrEqualTo(headerBoxRect.left - 0.5));
        expect(titleRect.right, lessThanOrEqualTo(headerBoxRect.right + 0.5));
      },
    );
  }

  testWidgets(
    'Vendor TermsAcceptanceGateScreen error state respects SafeArea & 1.3x text scale',
    (tester) async {
      await _pumpVendorWidget(
        tester,
        locale: const Locale('ar'),
        viewport: const Size(360, 600),
        overrides: [
          sharedLegalDocumentsRepositoryProvider.overrideWithValue(
            _FailingLegalDocsRepo(),
          ),
        ],
        child: const TermsAcceptanceGateScreen(),
      );

      expect(tester.takeException(), isNull);
      final retryFinder = find.text('إعادة المحاولة');
      final logoutFinder = find.text('تسجيل الخروج');
      expect(retryFinder, findsOneWidget);
      expect(logoutFinder, findsOneWidget);

      final scrollRect = tester.getRect(find.byType(SingleChildScrollView));
      expect(scrollRect.top, greaterThanOrEqualTo(47.0));
      expect(scrollRect.bottom, lessThanOrEqualTo(600.0 - 34.0));
    },
  );

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final viewport in const [
      Size(280, 640),
      Size(320, 640),
      Size(360, 640),
      Size(800, 900),
    ]) {
      testWidgets(
        'VendorProductSalesScreen handles ${viewport.width.toInt()}x${viewport.height.toInt()} at 1.3x scale without overflow or infinite width crash (${locale.languageCode})',
        (tester) async {
          await _pumpVendorWidget(
            tester,
            locale: locale,
            viewport: viewport,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            textScaler: const TextScaler.linear(1.3),
            overrides: [
              vendorProductSalesProvider.overrideWith(
                (ref, args) async => {
                  'products': [
                    {
                      'productId': 'p1',
                      'productName':
                          'Double Crispy Fried Chicken Meal Family Box Large',
                      'productNameAr':
                          'وجبة دجاج مقرمش عائلي حجم كبير جداً مع إضافات',
                      'quantitySold': 42,
                      'ordersCount': 18,
                      'grossRevenue': 6450.75,
                      'commission': 645.08,
                      'netRevenue': 5805.67,
                    },
                  ],
                  'totals': {
                    'productCount': 1,
                    'quantitySold': 42,
                    'ordersCount': 18,
                    'grossRevenue': 6450.75,
                    'commission': 645.08,
                    'netRevenue': 5805.67,
                  },
                  'page': 1,
                  'totalPages': 1,
                },
              ),
            ],
            child: const VendorProductSalesScreen(
              vendorId: 'v1',
              vendorName: 'Ultra Long Gourmet Store Branch Name',
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(SafeArea), findsWidgets);
        },
      );
    }

    testWidgets(
      'LegalDocumentsScreen tabs render without overflow at 320x640 and 1.3x scale (${locale.languageCode})',
      (tester) async {
        await _pumpVendorWidget(
          tester,
          locale: locale,
          viewport: const Size(320, 640),
          padding: const EdgeInsets.only(top: 47, bottom: 34),
          textScaler: const TextScaler.linear(1.3),
          overrides: [
            legalDocumentsProvider.overrideWith(
              () => _FakeLegalDocumentsNotifier(),
            ),
          ],
          child: const Scaffold(
            body: SafeArea(child: LegalDocumentsScreen()),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TabBar), findsOneWidget);
      },
    );
  }
}

class _FakeLegalDocumentsNotifier extends LegalDocumentsNotifier {
  @override
  LegalDocumentsState build() => const LegalDocumentsState(
        isLoading: false,
        termsDocuments: [
          {
            'id': 't1',
            'type': 'TERMS_OF_USE',
            'title': 'Vendor Terms v2.1 Extended',
            'titleAr': 'شروط الاستخدام للتجار الإصدار 2.1',
            'version': '2.1',
            'isActive': true,
          },
        ],
        privacyDocuments: [
          {
            'id': 'p1',
            'type': 'PRIVACY_POLICY',
            'title': 'Privacy Policy v1.4',
            'titleAr': 'سياسة الخصوصية الإصدار 1.4',
            'version': '1.4',
            'isActive': true,
          },
        ],
      );

  @override
  Future<void> fetchAllDocuments() async {}
}
