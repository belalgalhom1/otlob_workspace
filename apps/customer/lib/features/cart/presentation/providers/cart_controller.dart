import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:flutter/foundation.dart';

import 'cart_models.dart';
export 'cart_models.dart' show CartItem, CartProductRef, CartVariantRef, CartOptionRef;

part 'cart_controller.g.dart';

/// Canonical key for a raw option selection (order-independent). Used only
/// for vendor-menu maps that never enter the cart domain as models.
String _optionsKey(List<Map<String, dynamic>> options) {
  final ids = options
      .map((o) => o['id']?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .toList()
    ..sort();
  return ids.join(',');
}

class CartState {
  final Map<String, List<CartItem>> vendorBaskets;

  const CartState({required this.vendorBaskets});

  int get totalItems {
    int count = 0;
    for (final vendorItems in vendorBaskets.values) {
      for (final item in vendorItems) {
        count += item.quantity;
      }
    }
    return count;
  }

  List<CartItem> get allItems {
    return vendorBaskets.values.expand((items) => items).toList();
  }

  double getVendorSubtotal(String vendorId) {
    final basket = vendorBaskets[vendorId];
    if (basket == null) return 0.0;
    return basket.fold(
      0.0,
      (total, item) => total + item.totalPrice,
    );
  }
}

@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  @override
  CartState build() {
    _loadCarts();
    return const CartState(vendorBaskets: {});
  }

  List<CartItem> _parseCartItems(
    List<dynamic>? rawItems,
    String vendorId,
    Map<String, dynamic>? vendorJson, {
    String defaultUnit = 'package',
  }) {
    if (rawItems == null) return [];
    final vendorName = vendorJson?['storeName'];
    final vendorNameAr = vendorJson?['storeNameAr'];
    final vendorLogo = vendorJson?['logo'];
    final vendorCoverImage = vendorJson?['coverImage'];
    final commissionRate = vendorJson?['commissionRate'];
    final isContracted = vendorJson?['isContracted'];
    final vendorStatus = vendorJson?['status'] ?? 'OPEN';

    final List<CartItem> items = [];
    for (final i in rawItems) {
      final itemJson = Map<String, dynamic>.from(i as Map);
      final productJson = Map<String, dynamic>.from(itemJson['product'] as Map? ?? {});
      final unitPrice = (itemJson['unitPrice'] as num?)?.toDouble();
      final totalPrice = (itemJson['totalPrice'] as num?)?.toDouble();

      final itemProduct = Map<String, dynamic>.from(productJson);
      if (unitPrice != null) itemProduct['price'] = unitPrice;
      if (productJson['comparePrice'] != null) {
        itemProduct['comparePrice'] = productJson['comparePrice'];
      }
      itemProduct['vendorId'] = vendorId;
      itemProduct['vendorName'] = vendorName;
      itemProduct['vendorNameAr'] = vendorNameAr;
      itemProduct['vendorLogo'] = vendorLogo;
      itemProduct['vendorCoverImage'] = vendorCoverImage;
      itemProduct['commissionRate'] = commissionRate;
      itemProduct['isContracted'] = isContracted;
      itemProduct['vendorStatus'] = vendorStatus;

      items.add(CartItem(
        backendId: itemJson['id']?.toString(),
        product: CartProductRef.fromJson(itemProduct),
        quantity: (itemJson['quantity'] as num?)?.toInt() ?? 1,
        selectedUnit: (itemJson['selectedUnit'] as String?) ?? defaultUnit,
        selectedVariant: itemJson['variant'] != null
            ? CartVariantRef.fromJson(
                Map<String, dynamic>.from(itemJson['variant'] as Map))
            : null,
        selectedOptions: itemJson['options'] != null
            ? (itemJson['options'] as List)
                .map((o) =>
                    CartOptionRef.fromJson(Map<String, dynamic>.from(o as Map)))
                .toList()
            : [],
        unitPrice: unitPrice,
        backendTotalPrice: totalPrice,
      ));
    }
    return items;
  }

  Future<void> _loadCarts() async {
    try {
      final cartRepo = ref.read(customerCartRepositoryProvider);
      final carts = await cartRepo.getMyCarts();
      
      final Map<String, List<CartItem>> baskets = {};
      
      if (carts is List) {
        for (final c in carts) {
          final cartJson = Map<String, dynamic>.from(c as Map);
          final vendorId = cartJson['vendorId'] as String;
          final vendorJson = cartJson['vendor'] as Map<String, dynamic>?;
          final items = _parseCartItems(cartJson['items'] as List?, vendorId, vendorJson);
          baskets[vendorId] = items;
        }
      }
      
      state = CartState(vendorBaskets: baskets);
    } catch (e) {
      debugPrint('Error loading carts: $e');
    }
  }

  Future<void> addItem(
    Map<String, dynamic> product, {
    String unit = 'package',
    Map<String, dynamic>? variant,
    List<Map<String, dynamic>> options = const [],
  }) async {
    final vendorId = product['vendorId'] as String;
    
    try {
      final cartRepo = ref.read(customerCartRepositoryProvider);

      final response = await cartRepo.addItem(
        vendorId,
        productId: product['id']?.toString(),
        quantity: 1,
        selectedUnit: unit,
        variantId: variant?['id']?.toString(),
        optionIds: options
            .map((o) => o['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
        offerMessageId: product['offerMessageId']?.toString(),
      );

      if (response != null && response is Map) {
        final updatedCart = Map<String, dynamic>.from(response);
        final vendorJson = updatedCart['vendor'] as Map<String, dynamic>?;
        final items = _parseCartItems(updatedCart['items'] as List?, vendorId, vendorJson, defaultUnit: unit);
        
        final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
        currentBaskets[vendorId] = items;
        state = CartState(vendorBaskets: currentBaskets);
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(CartItem cartItem, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItemExact(cartItem);
      return;
    }

    String? vendorId = cartItem.product.vendorId;
    if (vendorId == null) {
      for (final entry in state.vendorBaskets.entries) {
        if (entry.value.any((item) => item.backendId == cartItem.backendId || item.product.id == cartItem.product.id)) {
          vendorId = entry.key;
          break;
        }
      }
    }
    if (vendorId == null || cartItem.backendId == null) return;

    try {
      final cartRepo = ref.read(customerCartRepositoryProvider);
      
      final response = await cartRepo.updateItem(
        vendorId,
        cartItem.backendId!,
        quantity: newQuantity,
      );

      if (response != null && response is Map) {
        final updatedCart = Map<String, dynamic>.from(response);
        final vendorJson = updatedCart['vendor'] as Map<String, dynamic>?;
        final items = _parseCartItems(updatedCart['items'] as List?, vendorId, vendorJson, defaultUnit: cartItem.selectedUnit);

        final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
        currentBaskets[vendorId] = items;
        state = CartState(vendorBaskets: currentBaskets);
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> _removeItemExact(CartItem cartItem) async {
    String? vendorId = cartItem.product.vendorId;
    if (vendorId == null) {
      for (final entry in state.vendorBaskets.entries) {
        if (entry.value.any((item) => item.backendId == cartItem.backendId || item.product.id == cartItem.product.id)) {
          vendorId = entry.key;
          break;
        }
      }
    }
    if (vendorId == null || cartItem.backendId == null) return;

    try {
      final cartRepo = ref.read(customerCartRepositoryProvider);
      await cartRepo.removeItem(vendorId, cartItem.backendId!);
      
      final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
      final vendorItems = List<CartItem>.from(currentBaskets[vendorId]!);
      
      vendorItems.removeWhere((item) =>
        (item.backendId != null && item.backendId == cartItem.backendId) ||
        (item.product.id == cartItem.product.id &&
            item.variantId == cartItem.variantId &&
            item.selectedUnit == cartItem.selectedUnit &&
            item.optionsKey == cartItem.optionsKey));
      
      if (vendorItems.isEmpty) {
        currentBaskets.remove(vendorId);
      } else {
        currentBaskets[vendorId] = vendorItems;
      }
      
      state = CartState(vendorBaskets: currentBaskets);
    } catch (e) {
      debugPrint('Error removing item: $e');
    }
  }

  Future<void> clearVendorCart(String vendorId) async {
    try {
      final cartRepo = ref.read(customerCartRepositoryProvider);
      await cartRepo.clearCart(vendorId);
      
      final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
      currentBaskets.remove(vendorId);
      state = CartState(vendorBaskets: currentBaskets);
    } catch (e) {
      debugPrint('Error clearing vendor cart: $e');
    }
  }

  Future<void> clearCart() async {
    final vendorIds = state.vendorBaskets.keys.toList();
    for (final vendorId in vendorIds) {
      try {
        final cartRepo = ref.read(customerCartRepositoryProvider);
        await cartRepo.clearCart(vendorId);
      } catch (e) {
        debugPrint('Error clearing vendor cart $vendorId on remote: $e');
      }
    }
    state = const CartState(vendorBaskets: {});
  }
}
