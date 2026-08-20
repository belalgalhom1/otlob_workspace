// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Address extends Address {
  @override
  final String id;
  @override
  final String label;
  @override
  final String address;
  @override
  final String? details;
  @override
  final bool isDefault;
  @override
  final String customerId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final JsonObject? customer;

  factory _$Address([void Function(AddressBuilder)? updates]) =>
      (AddressBuilder()..update(updates))._build();

  _$Address._({
    required this.id,
    required this.label,
    required this.address,
    this.details,
    required this.isDefault,
    required this.customerId,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
  }) : super._();
  @override
  Address rebuild(void Function(AddressBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AddressBuilder toBuilder() => AddressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Address &&
        id == other.id &&
        label == other.label &&
        address == other.address &&
        details == other.details &&
        isDefault == other.isDefault &&
        customerId == other.customerId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        customer == other.customer;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, details.hashCode);
    _$hash = $jc(_$hash, isDefault.hashCode);
    _$hash = $jc(_$hash, customerId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Address')
          ..add('id', id)
          ..add('label', label)
          ..add('address', address)
          ..add('details', details)
          ..add('isDefault', isDefault)
          ..add('customerId', customerId)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('customer', customer))
        .toString();
  }
}

class AddressBuilder implements Builder<Address, AddressBuilder> {
  _$Address? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  String? _details;
  String? get details => _$this._details;
  set details(String? details) => _$this._details = details;

  bool? _isDefault;
  bool? get isDefault => _$this._isDefault;
  set isDefault(bool? isDefault) => _$this._isDefault = isDefault;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  JsonObject? _customer;
  JsonObject? get customer => _$this._customer;
  set customer(JsonObject? customer) => _$this._customer = customer;

  AddressBuilder() {
    Address._defaults(this);
  }

  AddressBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _label = $v.label;
      _address = $v.address;
      _details = $v.details;
      _isDefault = $v.isDefault;
      _customerId = $v.customerId;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _customer = $v.customer;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Address other) {
    _$v = other as _$Address;
  }

  @override
  void update(void Function(AddressBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Address build() => _build();

  _$Address _build() {
    final _$result =
        _$v ??
        _$Address._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Address', 'id'),
          label: BuiltValueNullFieldError.checkNotNull(
            label,
            r'Address',
            'label',
          ),
          address: BuiltValueNullFieldError.checkNotNull(
            address,
            r'Address',
            'address',
          ),
          details: details,
          isDefault: BuiltValueNullFieldError.checkNotNull(
            isDefault,
            r'Address',
            'isDefault',
          ),
          customerId: BuiltValueNullFieldError.checkNotNull(
            customerId,
            r'Address',
            'customerId',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Address',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Address',
            'updatedAt',
          ),
          customer: customer,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
