// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_drivers_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NearbyDriversResponseDto extends NearbyDriversResponseDto {
  @override
  final num radiusKm;
  @override
  final num count;
  @override
  final BuiltList<NearbyDriverPreviewDto> drivers;
  @override
  final String fetchedAt;

  factory _$NearbyDriversResponseDto([
    void Function(NearbyDriversResponseDtoBuilder)? updates,
  ]) => (NearbyDriversResponseDtoBuilder()..update(updates))._build();

  _$NearbyDriversResponseDto._({
    required this.radiusKm,
    required this.count,
    required this.drivers,
    required this.fetchedAt,
  }) : super._();
  @override
  NearbyDriversResponseDto rebuild(
    void Function(NearbyDriversResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NearbyDriversResponseDtoBuilder toBuilder() =>
      NearbyDriversResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NearbyDriversResponseDto &&
        radiusKm == other.radiusKm &&
        count == other.count &&
        drivers == other.drivers &&
        fetchedAt == other.fetchedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, radiusKm.hashCode);
    _$hash = $jc(_$hash, count.hashCode);
    _$hash = $jc(_$hash, drivers.hashCode);
    _$hash = $jc(_$hash, fetchedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NearbyDriversResponseDto')
          ..add('radiusKm', radiusKm)
          ..add('count', count)
          ..add('drivers', drivers)
          ..add('fetchedAt', fetchedAt))
        .toString();
  }
}

class NearbyDriversResponseDtoBuilder
    implements
        Builder<NearbyDriversResponseDto, NearbyDriversResponseDtoBuilder> {
  _$NearbyDriversResponseDto? _$v;

  num? _radiusKm;
  num? get radiusKm => _$this._radiusKm;
  set radiusKm(num? radiusKm) => _$this._radiusKm = radiusKm;

  num? _count;
  num? get count => _$this._count;
  set count(num? count) => _$this._count = count;

  ListBuilder<NearbyDriverPreviewDto>? _drivers;
  ListBuilder<NearbyDriverPreviewDto> get drivers =>
      _$this._drivers ??= ListBuilder<NearbyDriverPreviewDto>();
  set drivers(ListBuilder<NearbyDriverPreviewDto>? drivers) =>
      _$this._drivers = drivers;

  String? _fetchedAt;
  String? get fetchedAt => _$this._fetchedAt;
  set fetchedAt(String? fetchedAt) => _$this._fetchedAt = fetchedAt;

  NearbyDriversResponseDtoBuilder() {
    NearbyDriversResponseDto._defaults(this);
  }

  NearbyDriversResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _radiusKm = $v.radiusKm;
      _count = $v.count;
      _drivers = $v.drivers.toBuilder();
      _fetchedAt = $v.fetchedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NearbyDriversResponseDto other) {
    _$v = other as _$NearbyDriversResponseDto;
  }

  @override
  void update(void Function(NearbyDriversResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NearbyDriversResponseDto build() => _build();

  _$NearbyDriversResponseDto _build() {
    _$NearbyDriversResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$NearbyDriversResponseDto._(
            radiusKm: BuiltValueNullFieldError.checkNotNull(
              radiusKm,
              r'NearbyDriversResponseDto',
              'radiusKm',
            ),
            count: BuiltValueNullFieldError.checkNotNull(
              count,
              r'NearbyDriversResponseDto',
              'count',
            ),
            drivers: drivers.build(),
            fetchedAt: BuiltValueNullFieldError.checkNotNull(
              fetchedAt,
              r'NearbyDriversResponseDto',
              'fetchedAt',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'drivers';
        drivers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'NearbyDriversResponseDto',
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
