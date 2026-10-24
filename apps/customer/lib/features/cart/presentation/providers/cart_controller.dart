import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

import 'cart_models.dart';
export 'cart_models.dart' show CartItem, CartProductRef, CartVariantRef, CartOptionRef;

part 'cart_controller.g.dart';

class CartState {
  final Map<String, List<CartItem>> vendorBaskets;
  final bool isLoading;

  const CartState({
    required this.vendorBaskets,
    this.isLoading = false,
  });

  CartState copyWith({
    Map<String, List<CartItem>>? vendorBaskets,
    bool? isLoading,
  }) {
    return CartState(
      vendorBaskets: vendorBaskets ?? this.vendorBaskets,
      isLoading: isLoading ?? this.isLoading,
    );
  }

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
    ref.listen<AuthStatus>(authControllerProvider, (prev, next) {
      if (next == AuthStatus.authenticated) {
        _loadCarts();
      } else if (next == AuthStatus.unauthenticated) {
        clearLocal();
      }
    });

    final authStatus = ref.read(authControllerProvider);
    if (authStatus != AuthStatus.unauthenticated) {
      _loadCarts();
    }
    return const CartState(vendorBaskets: {}, isLoading: false);
  }

  void clearLocal() {
    state = const CartState(vendorBaskets: {}, isLoading: false);
  }

  Future<void> loadCarts({bool force = false}) async {
    await _loadCarts(force: force);
  }

  List<CartItem> _parseCartItems(
    List<dynamic>? rawItems,
    String vendorId,
    Map<String, dynamic>? vendorJson, {
    String defaultUnit = 'package',
  }) {
    if (rawItems == null) return [];
    final vendorName = vendorJson?['storeName']?.toString();
    final vendorNameAr = vendorJson?['storeNameAr']?.toString();
    final vendorLogo = vendorJson?['logo']?.toString();
    final vendorCoverImage = vendorJson?['coverImage']?.toString();
    final commissionRate = vendorJson?['commissionRate'];
    final isContracted = vendorJson?['isContracted'];
    final vendorStatus = vendorJson?['status']?.toString() ?? 'OPEN';

    final List<CartItem> items = [];
    for (final i in rawItems) {
      if (i is! Map) continue;
      final itemJson = Map<String, dynamic>.from(i);
      final productRaw = itemJson['product'];
      final productJson = productRaw is Map
          ? Map<String, dynamic>.from(productRaw)
          : <String, dynamic>{};
      final unitPrice = (itemJson['unitPrice'] as num?)?.toDouble();
      final totalPrice = (itemJson['totalPrice'] as num?)?.toDouble();

      final itemProduct = Map<String, dynamic>.from(productJson);
      if (itemProduct['id'] == null && itemJson['productId'] != null) {
        itemProduct['id'] = itemJson['productId'];
      }
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

      final variantRaw = itemJson['variant'];
      final optionsRaw = itemJson['options'];

      items.add(CartItem(
        backendId: itemJson['id']?.toString(),
        product: CartProductRef.fromJson(itemProduct),
        quantity: (itemJson['quantity'] as num?)?.toInt() ?? 1,
        selectedUnit: (itemJson['selectedUnit'] as String?) ?? defaultUnit,
        selectedVariant: variantRaw is Map
            ? CartVariantRef.fromJson(Map<String, dynamic>.from(variantRaw))
            : null,
        selectedOptions: optionsRaw is List
            ? optionsRaw
                .whereType<Map>()
                .map((o) =>
                    CartOptionRef.fromJson(Map<String, dynamic>.from(o)))
                .toList()
            : [],
        unitPrice: unitPrice,
        backendTotalPrice: totalPrice,
      ));
    }
    return items;
  }

  Future<void> _loadCarts({bool force = false}) async {
    final authStatus = ref.read(authControllerProvider);
    if (authStatus == AuthStatus.unauthenticated) {
      clearLocal();
      return;
    }
    try {
      final authRepo = ref.read(sharedAuthRepositoryProvider);
      final hasSession = await authRepo.isLoggedIn();
      if (!hasSession) {
        clearLocal();
        return;
      }

      state = state.copyWith(isLoading: true);
      final cartRepo = ref.read(customerCartRepositoryProvider);
      final carts = await cartRepo.getMyCarts();

      final Map<String, List<CartItem>> baskets = {};

      if (carts is List) {
        for (final c in carts) {
          if (c is! Map) continue;
          final cartJson = Map<String, dynamic>.from(c);
          final vendorId = cartJson['vendorId']?.toString() ?? '';
          if (vendorId.isEmpty) continue;
          final vendorJson = cartJson['vendor'] is Map
              ? Map<String, dynamic>.from(cartJson['vendor'] as Map)
              : null;
          final items = _parseCartItems(cartJson['items'] as List?, vendorId, vendorJson);
          if (items.isNotEmpty) {
            baskets[vendorId] = items;
          }
        }
      }

      state = CartState(vendorBaskets: baskets, isLoading: false);
    } catch (e, st) {
      debugPrint('Error loading carts: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addItem(
    Map<String, dynamic> product, {
    String unit = 'package',
    Map<String, dynamic>? variant,
    List<Map<String, dynamic>> options = const [],
  }) async {
    final vendorId = product['vendorId']?.toString() ?? '';
    if (vendorId.isEmpty) {
      debugPrint('Cannot add item: missing vendorId');
      return;
    }

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
        final vendorJson = updatedCart['vendor'] is Map
            ? Map<String, dynamic>.from(updatedCart['vendor'] as Map)
            : null;
        final items = _parseCartItems(updatedCart['items'] as List?, vendorId, vendorJson, defaultUnit: unit);

        final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
        if (items.isEmpty) {
          currentBaskets.remove(vendorId);
        } else {
          currentBaskets[vendorId] = items;
        }
        state = state.copyWith(vendorBaskets: currentBaskets);
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
    if (vendorId == null || vendorId.isEmpty) {
      for (final entry in state.vendorBaskets.entries) {
        if (entry.value.any((item) => item.backendId == cartItem.backendId || item.product.id == cartItem.product.id)) {
          vendorId = entry.key;
          break;
        }
      }
    }
    if (vendorId == null || vendorId.isEmpty || cartItem.backendId == null) return;

    try {
      final cartRepo = ref.read(customerCartRepositoryProvider);

      final response = await cartRepo.updateItem(
        vendorId,
        cartItem.backendId!,
        quantity: newQuantity,
      );

      if (response != null && response is Map) {
        final updatedCart = Map<String, dynamic>.from(response);
        final vendorJson = updatedCart['vendor'] is Map
            ? Map<String, dynamic>.from(updatedCart['vendor'] as Map)
            : null;
        final items = _parseCartItems(updatedCart['items'] as List?, vendorId, vendorJson, defaultUnit: cartItem.selectedUnit);

        final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
        if (items.isEmpty) {
          currentBaskets.remove(vendorId);
        } else {
          currentBaskets[vendorId] = items;
        }
        state = state.copyWith(vendorBaskets: currentBaskets);
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> _removeItemExact(CartItem cartItem) async {
    String? vendorId = cartItem.product.vendorId;
    if (vendorId == null || vendorId.isEmpty) {
      for (final entry in state.vendorBaskets.entries) {
        if (entry.value.any((item) => item.backendId == cartItem.backendId || item.product.id == cartItem.product.id)) {
          vendorId = entry.key;
          break;
        }
      }
    }
    if (vendorId == null || vendorId.isEmpty || cartItem.backendId == null) return;

    try {
      final cartRepo = ref.read(customerCartRepositoryProvider);
      await cartRepo.removeItem(vendorId, cartItem.backendId!);

      final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
      final existingItems = currentBaskets[vendorId];
      if (existingItems == null) return;
      final vendorItems = List<CartItem>.from(existingItems);

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

      state = state.copyWith(vendorBaskets: currentBaskets);
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
      state = state.copyWith(vendorBaskets: currentBaskets);
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
    state = const CartState(vendorBaskets: {}, isLoading: false);
  }
}
