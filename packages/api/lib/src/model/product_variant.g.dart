// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_variant.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductVariant extends ProductVariant {
  @override
  final String id;
  @override
  final String productId;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String? sku;
  @override
  final num basePrice;
  @override
  final num? comparePrice;
  @override
  final num? stock;
  @override
  final bool isActive;
  @override
  final num version;
  @override
  final BuiltList<CartItem> cartItems;
  @override
  final BuiltList<OrderItem> orderItems;
  @override
  final BuiltList<ProductOptionGroup> optionGroups;
  @override
  final JsonObject? product;

  factory _$ProductVariant([void Function(ProductVariantBuilder)? updates]) =>
      (ProductVariantBuilder()..update(updates))._build();

  _$ProductVariant._({
    required this.id,
    required this.productId,
    required this.name,
    this.nameAr,
    this.sku,
    required this.basePrice,
    this.comparePrice,
    this.stock,
    required this.isActive,
    required this.version,
    required this.cartItems,
    required this.orderItems,
    required this.optionGroups,
    this.product,
  }) : super._();
  @override
  ProductVariant rebuild(void Function(ProductVariantBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductVariantBuilder toBuilder() => ProductVariantBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductVariant &&
        id == other.id &&
        productId == other.productId &&
        name == other.name &&
        nameAr == other.nameAr &&
        sku == other.sku &&
        basePrice == other.basePrice &&
        comparePrice == other.comparePrice &&
        stock == other.stock &&
        isActive == other.isActive &&
        version == other.version &&
        cartItems == other.cartItems &&
        orderItems == other.orderItems &&
        optionGroups == other.optionGroups &&
        product == other.product;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, sku.hashCode);
    _$hash = $jc(_$hash, basePrice.hashCode);
    _$hash = $jc(_$hash, comparePrice.hashCode);
    _$hash = $jc(_$hash, stock.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, cartItems.hashCode);
    _$hash = $jc(_$hash, orderItems.hashCode);
    _$hash = $jc(_$hash, optionGroups.hashCode);
    _$hash = $jc(_$hash, product.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductVariant')
          ..add('id', id)
          ..add('productId', productId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('sku', sku)
          ..add('basePrice', basePrice)
          ..add('comparePrice', comparePrice)
          ..add('stock', stock)
          ..add('isActive', isActive)
          ..add('version', version)
          ..add('cartItems', cartItems)
          ..add('orderItems', orderItems)
          ..add('optionGroups', optionGroups)
          ..add('product', product))
        .toString();
  }
}

class ProductVariantBuilder
    implements Builder<ProductVariant, ProductVariantBuilder> {
  _$ProductVariant? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  String? _sku;
  String? get sku => _$this._sku;
  set sku(String? sku) => _$this._sku = sku;

  num? _basePrice;
  num? get basePrice => _$this._basePrice;
  set basePrice(num? basePrice) => _$this._basePrice = basePrice;

  num? _comparePrice;
  num? get comparePrice => _$this._comparePrice;
  set comparePrice(num? comparePrice) => _$this._comparePrice = comparePrice;

  num? _stock;
  num? get stock => _$this._stock;
  set stock(num? stock) => _$this._stock = stock;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  num? _version;
  num? get version => _$this._version;
  set version(num? version) => _$this._version = version;

  ListBuilder<CartItem>? _cartItems;
  ListBuilder<CartItem> get cartItems =>
      _$this._cartItems ??= ListBuilder<CartItem>();
  set cartItems(ListBuilder<CartItem>? cartItems) =>
      _$this._cartItems = cartItems;

  ListBuilder<OrderItem>? _orderItems;
  ListBuilder<OrderItem> get orderItems =>
      _$this._orderItems ??= ListBuilder<OrderItem>();
  set orderItems(ListBuilder<OrderItem>? orderItems) =>
      _$this._orderItems = orderItems;

  ListBuilder<ProductOptionGroup>? _optionGroups;
  ListBuilder<ProductOptionGroup> get optionGroups =>
      _$this._optionGroups ??= ListBuilder<ProductOptionGroup>();
  set optionGroups(ListBuilder<ProductOptionGroup>? optionGroups) =>
      _$this._optionGroups = optionGroups;

  JsonObject? _product;
  JsonObject? get product => _$this._product;
  set product(JsonObject? product) => _$this._product = product;

  ProductVariantBuilder() {
    ProductVariant._defaults(this);
  }

  ProductVariantBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _productId = $v.productId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _sku = $v.sku;
      _basePrice = $v.basePrice;
      _comparePrice = $v.comparePrice;
      _stock = $v.stock;
      _isActive = $v.isActive;
      _version = $v.version;
      _cartItems = $v.cartItems.toBuilder();
      _orderItems = $v.orderItems.toBuilder();
      _optionGroups = $v.optionGroups.toBuilder();
      _product = $v.product;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductVariant other) {
    _$v = other as _$ProductVariant;
  }

  @override
  void update(void Function(ProductVariantBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductVariant build() => _build();

  _$ProductVariant _build() {
    _$ProductVariant _$result;
    try {
      _$result =
          _$v ??
          _$ProductVariant._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'ProductVariant',
              'id',
            ),
            productId: BuiltValueNullFieldError.checkNotNull(
              productId,
              r'ProductVariant',
              'productId',
            ),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ProductVariant',
              'name',
            ),
            nameAr: nameAr,
            sku: sku,
            basePrice: BuiltValueNullFieldError.checkNotNull(
              basePrice,
              r'ProductVariant',
              'basePrice',
            ),
            comparePrice: comparePrice,
            stock: stock,
            isActive: BuiltValueNullFieldError.checkNotNull(
              isActive,
              r'ProductVariant',
              'isActive',
            ),
            version: BuiltValueNullFieldError.checkNotNull(
              version,
              r'ProductVariant',
              'version',
            ),
            cartItems: cartItems.build(),
            orderItems: orderItems.build(),
            optionGroups: optionGroups.build(),
            product: product,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'cartItems';
        cartItems.build();
        _$failedField = 'orderItems';
        orderItems.build();
        _$failedField = 'optionGroups';
        optionGroups.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductVariant',
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
