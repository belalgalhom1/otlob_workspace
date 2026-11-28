import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers/notification_router.dart';
import 'package:vendor/features/wallet/presentation/driver_manager_wallet_screen.dart';
import 'package:vendor/features/wallet/presentation/widgets/driver_manager_payout_dialog.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeAdminDriversRepository extends Fake
    implements AdminDriversRepository {
  final List<Map<String, dynamic>> payoutCalls = [];
  Map<String, dynamic>? ledgerResponse;

  @override
  Future<dynamic> processDriverManagerPayout({
    required String driverManagerUserId,
    int? amount,
    bool settleFullBalance = false,
    String? receiptUrl,
    String? description,
    String? idempotencyKey,
  }) async {
    payoutCalls.add({
      'driverManagerUserId': driverManagerUserId,
      'amount': amount,
      'settleFullBalance': settleFullBalance,
      'receiptUrl': receiptUrl,
      'description': description,
      'idempotencyKey': idempotencyKey,
    });
    return {
      'walletBalance': settleFullBalance ? 0 : (850 - (amount ?? 0)),
      'paidAmount': settleFullBalance ? 850 : (amount ?? 0),
    };
  }

  @override
  Future<dynamic> getDriverManagerTransactionsByUserId(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return ledgerResponse ??
        {
          'walletBalance': 0,
          'manager': {'userId': userId, 'name': 'Tarek Manager'},
          'data': [
            {
              'id': 'tx-payout-1',
              'type': 'PAYOUT',
              'amount': -850,
              'balanceAfter': 0,
              'description': 'InstaPay transfer #9912',
              'receiptUrl': '/media/receipts/payout-1.webp',
              'processedBy': {'id': 'u-super-1', 'name': 'Super Admin'},
              'createdAt': '2026-11-28T00:00:00.000Z',
            },
          ],
          'meta': {'total': 1, 'page': 1, 'limit': 20, 'totalPages': 1},
        };
  }
}

Widget _wrapApp({
  required Locale locale,
  required _FakeAdminDriversRepository repo,
  required Widget home,
}) {
  return ProviderScope(
    overrides: [
      dioProvider.overrideWithValue(
        Dio(BaseOptions(baseUrl: 'https://api.otlob-test.invalid')),
      ),
      adminDriversRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );
}

void main() {
  testWidgets(
    'DriverManagerPayoutDialog zeros out full balance in Arabic RTL at 360px without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 820);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _FakeAdminDriversRepository();
      bool? dialogResult;

      await tester.pumpWidget(
        _wrapApp(
          locale: const Locale('ar'),
          repo: repo,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    dialogResult = await DriverManagerPayoutDialog.show(
                      context,
                      managerUserId: 'u-mgr-1',
                      managerName: 'طارق مسؤول السائقين',
                      currentBalance: 850,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('تحويل وتصفية المحفظة'), findsOneWidget);
      expect(find.text('تصفير كامل الرصيد'), findsOneWidget);
      expect(find.text('850.00'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);

      final arNotesField = find.byType(TextField).last;
      await tester.ensureVisible(arNotesField);
      await tester.enterText(arNotesField, 'تحويل إنستا باي رقم 9912');

      final arConfirm = find.text('تصفير المحفظة وإرسال الإيصال');
      await tester.ensureVisible(arConfirm);
      await tester.tap(arConfirm);
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(repo.payoutCalls, hasLength(1));
      expect(repo.payoutCalls.first['driverManagerUserId'], 'u-mgr-1');
      expect(repo.payoutCalls.first['settleFullBalance'], isTrue);
      expect(repo.payoutCalls.first['amount'], isNull);
      expect(repo.payoutCalls.first['description'], 'تحويل إنستا باي رقم 9912');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DriverManagerPayoutDialog validates and submits custom partial payout in English LTR',
    (tester) async {
      tester.view.physicalSize = const Size(420, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _FakeAdminDriversRepository();
      bool? dialogResult;

      await tester.pumpWidget(
        _wrapApp(
          locale: const Locale('en'),
          repo: repo,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    dialogResult = await DriverManagerPayoutDialog.show(
                      context,
                      managerUserId: 'u-mgr-2',
                      managerName: 'Ali Manager',
                      currentBalance: 850,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom Amount'));
      await tester.pumpAndSettle();

      // Enter an amount exceeding balance -> inline error banner
      await tester.enterText(find.byType(TextField).first, '900');
      final enConfirm = find.text('Confirm Payout');
      await tester.ensureVisible(enConfirm);
      await tester.tap(enConfirm);
      await tester.pumpAndSettle();
      expect(find.textContaining('exceeds current balance'), findsOneWidget);
      expect(repo.payoutCalls, isEmpty);

      // Valid partial payout -> succeeds
      final amountField = find.byType(TextField).first;
      await tester.ensureVisible(amountField);
      await tester.enterText(amountField, '250');
      await tester.pump();
      expect(find.text('600.00'), findsOneWidget);

      await tester.ensureVisible(enConfirm);
      await tester.tap(enConfirm);
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(repo.payoutCalls, hasLength(1));
      expect(repo.payoutCalls.first['settleFullBalance'], isFalse);
      expect(repo.payoutCalls.first['amount'], 250);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DriverManagerWalletScreen displays transfer receipt button and processor name in Arabic RTL at 360px',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _FakeAdminDriversRepository();
      await tester.pumpWidget(
        _wrapApp(
          locale: const Locale('ar'),
          repo: repo,
          home: const DriverManagerWalletScreen(
            userId: 'u-mgr-1',
            managerName: 'Tarek Manager',
            canPayout: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('عرض إيصال التحويل'), findsOneWidget);
      expect(find.text('بواسطة: Super Admin'), findsOneWidget);
      expect(find.text('الرصيد مصفّر حالياً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('NotificationRouter routes driver_manager_payout to driver_manager_wallet', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(notificationRouterProvider.notifier).handleTap({
      'kind': 'driver_manager_payout',
      'route': 'driver_manager_wallet',
      'transactionId': 'tx-payout-1',
    });

    final route = container.read(notificationRouterProvider);
    expect(route, isNotNull);
    expect(route!.kind, 'driver_manager_wallet');
    expect(route.id, 'tx-payout-1');
  });
}
