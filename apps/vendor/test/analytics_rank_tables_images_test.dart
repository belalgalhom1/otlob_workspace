import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/analytics/presentation/widgets/product_rank_table.dart';
import 'package:vendor/features/analytics/presentation/widgets/vendor_rank_table.dart';
import 'package:vendor/features/analytics/providers/analytics_provider.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

Widget _wrapWithApp({
  required Widget child,
  required List<dynamic> overrides,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_URL=https://api.otlob-egy.online');
  });

  testWidgets(
    'VendorRankTable displays formatted coverImage fallback and top product thumbnail',
    (tester) async {
      final vendor = AnalyticsVendor(
        id: 'v-1',
        storeName: 'Burger King',
        storeNameAr: 'برجر كينج',
        logo: null,
        coverImage: '/media/vendors/covers/bk.webp',
        walletBalance: 1143,
        totalOrders: 12,
        totalRevenue: 1270,
        topProduct: AnalyticsTopProduct(
          name: 'Whopper',
          nameAr: 'وابر',
          imageUrl: '/media/products/images/whopper.webp',
          totalOrders: 14,
        ),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          overrides: [
            topVendorsProvider.overrideWith((ref) async => [vendor]),
          ],
          child: const VendorRankTable(),
        ),
      );
      await tester.pump();
      await tester.pump();

      final avatars = tester
          .widgetList<AppNetworkAvatar>(find.byType(AppNetworkAvatar))
          .toList();
      expect(avatars.length, 2);
      expect(
        avatars[0].imageUrl,
        ImageUtils.formatImageUrl('/media/vendors/covers/bk.webp'),
      );
      expect(
        AppNetworkAvatar.normalizeHttpUrl(avatars[0].imageUrl),
        isNotNull,
      );
      expect(
        avatars[1].imageUrl,
        ImageUtils.formatImageUrl('/media/products/images/whopper.webp'),
      );
      expect(
        AppNetworkAvatar.normalizeHttpUrl(avatars[1].imageUrl),
        isNotNull,
      );
    },
  );

  testWidgets(
    'ProductRankTable formats relative product imageUrl into a valid network URL',
    (tester) async {
      final product = AnalyticsTopProduct(
        name: 'Panadol tab',
        nameAr: 'بنادول',
        imageUrl: '/media/products/images/panadol.webp',
        totalOrders: 9,
      );

      await tester.pumpWidget(
        _wrapWithApp(
          locale: const Locale('ar'),
          overrides: [
            topProductsProvider.overrideWith((ref) async => [product]),
          ],
          child: const ProductRankTable(),
        ),
      );
      await tester.pump();
      await tester.pump();

      final avatar = tester.widget<AppNetworkAvatar>(
        find.byType(AppNetworkAvatar),
      );
      expect(
        avatar.imageUrl,
        ImageUtils.formatImageUrl('/media/products/images/panadol.webp'),
      );
      expect(AppNetworkAvatar.normalizeHttpUrl(avatar.imageUrl), isNotNull);
      expect(find.text('بنادول'), findsOneWidget);
    },
  );
}
