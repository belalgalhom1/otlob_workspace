import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/cart_controller.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../profile/presentation/providers/coin_history_provider.dart';
import '../../../profile/presentation/providers/delivery_address_provider.dart';
import '../../../../core/providers/platform_settings_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? vendorId;
  const CheckoutScreen({super.key, required this.vendorId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPayment = 'CASH_ON_DELIVERY';
  bool _isProcessing = false;
  bool _useCoins = false;

  void _placeOrder(AppStrings s, List<CartItem> vendorItems, int? coinsToUse, Map<String, dynamic>? selectedAddress) async {
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isArabic ? 'الرجاء اختيار عنوان' : 'Please select an address')));
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

    final (errorMsg, orderId) = await ref.read(ordersProvider.notifier).placeOrder(
          vendorId: widget.vendorId ?? '',
          items: vendorItems,
          paymentMethod: _selectedPayment.startsWith('MOBILE_WALLET')
              ? 'MOBILE_WALLET'
              : 'CASH_ON_DELIVERY',
          address: selectedAddress['address'] ?? s.locationName,
          location: coords,
          coinsToUse: coinsToUse,
        );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (errorMsg == null && orderId != null) {
        ref.read(cartProvider.notifier).clearVendorCart(widget.vendorId ?? '');
        _showSuccess(s, orderId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.translateApiError(errorMsg ?? 'Failed to place order')),
            backgroundColor: Colors.red,
        ));
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
    final cartState = ref.watch(cartProvider);
    final profileState = ref.watch(profileProvider);

    if (widget.vendorId == null ||
        !cartState.vendorBaskets.containsKey(widget.vendorId)) {
      return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop())),
        body: Center(child: Text(s.emptyCart)),
      );
    }

    final vendorItems = cartState.vendorBaskets[widget.vendorId ?? ''] ?? [];
    final vendorName = vendorItems.isNotEmpty
        ? (vendorItems.first.product['vendorName'] as String? ?? s.vendor)
        : s.vendor;
    final subtotal = cartState.getVendorSubtotal(widget.vendorId ?? '');

    final settings = ref.watch(platformSettingsProvider).value;
    final deliveryFee = double.tryParse(settings?.baseDeliveryFee?.toString() ?? '0') ?? 0.0;
    final serviceFee = 0.0;

    final total = subtotal;
    
    final coinState = ref.watch(coinHistoryProvider);
    final settings = ref.watch(platformSettingsProvider).value;
    double coinDiscount = 0;
    int? coinsToUse;

    if (_useCoins && settings != null && coinState.currentBalance >= settings.minCoinsToUse) {
      final maxCoinDiscount = coinState.currentBalance * settings.coinValue;
      if (maxCoinDiscount > total) {
        // Cap — only use as many coins as needed to cover the total
        coinDiscount = total;
        coinsToUse = (total / settings.coinValue).ceil();
      } else {
        coinDiscount = maxCoinDiscount;
        coinsToUse = coinState.currentBalance;
      }
    }
    
    final finalTotal = total - coinDiscount;

    final selectedAddress = ref.watch(activeDeliveryAddressProvider);

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
              padding: const EdgeInsets.all(16),
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
                _sectionCard(s.orderSummary, [
                  ...vendorItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(item.product['name'] as String,
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
                                      fontWeight: FontWeight.bold)),
                            ]),
                            if (item.selectedVariant != null)
                              Text(
                                  s.isArabic
                                      ? (item.selectedVariant!['nameAr'] ??
                                          item.selectedVariant!['name'])
                                      : item.selectedVariant!['name'],
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            if (item.selectedOptions.isNotEmpty)
                              Text(
                                  item.selectedOptions
                                      .map((o) => s.isArabic
                                          ? (o['nameAr'] ?? o['name'])
                                          : o['name'])
                                      .join(', '),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.blueGrey)),
                          ],
                        ),
                      )),
                  const Divider(),
                  _priceRow(
                      s.subtotal, '${subtotal.toStringAsFixed(0)} ${s.egp}'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.isArabic ? 'رسوم التوصيل والخدمة' : 'Delivery & Service Fees',
                            style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        Text(s.isArabic ? 'تحدد لاحقاً' : 'Calculated later',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                      ],
                    ),
                  ),
                  
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
                  
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.total,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${finalTotal.toStringAsFixed(0)} ${s.egp}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.primary)),
                      ]),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _placeOrder(s, vendorItems, coinsToUse, selectedAddress),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                        '${s.placeOrder} (${finalTotal.toStringAsFixed(0)} ${s.egp})',
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
