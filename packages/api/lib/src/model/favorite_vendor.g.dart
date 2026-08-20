// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_vendor.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FavoriteVendor extends FavoriteVendor {
  @override
  final String id;
  @override
  final String customerId;
  @override
  final String vendorId;
  @override
  final DateTime createdAt;
  @override
  final JsonObject? customer;
  @override
  final JsonObject? vendor;

  factory _$FavoriteVendor([void Function(FavoriteVendorBuilder)? updates]) =>
      (FavoriteVendorBuilder()..update(updates))._build();

  _$FavoriteVendor._({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.createdAt,
    this.customer,
    this.vendor,
  }) : super._();
  @override
  FavoriteVendor rebuild(void Function(FavoriteVendorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FavoriteVendorBuilder toBuilder() => FavoriteVendorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FavoriteVendor &&
        id == other.id &&
        customerId == other.customerId &&
        vendorId == other.vendorId &&
        createdAt == other.createdAt &&
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
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FavoriteVendor')
          ..add('id', id)
          ..add('customerId', customerId)
          ..add('vendorId', vendorId)
          ..add('createdAt', createdAt)
          ..add('customer', customer)
          ..add('vendor', vendor))
        .toString();
  }
}

class FavoriteVendorBuilder
    implements Builder<FavoriteVendor, FavoriteVendorBuilder> {
  _$FavoriteVendor? _$v;

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

  JsonObject? _customer;
  JsonObject? get customer => _$this._customer;
  set customer(JsonObject? customer) => _$this._customer = customer;

  JsonObject? _vendor;
  JsonObject? get vendor => _$this._vendor;
  set vendor(JsonObject? vendor) => _$this._vendor = vendor;

  FavoriteVendorBuilder() {
    FavoriteVendor._defaults(this);
  }

  FavoriteVendorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _customerId = $v.customerId;
      _vendorId = $v.vendorId;
      _createdAt = $v.createdAt;
      _customer = $v.customer;
      _vendor = $v.vendor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FavoriteVendor other) {
    _$v = other as _$FavoriteVendor;
  }

  @override
  void update(void Function(FavoriteVendorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FavoriteVendor build() => _build();

  _$FavoriteVendor _build() {
    final _$result =
        _$v ??
        _$FavoriteVendor._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'FavoriteVendor',
            'id',
          ),
          customerId: BuiltValueNullFieldError.checkNotNull(
            customerId,
            r'FavoriteVendor',
            'customerId',
          ),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'FavoriteVendor',
            'vendorId',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'FavoriteVendor',
            'createdAt',
          ),
          customer: customer,
          vendor: vendor,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
