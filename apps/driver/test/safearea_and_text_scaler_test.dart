import 'package:data/data.dart';
import 'package:driver/core/providers/app_preferences_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/auth/presentation/pages/login_screen.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/legal/presentation/pages/terms_acceptance_gate_screen.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';
import 'package:driver/features/orders/presentation/driver_orders_history_provider.dart';
import 'package:driver/features/orders/presentation/pages/deliveries_history_screen.dart';
import 'package:driver/features/profile/presentation/pages/suspended_screen.dart';
import 'package:driver/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeDriverWallet extends DriverWallet {
  final Map<String, dynamic> initialData;
  _FakeDriverWallet(this.initialData);

  @override
  AsyncValue<Map<String, dynamic>> build() => AsyncValue.data(initialData);
}

class _FakeDriverProfile extends DriverProfile {
  final Map<String, dynamic> profile;
  _FakeDriverProfile(this.profile);

  @override
  AsyncValue<dynamic> build() => AsyncValue.data(profile);
}

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

class _FailingLegalDocsRepo extends Fake
    implements SharedLegalDocumentsRepository {
  @override
  Future<Map<String, dynamic>?> getActiveDocument(String type) async {
    throw Exception('network error');
  }
}

class _FakeDriverAuth extends Auth {
  @override
  AsyncValue<bool> build() => const AsyncValue.data(false);
}

class _FakeDriverPreferences extends AppPreferences {
  final Locale locale;
  _FakeDriverPreferences(this.locale);

  @override
  AppPreferencesState build() =>
      AppPreferencesState(themeMode: ThemeMode.light, locale: locale);
}

class _FakeDriverOrdersHistory extends DriverOrdersHistory {
  final DriverOrdersHistoryState initialState;
  _FakeDriverOrdersHistory(this.initialState);

  @override
  DriverOrdersHistoryState build() => initialState;

  @override
  Future<void> fetchDeliveries({bool isRefresh = false}) async {}

  @override
  Future<void> loadMore() async {}
}

class _FakeDriverOrdersRepository extends Fake
    implements DriverOrdersRepository {
  @override
  Future<dynamic> getMyAssistRequests() async => const <dynamic>[];
}

Future<void> _pumpDriverWidget(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
  Size viewport = const Size(360, 640),
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  TextScaler textScaler = const TextScaler.linear(1.3),
  List<dynamic> overrides = const [],
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: viewport,
            padding: padding,
            textScaler: textScaler,
          ),
          child: AppWindowConstraintGuard(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'Driver WalletScreen renders negative-balance action buttons without overflow at 1.3x scale on 360px (${locale.languageCode})',
      (tester) async {
        await _pumpDriverWidget(
          tester,
          locale: locale,
          overrides: [
            driverWalletProvider.overrideWith(
              () => _FakeDriverWallet({
                'balance': -1250.5,
                'transactions': const [],
                'platformWallets': const [],
                'driverWallets': const [],
                'topUpRequests': const [],
              }),
            ),
            driverProfileProvider.overrideWith(
              () => _FakeDriverProfile({'hasUnpaidCommission': true}),
            ),
            configurationProvider.overrideWith(_FakeConfiguration.new),
          ],
          child: const WalletScreen(),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.text(
            locale.languageCode == 'ar' ? 'سداد وتوريد النقدية' : 'Settle Dues',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Driver SuspendedScreen renders long outstanding balance cleanly at 1.3x scale with SafeArea (${locale.languageCode})',
      (tester) async {
        await _pumpDriverWidget(
          tester,
          locale: locale,
          overrides: [
            driverWalletProvider.overrideWith(
              () => _FakeDriverWallet({
                'balance': -99999.0,
                'platformWallets': const [],
                'topUpRequests': const [],
              }),
            ),
            driverProfileProvider.overrideWith(
              () => _FakeDriverProfile({'hasUnpaidCommission': true}),
            ),
            configurationProvider.overrideWith(_FakeConfiguration.new),
          ],
          child: const SuspendedScreen(),
        );

        expect(tester.takeException(), isNull);
        final expectedCurr = locale.languageCode == 'ar' ? 'ج.م' : 'EGP';
        expect(find.text('99999.00 $expectedCurr'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Driver TermsAcceptanceGateScreen error view respects SafeArea & 1.3x scale',
    (tester) async {
      await _pumpDriverWidget(
        tester,
        locale: const Locale('ar'),
        overrides: [
          sharedLegalDocumentsRepositoryProvider.overrideWithValue(
            _FailingLegalDocsRepo(),
          ),
        ],
        child: const TermsAcceptanceGateScreen(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text('تسجيل الخروج'), findsOneWidget);

      final scrollRect = tester.getRect(find.byType(SingleChildScrollView));
      expect(scrollRect.top, greaterThanOrEqualTo(47.0));
      expect(scrollRect.bottom, lessThanOrEqualTo(640.0 - 34.0));
    },
  );

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final entry in const [
      (viewport: Size(320, 568), scale: 0.85),
      (viewport: Size(360, 640), scale: 1.3),
    ]) {
      testWidgets(
        'Driver LoginScreen respects extendBodyBehindAppBar SafeArea at ${entry.viewport.width.toInt()}x${entry.viewport.height.toInt()} & ${entry.scale}x (${locale.languageCode})',
        (tester) async {
          await _pumpDriverWidget(
            tester,
            locale: locale,
            viewport: entry.viewport,
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(entry.scale),
            overrides: [
              authProvider.overrideWith(() => _FakeDriverAuth()),
              appPreferencesProvider.overrideWith(
                () => _FakeDriverPreferences(locale),
              ),
            ],
            child: const LoginScreen(),
          );

          expect(tester.takeException(), isNull);
          final scrollFinder = find.byType(SingleChildScrollView);
          expect(scrollFinder, findsOneWidget);
        },
      );
    }

    testWidgets(
      'DeliveriesHistoryScreen handles narrow 320px width, 1.3x scale, and bottom SafeArea (${locale.languageCode})',
      (tester) async {
        await _pumpDriverWidget(
          tester,
          locale: locale,
          viewport: const Size(320, 640),
          padding: const EdgeInsets.only(top: 47, bottom: 34),
          textScaler: const TextScaler.linear(1.3),
          overrides: [
            configurationProvider.overrideWith(() => _FakeConfiguration()),
            driverOrdersHistoryProvider.overrideWith(
              () => _FakeDriverOrdersHistory(
                DriverOrdersHistoryState(
                  isLoading: false,
                  orders: [
                    {
                      'id': 'ord-hist-1',
                      'orderNumber': 'ORD-2026-MULTI-88421',
                      'type': 'RIDE',
                      'deliveryFee': 185.50,
                      'createdAt': '2026-11-15T18:30:00Z',
                      'vendor': {
                        'storeName': 'Ultra Long Multi-Store Gourmet Super Market Branch',
                        'storeNameAr': 'سوبر ماركت ومتاجر متعددة فاخرة الفرع الرئيسي',
                      },
                      'deliveryAddress':
                          'Apartment 14B, Building 27, Extended Boulevard District, Cairo',
                    },
                  ],
                ),
              ),
            ),
          ],
          child: const DeliveriesHistoryScreen(),
        );

        expect(tester.takeException(), isNull);
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding?.resolve(TextDirection.ltr).bottom, 50.0);
      },
    );

    testWidgets(
      'OrderDetailsBottomSheet renders multi-store cash, earnings, and pickup statuses on 320px at 1.3x (${locale.languageCode})',
      (tester) async {
        await _pumpDriverWidget(
          tester,
          locale: locale,
          viewport: const Size(320, 640),
          padding: const EdgeInsets.only(top: 47, bottom: 34),
          textScaler: const TextScaler.linear(1.3),
          overrides: [
            configurationProvider.overrideWith(() => _FakeConfiguration()),
            driverOrdersRepositoryProvider.overrideWithValue(
              _FakeDriverOrdersRepository(),
            ),
          ],
          child: Scaffold(
            body: OrderDetailsBottomSheet(
              order: {
                'id': 'ord-det-1',
                'orderNumber': 'ORD-99812',
                'status': 'ON_THE_WAY',
                'paymentMethod': 'CASH_ON_DELIVERY',
                'total': 540.0,
                'subtotal': 460.0,
                'deliveryFee': 80.0,
                'driverEarnings': 56.0,
                'customer': {'name': 'Omar Khaled', 'phone': '+201001234567'},
                'deliveryAddress': 'Building 9, District 5, New Cairo',
                'items': [
                  {
                    'quantity': 2,
                    'price': 230.0,
                    'product': {
                      'name': 'Family Feast Combo Box',
                      'nameAr': 'صندوق وليمة عائلية',
                    },
                  },
                ],
                'financials': {
                  'isPrepaid': false,
                  'cashToCollect': 540.0,
                  'cashToPayStore': 414.0,
                  'deliveryFee': 80.0,
                  'driverEarnings': 56.0,
                  'storePayments': [
                    {
                      'vendorName': 'Al-Madina Bakery & Sweets Main Branch',
                      'isContracted': true,
                      'cashToPay': 210.0,
                    },
                    {
                      'vendorName': 'Fresh Market Roastery Central Store',
                      'isContracted': false,
                      'cashToPay': 204.0,
                    },
                  ],
                },
                'vendorFulfillments': [
                  {
                    'status': 'READY_FOR_PICKUP',
                    'vendor': {
                      'storeName': 'Al-Madina Bakery & Sweets',
                      'storeNameAr': 'مخبز وحلويات المدينة',
                    },
                    'vendorBranch': {
                      'name': 'Main Branch Downtown',
                      'nameAr': 'الفرع الرئيسي وسط البلد',
                    },
                  },
                  {
                    'status': 'PREPARING',
                    'vendor': {
                      'storeName': 'Fresh Market Roastery',
                      'storeNameAr': 'محمصة السوق الطازج',
                    },
                    'vendorBranch': {
                      'name': 'Central Store',
                      'nameAr': 'المتجر المركزي',
                    },
                  },
                ],
              },
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(OrderDetailsBottomSheet), findsOneWidget);
      },
    );
  }
}
