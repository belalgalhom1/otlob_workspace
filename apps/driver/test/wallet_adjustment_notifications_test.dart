import 'package:core/core.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/core/providers/notification_router.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/profile/presentation/pages/suspended_screen.dart';
import 'package:driver/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeDriverWallet extends DriverWallet {
  final Map<String, dynamic> initialData;
  _FakeDriverWallet(this.initialData);

  @override
  AsyncValue<Map<String, dynamic>> build() => AsyncValue.data(initialData);
}

class _FakeDriverProfile extends DriverProfile {
  final Map<String, dynamic> profileData;
  _FakeDriverProfile(this.profileData);

  @override
  AsyncValue<dynamic> build() => AsyncValue.data({'data': profileData});
}

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

Future<void> _pumpDriverWidget(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
  Size viewport = const Size(320, 760),
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
      overrides: [
        baseUrlProvider.overrideWithValue('https://api.otlob-test.invalid'),
        configurationProvider.overrideWith(_FakeConfiguration.new),
        ...overrides,
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
          child: AppWindowConstraintGuard(child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('DriverNotificationRouter unit checks', () {
    test('routes wallet_topup and /wallet payloads to wallet BEFORE requestId assist checks while preserving chat and order', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(driverNotificationRouterProvider.notifier);

      // Payload containing BOTH kind=wallet_topup and requestId must go to wallet
      final parsedTopUp = router.parseTapPayload({
        'kind': 'wallet_topup',
        'requestId': 'topup-55',
        'topUpId': 'topup-55',
        'route': '/wallet',
      });
      expect(parsedTopUp, isNotNull);
      expect(parsedTopUp!.destination, DriverNotificationDestination.wallet);
      expect(parsedTopUp.topUpId, 'topup-55');

      // PAYMENT notification without kind also routes to wallet when topUpId is present
      final parsedPayment = router.parseTapPayload({
        'type': 'PAYMENT',
        'topUpId': 'topup-88',
      });
      expect(parsedPayment, isNotNull);
      expect(parsedPayment!.destination, DriverNotificationDestination.wallet);
      expect(parsedPayment.topUpId, 'topup-88');

      // Existing chat notification stays preserved
      final parsedChat = router.parseTapPayload({
        'conversationId': 'conv-12',
        'orderId': 'ord-9',
        'chatType': 'order',
      });
      expect(parsedChat, isNotNull);
      expect(parsedChat!.destination, DriverNotificationDestination.chat);
      expect(parsedChat.id, 'conv-12');
      expect(parsedChat.chatType, 'order');

      // Existing order notification stays preserved
      final parsedOrder = router.parseTapPayload({'orderId': 'ord-9'});
      expect(parsedOrder, isNotNull);
      expect(parsedOrder!.destination, DriverNotificationDestination.order);
      expect(parsedOrder.id, 'ord-9');
    });
  });

  group('Driver WalletScreen & SuspendedScreen top-up statuses', () {
    final sampleTopUps = <Map<String, dynamic>>[
      {
        'id': 'req-pending',
        'amount': 200.0,
        'status': 'PENDING',
        'createdAt': '2026-11-26T09:00:00.000Z',
        'platformWallet': {'type': 'VODAFONE', 'number': '01012345678'},
      },
      {
        'id': 'req-approved',
        'amount': 500.0,
        'status': 'APPROVED',
        'notes': 'Verified in bank statement',
        'createdAt': '2026-11-25T10:00:00.000Z',
        'reviewedAt': '2026-11-25T11:30:00.000Z',
        'platformWallet': {'type': 'INSTAPAY', 'number': 'otlob@instapay'},
      },
      {
        'id': 'req-rejected',
        'amount': 350.0,
        'status': 'REJECTED',
        'notes': 'Receipt image is cropped — missing transaction ID',
        'createdAt': '2026-11-24T12:00:00.000Z',
        'reviewedAt': '2026-11-24T13:15:00.000Z',
        'platformWallet': {'type': 'ORANGE', 'number': '01298765432'},
      },
    ];

    const blockedBrands = [
      'Vodafone Cash',
      'Orange Cash',
      'Etisalat Cash',
      'WE Pay',
      'فودافون كاش',
      'أورنج كاش',
      'اتصالات كاش',
      'وي باي',
    ];

    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets(
        'WalletScreen renders PENDING, APPROVED, and REJECTED requests with admin notes/reasons and Mobile Wallet labels (${locale.languageCode})',
        (tester) async {
          await _pumpDriverWidget(
            tester,
            locale: locale,
            overrides: [
              driverProfileProvider.overrideWith(
                () => _FakeDriverProfile({'status': 'ONLINE'}),
              ),
              driverWalletProvider.overrideWith(
                () => _FakeDriverWallet({
                  'balance': 125.0,
                  'topUpRequests': sampleTopUps,
                  'driverWallets': <dynamic>[],
                  'transactions': <dynamic>[],
                }),
              ),
            ],
            child: const WalletScreen(),
          );

          expect(tester.takeException(), isNull);

          final curr = locale.languageCode == 'ar' ? 'ج.م' : 'EGP';
          expect(find.text('+200.00 $curr'), findsOneWidget);
          expect(find.text('+500.00 $curr'), findsOneWidget);
          expect(find.text('+350.00 $curr'), findsOneWidget);

          expect(
            find.text('Receipt image is cropped — missing transaction ID'),
            findsOneWidget,
          );
          expect(find.text('Verified in bank statement'), findsOneWidget);

          final expectedWallet = locale.languageCode == 'ar'
              ? 'محفظة إلكترونية'
              : 'Mobile Wallet';
          expect(find.textContaining(expectedWallet), findsNWidgets(2));
          final expectedInstapay =
              locale.languageCode == 'ar' ? 'إنستا باي' : 'InstaPay';
          expect(find.textContaining(expectedInstapay), findsOneWidget);

          for (final brand in blockedBrands) {
            expect(find.textContaining(brand), findsNothing);
          }
        },
      );

      testWidgets(
        'SuspendedScreen displays rejected top-ups with rejection reasons cleanly on narrow viewports (${locale.languageCode})',
        (tester) async {
          final router = GoRouter(
            initialLocation: '/suspended',
            routes: [
              GoRoute(
                path: '/suspended',
                builder: (_, _) => const SuspendedScreen(),
              ),
              GoRoute(
                path: '/wallet',
                builder: (_, _) => const Scaffold(body: Text('Wallet Target')),
              ),
            ],
          );

          tester.view.physicalSize = const Size(320, 760);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                baseUrlProvider.overrideWithValue(
                  'https://api.otlob-test.invalid',
                ),
                configurationProvider.overrideWith(_FakeConfiguration.new),
                driverProfileProvider.overrideWith(
                  () => _FakeDriverProfile({
                    'status': 'SUSPENDED',
                    'hasUnpaidCommission': true,
                  }),
                ),
                driverWalletProvider.overrideWith(
                  () => _FakeDriverWallet({
                    'balance': -350.0,
                    'topUpRequests': sampleTopUps,
                    'platformWallets': const <dynamic>[],
                  }),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.darkTheme,
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: locale,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 47, bottom: 34),
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: AppWindowConstraintGuard(child: child!),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          final curr = locale.languageCode == 'ar' ? 'ج.م' : 'EGP';
          expect(find.text('+350.00 $curr'), findsOneWidget);
          expect(
            find.textContaining('Receipt image is cropped — missing transaction ID'),
            findsOneWidget,
          );
        },
      );
    }
  });
}
