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
import 'package:otlob_customer/features/home/presentation/providers/discovery_search_controller.dart';
import 'package:otlob_customer/features/home/presentation/providers/favorites_provider.dart';
import 'package:otlob_customer/features/home/presentation/providers/home_controller.dart';
import 'package:otlob_customer/features/home/presentation/providers/home_state.dart';
import 'package:otlob_customer/features/home/presentation/widgets/category_icon_image.dart';
import 'package:otlob_customer/features/home/presentation/widgets/home_suggested_store_card.dart';
import 'package:otlob_customer/features/home/presentation/widgets/offers_auto_scroller.dart';
import 'package:otlob_customer/features/profile/presentation/providers/coin_history_provider.dart';
import 'package:otlob_customer/features/profile/presentation/providers/delivery_address_provider.dart';
import 'package:otlob_customer/features/profile/presentation/providers/profile_controller.dart';
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

class _TestProfile extends Profile {
  final String avatarUrl;
  _TestProfile([this.avatarUrl = '']);

  @override
  ProfileState build() => ProfileState(
    name: 'Test User',
    email: 'test@otlob.app',
    phone: '01000000000',
    avatar: avatarUrl,
    isArabic: true,
    addresses: const [],
  );
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
  String userAvatar = '',
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
      key: ValueKey('easy_${locale.languageCode}_${themeMode.name}'),
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
          profileProvider.overrideWith(() => _TestProfile(userAvatar)),
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
    '360x740': (
      size: const Size(360, 740),
      padding: const EdgeInsets.only(top: 24, bottom: 12),
    ),
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

        // Verify all key sections are inside the viewport vertically with zero bottom-nav overlap
        final viewportHeight = entry.value.size.height;
        final headerLogoRect = tester.getRect(
          find.byKey(const ValueKey('home_header_logo')),
        );
        final courierRect = tester.getRect(find.text('24/7'));
        final offersRect = tester.getRect(find.byType(OffersAutoScroller));
        final storeRect = tester.getRect(
          find.byType(HomeSuggestedStoreCard).first,
        );
        final navRect = tester.getRect(
          find.byKey(const ValueKey('home_bottom_nav')),
        );
        expect(headerLogoRect.width, 40.0);
        expect(headerLogoRect.height, 40.0);
        expect(storeRect.width, 192.0);
        expect(courierRect.top, greaterThan(0));
        expect(offersRect.bottom, lessThanOrEqualTo(storeRect.top));
        expect(storeRect.bottom, lessThanOrEqualTo(navRect.top));
        expect(navRect.bottom, lessThanOrEqualTo(viewportHeight + 0.5));
        expect(
          navRect.height,
          greaterThanOrEqualTo(62.0 + entry.value.padding.bottom),
        );
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
    // Verify store distance + delivery time never uses ellipsis truncation
    final metaText = tester.widget<Text>(find.text('0.9 km • 17-27 mins'));
    expect(metaText.overflow, isNot(TextOverflow.ellipsis));

    // Also verify tight 360x740 viewport at 1.3x text scale has zero overflow
    await _pumpHome(
      tester,
      viewport: const Size(360, 740),
      safeAreaPadding: const EdgeInsets.only(top: 24, bottom: 12),
      locale: const Locale('ar'),
      textScaler: const TextScaler.linear(1.3),
    );
    expect(tester.takeException(), isNull);
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
            profileProvider.overrideWith(() => _TestProfile()),
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

  testWidgets(
    'HomeScreen search redirects directly to results panel without touching Suggested for you',
    (tester) async {
      await _pumpHome(
        tester,
        viewport: const Size(390, 844),
        safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
        locale: const Locale('ar'),
      );

      expect(find.byType(HomeSuggestedStoreCard), findsNWidgets(2));

      // Typing immediately redirects to the search results panel (no mutation of Suggested for you)
      await tester.enterText(find.byType(TextField), 'العزبي');
      await tester.pump();
      expect(find.byType(HomeSuggestedStoreCard), findsNothing);

      // Clearing search restores the original untouched Suggested for you cards
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.byType(HomeSuggestedStoreCard), findsNWidgets(2));
    },
  );

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
    expect(darkAllLabel.style?.color, const Color(0xFFFFFFFF));

    // Header falls back to main app logo inside a circular gold ring when user has no uploaded avatar
    expect(find.byKey(const ValueKey('home_header_main_logo')), findsOneWidget);
    final darkHeaderLogo = tester.widget<Container>(
      find.byKey(const ValueKey('home_header_logo')),
    );
    final darkHeaderDec = darkHeaderLogo.decoration as BoxDecoration?;
    expect(darkHeaderDec?.shape, BoxShape.circle);
    expect(darkHeaderDec?.color, isNull);
    expect(darkHeaderDec?.border, isNotNull);

    // "All" tile renders main app logo inside a circular gold ring with no background fill
    expect(find.byKey(const ValueKey('home_all_main_logo')), findsOneWidget);
    final darkAllTile = tester.widget<Container>(
      find.byKey(const ValueKey('home_all_category_tile')),
    );
    final darkAllDec = darkAllTile.decoration as BoxDecoration?;
    expect(darkAllDec?.shape, BoxShape.circle);
    expect(darkAllDec?.color, isNull);
    expect(darkAllDec?.border, isNotNull);
    for (final catType in const ['restaurants', 'pharmacy', 'produce', 'grocery']) {
      final tile = tester.widget<Container>(
        find.byKey(ValueKey('home_category_tile_$catType')),
      );
      expect(tile.color, Colors.transparent);
      expect(tile.decoration, isNull);
    }

    // Light Mode check: #F7F6F2 airy bg + transparent category tiles + circular gold-ring All logo
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
    expect(lightAllLabel.style?.color, const Color(0xFF11100E));

    expect(find.byKey(const ValueKey('home_header_main_logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_all_main_logo')), findsOneWidget);
    final lightAllTile = tester.widget<Container>(
      find.byKey(const ValueKey('home_all_category_tile')),
    );
    final lightAllDec = lightAllTile.decoration as BoxDecoration?;
    expect(lightAllDec?.shape, BoxShape.circle);
    expect(lightAllDec?.color, isNull);
    expect(lightAllDec?.border, isNotNull);
    for (final catType in const ['restaurants', 'pharmacy', 'produce', 'grocery']) {
      final tile = tester.widget<Container>(
        find.byKey(ValueKey('home_category_tile_$catType')),
      );
      expect(tile.color, Colors.transparent);
      expect(tile.decoration, isNull);
    }
  });

  testWidgets(
    'HomeScreen top header shows user profile avatar automatically when uploaded instead of main logo',
    (tester) async {
      await _pumpHome(
        tester,
        viewport: const Size(390, 844),
        safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
        locale: const Locale('ar'),
        userAvatar: 'https://api.otlob-egy.online/uploads/avatar_123.jpg',
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('home_header_main_logo')), findsNothing);
      expect(
        find.byKey(
          const ValueKey(
            'home_header_avatar_https://api.otlob-egy.online/uploads/avatar_123.jpg',
          ),
        ),
        findsOneWidget,
      );
    },
  );

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

      expect(alphaAt(0, 0), 0);
      expect(alphaAt(1, 1), greaterThan(0));
      expect(alphaAt(1, 1), lessThan(255));
      expect(alphaAt(2, 2), 255);
      expect(alphaAt(3, 3), 255);
    },
  );

  test(
    'removeUniformBackgroundRgba strips solid white product studio backdrop while preserving interior highlights and natural photos',
    () {
      const w = 7;
      const h = 7;
      final whiteBgProduct = Uint8List(w * h * 4);

      void setPx(Uint8List buf, int x, int y, int r, int g, int b, int a) {
        final off = (y * w + x) * 4;
        buf[off] = r;
        buf[off + 1] = g;
        buf[off + 2] = b;
        buf[off + 3] = a;
      }

      // Product on pure white (#FFFFFF) studio backdrop with white highlight inside red product
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final ring = [x, y, w - 1 - x, h - 1 - y].reduce((a, b) => a < b ? a : b);
          if (ring == 0) {
            setPx(whiteBgProduct, x, y, 252, 252, 252, 255);
          } else if (ring == 1) {
            setPx(whiteBgProduct, x, y, 232, 232, 232, 255);
          } else if (ring == 2) {
            setPx(whiteBgProduct, x, y, 200, 50, 30, 255);
          } else {
            // Interior white label on the product -> must stay fully opaque!
            setPx(whiteBgProduct, x, y, 255, 255, 255, 255);
          }
        }
      }

      final cleaned = removeUniformBackgroundRgba(
        rgbaBytes: whiteBgProduct,
        width: w,
        height: h,
      );
      int alphaAt(Uint8List buf, int x, int y) => buf[(y * w + x) * 4 + 3];

      expect(alphaAt(cleaned, 0, 0), 0);
      // Light-gray product box edge (ring 1, rgb 232) must NOT be eaten into!
      expect(alphaAt(cleaned, 1, 1), 255);
      expect(alphaAt(cleaned, 2, 2), 255);
      expect(alphaAt(cleaned, 3, 3), 255);

      // Multi-colored natural photo (distinct corners) -> left completely untouched
      final naturalPhoto = Uint8List(w * h * 4);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          setPx(naturalPhoto, x, y, 120, 90, 60, 255);
        }
      }
      setPx(naturalPhoto, 0, 0, 20, 200, 40, 255);
      setPx(naturalPhoto, w - 1, 0, 220, 30, 20, 255);
      setPx(naturalPhoto, 0, h - 1, 30, 50, 230, 255);
      setPx(naturalPhoto, w - 1, h - 1, 240, 220, 20, 255);

      final untouched = removeUniformBackgroundRgba(
        rgbaBytes: naturalPhoto,
        width: w,
        height: h,
      );
      expect(alphaAt(untouched, 0, 0), 255);
      expect(alphaAt(untouched, 3, 3), 255);
    },
  );

  testWidgets(
    'HomeScreen product search displays matching product with its vendor and navigates to vendor product on tap',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Map<String, dynamic>? pushedVendorExtra;
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const MediaQuery(
              data: MediaQueryData(
                size: Size(390, 844),
                padding: EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/vendor',
            builder: (_, state) {
              pushedVendorExtra = state.extra as Map<String, dynamic>?;
              return const Scaffold(body: Center(child: Text('VENDOR_PAGE')));
            },
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
              profileProvider.overrideWith(() => _TestProfile()),
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
              discoverySearchControllerProvider.overrideWith((ref, arg) async {
                if (arg.query == 'بيج تيستي') {
                  return [
                    {
                      'id': 'v1',
                      'name': 'Burger King',
                      'nameAr': 'برجر كينج',
                      'rating': 4.8,
                      'distanceKm': 0.4,
                      'deliveryTime': '16-26 دقيقة',
                      'status': 'OPEN',
                      'matchingProducts': [
                        {
                          'id': 'p_big_tasty',
                          'name': 'Big Tasty',
                          'nameAr': 'بيج تيستي',
                          'description': 'ساندوتش لحم مشوي مع صوص',
                          'price': 120,
                          'image': '',
                        },
                      ],
                    },
                  ];
                }
                return [];
              }),
            ],
            child: Builder(
              builder: (context) => MaterialApp.router(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: ThemeMode.dark,
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Enter a product name in the Home search bar & wait past debounce
      await tester.enterText(find.byType(TextField), 'بيج تيستي');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Shows BOTH the matching product & its vendor details
      expect(find.text('برجر كينج'), findsOneWidget);
      expect(find.text('بيج تيستي'), findsWidgets);
      expect(find.text('120 ج.م'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);

      // Tapping the product opens the vendor page with productId
      await tester.tap(
        find.byKey(const ValueKey('home_search_product_p_big_tasty')),
      );
      await tester.pumpAndSettle();
      expect(find.text('VENDOR_PAGE'), findsOneWidget);
      expect(pushedVendorExtra?['id'], 'v1');
      expect(pushedVendorExtra?['productId'], 'p_big_tasty');
    },
  );

  testWidgets(
    'Typing a single letter in Home search keeps keyboard focus uninterrupted as results panel opens',
    (tester) async {
      await _pumpHome(
        tester,
        viewport: const Size(390, 844),
        safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
        locale: const Locale('ar'),
      );

      final textFieldFinder = find.byType(TextField);
      await tester.tap(textFieldFinder);
      await tester.pump();

      // Type first letter and let debounce transition Home into search results view
      tester.testTextInput.enterText('ب');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Search TextField must stay focused without needing a second tap!
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);

      // Continue typing directly via active IME without tapping the search box again
      tester.testTextInput.enterText('برجر');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(editable.controller.text, 'برجر');
      expect(editable.focusNode.hasFocus, isTrue);
    },
  );

  testWidgets(
    'Pulling down from Home header triggers dashboard refresh while keeping zero vertical scroll',
    (tester) async {
      var homeBuildCount = 0;
      final data = _buildSampleHomeData();

      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
                () => _CountingHomeController(
                  data,
                  onBuild: () => homeBuildCount++,
                ),
              ),
              platformSettingsProvider.overrideWith(
                (ref) async => PlatformSettingsData(),
              ),
              coinHistoryProvider.overrideWith(() => _TestCoinHistory(10)),
              inboxCountsProvider.overrideWith(() => _TestInboxCounts()),
              cartProvider.overrideWith(
                () => _TestCart(const CartState(vendorBaskets: {})),
              ),
              favoritesProvider.overrideWith(() => _TestFavorites()),
              authControllerProvider.overrideWith(() => _TestAuthController()),
              profileProvider.overrideWith(() => _TestProfile()),
              activeDeliveryAddressProvider.overrideWith(
                (ref) => {'address': 'السكه الجديد'},
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
              builder: (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: ThemeMode.dark,
                home: const MediaQuery(
                  data: MediaQueryData(
                    size: Size(390, 844),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: HomeScreen(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(homeBuildCount, 1);

      // Drag downward from the Home header past touch slop & refresh threshold
      final headerDrag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('home_header_pull_refresh_area')),
        ),
      );
      await headerDrag.moveBy(const Offset(0, 30));
      await tester.pump();
      await headerDrag.moveBy(const Offset(0, 130));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('home_pull_refresh_indicator')),
        findsOneWidget,
      );

      await headerDrag.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(homeBuildCount, greaterThanOrEqualTo(2));
      expect(
        tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where((s) => s.axis == Axis.vertical),
        isEmpty,
      );
    },
  );

  testWidgets(
    'HomeScreen displays Nearby Vendors instead of Suggested for You and uses readable white texts in Dark Mode and dark texts in Light Mode',
    (tester) async {
      // 1. Dark Mode (English)
      await _pumpHome(
        tester,
        viewport: const Size(390, 844),
        safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Nearby Vendors'), findsOneWidget);
      expect(find.text('Suggested for You'), findsNothing);
      expect(find.text('Suggested for you'), findsNothing);

      // Verify key texts are crisp white in dark mode
      for (final textToCheck in [
        'Nearby Vendors',
        'Hot Deals',
        'See All',
        'All',
        'Burger King',
        '40',
        '4.9',
        '105',
        'Home',
      ]) {
        final finder = find.textContaining(textToCheck);
        expect(finder, findsWidgets, reason: 'Missing text "$textToCheck"');
        final w = tester.widget<Text>(finder.first);
        final c = w.style?.color;
        expect(c, isNotNull, reason: 'Missing style color for "$textToCheck"');
        expect(
          c!.computeLuminance(),
          greaterThan(0.65),
          reason:
              'Expected light/white text in Dark Mode for "$textToCheck", got $c',
        );
      }

      // 2. Dark Mode (Arabic)
      await _pumpHome(
        tester,
        viewport: const Size(390, 844),
        safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
      );
      expect(find.text('المتاجر القريبة'), findsOneWidget);
      expect(find.text('مقترح لك'), findsNothing);

      // 3. Light Mode (English)
      await _pumpHome(
        tester,
        viewport: const Size(390, 844),
        safeAreaPadding: const EdgeInsets.only(top: 47, bottom: 34),
        locale: const Locale('en'),
        themeMode: ThemeMode.light,
      );

      expect(find.text('Nearby Vendors'), findsOneWidget);
      expect(find.text('Suggested for You'), findsNothing);

      // Verify key texts are deep dark ink in light mode
      for (final textToCheck in [
        'Nearby Vendors',
        'Hot Deals',
        'See All',
        'All',
        'Burger King',
        '40',
        '4.9',
        '105',
        'Home',
      ]) {
        final finder = find.textContaining(textToCheck);
        expect(finder, findsWidgets, reason: 'Missing text "$textToCheck"');
        final w = tester.widget<Text>(finder.first);
        final c = w.style?.color;
        expect(c, isNotNull, reason: 'Missing style color for "$textToCheck"');
        expect(
          c!.computeLuminance(),
          lessThan(0.12),
          reason:
              'Expected dark readable text in Light Mode for "$textToCheck", got $c',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}

class _CountingHomeController extends HomeController {
  final HomeData data;
  final VoidCallback onBuild;
  _CountingHomeController(this.data, {required this.onBuild});

  @override
  Future<HomeData> build() async {
    onBuild();
    return data;
  }
}
