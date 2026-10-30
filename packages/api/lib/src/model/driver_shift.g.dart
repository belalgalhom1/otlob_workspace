// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_shift.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverShift extends DriverShift {
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
  final DateTime createdAt;

  factory _$DriverShift([void Function(DriverShiftBuilder)? updates]) =>
      (DriverShiftBuilder()..update(updates))._build();

  _$DriverShift._({
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
    required this.createdAt,
  }) : super._();
  @override
  DriverShift rebuild(void Function(DriverShiftBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DriverShiftBuilder toBuilder() => DriverShiftBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverShift &&
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
        createdAt == other.createdAt;
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
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverShift')
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
          ..add('createdAt', createdAt))
        .toString();
  }
}

class DriverShiftBuilder implements Builder<DriverShift, DriverShiftBuilder> {
  _$DriverShift? _$v;

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

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DriverShiftBuilder() {
    DriverShift._defaults(this);
  }

  DriverShiftBuilder get _$this {
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
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverShift other) {
    _$v = other as _$DriverShift;
  }

  @override
  void update(void Function(DriverShiftBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverShift build() => _build();

  _$DriverShift _build() {
    final _$result =
        _$v ??
        _$DriverShift._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'DriverShift', 'id'),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'DriverShift',
            'driverId',
          ),
          shiftPoolId: shiftPoolId,
          zoneId: zoneId,
          shiftDate: BuiltValueNullFieldError.checkNotNull(
            shiftDate,
            r'DriverShift',
            'shiftDate',
          ),
          startTime: BuiltValueNullFieldError.checkNotNull(
            startTime,
            r'DriverShift',
            'startTime',
          ),
          endTime: BuiltValueNullFieldError.checkNotNull(
            endTime,
            r'DriverShift',
            'endTime',
          ),
          actualStart: actualStart,
          actualEnd: actualEnd,
          startPhotoUrl: startPhotoUrl,
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'DriverShift',
            'status',
          ),
          breakMinutes: breakMinutes,
          totalEarnings: totalEarnings,
          totalDeliveries: totalDeliveries,
          expiredDispatches: BuiltValueNullFieldError.checkNotNull(
            expiredDispatches,
            r'DriverShift',
            'expiredDispatches',
          ),
          rejectedDispatches: BuiltValueNullFieldError.checkNotNull(
            rejectedDispatches,
            r'DriverShift',
            'rejectedDispatches',
          ),
          warningSent: BuiltValueNullFieldError.checkNotNull(
            warningSent,
            r'DriverShift',
            'warningSent',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'DriverShift',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
