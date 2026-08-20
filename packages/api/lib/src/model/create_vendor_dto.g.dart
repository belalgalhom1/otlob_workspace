// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_vendor_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateVendorDto extends CreateVendorDto {
  @override
  final String storeName;
  @override
  final String? storeNameAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final String verticalId;
  @override
  final String? taxId;
  @override
  final num? commissionRate;
  @override
  final String? phone;
  @override
  final bool? isContracted;
  @override
  final JsonObject? workingHours;
  @override
  final bool? is24Hours;

  factory _$CreateVendorDto([void Function(CreateVendorDtoBuilder)? updates]) =>
      (CreateVendorDtoBuilder()..update(updates))._build();

  _$CreateVendorDto._({
    required this.storeName,
    this.storeNameAr,
    this.description,
    this.descriptionAr,
    required this.verticalId,
    this.taxId,
    this.commissionRate,
    this.phone,
    this.isContracted,
    this.workingHours,
    this.is24Hours,
  }) : super._();
  @override
  CreateVendorDto rebuild(void Function(CreateVendorDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateVendorDtoBuilder toBuilder() => CreateVendorDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateVendorDto &&
        storeName == other.storeName &&
        storeNameAr == other.storeNameAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        verticalId == other.verticalId &&
        taxId == other.taxId &&
        commissionRate == other.commissionRate &&
        phone == other.phone &&
        isContracted == other.isContracted &&
        workingHours == other.workingHours &&
        is24Hours == other.is24Hours;
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
    _$hash = $jc(_$hash, workingHours.hashCode);
    _$hash = $jc(_$hash, is24Hours.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateVendorDto')
          ..add('storeName', storeName)
          ..add('storeNameAr', storeNameAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('verticalId', verticalId)
          ..add('taxId', taxId)
          ..add('commissionRate', commissionRate)
          ..add('phone', phone)
          ..add('isContracted', isContracted)
          ..add('workingHours', workingHours)
          ..add('is24Hours', is24Hours))
        .toString();
  }
}

class CreateVendorDtoBuilder
    implements Builder<CreateVendorDto, CreateVendorDtoBuilder> {
  _$CreateVendorDto? _$v;

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

  JsonObject? _workingHours;
  JsonObject? get workingHours => _$this._workingHours;
  set workingHours(JsonObject? workingHours) =>
      _$this._workingHours = workingHours;

  bool? _is24Hours;
  bool? get is24Hours => _$this._is24Hours;
  set is24Hours(bool? is24Hours) => _$this._is24Hours = is24Hours;

  CreateVendorDtoBuilder() {
    CreateVendorDto._defaults(this);
  }

  CreateVendorDtoBuilder get _$this {
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
      _workingHours = $v.workingHours;
      _is24Hours = $v.is24Hours;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateVendorDto other) {
    _$v = other as _$CreateVendorDto;
  }

  @override
  void update(void Function(CreateVendorDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateVendorDto build() => _build();

  _$CreateVendorDto _build() {
    final _$result =
        _$v ??
        _$CreateVendorDto._(
          storeName: BuiltValueNullFieldError.checkNotNull(
            storeName,
            r'CreateVendorDto',
            'storeName',
          ),
          storeNameAr: storeNameAr,
          description: description,
          descriptionAr: descriptionAr,
          verticalId: BuiltValueNullFieldError.checkNotNull(
            verticalId,
            r'CreateVendorDto',
            'verticalId',
          ),
          taxId: taxId,
          commissionRate: commissionRate,
          phone: phone,
          isContracted: isContracted,
          workingHours: workingHours,
          is24Hours: is24Hours,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
