// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_branch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VendorBranch extends VendorBranch {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String address;
  @override
  final String? phone;
  @override
  final bool isOpen;
  @override
  final String vendorId;
  @override
  final String zoneId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$VendorBranch([void Function(VendorBranchBuilder)? updates]) =>
      (VendorBranchBuilder()..update(updates))._build();

  _$VendorBranch._({
    required this.id,
    required this.name,
    this.nameAr,
    required this.address,
    this.phone,
    required this.isOpen,
    required this.vendorId,
    required this.zoneId,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  VendorBranch rebuild(void Function(VendorBranchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VendorBranchBuilder toBuilder() => VendorBranchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VendorBranch &&
        id == other.id &&
        name == other.name &&
        nameAr == other.nameAr &&
        address == other.address &&
        phone == other.phone &&
        isOpen == other.isOpen &&
        vendorId == other.vendorId &&
        zoneId == other.zoneId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, isOpen.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VendorBranch')
          ..add('id', id)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('address', address)
          ..add('phone', phone)
          ..add('isOpen', isOpen)
          ..add('vendorId', vendorId)
          ..add('zoneId', zoneId)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class VendorBranchBuilder
    implements Builder<VendorBranch, VendorBranchBuilder> {
  _$VendorBranch? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  bool? _isOpen;
  bool? get isOpen => _$this._isOpen;
  set isOpen(bool? isOpen) => _$this._isOpen = isOpen;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  VendorBranchBuilder() {
    VendorBranch._defaults(this);
  }

  VendorBranchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _address = $v.address;
      _phone = $v.phone;
      _isOpen = $v.isOpen;
      _vendorId = $v.vendorId;
      _zoneId = $v.zoneId;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VendorBranch other) {
    _$v = other as _$VendorBranch;
  }

  @override
  void update(void Function(VendorBranchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VendorBranch build() => _build();

  _$VendorBranch _build() {
    final _$result =
        _$v ??
        _$VendorBranch._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'VendorBranch', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'VendorBranch',
            'name',
          ),
          nameAr: nameAr,
          address: BuiltValueNullFieldError.checkNotNull(
            address,
            r'VendorBranch',
            'address',
          ),
          phone: phone,
          isOpen: BuiltValueNullFieldError.checkNotNull(
            isOpen,
            r'VendorBranch',
            'isOpen',
          ),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'VendorBranch',
            'vendorId',
          ),
          zoneId: BuiltValueNullFieldError.checkNotNull(
            zoneId,
            r'VendorBranch',
            'zoneId',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'VendorBranch',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'VendorBranch',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
