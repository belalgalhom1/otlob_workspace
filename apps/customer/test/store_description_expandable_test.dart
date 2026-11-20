import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/home/presentation/pages/restaurant_detail_screen.dart';
import 'package:otlob_customer/features/home/presentation/widgets/vendor_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit/ui_kit.dart' show AppExpandableText;

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

class _UnauthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;
}

class _FakeVendorsRepo extends Fake implements CustomerVendorsRepository {
  final Map<String, dynamic> vendorPayload;
  _FakeVendorsRepo(this.vendorPayload);

  @override
  Future<dynamic> getVendor(String id, {String? branchId}) async =>
      Map<String, dynamic>.from(vendorPayload);
}

Map<String, dynamic> _burgerKingVendor({required bool longDescription}) => {
      'id': 'v-bk-1',
      'storeName': 'Burger King',
      'storeNameAr': 'برجر كينج',
      'description': longDescription
          ? 'Burger King Restaurant 🍔👑\n\n'
              'Our burgers are fresh every day, straight from the grill.\n'
              'Cleanliness, perfect taste, and affordable prices.\n'
              'We have everything you crave: burgers, crispy chicken, fries, and meals for the whole family.\n'
              'Come and try it yourself, and the taste will speak for itself.'
          : 'Fresh flame-grilled burgers.',
      'descriptionAr': longDescription
          ? 'مطعم برجر كينج 🍔👑\n\n'
              'برجر طازج كل يوم مشوي على اللهب مباشرة.\n'
              'نظافة وجودة عالية وطعم رائع بأسعار مناسبة للجميع.\n'
              'لدينا كل ما تحبه من البرجر والدجاج المقرمش والبطاطس ووجبات العائلة.\n'
              'تفضل بزيارتنا وجرب بنفسك والطعم سيتحدث عن نفسه.'
          : 'برجر طازج مشوي على اللهب.',
      'rating': 5.0,
      'ratingCount': 1,
      'status': 'OPEN',
      'branches': [
        {'id': 'br-1', 'name': 'haha', 'nameAr': 'الفرع الرئيسي', 'address': 'bH', 'isOpen': true},
      ],
      'categories': <dynamic>[],
    };

void main() {
  testWidgets(
    'VendorDetailScreen previews long description with Read more -> expands cleanly to Read less -> collapses back (EN)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      final payload = _burgerKingVendor(longDescription: true);
      tester.view.physicalSize = const Size(360, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_UnauthController.new),
            data_providers.customerVendorsRepositoryProvider
                .overrideWithValue(_FakeVendorsRepo(payload)),
          ],
          child: EasyLocalization(
            key: UniqueKey(),
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'unused',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            useOnlyLangCode: true,
            assetLoader: const _CatalogAssetLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                theme: ThemeData.dark(),
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: VendorDetailScreen(restaurant: payload),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Burger King'), findsOneWidget);
      expect(find.byType(AppExpandableText), findsOneWidget);
      expect(find.text('Read more'), findsOneWidget);
      expect(find.text('Read less'), findsNothing);

      final collapsedHeight =
          tester.getSize(find.byType(AppExpandableText)).height;

      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();

      expect(find.text('Read less'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);
      final expandedHeight =
          tester.getSize(find.byType(AppExpandableText)).height;
      expect(expandedHeight, greaterThan(collapsedHeight));

      await tester.ensureVisible(find.text('Read less'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read less'));
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppExpandableText)).height,
        collapsedHeight,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'VendorDetailScreen supports Arabic RTL Read more / Read less and hides button for short descriptions',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      final longArPayload = _burgerKingVendor(longDescription: true);
      tester.view.physicalSize = const Size(360, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_UnauthController.new),
            data_providers.customerVendorsRepositoryProvider
                .overrideWithValue(_FakeVendorsRepo(longArPayload)),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'unused',
            fallbackLocale: const Locale('ar'),
            startLocale: const Locale('ar'),
            useOnlyLangCode: true,
            assetLoader: const _CatalogAssetLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: VendorDetailScreen(restaurant: longArPayload),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اقرأ المزيد'), findsOneWidget);
      await tester.tap(find.text('اقرأ المزيد'));
      await tester.pumpAndSettle();
      expect(find.text('عرض أقل'), findsOneWidget);

      // Short description omits Read more/less entirely.
      final shortPayload = _burgerKingVendor(longDescription: false)
        ..['id'] = 'v-bk-short';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_UnauthController.new),
            data_providers.customerVendorsRepositoryProvider
                .overrideWithValue(_FakeVendorsRepo(shortPayload)),
          ],
          child: EasyLocalization(
            key: UniqueKey(),
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'unused',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            useOnlyLangCode: true,
            assetLoader: const _CatalogAssetLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: VendorDetailScreen(restaurant: shortPayload),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fresh flame-grilled burgers.'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);
      expect(find.text('Read less'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'VendorCard expands/collapses description via Read more without triggering card navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();

      var navigatedToVendor = false;
      final vendor = _burgerKingVendor(longDescription: true)
        ..['name'] = 'Burger King'
        ..['nameAr'] = 'برجر كينج'
        ..['vendor'] = _burgerKingVendor(longDescription: true)['description']
        ..['vendorAr'] =
            _burgerKingVendor(longDescription: true)['descriptionAr'];

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: VendorCard(vendor: vendor),
              ),
            ),
          ),
          GoRoute(
            path: '/vendor',
            builder: (_, _) {
              navigatedToVendor = true;
              return const Scaffold(body: Text('VENDOR_DETAIL'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_UnauthController.new),
          ],
          child: EasyLocalization(
            key: UniqueKey(),
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'unused',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            useOnlyLangCode: true,
            assetLoader: const _CatalogAssetLoader(),
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
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();

      expect(find.text('Read less'), findsOneWidget);
      expect(navigatedToVendor, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
