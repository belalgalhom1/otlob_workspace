import 'package:data/data.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/legal/presentation/pages/terms_acceptance_gate_screen.dart';
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

Future<void> _pumpDriverWidget(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
  List<dynamic> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(360, 640);
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
          data: const MediaQueryData(
            size: Size(360, 640),
            padding: EdgeInsets.only(top: 47, bottom: 34),
            textScaler: TextScaler.linear(1.3),
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
        expect(find.text('99999.00 EGP'), findsOneWidget);
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
}
