// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_vendor_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateVendorDto extends UpdateVendorDto {
  @override
  final String? storeName;
  @override
  final String? storeNameAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final String? verticalId;
  @override
  final String? taxId;
  @override
  final num? commissionRate;
  @override
  final String? phone;
  @override
  final bool? isContracted;

  factory _$UpdateVendorDto([void Function(UpdateVendorDtoBuilder)? updates]) =>
      (UpdateVendorDtoBuilder()..update(updates))._build();

  _$UpdateVendorDto._({
    this.storeName,
    this.storeNameAr,
    this.description,
    this.descriptionAr,
    this.verticalId,
    this.taxId,
    this.commissionRate,
    this.phone,
    this.isContracted,
  }) : super._();
  @override
  UpdateVendorDto rebuild(void Function(UpdateVendorDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateVendorDtoBuilder toBuilder() => UpdateVendorDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateVendorDto &&
        storeName == other.storeName &&
        storeNameAr == other.storeNameAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        verticalId == other.verticalId &&
        taxId == other.taxId &&
        commissionRate == other.commissionRate &&
        phone == other.phone &&
        isContracted == other.isContracted;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, storeName.hashCode);
    _$hash = $jc(_$hash, storeNameAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, verticalId.hashCode);
    _$hash = $jc(_$hash, taxId.hashCode);
    _$hash = $jc(_$hash, commissionRate.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, isContracted.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateVendorDto')
          ..add('storeName', storeName)
          ..add('storeNameAr', storeNameAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('verticalId', verticalId)
          ..add('taxId', taxId)
          ..add('commissionRate', commissionRate)
          ..add('phone', phone)
          ..add('isContracted', isContracted))
        .toString();
  }
}

class UpdateVendorDtoBuilder
    implements Builder<UpdateVendorDto, UpdateVendorDtoBuilder> {
  _$UpdateVendorDto? _$v;

  String? _storeName;
  String? get storeName => _$this._storeName;
  set storeName(String? storeName) => _$this._storeName = storeName;

  String? _storeNameAr;
  String? get storeNameAr => _$this._storeNameAr;
  set storeNameAr(String? storeNameAr) => _$this._storeNameAr = storeNameAr;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _descriptionAr;
  String? get descriptionAr => _$this._descriptionAr;
  set descriptionAr(String? descriptionAr) =>
      _$this._descriptionAr = descriptionAr;

  String? _verticalId;
  String? get verticalId => _$this._verticalId;
  set verticalId(String? verticalId) => _$this._verticalId = verticalId;

  String? _taxId;
  String? get taxId => _$this._taxId;
  set taxId(String? taxId) => _$this._taxId = taxId;

  num? _commissionRate;
  num? get commissionRate => _$this._commissionRate;
  set commissionRate(num? commissionRate) =>
      _$this._commissionRate = commissionRate;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  bool? _isContracted;
  bool? get isContracted => _$this._isContracted;
  set isContracted(bool? isContracted) => _$this._isContracted = isContracted;

  UpdateVendorDtoBuilder() {
    UpdateVendorDto._defaults(this);
  }

  UpdateVendorDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _storeName = $v.storeName;
      _storeNameAr = $v.storeNameAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _verticalId = $v.verticalId;
      _taxId = $v.taxId;
      _commissionRate = $v.commissionRate;
      _phone = $v.phone;
      _isContracted = $v.isContracted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateVendorDto other) {
    _$v = other as _$UpdateVendorDto;
  }

  @override
  void update(void Function(UpdateVendorDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateVendorDto build() => _build();

  _$UpdateVendorDto _build() {
    final _$result =
        _$v ??
        _$UpdateVendorDto._(
          storeName: storeName,
          storeNameAr: storeNameAr,
          description: description,
          descriptionAr: descriptionAr,
          verticalId: verticalId,
          taxId: taxId,
          commissionRate: commissionRate,
          phone: phone,
          isContracted: isContracted,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
