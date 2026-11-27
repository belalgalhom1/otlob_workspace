import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/widgets/floating_cart_overlay.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/home/presentation/pages/restaurant_detail_screen.dart';
import 'package:otlob_customer/features/home/presentation/providers/favorites_provider.dart';
import 'package:otlob_customer/features/home/presentation/widgets/store_detail_tokens.dart';
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

class _AuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}

class _FakeVendorsRepo extends Fake implements CustomerVendorsRepository {
  final Map<String, dynamic> vendorPayload;
  _FakeVendorsRepo(this.vendorPayload);

  @override
  Future<dynamic> getVendor(String id, {String? branchId}) async =>
      Map<String, dynamic>.from(vendorPayload);
}

class _FakeFavorites extends Favorites {
  @override
  Set<String> build() => {};

  @override
  Future<void> toggleFavorite(String vendorId) async {
    if (state.contains(vendorId)) {
      state = {...state}..remove(vendorId);
    } else {
      state = {...state, vendorId};
    }
  }
}

class _RecordingCart extends Cart {
  final List<Map<String, dynamic>> addedItems = [];

  @override
  CartState build() => const CartState(vendorBaskets: {});

  @override
  Future<void> addItem(
    Map<String, dynamic> product, {
    String unit = 'package',
    Map<String, dynamic>? variant,
    List<Map<String, dynamic>> options = const [],
  }) async {
    addedItems.add({
      'product': product,
      'unit': unit,
      'variant': variant,
      'options': options,
    });
    final vendorId = product['vendorId']?.toString() ?? 'v-1';
    final price = double.tryParse(
          (variant?['price'] ?? product['price'] ?? '50').toString(),
        ) ??
        50.0;
    final item = CartItem(
      product: CartProductRef(
        id: product['id']?.toString() ?? 'p-1',
        name: product['name']?.toString() ?? '',
        price: price,
        vendorId: vendorId,
        isActive: true,
        tracksStock: false,
      ),
      quantity: 1,
      selectedUnit: unit,
      selectedVariant: variant != null
          ? CartVariantRef(
              id: variant['id']?.toString() ?? '',
              name: variant['name']?.toString() ?? '',
              basePrice: price,
              isActive: true,
              tracksStock: false,
            )
          : null,
    );
    final existing = List<CartItem>.from(state.vendorBaskets[vendorId] ?? []);
    existing.add(item);
    state = CartState(
      vendorBaskets: {...state.vendorBaskets, vendorId: existing},
    );
  }
}

Map<String, dynamic> _sampleStorePayload() => {
      'id': 'v-blaban-1',
      'storeName': 'B.Laban',
      'storeNameAr': 'بـ لبن',
      'description': 'Fresh Egyptian dairy desserts daily.',
      'descriptionAr':
          'أفضل حلويات الألبان المصرية الطازجة يومياً بقشطة طبيعية ومكونات عالية الجودة لجميع أفراد الأسرة.',
      'rating': 4.8,
      'ratingCount': 124,
      'status': 'OPEN',
      'coverImage': '',
      'logo': '',
      'vertical': {'name': 'Desserts', 'nameAr': 'حلويات', 'slug': 'desserts'},
      'branches': [
        {
          'id': 'br-1',
          'name': 'Nasr City',
          'nameAr': 'فرع مدينة نصر',
          'address': 'Abbas El Akkad St',
          'isOpen': true,
        },
        {
          'id': 'br-2',
          'name': 'Maadi',
          'nameAr': 'فرع المعادي',
          'address': 'Road 9',
          'isOpen': true,
        },
      ],
      'categories': [
        {'id': 'cat-1', 'name': 'Qashtouta', 'nameAr': 'قشطوطة', 'iconUrl': ''},
        {'id': 'cat-2', 'name': 'Rice Pudding', 'nameAr': 'أرز بلبن', 'iconUrl': ''},
      ],
      'menu': [
        {
          'id': 'p-1',
          'category': 'cat-1',
          'categoryId': 'cat-1',
          'name': 'Qashtouta',
          'nameAr': 'قشطوطة',
          'description': 'Milk cake with fresh cream and mango keyword',
          'descriptionAr': 'كيك حليب مع قشطة طازجة وكلمة مانجو في الوصف',
          'price': 65,
          'basePrice': 65,
          'comparePrice': 80,
          'tracksStock': false,
          'imageUrl': '',
          'variants': <dynamic>[],
          'optionGroups': <dynamic>[],
        },
        {
          'id': 'p-2',
          'category': 'cat-1',
          'categoryId': 'cat-1',
          'name': 'Qashtouta Lotus',
          'nameAr': 'قشطوطة لوتس',
          'description': 'Qashtouta topped with Lotus sauce',
          'descriptionAr': 'قشطوطة مغطاة بصوص اللوتس',
          'price': 75,
          'basePrice': 75,
          'hasVariants': true,
          'tracksStock': false,
          'imageUrl': '',
          'variants': [
            {
              'id': 'var-s',
              'name': 'Regular',
              'nameAr': 'وسط',
              'price': 75,
              'basePrice': 75,
              'imageUrl': '',
            },
            {
              'id': 'var-l',
              'name': 'Large',
              'nameAr': 'كبير',
              'price': 110,
              'basePrice': 110,
              'imageUrl': '',
            },
          ],
          'optionGroups': <dynamic>[],
        },
        {
          'id': 'p-3',
          'category': 'cat-2',
          'categoryId': 'cat-2',
          'name': 'Rice Pudding',
          'nameAr': 'أرز بلبن',
          'description': 'Classic creamy rice pudding',
          'descriptionAr': 'أرز بلبن كريمي أصلي',
          'price': 40,
          'basePrice': 40,
          'tracksStock': false,
          'imageUrl': '',
          'variants': <dynamic>[],
          'optionGroups': <dynamic>[],
        },
      ],
    };

Future<_RecordingCart> _pumpStoreDetail(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.dark,
  Locale locale = const Locale('ar'),
  Size viewport = const Size(390, 844),
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final cart = _RecordingCart();
  final payload = _sampleStorePayload();

  await tester.pumpWidget(
    EasyLocalization(
      key: UniqueKey(),
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'unused',
      fallbackLocale: const Locale('ar'),
      startLocale: locale,
      useOnlyLangCode: true,
      assetLoader: const _TestAssetLoader(),
      child: ProviderScope(
        overrides: [
          baseUrlProvider.overrideWithValue('https://api.otlob-egy.online'),
          authControllerProvider.overrideWith(_AuthController.new),
          data_providers.customerVendorsRepositoryProvider
              .overrideWithValue(_FakeVendorsRepo(payload)),
          favoritesProvider.overrideWith(_FakeFavorites.new),
          cartProvider.overrideWith(() => cart),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: viewport,
                padding: const EdgeInsets.only(top: 44, bottom: 24),
              ),
              child: VendorDetailScreen(restaurant: payload),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
  return cart;
}

void main() {
  test('normalizeMenuSearchText normalizes Arabic variants and strips diacritics', () {
    expect(normalizeMenuSearchText('أرز بلبن'), 'ارز بلبن');
    expect(normalizeMenuSearchText('قَشْطُوطَة'), 'قشطوطه');
    expect(normalizeMenuSearchText('مُهلّبيّة كبرى'), 'مهلبيه كبري');
  });

  testWidgets(
    'Store Details uses viewport-locked zero outer scroll, scaled 168px banner, dark/light tokens, category icon fallback, and visual category filtering',
    (tester) async {
      await _pumpStoreDetail(tester, themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);

      // Dark theme #0F0E0C background
      final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(darkScaffold.backgroundColor, const Color(0xFF0F0E0C));

      // Scaled fixed 168px full-bleed cover banner (moves content lower so cover is more visible)
      final bannerSize = tester.getSize(
        find.byKey(const ValueKey('store_detail_banner')),
      );
      expect(bannerSize.height, 168.0);

      // Only the menu product list scrolls vertically (zero outer scroll)
      final verticalScrollables = tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .where((s) => s.axis == Axis.vertical)
          .toList();
      expect(verticalScrollables.length, 1);

      // Categories without iconUrl render clean category fallback icons (never product images)
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('store_category_tile_cat-1')),
          matching: find.byIcon(Icons.category_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('store_category_tile_all')),
          matching: find.byIcon(Icons.grid_view_rounded),
        ),
        findsOneWidget,
      );

      // All 3 products rendered initially under 'الكل'
      expect(find.byKey(const ValueKey('store_product_card_p-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_product_card_p-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_product_card_p-3')), findsOneWidget);

      // Tap category 'أرز بلبن' (cat-2) -> filters strictly to p-3
      await tester.tap(find.byKey(const ValueKey('store_category_tile_cat-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('store_product_card_p-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_product_card_p-1')), findsNothing);
      expect(find.byKey(const ValueKey('store_product_card_p-2')), findsNothing);

      // Light mode parity (#F7F6F2)
      await _pumpStoreDetail(tester, themeMode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(lightScaffold.backgroundColor, const Color(0xFFF7F6F2));
    },
  );

  testWidgets(
    'Strict product-name-only search ignores descriptions, normalizes Arabic, and prioritizes exact matches',
    (tester) async {
      await _pumpStoreDetail(tester);

      final searchField = find.byKey(const ValueKey('store_menu_search_field'));

      // Description-only keyword ('مانجو') must NOT match p-1
      await tester.enterText(searchField, 'مانجو');
      await tester.pump();
      expect(find.byKey(const ValueKey('store_product_card_p-1')), findsNothing);
      expect(find.byKey(const ValueKey('store_product_card_p-2')), findsNothing);
      expect(find.byKey(const ValueKey('store_product_card_p-3')), findsNothing);

      // Arabic normalization: 'ارز' matches 'أرز بلبن' (p-3)
      await tester.enterText(searchField, 'ارز');
      await tester.pump();
      expect(find.byKey(const ValueKey('store_product_card_p-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_product_card_p-1')), findsNothing);

      // Exact-match priority: 'قشطوطه' (normalized == 'قشطوطة') shows ONLY p-1, not p-2 ('قشطوطة لوتس')
      await tester.enterText(searchField, 'قشطوطه');
      await tester.pump();
      expect(find.byKey(const ValueKey('store_product_card_p-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_product_card_p-2')), findsNothing);

      // Clear button restores all items
      await tester.tap(find.byKey(const ValueKey('store_menu_search_clear')));
      await tester.pump();
      expect(find.byKey(const ValueKey('store_product_card_p-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_product_card_p-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('store_product_card_p-3')), findsOneWidget);
    },
  );

  testWidgets(
    'Fly-to-Cart animation launches from quick-add and bottom sheet and commits to existing untouched FloatingCartOverlay',
    (tester) async {
      final cart = await _pumpStoreDetail(tester);
      expect(find.byType(FloatingCartOverlay), findsOneWidget);

      // 1. Entry Point 1: Quick add on simple product p-1
      await tester.tap(find.byKey(const ValueKey('store_quick_add_p-1')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        find.byKey(const ValueKey('fly_to_cart_overlay_item')),
        findsOneWidget,
      );
      // Let 600ms flight + 320ms spring pop finish
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey('fly_to_cart_overlay_item')),
        findsNothing,
      );
      expect(cart.addedItems.length, 1);
      expect(cart.addedItems.first['product']['id'], 'p-1');

      // 2. Entry Point 2: Variant product p-2 opens bottom sheet -> select Large -> Add to Cart flies before closing
      await tester.tap(find.byKey(const ValueKey('store_quick_add_p-2')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('product_bottom_sheet_container')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('variant_row_var-l')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('product_sheet_add_to_cart_btn')),
      );
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        find.byKey(const ValueKey('fly_to_cart_overlay_item')),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey('fly_to_cart_overlay_item')),
        findsNothing,
      );
      expect(cart.addedItems.length, 2);
      expect(cart.addedItems.last['variant']['id'], 'var-l');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tapping outside ProductBottomSheet backdrop closes the sheet automatically',
    (tester) async {
      await _pumpStoreDetail(tester);

      // Open product bottom sheet for variant product p-2
      await tester.tap(find.byKey(const ValueKey('store_quick_add_p-2')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('product_bottom_sheet_container')),
        findsOneWidget,
      );

      // Tap outside the sheet (near top of viewport on the backdrop)
      await tester.tapAt(const Offset(195, 80));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('product_bottom_sheet_container')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Store detail search disables theme fill and descriptions use crisp white in Dark Mode and dark ink in Light Mode',
    (tester) async {
      await _pumpStoreDetail(
        tester,
        themeMode: ThemeMode.dark,
        locale: const Locale('en'),
      );

      final searchTextField = tester.widget<TextField>(
        find.byKey(const ValueKey('store_menu_search_field')),
      );
      expect(searchTextField.decoration?.filled, isFalse);
      expect(searchTextField.decoration?.fillColor, Colors.transparent);

      final darkVendorDesc = tester.widget<Text>(
        find.text('Fresh Egyptian dairy desserts daily.'),
      );
      expect(darkVendorDesc.style?.color, const Color(0xFFFFFFFF));

      final darkProductDesc = tester.widget<Text>(
        find.text('Classic creamy rice pudding'),
      );
      expect(darkProductDesc.style?.color, const Color(0xFFFFFFFF));

      await _pumpStoreDetail(
        tester,
        themeMode: ThemeMode.light,
        locale: const Locale('en'),
      );

      final lightVendorDesc = tester.widget<Text>(
        find.text('Fresh Egyptian dairy desserts daily.'),
      );
      expect(lightVendorDesc.style?.color, const Color(0xFF11100E));

      final lightProductDesc = tester.widget<Text>(
        find.text('Classic creamy rice pudding'),
      );
      expect(lightProductDesc.style?.color, const Color(0xFF11100E));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Menu renders a 3-column product grid on mobile with consistent sizing, wraps next 3 onto row 2, handles long names, and works in EN LTR and AR RTL',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      final basePayload = _sampleStorePayload();
      final sixItems = [
        ...(basePayload['menu'] as List<dynamic>),
        {
          'id': 'p-4',
          'category': 'cat-1',
          'categoryId': 'cat-1',
          'name': 'Super Extra Creamy Royal Pistachio Qashtouta Family Box',
          'nameAr': 'قشطوطة فستق ملكي بالكريمة الطازجة حجم عائلي كبير جداً',
          'description': 'Serves 4 people',
          'descriptionAr': 'تكفي ٤ أفراد',
          'price': 185,
          'basePrice': 185,
          'comparePrice': 220,
          'tracksStock': false,
          'imageUrl': '',
          'variants': <dynamic>[],
          'optionGroups': <dynamic>[],
        },
        {
          'id': 'p-5',
          'category': 'cat-2',
          'categoryId': 'cat-2',
          'name': 'Mango Kunafa Bowl',
          'nameAr': 'كنافة بالمانجو',
          'description': 'Fresh seasonal mango',
          'descriptionAr': 'مانجو طازج موسمي',
          'price': 90,
          'basePrice': 90,
          'tracksStock': false,
          'imageUrl': '',
          'variants': <dynamic>[],
          'optionGroups': <dynamic>[],
        },
        {
          'id': 'p-6',
          'category': 'cat-2',
          'categoryId': 'cat-2',
          'name': 'Om Ali Nuts',
          'nameAr': 'أم علي بالمكسرات',
          'description': 'Baked hot with nuts',
          'descriptionAr': 'ساخنة بالمكسرات',
          'price': 70,
          'basePrice': 70,
          'tracksStock': false,
          'imageUrl': '',
          'variants': <dynamic>[],
          'optionGroups': <dynamic>[],
        },
      ];
      final sixItemPayload = {...basePayload, 'menu': sixItems};

      for (final locale in const [Locale('en'), Locale('ar')]) {
        const viewport = Size(390, 920);
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final cart = _RecordingCart();
        await tester.pumpWidget(
          EasyLocalization(
            key: UniqueKey(),
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'unused',
            fallbackLocale: const Locale('ar'),
            startLocale: locale,
            useOnlyLangCode: true,
            assetLoader: const _TestAssetLoader(),
            child: ProviderScope(
              overrides: [
                baseUrlProvider.overrideWithValue(
                  'https://api.otlob-egy.online',
                ),
                authControllerProvider.overrideWith(_AuthController.new),
                data_providers.customerVendorsRepositoryProvider
                    .overrideWithValue(_FakeVendorsRepo(sixItemPayload)),
                favoritesProvider.overrideWith(_FakeFavorites.new),
                cartProvider.overrideWith(() => cart),
              ],
              child: Builder(
                builder: (context) => MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  theme: ThemeData.light(),
                  darkTheme: ThemeData.dark(),
                  themeMode: locale.languageCode == 'en'
                      ? ThemeMode.light
                      : ThemeMode.dark,
                  home: MediaQuery(
                    data: const MediaQueryData(
                      size: viewport,
                      padding: EdgeInsets.only(top: 44, bottom: 24),
                      textScaler: TextScaler.linear(1.25),
                    ),
                    child: VendorDetailScreen(restaurant: sixItemPayload),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(SliverGrid), findsOneWidget);

        final bannerBefore = tester.getRect(
          find.byKey(const ValueKey('store_detail_banner')),
        );
        final r1 = tester.getRect(
          find.byKey(const ValueKey('store_product_card_p-1')),
        );
        final r2 = tester.getRect(
          find.byKey(const ValueKey('store_product_card_p-2')),
        );
        final r3 = tester.getRect(
          find.byKey(const ValueKey('store_product_card_p-3')),
        );

        // First 3 items sit on the exact same row with equal width & height
        expect(r1.top, closeTo(r2.top, 0.5));
        expect(r2.top, closeTo(r3.top, 0.5));
        expect(r1.width, closeTo(r2.width, 0.5));
        expect(r2.width, closeTo(r3.width, 0.5));
        expect(r1.height, closeTo(r2.height, 0.5));

        if (locale.languageCode == 'en') {
          expect(r1.right, lessThan(r2.left));
          expect(r2.right, lessThan(r3.left));
        } else {
          // Arabic RTL flows right-to-left
          expect(r1.left, greaterThan(r2.right));
          expect(r2.left, greaterThan(r3.right));
        }

        // Scroll page down: verify the whole page scrolls (banner moves up) and row 2 (p-4..p-6) is visible
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('store_product_card_p-4')),
          140,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final r4 = tester.getRect(
          find.byKey(const ValueKey('store_product_card_p-4')),
        );
        final r5 = tester.getRect(
          find.byKey(const ValueKey('store_product_card_p-5')),
        );
        final r6 = tester.getRect(
          find.byKey(const ValueKey('store_product_card_p-6')),
        );
        expect(r4.top, closeTo(r5.top, 0.5));
        expect(r5.top, closeTo(r6.top, 0.5));
        expect(
          tester
              .getRect(find.byKey(const ValueKey('store_product_card_p-1')))
              .top,
          lessThan(r4.top),
        );
        expect(bannerBefore.height, 168.0);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
