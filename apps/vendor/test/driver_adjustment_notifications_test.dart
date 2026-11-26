import 'package:api/api.dart' hide WalletTopUpRequest;
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers/notification_router.dart';
import 'package:vendor/features/wallet/data/wallet_models.dart';
import 'package:vendor/features/wallet/data/wallet_providers.dart';
import 'package:vendor/features/wallet/presentation/topup_details_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeAdminWalletRepository extends Fake
    implements AdminWalletRepository {
  Map<String, dynamic>? detailsPayload;
  bool failGetById = false;
  List<dynamic> pendingItems = const [];
  final List<({String id, ReviewWalletTopUpDto dto})> reviews = [];

  @override
  Future<dynamic> walletGetPendingTopUps() async => pendingItems;

  @override
  Future<dynamic> walletGetTopUpById({required String id}) async {
    if (failGetById) {
      throw DioException(
        requestOptions: RequestOptions(path: '/wallet/topups/$id'),
        type: DioExceptionType.connectionError,
        message: 'Simulated failure',
      );
    }
    return detailsPayload ??
        {
          'id': id,
          'driverId': 'drv-1',
          'amount': 350.0,
          'status': 'PENDING',
          'receiptUrl': '',
          'createdAt': '2026-11-26T08:00:00.000Z',
          'platformWalletId': 'pw-1',
          'platformWallet': {'id': 'pw-1', 'type': 'VODAFONE', 'number': '01012345678'},
          'driver': {
            'id': 'drv-1',
            'walletBalance': -150.0,
            'user': {'name': 'Ahmed Hassan', 'phone': '+201099887766'},
          },
        };
  }

  @override
  Future<dynamic> walletReviewTopUp({
    required String id,
    required ReviewWalletTopUpDto reviewWalletTopUpDto,
  }) async {
    reviews.add((id: id, dto: reviewWalletTopUpDto));
    final current = Map<String, dynamic>.from(
      detailsPayload ?? await walletGetTopUpById(id: id) as Map,
    );
    current['status'] = reviewWalletTopUpDto.status.name;
    current['notes'] = reviewWalletTopUpDto.notes;
    current['reviewedAt'] = '2026-11-26T09:15:00.000Z';
    current['approvedById'] = 'admin-1';
    current['approvedBy'] = {'id': 'admin-1', 'name': 'Super Admin'};
    detailsPayload = current;
    return current;
  }
}

Future<void> _pumpVendorDetailsApp(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
  Size viewport = const Size(360, 780),
  TextScaler textScaler = const TextScaler.linear(1.3),
  required _FakeAdminWalletRepository repo,
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
        dioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'https://api.otlob-test.invalid')),
        ),
        adminWalletRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: viewport,
            padding: const EdgeInsets.only(top: 44, bottom: 24),
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
  group('NotificationRouter & WalletTopUpRequest unit checks', () {
    test('routes wallet_topup and wallet_topup_details while preserving order & chat routes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(notificationRouterProvider.notifier);

      router.handleTap({
        'kind': 'wallet_topup',
        'topUpId': 'topup-101',
        'route': 'wallet_topup_details',
      });
      final topUpRoute = container.read(notificationRouterProvider);
      expect(topUpRoute, isNotNull);
      expect(topUpRoute!.kind, 'wallet_topup');
      expect(topUpRoute.id, 'topup-101');

      router.clear();
      expect(container.read(notificationRouterProvider), isNull);

      router.handleTap({
        'route': 'wallet_topup_details',
        'requestId': 'topup-202',
      });
      final detailsRoute = container.read(notificationRouterProvider);
      expect(detailsRoute, isNotNull);
      expect(detailsRoute!.kind, 'wallet_topup');
      expect(detailsRoute.id, 'topup-202');

      // Preserve order notification routing
      router.handleTap({'orderId': 'order-77', 'type': 'ORDER_PLACED'});
      final orderRoute = container.read(notificationRouterProvider);
      expect(orderRoute, isNotNull);
      expect(orderRoute!.kind, 'order');
      expect(orderRoute.id, 'order-77');

      // Preserve chat notification routing
      router.handleTap({
        'conversationId': 'conv-55',
        'chatType': 'ORDER',
      });
      final chatRoute = container.read(notificationRouterProvider);
      expect(chatRoute, isNotNull);
      expect(chatRoute!.kind, 'chat');
      expect(chatRoute.id, 'conv-55');
      expect(chatRoute.chatType, 'ORDER');
    });

    test('WalletTopUpRequest.platformWalletLabel uses Mobile Wallet / InstaPay without carrier brands', () {
      const blockedLabels = [
        'Vodafone Cash',
        'Orange Cash',
        'Etisalat Cash',
        'WE Pay',
        'فودافون كاش',
        'أورنج كاش',
        'اتصالات كاش',
        'وي باي',
      ];

      for (final carrier in ['VODAFONE', 'ORANGE', 'ETISALAT', 'WE']) {
        final req = WalletTopUpRequest.fromJson({
          'id': 'req-$carrier',
          'driverId': 'drv-1',
          'amount': 250,
          'status': 'PENDING',
          'receiptUrl': '',
          'createdAt': '2026-11-26T08:00:00.000Z',
          'platformWallet': {'type': carrier, 'number': '01012345678'},
        });
        final en = req.platformWalletLabel(isArabic: false);
        final ar = req.platformWalletLabel(isArabic: true);

        expect(en, 'Mobile Wallet - 01012345678');
        expect(ar, contains('محفظة إلكترونية'));
        expect(ar, contains('01012345678'));
        for (final blocked in blockedLabels) {
          expect(en, isNot(contains(blocked)));
          expect(ar, isNot(contains(blocked)));
        }
      }

      final instapay = WalletTopUpRequest.fromJson({
        'id': 'req-ip',
        'driverId': 'drv-1',
        'amount': 500,
        'status': 'PENDING',
        'receiptUrl': '',
        'createdAt': '2026-11-26T08:00:00.000Z',
        'platformWallet': {'type': 'INSTAPAY', 'number': 'driver@instapay'},
      });
      expect(
        instapay.platformWalletLabel(isArabic: false),
        'InstaPay - driver@instapay',
      );
      expect(
        instapay.platformWalletLabel(isArabic: true),
        contains('إنستا باي'),
      );
    });

    test('PendingTopUps.reviewTopUp forwards status enum and notes to repository', () async {
      final repo = _FakeAdminWalletRepository();
      final container = ProviderContainer(
        overrides: [adminWalletRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(pendingTopUpsProvider.future);
      await container
          .read(pendingTopUpsProvider.notifier)
          .reviewTopUp(
            'topup-90',
            'REJECTED',
            notes: 'Transfer reference not visible in receipt',
          );

      expect(repo.reviews, hasLength(1));
      expect(repo.reviews.first.id, 'topup-90');
      expect(
        repo.reviews.first.dto.status,
        ReviewWalletTopUpDtoStatusEnum.REJECTED,
      );
      expect(
        repo.reviews.first.dto.notes,
        'Transfer reference not visible in receipt',
      );
    });
  });

  group('DriverAdjustmentDetailsScreen widget verification', () {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets(
        'renders PENDING adjustment details, Mobile Wallet label, and submits rejection with reason (${locale.languageCode})',
        (tester) async {
          final repo = _FakeAdminWalletRepository();
          await _pumpVendorDetailsApp(
            tester,
            locale: locale,
            repo: repo,
            child: const DriverAdjustmentDetailsScreen(requestId: 'topup-101'),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Ahmed Hassan'), findsOneWidget);
          expect(find.text('350'), findsOneWidget);
          final expectedCurrency = locale.languageCode == 'ar' ? 'ج.م' : 'EGP';
          expect(find.text(expectedCurrency), findsWidgets);
          expect(find.textContaining('01012345678'), findsOneWidget);

          final expectedWalletText = locale.languageCode == 'ar'
              ? 'محفظة إلكترونية'
              : 'Mobile Wallet';
          expect(find.textContaining(expectedWalletText), findsOneWidget);

          // Enter rejection reason notes and reject.
          const rejectionNote = 'Blur photo — please resend clear receipt';
          await tester.enterText(find.byType(TextField), rejectionNote);
          await tester.pump();

          final rejectLabel = locale.languageCode == 'ar' ? 'رفض' : 'Reject';
          final rejectButton = find.text(rejectLabel);
          await tester.ensureVisible(rejectButton);
          await tester.tap(rejectButton);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(repo.reviews, hasLength(1));
          expect(
            repo.reviews.first.dto.status,
            ReviewWalletTopUpDtoStatusEnum.REJECTED,
          );
          expect(repo.reviews.first.dto.notes, rejectionNote);

          // After rejection, details reload showing reviewed metadata & notes.
          expect(find.text(rejectionNote), findsOneWidget);
          expect(find.textContaining('Super Admin'), findsOneWidget);
        },
      );
    }

    testWidgets('shows error state and recovers cleanly on retry', (tester) async {
      final repo = _FakeAdminWalletRepository()..failGetById = true;
      await _pumpVendorDetailsApp(
        tester,
        locale: const Locale('en'),
        repo: repo,
        child: const DriverAdjustmentDetailsScreen(requestId: 'topup-err'),
      );

      expect(tester.takeException(), isNull);
      final retryFinder = find.text('Refresh');
      expect(retryFinder, findsOneWidget);

      repo.failGetById = false;
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ahmed Hassan'), findsOneWidget);
    });
  });
}
