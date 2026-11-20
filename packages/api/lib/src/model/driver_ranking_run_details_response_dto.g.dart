// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_run_details_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverRankingRunDetailsResponseDto
    extends DriverRankingRunDetailsResponseDto {
  @override
  final DriverRankingEvaluationRunDto run;
  @override
  final BuiltList<DriverRankHistoryEntryDto> entries;
  @override
  final DriverRankingPaginationMetaDto meta;

  factory _$DriverRankingRunDetailsResponseDto([
    void Function(DriverRankingRunDetailsResponseDtoBuilder)? updates,
  ]) => (DriverRankingRunDetailsResponseDtoBuilder()..update(updates))._build();

  _$DriverRankingRunDetailsResponseDto._({
    required this.run,
    required this.entries,
    required this.meta,
  }) : super._();
  @override
  DriverRankingRunDetailsResponseDto rebuild(
    void Function(DriverRankingRunDetailsResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverRankingRunDetailsResponseDtoBuilder toBuilder() =>
      DriverRankingRunDetailsResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverRankingRunDetailsResponseDto &&
        run == other.run &&
        entries == other.entries &&
        meta == other.meta;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, run.hashCode);
    _$hash = $jc(_$hash, entries.hashCode);
    _$hash = $jc(_$hash, meta.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverRankingRunDetailsResponseDto')
          ..add('run', run)
          ..add('entries', entries)
          ..add('meta', meta))
        .toString();
  }
}

class DriverRankingRunDetailsResponseDtoBuilder
    implements
        Builder<
          DriverRankingRunDetailsResponseDto,
          DriverRankingRunDetailsResponseDtoBuilder
        > {
  _$DriverRankingRunDetailsResponseDto? _$v;

  DriverRankingEvaluationRunDtoBuilder? _run;
  DriverRankingEvaluationRunDtoBuilder get run =>
      _$this._run ??= DriverRankingEvaluationRunDtoBuilder();
  set run(DriverRankingEvaluationRunDtoBuilder? run) => _$this._run = run;

  ListBuilder<DriverRankHistoryEntryDto>? _entries;
  ListBuilder<DriverRankHistoryEntryDto> get entries =>
      _$this._entries ??= ListBuilder<DriverRankHistoryEntryDto>();
  set entries(ListBuilder<DriverRankHistoryEntryDto>? entries) =>
      _$this._entries = entries;

  DriverRankingPaginationMetaDtoBuilder? _meta;
  DriverRankingPaginationMetaDtoBuilder get meta =>
      _$this._meta ??= DriverRankingPaginationMetaDtoBuilder();
  set meta(DriverRankingPaginationMetaDtoBuilder? meta) => _$this._meta = meta;

  DriverRankingRunDetailsResponseDtoBuilder() {
    DriverRankingRunDetailsResponseDto._defaults(this);
  }

  DriverRankingRunDetailsResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _run = $v.run.toBuilder();
      _entries = $v.entries.toBuilder();
      _meta = $v.meta.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverRankingRunDetailsResponseDto other) {
    _$v = other as _$DriverRankingRunDetailsResponseDto;
  }

  @override
  void update(
    void Function(DriverRankingRunDetailsResponseDtoBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  DriverRankingRunDetailsResponseDto build() => _build();

  _$DriverRankingRunDetailsResponseDto _build() {
    _$DriverRankingRunDetailsResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverRankingRunDetailsResponseDto._(
            run: run.build(),
            entries: entries.build(),
            meta: meta.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'run';
        run.build();
        _$failedField = 'entries';
        entries.build();
        _$failedField = 'meta';
        meta.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverRankingRunDetailsResponseDto',
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
