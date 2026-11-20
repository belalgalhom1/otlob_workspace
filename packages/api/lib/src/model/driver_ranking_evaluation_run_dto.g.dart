// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_evaluation_run_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverRankingEvaluationRunDto extends DriverRankingEvaluationRunDto {
  @override
  final String id;
  @override
  final String periodKey;
  @override
  final DriverRankingRunStatus status;
  @override
  final DriverRankingTriggerSource triggerSource;
  @override
  final JsonObject? triggeredByUserId;
  @override
  final DateTime scheduledFor;
  @override
  final DateTime? executedAt;
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;
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
  final JsonObject? errorMessage;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$DriverRankingEvaluationRunDto([
    void Function(DriverRankingEvaluationRunDtoBuilder)? updates,
  ]) => (DriverRankingEvaluationRunDtoBuilder()..update(updates))._build();

  _$DriverRankingEvaluationRunDto._({
    required this.id,
    required this.periodKey,
    required this.status,
    required this.triggerSource,
    this.triggeredByUserId,
    required this.scheduledFor,
    this.executedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.totalDrivers,
    required this.promotedCount,
    required this.demotedCount,
    required this.unchangedCount,
    required this.inactiveCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  DriverRankingEvaluationRunDto rebuild(
    void Function(DriverRankingEvaluationRunDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverRankingEvaluationRunDtoBuilder toBuilder() =>
      DriverRankingEvaluationRunDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverRankingEvaluationRunDto &&
        id == other.id &&
        periodKey == other.periodKey &&
        status == other.status &&
        triggerSource == other.triggerSource &&
        triggeredByUserId == other.triggeredByUserId &&
        scheduledFor == other.scheduledFor &&
        executedAt == other.executedAt &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd &&
        totalDrivers == other.totalDrivers &&
        promotedCount == other.promotedCount &&
        demotedCount == other.demotedCount &&
        unchangedCount == other.unchangedCount &&
        inactiveCount == other.inactiveCount &&
        errorMessage == other.errorMessage &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, periodKey.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, triggerSource.hashCode);
    _$hash = $jc(_$hash, triggeredByUserId.hashCode);
    _$hash = $jc(_$hash, scheduledFor.hashCode);
    _$hash = $jc(_$hash, executedAt.hashCode);
    _$hash = $jc(_$hash, periodStart.hashCode);
    _$hash = $jc(_$hash, periodEnd.hashCode);
    _$hash = $jc(_$hash, totalDrivers.hashCode);
    _$hash = $jc(_$hash, promotedCount.hashCode);
    _$hash = $jc(_$hash, demotedCount.hashCode);
    _$hash = $jc(_$hash, unchangedCount.hashCode);
    _$hash = $jc(_$hash, inactiveCount.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverRankingEvaluationRunDto')
          ..add('id', id)
          ..add('periodKey', periodKey)
          ..add('status', status)
          ..add('triggerSource', triggerSource)
          ..add('triggeredByUserId', triggeredByUserId)
          ..add('scheduledFor', scheduledFor)
          ..add('executedAt', executedAt)
          ..add('periodStart', periodStart)
          ..add('periodEnd', periodEnd)
          ..add('totalDrivers', totalDrivers)
          ..add('promotedCount', promotedCount)
          ..add('demotedCount', demotedCount)
          ..add('unchangedCount', unchangedCount)
          ..add('inactiveCount', inactiveCount)
          ..add('errorMessage', errorMessage)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class DriverRankingEvaluationRunDtoBuilder
    implements
        Builder<
          DriverRankingEvaluationRunDto,
          DriverRankingEvaluationRunDtoBuilder
        > {
  _$DriverRankingEvaluationRunDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _periodKey;
  String? get periodKey => _$this._periodKey;
  set periodKey(String? periodKey) => _$this._periodKey = periodKey;

  DriverRankingRunStatus? _status;
  DriverRankingRunStatus? get status => _$this._status;
  set status(DriverRankingRunStatus? status) => _$this._status = status;

  DriverRankingTriggerSource? _triggerSource;
  DriverRankingTriggerSource? get triggerSource => _$this._triggerSource;
  set triggerSource(DriverRankingTriggerSource? triggerSource) =>
      _$this._triggerSource = triggerSource;

  JsonObject? _triggeredByUserId;
  JsonObject? get triggeredByUserId => _$this._triggeredByUserId;
  set triggeredByUserId(JsonObject? triggeredByUserId) =>
      _$this._triggeredByUserId = triggeredByUserId;

  DateTime? _scheduledFor;
  DateTime? get scheduledFor => _$this._scheduledFor;
  set scheduledFor(DateTime? scheduledFor) =>
      _$this._scheduledFor = scheduledFor;

  DateTime? _executedAt;
  DateTime? get executedAt => _$this._executedAt;
  set executedAt(DateTime? executedAt) => _$this._executedAt = executedAt;

  DateTime? _periodStart;
  DateTime? get periodStart => _$this._periodStart;
  set periodStart(DateTime? periodStart) => _$this._periodStart = periodStart;

  DateTime? _periodEnd;
  DateTime? get periodEnd => _$this._periodEnd;
  set periodEnd(DateTime? periodEnd) => _$this._periodEnd = periodEnd;

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

  JsonObject? _errorMessage;
  JsonObject? get errorMessage => _$this._errorMessage;
  set errorMessage(JsonObject? errorMessage) =>
      _$this._errorMessage = errorMessage;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DriverRankingEvaluationRunDtoBuilder() {
    DriverRankingEvaluationRunDto._defaults(this);
  }

  DriverRankingEvaluationRunDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _periodKey = $v.periodKey;
      _status = $v.status;
      _triggerSource = $v.triggerSource;
      _triggeredByUserId = $v.triggeredByUserId;
      _scheduledFor = $v.scheduledFor;
      _executedAt = $v.executedAt;
      _periodStart = $v.periodStart;
      _periodEnd = $v.periodEnd;
      _totalDrivers = $v.totalDrivers;
      _promotedCount = $v.promotedCount;
      _demotedCount = $v.demotedCount;
      _unchangedCount = $v.unchangedCount;
      _inactiveCount = $v.inactiveCount;
      _errorMessage = $v.errorMessage;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverRankingEvaluationRunDto other) {
    _$v = other as _$DriverRankingEvaluationRunDto;
  }

  @override
  void update(void Function(DriverRankingEvaluationRunDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverRankingEvaluationRunDto build() => _build();

  _$DriverRankingEvaluationRunDto _build() {
    final _$result =
        _$v ??
        _$DriverRankingEvaluationRunDto._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'DriverRankingEvaluationRunDto',
            'id',
          ),
          periodKey: BuiltValueNullFieldError.checkNotNull(
            periodKey,
            r'DriverRankingEvaluationRunDto',
            'periodKey',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'DriverRankingEvaluationRunDto',
            'status',
          ),
          triggerSource: BuiltValueNullFieldError.checkNotNull(
            triggerSource,
            r'DriverRankingEvaluationRunDto',
            'triggerSource',
          ),
          triggeredByUserId: triggeredByUserId,
          scheduledFor: BuiltValueNullFieldError.checkNotNull(
            scheduledFor,
            r'DriverRankingEvaluationRunDto',
            'scheduledFor',
          ),
          executedAt: executedAt,
          periodStart: BuiltValueNullFieldError.checkNotNull(
            periodStart,
            r'DriverRankingEvaluationRunDto',
            'periodStart',
          ),
          periodEnd: BuiltValueNullFieldError.checkNotNull(
            periodEnd,
            r'DriverRankingEvaluationRunDto',
            'periodEnd',
          ),
          totalDrivers: BuiltValueNullFieldError.checkNotNull(
            totalDrivers,
            r'DriverRankingEvaluationRunDto',
            'totalDrivers',
          ),
          promotedCount: BuiltValueNullFieldError.checkNotNull(
            promotedCount,
            r'DriverRankingEvaluationRunDto',
            'promotedCount',
          ),
          demotedCount: BuiltValueNullFieldError.checkNotNull(
            demotedCount,
            r'DriverRankingEvaluationRunDto',
            'demotedCount',
          ),
          unchangedCount: BuiltValueNullFieldError.checkNotNull(
            unchangedCount,
            r'DriverRankingEvaluationRunDto',
            'unchangedCount',
          ),
          inactiveCount: BuiltValueNullFieldError.checkNotNull(
            inactiveCount,
            r'DriverRankingEvaluationRunDto',
            'inactiveCount',
          ),
          errorMessage: errorMessage,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'DriverRankingEvaluationRunDto',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'DriverRankingEvaluationRunDto',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
