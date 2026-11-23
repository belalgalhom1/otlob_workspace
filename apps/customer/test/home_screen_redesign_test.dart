import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otlob_customer/core/providers/platform_settings_provider.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/chat/presentation/providers/inbox_counts_provider.dart';
import 'package:otlob_customer/features/home/presentation/pages/home_screen.dart';
import 'package:otlob_customer/features/home/presentation/providers/customer_location_provider.dart';
import 'package:otlob_customer/features/home/presentation/providers/favorites_provider.dart';
import 'package:otlob_customer/features/home/presentation/providers/home_controller.dart';
import 'package:otlob_customer/features/home/presentation/providers/home_state.dart';
import 'package:otlob_customer/features/home/presentation/widgets/category_icon_image.dart';
import 'package:otlob_customer/features/home/presentation/widgets/home_suggested_store_card.dart';
import 'package:otlob_customer/features/home/presentation/widgets/offers_auto_scroller.dart';
import 'package:otlob_customer/features/profile/presentation/providers/coin_history_provider.dart';
import 'package:otlob_customer/features/profile/presentation/providers/delivery_address_provider.dart';
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

class _TestHomeController extends HomeController {
  final HomeData data;
  _TestHomeController(this.data);

  @override
  Future<HomeData> build() async => data;
}

class _TestAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}

class _TestCoinHistory extends CoinHistory {
  final int balance;
  _TestCoinHistory(this.balance);

  @override
  CoinHistoryState build() => CoinHistoryState(currentBalance: balance);
}

class _TestInboxCounts extends InboxCounts {
  final int chatUnread;
  final int notificationsUnread;
  _TestInboxCounts({this.chatUnread = 0, this.notificationsUnread = 0});

  @override
  InboxCountsState build() => InboxCountsState(
    chatUnread: chatUnread,
    notificationsUnread: notificationsUnread,
  );

  @override
  Future<void> refresh() async {}
}

class _TestCart extends Cart {
  final CartState cartState;
  _TestCart(this.cartState);

  @override
  CartState build() => cartState;
}

class _TestFavorites extends Favorites {
  @override
  Set<String> build() => {'v1'};

  @override
  Future<void> toggleFavorite(String vendorId) async {
    if (state.contains(vendorId)) {
      state = {...state}..remove(vendorId);
    } else {
      state = {...state, vendorId};
    }
  }
}

HomeData _buildSampleHomeData({bool includeOffers = true}) {
  return HomeData(
    categories: [
      {'id': 'all', 'name': 'All', 'nameAr': 'الكل', 'type': 'all'},
      {'id': '1', 'name': 'Restaurants', 'nameAr': 'مطاعم', 'type': 'restaurants', 'iconUrl': ''},
      {'id': '2', 'name': 'Pharmacies', 'nameAr': 'صيدليات', 'type': 'pharmacy', 'iconUrl': ''},
      {'id': '3', 'name': 'Produce', 'nameAr': 'فواكه وخضار', 'type': 'produce', 'iconUrl': ''},
      {'id': '4', 'name': 'Grocery', 'nameAr': 'بقالة', 'type': 'grocery', 'iconUrl': ''},
    ],
    products: [
      {
        'id': 'v1',
        'name': 'Burger King',
        'nameAr': 'برجر كينج',
        'vendor': 'Burgers',
        'status': 'OPEN',
        'rating': 4.9,
        'distanceKm': 0.9,
        'deliveryTime': '17-27 دقيقة',
        'deliveryTimeEn': '17-27 mins',
        'image': '',
        'logo': '',
        'coverImage': '',
      },
      {
        'id': 'v2',
        'name': 'Al-Ezaby Pharmacy',
        'nameAr': 'صيدلية العزبي',
        'vendor': 'Pharmacy',
        'status': 'CLOSED',
        'rating': 4.7,
        'distanceKm': 1.4,
        'deliveryTime': '20-30 دقيقة',
        'deliveryTimeEn': '20-30 mins',
        'image': '',
        'logo': '',
        'coverImage': '',
      },
    ],
    promotions: [
      {
        'id': 'p1',
        'title': 'Fast Delivery Everywhere',
        'titleAr': 'توصيل أطلب لكل مكان',
        'description': 'Bikes, motorcycles and cars ready 24h',
        'descriptionAr': 'دراجات وموتوسيكلات جاهزة لخدمتك 24 ساعة',
        'imageUrl': '',
        'type': 'VENDOR',
        'vendorId': 'v1',
      },
    ],
    offers: includeOffers
        ? [
            {
              'id': 'o1',
              'vendorId': 'v1',
              'productId': 'prod1',
              'originalPrice': 150,
              'offerPrice': 105,
              'productName': 'Double Cheese Burger',
              'productNameAr': 'دبل تشيز برجر',
              'vendorStoreName': 'Burger King',
              'vendorStoreNameAr': 'برجر كينج',
              'productImageUrl': '',
            },
            {
              'id': 'o2',
              'vendorId': 'v2',
              'productId': 'prod2',
              'originalPrice': 200,
              'offerPrice': 160,
              'productName': 'Vitamin C Pack',
              'productNameAr': 'عبوة فيتامين سي',
              'vendorStoreName': 'Al-Ezaby Pharmacy',
              'vendorStoreNameAr': 'صيدلية العزبي',
              'productImageUrl': '',
            },
          ]
        : [],
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size viewport,
  required EdgeInsets safeAreaPadding,
  Locale locale = const Locale('ar'),
  TextScaler textScaler = TextScaler.noScaling,
  ThemeMode themeMode = ThemeMode.dark,
  HomeData? data,
  int cartItemsCount = 3,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final homeData = data ?? _buildSampleHomeData();
  final cartState = CartState(
    vendorBaskets: cartItemsCount > 0
        ? {
            'v1': [
              CartItem(
                product: const CartProductRef(
                  id: 'prod1',
                  name: 'Burger',
                  price: 105,
                  vendorId: 'v1',
                  isActive: true,
                  tracksStock: false,
                ),
                quantity: cartItemsCount,
              ),
            ],
          }
        : const {},
  );

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'translations',
      fallbackLocale: const Locale('en'),
      startLocale: locale,
      assetLoader: const _TestAssetLoader(),
      child: ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith(
            () => _TestHomeController(homeData),
          ),
          platformSettingsProvider.overrideWith(
            (ref) async => PlatformSettingsData(),
          ),
          authControllerProvider.overrideWith(() => _TestAuthController()),
          coinHistoryProvider.overrideWith(() => _TestCoinHistory(40)),
          inboxCountsProvider.overrideWith(
            () => _TestInboxCounts(chatUnread: 1, notificationsUnread: 2),
          ),
          cartProvider.overrideWith(() => _TestCart(cartState)),
          favoritesProvider.overrideWith(() => _TestFavorites()),
          activeDeliveryAddressProvider.overrideWith(
            (ref) => {'id': 'a1', 'label': 'Home', 'address': 'السكه الجديد'},
          ),
          effectiveCustomerLocationProvider.overrideWith(
            (ref) async => const EffectiveLocation(
              lat: 30.0444,
              lng: 31.2357,
              isGps: false,
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeMode,
              home: MediaQuery(
                data: MediaQueryData(
                  size: viewport,
                  padding: safeAreaPadding,
                  textScaler: textScaler,
                ),
                child: const HomeScreen(),
              ),
            );
          },
        ),
      ),
    ),
  );

  // Pump a few frames (avoid pumpAndSettle because of periodic timers)
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  final viewports = <String, ({Size size, EdgeInsets padding})>{
    '360x800': (
      size: const Size(360, 800),
      padding: const EdgeInsets.only(top: 28, bottom: 16),
    ),
    '390x844': (
      size: const Size(390, 844),
      padding: const EdgeInsets.only(top: 47, bottom: 34),
    ),
    '412x915': (
      size: const Size(412, 915),
      padding: const EdgeInsets.only(top: 36, bottom: 24),
    ),
  };

  for (final entry in viewports.entries) {
    testWidgets(
      'HomeScreen zero-scroll RTL layout fits with zero overflow on ${entry.key}',
      (tester) async {
        await _pumpHome(
          tester,
          viewport: entry.value.size,
          safeAreaPadding: entry.value.padding,
          locale: const Locale('ar'),
        );

        expect(tester.takeException(), isNull);

        // Verify ZERO vertical scrollables exist on HomeScreen
        final verticalScrollables = tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where((s) => s.axis == Axis.vertical);
        expect(verticalScrollables, isEmpty);

        // Verify real dynamic data bindings are all rendered simultaneously
        expect(find.text('السكه الجديد'), findsOneWidget);
        expect(find.text('40'), findsOneWidget);
        expect(find.text('ابحث عن ما تريد'), findsOneWidget);
        expect(find.text('الكل'), findsOneWidget);
        expect(find.text('مطاعم'), findsOneWidget);
        expect(find.text('صيدليات'), findsOneWidget);
        expect(find.text('بقالة'), findsOneWidget);
        expect(find.text('24/7'), findsOneWidget);
        expect(find.byType(OffersAutoScroller), findsOneWidget);
        expect(find.text('دبل تشيز برجر'), findsOneWidget);
        expect(find.text('-30%'), findsOneWidget);
        expect(find.byType(HomeSuggestedStoreCard), findsWidgets);
        expect(find.text('برجر كينج'), findsWidgets);
        // Real cart badge count in bottom nav
        expect(find.text('3'), findsOneWidget);

        // Verify all key sections are inside the viewport vertically
        final viewportHeight = entry.value.size.height;
        final courierRect = tester.getRect(find.text('24/7'));
        final offersRect = tester.getRect(find.byType(OffersAutoScroller));
        final storeRect = tester.getRect(
          find.byType(HomeSuggestedStoreCard).first,
        );
        expect(courierRect.top, greaterThan(0));
        expect(offersRect.bottom, lessThan(viewportHeight));
        expect(storeRect.bottom, lessThan(viewportHeight));
      },
    );
  }

  testWidgets('HomeScreen fits cleanly in LTR English & 1.3x text scale', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      viewport: const Size(390, 844),
      safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(1.3),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Search for what you want'), findsOneWidget);
    expect(find.text('Double Cheese Burger'), findsOneWidget);
    expect(find.text('Burger King'), findsWidgets);
  });

  testWidgets('Tapping anywhere on Custom Courier banner opens /custom-delivery', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    const viewport = Size(390, 844);
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const HomeScreen(),
        ),
        GoRoute(
          path: '/custom-delivery',
          builder: (_, _) => const Scaffold(body: Text('CUSTOM_DELIVERY_PAGE')),
        ),
      ],
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('ar'),
        assetLoader: const _TestAssetLoader(),
        child: ProviderScope(
          overrides: [
            homeControllerProvider.overrideWith(
              () => _TestHomeController(_buildSampleHomeData()),
            ),
            platformSettingsProvider.overrideWith(
              (ref) async => PlatformSettingsData(),
            ),
            authControllerProvider.overrideWith(() => _TestAuthController()),
            coinHistoryProvider.overrideWith(() => _TestCoinHistory(40)),
            inboxCountsProvider.overrideWith(() => _TestInboxCounts()),
            cartProvider.overrideWith(
              () => _TestCart(const CartState(vendorBaskets: {})),
            ),
            favoritesProvider.overrideWith(() => _TestFavorites()),
            activeDeliveryAddressProvider.overrideWith(
              (ref) => {'id': 'a1', 'label': 'Home', 'address': 'السكه الجديد'},
            ),
            effectiveCustomerLocationProvider.overrideWith(
              (ref) async => const EffectiveLocation(
                lat: 30.0444,
                lng: 31.2357,
                isGps: false,
              ),
            ),
          ],
          child: Builder(
            builder: (context) => MaterialApp.router(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              routerConfig: router,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the banner badge/body (NOT the "اطلب الآن" button)
    await tester.tap(find.text('24/7'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('CUSTOM_DELIVERY_PAGE'), findsOneWidget);
  });

  testWidgets('HomeScreen search dynamically filters suggested stores', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      viewport: const Size(390, 844),
      safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
      locale: const Locale('ar'),
    );

    expect(find.byType(HomeSuggestedStoreCard), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'العزبي');
    await tester.pump();

    expect(find.byType(HomeSuggestedStoreCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeSuggestedStoreCard),
        matching: find.text('صيدلية العزبي'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('HomeScreen adapts dynamically to Dark Mode and Light Mode', (
    tester,
  ) async {
    // Dark Mode check: #0F0E0C bg + WHITE inverted logos with dark TLOB & warm gold أطلب
    await _pumpHome(
      tester,
      viewport: const Size(390, 844),
      safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);
    final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(darkScaffold.backgroundColor, const Color(0xFF0F0E0C));
    final darkAllLabel = tester.widget<Text>(find.text('الكل'));
    expect(darkAllLabel.style?.color, const Color(0xFFE5A93C));

    final darkHeaderLogo = tester.widget<Container>(
      find.byKey(const ValueKey('home_header_logo')),
    );
    expect(
      (darkHeaderLogo.decoration as BoxDecoration).color,
      const Color(0xFFFFFFFF),
    );
    final darkAllTile = tester.widget<Container>(
      find.byKey(const ValueKey('home_all_category_tile')),
    );
    expect(
      (darkAllTile.decoration as BoxDecoration).color,
      const Color(0xFFFFFFFF),
    );
    for (final catType in const ['restaurants', 'pharmacy', 'produce', 'grocery']) {
      final tile = tester.widget<Container>(
        find.byKey(ValueKey('home_category_tile_$catType')),
      );
      expect(
        (tile.decoration as BoxDecoration).color,
        const Color(0xFFFFFFFF),
      );
    }
    final darkTlobTexts = tester.widgetList<Text>(find.text('TLOB')).toList();
    expect(darkTlobTexts.length, 2);
    for (final t in darkTlobTexts) {
      expect(t.style?.color, const Color(0xFF11100E));
    }
    final darkOtlobTexts = tester.widgetList<Text>(find.text('أطلب')).toList();
    expect(darkOtlobTexts.length, 2);
    for (final t in darkOtlobTexts) {
      expect(t.style?.color, const Color(0xFFB87B14));
    }

    // Light Mode check: #F7F6F2 airy bg + BLACK inverted logos with white TLOB & light gold أطلب
    await _pumpHome(
      tester,
      viewport: const Size(390, 844),
      safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
      locale: const Locale('ar'),
      themeMode: ThemeMode.light,
    );
    expect(tester.takeException(), isNull);
    final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(lightScaffold.backgroundColor, const Color(0xFFF7F6F2));
    final lightAllLabel = tester.widget<Text>(find.text('الكل'));
    expect(lightAllLabel.style?.color, const Color(0xFFB87B14));

    final lightHeaderLogo = tester.widget<Container>(
      find.byKey(const ValueKey('home_header_logo')),
    );
    expect(
      (lightHeaderLogo.decoration as BoxDecoration).color,
      const Color(0xFF11100E),
    );
    // All 5 Business Type tiles (including "الكل") stay pure #FFFFFF in Light Mode too
    final lightAllTile = tester.widget<Container>(
      find.byKey(const ValueKey('home_all_category_tile')),
    );
    expect(
      (lightAllTile.decoration as BoxDecoration).color,
      const Color(0xFFFFFFFF),
    );
    final lightAllCircle = tester.widget<Container>(
      find.byKey(const ValueKey('home_all_category_circle_logo')),
    );
    expect(
      (lightAllCircle.decoration as BoxDecoration).color,
      const Color(0xFFFFFFFF),
    );
    expect(
      (lightAllCircle.decoration as BoxDecoration).shape,
      BoxShape.circle,
    );
    for (final catType in const ['restaurants', 'pharmacy', 'produce', 'grocery']) {
      final tile = tester.widget<Container>(
        find.byKey(ValueKey('home_category_tile_$catType')),
      );
      expect(
        (tile.decoration as BoxDecoration).color,
        const Color(0xFFFFFFFF),
      );
    }
    // Header TLOB is inverted white-on-black in Light Mode; "الكل" tile TLOB is dark #11100E on #FFFFFF
    final headerTlob = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home_header_logo')),
        matching: find.text('TLOB'),
      ),
    );
    expect(headerTlob.style?.color, const Color(0xFFFFFFFF));
    final allTileTlob = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home_all_category_tile')),
        matching: find.text('TLOB'),
      ),
    );
    expect(allTileTlob.style?.color, const Color(0xFF11100E));
    final allTileOtlob = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home_all_category_tile')),
        matching: find.text('أطلب'),
      ),
    );
    expect(allTileOtlob.style?.color, const Color(0xFFB87B14));
  });

  testWidgets('HomeScreen handles empty offers gracefully with zero overflow', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      viewport: const Size(360, 800),
      safeAreaPadding: const EdgeInsets.only(top: 28, bottom: 16),
      locale: const Locale('ar'),
      data: _buildSampleHomeData(includeOffers: false),
      cartItemsCount: 0,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(OffersAutoScroller), findsNothing);
    expect(find.byType(HomeSuggestedStoreCard), findsNWidgets(2));
  });

  test(
    'removeBlackBackgroundRgba strips exterior near-black pixels with feathering while preserving interior dark details',
    () {
      // 7x7 RGBA test image:
      // - Outer border (ring 0): pure black (5, 5, 5, 255) -> must become alpha 0
      // - Ring 1: anti-aliased dark feather (34, 34, 34, 255) -> 0 < alpha < 255
      // - Ring 2: bright red artwork boundary (220, 40, 40, 255) -> alpha 255
      // - Center pixel (3,3): interior dark detail (8, 8, 8, 255) -> must stay alpha 255!
      const w = 7;
      const h = 7;
      final bytes = Uint8List(w * h * 4);

      void setPx(int x, int y, int r, int g, int b, int a) {
        final off = (y * w + x) * 4;
        bytes[off] = r;
        bytes[off + 1] = g;
        bytes[off + 2] = b;
        bytes[off + 3] = a;
      }

      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final ring = [x, y, w - 1 - x, h - 1 - y].reduce((a, b) => a < b ? a : b);
          if (ring == 0) {
            setPx(x, y, 5, 5, 5, 255);
          } else if (ring == 1) {
            setPx(x, y, 34, 34, 34, 255);
          } else if (ring == 2) {
            setPx(x, y, 220, 40, 40, 255);
          } else {
            setPx(x, y, 8, 8, 8, 255);
          }
        }
      }

      final processed = removeBlackBackgroundRgba(
        rgbaBytes: bytes,
        width: w,
        height: h,
      );

      int alphaAt(int x, int y) => processed[(y * w + x) * 4 + 3];

      // Exterior corner black pixel -> fully transparent
      expect(alphaAt(0, 0), 0);
      // Feather band pixel (34,34,34) -> smooth partial alpha
      expect(alphaAt(1, 1), greaterThan(0));
      expect(alphaAt(1, 1), lessThan(255));
      // Bright artwork pixel -> fully opaque
      expect(alphaAt(2, 2), 255);
      // Interior dark detail surrounded by artwork -> preserved fully opaque!
      expect(alphaAt(3, 3), 255);
    },
  );
}
