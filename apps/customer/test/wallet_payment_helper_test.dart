import 'package:otlob_customer/features/orders/presentation/utils/wallet_payment_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final mixedWallets = [
    {'type': 'VODAFONE', 'number': '01012345678', 'isActive': true},
    {'type': 'INSTAPAY', 'number': 'driver@instapay', 'isActive': true},
    {'type': 'ORANGE', 'number': '01299999999', 'isActive': false},
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CustomerPaymentPreferenceStore.clearForTesting();
  });

  test('selecting InstaPay shows driver InstaPay account instead of hiding it', () {
    final result = WalletPaymentHelper.filterDriverWallets(
      mixedWallets,
      preferredChannel: CustomerPaymentChannel.instapay,
    );

    expect(result.matchedPreferred, isTrue);
    expect(result.wallets.length, 1);
    expect(result.wallets.first['type'], 'INSTAPAY');
    expect(result.wallets.first['number'], 'driver@instapay');
    expect(
      WalletPaymentHelper.transferInstruction(
        filtered: result,
        isArabic: false,
      ),
      contains('InstaPay'),
    );
  });

  test('selecting InstaPay falls back to Mobile Wallet with clear notice when driver lacks InstaPay', () {
    final result = WalletPaymentHelper.filterDriverWallets(
      [
        {'type': 'VODAFONE', 'number': '01012345678', 'isActive': true},
      ],
      preferredChannel: CustomerPaymentChannel.instapay,
    );

    expect(result.matchedPreferred, isFalse);
    expect(result.isInstaPayFallbackToMobile, isTrue);
    expect(result.wallets.length, 1);
    expect(result.wallets.first['type'], 'VODAFONE');
    expect(
      WalletPaymentHelper.transferInstruction(
        filtered: result,
        isArabic: false,
      ),
      contains("hasn't added an InstaPay"),
    );
  });

  test('selecting Mobile Wallet shows Mobile Wallet accounts', () {
    final result = WalletPaymentHelper.filterDriverWallets(
      mixedWallets,
      preferredChannel: CustomerPaymentChannel.mobileWallet,
    );

    expect(result.matchedPreferred, isTrue);
    expect(result.wallets.length, 1);
    expect(result.wallets.first['type'], 'VODAFONE');
  });

  test('when no preference is saved, shows all active wallets including InstaPay', () {
    final result = WalletPaymentHelper.filterDriverWallets(mixedWallets);

    expect(result.wallets.length, 2);
    expect(
      result.wallets.map((w) => w['type']).toList(),
      ['VODAFONE', 'INSTAPAY'],
    );
  });

  test('CustomerPaymentPreferenceStore saves and restores InstaPay selection per orderId', () async {
    await CustomerPaymentPreferenceStore.save(
      'ord-46',
      CustomerPaymentChannel.instapay,
    );
    expect(
      CustomerPaymentPreferenceStore.getSync('ord-46'),
      CustomerPaymentChannel.instapay,
    );

    // Simulate app restart by clearing in-memory cache and re-loading from SharedPreferences.
    CustomerPaymentPreferenceStore.clearForTesting();
    await CustomerPaymentPreferenceStore.ensureLoaded();
    expect(
      CustomerPaymentPreferenceStore.getSync('ord-46'),
      CustomerPaymentChannel.instapay,
    );
  });
}
