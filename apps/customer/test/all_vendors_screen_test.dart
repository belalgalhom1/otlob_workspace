import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/home/presentation/pages/all_vendors_screen.dart';
import 'package:otlob_customer/features/home/presentation/providers/favorites_provider.dart';
import 'package:otlob_customer/features/home/presentation/providers/home_controller.dart';
import 'package:otlob_customer/features/home/presentation/providers/home_state.dart';
import 'package:otlob_customer/features/home/presentation/widgets/vendor_card.dart';
import 'package:otlob_customer/features/home/presentation/widgets/vertical_promo_banners.dart';
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

class _TestCart extends Cart {
  @override
  CartState build() => const CartState(vendorBaskets: {});
}

class _TestFavorites extends Favorites {
  @override
  Set<String> build() => const {'v1'};
}

HomeData _sampleData({required List<Map<String, dynamic>> promotions}) {
  return HomeData(
    categories: const [
      {'id': 'all', 'name': 'All', 'nameAr': 'الكل', 'type': 'all'},
      {
        'id': 'vert-restaurants',
        'name': 'Restaurants',
        'nameAr': 'مطاعم',
        'type': 'restaurants',
      },
      {
        'id': 'vert-grocery',
        'name': 'Supermarkets',
        'nameAr': 'سوبرماركت',
        'type': 'grocery',
      },
    ],
    products: const [
      {
        'id': 'v1',
        'name': 'Burger King',
        'nameAr': 'برجر كينج',
        'type': 'restaurants',
        'status': 'OPEN',
        'rating': 4.5,
        'ratingCount': 12,
        'distanceKm': 0.8,
        'deliveryTime': '16-26 دقيقة',
        'deliveryTimeEn': '16-26 mins',
        'vendor': 'Burgers & Fries',
        'vendorAr': 'برجر وبطاطس مقرمشة',
        'tag': 'Top Rated',
        'image': '',
        'logo': '',
      },
      {
        'id': 'v2',
        'name': 'B Laban',
        'nameAr': 'بلبن',
        'type': 'restaurants',
        'status': 'OPEN',
        'rating': 4.8,
        'ratingCount': 25,
        'distanceKm': 2.4,
        'deliveryTime': '20-30 دقيقة',
        'deliveryTimeEn': '20-30 mins',
        'vendor': 'Desserts',
        'vendorAr': 'حلويات شرقية',
        'tag': 'Open',
        'image': '',
        'logo': '',
      },
      {
        'id': 'v3',
        'name': 'Koshary El Tahrir',
        'nameAr': 'كشري التحرير',
        'type': 'restaurants',
        'status': 'CLOSED',
        'rating': 4.2,
        'ratingCount': 9,
        'distanceKm': 1.5,
        'deliveryTime': '15-25 دقيقة',
        'deliveryTimeEn': '15-25 mins',
        'image': '',
        'logo': '',
      },
    ],
    promotions: promotions,
    offers: const [],
    activeOrder: null,
  );
}

Widget _buildTestApp(HomeData data, {Locale locale = const Locale('ar')}) {
  return ProviderScope(
    overrides: [
      homeControllerProvider.overrideWith(() => _TestHomeController(data)),
      authControllerProvider.overrideWith(_TestAuthController.new),
      cartProvider.overrideWith(_TestCart.new),
      favoritesProvider.overrideWith(_TestFavorites.new),
    ],
    child: EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'unused',
      assetLoader: const _TestAssetLoader(),
      startLocale: locale,
      fallbackLocale: const Locale('ar'),
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData.dark(),
          home: const AllVendorsScreen(type: 'restaurants'),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'renders business-type-specific banners and compact horizontal store rows in Arabic RTL at 360px without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = _sampleData(
        promotions: const [
          {
            'id': 'p-home',
            'title': 'Home Global Promo',
            'titleAr': 'عرض الصفحة الرئيسية',
            'imageUrl': '',
            'type': 'BANNER',
            'verticalId': null,
            'verticalSlug': null,
          },
          {
            'id': 'p-rest',
            'title': 'Restaurants Special',
            'titleAr': 'خصومات المطاعم',
            'description': 'Up to 30% off',
            'descriptionAr': 'خصم حتى 30% على المطاعم',
            'imageUrl': '',
            'type': 'BANNER',
            'verticalId': 'vert-restaurants',
            'verticalSlug': 'restaurants',
          },
          {
            'id': 'p-grocery',
            'title': 'Grocery Promo',
            'titleAr': 'عروض السوبرماركت',
            'imageUrl': '',
            'type': 'BANNER',
            'verticalId': 'vert-grocery',
            'verticalSlug': 'grocery',
          },
        ],
      );

      await tester.pumpWidget(_buildTestApp(data, locale: const Locale('ar')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      // Business-type banner is shown, while Home & Grocery banners are excluded.
      expect(find.byType(VerticalPromoBanners), findsOneWidget);
      expect(find.text('خصومات المطاعم'), findsOneWidget);
      expect(find.text('عرض الصفحة الرئيسية'), findsNothing);
      expect(find.text('عروض السوبرماركت'), findsNothing);

      // Compact horizontal VendorCard rows render cleanly with Arabic names.
      final cardFinder = find.byType(VendorCard);
      expect(cardFinder, findsAtLeastNWidgets(2));
      expect(find.text('برجر كينج'), findsAtLeastNWidgets(1));
      expect(find.text('بلبن'), findsAtLeastNWidgets(1));

      // Each store card takes a compact horizontal slice (< 140px tall).
      final firstCardSize = tester.getSize(cardFinder.first);
      expect(firstCardSize.height, lessThan(140));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hides VerticalPromoBanners when no ads target the business type and renders cleanly in English LTR',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = _sampleData(
        promotions: const [
          {
            'id': 'p-home',
            'title': 'Home Only',
            'imageUrl': '',
            'type': 'BANNER',
            'verticalId': null,
            'verticalSlug': null,
          },
        ],
      );

      await tester.pumpWidget(_buildTestApp(data, locale: const Locale('en')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(VerticalPromoBanners), findsNothing);
      expect(find.byType(VendorCard), findsAtLeastNWidgets(2));
      expect(find.text('Burger King'), findsAtLeastNWidgets(1));
      expect(find.text('Open'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    },
  );
}
