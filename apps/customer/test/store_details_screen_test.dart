import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/widgets/floating_cart_overlay.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/home/presentation/pages/restaurant_detail_screen.dart';
import 'package:otlob_customer/features/home/presentation/widgets/product_bottom_sheet.dart';
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

class _AuthUserController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}

class _FakeAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;
}

class _FakeFavoritesRepo extends Fake implements CustomerFavoritesRepository {
  final Set<String> favIds = {};

  @override
  Future<dynamic> getFavorites() async =>
      favIds.map((id) => {'vendorId': id}).toList();

  @override
  Future<dynamic> toggleFavoriteVendor(String vendorId) async {
    if (favIds.contains(vendorId)) {
      favIds.remove(vendorId);
    } else {
      favIds.add(vendorId);
    }
    return {'favorited': favIds.contains(vendorId)};
  }
}

class _FakeCartRepo extends Fake implements CustomerCartRepository {
  final List<Map<String, dynamic>> addedCalls = [];
  final List<Map<String, dynamic>> serverItems = [];

  @override
  Future<dynamic> getMyCarts() async => [];

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
    addedCalls.add({
      'vendorId': vendorId,
      'productId': productId,
      'variantId': variantId,
      'selectedUnit': selectedUnit,
    });
    final price = variantId == 'var-lg' ? 140 : 95;
    serverItems.add({
      'id': 'ci-${serverItems.length + 1}',
      'productId': productId,
      'quantity': quantity,
      'selectedUnit': selectedUnit ?? 'package',
      'unitPrice': price,
      'totalPrice': price * quantity,
      'product': {
        'id': productId,
        'name': 'Item $productId',
        'nameAr': 'منتج $productId',
        'basePrice': price,
        'isActive': true,
        'tracksStock': false,
      },
      if (variantId != null)
        'variant': {
          'id': variantId,
          'name': 'Large',
          'nameAr': 'كبير',
          'basePrice': price,
          'isActive': true,
          'tracksStock': false,
        },
      'options': const [],
    });
    return {
      'id': 'cart-1',
      'vendorId': vendorId,
      'vendor': {
        'id': vendorId,
        'storeName': 'Karam El Sham',
        'storeNameAr': 'كرم الشام',
        'status': 'OPEN',
      },
      'items': List<Map<String, dynamic>>.from(serverItems),
    };
  }
}

class _FakeVendorsRepo extends Fake implements CustomerVendorsRepository {
  Map<String, dynamic> payload;
  bool shouldThrow;
  String? lastBranchId;

  _FakeVendorsRepo(this.payload, {this.shouldThrow = false});

  @override
  Future<dynamic> getVendor(String id, {String? branchId}) async {
    lastBranchId = branchId;
    if (shouldThrow) {
      throw Exception('Backend unavailable');
    }
    return Map<String, dynamic>.from(payload);
  }
}

Map<String, dynamic> _buildSampleVendor() => {
  'id': 'vendor-karam-1',
  'storeName': 'Karam El Sham',
  'storeNameAr': 'كرم الشام',
  'description': 'Authentic Syrian shawarma & charcoal grills.',
  'descriptionAr': 'شاورما سوري أصلية ومشويات على الفحم.',
  'coverImage': 'https://example.com/banner.jpg',
  'logo': 'https://example.com/logo.jpg',
  'status': 'OPEN',
  'rating': 4.7,
  'ratingCount': 312,
  'distanceKm': 2.3,
  'vertical': {
    'id': 'vert-1',
    'name': 'Restaurants',
    'nameAr': 'مطاعم',
    'slug': 'restaurants',
  },
  'branches': [
    {
      'id': 'br-nasr',
      'name': 'Nasr City',
      'nameAr': 'فرع مدينة نصر',
      'address': 'Abbas El Akkad St',
      'isOpen': true,
    },
    {
      'id': 'br-maadi',
      'name': 'Maadi',
      'nameAr': 'فرع المعادي',
      'address': 'Road 9',
      'isOpen': true,
    },
  ],
  'categories': [
    {
      'id': 'cat-shawarma',
      'name': 'Shawarma',
      'nameAr': 'شاورما',
      'iconUrl': 'https://example.com/cat-shawarma.jpg',
    },
    {
      'id': 'cat-meals',
      'name': 'Meals',
      'nameAr': 'وجبات عربي',
      'iconUrl': null, // Tests fallback to first product image in category
    },
    {
      'id': 'cat-sides',
      'name': 'Sides',
      'nameAr': 'مقبلات',
      'iconUrl': 'https://example.com/cat-sides.jpg',
    },
    {
      'id': 'cat-grills',
      'name': 'Grills',
      'nameAr': 'مشويات',
      'iconUrl': 'https://example.com/cat-grills.jpg',
    },
    {
      'id': 'cat-drinks',
      'name': 'Drinks',
      'nameAr': 'مشروبات',
      'iconUrl': 'https://example.com/cat-drinks.jpg',
    },
    {
      'id': 'cat-desserts',
      'name': 'Desserts',
      'nameAr': 'حلويات',
      'iconUrl': 'https://example.com/cat-desserts.jpg',
    },
  ],
  'menu': [
    {
      'id': 'p-1',
      'name': 'Chicken Shawarma',
      'nameAr': 'شاورما دجاج',
      'description': 'Served with garlic dip and fries',
      'descriptionAr': 'تقدم مع الثومية والبطاطس',
      'price': 95,
      'basePrice': 95,
      'comparePrice': 110,
      'image': 'https://example.com/p1.jpg',
      'category': 'cat-shawarma',
      'hasVariants': false,
      'variants': <dynamic>[],
      'optionGroups': <dynamic>[],
    },
    {
      'id': 'p-2',
      'name': 'Chicken Shawarma Extra',
      'nameAr': 'شاورما دجاج إكسترا',
      'description': 'Double meat sandwich',
      'descriptionAr': 'ساندوتش دبل دجاج',
      'price': 125,
      'basePrice': 125,
      'image': 'https://example.com/p2.jpg',
      'category': 'cat-shawarma',
      'hasVariants': false,
      'variants': <dynamic>[],
      'optionGroups': <dynamic>[],
    },
    {
      'id': 'p-3',
      'name': 'Arabic Meal',
      'nameAr': 'وجبة عربي شاورما',
      'description': 'Includes Chicken Shawarma slices and garlic sauce',
      'descriptionAr': 'تحتوي على قطع دجاج مقرمشة وثومية',
      'price': 115,
      'basePrice': 115,
      'image': 'https://example.com/p3-meal.jpg',
      'category': 'cat-meals',
      'hasVariants': true,
      'variants': [
        {
          'id': 'var-reg',
          'name': 'Regular',
          'nameAr': 'عادي',
          'price': 115,
          'basePrice': 115,
          'imageUrl': 'https://example.com/var-reg.jpg',
        },
        {
          'id': 'var-lg',
          'name': 'Large',
          'nameAr': 'كبير',
          'price': 140,
          'basePrice': 140,
          'imageUrl': 'https://example.com/var-lg.jpg',
        },
      ],
      'optionGroups': <dynamic>[],
    },
    {
      'id': 'p-4',
      'name': 'Fries Box',
      'nameAr': 'باكت بطاطس',
      'description': 'Mentioning شاورما دجاج in description ONLY',
      'descriptionAr': 'تقدم بجانب شاورما دجاج ساخنة',
      'price': 45,
      'basePrice': 45,
      'image': 'https://example.com/p4.jpg',
      'category': 'cat-sides',
      'hasVariants': false,
      'variants': <dynamic>[],
      'optionGroups': <dynamic>[],
    },
  ],
};

Future<void> _pumpStoreDetails(
  WidgetTester tester, {
  required _FakeVendorsRepo vendorsRepo,
  required _FakeCartRepo cartRepo,
  required _FakeFavoritesRepo favRepo,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.dark,
  Size viewport = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        baseUrlProvider.overrideWithValue('https://example.com'),
        authControllerProvider.overrideWith(_AuthUserController.new),
        data_providers.sharedAuthRepositoryProvider.overrideWithValue(
          _FakeAuthRepo(),
        ),
        data_providers.customerVendorsRepositoryProvider.overrideWithValue(
          vendorsRepo,
        ),
        data_providers.customerCartRepositoryProvider.overrideWithValue(
          cartRepo,
        ),
        data_providers.customerFavoritesRepositoryProvider.overrideWithValue(
          favRepo,
        ),
      ],
      child: EasyLocalization(
        key: UniqueKey(),
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'packages/core/assets/translations',
        fallbackLocale: locale,
        startLocale: locale,
        useOnlyLangCode: true,
        assetLoader: const _TestAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: VendorDetailScreen(
              restaurant: {
                'id': 'vendor-karam-1',
                'storeName': 'Karam El Sham',
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Viewport-locked layout, 106px banner, Dark & Light tokens, visual 48x48 category tiles, and existing FloatingCartOverlay untouched',
    (tester) async {
      final vendorsRepo = _FakeVendorsRepo(_buildSampleVendor());
      final cartRepo = _FakeCartRepo();
      final favRepo = _FakeFavoritesRepo();

      await _pumpStoreDetails(
        tester,
        vendorsRepo: vendorsRepo,
        cartRepo: cartRepo,
        favRepo: favRepo,
        themeMode: ThemeMode.dark,
      );

      // 1. Banner is fixed 106px, no CustomScrollView outer scroll
      expect(find.byType(CustomScrollView), findsNothing);
      final bannerSize = tester.getSize(
        find.byKey(const Key('store_top_banner')),
      );
      expect(bannerSize.height, 106.0);

      // 2. Dark theme scaffold background matches #0F0E0C
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, const Color(0xFF0F0E0C));

      // 3. Existing FloatingCartOverlay is present in widget tree (untouched design)
      expect(find.byType(FloatingCartOverlay), findsOneWidget);

      // 4. Visual category tiles show All (4) + real categories with item counts,
      // and NO category headers are rendered inside the vertical menu list
      expect(find.byKey(const Key('store_category_tile_all')), findsOneWidget);
      expect(
        find.byKey(const Key('store_category_tile_cat-shawarma')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('store_category_tile_cat-meals')),
        findsOneWidget,
      );
      expect(
        find.text('شاورما'),
        findsOneWidget,
      ); // Only in category bar, not in menu list

      // Tapping a category auto-centers it horizontally & filters items
      final catScrollFinder = find.byKey(
        const Key('store_visual_category_scroll'),
      );
      final scrollBefore = tester
          .widget<SingleChildScrollView>(catScrollFinder)
          .controller!
          .offset;
      await tester.tap(find.byKey(const Key('store_category_tile_cat-sides')));
      await tester.pumpAndSettle();
      final scrollAfter = tester
          .widget<SingleChildScrollView>(catScrollFinder)
          .controller!
          .offset;
      expect(scrollAfter, greaterThan(scrollBefore));
      expect(find.text('باكت بطاطس'), findsOneWidget);
      expect(find.text('شاورما دجاج'), findsNothing);

      // Scroll back to All tile and switch back to All
      await tester.ensureVisible(
        find.byKey(const Key('store_category_tile_all')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('store_category_tile_all')));
      await tester.pumpAndSettle();
      expect(find.text('شاورما دجاج'), findsOneWidget);

      // 5. Verify Light Mode #F7F6F2 background token
      await _pumpStoreDetails(
        tester,
        vendorsRepo: vendorsRepo,
        cartRepo: cartRepo,
        favRepo: favRepo,
        themeMode: ThemeMode.light,
      );
      final lightScaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(lightScaffold.backgroundColor, const Color(0xFFF7F6F2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Strict product-name search ignores descriptions, normalizes Arabic characters, and enforces exact-match priority',
    (tester) async {
      final vendorsRepo = _FakeVendorsRepo(_buildSampleVendor());
      final cartRepo = _FakeCartRepo();
      final favRepo = _FakeFavoritesRepo();

      await _pumpStoreDetails(
        tester,
        vendorsRepo: vendorsRepo,
        cartRepo: cartRepo,
        favRepo: favRepo,
      );

      final searchInput = find.byKey(const Key('store_menu_search_input'));

      // Partial query "شاورما" matches product names (p-1, p-2, p-3),
      // and strictly EXCLUDES p-4 ("باكت بطاطس") even though its description contains "شاورما دجاج"!
      await tester.enterText(searchInput, 'شاورما');
      await tester.pump();
      expect(find.byKey(const Key('store_product_card_p-1')), findsOneWidget);
      expect(find.byKey(const Key('store_product_card_p-2')), findsOneWidget);
      expect(find.byKey(const Key('store_product_card_p-3')), findsOneWidget);
      expect(find.byKey(const Key('store_product_card_p-4')), findsNothing);

      // Exact-match priority: "شاورما دجاج" matches p-1 ("شاورما دجاج") EXACTLY,
      // so p-2 ("شاورما دجاج إكسترا") is excluded!
      await tester.enterText(searchInput, 'شاورما دجاج');
      await tester.pump();
      expect(find.byKey(const Key('store_product_card_p-1')), findsOneWidget);
      expect(find.byKey(const Key('store_product_card_p-2')), findsNothing);
      expect(find.byKey(const Key('store_product_card_p-3')), findsNothing);

      // Arabic normalization: "وجبه عربى شاورما" (ه instead of ة, ى instead of ي)
      // matches p-3 ("وجبة عربي شاورما")
      await tester.enterText(searchInput, 'وجبه عربى شاورما');
      await tester.pump();
      expect(find.byKey(const Key('store_product_card_p-3')), findsOneWidget);
      expect(find.byKey(const Key('store_product_card_p-1')), findsNothing);

      // Clear button resets query
      await tester.tap(find.byKey(const Key('store_menu_search_clear')));
      await tester.pump();
      expect(find.byKey(const Key('store_product_card_p-4')), findsOneWidget);
    },
  );

  testWidgets(
    'Fly-to-Cart launches 600ms parabolic overlay from both quick-add (+ أضف) and variant bottom sheet (إضافة للسلة) and populates untouched FloatingCartOverlay',
    (tester) async {
      final vendorsRepo = _FakeVendorsRepo(_buildSampleVendor());
      final cartRepo = _FakeCartRepo();
      final favRepo = _FakeFavoritesRepo();

      await _pumpStoreDetails(
        tester,
        vendorsRepo: vendorsRepo,
        cartRepo: cartRepo,
        favRepo: favRepo,
      );

      // Entry Point 1: Quick Add (+ أضف) on simple product p-1
      await tester.tap(find.byKey(const Key('store_quick_add_p-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Floating 48x48 thumbnail overlay is in flight mid-arc!
      expect(
        find.byKey(const Key('fly_to_cart_floating_thumbnail')),
        findsOneWidget,
      );

      // Complete 600ms flight + 320ms spring pop on existing FloatingCartOverlay
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fly_to_cart_floating_thumbnail')),
        findsNothing,
      );
      expect(cartRepo.addedCalls.length, 1);
      expect(cartRepo.addedCalls.first['productId'], 'p-1');
      // Existing FloatingCartOverlay now renders the real cart count & price!
      expect(find.textContaining('95.00'), findsOneWidget);

      // Entry Point 2: Variant Bottom Sheet on p-3 (captures 160px preview BEFORE closing!)
      await tester.tap(find.byKey(const Key('store_quick_add_p-3')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductBottomSheet), findsOneWidget);

      // Select Large variant (140 EGP) -> updates 160px preview to var-lg.jpg & price to 140
      await tester.tap(find.text('كبير'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const ValueKey('https://example.com/var-lg.jpg')),
        findsOneWidget,
      );

      // Tap إضافة للسلة -> sheet closes immediately & parabolic fly launches from non-zero preview rect
      await tester.tap(
        find.byKey(const Key('product_sheet_add_to_cart_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(
        find.byKey(const Key('fly_to_cart_floating_thumbnail')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 460));
      await tester.pumpAndSettle();

      expect(cartRepo.addedCalls.length, 2);
      expect(cartRepo.addedCalls.last['productId'], 'p-3');
      expect(cartRepo.addedCalls.last['variantId'], 'var-lg');
      // Existing FloatingCartOverlay updated to 2 items (95 + 140 = 235.00 EGP)
      expect(find.textContaining('235.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Favorites toggle, branch switching, and API error retry wire to real repositories',
    (tester) async {
      final vendorsRepo = _FakeVendorsRepo(
        _buildSampleVendor(),
        shouldThrow: true,
      );
      final cartRepo = _FakeCartRepo();
      final favRepo = _FakeFavoritesRepo();

      await _pumpStoreDetails(
        tester,
        vendorsRepo: vendorsRepo,
        cartRepo: cartRepo,
        favRepo: favRepo,
      );

      // Error state with Retry
      expect(find.byKey(const Key('store_error_retry_button')), findsOneWidget);
      vendorsRepo.shouldThrow = false;
      await tester.tap(find.byKey(const Key('store_error_retry_button')));
      await tester.pumpAndSettle();

      expect(find.text('كرم الشام'), findsOneWidget);

      // Favorite toggle
      expect(favRepo.favIds.contains('vendor-karam-1'), isFalse);
      await tester.tap(find.byKey(const Key('store_favorite_button')));
      await tester.pumpAndSettle();
      expect(favRepo.favIds.contains('vendor-karam-1'), isTrue);

      // Branch selector switches active branch & refetches vendor menu for branchId
      expect(find.textContaining('فرع مدينة نصر'), findsOneWidget);
      await tester.tap(find.byKey(const Key('store_change_branch_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('فرع المعادي'));
      await tester.pumpAndSettle();

      expect(vendorsRepo.lastBranchId, 'br-maadi');
      expect(find.textContaining('فرع المعادي'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'StoreDetailsTokens.normalizeProductName handles Arabic normalization',
    () {
      expect(
        StoreDetailsTokens.normalizeProductName('إِسْكَنْدَرَانِيّ مَشْوِيَّة'),
        StoreDetailsTokens.normalizeProductName('اسكندرانى مشويه'),
      );
      expect(
        StoreDetailsTokens.normalizeProductName('آيس كريم فانيليا'),
        StoreDetailsTokens.normalizeProductName('أيس كريم فانيليا'),
      );
    },
  );
}
