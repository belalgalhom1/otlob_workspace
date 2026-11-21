// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_coordinate_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RouteCoordinateDto extends RouteCoordinateDto {
  @override
  final num latitude;
  @override
  final num longitude;

  factory _$RouteCoordinateDto([
    void Function(RouteCoordinateDtoBuilder)? updates,
  ]) => (RouteCoordinateDtoBuilder()..update(updates))._build();

  _$RouteCoordinateDto._({required this.latitude, required this.longitude})
    : super._();
  @override
  RouteCoordinateDto rebuild(
    void Function(RouteCoordinateDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RouteCoordinateDtoBuilder toBuilder() =>
      RouteCoordinateDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RouteCoordinateDto &&
        latitude == other.latitude &&
        longitude == other.longitude;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RouteCoordinateDto')
          ..add('latitude', latitude)
          ..add('longitude', longitude))
        .toString();
  }
}

class RouteCoordinateDtoBuilder
    implements Builder<RouteCoordinateDto, RouteCoordinateDtoBuilder> {
  _$RouteCoordinateDto? _$v;

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  RouteCoordinateDtoBuilder() {
    RouteCoordinateDto._defaults(this);
  }

  RouteCoordinateDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RouteCoordinateDto other) {
    _$v = other as _$RouteCoordinateDto;
  }

  @override
  void update(void Function(RouteCoordinateDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RouteCoordinateDto build() => _build();

  _$RouteCoordinateDto _build() {
    final _$result =
        _$v ??
        _$RouteCoordinateDto._(
          latitude: BuiltValueNullFieldError.checkNotNull(
            latitude,
            r'RouteCoordinateDto',
            'latitude',
          ),
          longitude: BuiltValueNullFieldError.checkNotNull(
            longitude,
            r'RouteCoordinateDto',
            'longitude',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
