import 'package:core/core.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

Future<void> _pumpOrderDetailsSheet(
  WidgetTester tester, {
  required Map<String, dynamic> order,
  required Locale locale,
  Size viewport = const Size(320, 640),
  TextScaler textScaler = const TextScaler.linear(1.4),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
        configurationProvider.overrideWith(_FakeConfiguration.new),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: viewport,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            textScaler: textScaler,
          ),
          child: AppWindowConstraintGuard(
            child: Scaffold(
              body: OrderDetailsBottomSheet(order: order),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'Single-vendor OrderDetailsBottomSheet displays Image.network for vendor logo and falls back cleanly on missing/failed image (${locale.languageCode})',
      (tester) async {
        final orderWithLogo = <String, dynamic>{
          'id': 'ord-single-logo',
          'orderNumber': 'ORD-SINGLE-001',
          'type': 'VENDOR',
          'status': 'PICKED_UP',
          'totalPrice': 140.0,
          'deliveryFee': 25.0,
          'paymentMethod': 'CASH',
          'customer': {'name': 'Omar', 'phone': '01012345678'},
          'vendor': {
            'storeName': 'Gourmet Burger House',
            'phone': '01099887766',
            'logo': 'https://cdn.otlob-test.invalid/vendors/burger-logo.png',
          },
          'vendorBranch': {
            'name': 'Nasr City',
            'nameAr': 'مدينة نصر',
            'address': '12 Abbas El Akkad St, Cairo',
          },
          'items': [
            {
              'quantity': 2,
              'price': 57.5,
              'product': {'name': 'Classic Burger', 'nameAr': 'برجر كلاسيك'},
            },
          ],
        };

        await _pumpOrderDetailsSheet(
          tester,
          order: orderWithLogo,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsWidgets);

        final netImages = tester
            .widgetList<Image>(find.byType(Image))
            .where((img) => img.image is NetworkImage)
            .map((img) => (img.image as NetworkImage).url)
            .toList();
        expect(
          netImages,
          contains('https://cdn.otlob-test.invalid/vendors/burger-logo.png'),
        );

        // Allow failed test-env HTTP image errorBuilder to paint LucideIcons.store fallback.
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(LucideIcons.store), findsWidgets);

        // Now verify explicit missing logo renders fallback avatar directly without Image.network.
        final orderWithoutLogo = <String, dynamic>{
          ...orderWithLogo,
          'vendor': {
            'storeName': 'No Logo Bakery',
            'phone': '01099887766',
            'logo': '',
          },
        };
        await _pumpOrderDetailsSheet(
          tester,
          order: orderWithoutLogo,
          locale: locale,
          viewport: const Size(320, 640),
          textScaler: const TextScaler.linear(1.5),
        );
        expect(tester.takeException(), isNull);
        final remainingNetImages = tester
            .widgetList<Image>(find.byType(Image))
            .where((img) => img.image is NetworkImage);
        expect(remainingNetImages, isEmpty);
        expect(find.byIcon(LucideIcons.store), findsWidgets);
      },
    );

    testWidgets(
      'Multi-vendor OrderDetailsBottomSheet shows vendor profile picture per stop and Stop Items header with fallback (${locale.languageCode})',
      (tester) async {
        final multiVendorOrder = <String, dynamic>{
          'id': 'ord-multi-logo',
          'orderNumber': 'ORD-MULTI-002',
          'type': 'VENDOR',
          'status': 'PICKED_UP',
          'totalPrice': 220.0,
          'deliveryFee': 30.0,
          'paymentMethod': 'CASH',
          'customer': {'name': 'Mona', 'phone': '01112223344'},
          'items': [
            {
              'quantity': 1,
              'price': 100.0,
              'product': {'name': 'Box A', 'nameAr': 'صندوق أ'},
            },
            {
              'quantity': 1,
              'price': 100.0,
              'product': {'name': 'Box B', 'nameAr': 'صندوق ب'},
            },
          ],
          'vendorFulfillments': [
            {
              'id': 'ful-1',
              'status': 'PICKED_UP',
              'isContracted': true,
              'subtotal': 100.0,
              'commissionRate': 10.0,
              'vendor': {
                'storeName': 'test2',
                'logo': 'uploads/vendors/store-two.png',
                'phone': '0102876421',
              },
              'vendorBranch': {
                'name': 'haha',
                'nameAr': 'هاها',
                'address': '10 Tahrir Square',
              },
              'items': [
                {
                  'quantity': 1,
                  'price': 100.0,
                  'product': {'name': 'Box A', 'nameAr': 'صندوق أ'},
                },
              ],
            },
            {
              'id': 'ful-2',
              'status': 'PICKED_UP',
              'isContracted': true,
              'subtotal': 100.0,
              'commissionRate': 10.0,
              'vendor': {
                'storeName': 'test',
                'logo': null,
                'phone': '01132123398',
              },
              'vendorBranch': {
                'name': 'Abu zabaal',
                'nameAr': 'أبو زعبل',
                'address': 'Abu zabaal main road',
              },
              'items': [
                {
                  'quantity': 1,
                  'price': 100.0,
                  'product': {'name': 'Box B', 'nameAr': 'صندوق ب'},
                },
              ],
            },
          ],
        };

        await _pumpOrderDetailsSheet(
          tester,
          order: multiVendorOrder,
          locale: locale,
          viewport: const Size(320, 640),
          textScaler: const TextScaler.linear(1.4),
        );

        expect(tester.takeException(), isNull);

        // Stop 1 pickup card renders its vendor avatar above the fold.
        int countResolvedLogoImages() => tester
            .widgetList<Image>(find.byType(Image))
            .where((img) => img.image is NetworkImage)
            .map((img) => (img.image as NetworkImage).url)
            .where((url) => url.endsWith('/uploads/vendors/store-two.png'))
            .length;

        expect(countResolvedLogoImages(), greaterThanOrEqualTo(2));

        // Stop 1 Items header is built inside the sheet with Store 1's avatar.
        final stop1HeaderFinder = find.textContaining('(test2)');
        expect(stop1HeaderFinder, findsOneWidget);

        // Stop 2 has null logo -> LucideIcons.store fallback is shown.
        expect(find.byIcon(LucideIcons.store), findsWidgets);

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
