import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/core/l10n/app_strings.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/home/presentation/widgets/product_bottom_sheet.dart';
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

class _UnauthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;
}

class _FakeAuthRepo extends Fake implements SharedAuthRepository {
  @override
  Future<bool> isLoggedIn() async => false;
}

class _FakeCartRepo extends Fake implements CustomerCartRepository {
  @override
  Future<dynamic> getMyCarts() async => [];
}

void main() {
  testWidgets(
    'ProductBottomSheet starts with product image and swaps hero image only when user explicitly selects a variant',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      const productUrl = 'https://example.com/product.png';
      const variant1Url = 'https://example.com/variant1.png';

      final item = <String, dynamic>{
        'id': 'prod-1',
        'name': 'Qashtouta',
        'nameAr': 'قشطوطة',
        'imageUrl': productUrl,
        'hasVariants': true,
        'variants': [
          {
            'id': 'var-1',
            'name': 'Variant With Image',
            'price': 20,
            'basePrice': 20,
            'imageUrl': variant1Url,
          },
          {
            'id': 'var-2',
            'name': 'Variant Without Image',
            'price': 30,
            'basePrice': 30,
            'imageUrl': null,
          },
        ],
        'optionGroups': <dynamic>[],
      };

      final restaurant = <String, dynamic>{
        'id': 'vend-1',
        'storeName': 'B.Laban',
      };

      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baseUrlProvider.overrideWithValue('https://example.com'),
            authControllerProvider.overrideWith(_UnauthController.new),
            data_providers.sharedAuthRepositoryProvider
                .overrideWithValue(_FakeAuthRepo()),
            data_providers.customerCartRepositoryProvider
                .overrideWithValue(_FakeCartRepo()),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            path: 'packages/core/assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            assetLoader: const _TestAssetLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: Builder(
                    builder: (innerCtx) => ProductBottomSheet(
                      item: item,
                      restaurant: restaurant,
                      initialUnit: 'package',
                      s: AppStrings.of(innerCtx),
                      isDark: false,
                      isPharmacy: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // 1. On open, even though var-1 is auto-selected, hero shows productUrl.
      expect(find.byKey(const ValueKey(productUrl)), findsOneWidget);
      expect(find.byKey(const ValueKey(variant1Url)), findsNothing);

      // 2. When user explicitly taps Variant With Image, hero swaps to variant1Url.
      await tester.tap(find.text('Variant With Image'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey(variant1Url)), findsOneWidget);
      expect(find.byKey(const ValueKey(productUrl)), findsNothing);

      // 3. When user taps Variant Without Image, hero falls back to productUrl.
      await tester.tap(find.text('Variant Without Image'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey(productUrl)), findsOneWidget);
      expect(find.byKey(const ValueKey(variant1Url)), findsNothing);
    },
  );

  testWidgets(
    'ProductBottomSheet pre-selects first in-stock variant, honors initialVariantId, and checks non-required minSelect',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      final item = <String, dynamic>{
        'id': 'prod-2',
        'name': 'Pizza',
        'nameAr': 'بيتزا',
        'imageUrl': 'https://example.com/pizza.png',
        'hasVariants': true,
        'variants': [
          {
            'id': 'var-out',
            'name': 'Sold Out Small',
            'price': 50,
            'basePrice': 50,
            'stock': 0,
            'tracksStock': true,
          },
          {
            'id': 'var-in',
            'name': 'In Stock Medium',
            'price': 80,
            'basePrice': 80,
            'stock': 3,
            'tracksStock': true,
          },
          {
            'id': 'var-third',
            'name': 'Family Large',
            'price': 120,
            'basePrice': 120,
            'stock': 5,
            'tracksStock': true,
          },
        ],
        'optionGroups': <dynamic>[
          {
            'id': 'grp-min2',
            'name': 'Pick 2 Sauces',
            'isRequired': false,
            'minSelect': 2,
            'maxSelect': 2,
            'options': [
              {'id': 'opt-a', 'name': 'Ranch', 'priceAdded': 0},
              {'id': 'opt-b', 'name': 'BBQ', 'priceAdded': 0},
            ],
          },
        ],
      };

      final restaurant = <String, dynamic>{
        'id': 'vend-1',
        'storeName': 'Pizza Place',
      };

      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> pumpSheet({String? initialVariantId}) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              baseUrlProvider.overrideWithValue('https://example.com'),
              authControllerProvider.overrideWith(_UnauthController.new),
              data_providers.sharedAuthRepositoryProvider
                  .overrideWithValue(_FakeAuthRepo()),
              data_providers.customerCartRepositoryProvider
                  .overrideWithValue(_FakeCartRepo()),
            ],
            child: EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('ar')],
              path: 'packages/core/assets/translations',
              fallbackLocale: const Locale('en'),
              startLocale: const Locale('en'),
              assetLoader: const _TestAssetLoader(),
              child: Builder(
                builder: (context) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: Scaffold(
                    body: Builder(
                      builder: (innerCtx) => ProductBottomSheet(
                        key: ValueKey(initialVariantId ?? 'default'),
                        item: item,
                        restaurant: restaurant,
                        initialUnit: 'package',
                        initialVariantId: initialVariantId,
                        s: AppStrings.of(innerCtx),
                        isDark: false,
                        isPharmacy: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
      }

      // First in-stock variant (var-in, 80 EGP) is selected automatically, skipping var-out (50 EGP).
      await pumpSheet();
      expect(find.textContaining('80 '), findsNWidgets(2)); // header price + var-in chip
      // Since minSelect=2 even though isRequired=false, button requires option selection first.
      expect(find.text('Select Required Options'), findsOneWidget);

      // Selecting both options satisfies minSelect=2 and enables Add to Cart.
      await tester.ensureVisible(find.text('Ranch'));
      await tester.pump();
      await tester.tap(find.text('Ranch'));
      await tester.pump();
      await tester.ensureVisible(find.text('BBQ'));
      await tester.pump();
      await tester.tap(find.text('BBQ'));
      await tester.pump();
      expect(find.text('Add to Cart'), findsOneWidget);

      // Passing initialVariantId='var-third' pre-selects var-third (120 EGP).
      await pumpSheet(initialVariantId: 'var-third');
      expect(find.textContaining('120 '), findsNWidgets(2));
    },
  );
}
