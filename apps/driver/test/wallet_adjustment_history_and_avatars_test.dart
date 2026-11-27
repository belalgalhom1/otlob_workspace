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
      'Driver WalletScreen omits Adjustment History, keeps full multi-line notes in Transaction History, and places Adjustment Requests below Transaction History (${locale.languageCode})',
      (tester) async {
        const longAdminNote =
            'Performance bonus granted by operations for completing 15 peak-hour rain deliveries safely across Zamalek and Dokki without customer complaints.';

        final sampleWalletPayload = {
          'balance': 345.0,
          'topUpRequests': [
            {
              'id': 'topup-req-1',
              'amount': 250.0,
              'status': 'PENDING',
              'createdAt': '2026-11-21T09:00:00.000Z',
              'platformWallet': {'type': 'INSTAPAY', 'number': 'otlob@instapay'},
            },
          ],
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
        };

        await _pumpDriverTestApp(
          tester,
          locale: locale,
          overrides: [
            driverWalletProvider.overrideWith(
              () => _FakeDriverWallet(sampleWalletPayload),
            ),
          ],
          child: const WalletScreen(),
        );

        expect(tester.takeException(), isNull);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(WalletScreen)),
        )!;
        final historyTitle = l10n.recentTransactions;
        final requestsTitle = l10n.topUpRequestsTitle;
        expect(find.text(historyTitle), findsOneWidget);

        // Adjustment History section must be completely removed.
        expect(find.text(l10n.adjustmentHistory), findsNothing);

        // Scroll to bring Transaction History notes & Adjustment Requests into view
        await tester.scrollUntilVisible(
          find.text(longAdminNote),
          160.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text(longAdminNote), findsOneWidget);
        final Text noteWidget = tester.widget<Text>(find.text(longAdminNote));
        expect(noteWidget.maxLines, isNull);
        expect(noteWidget.overflow, isNot(TextOverflow.ellipsis));
        expect(find.text('   '), findsNothing);

        await tester.scrollUntilVisible(
          find.text(requestsTitle),
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text(requestsTitle), findsOneWidget);
        expect(find.text(l10n.adjustmentHistory), findsNothing);
        final expectedCurr = locale.languageCode == 'ar' ? 'ج.م' : 'EGP';
        expect(find.text('+250.00 $expectedCurr'), findsOneWidget);

        // On a taller viewport where both headers fit, assert Adjustment Requests sits strictly below Transaction History
        await _pumpDriverTestApp(
          tester,
          locale: locale,
          viewport: const Size(412, 1200),
          textScaler: const TextScaler.linear(1.0),
          overrides: [
            driverWalletProvider.overrideWith(
              () => _FakeDriverWallet(sampleWalletPayload),
            ),
          ],
          child: const WalletScreen(),
        );

        expect(find.text(l10n.adjustmentHistory), findsNothing);
        final historyDy = tester.getTopLeft(find.text(historyTitle)).dy;
        final requestsDy = tester.getTopLeft(find.text(requestsTitle)).dy;
        expect(requestsDy, greaterThan(historyDy));
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
