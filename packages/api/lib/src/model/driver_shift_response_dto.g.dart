// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_shift_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverShiftResponseDto extends DriverShiftResponseDto {
  @override
  final String id;
  @override
  final String driverId;
  @override
  final String? shiftPoolId;
  @override
  final String? zoneId;
  @override
  final DateTime shiftDate;
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  final DateTime? actualStart;
  @override
  final DateTime? actualEnd;
  @override
  final String? startPhotoUrl;
  @override
  final DriverShiftStatus status;
  @override
  final num? breakMinutes;
  @override
  final num? totalEarnings;
  @override
  final num? totalDeliveries;
  @override
  final num expiredDispatches;
  @override
  final num rejectedDispatches;
  @override
  final bool warningSent;
  @override
  final bool isExcused;
  @override
  final String? excuseReason;
  @override
  final String? excusedByUserId;
  @override
  final DateTime? excusedAt;
  @override
  final DateTime createdAt;
  @override
  final Driver? driver;
  @override
  final ShiftPool? shiftPool;
  @override
  final Zone? zone;
  @override
  final BuiltList<DriverWalletTransaction>? walletTransactions;
  @override
  final BuiltList<OrderDispatch>? dispatches;
  @override
  final BuiltList<Order>? orders;
  @override
  final BuiltList<ShiftSwapRequest>? swapRequests;
  @override
  final BuiltList<DriverBreak>? breaks;

  factory _$DriverShiftResponseDto([
    void Function(DriverShiftResponseDtoBuilder)? updates,
  ]) => (DriverShiftResponseDtoBuilder()..update(updates))._build();

  _$DriverShiftResponseDto._({
    required this.id,
    required this.driverId,
    this.shiftPoolId,
    this.zoneId,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.actualStart,
    this.actualEnd,
    this.startPhotoUrl,
    required this.status,
    this.breakMinutes,
    this.totalEarnings,
    this.totalDeliveries,
    required this.expiredDispatches,
    required this.rejectedDispatches,
    required this.warningSent,
    required this.isExcused,
    this.excuseReason,
    this.excusedByUserId,
    this.excusedAt,
    required this.createdAt,
    this.driver,
    this.shiftPool,
    this.zone,
    this.walletTransactions,
    this.dispatches,
    this.orders,
    this.swapRequests,
    this.breaks,
  }) : super._();
  @override
  DriverShiftResponseDto rebuild(
    void Function(DriverShiftResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverShiftResponseDtoBuilder toBuilder() =>
      DriverShiftResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverShiftResponseDto &&
        id == other.id &&
        driverId == other.driverId &&
        shiftPoolId == other.shiftPoolId &&
        zoneId == other.zoneId &&
        shiftDate == other.shiftDate &&
        startTime == other.startTime &&
        endTime == other.endTime &&
        actualStart == other.actualStart &&
        actualEnd == other.actualEnd &&
        startPhotoUrl == other.startPhotoUrl &&
        status == other.status &&
        breakMinutes == other.breakMinutes &&
        totalEarnings == other.totalEarnings &&
        totalDeliveries == other.totalDeliveries &&
        expiredDispatches == other.expiredDispatches &&
        rejectedDispatches == other.rejectedDispatches &&
        warningSent == other.warningSent &&
        isExcused == other.isExcused &&
        excuseReason == other.excuseReason &&
        excusedByUserId == other.excusedByUserId &&
        excusedAt == other.excusedAt &&
        createdAt == other.createdAt &&
        driver == other.driver &&
        shiftPool == other.shiftPool &&
        zone == other.zone &&
        walletTransactions == other.walletTransactions &&
        dispatches == other.dispatches &&
        orders == other.orders &&
        swapRequests == other.swapRequests &&
        breaks == other.breaks;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, shiftPoolId.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jc(_$hash, shiftDate.hashCode);
    _$hash = $jc(_$hash, startTime.hashCode);
    _$hash = $jc(_$hash, endTime.hashCode);
    _$hash = $jc(_$hash, actualStart.hashCode);
    _$hash = $jc(_$hash, actualEnd.hashCode);
    _$hash = $jc(_$hash, startPhotoUrl.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, breakMinutes.hashCode);
    _$hash = $jc(_$hash, totalEarnings.hashCode);
    _$hash = $jc(_$hash, totalDeliveries.hashCode);
    _$hash = $jc(_$hash, expiredDispatches.hashCode);
    _$hash = $jc(_$hash, rejectedDispatches.hashCode);
    _$hash = $jc(_$hash, warningSent.hashCode);
    _$hash = $jc(_$hash, isExcused.hashCode);
    _$hash = $jc(_$hash, excuseReason.hashCode);
    _$hash = $jc(_$hash, excusedByUserId.hashCode);
    _$hash = $jc(_$hash, excusedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, driver.hashCode);
    _$hash = $jc(_$hash, shiftPool.hashCode);
    _$hash = $jc(_$hash, zone.hashCode);
    _$hash = $jc(_$hash, walletTransactions.hashCode);
    _$hash = $jc(_$hash, dispatches.hashCode);
    _$hash = $jc(_$hash, orders.hashCode);
    _$hash = $jc(_$hash, swapRequests.hashCode);
    _$hash = $jc(_$hash, breaks.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverShiftResponseDto')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('shiftPoolId', shiftPoolId)
          ..add('zoneId', zoneId)
          ..add('shiftDate', shiftDate)
          ..add('startTime', startTime)
          ..add('endTime', endTime)
          ..add('actualStart', actualStart)
          ..add('actualEnd', actualEnd)
          ..add('startPhotoUrl', startPhotoUrl)
          ..add('status', status)
          ..add('breakMinutes', breakMinutes)
          ..add('totalEarnings', totalEarnings)
          ..add('totalDeliveries', totalDeliveries)
          ..add('expiredDispatches', expiredDispatches)
          ..add('rejectedDispatches', rejectedDispatches)
          ..add('warningSent', warningSent)
          ..add('isExcused', isExcused)
          ..add('excuseReason', excuseReason)
          ..add('excusedByUserId', excusedByUserId)
          ..add('excusedAt', excusedAt)
          ..add('createdAt', createdAt)
          ..add('driver', driver)
          ..add('shiftPool', shiftPool)
          ..add('zone', zone)
          ..add('walletTransactions', walletTransactions)
          ..add('dispatches', dispatches)
          ..add('orders', orders)
          ..add('swapRequests', swapRequests)
          ..add('breaks', breaks))
        .toString();
  }
}

class DriverShiftResponseDtoBuilder
    implements Builder<DriverShiftResponseDto, DriverShiftResponseDtoBuilder> {
  _$DriverShiftResponseDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _shiftPoolId;
  String? get shiftPoolId => _$this._shiftPoolId;
  set shiftPoolId(String? shiftPoolId) => _$this._shiftPoolId = shiftPoolId;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  DateTime? _shiftDate;
  DateTime? get shiftDate => _$this._shiftDate;
  set shiftDate(DateTime? shiftDate) => _$this._shiftDate = shiftDate;

  DateTime? _startTime;
  DateTime? get startTime => _$this._startTime;
  set startTime(DateTime? startTime) => _$this._startTime = startTime;

  DateTime? _endTime;
  DateTime? get endTime => _$this._endTime;
  set endTime(DateTime? endTime) => _$this._endTime = endTime;

  DateTime? _actualStart;
  DateTime? get actualStart => _$this._actualStart;
  set actualStart(DateTime? actualStart) => _$this._actualStart = actualStart;

  DateTime? _actualEnd;
  DateTime? get actualEnd => _$this._actualEnd;
  set actualEnd(DateTime? actualEnd) => _$this._actualEnd = actualEnd;

  String? _startPhotoUrl;
  String? get startPhotoUrl => _$this._startPhotoUrl;
  set startPhotoUrl(String? startPhotoUrl) =>
      _$this._startPhotoUrl = startPhotoUrl;

  DriverShiftStatus? _status;
  DriverShiftStatus? get status => _$this._status;
  set status(DriverShiftStatus? status) => _$this._status = status;

  num? _breakMinutes;
  num? get breakMinutes => _$this._breakMinutes;
  set breakMinutes(num? breakMinutes) => _$this._breakMinutes = breakMinutes;

  num? _totalEarnings;
  num? get totalEarnings => _$this._totalEarnings;
  set totalEarnings(num? totalEarnings) =>
      _$this._totalEarnings = totalEarnings;

  num? _totalDeliveries;
  num? get totalDeliveries => _$this._totalDeliveries;
  set totalDeliveries(num? totalDeliveries) =>
      _$this._totalDeliveries = totalDeliveries;

  num? _expiredDispatches;
  num? get expiredDispatches => _$this._expiredDispatches;
  set expiredDispatches(num? expiredDispatches) =>
      _$this._expiredDispatches = expiredDispatches;

  num? _rejectedDispatches;
  num? get rejectedDispatches => _$this._rejectedDispatches;
  set rejectedDispatches(num? rejectedDispatches) =>
      _$this._rejectedDispatches = rejectedDispatches;

  bool? _warningSent;
  bool? get warningSent => _$this._warningSent;
  set warningSent(bool? warningSent) => _$this._warningSent = warningSent;

  bool? _isExcused;
  bool? get isExcused => _$this._isExcused;
  set isExcused(bool? isExcused) => _$this._isExcused = isExcused;

  String? _excuseReason;
  String? get excuseReason => _$this._excuseReason;
  set excuseReason(String? excuseReason) => _$this._excuseReason = excuseReason;

  String? _excusedByUserId;
  String? get excusedByUserId => _$this._excusedByUserId;
  set excusedByUserId(String? excusedByUserId) =>
      _$this._excusedByUserId = excusedByUserId;

  DateTime? _excusedAt;
  DateTime? get excusedAt => _$this._excusedAt;
  set excusedAt(DateTime? excusedAt) => _$this._excusedAt = excusedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DriverBuilder? _driver;
  DriverBuilder get driver => _$this._driver ??= DriverBuilder();
  set driver(DriverBuilder? driver) => _$this._driver = driver;

  ShiftPoolBuilder? _shiftPool;
  ShiftPoolBuilder get shiftPool => _$this._shiftPool ??= ShiftPoolBuilder();
  set shiftPool(ShiftPoolBuilder? shiftPool) => _$this._shiftPool = shiftPool;

  ZoneBuilder? _zone;
  ZoneBuilder get zone => _$this._zone ??= ZoneBuilder();
  set zone(ZoneBuilder? zone) => _$this._zone = zone;

  ListBuilder<DriverWalletTransaction>? _walletTransactions;
  ListBuilder<DriverWalletTransaction> get walletTransactions =>
      _$this._walletTransactions ??= ListBuilder<DriverWalletTransaction>();
  set walletTransactions(
    ListBuilder<DriverWalletTransaction>? walletTransactions,
  ) => _$this._walletTransactions = walletTransactions;

  ListBuilder<OrderDispatch>? _dispatches;
  ListBuilder<OrderDispatch> get dispatches =>
      _$this._dispatches ??= ListBuilder<OrderDispatch>();
  set dispatches(ListBuilder<OrderDispatch>? dispatches) =>
      _$this._dispatches = dispatches;

  ListBuilder<Order>? _orders;
  ListBuilder<Order> get orders => _$this._orders ??= ListBuilder<Order>();
  set orders(ListBuilder<Order>? orders) => _$this._orders = orders;

  ListBuilder<ShiftSwapRequest>? _swapRequests;
  ListBuilder<ShiftSwapRequest> get swapRequests =>
      _$this._swapRequests ??= ListBuilder<ShiftSwapRequest>();
  set swapRequests(ListBuilder<ShiftSwapRequest>? swapRequests) =>
      _$this._swapRequests = swapRequests;

  ListBuilder<DriverBreak>? _breaks;
  ListBuilder<DriverBreak> get breaks =>
      _$this._breaks ??= ListBuilder<DriverBreak>();
  set breaks(ListBuilder<DriverBreak>? breaks) => _$this._breaks = breaks;

  DriverShiftResponseDtoBuilder() {
    DriverShiftResponseDto._defaults(this);
  }

  DriverShiftResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverId = $v.driverId;
      _shiftPoolId = $v.shiftPoolId;
      _zoneId = $v.zoneId;
      _shiftDate = $v.shiftDate;
      _startTime = $v.startTime;
      _endTime = $v.endTime;
      _actualStart = $v.actualStart;
      _actualEnd = $v.actualEnd;
      _startPhotoUrl = $v.startPhotoUrl;
      _status = $v.status;
      _breakMinutes = $v.breakMinutes;
      _totalEarnings = $v.totalEarnings;
      _totalDeliveries = $v.totalDeliveries;
      _expiredDispatches = $v.expiredDispatches;
      _rejectedDispatches = $v.rejectedDispatches;
      _warningSent = $v.warningSent;
      _isExcused = $v.isExcused;
      _excuseReason = $v.excuseReason;
      _excusedByUserId = $v.excusedByUserId;
      _excusedAt = $v.excusedAt;
      _createdAt = $v.createdAt;
      _driver = $v.driver?.toBuilder();
      _shiftPool = $v.shiftPool?.toBuilder();
      _zone = $v.zone?.toBuilder();
      _walletTransactions = $v.walletTransactions?.toBuilder();
      _dispatches = $v.dispatches?.toBuilder();
      _orders = $v.orders?.toBuilder();
      _swapRequests = $v.swapRequests?.toBuilder();
      _breaks = $v.breaks?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverShiftResponseDto other) {
    _$v = other as _$DriverShiftResponseDto;
  }

  @override
  void update(void Function(DriverShiftResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverShiftResponseDto build() => _build();

  _$DriverShiftResponseDto _build() {
    _$DriverShiftResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverShiftResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'DriverShiftResponseDto',
              'id',
            ),
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'DriverShiftResponseDto',
              'driverId',
            ),
            shiftPoolId: shiftPoolId,
            zoneId: zoneId,
            shiftDate: BuiltValueNullFieldError.checkNotNull(
              shiftDate,
              r'DriverShiftResponseDto',
              'shiftDate',
            ),
            startTime: BuiltValueNullFieldError.checkNotNull(
              startTime,
              r'DriverShiftResponseDto',
              'startTime',
            ),
            endTime: BuiltValueNullFieldError.checkNotNull(
              endTime,
              r'DriverShiftResponseDto',
              'endTime',
            ),
            actualStart: actualStart,
            actualEnd: actualEnd,
            startPhotoUrl: startPhotoUrl,
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'DriverShiftResponseDto',
              'status',
            ),
            breakMinutes: breakMinutes,
            totalEarnings: totalEarnings,
            totalDeliveries: totalDeliveries,
            expiredDispatches: BuiltValueNullFieldError.checkNotNull(
              expiredDispatches,
              r'DriverShiftResponseDto',
              'expiredDispatches',
            ),
            rejectedDispatches: BuiltValueNullFieldError.checkNotNull(
              rejectedDispatches,
              r'DriverShiftResponseDto',
              'rejectedDispatches',
            ),
            warningSent: BuiltValueNullFieldError.checkNotNull(
              warningSent,
              r'DriverShiftResponseDto',
              'warningSent',
            ),
            isExcused: BuiltValueNullFieldError.checkNotNull(
              isExcused,
              r'DriverShiftResponseDto',
              'isExcused',
            ),
            excuseReason: excuseReason,
            excusedByUserId: excusedByUserId,
            excusedAt: excusedAt,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'DriverShiftResponseDto',
              'createdAt',
            ),
            driver: _driver?.build(),
            shiftPool: _shiftPool?.build(),
            zone: _zone?.build(),
            walletTransactions: _walletTransactions?.build(),
            dispatches: _dispatches?.build(),
            orders: _orders?.build(),
            swapRequests: _swapRequests?.build(),
            breaks: _breaks?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'driver';
        _driver?.build();
        _$failedField = 'shiftPool';
        _shiftPool?.build();
        _$failedField = 'zone';
        _zone?.build();
        _$failedField = 'walletTransactions';
        _walletTransactions?.build();
        _$failedField = 'dispatches';
        _dispatches?.build();
        _$failedField = 'orders';
        _orders?.build();
        _$failedField = 'swapRequests';
        _swapRequests?.build();
        _$failedField = 'breaks';
        _breaks?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverShiftResponseDto',
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
