// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_vendor_branch_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateVendorBranchDto extends CreateVendorBranchDto {
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String address;
  @override
  final String? phone;
  @override
  final BuiltList<String> location;
  @override
  final String? zoneId;
  @override
  final bool? isOpen;

  factory _$CreateVendorBranchDto([
    void Function(CreateVendorBranchDtoBuilder)? updates,
  ]) => (CreateVendorBranchDtoBuilder()..update(updates))._build();

  _$CreateVendorBranchDto._({
    required this.name,
    this.nameAr,
    required this.address,
    this.phone,
    required this.location,
    this.zoneId,
    this.isOpen,
  }) : super._();
  @override
  CreateVendorBranchDto rebuild(
    void Function(CreateVendorBranchDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateVendorBranchDtoBuilder toBuilder() =>
      CreateVendorBranchDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateVendorBranchDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        address == other.address &&
        phone == other.phone &&
        location == other.location &&
        zoneId == other.zoneId &&
        isOpen == other.isOpen;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jc(_$hash, isOpen.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateVendorBranchDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('address', address)
          ..add('phone', phone)
          ..add('location', location)
          ..add('zoneId', zoneId)
          ..add('isOpen', isOpen))
        .toString();
  }
}

class CreateVendorBranchDtoBuilder
    implements Builder<CreateVendorBranchDto, CreateVendorBranchDtoBuilder> {
  _$CreateVendorBranchDto? _$v;

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

  ListBuilder<String>? _location;
  ListBuilder<String> get location =>
      _$this._location ??= ListBuilder<String>();
  set location(ListBuilder<String>? location) => _$this._location = location;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  bool? _isOpen;
  bool? get isOpen => _$this._isOpen;
  set isOpen(bool? isOpen) => _$this._isOpen = isOpen;

  CreateVendorBranchDtoBuilder() {
    CreateVendorBranchDto._defaults(this);
  }

  CreateVendorBranchDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _address = $v.address;
      _phone = $v.phone;
      _location = $v.location.toBuilder();
      _zoneId = $v.zoneId;
      _isOpen = $v.isOpen;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateVendorBranchDto other) {
    _$v = other as _$CreateVendorBranchDto;
  }

  @override
  void update(void Function(CreateVendorBranchDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateVendorBranchDto build() => _build();

  _$CreateVendorBranchDto _build() {
    _$CreateVendorBranchDto _$result;
    try {
      _$result =
          _$v ??
          _$CreateVendorBranchDto._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'CreateVendorBranchDto',
              'name',
            ),
            nameAr: nameAr,
            address: BuiltValueNullFieldError.checkNotNull(
              address,
              r'CreateVendorBranchDto',
              'address',
            ),
            phone: phone,
            location: location.build(),
            zoneId: zoneId,
            isOpen: isOpen,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'location';
        location.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateVendorBranchDto',
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
