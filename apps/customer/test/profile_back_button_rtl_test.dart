import 'dart:convert';
import 'dart:io';

import 'package:data/providers.dart' as data_providers;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otlob_customer/core/providers/app_settings_provider.dart';
import 'package:otlob_customer/core/router/route_paths.dart';
import 'package:otlob_customer/core/services/token_service.dart';
import 'package:otlob_customer/features/auth/presentation/providers/auth_controller.dart';
import 'package:otlob_customer/features/cart/presentation/providers/cart_controller.dart';
import 'package:otlob_customer/features/profile/presentation/pages/profile_screen.dart';
import 'package:otlob_customer/features/profile/presentation/providers/coin_history_provider.dart';
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

class _FakeAuthController extends AuthController {
  @override
  AuthStatus build() => AuthStatus.authenticated;
}

class _FakeAppSettings extends AppSettings {
  final String languageCode;
  _FakeAppSettings(this.languageCode);

  @override
  AppSettingsState build() => AppSettingsState(
        themeMode: ThemeMode.dark,
        languageCode: languageCode,
        hasSeenOnboarding: true,
      );
}

class _FakeProfile extends Profile {
  final bool isArabic;
  _FakeProfile({required this.isArabic});

  @override
  ProfileState build() => ProfileState(
        name: 'Test Customer',
        email: 'customer@otlob.app',
        phone: '+201000000000',
        avatar: '',
        isArabic: isArabic,
      );
}

class _FakeSharedNotificationSettings
    extends data_providers.SharedNotificationSettings {
  @override
  AsyncValue<dynamic> build() => const AsyncValue.data({'pushEnabled': true});

  @override
  Future<void> fetchSettings() async {}
}

class _FakeCoinHistory extends CoinHistory {
  @override
  CoinHistoryState build() => CoinHistoryState(currentBalance: 120);
}

class _FakeCart extends Cart {
  @override
  CartState build() => const CartState(vendorBaskets: {});
}

Future<void> _pumpRouterWithProfile(
  WidgetTester tester, {
  required Locale locale,
  required String initialLocation,
}) async {
  SharedPreferences.setMockInitialValues({});
  dotenv.loadFromString(envString: 'API_URL=https://example.invalid');
  await EasyLocalization.ensureInitialized();

  const viewport = Size(320, 640);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push('/profile'),
              child: const Text('OPEN_PROFILE'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  final isArabic = locale.languageCode == 'ar';

  await tester.pumpWidget(
    EasyLocalization(
      key: ValueKey('ez-${locale.languageCode}-$initialLocation'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'translations',
      fallbackLocale: const Locale('ar'),
      startLocale: locale,
      saveLocale: false,
      assetLoader: const _TestAssetLoader(),
      child: ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          appSettingsProvider.overrideWith(
            () => _FakeAppSettings(locale.languageCode),
          ),
          profileProvider.overrideWith(() => _FakeProfile(isArabic: isArabic)),
          data_providers.sharedNotificationSettingsProvider.overrideWith(
            _FakeSharedNotificationSettings.new,
          ),
          coinHistoryProvider.overrideWith(_FakeCoinHistory.new),
          cartProvider.overrideWith(_FakeCart.new),
          accessTokenProvider.overrideWith((ref) async => 'test-token'),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp.router(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              routerConfig: router,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: viewport,
                    padding: const EdgeInsets.only(top: 47, bottom: 34),
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      'ProfileScreen back button receives hit-tests and pops route in ${locale.languageCode}',
      (tester) async {
        await _pumpRouterWithProfile(
          tester,
          locale: locale,
          initialLocation: RoutePaths.home,
        );

        await tester.tap(find.text('OPEN_PROFILE'));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(ProfileScreen))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );

        final backIconFinder = find.byIcon(Icons.arrow_back_ios_new_rounded);
        expect(backIconFinder, findsOneWidget);

        final backCenter = tester.getCenter(backIconFinder);
        expect(backCenter.dy, greaterThan(47));
        if (locale.languageCode == 'ar') {
          expect(backCenter.dx, greaterThan(160));
        } else {
          expect(backCenter.dx, lessThan(160));
        }

        await tester.tap(backIconFinder);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ProfileScreen), findsNothing);
        expect(find.text('OPEN_PROFILE'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'ProfileScreen back button falls back to RoutePaths.home when opened without stack history in ar',
    (tester) async {
      await _pumpRouterWithProfile(
        tester,
        locale: const Locale('ar'),
        initialLocation: '/profile',
      );

      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.text('OPEN_PROFILE'), findsOneWidget);
    },
  );
}
