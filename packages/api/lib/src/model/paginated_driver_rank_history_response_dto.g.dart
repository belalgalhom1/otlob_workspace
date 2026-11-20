// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_driver_rank_history_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaginatedDriverRankHistoryResponseDto
    extends PaginatedDriverRankHistoryResponseDto {
  @override
  final BuiltList<DriverRankHistoryEntryDto> data;
  @override
  final DriverRankingPaginationMetaDto meta;

  factory _$PaginatedDriverRankHistoryResponseDto([
    void Function(PaginatedDriverRankHistoryResponseDtoBuilder)? updates,
  ]) => (PaginatedDriverRankHistoryResponseDtoBuilder()..update(updates))
      ._build();

  _$PaginatedDriverRankHistoryResponseDto._({
    required this.data,
    required this.meta,
  }) : super._();
  @override
  PaginatedDriverRankHistoryResponseDto rebuild(
    void Function(PaginatedDriverRankHistoryResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PaginatedDriverRankHistoryResponseDtoBuilder toBuilder() =>
      PaginatedDriverRankHistoryResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaginatedDriverRankHistoryResponseDto &&
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
            r'PaginatedDriverRankHistoryResponseDto',
          )
          ..add('data', data)
          ..add('meta', meta))
        .toString();
  }
}

class PaginatedDriverRankHistoryResponseDtoBuilder
    implements
        Builder<
          PaginatedDriverRankHistoryResponseDto,
          PaginatedDriverRankHistoryResponseDtoBuilder
        > {
  _$PaginatedDriverRankHistoryResponseDto? _$v;

  ListBuilder<DriverRankHistoryEntryDto>? _data;
  ListBuilder<DriverRankHistoryEntryDto> get data =>
      _$this._data ??= ListBuilder<DriverRankHistoryEntryDto>();
  set data(ListBuilder<DriverRankHistoryEntryDto>? data) => _$this._data = data;

  DriverRankingPaginationMetaDtoBuilder? _meta;
  DriverRankingPaginationMetaDtoBuilder get meta =>
      _$this._meta ??= DriverRankingPaginationMetaDtoBuilder();
  set meta(DriverRankingPaginationMetaDtoBuilder? meta) => _$this._meta = meta;

  PaginatedDriverRankHistoryResponseDtoBuilder() {
    PaginatedDriverRankHistoryResponseDto._defaults(this);
  }

  PaginatedDriverRankHistoryResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _data = $v.data.toBuilder();
      _meta = $v.meta.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaginatedDriverRankHistoryResponseDto other) {
    _$v = other as _$PaginatedDriverRankHistoryResponseDto;
  }

  @override
  void update(
    void Function(PaginatedDriverRankHistoryResponseDtoBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  PaginatedDriverRankHistoryResponseDto build() => _build();

  _$PaginatedDriverRankHistoryResponseDto _build() {
    _$PaginatedDriverRankHistoryResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$PaginatedDriverRankHistoryResponseDto._(
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
          r'PaginatedDriverRankHistoryResponseDto',
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
