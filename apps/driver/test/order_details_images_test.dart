import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeConfig extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

void main() {
  testWidgets(
    'Driver OrderDetailsBottomSheet displays per-stop vendor logos and product images for multi-vendor & missing-image fallbacks',
    (tester) async {
      final mvOrder = <String, dynamic>{
        'id': 'ord-drv-mv-1',
        'orderNumber': 'ORD-DRV-88',
        'type': 'STANDARD',
        'status': 'READY_FOR_PICKUP',
        'paymentMethod': 'CASH_ON_DELIVERY',
        'grandTotal': 340.0,
        'deliveryFee': 30.0,
        'customer': {
          'name': 'Youssef',
          'phone': '01055566677',
          'avatar': 'https://cdn.otlob-test.invalid/users/youssef.png',
        },
        'vendorFulfillments': [
          {
            'id': 'ff-1',
            'status': 'READY_FOR_PICKUP',
            'subtotal': 160.0,
            'vendor': {
              'id': 'v-1',
              'storeName': 'Grill Master',
              'logo': 'https://cdn.otlob-test.invalid/vendors/grill.png',
            },
            'vendorBranch': {'name': 'Zamalek', 'address': '26 July St'},
          },
          {
            'id': 'ff-2',
            'status': 'PREPARING',
            'subtotal': 150.0,
            'vendor': {
              'id': 'v-2',
              'storeName': 'Juice Lab',
              'logo': null,
            },
            'vendorBranch': {'name': 'Mohandessin', 'address': 'Gameat St'},
          },
        ],
        // Empty f['items'] deliberately exercises fulfillmentId lookup from order['items']
        'items': [
          {
            'id': 'i-1',
            'fulfillmentId': 'ff-1',
            'productName': 'Smash Burger',
            'variantName': 'Double',
            'quantity': 1,
            'unitPrice': 160.0,
            'product': {
              'imageUrl': 'https://cdn.otlob-test.invalid/products/smash.png',
            },
          },
          {
            'id': 'i-2',
            'fulfillmentId': 'ff-2',
            'productName': 'Mango Smoothie',
            'quantity': 2,
            'unitPrice': 75.0,
            'product': {'imageUrl': null},
          },
        ],
      };

      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
            configurationProvider.overrideWith(_FakeConfig.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: OrderDetailsBottomSheet(order: mvOrder),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Stop 1 Items (Grill Master)'), findsOneWidget);
      expect(find.text('Stop 2 Items (Juice Lab)'), findsOneWidget);
      expect(find.text('Smash Burger'), findsOneWidget);
      expect(find.text('Double'), findsOneWidget);
      expect(find.text('Mango Smoothie'), findsOneWidget);

      final cachedUrls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((w) => w.imageUrl)
          .toList();
      expect(
        cachedUrls,
        containsAll([
          'https://cdn.otlob-test.invalid/users/youssef.png',
          'https://cdn.otlob-test.invalid/products/smash.png',
        ]),
      );

      final netLogoUrls = tester
          .widgetList<Image>(find.byType(Image))
          .where((img) => img.image is NetworkImage)
          .map((img) => (img.image as NetworkImage).url)
          .toList();
      expect(
        netLogoUrls,
        contains('https://cdn.otlob-test.invalid/vendors/grill.png'),
      );

      // Missing vendor logo and missing product image show fallback icons cleanly
      expect(find.byIcon(LucideIcons.store), findsWidgets);
      expect(find.byIcon(LucideIcons.package), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
