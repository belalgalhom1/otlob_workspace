// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_statistic.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverStatistic extends DriverStatistic {
  @override
  final String id;
  @override
  final String driverId;
  @override
  final JsonObject? period;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final num totalOrders;
  @override
  final num totalEarnings;
  @override
  final num completedOrders;
  @override
  final num cancelledOrders;
  @override
  final num? onlineHours;
  @override
  final num totalDispatchesReceived;
  @override
  final num dispatchesAccepted;
  @override
  final num dispatchesRejected;
  @override
  final num dispatchesExpired;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final JsonObject? driver;

  factory _$DriverStatistic([void Function(DriverStatisticBuilder)? updates]) =>
      (DriverStatisticBuilder()..update(updates))._build();

  _$DriverStatistic._({
    required this.id,
    required this.driverId,
    this.period,
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalEarnings,
    required this.completedOrders,
    required this.cancelledOrders,
    this.onlineHours,
    required this.totalDispatchesReceived,
    required this.dispatchesAccepted,
    required this.dispatchesRejected,
    required this.dispatchesExpired,
    required this.createdAt,
    required this.updatedAt,
    this.driver,
  }) : super._();
  @override
  DriverStatistic rebuild(void Function(DriverStatisticBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DriverStatisticBuilder toBuilder() => DriverStatisticBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverStatistic &&
        id == other.id &&
        driverId == other.driverId &&
        period == other.period &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        totalOrders == other.totalOrders &&
        totalEarnings == other.totalEarnings &&
        completedOrders == other.completedOrders &&
        cancelledOrders == other.cancelledOrders &&
        onlineHours == other.onlineHours &&
        totalDispatchesReceived == other.totalDispatchesReceived &&
        dispatchesAccepted == other.dispatchesAccepted &&
        dispatchesRejected == other.dispatchesRejected &&
        dispatchesExpired == other.dispatchesExpired &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        driver == other.driver;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jc(_$hash, totalOrders.hashCode);
    _$hash = $jc(_$hash, totalEarnings.hashCode);
    _$hash = $jc(_$hash, completedOrders.hashCode);
    _$hash = $jc(_$hash, cancelledOrders.hashCode);
    _$hash = $jc(_$hash, onlineHours.hashCode);
    _$hash = $jc(_$hash, totalDispatchesReceived.hashCode);
    _$hash = $jc(_$hash, dispatchesAccepted.hashCode);
    _$hash = $jc(_$hash, dispatchesRejected.hashCode);
    _$hash = $jc(_$hash, dispatchesExpired.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, driver.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverStatistic')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('period', period)
          ..add('startDate', startDate)
          ..add('endDate', endDate)
          ..add('totalOrders', totalOrders)
          ..add('totalEarnings', totalEarnings)
          ..add('completedOrders', completedOrders)
          ..add('cancelledOrders', cancelledOrders)
          ..add('onlineHours', onlineHours)
          ..add('totalDispatchesReceived', totalDispatchesReceived)
          ..add('dispatchesAccepted', dispatchesAccepted)
          ..add('dispatchesRejected', dispatchesRejected)
          ..add('dispatchesExpired', dispatchesExpired)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('driver', driver))
        .toString();
  }
}

class DriverStatisticBuilder
    implements Builder<DriverStatistic, DriverStatisticBuilder> {
  _$DriverStatistic? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  JsonObject? _period;
  JsonObject? get period => _$this._period;
  set period(JsonObject? period) => _$this._period = period;

  DateTime? _startDate;
  DateTime? get startDate => _$this._startDate;
  set startDate(DateTime? startDate) => _$this._startDate = startDate;

  DateTime? _endDate;
  DateTime? get endDate => _$this._endDate;
  set endDate(DateTime? endDate) => _$this._endDate = endDate;

  num? _totalOrders;
  num? get totalOrders => _$this._totalOrders;
  set totalOrders(num? totalOrders) => _$this._totalOrders = totalOrders;

  num? _totalEarnings;
  num? get totalEarnings => _$this._totalEarnings;
  set totalEarnings(num? totalEarnings) =>
      _$this._totalEarnings = totalEarnings;

  num? _completedOrders;
  num? get completedOrders => _$this._completedOrders;
  set completedOrders(num? completedOrders) =>
      _$this._completedOrders = completedOrders;

  num? _cancelledOrders;
  num? get cancelledOrders => _$this._cancelledOrders;
  set cancelledOrders(num? cancelledOrders) =>
      _$this._cancelledOrders = cancelledOrders;

  num? _onlineHours;
  num? get onlineHours => _$this._onlineHours;
  set onlineHours(num? onlineHours) => _$this._onlineHours = onlineHours;

  num? _totalDispatchesReceived;
  num? get totalDispatchesReceived => _$this._totalDispatchesReceived;
  set totalDispatchesReceived(num? totalDispatchesReceived) =>
      _$this._totalDispatchesReceived = totalDispatchesReceived;

  num? _dispatchesAccepted;
  num? get dispatchesAccepted => _$this._dispatchesAccepted;
  set dispatchesAccepted(num? dispatchesAccepted) =>
      _$this._dispatchesAccepted = dispatchesAccepted;

  num? _dispatchesRejected;
  num? get dispatchesRejected => _$this._dispatchesRejected;
  set dispatchesRejected(num? dispatchesRejected) =>
      _$this._dispatchesRejected = dispatchesRejected;

  num? _dispatchesExpired;
  num? get dispatchesExpired => _$this._dispatchesExpired;
  set dispatchesExpired(num? dispatchesExpired) =>
      _$this._dispatchesExpired = dispatchesExpired;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  JsonObject? _driver;
  JsonObject? get driver => _$this._driver;
  set driver(JsonObject? driver) => _$this._driver = driver;

  DriverStatisticBuilder() {
    DriverStatistic._defaults(this);
  }

  DriverStatisticBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverId = $v.driverId;
      _period = $v.period;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _totalOrders = $v.totalOrders;
      _totalEarnings = $v.totalEarnings;
      _completedOrders = $v.completedOrders;
      _cancelledOrders = $v.cancelledOrders;
      _onlineHours = $v.onlineHours;
      _totalDispatchesReceived = $v.totalDispatchesReceived;
      _dispatchesAccepted = $v.dispatchesAccepted;
      _dispatchesRejected = $v.dispatchesRejected;
      _dispatchesExpired = $v.dispatchesExpired;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _driver = $v.driver;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverStatistic other) {
    _$v = other as _$DriverStatistic;
  }

  @override
  void update(void Function(DriverStatisticBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverStatistic build() => _build();

  _$DriverStatistic _build() {
    final _$result =
        _$v ??
        _$DriverStatistic._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'DriverStatistic',
            'id',
          ),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'DriverStatistic',
            'driverId',
          ),
          period: period,
          startDate: BuiltValueNullFieldError.checkNotNull(
            startDate,
            r'DriverStatistic',
            'startDate',
          ),
          endDate: BuiltValueNullFieldError.checkNotNull(
            endDate,
            r'DriverStatistic',
            'endDate',
          ),
          totalOrders: BuiltValueNullFieldError.checkNotNull(
            totalOrders,
            r'DriverStatistic',
            'totalOrders',
          ),
          totalEarnings: BuiltValueNullFieldError.checkNotNull(
            totalEarnings,
            r'DriverStatistic',
            'totalEarnings',
          ),
          completedOrders: BuiltValueNullFieldError.checkNotNull(
            completedOrders,
            r'DriverStatistic',
            'completedOrders',
          ),
          cancelledOrders: BuiltValueNullFieldError.checkNotNull(
            cancelledOrders,
            r'DriverStatistic',
            'cancelledOrders',
          ),
          onlineHours: onlineHours,
          totalDispatchesReceived: BuiltValueNullFieldError.checkNotNull(
            totalDispatchesReceived,
            r'DriverStatistic',
            'totalDispatchesReceived',
          ),
          dispatchesAccepted: BuiltValueNullFieldError.checkNotNull(
            dispatchesAccepted,
            r'DriverStatistic',
            'dispatchesAccepted',
          ),
          dispatchesRejected: BuiltValueNullFieldError.checkNotNull(
            dispatchesRejected,
            r'DriverStatistic',
            'dispatchesRejected',
          ),
          dispatchesExpired: BuiltValueNullFieldError.checkNotNull(
            dispatchesExpired,
            r'DriverStatistic',
            'dispatchesExpired',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'DriverStatistic',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'DriverStatistic',
            'updatedAt',
          ),
          driver: driver,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
