import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/dispatch/presentation/pages/dispatch_modal.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';
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

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

class _FakeDriverOrdersRepository extends Fake
    implements DriverOrdersRepository {
  @override
  Future<dynamic> getMyAssistRequests() async => const <dynamic>[];
}

Future<void> _pumpDriverTestApp(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
  Size viewport = const Size(320, 720),
  TextScaler textScaler = const TextScaler.linear(1.35),
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
          child: AppWindowConstraintGuard(child: Scaffold(body: child)),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'Driver WalletScreen displays Adjustment History, renders long multi-line notes without truncation, hides empty note blocks, and fits narrow viewport (${locale.languageCode})',
      (tester) async {
        const longAdminNote =
            'Performance bonus granted by operations for completing 15 peak-hour rain deliveries safely across Zamalek and Dokki without customer complaints.';

        await _pumpDriverTestApp(
          tester,
          locale: locale,
          overrides: [
            driverWalletProvider.overrideWith(
              () => _FakeDriverWallet({
                'balance': 345.0,
                'topUpRequests': <dynamic>[],
                'driverWallets': <dynamic>[],
                'transactions': [
                  {
                    'id': 'tx-adj-with-note',
                    'type': 'BONUS',
                    'amount': 120.0,
                    'balanceAfter': 345.0,
                    'isManualAdjustment': true,
                    'note': longAdminNote,
                    'createdAt': '2026-11-20T03:30:00.000Z',
                  },
                  {
                    'id': 'tx-adj-empty-note',
                    'type': 'PENALTY',
                    'amount': -25.0,
                    'balanceAfter': 225.0,
                    'isManualAdjustment': true,
                    'note': '   ',
                    'createdAt': '2026-11-19T14:15:00.000Z',
                  },
                  {
                    'id': 'tx-delivery-1',
                    'type': 'DELIVERY_FEE',
                    'amount': 50.0,
                    'balanceAfter': 250.0,
                    'isManualAdjustment': false,
                    'createdAt': '2026-11-19T12:00:00.000Z',
                  },
                ],
              }),
            ),
          ],
          child: const WalletScreen(),
        );

        expect(tester.takeException(), isNull);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(WalletScreen)),
        )!;
        final historyTitle = l10n.recentTransactions;
        expect(find.text(historyTitle), findsOneWidget);

        final expectedHeader = l10n.adjustmentHistory;

        // Adjustment History now sits below Recent Transactions; scroll down to bring it into view
        await tester.scrollUntilVisible(
          find.text(expectedHeader),
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text(expectedHeader), findsOneWidget);
        expect(find.text(longAdminNote), findsWidgets);
        final expectedCurr = locale.languageCode == 'ar' ? 'ج.م' : 'EGP';
        expect(find.text('+120.00 $expectedCurr'), findsOneWidget);
        expect(find.text('-25.00 $expectedCurr'), findsOneWidget);

        // Verify the note Text inside Adjustment History is NOT limited with ellipsis
        final noteFinder = find.text(longAdminNote).first;
        final Text noteWidget = tester.widget<Text>(noteFinder);
        expect(noteWidget.maxLines, isNull);
        expect(noteWidget.overflow, isNot(TextOverflow.ellipsis));

        // Verify empty note card renders no empty message/note block
        expect(find.text('   '), findsNothing);

        // On a taller viewport where both headers fit, assert Adjustments is strictly below History
        await _pumpDriverTestApp(
          tester,
          locale: locale,
          viewport: const Size(412, 1200),
          textScaler: const TextScaler.linear(1.0),
          overrides: [
            driverWalletProvider.overrideWith(
              () => _FakeDriverWallet({
                'balance': 345.0,
                'topUpRequests': <dynamic>[],
                'driverWallets': <dynamic>[],
                'transactions': [
                  {
                    'id': 'tx-adj-with-note',
                    'type': 'BONUS',
                    'amount': 120.0,
                    'balanceAfter': 345.0,
                    'isManualAdjustment': true,
                    'note': longAdminNote,
                    'createdAt': '2026-11-20T03:30:00.000Z',
                  },
                  {
                    'id': 'tx-delivery-1',
                    'type': 'DELIVERY_FEE',
                    'amount': 50.0,
                    'balanceAfter': 250.0,
                    'isManualAdjustment': false,
                    'createdAt': '2026-11-19T12:00:00.000Z',
                  },
                ],
              }),
            ),
          ],
          child: const WalletScreen(),
        );

        final historyDy = tester.getTopLeft(find.text(historyTitle)).dy;
        final adjustmentsDy = tester.getTopLeft(find.text(expectedHeader)).dy;
        expect(adjustmentsDy, greaterThan(historyDy));
      },
    );
  }

  testWidgets(
    'DispatchModal and OrderDetailsBottomSheet render vendor logos and customer/assist avatars gracefully',
    (tester) async {
      await _pumpDriverTestApp(
        tester,
        locale: const Locale('en'),
        overrides: [
          driverOrdersRepositoryProvider.overrideWithValue(
            _FakeDriverOrdersRepository(),
          ),
        ],
        child: const DispatchModal(
          dispatchData: {
            'orderId': 'ord-d-1',
            'estimatedEarnings': 55.0,
            'deliveryFee': 55.0,
            'distanceKm': 3.4,
            'pickupLocationName': 'Fresh Market',
            'pickupLocationLogo': 'https://cdn.otlob-test.invalid/logos/fresh.png',
            'dropoffLocationName': 'Omar Khalid',
            'dropoffCustomerAvatar':
                'https://cdn.otlob-test.invalid/avatars/omar.png',
            'timeoutSeconds': 30,
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AppNetworkAvatar), findsNWidgets(2));
      expect(find.text('Fresh Market'), findsOneWidget);
      expect(find.text('Omar Khalid'), findsOneWidget);

      await _pumpDriverTestApp(
        tester,
        locale: const Locale('en'),
        overrides: [
          driverOrdersRepositoryProvider.overrideWithValue(
            _FakeDriverOrdersRepository(),
          ),
        ],
        child: const OrderDetailsBottomSheet(
          order: {
            'id': 'ord-d-2',
            'orderNumber': 'ORD-202',
            'type': 'VENDOR',
            'status': 'PICKED_UP',
            'totalPrice': 180.0,
            'deliveryFee': 30.0,
            'paymentMethod': 'CASH',
            'customer': {
              'name': 'Salma Hassan',
              'phone': '01012345678',
              'avatar': 'https://cdn.otlob-test.invalid/avatars/salma.png',
            },
            'assistDriver': {
              'name': 'Karim Assistant',
              'avatar': 'https://cdn.otlob-test.invalid/avatars/karim.png',
            },
            'vendorFulfillments': [
              {
                'id': 'f-1',
                'status': 'PICKED_UP',
                'vendor': {
                  'storeName': 'Store A',
                  'logo': 'https://cdn.otlob-test.invalid/logos/a.png',
                },
              },
              {
                'id': 'f-2',
                'status': 'READY_FOR_PICKUP',
                'vendor': {
                  'storeName': 'Store B',
                  'logo': 'https://cdn.otlob-test.invalid/logos/b.png',
                },
              },
            ],
            'items': [],
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AppNetworkAvatar), findsWidgets);
      expect(find.text('Salma Hassan'), findsOneWidget);
      expect(find.textContaining('Karim Assistant'), findsOneWidget);
    },
  );
}
