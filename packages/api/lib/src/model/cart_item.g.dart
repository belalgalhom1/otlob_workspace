// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CartItem extends CartItem {
  @override
  final String id;
  @override
  final String cartId;
  @override
  final String? productId;
  @override
  final String? variantId;
  @override
  final String? customName;
  @override
  final num? customPrice;
  @override
  final String? customImageUrl;
  @override
  final num quantity;
  @override
  final String? specialRequest;
  @override
  final String? optionHash;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final BuiltList<CartItemOption> selectedOptions;
  @override
  final JsonObject? cart;
  @override
  final JsonObject? product;
  @override
  final JsonObject? variant;

  factory _$CartItem([void Function(CartItemBuilder)? updates]) =>
      (CartItemBuilder()..update(updates))._build();

  _$CartItem._({
    required this.id,
    required this.cartId,
    this.productId,
    this.variantId,
    this.customName,
    this.customPrice,
    this.customImageUrl,
    required this.quantity,
    this.specialRequest,
    this.optionHash,
    required this.createdAt,
    required this.updatedAt,
    required this.selectedOptions,
    this.cart,
    this.product,
    this.variant,
  }) : super._();
  @override
  CartItem rebuild(void Function(CartItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CartItemBuilder toBuilder() => CartItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CartItem &&
        id == other.id &&
        cartId == other.cartId &&
        productId == other.productId &&
        variantId == other.variantId &&
        customName == other.customName &&
        customPrice == other.customPrice &&
        customImageUrl == other.customImageUrl &&
        quantity == other.quantity &&
        specialRequest == other.specialRequest &&
        optionHash == other.optionHash &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        selectedOptions == other.selectedOptions &&
        cart == other.cart &&
        product == other.product &&
        variant == other.variant;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, cartId.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, variantId.hashCode);
    _$hash = $jc(_$hash, customName.hashCode);
    _$hash = $jc(_$hash, customPrice.hashCode);
    _$hash = $jc(_$hash, customImageUrl.hashCode);
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jc(_$hash, optionHash.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, selectedOptions.hashCode);
    _$hash = $jc(_$hash, cart.hashCode);
    _$hash = $jc(_$hash, product.hashCode);
    _$hash = $jc(_$hash, variant.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CartItem')
          ..add('id', id)
          ..add('cartId', cartId)
          ..add('productId', productId)
          ..add('variantId', variantId)
          ..add('customName', customName)
          ..add('customPrice', customPrice)
          ..add('customImageUrl', customImageUrl)
          ..add('quantity', quantity)
          ..add('specialRequest', specialRequest)
          ..add('optionHash', optionHash)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('selectedOptions', selectedOptions)
          ..add('cart', cart)
          ..add('product', product)
          ..add('variant', variant))
        .toString();
  }
}

class CartItemBuilder implements Builder<CartItem, CartItemBuilder> {
  _$CartItem? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _cartId;
  String? get cartId => _$this._cartId;
  set cartId(String? cartId) => _$this._cartId = cartId;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _variantId;
  String? get variantId => _$this._variantId;
  set variantId(String? variantId) => _$this._variantId = variantId;

  String? _customName;
  String? get customName => _$this._customName;
  set customName(String? customName) => _$this._customName = customName;

  num? _customPrice;
  num? get customPrice => _$this._customPrice;
  set customPrice(num? customPrice) => _$this._customPrice = customPrice;

  String? _customImageUrl;
  String? get customImageUrl => _$this._customImageUrl;
  set customImageUrl(String? customImageUrl) =>
      _$this._customImageUrl = customImageUrl;

  num? _quantity;
  num? get quantity => _$this._quantity;
  set quantity(num? quantity) => _$this._quantity = quantity;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  String? _optionHash;
  String? get optionHash => _$this._optionHash;
  set optionHash(String? optionHash) => _$this._optionHash = optionHash;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ListBuilder<CartItemOption>? _selectedOptions;
  ListBuilder<CartItemOption> get selectedOptions =>
      _$this._selectedOptions ??= ListBuilder<CartItemOption>();
  set selectedOptions(ListBuilder<CartItemOption>? selectedOptions) =>
      _$this._selectedOptions = selectedOptions;

  JsonObject? _cart;
  JsonObject? get cart => _$this._cart;
  set cart(JsonObject? cart) => _$this._cart = cart;

  JsonObject? _product;
  JsonObject? get product => _$this._product;
  set product(JsonObject? product) => _$this._product = product;

  JsonObject? _variant;
  JsonObject? get variant => _$this._variant;
  set variant(JsonObject? variant) => _$this._variant = variant;

  CartItemBuilder() {
    CartItem._defaults(this);
  }

  CartItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _cartId = $v.cartId;
      _productId = $v.productId;
      _variantId = $v.variantId;
      _customName = $v.customName;
      _customPrice = $v.customPrice;
      _customImageUrl = $v.customImageUrl;
      _quantity = $v.quantity;
      _specialRequest = $v.specialRequest;
      _optionHash = $v.optionHash;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _selectedOptions = $v.selectedOptions.toBuilder();
      _cart = $v.cart;
      _product = $v.product;
      _variant = $v.variant;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CartItem other) {
    _$v = other as _$CartItem;
  }

  @override
  void update(void Function(CartItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CartItem build() => _build();

  _$CartItem _build() {
    _$CartItem _$result;
    try {
      _$result =
          _$v ??
          _$CartItem._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'CartItem', 'id'),
            cartId: BuiltValueNullFieldError.checkNotNull(
              cartId,
              r'CartItem',
              'cartId',
            ),
            productId: productId,
            variantId: variantId,
            customName: customName,
            customPrice: customPrice,
            customImageUrl: customImageUrl,
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'CartItem',
              'quantity',
            ),
            specialRequest: specialRequest,
            optionHash: optionHash,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'CartItem',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'CartItem',
              'updatedAt',
            ),
            selectedOptions: selectedOptions.build(),
            cart: cart,
            product: product,
            variant: variant,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'selectedOptions';
        selectedOptions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CartItem',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
