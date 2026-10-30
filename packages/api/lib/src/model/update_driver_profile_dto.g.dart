// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_driver_profile_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateDriverProfileDto extends UpdateDriverProfileDto {
  @override
  final String? name;
  @override
  final String? nationalId;
  @override
  final String? licenseNumber;

  factory _$UpdateDriverProfileDto([
    void Function(UpdateDriverProfileDtoBuilder)? updates,
  ]) => (UpdateDriverProfileDtoBuilder()..update(updates))._build();

  _$UpdateDriverProfileDto._({this.name, this.nationalId, this.licenseNumber})
    : super._();
  @override
  UpdateDriverProfileDto rebuild(
    void Function(UpdateDriverProfileDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateDriverProfileDtoBuilder toBuilder() =>
      UpdateDriverProfileDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateDriverProfileDto &&
        name == other.name &&
        nationalId == other.nationalId &&
        licenseNumber == other.licenseNumber;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nationalId.hashCode);
    _$hash = $jc(_$hash, licenseNumber.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateDriverProfileDto')
          ..add('name', name)
          ..add('nationalId', nationalId)
          ..add('licenseNumber', licenseNumber))
        .toString();
  }
}

class UpdateDriverProfileDtoBuilder
    implements Builder<UpdateDriverProfileDto, UpdateDriverProfileDtoBuilder> {
  _$UpdateDriverProfileDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nationalId;
  String? get nationalId => _$this._nationalId;
  set nationalId(String? nationalId) => _$this._nationalId = nationalId;

  String? _licenseNumber;
  String? get licenseNumber => _$this._licenseNumber;
  set licenseNumber(String? licenseNumber) =>
      _$this._licenseNumber = licenseNumber;

  UpdateDriverProfileDtoBuilder() {
    UpdateDriverProfileDto._defaults(this);
  }

  UpdateDriverProfileDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nationalId = $v.nationalId;
      _licenseNumber = $v.licenseNumber;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateDriverProfileDto other) {
    _$v = other as _$UpdateDriverProfileDto;
  }

  @override
  void update(void Function(UpdateDriverProfileDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateDriverProfileDto build() => _build();

  _$UpdateDriverProfileDto _build() {
    final _$result =
        _$v ??
        _$UpdateDriverProfileDto._(
          name: name,
          nationalId: nationalId,
          licenseNumber: licenseNumber,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
