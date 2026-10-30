// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_branch_availability.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductBranchAvailability extends ProductBranchAvailability {
  @override
  final String productId;
  @override
  final String branchId;
  @override
  final DateTime createdAt;

  factory _$ProductBranchAvailability([
    void Function(ProductBranchAvailabilityBuilder)? updates,
  ]) => (ProductBranchAvailabilityBuilder()..update(updates))._build();

  _$ProductBranchAvailability._({
    required this.productId,
    required this.branchId,
    required this.createdAt,
  }) : super._();
  @override
  ProductBranchAvailability rebuild(
    void Function(ProductBranchAvailabilityBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductBranchAvailabilityBuilder toBuilder() =>
      ProductBranchAvailabilityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductBranchAvailability &&
        productId == other.productId &&
        branchId == other.branchId &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, branchId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductBranchAvailability')
          ..add('productId', productId)
          ..add('branchId', branchId)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class ProductBranchAvailabilityBuilder
    implements
        Builder<ProductBranchAvailability, ProductBranchAvailabilityBuilder> {
  _$ProductBranchAvailability? _$v;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _branchId;
  String? get branchId => _$this._branchId;
  set branchId(String? branchId) => _$this._branchId = branchId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  ProductBranchAvailabilityBuilder() {
    ProductBranchAvailability._defaults(this);
  }

  ProductBranchAvailabilityBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _productId = $v.productId;
      _branchId = $v.branchId;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductBranchAvailability other) {
    _$v = other as _$ProductBranchAvailability;
  }

  @override
  void update(void Function(ProductBranchAvailabilityBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductBranchAvailability build() => _build();

  _$ProductBranchAvailability _build() {
    final _$result =
        _$v ??
        _$ProductBranchAvailability._(
          productId: BuiltValueNullFieldError.checkNotNull(
            productId,
            r'ProductBranchAvailability',
            'productId',
          ),
          branchId: BuiltValueNullFieldError.checkNotNull(
            branchId,
            r'ProductBranchAvailability',
            'branchId',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'ProductBranchAvailability',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
