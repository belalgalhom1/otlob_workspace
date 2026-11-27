import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Customer's selected electronic transfer channel at checkout.
///
/// The backend stores both mobile-money wallets and InstaPay under
/// `PaymentMethod.MOBILE_WALLET` while driver accounts carry distinct
/// `WalletType` entries (`VODAFONE`, `ORANGE`, `WE`, `ETISALAT`, `INSTAPAY`).
enum CustomerPaymentChannel {
  mobileWallet,
  instapay;

  String get storageValue =>
      this == CustomerPaymentChannel.instapay ? 'INSTAPAY' : 'MOBILE_WALLET';

  static CustomerPaymentChannel? fromStorage(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    if (normalized == 'INSTAPAY' || normalized == 'MOBILE_WALLET_INSTAPAY') {
      return CustomerPaymentChannel.instapay;
    }
    if (normalized == 'MOBILE_WALLET' ||
        normalized == 'MOBILE_WALLET_VODAFONE') {
      return CustomerPaymentChannel.mobileWallet;
    }
    return null;
  }
}

/// Persists the customer's selected wallet channel (`INSTAPAY` vs
/// `MOBILE_WALLET`) per `orderId` so Orders, Tracking, and Custom Delivery
/// payment cards display the exact transfer method the customer chose.
class CustomerPaymentPreferenceStore {
  CustomerPaymentPreferenceStore._();

  static const String _prefsKey = 'customer_order_payment_channel_v1';
  static const int _maxEntries = 60;

  static final Map<String, String> _cache = <String, String>{};
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (key != null && value != null) {
            _cache[key.toString()] = value.toString();
          }
        });
      }
    } catch (_) {
      // Best-effort local preference hydration.
    }
  }

  static Future<void> save(
    String orderId,
    CustomerPaymentChannel channel,
  ) async {
    final id = orderId.trim();
    if (id.isEmpty) return;
    await ensureLoaded();
    _cache[id] = channel.storageValue;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_cache));
    } catch (_) {
      // Keep in-memory copy even if disk write fails.
    }
  }

  static CustomerPaymentChannel? getSync(String? orderId) {
    final id = orderId?.trim();
    if (id == null || id.isEmpty) return null;
    return CustomerPaymentChannel.fromStorage(_cache[id]);
  }

  static void clearForTesting() {
    _cache.clear();
    _loaded = false;
  }
}

class FilteredDriverWallets {
  final List<Map<String, dynamic>> wallets;
  final CustomerPaymentChannel? preferredChannel;
  final bool matchedPreferred;

  const FilteredDriverWallets({
    required this.wallets,
    required this.preferredChannel,
    required this.matchedPreferred,
  });

  bool get isInstaPayFallbackToMobile =>
      preferredChannel == CustomerPaymentChannel.instapay &&
      !matchedPreferred &&
      wallets.isNotEmpty;

  bool get isMobileFallbackToInstaPay =>
      preferredChannel == CustomerPaymentChannel.mobileWallet &&
      !matchedPreferred &&
      wallets.isNotEmpty;
}

/// Single source of truth for filtering and labeling driver wallets across
/// Orders, Tracking, and Custom Delivery / Ride payment cards.
class WalletPaymentHelper {
  const WalletPaymentHelper._();

  static bool isInstaPayWallet(Map<dynamic, dynamic> wallet) {
    return (wallet['type'] ?? wallet['provider'] ?? '')
        .toString()
        .toUpperCase()
        .contains('INSTAPAY');
  }

  static String providerLabel(
    Map<dynamic, dynamic> wallet, {
    required bool isArabic,
  }) {
    if (isInstaPayWallet(wallet)) {
      return isArabic ? 'إنستا باي' : 'InstaPay';
    }
    return isArabic ? 'محفظة إلكترونية' : 'Mobile Wallet';
  }

  /// Filters active driver wallets based on what the customer selected:
  /// - Selected `INSTAPAY`: shows InstaPay accounts; falls back to Mobile
  ///   Wallet with `matchedPreferred = false` only if driver has no InstaPay.
  /// - Selected `MOBILE_WALLET`: shows Mobile Wallets; falls back to InstaPay
  ///   with `matchedPreferred = false` only if driver has no Mobile Wallet.
  /// - No recorded preference (e.g. COD upfront deposit or another device):
  ///   shows ALL active wallets (both Mobile Wallet and InstaPay) so InstaPay
  ///   is never hidden.
  static FilteredDriverWallets filterDriverWallets(
    List<dynamic> rawWallets, {
    CustomerPaymentChannel? preferredChannel,
  }) {
    final active = rawWallets
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((w) => w['isActive'] != false)
        .toList();

    if (active.isEmpty) {
      return FilteredDriverWallets(
        wallets: const [],
        preferredChannel: preferredChannel,
        matchedPreferred: true,
      );
    }

    final instapay = active.where(isInstaPayWallet).toList();
    final mobile = active.where((w) => !isInstaPayWallet(w)).toList();

    if (preferredChannel == CustomerPaymentChannel.instapay) {
      if (instapay.isNotEmpty) {
        return FilteredDriverWallets(
          wallets: instapay,
          preferredChannel: preferredChannel,
          matchedPreferred: true,
        );
      }
      return FilteredDriverWallets(
        wallets: mobile,
        preferredChannel: preferredChannel,
        matchedPreferred: false,
      );
    }

    if (preferredChannel == CustomerPaymentChannel.mobileWallet) {
      if (mobile.isNotEmpty) {
        return FilteredDriverWallets(
          wallets: mobile,
          preferredChannel: preferredChannel,
          matchedPreferred: true,
        );
      }
      return FilteredDriverWallets(
        wallets: instapay,
        preferredChannel: preferredChannel,
        matchedPreferred: false,
      );
    }

    // No explicit channel preference recorded -> show all active wallets
    // (Mobile Wallet + InstaPay) so InstaPay is always accessible.
    return FilteredDriverWallets(
      wallets: active,
      preferredChannel: null,
      matchedPreferred: true,
    );
  }

  static String transferInstruction({
    required FilteredDriverWallets filtered,
    required bool isArabic,
  }) {
    if (filtered.isInstaPayFallbackToMobile) {
      return isArabic
          ? 'لا يتوفر حساب إنستا باي لهذا الكابتن حالياً. يمكنك التحويل إلى محفظته الإلكترونية أدناه ثم تأكيد التحويل.'
          : "This driver hasn't added an InstaPay account yet. You can transfer to their Mobile Wallet below, then confirm.";
    }
    if (filtered.isMobileFallbackToInstaPay) {
      return isArabic
          ? 'لا تتوفر محفظة إلكترونية لهذا الكابتن حالياً. يمكنك التحويل عبر إنستا باي أدناه ثم تأكيد التحويل.'
          : "This driver hasn't added a Mobile Wallet yet. You can transfer via InstaPay below, then confirm.";
    }
    if (filtered.preferredChannel == CustomerPaymentChannel.instapay) {
      return isArabic
          ? 'يرجى تحويل المبلغ عبر إنستا باي إلى حساب الكابتن التالي، ثم إرفاق الإيصال وتأكيد التحويل.'
          : "Please transfer the amount via InstaPay to the driver's account below, then upload the receipt and confirm.";
    }
    if (filtered.preferredChannel == CustomerPaymentChannel.mobileWallet) {
      return isArabic
          ? 'يرجى تحويل المبلغ إلى المحفظة الإلكترونية للكابتن التالية، ثم إرفاق الإيصال وتأكيد التحويل.'
          : "Please transfer the amount to the driver's mobile wallet below, then upload the receipt and confirm.";
    }
    return isArabic
        ? 'يرجى تحويل المبلغ عبر المحفظة الإلكترونية أو إنستا باي إلى أحد حسابات الكابتن التالية، ثم تأكيد التحويل.'
        : "Please transfer the amount via Mobile Wallet or InstaPay to one of the driver's accounts below, then confirm.";
  }
}
