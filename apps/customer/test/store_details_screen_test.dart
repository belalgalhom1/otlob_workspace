import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/home/presentation/pages/restaurant_detail_screen.dart';
import 'package:otlob_customer/features/home/presentation/widgets/store_details_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

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

class _AuthAuthenticatedController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}

class _FakeAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;
}

class _FakeVendorsRepo extends Fake implements CustomerVendorsRepository {
  Map<String, dynamic> Function(String id, String? branchId) onGetVendor;
  _FakeVendorsRepo(this.onGetVendor);

  @override
  Future<dynamic> getVendor(String id, {String? branchId}) async =>
      onGetVendor(id, branchId);
}

class _FakeFavoritesRepo extends Fake implements CustomerFavoritesRepository {
  final List<String> toggledVendorIds = [];

  @override
  Future<dynamic> getFavorites() async => <dynamic>[];

  @override
  Future<dynamic> toggleFavoriteVendor(String vendorId) async {
    toggledVendorIds.add(vendorId);
    return {'isFavorite': true};
  }
}

class _InMemoryCartRepo extends Fake implements CustomerCartRepository {
  final Map<String, List<Map<String, dynamic>>> _baskets = {};
  int _nextItemId = 1;
  final Map<String, Map<String, dynamic>> productLookup;

  _InMemoryCartRepo(this.productLookup);

  @override
  Future<dynamic> getMyCarts() async {
    return _baskets.entries
        .map((e) => {'vendorId': e.key, 'items': e.value})
        .toList();
  }

  @override
  Future<dynamic> addItem(
    String vendorId, {
    String? productId,
    int quantity = 1,
    String? selectedUnit,
    String? variantId,
    List<String>? optionIds,
    String? specialRequest,
    String? offerMessageId,
  }) async {
    final unit = selectedUnit ?? 'package';
    final list = _baskets.putIfAbsent(vendorId, () => []);
    final prod = productLookup[productId ?? ''] ??
        {'id': productId, 'name': 'Item', 'nameAr': 'صنف', 'price': 50};
    Map<String, dynamic>? variant;
    if (variantId != null) {
      final vars = (prod['variants'] as List<dynamic>? ?? []);
      variant = vars
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .where((v) => v['id']?.toString() == variantId)
          .firstOrNull;
    }
    final unitPrice = (variant != null
            ? (variant['price'] ?? variant['basePrice'])
            : (prod['price'] ?? prod['basePrice'])) as num? ??
        0;

    final existingIdx = list.indexWhere(
      (i) =>
          i['productId'] == productId &&
          i['variant']?['id'] == variantId &&
          i['selectedUnit'] == unit,
    );
    if (existingIdx >= 0) {
      final newQty = (list[existingIdx]['quantity'] as int) + quantity;
      list[existingIdx] = {
        ...list[existingIdx],
        'quantity': newQty,
        'totalPrice': unitPrice * newQty,
      };
    } else {
      list.add({
        'id': 'ci-${_nextItemId++}',
        'productId': productId,
        'product': prod,
        'variant': variant,
        'options': <dynamic>[],
        'quantity': quantity,
        'selectedUnit': unit,
        'unitPrice': unitPrice,
        'totalPrice': unitPrice * quantity,
      });
    }
    return {'vendorId': vendorId, 'items': List<Map<String, dynamic>>.from(list)};
  }

  @override
  Future<dynamic> updateItem(
    String vendorId,
    String itemId, {
    required int quantity,
    String? selectedUnit,
    List<String>? optionIds,
    String? specialRequest,
  }) async {
    final list = _baskets[vendorId] ?? [];
    final idx = list.indexWhere((i) => i['id'] == itemId);
    if (idx >= 0) {
      final unitPrice = (list[idx]['unitPrice'] as num?) ?? 0;
      list[idx] = {
        ...list[idx],
        'quantity': quantity,
        'totalPrice': unitPrice * quantity,
      };
    }
    return {'vendorId': vendorId, 'items': List<Map<String, dynamic>>.from(list)};
  }

  @override
  Future<dynamic> removeItem(String vendorId, String itemId) async {
    _baskets[vendorId]?.removeWhere((i) => i['id'] == itemId);
    return {'vendorId': vendorId, 'items': _baskets[vendorId] ?? []};
  }
}

Map<String, dynamic> _sampleStorePayload() {
  return {
    'id': 'vendor-blaban',
    'storeName': 'B.Laban',
    'storeNameAr': 'بلبن',
    'description': 'Authentic Egyptian dairy desserts.',
    'descriptionAr':
        'أشهر حلويات الألبان الطازجة يومياً بقشطوطة وكشري حلو وأرز بلبن أصلي في كل الفروع.',
    'rating': 4.8,
    'ratingCount': 342,
    'status': 'OPEN',
    'deliveryTime': '25-35 دقيقة',
    'deliveryTimeEn': '25-35 mins',
    'vertical': {'slug': 'desserts', 'name': 'Desserts', 'nameAr': 'حلويات'},
    'branches': [
      {
        'id': 'br-nasr',
        'name': 'Nasr City',
        'nameAr': 'مدينة نصر',
        'address': 'شارع عباس العقاد',
        'isOpen': true,
      },
      {
        'id': 'br-maadi',
        'name': 'Maadi',
        'nameAr': 'المعادي',
        'address': 'شارع 9 المعادي',
        'isOpen': true,
      },
    ],
    'categories': [
      {'id': 'cat-qashtouta', 'name': 'Qashtouta', 'nameAr': 'قشطوطة'},
      {'id': 'cat-koshary', 'name': 'Sweet Koshary', 'nameAr': 'كشري حلو'},
      {'id': 'cat-rice', 'name': 'Rice Pudding', 'nameAr': 'أرز بلبن'},
    ],
    'menu': [
      {
        'id': 'p-qashtouta',
        'name': 'Qashtouta Mango',
        'nameAr': 'قشطوطة مانجو',
        'description': 'Soft milk cake topped with mango',
        'descriptionAr': 'كيكة حليب طرية مع مانجو طازج وكريمة',
        'price': 85,
        'basePrice': 85,
        'comparePrice': 100,
        'category': 'cat-qashtouta',
        'hasVariants': true,
        'variants': [
          {
            'id': 'v-reg',
            'name': 'Regular',
            'nameAr': 'حجم عادي',
            'price': 85,
            'basePrice': 85,
          },
          {
            'id': 'v-family',
            'name': 'Family',
            'nameAr': 'حجم عائلي',
            'price': 150,
            'basePrice': 150,
          },
        ],
        'optionGroups': <dynamic>[],
      },
      {
        'id': 'p-koshary',
        'name': 'Sweet Koshary',
        'nameAr': 'كشري',
        'description': 'Creamy dessert with konafa and pistachios',
        'descriptionAr': 'كنافة مع قشطوطة وصوص لوتس وفستق',
        'price': 70,
        'basePrice': 70,
        'category': 'cat-koshary',
        'hasVariants': false,
        'variants': <dynamic>[],
        'optionGroups': <dynamic>[],
      },
      {
        'id': 'p-koshary-super',
        'name': 'Super Koshary',
        'nameAr': 'كشري سوبر',
        'description': 'Double layered sweet koshary',
        'descriptionAr': 'كشري حلو دبل طبقات',
        'price': 95,
        'basePrice': 95,
        'category': 'cat-koshary',
        'hasVariants': false,
        'variants': <dynamic>[],
        'optionGroups': <dynamic>[],
      },
      {
        'id': 'p-rice-oven',
        'name': 'Baked Rice Pudding',
        'nameAr': 'أرز بلبن فرن',
        'description': 'Caramelized oven baked rice pudding',
        'descriptionAr': 'أرز بلبن بالكريمة وش محمر في الفرن',
        'price': 45,
        'basePrice': 45,
        'category': 'cat-rice',
        'hasVariants': false,
        'variants': <dynamic>[],
        'optionGroups': <dynamic>[],
      },
    ],
  };
}

Widget _buildHarness({
  required Map<String, dynamic> payload,
  required _FakeVendorsRepo vendorsRepo,
  required _FakeFavoritesRepo favsRepo,
  required _InMemoryCartRepo cartRepo,
  ThemeMode themeMode = ThemeMode.dark,
  Locale locale = const Locale('ar'),
}) {
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [
      baseUrlProvider.overrideWithValue('https://api.example.com'),
      authControllerProvider.overrideWith(_AuthAuthenticatedController.new),
      data_providers.sharedAuthRepositoryProvider
          .overrideWithValue(_FakeAuthRepo()),
      data_providers.customerVendorsRepositoryProvider
          .overrideWithValue(vendorsRepo),
      data_providers.customerFavoritesRepositoryProvider
          .overrideWithValue(favsRepo),
      data_providers.customerCartRepositoryProvider.overrideWithValue(cartRepo),
    ],
    child: EasyLocalization(
      key: UniqueKey(),
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'unused',
      fallbackLocale: locale,
      startLocale: locale,
      useOnlyLangCode: true,
      assetLoader: const _TestAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: VendorDetailScreen(restaurant: payload),
        ),
      ),
    ),
  );
}

void main() {
  group('StoreDetailsTokens strict Arabic normalization & search', () {
    test('normalizeArabic unifies Alef, Teh Marbuta, Alef Maksura & strips harakat', () {
      expect(StoreDetailsTokens.normalizeArabic('أَرْزٌ بِلَبَنٍ'), 'ارز بلبن');
      expect(StoreDetailsTokens.normalizeArabic('قشطوطة إكسترا'), 'قشطوطه اكسترا');
      expect(StoreDetailsTokens.normalizeArabic('آيس كريم منى'), 'ايس كريم مني');
    });

    test('filterMenuProducts matches strictly on product name (never description) and prefers exact match', () {
      final menu = (_sampleStorePayload()['menu'] as List<dynamic>);

      // "كنافة" appears only in p-koshary's descriptionAr -> must NOT match
      final descOnly = StoreDetailsTokens.filterMenuProducts(
        allMenu: menu,
        activeCategoryId: 'all',
        rawQuery: 'كنافة',
      );
      expect(descOnly, isEmpty);

      // Exact normalized name "كشري" returns ONLY "كشري", not "كشري سوبر"
      final exact = StoreDetailsTokens.filterMenuProducts(
        allMenu: menu,
        activeCategoryId: 'all',
        rawQuery: 'كشري',
      );
      expect(exact.length, 1);
      expect(exact.first['id'], 'p-koshary');

      // Alef normalization: "ارز بلبن" matches "أرز بلبن فرن"
      final normalized = StoreDetailsTokens.filterMenuProducts(
        allMenu: menu,
        activeCategoryId: 'all',
        rawQuery: 'ارز بلبن',
      );
      expect(normalized.length, 1);
      expect(normalized.first['id'], 'p-rice-oven');
    });
  });

  group('VendorDetailScreen Store Details & Menu UI', () {
    testWidgets(
      'Renders viewport-locked Dark & Light themes with zero overflow across phone sizes, category tap filtering, and strict search',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await EasyLocalization.ensureInitialized();

        final payload = _sampleStorePayload();
        final productMap = {
          for (final p in (payload['menu'] as List<dynamic>))
            (p as Map)['id'].toString(): Map<String, dynamic>.from(p),
        };

        for (final size in const [
          Size(360, 800),
          Size(390, 844),
          Size(412, 915),
        ]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          final vendorsRepo =
              _FakeVendorsRepo((_, _) => Map<String, dynamic>.from(payload));
          final favsRepo = _FakeFavoritesRepo();
          final cartRepo = _InMemoryCartRepo(productMap);

          await tester.pumpWidget(
            _buildHarness(
              payload: payload,
              vendorsRepo: vendorsRepo,
              favsRepo: favsRepo,
              cartRepo: cartRepo,
              themeMode: size.width == 390 ? ThemeMode.light : ThemeMode.dark,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('بلبن'), findsOneWidget);
          expect(find.text('4.8'), findsOneWidget);
          expect(find.text('(342)'), findsOneWidget);
          expect(find.text('الكل'), findsOneWidget);
          expect(find.text('القائمة'), findsOneWidget);
          expect(find.byKey(const Key('store_menu_products_list')), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        // Category tap filtering: tap "كشري حلو" first (auto-centering slides "أرز بلبن" into view), then tap "أرز بلبن"
        await tester.ensureVisible(find.text('كشري حلو'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('كشري حلو'));
        await tester.pumpAndSettle();
        expect(find.text('كشري'), findsOneWidget);
        expect(find.text('قشطوطة مانجو'), findsNothing);

        await tester.ensureVisible(find.text('أرز بلبن'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('أرز بلبن'));
        await tester.pumpAndSettle();
        expect(find.text('أرز بلبن فرن'), findsOneWidget);
        expect(find.text('قشطوطة مانجو'), findsNothing);

        // Return to "الكل" and verify strict name-only search + clear
        await tester.ensureVisible(find.text('الكل'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('الكل'));
        await tester.pumpAndSettle();
        expect(find.text('قشطوطة مانجو'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('store_menu_search_input')),
          'كنافة',
        );
        await tester.pumpAndSettle();
        expect(find.text('لا توجد أصناف مطابقة'), findsOneWidget);

        await tester.tap(find.byKey(const Key('store_menu_search_clear')));
        await tester.pumpAndSettle();
        expect(find.text('قشطوطة مانجو'), findsOneWidget);
        expect(tester.takeException(), isNull);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      'Quick add & variant sheet trigger fly-to-cart, commit to real cart, open cart modal with steppers, branch modal & favorite toggle',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await EasyLocalization.ensureInitialized();

        final payload = _sampleStorePayload();
        final productMap = {
          for (final p in (payload['menu'] as List<dynamic>))
            (p as Map)['id'].toString(): Map<String, dynamic>.from(p),
        };
        final vendorsRepo =
            _FakeVendorsRepo((_, _) => Map<String, dynamic>.from(payload));
        final favsRepo = _FakeFavoritesRepo();
        final cartRepo = _InMemoryCartRepo(productMap);

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildHarness(
            payload: payload,
            vendorsRepo: vendorsRepo,
            favsRepo: favsRepo,
            cartRepo: cartRepo,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Favorite toggle calls real favorites repo
        await tester.tap(find.byKey(const Key('store_favorite_button')));
        await tester.pump(const Duration(milliseconds: 100));
        expect(favsRepo.toggledVendorIds, contains('vendor-blaban'));

        // 2. Branch selector modal switches branch to Maadi
        await tester.tap(find.text('تغيير'));
        await tester.pumpAndSettle();
        expect(find.text('اختر الفرع'), findsOneWidget);
        await tester.tap(find.text('الفرع: المعادي'));
        await tester.pumpAndSettle();
        expect(find.text('الفرع: المعادي'), findsOneWidget);

        // 3. Quick add on single-price product ("كشري" -> 70 EGP)
        final addButtons = find.text('+ أضف');
        // Second product card is p-koshary (no variants)
        await tester.tap(addButtons.at(1));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('store_sticky_cart_bar')), findsOneWidget);
        expect(find.text('عرض السلة (1)'), findsOneWidget);
        expect(find.textContaining('70 '), findsWidgets);

        // 4. Tap variant product card ("قشطوطة مانجو"), select "حجم عائلي" (150 EGP), add via fly-to-cart
        await tester.tap(find.text('قشطوطة مانجو'));
        await tester.pumpAndSettle();
        expect(find.text('حجم عائلي'), findsOneWidget);
        await tester.tap(find.text('حجم عائلي'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('إضافة للسلة'));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        // Cart bar now holds 2 items totaling 70 + 150 = 220
        expect(find.text('عرض السلة (2)'), findsOneWidget);
        expect(find.textContaining('220 '), findsWidgets);

        // 5. Open Cart Modal and increment first item via '+' stepper
        await tester.tap(find.byKey(const Key('store_sticky_cart_bar')));
        await tester.pumpAndSettle();
        expect(find.text('سلة الطلبات'), findsOneWidget);
        await tester.tap(find.text('+').first);
        await tester.pumpAndSettle();

        // Total updates from 220 -> 290 (70*2 + 150)
        expect(find.textContaining('290 '), findsWidgets);

        // Drain toast timer cleanly
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Shows error state with Retry and recovers when backend succeeds',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await EasyLocalization.ensureInitialized();

        final payload = _sampleStorePayload();
        var shouldFail = true;
        final vendorsRepo = _FakeVendorsRepo((_, _) {
          if (shouldFail) throw Exception('Network down');
          return Map<String, dynamic>.from(payload);
        });
        final favsRepo = _FakeFavoritesRepo();
        final cartRepo = _InMemoryCartRepo({});

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildHarness(
            payload: payload,
            vendorsRepo: vendorsRepo,
            favsRepo: favsRepo,
            cartRepo: cartRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('إعادة المحاولة'), findsOneWidget);

        shouldFail = false;
        await tester.tap(find.text('إعادة المحاولة'));
        await tester.pumpAndSettle();

        expect(find.text('بلبن'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
