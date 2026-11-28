import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/dashboard/presentation/widgets/dashboard_settlement_requests_card.dart';
import 'package:vendor/features/wallet/data/wallet_models.dart';
import 'package:vendor/features/wallet/data/wallet_providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakePendingTopUps extends PendingTopUps {
  final Future<List<dynamic>> Function() loader;
  _FakePendingTopUps(this.loader);

  @override
  Future<List<dynamic>> build() => loader();
}

List<WalletTopUpRequest> _sampleRequests({int count = 6}) {
  final now = DateTime.now();
  return List.generate(
    count,
    (i) => WalletTopUpRequest(
      id: 'req-$i',
      driverId: 'drv-$i',
      driverName: i == 0 ? 'Ahmed Hassan Mohamed' : 'Driver ${i + 1}',
      amount: 150.0 + (i * 50),
      status: 'PENDING',
      receiptUrl: 'https://example.com/receipt-$i.jpg',
      createdAt: now.subtract(Duration(minutes: 5 + i * 10)),
      platformWalletType: i.isEven ? 'INSTAPAY' : 'MOBILE_WALLET',
      platformWalletNumber: '0101234567$i',
    ),
  );
}

Widget _buildCardHarness({
  required Locale locale,
  required bool isPhone,
  required Future<List<dynamic>> Function() loader,
  VoidCallback? onViewAll,
  ValueChanged<String>? onSelectRequest,
}) {
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [
      pendingTopUpsProvider.overrideWith(() => _FakePendingTopUps(loader)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Directionality(
        textDirection:
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DashboardSettlementRequestsCard(
              isPhone: isPhone,
              onViewAll: onViewAll ?? () {},
              onSelectRequest: onSelectRequest ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Shows up to 5 pending settlement requests in EN and fires onSelectRequest & onViewAll',
    (tester) async {
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? tappedId;
      var viewAllTapped = false;

      await tester.pumpWidget(
        _buildCardHarness(
          locale: const Locale('en'),
          isPhone: false,
          loader: () async => _sampleRequests(count: 6),
          onViewAll: () => viewAllTapped = true,
          onSelectRequest: (id) => tappedId = id,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settlement Requests'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('6 requests pending review'), findsOneWidget);
      expect(find.text('Ahmed Hassan Mohamed'), findsOneWidget);
      expect(find.text('150.00 EGP'), findsOneWidget);
      // Capped at 5 visible rows on dashboard
      expect(find.byKey(const ValueKey('dashboard_settlement_item_req-4')), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboard_settlement_item_req-5')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('dashboard_settlement_item_req-0')));
      await tester.pump();
      expect(tappedId, 'req-0');

      await tester.tap(find.byKey(const ValueKey('dashboard_settlement_view_all_btn')));
      await tester.pump();
      expect(viewAllTapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Renders cleanly in Arabic RTL on narrow 360px mobile width without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 840);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildCardHarness(
          locale: const Locale('ar'),
          isPhone: true,
          loader: () async => _sampleRequests(count: 3),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('طلبات التسوية'), findsOneWidget);
      expect(find.text('3 طلبات بانتظار المراجعة'), findsOneWidget);
      expect(find.text('قيد المراجعة'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Renders empty state cleanly when no requests are pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildCardHarness(
        locale: const Locale('ar'),
        isPhone: true,
        loader: () async => const <WalletTopUpRequest>[],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('طلبات التسوية'), findsOneWidget);
    expect(find.text('لا توجد طلبات معلقة'), findsOneWidget);
    expect(find.text('لا توجد طلبات تسوية معلقة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders error state and retries on refresh button tap', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      _buildCardHarness(
        locale: const Locale('en'),
        isPhone: false,
        loader: () async {
          attempts++;
          if (attempts == 1) {
            throw Exception('Network error');
          }
          return _sampleRequests(count: 1);
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard_settlement_retry_btn')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('dashboard_settlement_retry_btn')),
    );
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Ahmed Hassan Mohamed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
