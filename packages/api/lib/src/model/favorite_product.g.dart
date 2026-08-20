// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_product.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FavoriteProduct extends FavoriteProduct {
  @override
  final String id;
  @override
  final String customerId;
  @override
  final String productId;
  @override
  final DateTime createdAt;
  @override
  final JsonObject? customer;
  @override
  final JsonObject? product;

  factory _$FavoriteProduct([void Function(FavoriteProductBuilder)? updates]) =>
      (FavoriteProductBuilder()..update(updates))._build();

  _$FavoriteProduct._({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.createdAt,
    this.customer,
    this.product,
  }) : super._();
  @override
  FavoriteProduct rebuild(void Function(FavoriteProductBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FavoriteProductBuilder toBuilder() => FavoriteProductBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FavoriteProduct &&
        id == other.id &&
        customerId == other.customerId &&
        productId == other.productId &&
        createdAt == other.createdAt &&
        customer == other.customer &&
        product == other.product;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, customerId.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jc(_$hash, product.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FavoriteProduct')
          ..add('id', id)
          ..add('customerId', customerId)
          ..add('productId', productId)
          ..add('createdAt', createdAt)
          ..add('customer', customer)
          ..add('product', product))
        .toString();
  }
}

class FavoriteProductBuilder
    implements Builder<FavoriteProduct, FavoriteProductBuilder> {
  _$FavoriteProduct? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  JsonObject? _customer;
  JsonObject? get customer => _$this._customer;
  set customer(JsonObject? customer) => _$this._customer = customer;

  JsonObject? _product;
  JsonObject? get product => _$this._product;
  set product(JsonObject? product) => _$this._product = product;

  FavoriteProductBuilder() {
    FavoriteProduct._defaults(this);
  }

  FavoriteProductBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _customerId = $v.customerId;
      _productId = $v.productId;
      _createdAt = $v.createdAt;
      _customer = $v.customer;
      _product = $v.product;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FavoriteProduct other) {
    _$v = other as _$FavoriteProduct;
  }

  @override
  void update(void Function(FavoriteProductBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FavoriteProduct build() => _build();

  _$FavoriteProduct _build() {
    final _$result =
        _$v ??
        _$FavoriteProduct._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'FavoriteProduct',
            'id',
          ),
          customerId: BuiltValueNullFieldError.checkNotNull(
            customerId,
            r'FavoriteProduct',
            'customerId',
          ),
          productId: BuiltValueNullFieldError.checkNotNull(
            productId,
            r'FavoriteProduct',
            'productId',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'FavoriteProduct',
            'createdAt',
          ),
          customer: customer,
          product: product,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
