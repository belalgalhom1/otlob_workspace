import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart'
    show AppDialog, AppDialogHeader, AppDialogStyles, AppNetworkAvatar;
import '../../../../core/utils/image_utils.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';
import '../providers/cart_controller.dart';
import '../../../home/presentation/providers/vendor_detail_controller.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../profile/presentation/providers/coin_history_provider.dart';
import '../../../profile/presentation/providers/delivery_address_provider.dart';
import '../../../../core/providers/platform_settings_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? vendorId;
  final List<String>? vendorIds;
  const CheckoutScreen({super.key, this.vendorId, this.vendorIds});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool get isMultiVendor => activeVendorIds.length > 1;
  List<String> get activeVendorIds {
    final cart = ref.read(cartProvider);
    final baskets = cart.vendorBaskets;
    if (widget.vendorIds != null && widget.vendorIds!.isNotEmpty) {
      if (cart.isLoading && baskets.isEmpty) {
        return widget.vendorIds!;
      }
      return widget.vendorIds!
          .where((id) => (baskets[id] ?? const []).isNotEmpty)
          .toList();
    }
    if (widget.vendorId != null && widget.vendorId!.isNotEmpty) {
      if (cart.isLoading && baskets.isEmpty) {
        return [widget.vendorId!];
      }
      return (baskets[widget.vendorId!] ?? const []).isNotEmpty
          ? [widget.vendorId!]
          : const [];
    }
    return baskets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  String _selectedPayment = 'CASH_ON_DELIVERY';
  bool _isProcessing = false;
  bool _orderPlaced = false;
  bool _syncedEmptyCart = false;
  bool _useCoins = false;
  bool _isEstimating = false;
  bool _pendingReEstimate = false;
  Map<String, dynamic>? _estimate;
  String? _lastEstimateKey;
  String? _estimateError;
  String? _clientOrderKey;
  final TextEditingController _notesController = TextEditingController();

  String _clientOrderKeyForCheckout() =>
      _clientOrderKey ??= generateClientOrderKey();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchEstimate({bool force = false}) async {
    if (_orderPlaced) return;
    if (_isEstimating) {
      _pendingReEstimate = true;
      return;
    }
    final vendorIds = activeVendorIds;
    if (vendorIds.isEmpty) return;

    final selectedAddress = ref.read(activeDeliveryAddressProvider);
    if (selectedAddress == null) return;

    final locationData = selectedAddress['location'];
    List<double> coords = [];
    if (locationData is List) {
      coords = locationData.map((e) => (e as num).toDouble()).toList();
    } else if (locationData is Map && locationData['coordinates'] is List) {
      final coordinatesList = locationData['coordinates'] as List<dynamic>;
      coords = coordinatesList.map((e) => (e as num).toDouble()).toList();
    }
    if (coords.length != 2) return;

    final coinState = ref.read(coinHistoryProvider);
    final settings = ref.read(platformSettingsProvider).value;
    int? coinsToUse;
    if (_useCoins && settings != null && coinState.currentBalance >= settings.minCoinsToUse) {
      // Send the full balance; the backend applies coins to the grand total
      // (products + delivery + fees + tax) and consumes only what is needed,
      // so coins can pay for the entire order when the balance is sufficient.
      coinsToUse = coinState.currentBalance;
    }

    final vendorCartItems = isMultiVendor
        ? vendorIds.expand((vid) => ref.read(cartProvider).vendorBaskets[vid] ?? <CartItem>[]).toList()
        : (ref.read(cartProvider).vendorBaskets[vendorIds.first] ?? []);
    final cartFingerprint = vendorCartItems.map((i) {
      final pid = i.backendId ?? i.product.id;
      final vid = i.selectedVariant?.id ?? '';
      final opts = i.selectedOptions
          .map((o) => o.id)
          .where((s) => s.isNotEmpty)
          .toList()
        ..sort();
      return '$pid|$vid|${i.quantity}|${i.selectedUnit}|${opts.join(',')}';
    }).join(';');

    final normalizedPaymentMethod = _selectedPayment.startsWith('MOBILE_WALLET')
        ? 'MOBILE_WALLET'
        : 'CASH_ON_DELIVERY';
    final estimateKey =
        '${vendorIds.join(",")}|${coords[0]},${coords[1]}|$normalizedPaymentMethod|${coinsToUse ?? 0}|$cartFingerprint';
    if (!force && estimateKey == _lastEstimateKey) return;

    setState(() {
      _isEstimating = true;
      if (force) _estimateError = null;
    });
    try {
      final result = isMultiVendor
          ? await ref.read(ordersProvider.notifier).estimateMultiVendorOrder(
              vendorIds: vendorIds,
              paymentMethod: normalizedPaymentMethod,
              address: selectedAddress['address'] ?? '',
              location: coords,
              coinsToUse: coinsToUse,
            )
          : await ref.read(ordersProvider.notifier).estimateOrder(
              vendorId: vendorIds.first,
              paymentMethod: normalizedPaymentMethod,
              address: selectedAddress['address'] ?? '',
              location: coords,
              coinsToUse: coinsToUse,
            );
      if (mounted) {
        setState(() {
          _estimate = result;
          _lastEstimateKey = estimateKey;
          _estimateError = null;
          _isEstimating = false;
        });
      }
    } catch (e) {
      String? message;
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      if (mounted) {
        final resolvedError = message ?? e.toString();
        setState(() {
          _estimate = null;
          _lastEstimateKey = null;
          _estimateError = resolvedError;
          _isEstimating = false;
        });
        if (resolvedError.contains('cart.error.is_empty')) {
          await _recoverFromEmptyCartError(vendorIds);
        }
      }
    } finally {
      if (mounted && _pendingReEstimate && !_orderPlaced) {
        _pendingReEstimate = false;
        Future.microtask(() => _fetchEstimate(force: true));
      }
    }
  }

  Future<bool> _recoverFromEmptyCartError(List<String> beforeVendorIds) async {
    if (_syncedEmptyCart) return false;
    _syncedEmptyCart = true;
    await ref.read(cartProvider.notifier).loadCarts(force: true);
    if (!mounted) return false;

    final remainingVendorIds = activeVendorIds;
    final shrunk = remainingVendorIds.isNotEmpty &&
        (remainingVendorIds.length < beforeVendorIds.length ||
            remainingVendorIds.join(',') != beforeVendorIds.join(','));
    if (shrunk) {
      final s = AppStrings.of(context);
      setState(() {
        _estimateError = null;
        _estimate = null;
        _lastEstimateKey = null;
        _clientOrderKey = null;
        _syncedEmptyCart = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isArabic
                ? 'تمت إزالة المتاجر الفارغة من الطلب، جاري تحديث الإجمالي...'
                : 'Removed empty store items from checkout, updating total...',
          ),
        ),
      );
      return true;
    }
    return false;
  }

  void _placeOrder(AppStrings s, List<CartItem> vendorItems, int? coinsToUse, Map<String, dynamic>? selectedAddress) async {
    if (_isProcessing) return;
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isArabic ? 'الرجاء اختيار عنوان' : 'Please select an address')));
      return;
    }
    if (_estimate == null || _isEstimating) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isArabic
              ? 'يرجى الانتظار حتى يتم حساب الرسوم'
              : 'Please wait until fees are calculated')));
      return;
    }

    setState(() => _isProcessing = true);

    final locationData = selectedAddress['location'];
    List<double> coords = [];

    if (locationData is List) {
      coords = locationData.map((e) => (e as num).toDouble()).toList();
    } else if (locationData is Map && locationData['coordinates'] is List) {
      final coordinatesList = locationData['coordinates'] as List<dynamic>;
      coords = coordinatesList.map((e) => (e as num).toDouble()).toList();
    }

    if (coords.length != 2) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.isArabic
                ? 'الرجاء اختيار عنوان يحتوي على موقع جغرافي صحيح'
                : 'Please select an address with a valid map location')));
      }
      return;
    }

    final specialRequest = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final vendorIds = activeVendorIds;
    if (vendorIds.isEmpty) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    final paymentMethod = _selectedPayment.startsWith('MOBILE_WALLET')
        ? 'MOBILE_WALLET'
        : 'CASH_ON_DELIVERY';
    final address = selectedAddress['address'] ?? s.locationName;
    final ordersNotifier = ref.read(ordersProvider.notifier);

    final (errorMsg, orderId) = isMultiVendor
        ? await ordersNotifier.placeMultiVendorOrder(
            vendorIds: vendorIds,
            paymentMethod: paymentMethod,
            address: address,
            location: coords,
            specialRequest: specialRequest,
            coinsToUse: coinsToUse,
            idempotencyKey: _clientOrderKeyForCheckout(),
          )
        : await ordersNotifier.placeOrder(
            vendorId: vendorIds.first,
            items: vendorItems,
            paymentMethod: paymentMethod,
            address: address,
            location: coords,
            specialRequest: specialRequest,
            coinsToUse: coinsToUse,
            idempotencyKey: _clientOrderKeyForCheckout(),
          );

    if (!mounted) return;

    if (errorMsg == null && orderId != null) {
      setState(() {
        _orderPlaced = true;
        _isProcessing = false;
      });
      _clientOrderKey = null;
      ref.read(cartProvider.notifier).clearLocalBaskets(vendorIds);
      _showSuccess(s, orderId);
      return;
    }

    setState(() => _isProcessing = false);
    if (errorMsg != null && errorMsg.contains('cart.error.is_empty')) {
      final recovered = await _recoverFromEmptyCartError(vendorIds);
      if (!mounted || recovered) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ErrorUtils.translate(context, errorMsg ?? 'Failed to place order')),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccess(AppStrings s, String orderId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        maxWidth: 440,
        canPop: false,
        showDividers: false,
        header: AppDialogHeader(
          icon: LucideIcons.checkCircle2,
          accentColor: AppColors.success,
          title: s.orderSuccess,
          showCloseButton: false,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 140,
              width: 140,
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                repeat: false,
                errorBuilder: (c, e, st) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    size: 68,
                    color: AppColors.success,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.orderSuccessSub,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
            ),
          ],
        ),
        footer: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/home');
                  context.push('/order-tracking/$orderId');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppDialogStyles.foregroundFor(
                    AppColors.primary,
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.navigation, size: 17),
                label: Text(
                  s.goToOrders,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/home');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  foregroundColor: Theme.of(ctx).colorScheme.onSurface,
                  side: BorderSide(
                    color: AppDialogStyles.borderColor(ctx),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  s.navHome,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);
    final profileState = ref.watch(profileProvider);

    final vendorIds = activeVendorIds;
    final hasAnyItems = vendorIds.any((vid) => (cartState.vendorBaskets[vid] ?? []).isNotEmpty);

    if (_orderPlaced) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const SizedBox.shrink(),
      );
    }

    if (vendorIds.isEmpty || !hasAnyItems) {
      void navigateBack() {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }

      if (cartState.isLoading) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: navigateBack,
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: navigateBack,
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_basket_outlined,
                    size: 64,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  s.emptyCart,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.emptyCartSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(180, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    s.backToHome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final vendorItems = isMultiVendor
        ? vendorIds.expand((vid) => cartState.vendorBaskets[vid] ?? <CartItem>[]).toList()
        : (cartState.vendorBaskets[vendorIds.first] ?? []);
    final selectedBranch = !isMultiVendor && vendorIds.isNotEmpty
        ? ref.watch(selectedBranchProvider)[vendorIds.first]
        : null;
    final branchName = selectedBranch?.localizedName(s.isArabic);
    final isSingleBranch = ((_estimate?['branchCount'] as num?)?.toInt() ?? 1) <= 1;
    final storeDisplayName = vendorItems.isNotEmpty
        ? (s.isArabic
            ? (vendorItems.first.product.vendorNameAr ?? vendorItems.first.product.vendorName ?? s.vendor)
            : (vendorItems.first.product.vendorName ?? s.vendor))
        : s.vendor;
    final vendorName = isMultiVendor
        ? (s.isArabic ? 'عدة متاجر (${vendorIds.length})' : 'Multiple Stores (${vendorIds.length})')
        : (vendorItems.isNotEmpty
            ? '$storeDisplayName${isSingleBranch && branchName != null && branchName.isNotEmpty ? ' • $branchName' : ''}'
            : s.vendor);
    final subtotal = isMultiVendor
        ? vendorIds.fold(0.0, (acc, vid) => acc + cartState.getVendorSubtotal(vid))
        : cartState.getVendorSubtotal(vendorIds.first);
    final settings = ref.watch(platformSettingsProvider).value;

    final est = _estimate;
    final minOrder = (est?['minOrderAmount'] as num?)?.toDouble() ??
        ((settings?.minOrderAmount != null) ? settings!.minOrderAmount.toDouble() : 0.0);
    final isBelowMinOrder = minOrder > 0 && subtotal < minOrder;
    final minOrderDiff = isBelowMinOrder ? (minOrder - subtotal) : 0.0;

    final coinState = ref.watch(coinHistoryProvider);
    int? coinsToUse;

    final selectedAddress = ref.watch(activeDeliveryAddressProvider);

    if (!_orderPlaced &&
        selectedAddress != null &&
        !_isEstimating &&
        _estimateError == null &&
        !cartState.isLoading &&
        vendorIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchEstimate();
      });
    }

    final rawDeliveryFee = (est != null && est['deliveryFee'] != null) ? (est['deliveryFee'] as num).toDouble() : 0.0;
    final driverBonusFee = (est != null && est['driverBonusFee'] != null) ? (est['driverBonusFee'] as num).toDouble() : 0.0;
    final driverBonusPaidByCustomer =
        (est?['driverBonusPaidByCustomer'] as bool?) ??
        (settings?.driverBonusPaidByCustomer ?? false);
    // Only add driver bonus to customer Delivery Fee when customer pays it.
    final deliveryFee = rawDeliveryFee + (driverBonusPaidByCustomer ? driverBonusFee : 0.0);
    final serviceFee = (est != null && est['serviceFee'] != null) ? (est['serviceFee'] as num).toDouble() : 0.0;
    final tax = (est != null && est['tax'] != null) ? (est['tax'] as num).toDouble() : 0.0;
    final hasEstimate = est != null;
    final estDiscount = hasEstimate ? ((est['discount'] as num?)?.toDouble() ?? 0.0) : 0.0;
    final totalWithFees = subtotal + deliveryFee + serviceFee + tax;

    // Coins can cover the entire order (products + delivery + fees + tax).
    // Send the full balance; the backend caps the discount at the grand total.
    double localCoinDiscount = 0;
    if (_useCoins && settings != null && coinState.currentBalance >= settings.minCoinsToUse) {
      coinsToUse = coinState.currentBalance;
      final maxCoinDiscount = coinState.currentBalance * settings.coinValue;
      localCoinDiscount = maxCoinDiscount > totalWithFees ? totalWithFees : maxCoinDiscount;
    }

    final coinDiscount = hasEstimate ? estDiscount : localCoinDiscount;
    final finalTotal = hasEstimate
        ? ((est['grandTotal'] as num?)?.toDouble() ?? totalWithFees)
        : totalWithFees - coinDiscount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.checkoutTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(vendorName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: _isProcessing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 36,
              ),
              children: [
                _sectionCard(s.deliveryAddress, [
                  if (profileState.addresses.isEmpty)
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_off, color: Colors.grey),
                        title: Text(
                            s.isArabic ? 'لا توجد عناوين' : 'No addresses found'),
                        subtitle: Text(s.isArabic
                            ? 'اضف عنواناً في الملف الشخصي'
                            : 'Add one in profile'),
                        trailing: TextButton(
                          onPressed: () => context.push('/addresses'),
                          child: Text(s.isArabic ? 'إضافة' : 'Add'),
                        ),
                      ),
                    )
                  else ...[
                    RadioGroup<String>(
                      groupValue: selectedAddress?['id']?.toString(),
                      onChanged: (val) {
                        ref
                            .read(manualSelectedAddressIdProvider.notifier)
                            .setAddressId(val);
                        setState(() {
                          _estimateError = null;
                          _estimate = null;
                          _lastEstimateKey = null;
                        });
                        _fetchEstimate(force: true);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: profileState.addresses
                            .map((addr) => Material(
                                  type: MaterialType.transparency,
                                  child: RadioListTile<String>(
                                    value: addr['id'].toString(),
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(addr['label'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text(addr['address'] ?? '',
                                        style: const TextStyle(fontSize: 12)),
                                    activeColor: AppColors.primary,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const Divider(height: 1, indent: 8, endIndent: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: s.isArabic ? Alignment.centerRight : Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.push('/addresses'),
                          icon: const Icon(Icons.add_location_alt_outlined, size: 18, color: AppColors.primary),
                          label: Text(
                            s.isArabic ? 'إضافة أو إدارة العناوين' : 'Add or Manage Addresses',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),
                _sectionCard(s.paymentMethod, [
                  RadioGroup<String>(
                    groupValue: _selectedPayment,
                    onChanged: (v) {
                      if (v != null && v != _selectedPayment) {
                        setState(() {
                          _selectedPayment = v;
                          _estimateError = null;
                          _estimate = null;
                          _lastEstimateKey = null;
                        });
                        _fetchEstimate(force: true);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _paymentOption(s.cashOnDelivery, Icons.delivery_dining_outlined, 'CASH_ON_DELIVERY'),
                        _paymentOption(s.mobileWallet, Icons.wallet_outlined, 'MOBILE_WALLET_VODAFONE'),
                        _paymentOption(s.instapay, Icons.account_balance_outlined, 'MOBILE_WALLET_INSTAPAY'),
                      ],
                    ),
                  ),
                  if (_selectedPayment.startsWith('MOBILE_WALLET'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                      child: Text(
                        s.isArabic
                            ? 'ملاحظة: سيتم عرض رقم محفظة المندوب لتحويل المبلغ إليه بعد تأكيد الطلب.'
                            : 'Note: You will be shown the driver\'s wallet number to transfer the amount after placing the order.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),
                _sectionCard(s.isArabic ? 'ملاحظات الطلب (اختياري)' : 'Order Notes (Optional)', [
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: s.isArabic
                          ? 'اكتب أي تعليمات خاصة للمطعم أو مندوب التوصيل...'
                          : 'Enter any special instructions for vendor or driver...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _sectionCard(s.orderSummary, [
                  if (isMultiVendor) ...[
                    ...vendorIds.map((vid) {
                      final basketItems = cartState.vendorBaskets[vid] ?? [];
                      if (basketItems.isEmpty) return const SizedBox.shrink();
                      final first = basketItems.first.product;
                      final storeName = s.isArabic
                          ? (first.vendorNameAr ?? first.vendorName ?? s.vendor)
                          : (first.vendorName ?? s.vendor);
                      final branch = ref.watch(selectedBranchProvider)[vid];
                      final bName = branch?.localizedName(s.isArabic);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppNetworkAvatar(
                                  imageUrl: ImageUtils.formatImageUrl(
                                    first.vendorLogo,
                                  ),
                                  size: 24,
                                  borderRadius: 6,
                                  fallbackIcon: Icons.storefront_rounded,
                                  fallbackIconSize: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$storeName${bName != null && bName.isNotEmpty ? ' • $bName' : ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${basketItems.length} ${s.isArabic ? 'منتجات' : 'items'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            ...basketItems.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                            s.isArabic
                                                ? (item.product.nameAr ?? item.product.name)
                                                : item.product.name,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold))),
                                    Text('x${item.quantity}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.totalPrice.toStringAsFixed(0)} ${s.egp}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ]),
                                  if (item.selectedUnit == 'strip')
                                    Container(
                                      margin: const EdgeInsets.only(top: 2, bottom: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        s.strip,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  if (item.selectedVariant != null)
                                    Text(
                                        item.selectedVariant!.localizedName(s.isArabic),
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                  if (item.selectedOptions.isNotEmpty)
                                    Text(
                                        item.selectedOptions
                                            .map((o) => o.localizedName(s.isArabic))
                                            .join(', '),
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.blueGrey)),
                                ],
                              ),
                            )),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    if (((est?['branchCount'] as num?)?.toInt() ?? 1) > 1) ...[
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${s.isArabic ? 'فروع التجهيز:' : 'Pickup Branches:'} ${est!['branchCount']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ] else if (branchName != null && branchName.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${s.isArabic ? 'الفرع:' : 'Branch:'} $branchName',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    ...vendorItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        s.isArabic
                                            ? (item.product.nameAr ?? item.product.name)
                                            : item.product.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold))),
                                Text('x${item.quantity}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.totalPrice.toStringAsFixed(0)} ${s.egp}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ]),
                              if (item.selectedUnit == 'strip')
                                Container(
                                  margin: const EdgeInsets.only(top: 2, bottom: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    s.strip,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              if (item.selectedVariant != null)
                                Text(
                                    item.selectedVariant!.localizedName(s.isArabic),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              if (item.selectedOptions.isNotEmpty)
                                Text(
                                    item.selectedOptions
                                        .map((o) => o.localizedName(s.isArabic))
                                        .join(', '),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.blueGrey)),
                            ],
                          ),
                        )),
                  ],
                  if (est != null && ((est['isSplit'] == true) || ((est['deliveryCount'] as num? ?? 1) > 1)))
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.isArabic
                                      ? 'سيتم توصيل هذا الطلب عبر ${est['deliveryCount']} شحنات منفصلة لضمان سرعة التوصيل.'
                                      : 'This order will be delivered in ${est['deliveryCount']} separate shipments for faster delivery.',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          if (est['groups'] is List && (est['groups'] as List).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...(est['groups'] as List).whereType<Map>().map((grp) {
                              final seq = grp['sequence'] ?? 1;
                              final dist = (grp['distanceKm'] as num?)?.toDouble();
                              final fee = (grp['deliveryFee'] as num?)?.toDouble();
                              return Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  s.isArabic
                                      ? '• الرحلة $seq${dist != null ? ' • ${dist.toStringAsFixed(1)} كم' : ''}${fee != null ? ' • ${fee.toStringAsFixed(0)} ${s.egp}' : ''}'
                                      : '• Trip $seq${dist != null ? ' • ${dist.toStringAsFixed(1)} km' : ''}${fee != null ? ' • ${fee.toStringAsFixed(0)} ${s.egp}' : ''}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.lightBlue.shade200 : Colors.blue.shade800,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  const Divider(),
                  _priceRow(
                      s.isArabic ? 'إجمالي المنتجات' : 'Items Subtotal',
                      '${subtotal.toStringAsFixed(0)} ${s.egp}'),
                  const SizedBox(height: 6),
                  _priceRow(
                      s.isArabic ? 'رسوم التوصيل' : 'Delivery Fee',
                      hasEstimate
                          ? '${deliveryFee.toStringAsFixed(0)} ${s.egp}${(est['deliveryCount'] as num? ?? 1) > 1 ? ' (${est['deliveryCount']} ${s.isArabic ? 'شحنات' : 'trips'})' : ''}'
                          : (_isEstimating ? '...' : '--')),
                  if (serviceFee > 0) ...[
                    const SizedBox(height: 6),
                    _priceRow(
                        s.isArabic ? 'رسوم الخدمة' : 'Service Fee',
                        '${serviceFee.toStringAsFixed(0)} ${s.egp}'),
                  ],

                  if (tax > 0) ...[
                    const SizedBox(height: 6),
                    _priceRow(
                        s.isArabic ? 'الضرائب' : 'Tax',
                        '${tax.toStringAsFixed(0)} ${s.egp}'),
                  ],
                  
                  if (coinState.currentBalance > 0 && settings != null && coinState.currentBalance >= settings.minCoinsToUse) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  s.isArabic ? 'استخدام ${coinState.currentBalance} عملة' : 'Use ${coinState.currentBalance} Coins',
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _useCoins,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _useCoins = val;
                              _estimateError = null;
                              _estimate = null;
                              _lastEstimateKey = null;
                            });
                            _fetchEstimate(force: true);
                          },
                        ),
                      ],
                    ),
                  ],
                  if (_useCoins && coinDiscount > 0) ...[
                    const SizedBox(height: 8),
                    _priceRow(s.isArabic ? 'خصم العملات' : 'Coin Discount', '-${coinDiscount.toStringAsFixed(0)} ${s.egp}'),
                  ],

                  if (isBelowMinOrder)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.isArabic
                                  ? 'الحد الأدنى للطلب هو ${minOrder.toStringAsFixed(0)} ${s.egp} (ينقصك ${minOrderDiff.toStringAsFixed(0)} ${s.egp})'
                                  : 'Minimum order amount is ${minOrder.toStringAsFixed(0)} ${s.egp} (${minOrderDiff.toStringAsFixed(0)} ${s.egp} remaining)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.isArabic ? 'المجموع الإجمالي' : 'Total',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              s.isArabic ? '(شامل جميع الرسوم)' : '(Including all fees)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '${finalTotal.toStringAsFixed(0)} ${s.egp}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppColors.primary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasEstimate && ((est['upfrontAmount'] as num?)?.toDouble() ?? 0.0) > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.isArabic
                                  ? 'مطلوب دفع مقدم: ${(est['upfrontAmount'] as num).toDouble().toStringAsFixed(0)} ${s.egp} (الباقي عند الاستلام: ${(finalTotal - (est['upfrontAmount'] as num).toDouble()).clamp(0, finalTotal).toStringAsFixed(0)} ${s.egp})'
                                  : 'Upfront payment required: ${(est['upfrontAmount'] as num).toDouble().toStringAsFixed(0)} ${s.egp} (Due at delivery: ${(finalTotal - (est['upfrontAmount'] as num).toDouble()).clamp(0, finalTotal).toStringAsFixed(0)} ${s.egp})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasEstimate && ((est['coinsEarned'] as num?)?.toInt() ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          s.isArabic
                              ? 'ستكسب ${est['coinsEarned']} عملة بعد إتمام هذا الطلب'
                              : 'You will earn ${est['coinsEarned']} coins upon completion',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_estimateError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ErrorUtils.translate(context, _estimateError ?? ''),
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: _isEstimating
                                ? null
                                : () => _fetchEstimate(force: true),
                            child: Text(
                              s.isArabic ? 'إعادة المحاولة' : 'Retry',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.isArabic
                                  ? 'كيف تُحسب رسوم التوصيل؟'
                                  : 'How is delivery fee calculated?',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.isArabic
                                  ? 'تُحسب رسوم التوصيل بناءً على المسافة بين الفرع والموقع المحدد لديك وتُعرض أعلاه. الرسوم نهائية ولن تتغير بعد تأكيد الطلب.'
                                  : 'Delivery fee is calculated based on the distance between the vendor branch and your selected address, and is shown above. Fees are final and will not change after placing the order.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isBelowMinOrder ||
                            _isProcessing ||
                            _isEstimating ||
                            _estimate == null ||
                            _estimateError != null)
                        ? null
                        : () => _placeOrder(s, vendorItems, coinsToUse, selectedAddress),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isBelowMinOrder || _estimateError != null) ? Colors.grey : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                        _estimateError != null
                            ? ErrorUtils.translate(context, _estimateError!)
                            : isBelowMinOrder
                            ? (s.isArabic ? 'المبلغ أقل من الحد الأدنى للطلب (${minOrder.toStringAsFixed(0)} ${s.egp})' : 'Below Min Order Amount (${minOrder.toStringAsFixed(0)} ${s.egp})')
                            : '${s.placeOrder} (${finalTotal.toStringAsFixed(0)} ${s.egp})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _paymentOption(String title, IconData icon, String val) {
    final isSelected = _selectedPayment == val;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: () {
          if (_selectedPayment != val) {
            setState(() {
              _selectedPayment = val;
              _estimateError = null;
              _estimate = null;
              _lastEstimateKey = null;
            });
            _fetchEstimate(force: true);
          }
        },
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
        title: Text(title),
        trailing: Radio<String>(
          value: val,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _priceRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            val,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ]),
    );
  }
}
