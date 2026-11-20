// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_delivery_incidents_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaginatedDeliveryIncidentsResponseDto
    extends PaginatedDeliveryIncidentsResponseDto {
  @override
  final BuiltList<DriverDeliveryIncidentDto> data;
  @override
  final DriverRankingPaginationMetaDto meta;

  factory _$PaginatedDeliveryIncidentsResponseDto([
    void Function(PaginatedDeliveryIncidentsResponseDtoBuilder)? updates,
  ]) => (PaginatedDeliveryIncidentsResponseDtoBuilder()..update(updates))
      ._build();

  _$PaginatedDeliveryIncidentsResponseDto._({
    required this.data,
    required this.meta,
  }) : super._();
  @override
  PaginatedDeliveryIncidentsResponseDto rebuild(
    void Function(PaginatedDeliveryIncidentsResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PaginatedDeliveryIncidentsResponseDtoBuilder toBuilder() =>
      PaginatedDeliveryIncidentsResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaginatedDeliveryIncidentsResponseDto &&
        data == other.data &&
        meta == other.meta;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, meta.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'PaginatedDeliveryIncidentsResponseDto',
          )
          ..add('data', data)
          ..add('meta', meta))
        .toString();
  }
}

class PaginatedDeliveryIncidentsResponseDtoBuilder
    implements
        Builder<
          PaginatedDeliveryIncidentsResponseDto,
          PaginatedDeliveryIncidentsResponseDtoBuilder
        > {
  _$PaginatedDeliveryIncidentsResponseDto? _$v;

  ListBuilder<DriverDeliveryIncidentDto>? _data;
  ListBuilder<DriverDeliveryIncidentDto> get data =>
      _$this._data ??= ListBuilder<DriverDeliveryIncidentDto>();
  set data(ListBuilder<DriverDeliveryIncidentDto>? data) => _$this._data = data;

  DriverRankingPaginationMetaDtoBuilder? _meta;
  DriverRankingPaginationMetaDtoBuilder get meta =>
      _$this._meta ??= DriverRankingPaginationMetaDtoBuilder();
  set meta(DriverRankingPaginationMetaDtoBuilder? meta) => _$this._meta = meta;

  PaginatedDeliveryIncidentsResponseDtoBuilder() {
    PaginatedDeliveryIncidentsResponseDto._defaults(this);
  }

  PaginatedDeliveryIncidentsResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _data = $v.data.toBuilder();
      _meta = $v.meta.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaginatedDeliveryIncidentsResponseDto other) {
    _$v = other as _$PaginatedDeliveryIncidentsResponseDto;
  }

  @override
  void update(
    void Function(PaginatedDeliveryIncidentsResponseDtoBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PaginatedDeliveryIncidentsResponseDto build() => _build();

  _$PaginatedDeliveryIncidentsResponseDto _build() {
    _$PaginatedDeliveryIncidentsResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$PaginatedDeliveryIncidentsResponseDto._(
            data: data.build(),
            meta: meta.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'data';
        data.build();
        _$failedField = 'meta';
        meta.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PaginatedDeliveryIncidentsResponseDto',
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
