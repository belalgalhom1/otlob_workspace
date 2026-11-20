// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_week_window_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RankingWeekWindowDto extends RankingWeekWindowDto {
  @override
  final String periodKey;
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;

  factory _$RankingWeekWindowDto([
    void Function(RankingWeekWindowDtoBuilder)? updates,
  ]) => (RankingWeekWindowDtoBuilder()..update(updates))._build();

  _$RankingWeekWindowDto._({
    required this.periodKey,
    required this.periodStart,
    required this.periodEnd,
  }) : super._();
  @override
  RankingWeekWindowDto rebuild(
    void Function(RankingWeekWindowDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RankingWeekWindowDtoBuilder toBuilder() =>
      RankingWeekWindowDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RankingWeekWindowDto &&
        periodKey == other.periodKey &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, periodKey.hashCode);
    _$hash = $jc(_$hash, periodStart.hashCode);
    _$hash = $jc(_$hash, periodEnd.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RankingWeekWindowDto')
          ..add('periodKey', periodKey)
          ..add('periodStart', periodStart)
          ..add('periodEnd', periodEnd))
        .toString();
  }
}

class RankingWeekWindowDtoBuilder
    implements Builder<RankingWeekWindowDto, RankingWeekWindowDtoBuilder> {
  _$RankingWeekWindowDto? _$v;

  String? _periodKey;
  String? get periodKey => _$this._periodKey;
  set periodKey(String? periodKey) => _$this._periodKey = periodKey;

  DateTime? _periodStart;
  DateTime? get periodStart => _$this._periodStart;
  set periodStart(DateTime? periodStart) => _$this._periodStart = periodStart;

  DateTime? _periodEnd;
  DateTime? get periodEnd => _$this._periodEnd;
  set periodEnd(DateTime? periodEnd) => _$this._periodEnd = periodEnd;

  RankingWeekWindowDtoBuilder() {
    RankingWeekWindowDto._defaults(this);
  }

  RankingWeekWindowDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _periodKey = $v.periodKey;
      _periodStart = $v.periodStart;
      _periodEnd = $v.periodEnd;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RankingWeekWindowDto other) {
    _$v = other as _$RankingWeekWindowDto;
  }

  @override
  void update(void Function(RankingWeekWindowDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RankingWeekWindowDto build() => _build();

  _$RankingWeekWindowDto _build() {
    final _$result =
        _$v ??
        _$RankingWeekWindowDto._(
          periodKey: BuiltValueNullFieldError.checkNotNull(
            periodKey,
            r'RankingWeekWindowDto',
            'periodKey',
          ),
          periodStart: BuiltValueNullFieldError.checkNotNull(
            periodStart,
            r'RankingWeekWindowDto',
            'periodStart',
          ),
          periodEnd: BuiltValueNullFieldError.checkNotNull(
            periodEnd,
            r'RankingWeekWindowDto',
            'periodEnd',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
