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
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) =>
      false;
}

void main() {
  Future<void> pumpCancelledSheet(
    WidgetTester tester, {
    required Locale locale,
    required Map<String, dynamic> orderDetails,
    Size viewport = const Size(320, 680),
    double textScale = 1.35,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

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
          body: Stack(
            children: [
              const SizedBox.expand(),
              OrderTrackingSheetOverlay(
                orderStatus: 'CANCELLED',
                statusLabel: locale.languageCode == 'ar' ? 'ملغي' : 'Cancelled',
                orderDetails: orderDetails,
                tripPathLength: 0,
                followDriver: false,
                onRecenterDriver: () {},
                onOpenChat: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Displays named cancellation actor with avatar, preserves multiple same-status events, and renders store logos cleanly at 320px/1.35x',
    (tester) async {
      final orderDetails = <String, dynamic>{
        'id': 'ord-cancel-99',
        'status': 'CANCELLED',
        'cancelledBy': {
          'userId': 'u-1',
          'name': 'Nour El-Din',
          'nameAr': 'نور الدين',
          'role': 'ADMIN',
          'avatar': 'https://cdn.otlob-test.invalid/avatars/nour.png',
          'reason': 'Store closed early due to inventory check',
          'cancelledAt': '2026-11-20T04:15:00.000Z',
          'isSystem': false,
        },
        'vendorFulfillments': [
          {
            'id': 'ful-1',
            'status': 'PREPARING',
            'vendor': {
              'storeName': 'Fresh Market',
              'storeNameAr': 'فريش ماركت',
              'logo': 'https://cdn.otlob-test.invalid/logos/fresh.png',
            },
            'vendorBranch': {'name': 'Maadi'},
          },
          {
            'id': 'ful-2',
            'status': 'CANCELLED',
            'vendor': {
              'storeName': 'Bakery One',
              'storeNameAr': 'مخبز وان',
              'logo': 'https://cdn.otlob-test.invalid/logos/bakery.png',
            },
          },
        ],
        'statusEvents': [
          {
            'id': 'ev-3',
            'eventKey': 'cancelled:ord-cancel-99',
            'status': 'CANCELLED',
            'note': 'Cancelled by Nour El-Din',
            'actor': {
              'id': 'u-1',
              'name': 'Nour El-Din',
              'role': 'ADMIN',
              'avatar': 'https://cdn.otlob-test.invalid/avatars/nour.png',
            },
            'createdAt': '2026-11-20T04:15:00.000Z',
          },
          {
            'id': 'ev-2',
            'eventKey': 'ready:ful-1',
            'status': 'PREPARING',
            'note': 'Delivery 1: Fresh Market portion ready for pickup',
            'createdAt': '2026-11-20T04:10:00.000Z',
          },
          {
            'id': 'ev-1',
            'eventKey': 'preparing:ful-1',
            'status': 'PREPARING',
            'note': 'Delivery 1: Fresh Market portion started preparing',
            'createdAt': '2026-11-20T04:05:00.000Z',
          },
        ],
      };

      await pumpCancelledSheet(
        tester,
        locale: const Locale('en'),
        orderDetails: orderDetails,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Canceled by Nour El-Din'), findsWidgets);
      expect(find.textContaining('Store closed early'), findsOneWidget);
      expect(
        find.text('Delivery 1: Fresh Market portion ready for pickup'),
        findsOneWidget,
      );
      expect(
        find.text('Delivery 1: Fresh Market portion started preparing'),
        findsOneWidget,
      );
      expect(find.byType(AppNetworkAvatar), findsWidgets);
    },
  );
}
