import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';

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
    if (widget.vendorIds != null && widget.vendorIds!.isNotEmpty) {
      return widget.vendorIds!;
    }
    if (widget.vendorId != null && widget.vendorId!.isNotEmpty) {
      return [widget.vendorId!];
    }
    final cart = ref.read(cartProvider);
    return cart.vendorBaskets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  String _selectedPayment = 'CASH_ON_DELIVERY';
  bool _isProcessing = false;
  bool _useCoins = false;
  bool _isEstimating = false;
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

  Future<void> _fetchEstimate() async {
    if (_isEstimating) return;
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

    final estimateKey = '${vendorIds.join(",")}|${coords[0]},${coords[1]}|$_selectedPayment|${coinsToUse ?? 0}|$cartFingerprint';
    if (estimateKey == _lastEstimateKey) return;
    _lastEstimateKey = estimateKey;

    setState(() => _isEstimating = true);
    try {
      final result = isMultiVendor
          ? await ref.read(ordersProvider.notifier).estimateMultiVendorOrder(
              vendorIds: vendorIds,
              paymentMethod: _selectedPayment,
              address: selectedAddress['address'] ?? '',
              location: coords,
              coinsToUse: coinsToUse,
            )
          : await ref.read(ordersProvider.notifier).estimateOrder(
              vendorId: vendorIds.first,
              paymentMethod: _selectedPayment,
              address: selectedAddress['address'] ?? '',
              location: coords,
              coinsToUse: coinsToUse,
            );
      if (mounted) {
        setState(() {
          _estimate = result;
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
        setState(() {
          _estimate = null;
          _estimateError = message ?? e.toString();
          _isEstimating = false;
        });
      }
    }
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
    if (vendorIds.isEmpty) return;

    if (isMultiVendor) {
      final (errorMsg, orderId) = await ref.read(ordersProvider.notifier).placeMultiVendorOrder(
            vendorIds: vendorIds,
            paymentMethod: _selectedPayment.startsWith('MOBILE_WALLET')
                ? 'MOBILE_WALLET'
                : 'CASH_ON_DELIVERY',
            address: selectedAddress['address'] ?? s.locationName,
            location: coords,
            specialRequest: specialRequest,
            coinsToUse: coinsToUse,
            idempotencyKey: _clientOrderKeyForCheckout(),
          );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (errorMsg == null && orderId != null) {
          _clientOrderKey = null;
          for (final vid in vendorIds) {
            ref.read(cartProvider.notifier).clearVendorCart(vid);
          }
          _showSuccess(s, orderId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ErrorUtils.translate(context, errorMsg ?? 'Failed to place order')),
              backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      final (errorMsg, orderId) = await ref.read(ordersProvider.notifier).placeOrder(
            vendorId: vendorIds.first,
            items: vendorItems,
            paymentMethod: _selectedPayment.startsWith('MOBILE_WALLET')
                ? 'MOBILE_WALLET'
                : 'CASH_ON_DELIVERY',
            address: selectedAddress['address'] ?? s.locationName,
            location: coords,
            specialRequest: specialRequest,
            coinsToUse: coinsToUse,
            idempotencyKey: _clientOrderKeyForCheckout(),
          );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (errorMsg == null && orderId != null) {
          _clientOrderKey = null;
          ref.read(cartProvider.notifier).clearVendorCart(vendorIds.first);
          _showSuccess(s, orderId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ErrorUtils.translate(context, errorMsg ?? 'Failed to place order')),
              backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  void _showSuccess(AppStrings s, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 150,
            width: 150,
            child: Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json',
              repeat: false,
              errorBuilder: (c, e, st) =>
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.orderSuccess,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(s.orderSuccessSub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.pop();
                context.go('/home');
                context.push('/order-tracking/$orderId');
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(s.goToOrders, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.pop();
              context.go('/home');
            },
            child: Text(s.navHome),
          ),
        ]),
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

    if (vendorIds.isEmpty || !hasAnyItems) {
      if (cartState.vendorBaskets.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
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
                onPressed: () => context.pop())),
        body: Center(child: Text(s.emptyCart)),
      );
    }

    final vendorItems = isMultiVendor
        ? vendorIds.expand((vid) => cartState.vendorBaskets[vid] ?? <CartItem>[]).toList()
        : (cartState.vendorBaskets[vendorIds.first] ?? []);
    final selectedBranch = !isMultiVendor && vendorIds.isNotEmpty
        ? ref.watch(selectedBranchProvider)[vendorIds.first]
        : null;
    final branchName = selectedBranch?.localizedName(s.isArabic);
    final vendorName = isMultiVendor
        ? (s.isArabic ? 'عدة متاجر (${vendorIds.length})' : 'Multiple Stores (${vendorIds.length})')
        : (vendorItems.isNotEmpty
            ? '${vendorItems.first.product.vendorName ?? s.vendor}${branchName != null && branchName.isNotEmpty ? ' • $branchName' : ''}'
            : s.vendor);
    final subtotal = isMultiVendor
        ? vendorIds.fold(0.0, (acc, vid) => acc + cartState.getVendorSubtotal(vid))
        : cartState.getVendorSubtotal(vendorIds.first);
    final settings = ref.watch(platformSettingsProvider).value;

    final minOrder = (settings?.minOrderAmount != null) ? settings!.minOrderAmount.toDouble() : 0.0;
    final isBelowMinOrder = minOrder > 0 && subtotal < minOrder;
    final minOrderDiff = isBelowMinOrder ? (minOrder - subtotal) : 0.0;

    final coinState = ref.watch(coinHistoryProvider);
    int? coinsToUse;

    final selectedAddress = ref.watch(activeDeliveryAddressProvider);

    if (selectedAddress != null && !_isEstimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchEstimate();
      });
    }

    final est = _estimate;
    final rawDeliveryFee = (est != null && est['deliveryFee'] != null) ? (est['deliveryFee'] as num).toDouble() : 0.0;
    final driverBonusFee = (est != null && est['driverBonusFee'] != null) ? (est['driverBonusFee'] as num).toDouble() : 0.0;
    // Driver bonus is an internal platform incentive — fold into customer Delivery Fee
    final deliveryFee = rawDeliveryFee + driverBonusFee;
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
                    ...profileState.addresses.map((addr) => Material(
                          type: MaterialType.transparency,
                          child: RadioListTile<String>(
                            value: addr['id'],
                            groupValue: selectedAddress?['id'],
                            onChanged: (val) =>
                                ref.read(manualSelectedAddressIdProvider.notifier).setAddressId(val),
                            contentPadding: EdgeInsets.zero,
                            title: Text(addr['label'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(addr['address'] ?? '',
                                style: const TextStyle(fontSize: 12)),
                            activeColor: AppColors.primary,
                          ),
                        )),
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
                  _paymentOption(s.cashOnDelivery, Icons.delivery_dining_outlined, 'CASH_ON_DELIVERY'),
                  _paymentOption(s.mobileWallet, Icons.wallet_outlined, 'MOBILE_WALLET_VODAFONE'),
                  _paymentOption(s.instapay, Icons.account_balance_outlined, 'MOBILE_WALLET_INSTAPAY'),
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
                                const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$storeName${bName != null && bName.isNotEmpty ? ' • $bName' : ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                        child: Text(item.product.name,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold))),
                                    Text('x${item.quantity}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                          '${item.totalPrice.toStringAsFixed(0)} ${s.egp}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false),
                                    ),
                                  ]),
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
                    if (est != null && ((est['isSplit'] == true) || ((est['deliveryCount'] as num? ?? 1) > 1)))
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
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
                      ),
                  ] else ...[
                    if (branchName != null && branchName.isNotEmpty) ...[
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
                                    child: Text(item.product.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold))),
                                Text('x${item.quantity}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                      '${item.totalPrice.toStringAsFixed(0)} ${s.egp}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false),
                                ),
                              ]),
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
                  const Divider(),
                  _priceRow(
                      s.isArabic ? 'إجمالي المنتجات' : 'Items Subtotal',
                      '${subtotal.toStringAsFixed(0)} ${s.egp}'),
                  const SizedBox(height: 6),
                  _priceRow(
                      s.isArabic ? 'رسوم التوصيل' : 'Delivery Fee',
                      hasEstimate
                          ? '${deliveryFee.toStringAsFixed(0)} ${s.egp}${isMultiVendor && (est['deliveryCount'] as num? ?? 1) > 1 ? ' (${est['deliveryCount']} ${s.isArabic ? 'شحنات' : 'trips'})' : ''}'
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
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              s.isArabic ? 'استخدام ${coinState.currentBalance} عملة' : 'Use ${coinState.currentBalance} Coins',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        Switch(
                          value: _useCoins,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _useCoins = val;
                            });
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
                    children: [
                      Column(
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
                      Text(
                        '${finalTotal.toStringAsFixed(0)} ${s.egp}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
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
        onTap: () => setState(() => _selectedPayment = val),
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
        title: Text(title),
        trailing: Radio(
            value: val,
            groupValue: _selectedPayment,
            onChanged: (v) => setState(() => _selectedPayment = v as String),
            activeColor: AppColors.primary),
      ),
    );
  }

  Widget _priceRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(val,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
