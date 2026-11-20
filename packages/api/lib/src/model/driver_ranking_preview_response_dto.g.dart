// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_preview_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverRankingPreviewResponseDto
    extends DriverRankingPreviewResponseDto {
  @override
  final RankingWeekWindowDto week;
  @override
  final bool alreadyExecuted;
  @override
  final num totalDrivers;
  @override
  final num promotedCount;
  @override
  final num demotedCount;
  @override
  final num unchangedCount;
  @override
  final num inactiveCount;
  @override
  final BuiltList<DriverRankingPreviewItemDto> drivers;
  @override
  final DriverRankingPaginationMetaDto meta;

  factory _$DriverRankingPreviewResponseDto([
    void Function(DriverRankingPreviewResponseDtoBuilder)? updates,
  ]) => (DriverRankingPreviewResponseDtoBuilder()..update(updates))._build();

  _$DriverRankingPreviewResponseDto._({
    required this.week,
    required this.alreadyExecuted,
    required this.totalDrivers,
    required this.promotedCount,
    required this.demotedCount,
    required this.unchangedCount,
    required this.inactiveCount,
    required this.drivers,
    required this.meta,
  }) : super._();
  @override
  DriverRankingPreviewResponseDto rebuild(
    void Function(DriverRankingPreviewResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverRankingPreviewResponseDtoBuilder toBuilder() =>
      DriverRankingPreviewResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverRankingPreviewResponseDto &&
        week == other.week &&
        alreadyExecuted == other.alreadyExecuted &&
        totalDrivers == other.totalDrivers &&
        promotedCount == other.promotedCount &&
        demotedCount == other.demotedCount &&
        unchangedCount == other.unchangedCount &&
        inactiveCount == other.inactiveCount &&
        drivers == other.drivers &&
        meta == other.meta;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, week.hashCode);
    _$hash = $jc(_$hash, alreadyExecuted.hashCode);
    _$hash = $jc(_$hash, totalDrivers.hashCode);
    _$hash = $jc(_$hash, promotedCount.hashCode);
    _$hash = $jc(_$hash, demotedCount.hashCode);
    _$hash = $jc(_$hash, unchangedCount.hashCode);
    _$hash = $jc(_$hash, inactiveCount.hashCode);
    _$hash = $jc(_$hash, drivers.hashCode);
    _$hash = $jc(_$hash, meta.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverRankingPreviewResponseDto')
          ..add('week', week)
          ..add('alreadyExecuted', alreadyExecuted)
          ..add('totalDrivers', totalDrivers)
          ..add('promotedCount', promotedCount)
          ..add('demotedCount', demotedCount)
          ..add('unchangedCount', unchangedCount)
          ..add('inactiveCount', inactiveCount)
          ..add('drivers', drivers)
          ..add('meta', meta))
        .toString();
  }
}

class DriverRankingPreviewResponseDtoBuilder
    implements
        Builder<
          DriverRankingPreviewResponseDto,
          DriverRankingPreviewResponseDtoBuilder
        > {
  _$DriverRankingPreviewResponseDto? _$v;

  RankingWeekWindowDtoBuilder? _week;
  RankingWeekWindowDtoBuilder get week =>
      _$this._week ??= RankingWeekWindowDtoBuilder();
  set week(RankingWeekWindowDtoBuilder? week) => _$this._week = week;

  bool? _alreadyExecuted;
  bool? get alreadyExecuted => _$this._alreadyExecuted;
  set alreadyExecuted(bool? alreadyExecuted) =>
      _$this._alreadyExecuted = alreadyExecuted;

  num? _totalDrivers;
  num? get totalDrivers => _$this._totalDrivers;
  set totalDrivers(num? totalDrivers) => _$this._totalDrivers = totalDrivers;

  num? _promotedCount;
  num? get promotedCount => _$this._promotedCount;
  set promotedCount(num? promotedCount) =>
      _$this._promotedCount = promotedCount;

  num? _demotedCount;
  num? get demotedCount => _$this._demotedCount;
  set demotedCount(num? demotedCount) => _$this._demotedCount = demotedCount;

  num? _unchangedCount;
  num? get unchangedCount => _$this._unchangedCount;
  set unchangedCount(num? unchangedCount) =>
      _$this._unchangedCount = unchangedCount;

  num? _inactiveCount;
  num? get inactiveCount => _$this._inactiveCount;
  set inactiveCount(num? inactiveCount) =>
      _$this._inactiveCount = inactiveCount;

  ListBuilder<DriverRankingPreviewItemDto>? _drivers;
  ListBuilder<DriverRankingPreviewItemDto> get drivers =>
      _$this._drivers ??= ListBuilder<DriverRankingPreviewItemDto>();
  set drivers(ListBuilder<DriverRankingPreviewItemDto>? drivers) =>
      _$this._drivers = drivers;

  DriverRankingPaginationMetaDtoBuilder? _meta;
  DriverRankingPaginationMetaDtoBuilder get meta =>
      _$this._meta ??= DriverRankingPaginationMetaDtoBuilder();
  set meta(DriverRankingPaginationMetaDtoBuilder? meta) => _$this._meta = meta;

  DriverRankingPreviewResponseDtoBuilder() {
    DriverRankingPreviewResponseDto._defaults(this);
  }

  DriverRankingPreviewResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _week = $v.week.toBuilder();
      _alreadyExecuted = $v.alreadyExecuted;
      _totalDrivers = $v.totalDrivers;
      _promotedCount = $v.promotedCount;
      _demotedCount = $v.demotedCount;
      _unchangedCount = $v.unchangedCount;
      _inactiveCount = $v.inactiveCount;
      _drivers = $v.drivers.toBuilder();
      _meta = $v.meta.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverRankingPreviewResponseDto other) {
    _$v = other as _$DriverRankingPreviewResponseDto;
  }

  @override
  void update(void Function(DriverRankingPreviewResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverRankingPreviewResponseDto build() => _build();

  _$DriverRankingPreviewResponseDto _build() {
    _$DriverRankingPreviewResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverRankingPreviewResponseDto._(
            week: week.build(),
            alreadyExecuted: BuiltValueNullFieldError.checkNotNull(
              alreadyExecuted,
              r'DriverRankingPreviewResponseDto',
              'alreadyExecuted',
            ),
            totalDrivers: BuiltValueNullFieldError.checkNotNull(
              totalDrivers,
              r'DriverRankingPreviewResponseDto',
              'totalDrivers',
            ),
            promotedCount: BuiltValueNullFieldError.checkNotNull(
              promotedCount,
              r'DriverRankingPreviewResponseDto',
              'promotedCount',
            ),
            demotedCount: BuiltValueNullFieldError.checkNotNull(
              demotedCount,
              r'DriverRankingPreviewResponseDto',
              'demotedCount',
            ),
            unchangedCount: BuiltValueNullFieldError.checkNotNull(
              unchangedCount,
              r'DriverRankingPreviewResponseDto',
              'unchangedCount',
            ),
            inactiveCount: BuiltValueNullFieldError.checkNotNull(
              inactiveCount,
              r'DriverRankingPreviewResponseDto',
              'inactiveCount',
            ),
            drivers: drivers.build(),
            meta: meta.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'week';
        week.build();

        _$failedField = 'drivers';
        drivers.build();
        _$failedField = 'meta';
        meta.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverRankingPreviewResponseDto',
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
