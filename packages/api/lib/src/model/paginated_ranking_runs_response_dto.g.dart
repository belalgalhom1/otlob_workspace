// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_ranking_runs_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaginatedRankingRunsResponseDto
    extends PaginatedRankingRunsResponseDto {
  @override
  final BuiltList<DriverRankingEvaluationRunDto> data;
  @override
  final DriverRankingPaginationMetaDto meta;

  factory _$PaginatedRankingRunsResponseDto([
    void Function(PaginatedRankingRunsResponseDtoBuilder)? updates,
  ]) => (PaginatedRankingRunsResponseDtoBuilder()..update(updates))._build();

  _$PaginatedRankingRunsResponseDto._({required this.data, required this.meta})
    : super._();
  @override
  PaginatedRankingRunsResponseDto rebuild(
    void Function(PaginatedRankingRunsResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PaginatedRankingRunsResponseDtoBuilder toBuilder() =>
      PaginatedRankingRunsResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaginatedRankingRunsResponseDto &&
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
    return (newBuiltValueToStringHelper(r'PaginatedRankingRunsResponseDto')
          ..add('data', data)
          ..add('meta', meta))
        .toString();
  }
}

class PaginatedRankingRunsResponseDtoBuilder
    implements
        Builder<
          PaginatedRankingRunsResponseDto,
          PaginatedRankingRunsResponseDtoBuilder
        > {
  _$PaginatedRankingRunsResponseDto? _$v;

  ListBuilder<DriverRankingEvaluationRunDto>? _data;
  ListBuilder<DriverRankingEvaluationRunDto> get data =>
      _$this._data ??= ListBuilder<DriverRankingEvaluationRunDto>();
  set data(ListBuilder<DriverRankingEvaluationRunDto>? data) =>
      _$this._data = data;

  DriverRankingPaginationMetaDtoBuilder? _meta;
  DriverRankingPaginationMetaDtoBuilder get meta =>
      _$this._meta ??= DriverRankingPaginationMetaDtoBuilder();
  set meta(DriverRankingPaginationMetaDtoBuilder? meta) => _$this._meta = meta;

  PaginatedRankingRunsResponseDtoBuilder() {
    PaginatedRankingRunsResponseDto._defaults(this);
  }

  PaginatedRankingRunsResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _data = $v.data.toBuilder();
      _meta = $v.meta.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaginatedRankingRunsResponseDto other) {
    _$v = other as _$PaginatedRankingRunsResponseDto;
  }

  @override
  void update(void Function(PaginatedRankingRunsResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaginatedRankingRunsResponseDto build() => _build();

  _$PaginatedRankingRunsResponseDto _build() {
    _$PaginatedRankingRunsResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$PaginatedRankingRunsResponseDto._(
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
          r'PaginatedRankingRunsResponseDto',
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
