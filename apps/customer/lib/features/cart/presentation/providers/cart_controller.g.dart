// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Cart)
final cartProvider = CartProvider._();

final class CartProvider extends $NotifierProvider<Cart, CartState> {
  CartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartHash();

  @$internal
  @override
  Cart create() => Cart();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CartState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CartState>(value),
    );
  }
}

String _$cartHash() => r'63c58150f0b5cd63f7fa5a05895537740d9a2b95';

abstract class _$Cart extends $Notifier<CartState> {
  CartState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CartState, CartState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CartState, CartState>,
              CartState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
