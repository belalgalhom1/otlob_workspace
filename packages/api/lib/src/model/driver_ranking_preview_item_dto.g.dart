// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_preview_item_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverRankingPreviewItemDto extends DriverRankingPreviewItemDto {
  @override
  final String driverId;
  @override
  final String driverName;
  @override
  final DriverTier previousTier;
  @override
  final DriverTier newTier;
  @override
  final DriverRankChangeReason changeReason;
  @override
  final DriverRankingOutcome outcome;
  @override
  final num? performancePercentage;
  @override
  final num? acceptanceRate;
  @override
  final num? completionRate;
  @override
  final num? shiftPunctualityRate;
  @override
  final DriverMetricsSnapshotDto metricsSnapshot;
  @override
  final BuiltList<String> explanations;

  factory _$DriverRankingPreviewItemDto([
    void Function(DriverRankingPreviewItemDtoBuilder)? updates,
  ]) => (DriverRankingPreviewItemDtoBuilder()..update(updates))._build();

  _$DriverRankingPreviewItemDto._({
    required this.driverId,
    required this.driverName,
    required this.previousTier,
    required this.newTier,
    required this.changeReason,
    required this.outcome,
    this.performancePercentage,
    this.acceptanceRate,
    this.completionRate,
    this.shiftPunctualityRate,
    required this.metricsSnapshot,
    required this.explanations,
  }) : super._();
  @override
  DriverRankingPreviewItemDto rebuild(
    void Function(DriverRankingPreviewItemDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverRankingPreviewItemDtoBuilder toBuilder() =>
      DriverRankingPreviewItemDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverRankingPreviewItemDto &&
        driverId == other.driverId &&
        driverName == other.driverName &&
        previousTier == other.previousTier &&
        newTier == other.newTier &&
        changeReason == other.changeReason &&
        outcome == other.outcome &&
        performancePercentage == other.performancePercentage &&
        acceptanceRate == other.acceptanceRate &&
        completionRate == other.completionRate &&
        shiftPunctualityRate == other.shiftPunctualityRate &&
        metricsSnapshot == other.metricsSnapshot &&
        explanations == other.explanations;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, driverName.hashCode);
    _$hash = $jc(_$hash, previousTier.hashCode);
    _$hash = $jc(_$hash, newTier.hashCode);
    _$hash = $jc(_$hash, changeReason.hashCode);
    _$hash = $jc(_$hash, outcome.hashCode);
    _$hash = $jc(_$hash, performancePercentage.hashCode);
    _$hash = $jc(_$hash, acceptanceRate.hashCode);
    _$hash = $jc(_$hash, completionRate.hashCode);
    _$hash = $jc(_$hash, shiftPunctualityRate.hashCode);
    _$hash = $jc(_$hash, metricsSnapshot.hashCode);
    _$hash = $jc(_$hash, explanations.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverRankingPreviewItemDto')
          ..add('driverId', driverId)
          ..add('driverName', driverName)
          ..add('previousTier', previousTier)
          ..add('newTier', newTier)
          ..add('changeReason', changeReason)
          ..add('outcome', outcome)
          ..add('performancePercentage', performancePercentage)
          ..add('acceptanceRate', acceptanceRate)
          ..add('completionRate', completionRate)
          ..add('shiftPunctualityRate', shiftPunctualityRate)
          ..add('metricsSnapshot', metricsSnapshot)
          ..add('explanations', explanations))
        .toString();
  }
}

class DriverRankingPreviewItemDtoBuilder
    implements
        Builder<
          DriverRankingPreviewItemDto,
          DriverRankingPreviewItemDtoBuilder
        > {
  _$DriverRankingPreviewItemDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _driverName;
  String? get driverName => _$this._driverName;
  set driverName(String? driverName) => _$this._driverName = driverName;

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

  DriverRankingOutcome? _outcome;
  DriverRankingOutcome? get outcome => _$this._outcome;
  set outcome(DriverRankingOutcome? outcome) => _$this._outcome = outcome;

  num? _performancePercentage;
  num? get performancePercentage => _$this._performancePercentage;
  set performancePercentage(num? performancePercentage) =>
      _$this._performancePercentage = performancePercentage;

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

  DriverMetricsSnapshotDtoBuilder? _metricsSnapshot;
  DriverMetricsSnapshotDtoBuilder get metricsSnapshot =>
      _$this._metricsSnapshot ??= DriverMetricsSnapshotDtoBuilder();
  set metricsSnapshot(DriverMetricsSnapshotDtoBuilder? metricsSnapshot) =>
      _$this._metricsSnapshot = metricsSnapshot;

  ListBuilder<String>? _explanations;
  ListBuilder<String> get explanations =>
      _$this._explanations ??= ListBuilder<String>();
  set explanations(ListBuilder<String>? explanations) =>
      _$this._explanations = explanations;

  DriverRankingPreviewItemDtoBuilder() {
    DriverRankingPreviewItemDto._defaults(this);
  }

  DriverRankingPreviewItemDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _driverName = $v.driverName;
      _previousTier = $v.previousTier;
      _newTier = $v.newTier;
      _changeReason = $v.changeReason;
      _outcome = $v.outcome;
      _performancePercentage = $v.performancePercentage;
      _acceptanceRate = $v.acceptanceRate;
      _completionRate = $v.completionRate;
      _shiftPunctualityRate = $v.shiftPunctualityRate;
      _metricsSnapshot = $v.metricsSnapshot.toBuilder();
      _explanations = $v.explanations.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverRankingPreviewItemDto other) {
    _$v = other as _$DriverRankingPreviewItemDto;
  }

  @override
  void update(void Function(DriverRankingPreviewItemDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverRankingPreviewItemDto build() => _build();

  _$DriverRankingPreviewItemDto _build() {
    _$DriverRankingPreviewItemDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverRankingPreviewItemDto._(
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'DriverRankingPreviewItemDto',
              'driverId',
            ),
            driverName: BuiltValueNullFieldError.checkNotNull(
              driverName,
              r'DriverRankingPreviewItemDto',
              'driverName',
            ),
            previousTier: BuiltValueNullFieldError.checkNotNull(
              previousTier,
              r'DriverRankingPreviewItemDto',
              'previousTier',
            ),
            newTier: BuiltValueNullFieldError.checkNotNull(
              newTier,
              r'DriverRankingPreviewItemDto',
              'newTier',
            ),
            changeReason: BuiltValueNullFieldError.checkNotNull(
              changeReason,
              r'DriverRankingPreviewItemDto',
              'changeReason',
            ),
            outcome: BuiltValueNullFieldError.checkNotNull(
              outcome,
              r'DriverRankingPreviewItemDto',
              'outcome',
            ),
            performancePercentage: performancePercentage,
            acceptanceRate: acceptanceRate,
            completionRate: completionRate,
            shiftPunctualityRate: shiftPunctualityRate,
            metricsSnapshot: metricsSnapshot.build(),
            explanations: explanations.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'metricsSnapshot';
        metricsSnapshot.build();
        _$failedField = 'explanations';
        explanations.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverRankingPreviewItemDto',
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
