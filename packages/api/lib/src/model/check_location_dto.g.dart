// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_location_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CheckLocationDto extends CheckLocationDto {
  @override
  final num longitude;
  @override
  final num latitude;

  factory _$CheckLocationDto([
    void Function(CheckLocationDtoBuilder)? updates,
  ]) => (CheckLocationDtoBuilder()..update(updates))._build();

  _$CheckLocationDto._({required this.longitude, required this.latitude})
    : super._();
  @override
  CheckLocationDto rebuild(void Function(CheckLocationDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CheckLocationDtoBuilder toBuilder() =>
      CheckLocationDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CheckLocationDto &&
        longitude == other.longitude &&
        latitude == other.latitude;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CheckLocationDto')
          ..add('longitude', longitude)
          ..add('latitude', latitude))
        .toString();
  }
}

class CheckLocationDtoBuilder
    implements Builder<CheckLocationDto, CheckLocationDtoBuilder> {
  _$CheckLocationDto? _$v;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  CheckLocationDtoBuilder() {
    CheckLocationDto._defaults(this);
  }

  CheckLocationDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _longitude = $v.longitude;
      _latitude = $v.latitude;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CheckLocationDto other) {
    _$v = other as _$CheckLocationDto;
  }

  @override
  void update(void Function(CheckLocationDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CheckLocationDto build() => _build();

  _$CheckLocationDto _build() {
    final _$result =
        _$v ??
        _$CheckLocationDto._(
          longitude: BuiltValueNullFieldError.checkNotNull(
            longitude,
            r'CheckLocationDto',
            'longitude',
          ),
          latitude: BuiltValueNullFieldError.checkNotNull(
            latitude,
            r'CheckLocationDto',
            'latitude',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
