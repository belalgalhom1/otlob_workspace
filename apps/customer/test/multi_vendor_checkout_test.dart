import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:api/api.dart' hide CartItem;
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/providers/platform_settings_provider.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/cart/presentation/pages/cart_screen.dart';
import 'package:otlob_customer/features/cart/presentation/pages/checkout_screen.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/profile/presentation/providers/coin_history_provider.dart';
import 'package:otlob_customer/features/profile/presentation/providers/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthController extends AuthController {
  final AuthStatus initialStatus;
  _TestAuthController(this.initialStatus);

  @override
  AuthStatus build() => initialStatus;
}

class _FakeProfileController extends Profile {
  final ProfileState initialProfile;
  _FakeProfileController(this.initialProfile);

  @override
  ProfileState build() => initialProfile;
}

class _FakeCoinHistory extends CoinHistory {
  @override
  CoinHistoryState build() => CoinHistoryState(currentBalance: 0);
}

class _FakeAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;
}

class _FakeCartRepo extends Fake implements CustomerCartRepository {
  Future<dynamic> Function()? onGetMyCarts;
  int getMyCartsCallCount = 0;

  @override
  Future<dynamic> getMyCarts() {
    getMyCartsCallCount++;
    if (onGetMyCarts != null) {
      return onGetMyCarts!();
    }
    return Future.value([]);
  }
}

class _FakeOrderRepo extends Fake implements CustomerOrderRepository {
  int estimateSingleCalls = 0;
  int estimateMultiCalls = 0;
  String? lastSingleVendorId;
  Future<dynamic> Function(PlaceOrderDto dto)? onEstimateSingle;
  Future<dynamic> Function(PlaceMultiVendorOrderDto dto)? onEstimateMulti;

  @override
  Future<dynamic> estimateOrder(PlaceOrderDto dto) async {
    estimateSingleCalls++;
    lastSingleVendorId = dto.vendorId;
    if (onEstimateSingle != null) {
      return onEstimateSingle!(dto);
    }
    return {
      'deliveryFee': 15,
      'driverBonusFee': 0,
      'serviceFee': 0,
      'tax': 0,
      'discount': 0,
      'coinsUsed': 0,
      'coinsEarned': 5,
      'grandTotal': 115,
    };
  }

  @override
  Future<dynamic> estimateMultiVendor(PlaceMultiVendorOrderDto dto) async {
    estimateMultiCalls++;
    if (onEstimateMulti != null) {
      return onEstimateMulti!(dto);
    }
    return {
      'deliveryFee': 25,
      'driverBonusFee': 0,
      'serviceFee': 5,
      'tax': 0,
      'discount': 0,
      'coinsUsed': 0,
      'coinsEarned': 10,
      'grandTotal': 230,
    };
  }

  @override
  Future<dynamic> getMyOrders({
    String? status,
    num limit = 20,
    num page = 1,
  }) async {
    return [];
  }
}

Map<String, dynamic> _rawServerCart(String vendorId, String itemName) => {
  'vendorId': vendorId,
  'vendor': {
    'id': vendorId,
    'storeName': 'Store $vendorId',
    'status': 'OPEN',
  },
  'items': [
    {
      'id': 'ci-$vendorId-1',
      'productId': 'prod-$vendorId-1',
      'quantity': 1,
      'unitPrice': 100,
      'totalPrice': 100,
      'selectedUnit': 'package',
      'product': {
        'id': 'prod-$vendorId-1',
        'name': itemName,
        'price': 100,
        'isActive': true,
        'tracksStock': false,
      },
      'options': [],
    },
  ],
};

class _CatalogAssetLoader extends AssetLoader {
  const _CatalogAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final code = locale.languageCode;
    final p1 = '../../packages/core/assets/translations/$code.json';
    final p2 = 'packages/core/assets/translations/$code.json';
    final file = File(File(p1).existsSync() ? p1 : p2);
    if (!file.existsSync()) return {};
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

Future<void> _pumpCheckout(
  WidgetTester tester, {
  required _FakeCartRepo fakeCartRepo,
  required _FakeOrderRepo fakeOrderRepo,
  List<Map<String, dynamic>> addresses = const [],
  List<String> vendorIds = const ['v1', 'v2'],
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(AuthStatus.authenticated),
        ),
        sharedAuthRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
        customerCartRepositoryProvider.overrideWithValue(fakeCartRepo),
        customerOrderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        profileProvider.overrideWith(
          () => _FakeProfileController(
            ProfileState(
              name: 'Test',
              email: 't@example.com',
              phone: '01000000000',
              avatar: '',
              isArabic: locale.languageCode == 'ar',
              addresses: addresses,
            ),
          ),
        ),
        coinHistoryProvider.overrideWith(() => _FakeCoinHistory()),
        platformSettingsProvider.overrideWith(
          (ref) async => PlatformSettingsData(),
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'packages/core/assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        assetLoader: const _CatalogAssetLoader(),
        useOnlyLangCode: true,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: CheckoutScreen(vendorIds: vendorIds),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpCart(
  WidgetTester tester, {
  required _FakeCartRepo fakeCartRepo,
  required _FakeOrderRepo fakeOrderRepo,
  required PlatformSettingsData settings,
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(AuthStatus.authenticated),
        ),
        sharedAuthRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
        customerCartRepositoryProvider.overrideWithValue(fakeCartRepo),
        customerOrderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        profileProvider.overrideWith(
          () => _FakeProfileController(
            ProfileState(
              name: 'Test',
              email: 't@example.com',
              phone: '01000000000',
              avatar: '',
              isArabic: locale.languageCode == 'ar',
              addresses: const [],
            ),
          ),
        ),
        coinHistoryProvider.overrideWith(() => _FakeCoinHistory()),
        platformSettingsProvider.overrideWith((ref) async => settings),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'packages/core/assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        assetLoader: const _CatalogAssetLoader(),
        useOnlyLangCode: true,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const CartScreen(),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('Cart controller concurrency & force sync', () {
    test('stale initial loadCarts does not overwrite clearLocalBaskets', () async {
      final slowInitial = Completer<List<dynamic>>();
      final fakeCartRepo = _FakeCartRepo()
        ..onGetMyCarts = () => slowInitial.future;

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(AuthStatus.authenticated),
          ),
          sharedAuthRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          customerCartRepositoryProvider.overrideWithValue(fakeCartRepo),
        ],
      );
      addTearDown(container.dispose);

      // Keep provider alive & read initial state (starts background load)
      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);

      // User places order or clears a vendor basket while initial load is still in flight
      container.read(cartProvider.notifier).clearLocalBaskets(['v2']);

      // Stale snapshot finally arrives with both v1 and v2
      slowInitial.complete([
        _rawServerCart('v1', 'Item 1'),
        _rawServerCart('v2', 'Item 2'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Because clearLocalBaskets bumped _loadEpoch, stale snapshot is discarded
      expect(container.read(cartProvider).vendorBaskets.containsKey('v2'), isFalse);
    });

    test('loadCarts coalesces unless force=true and discards superseded response', () async {
      final firstLoad = Completer<List<dynamic>>();
      final forcedLoad = Completer<List<dynamic>>();
      var callIndex = 0;

      final fakeCartRepo = _FakeCartRepo()
        ..onGetMyCarts = () {
          callIndex++;
          return callIndex == 1 ? firstLoad.future : forcedLoad.future;
        };

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(AuthStatus.authenticated),
          ),
          sharedAuthRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          customerCartRepositoryProvider.overrideWithValue(fakeCartRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);
      expect(fakeCartRepo.getMyCartsCallCount, 1);

      // Non-forced call reuses in-flight call
      final coalesced = container.read(cartProvider.notifier).loadCarts();
      await Future<void>.delayed(Duration.zero);
      expect(fakeCartRepo.getMyCartsCallCount, 1);

      // Forced call starts a fresh request
      final forced = container.read(cartProvider.notifier).loadCarts(force: true);
      await Future<void>.delayed(Duration.zero);
      expect(fakeCartRepo.getMyCartsCallCount, 2);

      // Older load returns stale v1+v2
      firstLoad.complete([
        _rawServerCart('v1', 'Item 1'),
        _rawServerCart('v2', 'Item 2'),
      ]);
      await coalesced;

      // Forced load returns server truth: only v1 remains
      forcedLoad.complete([_rawServerCart('v1', 'Item 1')]);
      await forced;

      final baskets = container.read(cartProvider).vendorBaskets;
      expect(baskets.keys.toList(), ['v1']);
    });

    test('clearLocal aborts any in-flight getMyCarts snapshot', () async {
      final slowLoad = Completer<List<dynamic>>();
      final fakeCartRepo = _FakeCartRepo()
        ..onGetMyCarts = () => slowLoad.future;

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(AuthStatus.authenticated),
          ),
          sharedAuthRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          customerCartRepositoryProvider.overrideWithValue(fakeCartRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(cartProvider);
      await Future<void>.delayed(Duration.zero);

      container.read(cartProvider.notifier).clearLocal();
      slowLoad.complete([_rawServerCart('v1', 'Item 1')]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(container.read(cartProvider).vendorBaskets, isEmpty);
    });
  });

  group('CheckoutScreen empty cart & multi-vendor recovery', () {
    testWidgets('shows empty cart UI instead of infinite spinner when carts are empty', (tester) async {
      final fakeCartRepo = _FakeCartRepo()..onGetMyCarts = () async => [];
      final fakeOrderRepo = _FakeOrderRepo();

      await _pumpCheckout(
        tester,
        fakeCartRepo: fakeCartRepo,
        fakeOrderRepo: fakeOrderRepo,
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders Arabic RTL empty cart state without overflow', (tester) async {
      final fakeCartRepo = _FakeCartRepo()..onGetMyCarts = () async => [];
      final fakeOrderRepo = _FakeOrderRepo();

      await _pumpCheckout(
        tester,
        fakeCartRepo: fakeCartRepo,
        fakeOrderRepo: fakeOrderRepo,
        locale: const Locale('ar'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('prunes dropped vendor and degrades to single-vendor estimateOrder', (tester) async {
      final fakeCartRepo = _FakeCartRepo()
        ..onGetMyCarts = () async => [_rawServerCart('v1', 'Burger')];
      final fakeOrderRepo = _FakeOrderRepo();

      await _pumpCheckout(
        tester,
        fakeCartRepo: fakeCartRepo,
        fakeOrderRepo: fakeOrderRepo,
        addresses: const [
          {
            'id': 'addr-1',
            'address': 'Nasr City',
            'isDefault': true,
            'location': [31.33, 30.0444],
          },
        ],
      );

      expect(fakeOrderRepo.estimateMultiCalls, 0);
      expect(fakeOrderRepo.estimateSingleCalls, 1);
      expect(fakeOrderRepo.lastSingleVendorId, 'v1');
    });

    testWidgets('recovers from multi-vendor cart.error.is_empty when only one vendor disappeared on server', (tester) async {
      var cartFetchCount = 0;
      final fakeCartRepo = _FakeCartRepo()
        ..onGetMyCarts = () async {
          cartFetchCount++;
          if (cartFetchCount == 1) {
            return [
              _rawServerCart('v1', 'Burger'),
              _rawServerCart('v2', 'Pizza'),
            ];
          }
          // Server reveals v2 cart was already cleared
          return [_rawServerCart('v1', 'Burger')];
        };

      final fakeOrderRepo = _FakeOrderRepo()
        ..onEstimateMulti = (dto) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/orders/multi-vendor/fee-estimate'),
            response: Response(
              requestOptions: RequestOptions(path: '/orders/multi-vendor/fee-estimate'),
              statusCode: 400,
              data: {'message': 'cart.error.is_empty'},
            ),
            type: DioExceptionType.badResponse,
          );
        };

      await _pumpCheckout(
        tester,
        fakeCartRepo: fakeCartRepo,
        fakeOrderRepo: fakeOrderRepo,
        addresses: const [
          {
            'id': 'addr-1',
            'address': 'Nasr City',
            'isDefault': true,
            'location': [31.33, 30.0444],
          },
        ],
      );

      // Multi-vendor failed once with cart.error.is_empty -> synced -> recovered to single-vendor v1!
      expect(fakeOrderRepo.estimateMultiCalls, 1);
      expect(fakeOrderRepo.estimateSingleCalls, 1);
      expect(fakeOrderRepo.lastSingleVendorId, 'v1');
      expect(
        find.text('Removed empty store items from checkout, updating total...'),
        findsOneWidget,
      );
    });
  });

  group('PlatformSettingsData & CartScreen maxMultiVendorVendors guard', () {
    test('parses maxMultiVendorVendors from JSON and safely falls back to 5', () {
      expect(PlatformSettingsData().maxMultiVendorVendors, 5);
      expect(
        PlatformSettingsData.fromJson({'maxMultiVendorVendors': 3})
            .maxMultiVendorVendors,
        3,
      );
      expect(
        PlatformSettingsData.fromJson({'maxMultiVendorVendors': '1'})
            .maxMultiVendorVendors,
        1,
      );
      expect(
        PlatformSettingsData.fromJson({'maxMultiVendorVendors': 0})
            .maxMultiVendorVendors,
        5,
      );
      expect(
        PlatformSettingsData.fromJson({'maxMultiVendorVendors': 'bad'})
            .maxMultiVendorVendors,
        5,
      );
    });

    testWidgets(
      'disables Checkout All and warns when stores exceed maxMultiVendorVendors while keeping single-store Checkout active',
      (tester) async {
        final fakeCartRepo = _FakeCartRepo()
          ..onGetMyCarts = () async => [
                _rawServerCart('v1', 'Burger'),
                _rawServerCart('v2', 'Pizza'),
                _rawServerCart('v3', 'Sushi'),
              ];

        await _pumpCart(
          tester,
          fakeCartRepo: fakeCartRepo,
          fakeOrderRepo: _FakeOrderRepo(),
          settings: PlatformSettingsData(maxMultiVendorVendors: 2),
        );

        expect(
          find.text(
            'Max 2 stores per combined order (you have 3). Remove 1 store or order separately.',
          ),
          findsOneWidget,
        );
        expect(find.text('3/2 stores • 3 items'), findsOneWidget);

        final checkoutAllBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Checkout All'),
        );
        expect(checkoutAllBtn.onPressed, isNull);

        // Single-store Checkout on the first vendor card remains enabled
        final singleCheckoutBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Checkout').first,
        );
        expect(singleCheckoutBtn.onPressed, isNotNull);
      },
    );

    testWidgets(
      'renders Arabic RTL disabled multi-vendor notice cleanly when maxMultiVendorVendors is 1',
      (tester) async {
        final fakeCartRepo = _FakeCartRepo()
          ..onGetMyCarts = () async => [
                _rawServerCart('v1', 'Burger'),
                _rawServerCart('v2', 'Pizza'),
              ];

        await _pumpCart(
          tester,
          fakeCartRepo: fakeCartRepo,
          fakeOrderRepo: _FakeOrderRepo(),
          settings: PlatformSettingsData(maxMultiVendorVendors: 1),
          locale: const Locale('ar'),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.text(
            'الطلب متعدد المتاجر غير متاح حالياً. يمكنك إتمام طلب كل متجر على حدة.',
          ),
          findsOneWidget,
        );

        final checkoutAllBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'إتمام طلب الكل'),
        );
        expect(checkoutAllBtn.onPressed, isNull);
      },
    );
  });
}
