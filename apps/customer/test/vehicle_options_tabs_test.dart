import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/providers/platform_settings_provider.dart';
import 'package:otlob_customer/features/home/presentation/pages/custom_delivery_screen.dart';
import 'package:otlob_customer/features/profile/presentation/providers/coin_history_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    if (locale.languageCode == 'ar') {
      return {
        'app.customDelivery': 'توصيل مخصص',
        'app.delivery': 'توصيل',
        'app.ride': 'مشوار',
        'app.vehicleType': 'نوع المركبة',
        'app.pickupLocation': 'موقع الاستلام',
        'app.dropoffLocation': 'موقع التسليم',
        'app.enterPickupLocation': 'أدخل موقع الاستلام',
        'app.enterDropoffLocation': 'أدخل موقع التسليم',
        'app.itemDetails': 'تفاصيل الغرض',
        'app.enterItemDetails': 'أدخل تفاصيل الغرض',
        'app.requestCourier': 'طلب مندوب',
        'app.egp': 'ج.م',
        'app.motorcycle': 'موتوسيكل',
        'app.car': 'سيارة خاصة',
      };
    }
    return {
      'app.customDelivery': 'Custom Delivery',
      'app.delivery': 'Delivery',
      'app.ride': 'Ride',
      'app.vehicleType': 'Vehicle Type',
      'app.pickupLocation': 'Pickup Location',
      'app.dropoffLocation': 'Dropoff Location',
      'app.enterPickupLocation': 'Enter pickup location',
      'app.enterDropoffLocation': 'Enter dropoff location',
      'app.itemDetails': 'Item Details',
      'app.enterItemDetails': 'Enter item details',
      'app.requestCourier': 'Request Courier',
      'app.egp': 'EGP',
      'app.motorcycle': 'Motorcycle',
      'app.car': 'Private Car',
    };
  }
}

class _FakeCoinHistoryNotifier extends CoinHistory {
  @override
  CoinHistoryState build() => CoinHistoryState();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Locale locale,
    PlatformSettingsData? settings,
    double textScale = 1.0,
  }) async {
    final data = settings ?? PlatformSettingsData();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'unused',
        assetLoader: const _TestAssetLoader(),
        startLocale: locale,
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: ProviderScope(
          overrides: [
            platformSettingsProvider.overrideWith((ref) async => data),
            coinHistoryProvider.overrideWith(_FakeCoinHistoryNotifier.new),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              ),
              home: const CustomDeliveryScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Custom Delivery Tab & Ride Tab render exact English LTR options and remove old options',
    (tester) async {
      await pumpScreen(tester, locale: const Locale('en'), textScale: 1.2);

      // Default tab: Custom Delivery -> Motorcycle, Tricycle, Quarter-ton Pickup Truck, Half-ton Pickup Truck
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('Tricycle'), findsOneWidget);
      expect(find.text('Quarter-ton Pickup Truck'), findsOneWidget);
      expect(find.text('Half-ton Pickup Truck'), findsOneWidget);

      // Removed / Ride-only options must NOT appear on Custom Delivery Tab
      expect(find.text('Bicycle'), findsNothing);
      expect(find.text('Private Car'), findsNothing);
      expect(find.text('Van'), findsNothing);
      expect(find.text('Truck'), findsNothing);
      expect(find.text('Minibus'), findsNothing);
      expect(find.text('Tuk-tuk'), findsNothing);

      // Select Quarter-ton Pickup Truck, then switch to Ride Tab
      final quarterFinder =
          find.byKey(const ValueKey('vehicle_option_delivery_quarter_truck'));
      await tester.ensureVisible(quarterFinder);
      await tester.pumpAndSettle();
      await tester.tap(quarterFinder);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ride'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ride'));
      await tester.pumpAndSettle();

      // Ride Tab -> Motorcycle, Private Car, Minibus, Tuk-tuk
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('Private Car'), findsOneWidget);
      expect(find.text('Minibus'), findsOneWidget);
      expect(find.text('Tuk-tuk'), findsOneWidget);

      // Custom-only / removed options must NOT appear on Ride Tab
      expect(find.text('Tricycle'), findsNothing);
      expect(find.text('Quarter-ton Pickup Truck'), findsNothing);
      expect(find.text('Half-ton Pickup Truck'), findsNothing);
      expect(find.text('Bicycle'), findsNothing);
      expect(find.text('Van'), findsNothing);
      expect(find.text('Truck'), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Custom Delivery Tab & Ride Tab render exact Arabic RTL options cleanly at 1.25x TextScaler',
    (tester) async {
      await pumpScreen(tester, locale: const Locale('ar'), textScale: 1.25);

      // Custom Delivery Tab in Arabic RTL
      expect(find.text('موتوسيكل'), findsOneWidget);
      expect(find.text('تروسيكل'), findsOneWidget);
      expect(find.text('شاحنة ربع نقل'), findsOneWidget);
      expect(find.text('شاحنة نص نقل'), findsOneWidget);
      expect(find.text('دراجة'), findsNothing);
      expect(find.text('فان'), findsNothing);
      expect(find.text('سيارة خاصة'), findsNothing);

      // Switch to Ride Tab in Arabic RTL
      await tester.tap(find.text('مشوار'));
      await tester.pumpAndSettle();

      expect(find.text('موتوسيكل'), findsOneWidget);
      expect(find.text('سيارة خاصة'), findsOneWidget);
      expect(find.text('سيارة ميكروباص'), findsOneWidget);
      expect(find.text('توكتوك'), findsOneWidget);
      expect(find.text('تروسيكل'), findsNothing);
      expect(find.text('شاحنة ربع نقل'), findsNothing);
      expect(find.text('شاحنة نص نقل'), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Disabled vehicle types in PlatformSettingsData are hidden on Ride and Custom Delivery tabs',
    (tester) async {
      await pumpScreen(
        tester,
        locale: const Locale('en'),
        settings: PlatformSettingsData(
          allowTukTuk: false,
          allowQuarterTruck: false,
        ),
      );

      // Custom Delivery hides Quarter-ton Pickup Truck
      expect(find.text('Quarter-ton Pickup Truck'), findsNothing);
      expect(find.text('Half-ton Pickup Truck'), findsOneWidget);

      // Ride hides Tuk-tuk
      await tester.tap(find.text('Ride'));
      await tester.pumpAndSettle();
      expect(find.text('Tuk-tuk'), findsNothing);
      expect(find.text('Minibus'), findsOneWidget);
      expect(find.text('Private Car'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
