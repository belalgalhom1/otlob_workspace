// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_schedule_status_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverRankingScheduleStatusDto extends DriverRankingScheduleStatusDto {
  @override
  final bool enabled;
  @override
  final String evalTime;
  @override
  final String frequency;
  @override
  final String evaluationDay;
  @override
  final String timezone;
  @override
  final DateTime nextEvaluationAt;
  @override
  final RankingWeekWindowDto currentWeek;
  @override
  final RankingWeekWindowDto lastCompletedWeek;
  @override
  final DriverRankingEvaluationRunDto? latestRun;
  @override
  final DriverRankingEvaluationRunDto? lastCompletedWeekRun;

  factory _$DriverRankingScheduleStatusDto([
    void Function(DriverRankingScheduleStatusDtoBuilder)? updates,
  ]) => (DriverRankingScheduleStatusDtoBuilder()..update(updates))._build();

  _$DriverRankingScheduleStatusDto._({
    required this.enabled,
    required this.evalTime,
    required this.frequency,
    required this.evaluationDay,
    required this.timezone,
    required this.nextEvaluationAt,
    required this.currentWeek,
    required this.lastCompletedWeek,
    this.latestRun,
    this.lastCompletedWeekRun,
  }) : super._();
  @override
  DriverRankingScheduleStatusDto rebuild(
    void Function(DriverRankingScheduleStatusDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverRankingScheduleStatusDtoBuilder toBuilder() =>
      DriverRankingScheduleStatusDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverRankingScheduleStatusDto &&
        enabled == other.enabled &&
        evalTime == other.evalTime &&
        frequency == other.frequency &&
        evaluationDay == other.evaluationDay &&
        timezone == other.timezone &&
        nextEvaluationAt == other.nextEvaluationAt &&
        currentWeek == other.currentWeek &&
        lastCompletedWeek == other.lastCompletedWeek &&
        latestRun == other.latestRun &&
        lastCompletedWeekRun == other.lastCompletedWeekRun;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jc(_$hash, evalTime.hashCode);
    _$hash = $jc(_$hash, frequency.hashCode);
    _$hash = $jc(_$hash, evaluationDay.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, nextEvaluationAt.hashCode);
    _$hash = $jc(_$hash, currentWeek.hashCode);
    _$hash = $jc(_$hash, lastCompletedWeek.hashCode);
    _$hash = $jc(_$hash, latestRun.hashCode);
    _$hash = $jc(_$hash, lastCompletedWeekRun.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverRankingScheduleStatusDto')
          ..add('enabled', enabled)
          ..add('evalTime', evalTime)
          ..add('frequency', frequency)
          ..add('evaluationDay', evaluationDay)
          ..add('timezone', timezone)
          ..add('nextEvaluationAt', nextEvaluationAt)
          ..add('currentWeek', currentWeek)
          ..add('lastCompletedWeek', lastCompletedWeek)
          ..add('latestRun', latestRun)
          ..add('lastCompletedWeekRun', lastCompletedWeekRun))
        .toString();
  }
}

class DriverRankingScheduleStatusDtoBuilder
    implements
        Builder<
          DriverRankingScheduleStatusDto,
          DriverRankingScheduleStatusDtoBuilder
        > {
  _$DriverRankingScheduleStatusDto? _$v;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  String? _evalTime;
  String? get evalTime => _$this._evalTime;
  set evalTime(String? evalTime) => _$this._evalTime = evalTime;

  String? _frequency;
  String? get frequency => _$this._frequency;
  set frequency(String? frequency) => _$this._frequency = frequency;

  String? _evaluationDay;
  String? get evaluationDay => _$this._evaluationDay;
  set evaluationDay(String? evaluationDay) =>
      _$this._evaluationDay = evaluationDay;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  DateTime? _nextEvaluationAt;
  DateTime? get nextEvaluationAt => _$this._nextEvaluationAt;
  set nextEvaluationAt(DateTime? nextEvaluationAt) =>
      _$this._nextEvaluationAt = nextEvaluationAt;

  RankingWeekWindowDtoBuilder? _currentWeek;
  RankingWeekWindowDtoBuilder get currentWeek =>
      _$this._currentWeek ??= RankingWeekWindowDtoBuilder();
  set currentWeek(RankingWeekWindowDtoBuilder? currentWeek) =>
      _$this._currentWeek = currentWeek;

  RankingWeekWindowDtoBuilder? _lastCompletedWeek;
  RankingWeekWindowDtoBuilder get lastCompletedWeek =>
      _$this._lastCompletedWeek ??= RankingWeekWindowDtoBuilder();
  set lastCompletedWeek(RankingWeekWindowDtoBuilder? lastCompletedWeek) =>
      _$this._lastCompletedWeek = lastCompletedWeek;

  DriverRankingEvaluationRunDtoBuilder? _latestRun;
  DriverRankingEvaluationRunDtoBuilder get latestRun =>
      _$this._latestRun ??= DriverRankingEvaluationRunDtoBuilder();
  set latestRun(DriverRankingEvaluationRunDtoBuilder? latestRun) =>
      _$this._latestRun = latestRun;

  DriverRankingEvaluationRunDtoBuilder? _lastCompletedWeekRun;
  DriverRankingEvaluationRunDtoBuilder get lastCompletedWeekRun =>
      _$this._lastCompletedWeekRun ??= DriverRankingEvaluationRunDtoBuilder();
  set lastCompletedWeekRun(
    DriverRankingEvaluationRunDtoBuilder? lastCompletedWeekRun,
  ) => _$this._lastCompletedWeekRun = lastCompletedWeekRun;

  DriverRankingScheduleStatusDtoBuilder() {
    DriverRankingScheduleStatusDto._defaults(this);
  }

  DriverRankingScheduleStatusDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enabled = $v.enabled;
      _evalTime = $v.evalTime;
      _frequency = $v.frequency;
      _evaluationDay = $v.evaluationDay;
      _timezone = $v.timezone;
      _nextEvaluationAt = $v.nextEvaluationAt;
      _currentWeek = $v.currentWeek.toBuilder();
      _lastCompletedWeek = $v.lastCompletedWeek.toBuilder();
      _latestRun = $v.latestRun?.toBuilder();
      _lastCompletedWeekRun = $v.lastCompletedWeekRun?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverRankingScheduleStatusDto other) {
    _$v = other as _$DriverRankingScheduleStatusDto;
  }

  @override
  void update(void Function(DriverRankingScheduleStatusDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverRankingScheduleStatusDto build() => _build();

  _$DriverRankingScheduleStatusDto _build() {
    _$DriverRankingScheduleStatusDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverRankingScheduleStatusDto._(
            enabled: BuiltValueNullFieldError.checkNotNull(
              enabled,
              r'DriverRankingScheduleStatusDto',
              'enabled',
            ),
            evalTime: BuiltValueNullFieldError.checkNotNull(
              evalTime,
              r'DriverRankingScheduleStatusDto',
              'evalTime',
            ),
            frequency: BuiltValueNullFieldError.checkNotNull(
              frequency,
              r'DriverRankingScheduleStatusDto',
              'frequency',
            ),
            evaluationDay: BuiltValueNullFieldError.checkNotNull(
              evaluationDay,
              r'DriverRankingScheduleStatusDto',
              'evaluationDay',
            ),
            timezone: BuiltValueNullFieldError.checkNotNull(
              timezone,
              r'DriverRankingScheduleStatusDto',
              'timezone',
            ),
            nextEvaluationAt: BuiltValueNullFieldError.checkNotNull(
              nextEvaluationAt,
              r'DriverRankingScheduleStatusDto',
              'nextEvaluationAt',
            ),
            currentWeek: currentWeek.build(),
            lastCompletedWeek: lastCompletedWeek.build(),
            latestRun: _latestRun?.build(),
            lastCompletedWeekRun: _lastCompletedWeekRun?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'currentWeek';
        currentWeek.build();
        _$failedField = 'lastCompletedWeek';
        lastCompletedWeek.build();
        _$failedField = 'latestRun';
        _latestRun?.build();
        _$failedField = 'lastCompletedWeekRun';
        _lastCompletedWeekRun?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverRankingScheduleStatusDto',
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
