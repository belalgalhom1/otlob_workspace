import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/orders/presentation/widgets/multi_vendor_fulfillments_section.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

void main() {
  List<Map<String, dynamic>> sampleFulfillments() => [
        {
          'id': 'ful-1',
          'status': 'PENDING',
          'subtotal': 100.0,
          'commissionRate': 10,
          'vendor': {
            'storeName': 'test2',
            'storeNameAr': 'متجر 2',
            'isContracted': true,
          },
          'vendorBranch': {
            'name': 'haha',
            'nameAr': 'فرع هاها',
            'address': 'b H',
            'phone': '01012345678',
            'isContracted': true,
          },
          'items': [
            {
              'productName': 'yahah',
              'variantName': 'package',
              'quantity': 1,
              'unitPrice': 100.0,
              'totalPrice': 100.0,
            },
          ],
        },
        {
          'id': 'ful-2',
          'status': 'PENDING',
          'subtotal': 80.0,
          'commissionRate': 10,
          'vendor': {
            'storeName': 'test',
            'storeNameAr': 'متجر 1',
            'isContracted': true,
          },
          'vendorBranch': {
            'name': 'Abu zabaal',
            'nameAr': 'أبو زعبل',
            'address': '',
            'phone': '01098765432',
            'isContracted': true,
          },
          'items': [
            {
              'productName': 'Daily Box',
              'quantity': 2,
              'unitPrice': 40.0,
              'totalPrice': 80.0,
            },
          ],
        },
      ];

  Future<void> pumpSectionHarness(
    WidgetTester tester, {
    Size viewport = const Size(360, 640),
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.3,
    void Function(String phone)? onCallStore,
    void Function(String fulfillmentId)? onAcceptFulfillment,
    void Function(String fulfillmentId, String storeName)? onRejectFulfillment,
    void Function(String fulfillmentId)? onStartPreparing,
    void Function(String fulfillmentId)? onMarkReady,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final isArabic = locale.languageCode == 'ar';
    final fulfillments = sampleFulfillments();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: themeMode,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(textScale)),
            child: AppWindowConstraintGuard(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: Scaffold(
          appBar: AppBar(title: Text(isArabic ? 'الطلبات' : 'Orders')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Container(
                key: const ValueKey('outer-order-card'),
                padding: EdgeInsets.all(viewport.width < 430 ? 12 : 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: MultiVendorFulfillmentsSection(
                  order: const {
                    'id': 'order-multi-1',
                    'status': 'PENDING',
                    'paymentMethod': 'CASH',
                  },
                  fulfillments: fulfillments,
                  allItems: const [],
                  isArabic: isArabic,
                  userRole: 'SUPER_ADMIN',
                  canManageVendors: true,
                  canManageOrders: true,
                  statusBadgeBuilder: (status, ar) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status == 'PENDING'
                          ? (ar ? 'بانتظار القرار' : 'Pending Decision')
                          : status,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onCallStore: onCallStore ?? (_) {},
                  onViewPhoto: (_) {},
                  onAcceptFulfillment: onAcceptFulfillment ?? (_) {},
                  onRejectFulfillment: onRejectFulfillment ?? (_, _) {},
                  onStartPreparing: onStartPreparing ?? (_) {},
                  onMarkReady: onMarkReady ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MultiVendorFulfillmentsSection Layout & Responsiveness', () {
    testWidgets(
      'renders store names, branch addresses, subtotals, net payout, and actions cleanly on 360x640 dark phone at 1.3x text scale',
      (tester) async {
        String? calledPhone;
        String? acceptedId;
        String? rejectedId;
        String? rejectedStore;

        await pumpSectionHarness(
          tester,
          viewport: const Size(360, 640),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
          textScale: 1.3,
          onCallStore: (p) => calledPhone = p,
          onAcceptFulfillment: (id) => acceptedId = id,
          onRejectFulfillment: (id, store) {
            rejectedId = id;
            rejectedStore = store;
          },
        );

        final outerCardRect = tester.getRect(
          find.byKey(const ValueKey('outer-order-card')),
        );

        // Store names & addresses must stay horizontal, not single-char vertical columns.
        final store1Rect = tester.getRect(find.text('test2'));
        final branch1Rect = tester.getRect(find.text('haha - b H'));
        final store2Rect = tester.getRect(find.text('test'));
        final branch2Rect = tester.getRect(find.text('Abu zabaal'));

        expect(store1Rect.height, lessThan(48));
        expect(store1Rect.width, greaterThanOrEqualTo(40));
        expect(branch1Rect.height, lessThan(48));
        expect(branch1Rect.width, greaterThanOrEqualTo(45));
        expect(store2Rect.height, lessThan(48));
        expect(branch2Rect.height, lessThan(48));
        expect(branch2Rect.width, greaterThanOrEqualTo(55));

        // Subtotal & Net payout rows stay cleanly separated and strictly inside card bounds.
        final subtotalLabelRect = tester.getRect(
          find.text('Store Subtotal').first,
        );
        final subtotalValueRect = tester.getRect(
          find.text('100.00 EGP').first,
        );
        final netLabelRect = tester.getRect(find.text('Net (90%)').first);
        final netValueRect = tester.getRect(find.text('90.00 EGP').first);

        expect(subtotalLabelRect.right, lessThan(subtotalValueRect.left));
        expect(netLabelRect.right, lessThan(netValueRect.left));
        expect(subtotalValueRect.right, lessThanOrEqualTo(outerCardRect.right));
        expect(netValueRect.right, lessThanOrEqualTo(outerCardRect.right));

        // Interactive callbacks fire as expected.
        await tester.tap(find.byTooltip('Call store').first);
        await tester.pump();
        expect(calledPhone, '01012345678');

        final acceptBtn = find.text('Accept Store').first;
        await tester.ensureVisible(acceptBtn);
        await tester.pumpAndSettle();
        await tester.tap(acceptBtn);
        await tester.pump();
        expect(acceptedId, 'ful-1');

        final rejectBtn = find.text('Reject').first;
        await tester.ensureVisible(rejectBtn);
        await tester.pumpAndSettle();
        await tester.tap(rejectBtn);
        await tester.pump();
        expect(rejectedId, 'ful-1');
        expect(rejectedStore, 'test2');

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'adapts without overflow at ultra-narrow 320x640 viewport and 1.3x text scale',
      (tester) async {
        await pumpSectionHarness(
          tester,
          viewport: const Size(320, 640),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
          textScale: 1.3,
        );

        final outerCardRect = tester.getRect(
          find.byKey(const ValueKey('outer-order-card')),
        );
        final subtotalValueRect = tester.getRect(
          find.text('100.00 EGP').first,
        );
        expect(subtotalValueRect.right, lessThanOrEqualTo(outerCardRect.right));
        expect(find.text('Accept Store'), findsNWidgets(2));
        expect(find.text('Reject'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders Arabic RTL layout in light mode and tablet 800x900 without overflow',
      (tester) async {
        await pumpSectionHarness(
          tester,
          viewport: const Size(360, 640),
          locale: const Locale('ar'),
          themeMode: ThemeMode.light,
          textScale: 1.3,
        );

        final outerCardRect = tester.getRect(
          find.byKey(const ValueKey('outer-order-card')),
        );
        final labelRect = tester.getRect(
          find.text('إجمالي أصناف المتجر').first,
        );
        final valueRect = tester.getRect(find.text('100.00 EGP').first);

        // In RTL, label stays to the right of the value without colliding or overflowing.
        expect(valueRect.right, lessThan(labelRect.left));
        expect(valueRect.left, greaterThanOrEqualTo(outerCardRect.left));
        expect(find.text('متجر 2'), findsOneWidget);
        expect(find.text('فرع هاها - b H'), findsOneWidget);
        expect(find.text('قبول هذا المتجر'), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        await pumpSectionHarness(
          tester,
          viewport: const Size(800, 900),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
          textScale: 1.3,
        );
        expect(find.text('Store Subtotal'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
