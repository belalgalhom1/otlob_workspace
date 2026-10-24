import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_utils.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/cart_controller.dart';
import '../../../home/presentation/providers/vendor_detail_controller.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/delivery_address_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  /// Server estimates per vendor basket (same source as checkout).
  final Map<String, Map<String, dynamic>?> _estimates = {};
  final Map<String, bool> _estimating = {};
  String? _estimateAddressId;

  Future<void> _fetchBasketEstimate(String vendorId) async {
    if (_estimating[vendorId] == true) return;
    final address = ref.read(activeDeliveryAddressProvider);
    if (address == null) return;
    final loc = address['location'];
    List<double> coords = [];
    if (loc is List) {
      coords = loc.map((e) => (e as num).toDouble()).toList();
    } else if (loc is Map && loc['coordinates'] is List) {
      coords = (loc['coordinates'] as List).map((e) => (e as num).toDouble()).toList();
    }
    if (coords.length != 2) return;
    _estimating[vendorId] = true;
    try {
      final result = await ref.read(ordersProvider.notifier).estimateOrder(
            vendorId: vendorId,
            paymentMethod: 'CASH_ON_DELIVERY',
            address: address['address']?.toString() ?? '',
            location: coords,
          );
      if (mounted) {
        setState(() {
          _estimates[vendorId] = result;
          _estimating[vendorId] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _estimating[vendorId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cartState = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFBFBFB),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          s.cart, 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black,
          )
        ),
        actions: [
          if (cartState.vendorBaskets.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: IconButton(
                onPressed: () => _showClearConfirmation(context, ref, s),
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                tooltip: s.clearAll,
              ),
            ),
        ],
      ),
      body: cartState.vendorBaskets.isEmpty
          ? _buildEmptyCart(context, s, isDark)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: cartState.vendorBaskets.length,
              itemBuilder: (context, index) {
                final vendorId = cartState.vendorBaskets.keys.elementAt(index);
                final vendorItems = cartState.vendorBaskets[vendorId] ?? [];
                return _buildVendorBasket(context, ref, vendorId, vendorItems, s, isDark);
              },
            ),
      bottomNavigationBar: cartState.vendorBaskets.length > 1
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.isArabic ? 'طلب متعدد المتاجر' : 'Combined Multi-Vendor Order',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            s.isArabic
                                ? '${cartState.vendorBaskets.length} متاجر • ${cartState.totalItems} منتجات'
                                : '${cartState.vendorBaskets.length} stores • ${cartState.totalItems} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final anyClosed = cartState.vendorBaskets.values.any((items) =>
                            items.isNotEmpty && (items.first.product.vendorStatus ?? 'OPEN') != 'OPEN');
                        if (anyClosed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.isArabic
                                  ? 'أحد المتاجر في سلتك مغلق حالياً. يرجى إزالة منتجاته للمتابعة'
                                  : 'One of the stores in your cart is currently closed. Please remove its items to proceed'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final anyInactive = cartState.vendorBaskets.values.any((items) =>
                            items.any((it) => !it.product.isActive || (it.selectedVariant != null && !it.selectedVariant!.isActive)));
                        if (anyInactive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.isArabic
                                  ? 'يحتوي طلبك على منتجات غير متوفرة حالياً. الرجاء حذفها للمتابعة.'
                                  : 'Your basket contains unavailable items. Please remove them to proceed.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final activeVendorIds = cartState.vendorBaskets.entries
                            .where((e) => e.value.isNotEmpty)
                            .map((e) => e.key)
                            .toList();
                        context.push('/checkout', extra: activeVendorIds);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        s.isArabic ? 'إتمام طلب الكل' : 'Checkout All',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyCart(BuildContext context, AppStrings s, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_outlined, 
              size: 120, 
              color: isDark ? Colors.white12 : Colors.grey.shade200
            ),
          ),
          const SizedBox(height: 32),
          Text(
            s.emptyCart, 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black
            )
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              s.emptyCartSub, 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600, 
                fontSize: 16,
                height: 1.5
              )
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(200, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: Text(
              s.browseNow, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
            ),
          ),
        ]
      )
    );
  }

  Widget _buildVendorBasket(BuildContext context, WidgetRef ref, String vendorId, List<CartItem> items, AppStrings s, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();

    final firstProduct = items.first.product;
    final vendorName = s.isArabic
        ? (firstProduct.vendorNameAr ?? firstProduct.vendorName ?? s.vendor)
        : (firstProduct.vendorName ?? s.vendor);
    final vendorStatus = firstProduct.vendorStatus ?? 'OPEN';
    final isVendorOpen = vendorStatus == 'OPEN';
    final hasInactiveItems = items.any((it) => !it.product.isActive || (it.selectedVariant != null && !it.selectedVariant!.isActive));
    final subtotal = ref.read(cartProvider).getVendorSubtotal(vendorId);
    final canCheckout = isVendorOpen && !hasInactiveItems;

    // Same server estimate as checkout (items subtotal / delivery / tax /
    // total) so the cart shows real numbers instead of
    // "determined upon driver match".
    final activeAddress = ref.watch(activeDeliveryAddressProvider);
    final hasAddress = activeAddress != null;
    // Delivery depends on the address — drop cached estimates when it changes.
    final addressId = activeAddress?['id']?.toString();
    if (addressId != _estimateAddressId) {
      _estimateAddressId = addressId;
      _estimates.clear();
      _estimating.clear();
    }
    // NOTE: containsKey (not == null) is the "already tried" marker — a
    // null estimate from the server must not refetch on every build.
    final triedEstimate = _estimates.containsKey(vendorId);
    final est = _estimates[vendorId];
    final estimating = _estimating[vendorId] == true;
    if (hasAddress && !triedEstimate && !estimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchBasketEstimate(vendorId);
      });
    }
    final selectedBranch = ref.watch(selectedBranchProvider)[vendorId];
    final branchName = selectedBranch?.localizedName(s.isArabic);
    double toNum(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    final rawDeliveryFee = est != null ? toNum(est['deliveryFee']) : 0.0;
    final driverBonusFee = est != null ? toNum(est['driverBonusFee']) : 0.0;
    // Fold driverBonusFee into deliveryFee for clean customer display
    final deliveryFee = rawDeliveryFee + driverBonusFee;
    final serviceFee = est != null ? toNum(est['serviceFee']) : 0.0;
    final tax = est != null ? toNum(est['tax']) : 0.0;
    final total = est != null
        ? toNum(est['grandTotal'] ?? (subtotal + deliveryFee + serviceFee + tax))
        : subtotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), 
            blurRadius: 24, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vendor Header
          InkWell(
            onTap: () => context.push('/vendor', extra: {
              'id': vendorId,
              'storeName': firstProduct.vendorName,
              'storeNameAr': firstProduct.vendorNameAr,
              'logo': firstProduct.vendorLogo,
              'coverImage': firstProduct.vendorCoverImage,
              'image': firstProduct.vendorCoverImage,
            }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (firstProduct.vendorLogo?.isEmpty ?? true)
                        ? Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                          )
                        : CachedNetworkImage(
                            imageUrl: ImageUtils.formatImageUrl(firstProduct.vendorLogo),
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 40, width: 40,
                              color: isDark ? Colors.white12 : Colors.grey.shade100,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            errorWidget: (context, url, error) => Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorName, 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                        if (branchName != null && branchName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${s.isArabic ? "فرع" : "Branch"}: $branchName',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : Colors.black54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isVendorOpen)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s.isArabic ? 'مغلق حالياً' : 'Closed Now',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    s.isArabic ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded, 
                    size: 14, 
                    color: isDark ? Colors.white24 : Colors.black26
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(indent: 20, endIndent: 20, height: 32),

          // Items List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: items.map((item) => _buildCartItem(context, ref, item, s, isDark)).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Basket Footer / Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                if (hasInactiveItems)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.isArabic
                                ? 'يحتوي طلبك على منتجات غير متوفرة حالياً. الرجاء حذفها للمتابعة.'
                                : 'Your basket contains unavailable items. Please remove them to proceed.',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildSummaryRow(s.isArabic ? 'إجمالي المنتجات' : 'Items Subtotal', '${subtotal.toStringAsFixed(0)} ${s.egp}', isDark),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  s.isArabic ? 'رسوم التوصيل' : 'Delivery Fee',
                  est != null
                      ? '${deliveryFee.toStringAsFixed(0)} ${s.egp}'
                      : (estimating ? '...' : '--'),
                  isDark,
                  isDelivery: est != null,
                ),
                if (serviceFee > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    s.isArabic ? 'رسوم الخدمة' : 'Service Fee',
                    '${serviceFee.toStringAsFixed(0)} ${s.egp}',
                    isDark,
                  ),
                ],
                if (est != null) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    s.isArabic ? 'الضرائب' : 'Tax',
                    '${tax.toStringAsFixed(0)} ${s.egp}',
                    isDark,
                  ),
                ],
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.isArabic ? 'المجموع الإجمالي' : 'Total',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          est != null
                              ? (s.isArabic ? '(شامل جميع الرسوم)' : '(Including all fees)')
                              : (s.isArabic ? '(غير شامل التوصيل)' : '(Excl. delivery)'),
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${total.toStringAsFixed(0)} ${s.egp}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: canCheckout
                          ? () => context.push('/checkout', extra: vendorId)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    !isVendorOpen
                                        ? (s.isArabic ? 'المتجر مغلق حالياً ولا يستقبل طلبات' : 'Store is currently closed')
                                        : (s.isArabic ? 'الرجاء إزالة المنتجات غير المتوفرة للمتابعة' : 'Please remove unavailable items to proceed'),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCheckout ? AppColors.primary : Colors.grey,
                        foregroundColor: canCheckout ? Colors.black : Colors.white70,
                        minimumSize: const Size(120, 54),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(s.checkout, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isDelivery = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        Text(
          value, 
          style: TextStyle(
            color: isDelivery && value.startsWith('0') ? AppColors.success : (isDark ? Colors.white : Colors.black), 
            fontSize: 14, 
            fontWeight: FontWeight.w800
          )
        ),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item, AppStrings s, bool isDark) {
    final isInactive = !item.product.isActive || (item.selectedVariant != null && !item.selectedVariant!.isActive);
    final comparePrice =
        item.selectedVariant?.comparePrice ?? item.product.comparePrice;
    final itemUnitPrice = item.totalPrice / (item.quantity > 0 ? item.quantity : 1);
    final hasDiscount = comparePrice != null && comparePrice > itemUnitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (item.product.imageUrl?.isEmpty ?? true)
                    ? Container(height: 80, width: 80, color: isDark ? Colors.white12 : Colors.grey.shade100, child: const Icon(Icons.fastfood, color: Colors.grey))
                    : CachedNetworkImage(imageUrl: ImageUtils.formatImageUrl(item.product.imageUrl), height: 80, width: 80, fit: BoxFit.cover),
              ),
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(item, 0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  item.product.localizedName(s.isArabic), 
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 15, 
                    color: isInactive ? Colors.grey : (isDark ? Colors.white : Colors.black),
                    decoration: isInactive ? TextDecoration.lineThrough : null,
                  ), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                if (isInactive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      s.isArabic ? 'غير متوفر حالياً' : 'Currently Unavailable',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (item.selectedUnit == 'strip')
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(s.strip, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                if (item.selectedVariant != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.selectedVariant!.localizedName(s.isArabic),
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (item.selectedOptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.selectedOptions.map((o) => o.localizedName(s.isArabic)).join(', '),
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                // Wrap (not Row): the full price always shows — it flows
                // to the next line on narrow screens instead of overflowing
                // into the image or getting cut with "...".
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${item.totalPrice.toStringAsFixed(0)} ${s.egp}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    if (hasDiscount)
                      Text(
                        '${(comparePrice * item.quantity).toStringAsFixed(0)} ${s.egp}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ]
            )
          ),
          
          const SizedBox(width: 12),

          // Quantity Pill
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, 
              borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                _qtyBtn(Icons.remove, isDark, () => ref.read(cartProvider.notifier).updateQuantity(item, item.quantity - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), 
                  child: Text('${item.quantity}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87))
                ),
                _qtyBtn(Icons.add, isDark, () => ref.read(cartProvider.notifier).updateQuantity(item, item.quantity + 1)),
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, bool isDark, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8), 
        child: Icon(icon, size: 18, color: AppColors.primary)
      ),
    ),
  );

  void _showClearConfirmation(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.clearAll, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(s.emptyCartSub), // Reusing string for confirmation
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          TextButton(
            onPressed: () async {
              // Show a simple loading indicator or just await the remote operation
              await ref.read(cartProvider.notifier).clearCart();
              if (context.mounted) {
                Navigator.pop(context);
              }
            }, 
            child: Text(s.yes, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
