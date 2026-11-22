// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_driver_preview_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NearbyDriverPreviewDto extends NearbyDriverPreviewDto {
  @override
  final String? markerKey;
  @override
  final num latitude;
  @override
  final num longitude;
  @override
  final VehicleType vehicleType;
  @override
  final num distanceKm;

  factory _$NearbyDriverPreviewDto([
    void Function(NearbyDriverPreviewDtoBuilder)? updates,
  ]) => (NearbyDriverPreviewDtoBuilder()..update(updates))._build();

  _$NearbyDriverPreviewDto._({
    this.markerKey,
    required this.latitude,
    required this.longitude,
    required this.vehicleType,
    required this.distanceKm,
  }) : super._();
  @override
  NearbyDriverPreviewDto rebuild(
    void Function(NearbyDriverPreviewDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NearbyDriverPreviewDtoBuilder toBuilder() =>
      NearbyDriverPreviewDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NearbyDriverPreviewDto &&
        markerKey == other.markerKey &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        vehicleType == other.vehicleType &&
        distanceKm == other.distanceKm;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, markerKey.hashCode);
    _$hash = $jc(_$hash, latitude.hashCode);
    _$hash = $jc(_$hash, longitude.hashCode);
    _$hash = $jc(_$hash, vehicleType.hashCode);
    _$hash = $jc(_$hash, distanceKm.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NearbyDriverPreviewDto')
          ..add('markerKey', markerKey)
          ..add('latitude', latitude)
          ..add('longitude', longitude)
          ..add('vehicleType', vehicleType)
          ..add('distanceKm', distanceKm))
        .toString();
  }
}

class NearbyDriverPreviewDtoBuilder
    implements Builder<NearbyDriverPreviewDto, NearbyDriverPreviewDtoBuilder> {
  _$NearbyDriverPreviewDto? _$v;

  String? _markerKey;
  String? get markerKey => _$this._markerKey;
  set markerKey(String? markerKey) => _$this._markerKey = markerKey;

  num? _latitude;
  num? get latitude => _$this._latitude;
  set latitude(num? latitude) => _$this._latitude = latitude;

  num? _longitude;
  num? get longitude => _$this._longitude;
  set longitude(num? longitude) => _$this._longitude = longitude;

  VehicleType? _vehicleType;
  VehicleType? get vehicleType => _$this._vehicleType;
  set vehicleType(VehicleType? vehicleType) =>
      _$this._vehicleType = vehicleType;

  num? _distanceKm;
  num? get distanceKm => _$this._distanceKm;
  set distanceKm(num? distanceKm) => _$this._distanceKm = distanceKm;

  NearbyDriverPreviewDtoBuilder() {
    NearbyDriverPreviewDto._defaults(this);
  }

  NearbyDriverPreviewDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _markerKey = $v.markerKey;
      _latitude = $v.latitude;
      _longitude = $v.longitude;
      _vehicleType = $v.vehicleType;
      _distanceKm = $v.distanceKm;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NearbyDriverPreviewDto other) {
    _$v = other as _$NearbyDriverPreviewDto;
  }

  @override
  void update(void Function(NearbyDriverPreviewDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NearbyDriverPreviewDto build() => _build();

  _$NearbyDriverPreviewDto _build() {
    final _$result =
        _$v ??
        _$NearbyDriverPreviewDto._(
          markerKey: markerKey,
          latitude: BuiltValueNullFieldError.checkNotNull(
            latitude,
            r'NearbyDriverPreviewDto',
            'latitude',
          ),
          longitude: BuiltValueNullFieldError.checkNotNull(
            longitude,
            r'NearbyDriverPreviewDto',
            'longitude',
          ),
          vehicleType: BuiltValueNullFieldError.checkNotNull(
            vehicleType,
            r'NearbyDriverPreviewDto',
            'vehicleType',
          ),
          distanceKm: BuiltValueNullFieldError.checkNotNull(
            distanceKm,
            r'NearbyDriverPreviewDto',
            'distanceKm',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
