import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/features/orders/presentation/widgets/order_tracking_sheet.dart';
import 'package:ui_kit/ui_kit.dart';

class _SyncMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _SyncMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      false;
}

class _DirectionAwareWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _DirectionAwareWidgetsLocalizations(this._direction);

  final TextDirection _direction;

  @override
  TextDirection get textDirection => _direction;
}

class _SyncWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _SyncWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) => SynchronousFuture(
        _DirectionAwareWidgetsLocalizations(
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        ),
      );

  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) =>
      false;
}

class _SyncCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _SyncCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) =>
      false;
}

void main() {
  Map<String, dynamic> sampleMultiStoreOrder() => <String, dynamic>{
        'id': 'order-multi-1',
        'status': 'PENDING',
        'vendorFulfillments': [
          {
            'id': 'ful-1',
            'status': 'PENDING',
            'vendor': {
              'storeName': 'test2',
              'storeNameAr': 'متجر 2',
            },
            'vendorBranch': {
              'name': 'haha',
              'nameAr': 'فرع هاها',
            },
          },
          {
            'id': 'ful-2',
            'status': 'PENDING',
            'vendor': {
              'storeName': 'test',
              'storeNameAr': 'متجر 1',
            },
            'vendorBranch': {
              'name': 'Abu zabaal',
              'nameAr': 'أبو زعبل',
            },
          },
        ],
        'statusEvents': [
          {
            'status': 'PENDING',
            'createdAt': '2026-11-15T18:22:00.000Z',
            'note': 'Order sent to stores',
          },
          {
            'status': 'CREATED',
            'createdAt': '2026-11-15T18:20:00.000Z',
          },
        ],
      };

  Future<void> pumpTrackingHarness(
    WidgetTester tester, {
    Size viewport = const Size(360, 640),
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.3,
    Map<String, dynamic>? orderDetails,
    bool followDriver = false,
    int tripPathLength = 4,
    VoidCallback? onFitRoute,
    VoidCallback? onRecenterDriver,
    VoidCallback? onOpenChat,
    VoidCallback? onRateOrder,
    Widget? assistPromptWidget,
    Widget? pendingPaymentWidget,
    ValueChanged<double>? onSheetHeightChanged,
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

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          _SyncMaterialLocalizationsDelegate(),
          _SyncWidgetsLocalizationsDelegate(),
          _SyncCupertinoLocalizationsDelegate(),
        ],
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
          appBar: AppBar(
            title: Text(isArabic ? 'تتبع الطلب' : 'Track Order'),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  key: const ValueKey('mock-map'),
                  color: Colors.blueGrey.shade900,
                ),
              ),
              OrderTrackingSheetOverlay(
                orderStatus: 'PENDING',
                statusLabel: isArabic ? 'بانتظار رد المتجر' : 'Pending Vendor',
                distanceLabel: '2.4 km',
                orderDetails: orderDetails ?? sampleMultiStoreOrder(),
                tripPathLength: tripPathLength,
                followDriver: followDriver,
                onFitRoute: onFitRoute ?? () {},
                onRecenterDriver: onRecenterDriver ?? () {},
                onOpenChat: onOpenChat ?? () {},
                onRateOrder: onRateOrder,
                assistPromptWidget: assistPromptWidget,
                pendingPaymentWidget: pendingPaymentWidget,
                onSheetHeightChanged: onSheetHeightChanged,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OrderTrackingSheetOverlay UI & Responsiveness', () {
    testWidgets(
      'keeps >58% of map unobstructed by default, positions map FABs above sheet, and expands cleanly on dark 360x640 phone at 1.3x text scale',
      (tester) async {
        var fitTapped = false;
        var recenterTapped = false;
        var chatTapped = false;
        var rateTapped = false;

        await pumpTrackingHarness(
          tester,
          viewport: const Size(360, 640),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
          textScale: 1.3,
          onFitRoute: () => fitTapped = true,
          onRecenterDriver: () => recenterTapped = true,
          onOpenChat: () => chatTapped = true,
          onRateOrder: () => rateTapped = true,
        );

        final mapRect = tester.getRect(find.byKey(const ValueKey('mock-map')));
        final sheetScrollFinder = find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(SingleChildScrollView),
        );
        final initialSheetRect = tester.getRect(sheetScrollFinder);

        final visibleMapHeight = initialSheetRect.top - mapRect.top;
        expect(
          visibleMapHeight,
          greaterThan(mapRect.height * 0.58),
          reason:
              'Compact tracking sheet must leave >58% of the map viewport unobstructed initially',
        );

        // Floating map controls stay cleanly above the top edge of the sheet.
        final fitFinder = find.byIcon(Icons.alt_route_rounded);
        final recenterFinder = find.byIcon(Icons.location_searching);
        expect(fitFinder, findsOneWidget);
        expect(recenterFinder, findsOneWidget);
        expect(
          tester.getRect(recenterFinder).bottom,
          lessThanOrEqualTo(initialSheetRect.top),
        );

        await tester.tap(fitFinder);
        await tester.pump();
        expect(fitTapped, isTrue);

        await tester.tap(recenterFinder);
        await tester.pump();
        expect(recenterTapped, isTrue);

        // Quick header Chat button is immediately usable without expanding.
        expect(find.text('Order Status'), findsOneWidget);
        expect(find.text('Pending Vendor'), findsWidgets);
        expect(find.text('2 stores'), findsOneWidget);

        await tester.tap(find.text('Chat'));
        await tester.pump();
        expect(chatTapped, isTrue);

        // Expand sheet via chevron toggle and inspect full multi-store details.
        final expandChevron = find.byIcon(Icons.keyboard_arrow_up_rounded);
        expect(expandChevron, findsOneWidget);
        await tester.tap(expandChevron);
        await tester.pumpAndSettle();

        final expandedSheetRect = tester.getRect(sheetScrollFinder);
        expect(
          expandedSheetRect.top,
          lessThan(initialSheetRect.top - 80),
          reason: 'Expanding the sheet must reveal significantly more detail',
        );

        expect(find.text('Store Fulfillment Status'), findsOneWidget);
        expect(find.text('test2'), findsOneWidget);
        expect(find.text('Branch: haha'), findsOneWidget);
        expect(find.text('test'), findsOneWidget);
        expect(find.text('Branch: Abu zabaal'), findsOneWidget);
        expect(find.text('Order Updates'), findsOneWidget);

        final fullChatFinder = find.text('Order Chat');
        await tester.ensureVisible(fullChatFinder);
        await tester.pumpAndSettle();
        expect(fullChatFinder, findsOneWidget);

        final rateFinder = find.text('Rate Order');
        await tester.ensureVisible(rateFinder);
        await tester.pumpAndSettle();
        await tester.tap(rateFinder);
        await tester.pump();
        expect(rateTapped, isTrue);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'opens higher when urgent assist or pending payment prompts are present without overflowing',
      (tester) async {
        await pumpTrackingHarness(
          tester,
          viewport: const Size(360, 640),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
          textScale: 1.3,
          assistPromptWidget: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade100,
            child: const Text('Driver needs assistance confirmation'),
          ),
          pendingPaymentWidget: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade100,
            child: const Text('Complete wallet payment to dispatch driver'),
          ),
        );

        final mapRect = tester.getRect(find.byKey(const ValueKey('mock-map')));
        final sheetScrollFinder = find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(SingleChildScrollView),
        );
        final sheetRect = tester.getRect(sheetScrollFinder);

        // Urgent state still leaves ~55% of map visible (~0.45 sheet extent).
        expect(sheetRect.top - mapRect.top, greaterThan(mapRect.height * 0.48));
        expect(
          find.text('Driver needs assistance confirmation'),
          findsOneWidget,
        );
        expect(
          find.text('Complete wallet payment to dispatch driver'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders Arabic RTL layout cleanly in light mode at 1.3x text scale',
      (tester) async {
        await pumpTrackingHarness(
          tester,
          viewport: const Size(360, 640),
          locale: const Locale('ar'),
          themeMode: ThemeMode.light,
          textScale: 1.3,
        );

        final mapRect = tester.getRect(find.byKey(const ValueKey('mock-map')));
        final sheetScrollFinder = find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(SingleChildScrollView),
        );
        final sheetRect = tester.getRect(sheetScrollFinder);
        expect(sheetRect.top - mapRect.top, greaterThan(mapRect.height * 0.58));

        expect(find.text('حالة الطلب'), findsOneWidget);
        expect(find.text('2 متاجر'), findsOneWidget);
        expect(find.text('محادثة'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
        await tester.pumpAndSettle();

        expect(find.text('حالة تحضير المتاجر للطلب'), findsOneWidget);
        expect(find.text('متجر 2'), findsOneWidget);
        expect(find.text('الفرع: فرع هاها'), findsOneWidget);
        expect(find.text('تحديثات الطلب'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'reports initial collapsed height via onSheetHeightChanged on first frame',
      (tester) async {
        final reportedHeights = <double>[];
        await pumpTrackingHarness(
          tester,
          viewport: const Size(360, 640),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
          textScale: 1.3,
          onSheetHeightChanged: reportedHeights.add,
        );

        expect(reportedHeights, isNotEmpty);
        expect(reportedHeights.last, greaterThan(100.0));
        expect(reportedHeights.last, lessThan(640.0 * 0.5));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
