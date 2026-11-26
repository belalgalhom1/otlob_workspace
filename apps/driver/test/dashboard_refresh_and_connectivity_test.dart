import 'package:api/api.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/core/providers/driver_breaks_provider.dart';
import 'package:driver/features/dashboard/presentation/dashboard_screen.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/ranking/presentation/driver_ranking_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

class _FakeDriverProfile extends DriverProfile {
  final Map<String, dynamic> initialProfile;
  _FakeDriverProfile(this.initialProfile);

  @override
  AsyncValue<dynamic> build() => AsyncValue.data(initialProfile);

  @override
  Future<void> fetchProfile() async {}
}

class _FakeConfiguration extends Configuration {
  @override
  AsyncValue<Map<String, dynamic>> build() =>
      const AsyncValue.data({'currency': 'EGP'});
}

class _FakeDriverOrdersRepository extends Fake
    implements DriverOrdersRepository {
  @override
  Future<dynamic> getPendingAssistOffers() async => const <dynamic>[];
}

class _FakeOrderExecution extends OrderExecution {
  @override
  AsyncValue<dynamic> build() => const AsyncValue.data(null);

  @override
  Future<void> refresh() async {}
}

DriverMyRankSummaryResponseDto _makeFakeRank() {
  return DriverMyRankSummaryResponseDto(
    (b) => b
      ..driverId = 'driver_1'
      ..currentTier = DriverTier.GOLD
      ..timezone = 'Africa/Cairo'
      ..nextEvaluationAt = DateTime.now().add(const Duration(days: 3))
      ..currentWeek = RankingWeekWindowDto(
        (w) => w
          ..periodKey = '2026-W46'
          ..periodStart = DateTime.now()
          ..periodEnd = DateTime.now().add(const Duration(days: 7)),
      ).toBuilder(),
  );
}

void main() {
  group('Driver Dashboard Dual Refresh & Offline Banner Tests', () {
    testWidgets(
      'renders AppBar refresh icon and in-card sync button when online',
      (tester) async {
        final fakeOnlineProfile = {
          'status': 'ONLINE',
          'name': 'Captain Ahmed',
          'totalOrders': 42,
          'tier': 'GOLD',
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              baseUrlProvider.overrideWithValue(
                'https://api.otlob-test.invalid',
              ),
              configurationProvider.overrideWith(_FakeConfiguration.new),
              driverProfileProvider.overrideWith(
                () => _FakeDriverProfile(fakeOnlineProfile),
              ),
              driverOrdersRepositoryProvider.overrideWithValue(
                _FakeDriverOrdersRepository(),
              ),
              orderExecutionProvider.overrideWith(_FakeOrderExecution.new),
              breaksOverviewProvider.overrideWith(
                (ref) async => const BreaksOverview(),
              ),
              driverRankingSummaryProvider.overrideWith(
                (ref) async => _makeFakeRank(),
              ),
              isOnlineStreamProvider.overrideWith((ref) => Stream.value(true)),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('ar'),
              home: DashboardScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // 1. Verify top AppBar refresh action icon is present
        expect(find.byIcon(LucideIcons.refreshCw), findsAtLeastNWidgets(1));

        // 2. Verify compact top status indicator displays Arabic Online status
        expect(
          find.byKey(const ValueKey('driver_dashboard_status_card')),
          findsOneWidget,
        );
        expect(find.text('متصل'), findsOneWidget);
      },
    );

    testWidgets(
      'renders offline banner and flips status indicator offline when isOnline is false',
      (tester) async {
        final fakeOnlineProfile = {'status': 'ONLINE', 'name': 'Captain Ahmed'};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              baseUrlProvider.overrideWithValue(
                'https://api.otlob-test.invalid',
              ),
              configurationProvider.overrideWith(_FakeConfiguration.new),
              driverProfileProvider.overrideWith(
                () => _FakeDriverProfile(fakeOnlineProfile),
              ),
              driverOrdersRepositoryProvider.overrideWithValue(
                _FakeDriverOrdersRepository(),
              ),
              orderExecutionProvider.overrideWith(_FakeOrderExecution.new),
              breaksOverviewProvider.overrideWith(
                (ref) async => const BreaksOverview(),
              ),
              driverRankingSummaryProvider.overrideWith(
                (ref) async => _makeFakeRank(),
              ),
              isOnlineStreamProvider.overrideWith((ref) => Stream.value(false)),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('ar'),
              home: DashboardScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Verify offline banner shows up on dashboard and compact status flips to offline
        expect(find.byType(OfflineStatusBanner), findsOneWidget);
        expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
        expect(find.text('غير متصل'), findsOneWidget);
      },
    );
  });
}
