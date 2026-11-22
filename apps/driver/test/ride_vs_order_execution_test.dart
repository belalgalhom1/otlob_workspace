import 'dart:async';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/dispatch/presentation/pages/dispatch_modal.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/order_execution/presentation/pages/order_execution_screen.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

class _FakeDriverProfile extends DriverProfile {
  @override
  AsyncValue<dynamic> build() => const AsyncValue.data({
        'id': 'drv-1',
        'name': 'Captain Kareem',
        'status': 'ON_DELIVERY',
        'vehicleType': 'CAR',
      });

  @override
  Future<void> fetchProfile() async {}
}

class _FakeDriverOrdersRepository extends Fake
    implements DriverOrdersRepository {
  int updateCalls = 0;
  String? lastUpdatedStatus;
  List<dynamic> activeOrdersToReturn = const [];

  @override
  Future<List<dynamic>> getActiveDriverOrders() async => activeOrdersToReturn;

  @override
  Future<dynamic> getPendingAssistOffers() async => const [];

  @override
  Future<dynamic> updateOrderStatus(
    String orderId,
    String status, {
    String? fulfillmentId,
    String? deliveryGroupId,
    String? note,
  }) async {
    updateCalls++;
    lastUpdatedStatus = status;
    return {'status': status};
  }
}

class _RecordingOrderExecution extends OrderExecution {
  Map<String, dynamic> currentOrder;
  int markArrivedAtPickupCalls = 0;
  int confirmPickupWithoutPhotoCalls = 0;
  int confirmDeliveryWithoutPhotoCalls = 0;

  _RecordingOrderExecution(this.currentOrder);

  @override
  AsyncValue<dynamic> build() => AsyncValue.data(currentOrder);

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markArrivedAtPickup() async {
    markArrivedAtPickupCalls++;
    currentOrder = {...currentOrder, 'status': 'READY_FOR_PICKUP'};
    state = AsyncValue.data(currentOrder);
  }

  @override
  Future<void> confirmPickupWithoutPhoto() async {
    confirmPickupWithoutPhotoCalls++;
    currentOrder = {...currentOrder, 'status': 'PICKED_UP'};
    state = AsyncValue.data(currentOrder);
  }

  @override
  Future<void> confirmDeliveryWithoutPhoto() async {
    confirmDeliveryWithoutPhotoCalls++;
    state = const AsyncValue.data(null);
  }
}

class _FakeSocketService extends Fake implements CoreSocketService {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> onEvent(SocketEvent event) => _controller.stream;
}

Map<String, dynamic> _rideOrder({String status = 'DRIVER_ASSIGNED'}) => {
      'id': 'ord-ride-1',
      'orderNumber': 'OTL-R101',
      'type': 'RIDE',
      'status': status,
      'paymentMethod': 'CASH_ON_DELIVERY',
      'paymentStatus': 'PENDING',
      'grandTotal': 45.0,
      'deliveryFee': 45.0,
      'pickupAddress': 'Tahrir Square, Cairo',
      'deliveryAddress': 'Zamalek, Cairo',
      'customer': {
        'name': 'Mona Ali',
        'phone': '+201001112233',
      },
      'vendorFulfillments': const [],
      'financials': {
        'cashToCollect': 45.0,
        'cashToPayStore': 0.0,
        'isStorePrepaid': false,
        'driverEarnings': 36.0,
        'deliveryFee': 45.0,
        'storePayments': const [],
      },
    };

Map<String, dynamic> _customOrder({String status = 'DRIVER_ASSIGNED'}) => {
      'id': 'ord-custom-1',
      'orderNumber': 'OTL-C202',
      'type': 'CUSTOM_DELIVERY',
      'status': status,
      'paymentMethod': 'CASH_ON_DELIVERY',
      'paymentStatus': 'PENDING',
      'grandTotal': 60.0,
      'deliveryFee': 60.0,
      'pickupAddress': 'Maadi, Cairo',
      'deliveryAddress': 'Nasr City, Cairo',
      'customer': {
        'name': 'Omar Tarek',
        'phone': '+201009998877',
      },
      'vendorFulfillments': const [],
      'financials': {
        'cashToCollect': 60.0,
        'cashToPayStore': 0.0,
        'isStorePrepaid': false,
        'driverEarnings': 48.0,
        'deliveryFee': 60.0,
        'storePayments': const [],
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async {
        if (call.method == 'checkPermission' ||
            call.method == 'requestPermission') {
          return 3; // whileInUse
        }
        if (call.method == 'isLocationServiceEnabled') {
          return true;
        }
        if (call.method == 'getCurrentPosition' ||
            call.method == 'getLastKnownPosition') {
          return {
            'latitude': 30.0444,
            'longitude': 31.2357,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'accuracy': 10.0,
            'altitude': 0.0,
            'altitude_accuracy': 0.0,
            'heading': 0.0,
            'heading_accuracy': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'floor': 0,
            'is_mocked': true,
          };
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      null,
    );
  });

  Widget buildExecutionHarness({
    required _RecordingOrderExecution notifier,
    required _FakeDriverOrdersRepository repo,
    Locale locale = const Locale('en'),
    Size size = const Size(360, 760),
    double textScale = 1.0,
  }) {
    final router = GoRouter(
      initialLocation: '/order-execution',
      routes: [
        GoRoute(
          path: '/order-execution',
          builder: (_, _) => const OrderExecutionScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('DASHBOARD')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
        configurationProvider.overrideWith(_FakeConfiguration.new),
        driverProfileProvider.overrideWith(_FakeDriverProfile.new),
        driverOrdersRepositoryProvider.overrideWithValue(repo),
        coreSocketServiceProvider.overrideWithValue(_FakeSocketService()),
        orderExecutionProvider.overrideWith(() => notifier),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgets(
    'Normal RIDE shows Navigate to Pickup + passenger name, hides store cash notice and photo requirements, and transitions Arrived -> Start Ride -> Complete without photos',
    (tester) async {
      final repo = _FakeDriverOrdersRepository();
      final notifier = _RecordingOrderExecution(_rideOrder());

      await tester.pumpWidget(
        buildExecutionHarness(notifier: notifier, repo: repo),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Active Ride'), findsOneWidget);
      expect(find.text('Navigate to Pickup'), findsOneWidget);
      expect(find.text('Mona Ali'), findsOneWidget);

      // Must NOT show vendor/store labels or cash-at-store banner
      expect(find.textContaining('Do not pay cash at this store'), findsNothing);
      expect(find.text('Pickup Location'), findsNothing);

      // Must NOT require or display photo prompt on normal ride
      expect(find.text('Take order photo'), findsNothing);
      expect(
        find.textContaining('photo of the order is required'),
        findsNothing,
      );

      // Step 1: Tap "I've Arrived at Pickup" -> READY_FOR_PICKUP
      expect(find.text("I've Arrived at Pickup"), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(notifier.markArrivedAtPickupCalls, 1);
      expect(find.text('Arrived at Pickup'), findsOneWidget);
      expect(find.text('Start Ride'), findsOneWidget);

      // Step 2: Tap "Start Ride" -> calls non-photo transition cleanly
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(notifier.confirmPickupWithoutPhotoCalls, 1);

      // Now PICKED_UP phase: Navigate to Dropoff, still zero photo requirement
      expect(find.text('Navigate to Dropoff'), findsOneWidget);
      expect(find.text('Take delivery photo'), findsNothing);
      expect(find.textContaining('Complete Ride'), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(notifier.confirmDeliveryWithoutPhotoCalls, 1);
      expect(find.text('DASHBOARD'), findsOneWidget);
    },
  );

  testWidgets(
    'CUSTOM_DELIVERY transitions Arrived -> Confirm Package Pickup and preserves photo requirement while hiding store-only cash notice',
    (tester) async {
      final repo = _FakeDriverOrdersRepository();
      final notifier = _RecordingOrderExecution(_customOrder());

      await tester.pumpWidget(
        buildExecutionHarness(notifier: notifier, repo: repo),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Active Custom Delivery'), findsOneWidget);
      expect(find.textContaining('Do not pay cash at this store'), findsNothing);
      expect(find.text("I've Arrived at Pickup"), findsOneWidget);

      // Driver arrives at pickup -> transitions to READY_FOR_PICKUP with photo requirement
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(notifier.markArrivedAtPickupCalls, 1);
      expect(find.text('Arrived at Pickup'), findsOneWidget);
      expect(find.text('Confirm Package Pickup'), findsOneWidget);
      expect(find.text('Take order photo'), findsOneWidget);
      expect(
        find.textContaining('photo of the order is required'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'OrderDetailsBottomSheet and DispatchModal differentiate RIDE cleanly at 320px & 1.3x TextScaler in Arabic and English',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('en-details'),
          overrides: [
            baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
            configurationProvider.overrideWith(_FakeConfiguration.new),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: OrderDetailsBottomSheet(order: _rideOrder()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Ride Details'), findsWidgets);
      expect(find.text('Your Net Ride Earnings'), findsOneWidget);
      expect(find.textContaining('Do not pay cash at store'), findsNothing);
      expect(find.textContaining('Assistant Driver'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('ar-details'),
          overrides: [
            baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
            configurationProvider.overrideWith(_FakeConfiguration.new),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ar'),
              home: Scaffold(
                body: OrderDetailsBottomSheet(order: _rideOrder()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('تفاصيل الرحلة'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('en-dispatch'),
          overrides: [
            baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
            configurationProvider.overrideWith(_FakeConfiguration.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: DispatchModal(
                dispatchData: {
                  'dispatchId': 'disp-1',
                  'orderId': 'ord-ride-1',
                  'type': 'RIDE',
                  'estimatedEarnings': 36,
                  'distanceKm': 4.2,
                  'pickupLocationName': 'Tahrir Square',
                  'dropoffLocationName': 'Zamalek',
                  'expiresAt': DateTime.now()
                      .add(const Duration(seconds: 25))
                      .toIso8601String(),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('New Ride Request!'), findsOneWidget);
      expect(find.text('Accept Ride'), findsOneWidget);
      expect(find.byIcon(LucideIcons.car), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
