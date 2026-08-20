// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_zone_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateZoneDto extends UpdateZoneDto {
  @override
  final String? name;
  @override
  final String? nameAr;
  @override
  final bool? isActive;
  @override
  final num? baseDeliveryFeeOverride;
  @override
  final num? minOrderAmountOverride;
  @override
  final BuiltList<String>? boundary;

  factory _$UpdateZoneDto([void Function(UpdateZoneDtoBuilder)? updates]) =>
      (UpdateZoneDtoBuilder()..update(updates))._build();

  _$UpdateZoneDto._({
    this.name,
    this.nameAr,
    this.isActive,
    this.baseDeliveryFeeOverride,
    this.minOrderAmountOverride,
    this.boundary,
  }) : super._();
  @override
  UpdateZoneDto rebuild(void Function(UpdateZoneDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateZoneDtoBuilder toBuilder() => UpdateZoneDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateZoneDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        isActive == other.isActive &&
        baseDeliveryFeeOverride == other.baseDeliveryFeeOverride &&
        minOrderAmountOverride == other.minOrderAmountOverride &&
        boundary == other.boundary;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, baseDeliveryFeeOverride.hashCode);
    _$hash = $jc(_$hash, minOrderAmountOverride.hashCode);
    _$hash = $jc(_$hash, boundary.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateZoneDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('isActive', isActive)
          ..add('baseDeliveryFeeOverride', baseDeliveryFeeOverride)
          ..add('minOrderAmountOverride', minOrderAmountOverride)
          ..add('boundary', boundary))
        .toString();
  }
}

class UpdateZoneDtoBuilder
    implements Builder<UpdateZoneDto, UpdateZoneDtoBuilder> {
  _$UpdateZoneDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  num? _baseDeliveryFeeOverride;
  num? get baseDeliveryFeeOverride => _$this._baseDeliveryFeeOverride;
  set baseDeliveryFeeOverride(num? baseDeliveryFeeOverride) =>
      _$this._baseDeliveryFeeOverride = baseDeliveryFeeOverride;

  num? _minOrderAmountOverride;
  num? get minOrderAmountOverride => _$this._minOrderAmountOverride;
  set minOrderAmountOverride(num? minOrderAmountOverride) =>
      _$this._minOrderAmountOverride = minOrderAmountOverride;

  ListBuilder<String>? _boundary;
  ListBuilder<String> get boundary =>
      _$this._boundary ??= ListBuilder<String>();
  set boundary(ListBuilder<String>? boundary) => _$this._boundary = boundary;

  UpdateZoneDtoBuilder() {
    UpdateZoneDto._defaults(this);
  }

  UpdateZoneDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _isActive = $v.isActive;
      _baseDeliveryFeeOverride = $v.baseDeliveryFeeOverride;
      _minOrderAmountOverride = $v.minOrderAmountOverride;
      _boundary = $v.boundary?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateZoneDto other) {
    _$v = other as _$UpdateZoneDto;
  }

  @override
  void update(void Function(UpdateZoneDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateZoneDto build() => _build();

  _$UpdateZoneDto _build() {
    _$UpdateZoneDto _$result;
    try {
      _$result =
          _$v ??
          _$UpdateZoneDto._(
            name: name,
            nameAr: nameAr,
            isActive: isActive,
            baseDeliveryFeeOverride: baseDeliveryFeeOverride,
            minOrderAmountOverride: minOrderAmountOverride,
            boundary: _boundary?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'boundary';
        _boundary?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateZoneDto',
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
