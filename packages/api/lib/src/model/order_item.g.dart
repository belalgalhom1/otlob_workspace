// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderItem extends OrderItem {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final String? productId;
  @override
  final String? variantId;
  @override
  final String productName;
  @override
  final String? variantName;
  @override
  final num unitPrice;
  @override
  final num quantity;
  @override
  final num totalPrice;
  @override
  final String? specialRequest;
  @override
  final BuiltList<OrderItemOption> selectedOptions;
  @override
  final JsonObject? order;
  @override
  final JsonObject? product;
  @override
  final JsonObject? variant;

  factory _$OrderItem([void Function(OrderItemBuilder)? updates]) =>
      (OrderItemBuilder()..update(updates))._build();

  _$OrderItem._({
    required this.id,
    required this.orderId,
    this.productId,
    this.variantId,
    required this.productName,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.specialRequest,
    required this.selectedOptions,
    this.order,
    this.product,
    this.variant,
  }) : super._();
  @override
  OrderItem rebuild(void Function(OrderItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrderItemBuilder toBuilder() => OrderItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderItem &&
        id == other.id &&
        orderId == other.orderId &&
        productId == other.productId &&
        variantId == other.variantId &&
        productName == other.productName &&
        variantName == other.variantName &&
        unitPrice == other.unitPrice &&
        quantity == other.quantity &&
        totalPrice == other.totalPrice &&
        specialRequest == other.specialRequest &&
        selectedOptions == other.selectedOptions &&
        order == other.order &&
        product == other.product &&
        variant == other.variant;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, variantId.hashCode);
    _$hash = $jc(_$hash, productName.hashCode);
    _$hash = $jc(_$hash, variantName.hashCode);
    _$hash = $jc(_$hash, unitPrice.hashCode);
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, totalPrice.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jc(_$hash, selectedOptions.hashCode);
    _$hash = $jc(_$hash, order.hashCode);
    _$hash = $jc(_$hash, product.hashCode);
    _$hash = $jc(_$hash, variant.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderItem')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('productId', productId)
          ..add('variantId', variantId)
          ..add('productName', productName)
          ..add('variantName', variantName)
          ..add('unitPrice', unitPrice)
          ..add('quantity', quantity)
          ..add('totalPrice', totalPrice)
          ..add('specialRequest', specialRequest)
          ..add('selectedOptions', selectedOptions)
          ..add('order', order)
          ..add('product', product)
          ..add('variant', variant))
        .toString();
  }
}

class OrderItemBuilder implements Builder<OrderItem, OrderItemBuilder> {
  _$OrderItem? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _variantId;
  String? get variantId => _$this._variantId;
  set variantId(String? variantId) => _$this._variantId = variantId;

  String? _productName;
  String? get productName => _$this._productName;
  set productName(String? productName) => _$this._productName = productName;

  String? _variantName;
  String? get variantName => _$this._variantName;
  set variantName(String? variantName) => _$this._variantName = variantName;

  num? _unitPrice;
  num? get unitPrice => _$this._unitPrice;
  set unitPrice(num? unitPrice) => _$this._unitPrice = unitPrice;

  num? _quantity;
  num? get quantity => _$this._quantity;
  set quantity(num? quantity) => _$this._quantity = quantity;

  num? _totalPrice;
  num? get totalPrice => _$this._totalPrice;
  set totalPrice(num? totalPrice) => _$this._totalPrice = totalPrice;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  ListBuilder<OrderItemOption>? _selectedOptions;
  ListBuilder<OrderItemOption> get selectedOptions =>
      _$this._selectedOptions ??= ListBuilder<OrderItemOption>();
  set selectedOptions(ListBuilder<OrderItemOption>? selectedOptions) =>
      _$this._selectedOptions = selectedOptions;

  JsonObject? _order;
  JsonObject? get order => _$this._order;
  set order(JsonObject? order) => _$this._order = order;

  JsonObject? _product;
  JsonObject? get product => _$this._product;
  set product(JsonObject? product) => _$this._product = product;

  JsonObject? _variant;
  JsonObject? get variant => _$this._variant;
  set variant(JsonObject? variant) => _$this._variant = variant;

  OrderItemBuilder() {
    OrderItem._defaults(this);
  }

  OrderItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _productId = $v.productId;
      _variantId = $v.variantId;
      _productName = $v.productName;
      _variantName = $v.variantName;
      _unitPrice = $v.unitPrice;
      _quantity = $v.quantity;
      _totalPrice = $v.totalPrice;
      _specialRequest = $v.specialRequest;
      _selectedOptions = $v.selectedOptions.toBuilder();
      _order = $v.order;
      _product = $v.product;
      _variant = $v.variant;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderItem other) {
    _$v = other as _$OrderItem;
  }

  @override
  void update(void Function(OrderItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderItem build() => _build();

  _$OrderItem _build() {
    _$OrderItem _$result;
    try {
      _$result =
          _$v ??
          _$OrderItem._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'OrderItem', 'id'),
            orderId: BuiltValueNullFieldError.checkNotNull(
              orderId,
              r'OrderItem',
              'orderId',
            ),
            productId: productId,
            variantId: variantId,
            productName: BuiltValueNullFieldError.checkNotNull(
              productName,
              r'OrderItem',
              'productName',
            ),
            variantName: variantName,
            unitPrice: BuiltValueNullFieldError.checkNotNull(
              unitPrice,
              r'OrderItem',
              'unitPrice',
            ),
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'OrderItem',
              'quantity',
            ),
            totalPrice: BuiltValueNullFieldError.checkNotNull(
              totalPrice,
              r'OrderItem',
              'totalPrice',
            ),
            specialRequest: specialRequest,
            selectedOptions: selectedOptions.build(),
            order: order,
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
          r'OrderItem',
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
