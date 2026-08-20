// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Cart extends Cart {
  @override
  final String id;
  @override
  final String customerId;
  @override
  final String vendorId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final BuiltList<CartItem> items;
  @override
  final JsonObject? customer;
  @override
  final JsonObject? vendor;

  factory _$Cart([void Function(CartBuilder)? updates]) =>
      (CartBuilder()..update(updates))._build();

  _$Cart._({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.customer,
    this.vendor,
  }) : super._();
  @override
  Cart rebuild(void Function(CartBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CartBuilder toBuilder() => CartBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Cart &&
        id == other.id &&
        customerId == other.customerId &&
        vendorId == other.vendorId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        items == other.items &&
        customer == other.customer &&
        vendor == other.vendor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, customerId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Cart')
          ..add('id', id)
          ..add('customerId', customerId)
          ..add('vendorId', vendorId)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('items', items)
          ..add('customer', customer)
          ..add('vendor', vendor))
        .toString();
  }
}

class CartBuilder implements Builder<Cart, CartBuilder> {
  _$Cart? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ListBuilder<CartItem>? _items;
  ListBuilder<CartItem> get items => _$this._items ??= ListBuilder<CartItem>();
  set items(ListBuilder<CartItem>? items) => _$this._items = items;

  JsonObject? _customer;
  JsonObject? get customer => _$this._customer;
  set customer(JsonObject? customer) => _$this._customer = customer;

  JsonObject? _vendor;
  JsonObject? get vendor => _$this._vendor;
  set vendor(JsonObject? vendor) => _$this._vendor = vendor;

  CartBuilder() {
    Cart._defaults(this);
  }

  CartBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _customerId = $v.customerId;
      _vendorId = $v.vendorId;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _items = $v.items.toBuilder();
      _customer = $v.customer;
      _vendor = $v.vendor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Cart other) {
    _$v = other as _$Cart;
  }

  @override
  void update(void Function(CartBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Cart build() => _build();

  _$Cart _build() {
    _$Cart _$result;
    try {
      _$result =
          _$v ??
          _$Cart._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Cart', 'id'),
            customerId: BuiltValueNullFieldError.checkNotNull(
              customerId,
              r'Cart',
              'customerId',
            ),
            vendorId: BuiltValueNullFieldError.checkNotNull(
              vendorId,
              r'Cart',
              'vendorId',
            ),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'Cart',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'Cart',
              'updatedAt',
            ),
            items: items.build(),
            customer: customer,
            vendor: vendor,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Cart', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
