// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_metrics_snapshot_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverMetricsSnapshotDto extends DriverMetricsSnapshotDto {
  @override
  final num acceptedDispatches;
  @override
  final num rejectedDispatches;
  @override
  final num expiredDispatches;
  @override
  final num eligibleDispatches;
  @override
  final num cancelledDispatches;
  @override
  final num completedOrders;
  @override
  final num driverFaultFailures;
  @override
  final num driverResponsibleOrders;
  @override
  final ExcludedIncidentsSummaryDto excludedIncidents;
  @override
  final num onTimeShifts;
  @override
  final num lateShifts;
  @override
  final num missedShifts;
  @override
  final num eligibleShifts;
  @override
  final num cancelledShifts;
  @override
  final num excusedShifts;
  @override
  final num? acceptanceRate;
  @override
  final num? completionRate;
  @override
  final num? shiftPunctualityRate;
  @override
  final num applicableMetricsCount;
  @override
  final bool cappedDueToNoOrders;
  @override
  final BuiltList<String> explanations;

  factory _$DriverMetricsSnapshotDto([
    void Function(DriverMetricsSnapshotDtoBuilder)? updates,
  ]) => (DriverMetricsSnapshotDtoBuilder()..update(updates))._build();

  _$DriverMetricsSnapshotDto._({
    required this.acceptedDispatches,
    required this.rejectedDispatches,
    required this.expiredDispatches,
    required this.eligibleDispatches,
    required this.cancelledDispatches,
    required this.completedOrders,
    required this.driverFaultFailures,
    required this.driverResponsibleOrders,
    required this.excludedIncidents,
    required this.onTimeShifts,
    required this.lateShifts,
    required this.missedShifts,
    required this.eligibleShifts,
    required this.cancelledShifts,
    required this.excusedShifts,
    this.acceptanceRate,
    this.completionRate,
    this.shiftPunctualityRate,
    required this.applicableMetricsCount,
    required this.cappedDueToNoOrders,
    required this.explanations,
  }) : super._();
  @override
  DriverMetricsSnapshotDto rebuild(
    void Function(DriverMetricsSnapshotDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverMetricsSnapshotDtoBuilder toBuilder() =>
      DriverMetricsSnapshotDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverMetricsSnapshotDto &&
        acceptedDispatches == other.acceptedDispatches &&
        rejectedDispatches == other.rejectedDispatches &&
        expiredDispatches == other.expiredDispatches &&
        eligibleDispatches == other.eligibleDispatches &&
        cancelledDispatches == other.cancelledDispatches &&
        completedOrders == other.completedOrders &&
        driverFaultFailures == other.driverFaultFailures &&
        driverResponsibleOrders == other.driverResponsibleOrders &&
        excludedIncidents == other.excludedIncidents &&
        onTimeShifts == other.onTimeShifts &&
        lateShifts == other.lateShifts &&
        missedShifts == other.missedShifts &&
        eligibleShifts == other.eligibleShifts &&
        cancelledShifts == other.cancelledShifts &&
        excusedShifts == other.excusedShifts &&
        acceptanceRate == other.acceptanceRate &&
        completionRate == other.completionRate &&
        shiftPunctualityRate == other.shiftPunctualityRate &&
        applicableMetricsCount == other.applicableMetricsCount &&
        cappedDueToNoOrders == other.cappedDueToNoOrders &&
        explanations == other.explanations;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, acceptedDispatches.hashCode);
    _$hash = $jc(_$hash, rejectedDispatches.hashCode);
    _$hash = $jc(_$hash, expiredDispatches.hashCode);
    _$hash = $jc(_$hash, eligibleDispatches.hashCode);
    _$hash = $jc(_$hash, cancelledDispatches.hashCode);
    _$hash = $jc(_$hash, completedOrders.hashCode);
    _$hash = $jc(_$hash, driverFaultFailures.hashCode);
    _$hash = $jc(_$hash, driverResponsibleOrders.hashCode);
    _$hash = $jc(_$hash, excludedIncidents.hashCode);
    _$hash = $jc(_$hash, onTimeShifts.hashCode);
    _$hash = $jc(_$hash, lateShifts.hashCode);
    _$hash = $jc(_$hash, missedShifts.hashCode);
    _$hash = $jc(_$hash, eligibleShifts.hashCode);
    _$hash = $jc(_$hash, cancelledShifts.hashCode);
    _$hash = $jc(_$hash, excusedShifts.hashCode);
    _$hash = $jc(_$hash, acceptanceRate.hashCode);
    _$hash = $jc(_$hash, completionRate.hashCode);
    _$hash = $jc(_$hash, shiftPunctualityRate.hashCode);
    _$hash = $jc(_$hash, applicableMetricsCount.hashCode);
    _$hash = $jc(_$hash, cappedDueToNoOrders.hashCode);
    _$hash = $jc(_$hash, explanations.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverMetricsSnapshotDto')
          ..add('acceptedDispatches', acceptedDispatches)
          ..add('rejectedDispatches', rejectedDispatches)
          ..add('expiredDispatches', expiredDispatches)
          ..add('eligibleDispatches', eligibleDispatches)
          ..add('cancelledDispatches', cancelledDispatches)
          ..add('completedOrders', completedOrders)
          ..add('driverFaultFailures', driverFaultFailures)
          ..add('driverResponsibleOrders', driverResponsibleOrders)
          ..add('excludedIncidents', excludedIncidents)
          ..add('onTimeShifts', onTimeShifts)
          ..add('lateShifts', lateShifts)
          ..add('missedShifts', missedShifts)
          ..add('eligibleShifts', eligibleShifts)
          ..add('cancelledShifts', cancelledShifts)
          ..add('excusedShifts', excusedShifts)
          ..add('acceptanceRate', acceptanceRate)
          ..add('completionRate', completionRate)
          ..add('shiftPunctualityRate', shiftPunctualityRate)
          ..add('applicableMetricsCount', applicableMetricsCount)
          ..add('cappedDueToNoOrders', cappedDueToNoOrders)
          ..add('explanations', explanations))
        .toString();
  }
}

class DriverMetricsSnapshotDtoBuilder
    implements
        Builder<DriverMetricsSnapshotDto, DriverMetricsSnapshotDtoBuilder> {
  _$DriverMetricsSnapshotDto? _$v;

  num? _acceptedDispatches;
  num? get acceptedDispatches => _$this._acceptedDispatches;
  set acceptedDispatches(num? acceptedDispatches) =>
      _$this._acceptedDispatches = acceptedDispatches;

  num? _rejectedDispatches;
  num? get rejectedDispatches => _$this._rejectedDispatches;
  set rejectedDispatches(num? rejectedDispatches) =>
      _$this._rejectedDispatches = rejectedDispatches;

  num? _expiredDispatches;
  num? get expiredDispatches => _$this._expiredDispatches;
  set expiredDispatches(num? expiredDispatches) =>
      _$this._expiredDispatches = expiredDispatches;

  num? _eligibleDispatches;
  num? get eligibleDispatches => _$this._eligibleDispatches;
  set eligibleDispatches(num? eligibleDispatches) =>
      _$this._eligibleDispatches = eligibleDispatches;

  num? _cancelledDispatches;
  num? get cancelledDispatches => _$this._cancelledDispatches;
  set cancelledDispatches(num? cancelledDispatches) =>
      _$this._cancelledDispatches = cancelledDispatches;

  num? _completedOrders;
  num? get completedOrders => _$this._completedOrders;
  set completedOrders(num? completedOrders) =>
      _$this._completedOrders = completedOrders;

  num? _driverFaultFailures;
  num? get driverFaultFailures => _$this._driverFaultFailures;
  set driverFaultFailures(num? driverFaultFailures) =>
      _$this._driverFaultFailures = driverFaultFailures;

  num? _driverResponsibleOrders;
  num? get driverResponsibleOrders => _$this._driverResponsibleOrders;
  set driverResponsibleOrders(num? driverResponsibleOrders) =>
      _$this._driverResponsibleOrders = driverResponsibleOrders;

  ExcludedIncidentsSummaryDtoBuilder? _excludedIncidents;
  ExcludedIncidentsSummaryDtoBuilder get excludedIncidents =>
      _$this._excludedIncidents ??= ExcludedIncidentsSummaryDtoBuilder();
  set excludedIncidents(
    ExcludedIncidentsSummaryDtoBuilder? excludedIncidents,
  ) => _$this._excludedIncidents = excludedIncidents;

  num? _onTimeShifts;
  num? get onTimeShifts => _$this._onTimeShifts;
  set onTimeShifts(num? onTimeShifts) => _$this._onTimeShifts = onTimeShifts;

  num? _lateShifts;
  num? get lateShifts => _$this._lateShifts;
  set lateShifts(num? lateShifts) => _$this._lateShifts = lateShifts;

  num? _missedShifts;
  num? get missedShifts => _$this._missedShifts;
  set missedShifts(num? missedShifts) => _$this._missedShifts = missedShifts;

  num? _eligibleShifts;
  num? get eligibleShifts => _$this._eligibleShifts;
  set eligibleShifts(num? eligibleShifts) =>
      _$this._eligibleShifts = eligibleShifts;

  num? _cancelledShifts;
  num? get cancelledShifts => _$this._cancelledShifts;
  set cancelledShifts(num? cancelledShifts) =>
      _$this._cancelledShifts = cancelledShifts;

  num? _excusedShifts;
  num? get excusedShifts => _$this._excusedShifts;
  set excusedShifts(num? excusedShifts) =>
      _$this._excusedShifts = excusedShifts;

  num? _acceptanceRate;
  num? get acceptanceRate => _$this._acceptanceRate;
  set acceptanceRate(num? acceptanceRate) =>
      _$this._acceptanceRate = acceptanceRate;

  num? _completionRate;
  num? get completionRate => _$this._completionRate;
  set completionRate(num? completionRate) =>
      _$this._completionRate = completionRate;

  num? _shiftPunctualityRate;
  num? get shiftPunctualityRate => _$this._shiftPunctualityRate;
  set shiftPunctualityRate(num? shiftPunctualityRate) =>
      _$this._shiftPunctualityRate = shiftPunctualityRate;

  num? _applicableMetricsCount;
  num? get applicableMetricsCount => _$this._applicableMetricsCount;
  set applicableMetricsCount(num? applicableMetricsCount) =>
      _$this._applicableMetricsCount = applicableMetricsCount;

  bool? _cappedDueToNoOrders;
  bool? get cappedDueToNoOrders => _$this._cappedDueToNoOrders;
  set cappedDueToNoOrders(bool? cappedDueToNoOrders) =>
      _$this._cappedDueToNoOrders = cappedDueToNoOrders;

  ListBuilder<String>? _explanations;
  ListBuilder<String> get explanations =>
      _$this._explanations ??= ListBuilder<String>();
  set explanations(ListBuilder<String>? explanations) =>
      _$this._explanations = explanations;

  DriverMetricsSnapshotDtoBuilder() {
    DriverMetricsSnapshotDto._defaults(this);
  }

  DriverMetricsSnapshotDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _acceptedDispatches = $v.acceptedDispatches;
      _rejectedDispatches = $v.rejectedDispatches;
      _expiredDispatches = $v.expiredDispatches;
      _eligibleDispatches = $v.eligibleDispatches;
      _cancelledDispatches = $v.cancelledDispatches;
      _completedOrders = $v.completedOrders;
      _driverFaultFailures = $v.driverFaultFailures;
      _driverResponsibleOrders = $v.driverResponsibleOrders;
      _excludedIncidents = $v.excludedIncidents.toBuilder();
      _onTimeShifts = $v.onTimeShifts;
      _lateShifts = $v.lateShifts;
      _missedShifts = $v.missedShifts;
      _eligibleShifts = $v.eligibleShifts;
      _cancelledShifts = $v.cancelledShifts;
      _excusedShifts = $v.excusedShifts;
      _acceptanceRate = $v.acceptanceRate;
      _completionRate = $v.completionRate;
      _shiftPunctualityRate = $v.shiftPunctualityRate;
      _applicableMetricsCount = $v.applicableMetricsCount;
      _cappedDueToNoOrders = $v.cappedDueToNoOrders;
      _explanations = $v.explanations.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverMetricsSnapshotDto other) {
    _$v = other as _$DriverMetricsSnapshotDto;
  }

  @override
  void update(void Function(DriverMetricsSnapshotDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverMetricsSnapshotDto build() => _build();

  _$DriverMetricsSnapshotDto _build() {
    _$DriverMetricsSnapshotDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverMetricsSnapshotDto._(
            acceptedDispatches: BuiltValueNullFieldError.checkNotNull(
              acceptedDispatches,
              r'DriverMetricsSnapshotDto',
              'acceptedDispatches',
            ),
            rejectedDispatches: BuiltValueNullFieldError.checkNotNull(
              rejectedDispatches,
              r'DriverMetricsSnapshotDto',
              'rejectedDispatches',
            ),
            expiredDispatches: BuiltValueNullFieldError.checkNotNull(
              expiredDispatches,
              r'DriverMetricsSnapshotDto',
              'expiredDispatches',
            ),
            eligibleDispatches: BuiltValueNullFieldError.checkNotNull(
              eligibleDispatches,
              r'DriverMetricsSnapshotDto',
              'eligibleDispatches',
            ),
            cancelledDispatches: BuiltValueNullFieldError.checkNotNull(
              cancelledDispatches,
              r'DriverMetricsSnapshotDto',
              'cancelledDispatches',
            ),
            completedOrders: BuiltValueNullFieldError.checkNotNull(
              completedOrders,
              r'DriverMetricsSnapshotDto',
              'completedOrders',
            ),
            driverFaultFailures: BuiltValueNullFieldError.checkNotNull(
              driverFaultFailures,
              r'DriverMetricsSnapshotDto',
              'driverFaultFailures',
            ),
            driverResponsibleOrders: BuiltValueNullFieldError.checkNotNull(
              driverResponsibleOrders,
              r'DriverMetricsSnapshotDto',
              'driverResponsibleOrders',
            ),
            excludedIncidents: excludedIncidents.build(),
            onTimeShifts: BuiltValueNullFieldError.checkNotNull(
              onTimeShifts,
              r'DriverMetricsSnapshotDto',
              'onTimeShifts',
            ),
            lateShifts: BuiltValueNullFieldError.checkNotNull(
              lateShifts,
              r'DriverMetricsSnapshotDto',
              'lateShifts',
            ),
            missedShifts: BuiltValueNullFieldError.checkNotNull(
              missedShifts,
              r'DriverMetricsSnapshotDto',
              'missedShifts',
            ),
            eligibleShifts: BuiltValueNullFieldError.checkNotNull(
              eligibleShifts,
              r'DriverMetricsSnapshotDto',
              'eligibleShifts',
            ),
            cancelledShifts: BuiltValueNullFieldError.checkNotNull(
              cancelledShifts,
              r'DriverMetricsSnapshotDto',
              'cancelledShifts',
            ),
            excusedShifts: BuiltValueNullFieldError.checkNotNull(
              excusedShifts,
              r'DriverMetricsSnapshotDto',
              'excusedShifts',
            ),
            acceptanceRate: acceptanceRate,
            completionRate: completionRate,
            shiftPunctualityRate: shiftPunctualityRate,
            applicableMetricsCount: BuiltValueNullFieldError.checkNotNull(
              applicableMetricsCount,
              r'DriverMetricsSnapshotDto',
              'applicableMetricsCount',
            ),
            cappedDueToNoOrders: BuiltValueNullFieldError.checkNotNull(
              cappedDueToNoOrders,
              r'DriverMetricsSnapshotDto',
              'cappedDueToNoOrders',
            ),
            explanations: explanations.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'excludedIncidents';
        excludedIncidents.build();

        _$failedField = 'explanations';
        explanations.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverMetricsSnapshotDto',
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
