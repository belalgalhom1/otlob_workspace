// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_rank_history_entry_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverRankHistoryEntryDto extends DriverRankHistoryEntryDto {
  @override
  final String id;
  @override
  final String driverId;
  @override
  final JsonObject? driverName;
  @override
  final JsonObject? runId;
  @override
  final JsonObject? periodKey;
  @override
  final DateTime evaluatedAt;
  @override
  final DateTime? periodStart;
  @override
  final DateTime? periodEnd;
  @override
  final num? performancePercentage;
  @override
  final DriverMetricsSnapshotDto? metricsSnapshot;
  @override
  final DriverTier previousTier;
  @override
  final DriverTier newTier;
  @override
  final DriverRankChangeReason changeReason;
  @override
  final JsonObject? adminUserId;
  @override
  final JsonObject? overrideReason;
  @override
  final DateTime createdAt;

  factory _$DriverRankHistoryEntryDto([
    void Function(DriverRankHistoryEntryDtoBuilder)? updates,
  ]) => (DriverRankHistoryEntryDtoBuilder()..update(updates))._build();

  _$DriverRankHistoryEntryDto._({
    required this.id,
    required this.driverId,
    this.driverName,
    this.runId,
    this.periodKey,
    required this.evaluatedAt,
    this.periodStart,
    this.periodEnd,
    this.performancePercentage,
    this.metricsSnapshot,
    required this.previousTier,
    required this.newTier,
    required this.changeReason,
    this.adminUserId,
    this.overrideReason,
    required this.createdAt,
  }) : super._();
  @override
  DriverRankHistoryEntryDto rebuild(
    void Function(DriverRankHistoryEntryDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverRankHistoryEntryDtoBuilder toBuilder() =>
      DriverRankHistoryEntryDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverRankHistoryEntryDto &&
        id == other.id &&
        driverId == other.driverId &&
        driverName == other.driverName &&
        runId == other.runId &&
        periodKey == other.periodKey &&
        evaluatedAt == other.evaluatedAt &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd &&
        performancePercentage == other.performancePercentage &&
        metricsSnapshot == other.metricsSnapshot &&
        previousTier == other.previousTier &&
        newTier == other.newTier &&
        changeReason == other.changeReason &&
        adminUserId == other.adminUserId &&
        overrideReason == other.overrideReason &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, driverName.hashCode);
    _$hash = $jc(_$hash, runId.hashCode);
    _$hash = $jc(_$hash, periodKey.hashCode);
    _$hash = $jc(_$hash, evaluatedAt.hashCode);
    _$hash = $jc(_$hash, periodStart.hashCode);
    _$hash = $jc(_$hash, periodEnd.hashCode);
    _$hash = $jc(_$hash, performancePercentage.hashCode);
    _$hash = $jc(_$hash, metricsSnapshot.hashCode);
    _$hash = $jc(_$hash, previousTier.hashCode);
    _$hash = $jc(_$hash, newTier.hashCode);
    _$hash = $jc(_$hash, changeReason.hashCode);
    _$hash = $jc(_$hash, adminUserId.hashCode);
    _$hash = $jc(_$hash, overrideReason.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverRankHistoryEntryDto')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('driverName', driverName)
          ..add('runId', runId)
          ..add('periodKey', periodKey)
          ..add('evaluatedAt', evaluatedAt)
          ..add('periodStart', periodStart)
          ..add('periodEnd', periodEnd)
          ..add('performancePercentage', performancePercentage)
          ..add('metricsSnapshot', metricsSnapshot)
          ..add('previousTier', previousTier)
          ..add('newTier', newTier)
          ..add('changeReason', changeReason)
          ..add('adminUserId', adminUserId)
          ..add('overrideReason', overrideReason)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class DriverRankHistoryEntryDtoBuilder
    implements
        Builder<DriverRankHistoryEntryDto, DriverRankHistoryEntryDtoBuilder> {
  _$DriverRankHistoryEntryDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  JsonObject? _driverName;
  JsonObject? get driverName => _$this._driverName;
  set driverName(JsonObject? driverName) => _$this._driverName = driverName;

  JsonObject? _runId;
  JsonObject? get runId => _$this._runId;
  set runId(JsonObject? runId) => _$this._runId = runId;

  JsonObject? _periodKey;
  JsonObject? get periodKey => _$this._periodKey;
  set periodKey(JsonObject? periodKey) => _$this._periodKey = periodKey;

  DateTime? _evaluatedAt;
  DateTime? get evaluatedAt => _$this._evaluatedAt;
  set evaluatedAt(DateTime? evaluatedAt) => _$this._evaluatedAt = evaluatedAt;

  DateTime? _periodStart;
  DateTime? get periodStart => _$this._periodStart;
  set periodStart(DateTime? periodStart) => _$this._periodStart = periodStart;

  DateTime? _periodEnd;
  DateTime? get periodEnd => _$this._periodEnd;
  set periodEnd(DateTime? periodEnd) => _$this._periodEnd = periodEnd;

  num? _performancePercentage;
  num? get performancePercentage => _$this._performancePercentage;
  set performancePercentage(num? performancePercentage) =>
      _$this._performancePercentage = performancePercentage;

  DriverMetricsSnapshotDtoBuilder? _metricsSnapshot;
  DriverMetricsSnapshotDtoBuilder get metricsSnapshot =>
      _$this._metricsSnapshot ??= DriverMetricsSnapshotDtoBuilder();
  set metricsSnapshot(DriverMetricsSnapshotDtoBuilder? metricsSnapshot) =>
      _$this._metricsSnapshot = metricsSnapshot;

  DriverTier? _previousTier;
  DriverTier? get previousTier => _$this._previousTier;
  set previousTier(DriverTier? previousTier) =>
      _$this._previousTier = previousTier;

  DriverTier? _newTier;
  DriverTier? get newTier => _$this._newTier;
  set newTier(DriverTier? newTier) => _$this._newTier = newTier;

  DriverRankChangeReason? _changeReason;
  DriverRankChangeReason? get changeReason => _$this._changeReason;
  set changeReason(DriverRankChangeReason? changeReason) =>
      _$this._changeReason = changeReason;

  JsonObject? _adminUserId;
  JsonObject? get adminUserId => _$this._adminUserId;
  set adminUserId(JsonObject? adminUserId) => _$this._adminUserId = adminUserId;

  JsonObject? _overrideReason;
  JsonObject? get overrideReason => _$this._overrideReason;
  set overrideReason(JsonObject? overrideReason) =>
      _$this._overrideReason = overrideReason;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DriverRankHistoryEntryDtoBuilder() {
    DriverRankHistoryEntryDto._defaults(this);
  }

  DriverRankHistoryEntryDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverId = $v.driverId;
      _driverName = $v.driverName;
      _runId = $v.runId;
      _periodKey = $v.periodKey;
      _evaluatedAt = $v.evaluatedAt;
      _periodStart = $v.periodStart;
      _periodEnd = $v.periodEnd;
      _performancePercentage = $v.performancePercentage;
      _metricsSnapshot = $v.metricsSnapshot?.toBuilder();
      _previousTier = $v.previousTier;
      _newTier = $v.newTier;
      _changeReason = $v.changeReason;
      _adminUserId = $v.adminUserId;
      _overrideReason = $v.overrideReason;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverRankHistoryEntryDto other) {
    _$v = other as _$DriverRankHistoryEntryDto;
  }

  @override
  void update(void Function(DriverRankHistoryEntryDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverRankHistoryEntryDto build() => _build();

  _$DriverRankHistoryEntryDto _build() {
    _$DriverRankHistoryEntryDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverRankHistoryEntryDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'DriverRankHistoryEntryDto',
              'id',
            ),
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'DriverRankHistoryEntryDto',
              'driverId',
            ),
            driverName: driverName,
            runId: runId,
            periodKey: periodKey,
            evaluatedAt: BuiltValueNullFieldError.checkNotNull(
              evaluatedAt,
              r'DriverRankHistoryEntryDto',
              'evaluatedAt',
            ),
            periodStart: periodStart,
            periodEnd: periodEnd,
            performancePercentage: performancePercentage,
            metricsSnapshot: _metricsSnapshot?.build(),
            previousTier: BuiltValueNullFieldError.checkNotNull(
              previousTier,
              r'DriverRankHistoryEntryDto',
              'previousTier',
            ),
            newTier: BuiltValueNullFieldError.checkNotNull(
              newTier,
              r'DriverRankHistoryEntryDto',
              'newTier',
            ),
            changeReason: BuiltValueNullFieldError.checkNotNull(
              changeReason,
              r'DriverRankHistoryEntryDto',
              'changeReason',
            ),
            adminUserId: adminUserId,
            overrideReason: overrideReason,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'DriverRankHistoryEntryDto',
              'createdAt',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'metricsSnapshot';
        _metricsSnapshot?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverRankHistoryEntryDto',
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
