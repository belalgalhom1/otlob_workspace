import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlob_customer/features/orders/presentation/widgets/order_tracking_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart';

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

void main() {
  Future<void> pumpTrackingSheet(
    WidgetTester tester, {
    required Map<String, dynamic> orderDetails,
    Locale locale = const Locale('en'),
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        key: UniqueKey(),
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'unused',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        useOnlyLangCode: true,
        assetLoader: const _CatalogAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: OrderTrackingSheetOverlay(
                orderStatus: orderDetails['status']?.toString() ?? 'PREPARING',
                statusLabel: 'Preparing',
                orderDetails: orderDetails,
                tripPathLength: 2,
                followDriver: false,
                onRecenterDriver: () {},
                onOpenChat: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets(
    'Customer Track Order displays each vendor logo in Store Fulfillment Status for single-vendor and multi-vendor orders and falls back when logo is missing',
    (tester) async {
      // 1. Single-vendor with uploaded logo
      await pumpTrackingSheet(
        tester,
        orderDetails: {
          'id': 'ord-sv-1',
          'status': 'PREPARING',
          'vendor': {
            'id': 'v-1',
            'storeName': 'Burger Hub',
            'logo': 'https://cdn.otlob-test.invalid/vendors/burger-hub.png',
          },
          'vendorFulfillments': [
            {
              'id': 'ff-1',
              'status': 'PREPARING',
              'vendor': {
                'id': 'v-1',
                'storeName': 'Burger Hub',
                'logo': 'https://cdn.otlob-test.invalid/vendors/burger-hub.png',
              },
              'vendorBranch': {'name': 'Maadi'},
            },
          ],
        },
      );

      // Expand sheet to inspect Store Fulfillment Status clearly
      await tester.tap(find.text('Preparing').first);
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Burger Hub'), findsOneWidget);
      var cachedUrls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((w) => w.imageUrl)
          .toList();
      expect(
        cachedUrls,
        contains('https://cdn.otlob-test.invalid/vendors/burger-hub.png'),
      );

      // 2. Multi-vendor with 2 uploaded logos and 1 vendor missing a logo
      await pumpTrackingSheet(
        tester,
        orderDetails: {
          'id': 'ord-mv-1',
          'status': 'PREPARING',
          'vendor': null,
          'vendorFulfillments': [
            {
              'id': 'ff-a',
              'status': 'PREPARING',
              'vendor': {
                'id': 'va',
                'storeName': 'Alpha Bakery',
                'logo': 'https://cdn.otlob-test.invalid/vendors/alpha.png',
              },
            },
            {
              'id': 'ff-b',
              'status': 'READY_FOR_PICKUP',
              'vendor': {
                'id': 'vb',
                'storeName': 'Beta Roastery',
                'logo': 'https://cdn.otlob-test.invalid/vendors/beta.png',
              },
            },
            {
              'id': 'ff-c',
              'status': 'PENDING',
              'vendor': {
                'id': 'vc',
                'storeName': 'Gamma Sweets',
                'logo': null,
              },
            },
          ],
        },
      );

      await tester.tap(find.text('Preparing').first);
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Store Fulfillment Status'), findsOneWidget);
      expect(find.text('Alpha Bakery'), findsOneWidget);
      expect(find.text('Beta Roastery'), findsOneWidget);
      expect(find.text('Gamma Sweets'), findsOneWidget);

      cachedUrls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((w) => w.imageUrl)
          .toList();
      expect(
        cachedUrls,
        containsAll([
          'https://cdn.otlob-test.invalid/vendors/alpha.png',
          'https://cdn.otlob-test.invalid/vendors/beta.png',
        ]),
      );
      expect(cachedUrls.length, 2);
      // Missing-logo store renders default storefront icon fallback
      expect(find.byIcon(Icons.storefront_rounded), findsAtLeastNWidgets(2));
      expect(find.byType(AppNetworkAvatar), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
}
