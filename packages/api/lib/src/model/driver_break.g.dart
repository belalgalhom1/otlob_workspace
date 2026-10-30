// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_break.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverBreak extends DriverBreak {
  @override
  final String id;
  @override
  final String driverId;
  @override
  final String? shiftId;
  @override
  final DriverBreakReason reason;
  @override
  final String? note;
  @override
  final num? requestedMinutes;
  @override
  final DriverBreakStatus status;
  @override
  final DriverStatus? prevStatus;
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  final num? durationMinutes;
  @override
  final bool autoEnded;
  @override
  final String? reviewedById;
  @override
  final DateTime? reviewedAt;
  @override
  final DateTime createdAt;

  factory _$DriverBreak([void Function(DriverBreakBuilder)? updates]) =>
      (DriverBreakBuilder()..update(updates))._build();

  _$DriverBreak._({
    required this.id,
    required this.driverId,
    this.shiftId,
    required this.reason,
    this.note,
    this.requestedMinutes,
    required this.status,
    this.prevStatus,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes,
    required this.autoEnded,
    this.reviewedById,
    this.reviewedAt,
    required this.createdAt,
  }) : super._();
  @override
  DriverBreak rebuild(void Function(DriverBreakBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DriverBreakBuilder toBuilder() => DriverBreakBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverBreak &&
        id == other.id &&
        driverId == other.driverId &&
        shiftId == other.shiftId &&
        reason == other.reason &&
        note == other.note &&
        requestedMinutes == other.requestedMinutes &&
        status == other.status &&
        prevStatus == other.prevStatus &&
        startedAt == other.startedAt &&
        endedAt == other.endedAt &&
        durationMinutes == other.durationMinutes &&
        autoEnded == other.autoEnded &&
        reviewedById == other.reviewedById &&
        reviewedAt == other.reviewedAt &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, shiftId.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, requestedMinutes.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, prevStatus.hashCode);
    _$hash = $jc(_$hash, startedAt.hashCode);
    _$hash = $jc(_$hash, endedAt.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, autoEnded.hashCode);
    _$hash = $jc(_$hash, reviewedById.hashCode);
    _$hash = $jc(_$hash, reviewedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverBreak')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('shiftId', shiftId)
          ..add('reason', reason)
          ..add('note', note)
          ..add('requestedMinutes', requestedMinutes)
          ..add('status', status)
          ..add('prevStatus', prevStatus)
          ..add('startedAt', startedAt)
          ..add('endedAt', endedAt)
          ..add('durationMinutes', durationMinutes)
          ..add('autoEnded', autoEnded)
          ..add('reviewedById', reviewedById)
          ..add('reviewedAt', reviewedAt)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class DriverBreakBuilder implements Builder<DriverBreak, DriverBreakBuilder> {
  _$DriverBreak? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _shiftId;
  String? get shiftId => _$this._shiftId;
  set shiftId(String? shiftId) => _$this._shiftId = shiftId;

  DriverBreakReason? _reason;
  DriverBreakReason? get reason => _$this._reason;
  set reason(DriverBreakReason? reason) => _$this._reason = reason;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  num? _requestedMinutes;
  num? get requestedMinutes => _$this._requestedMinutes;
  set requestedMinutes(num? requestedMinutes) =>
      _$this._requestedMinutes = requestedMinutes;

  DriverBreakStatus? _status;
  DriverBreakStatus? get status => _$this._status;
  set status(DriverBreakStatus? status) => _$this._status = status;

  DriverStatus? _prevStatus;
  DriverStatus? get prevStatus => _$this._prevStatus;
  set prevStatus(DriverStatus? prevStatus) => _$this._prevStatus = prevStatus;

  DateTime? _startedAt;
  DateTime? get startedAt => _$this._startedAt;
  set startedAt(DateTime? startedAt) => _$this._startedAt = startedAt;

  DateTime? _endedAt;
  DateTime? get endedAt => _$this._endedAt;
  set endedAt(DateTime? endedAt) => _$this._endedAt = endedAt;

  num? _durationMinutes;
  num? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(num? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  bool? _autoEnded;
  bool? get autoEnded => _$this._autoEnded;
  set autoEnded(bool? autoEnded) => _$this._autoEnded = autoEnded;

  String? _reviewedById;
  String? get reviewedById => _$this._reviewedById;
  set reviewedById(String? reviewedById) => _$this._reviewedById = reviewedById;

  DateTime? _reviewedAt;
  DateTime? get reviewedAt => _$this._reviewedAt;
  set reviewedAt(DateTime? reviewedAt) => _$this._reviewedAt = reviewedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DriverBreakBuilder() {
    DriverBreak._defaults(this);
  }

  DriverBreakBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverId = $v.driverId;
      _shiftId = $v.shiftId;
      _reason = $v.reason;
      _note = $v.note;
      _requestedMinutes = $v.requestedMinutes;
      _status = $v.status;
      _prevStatus = $v.prevStatus;
      _startedAt = $v.startedAt;
      _endedAt = $v.endedAt;
      _durationMinutes = $v.durationMinutes;
      _autoEnded = $v.autoEnded;
      _reviewedById = $v.reviewedById;
      _reviewedAt = $v.reviewedAt;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverBreak other) {
    _$v = other as _$DriverBreak;
  }

  @override
  void update(void Function(DriverBreakBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverBreak build() => _build();

  _$DriverBreak _build() {
    final _$result =
        _$v ??
        _$DriverBreak._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'DriverBreak', 'id'),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'DriverBreak',
            'driverId',
          ),
          shiftId: shiftId,
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'DriverBreak',
            'reason',
          ),
          note: note,
          requestedMinutes: requestedMinutes,
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'DriverBreak',
            'status',
          ),
          prevStatus: prevStatus,
          startedAt: BuiltValueNullFieldError.checkNotNull(
            startedAt,
            r'DriverBreak',
            'startedAt',
          ),
          endedAt: endedAt,
          durationMinutes: durationMinutes,
          autoEnded: BuiltValueNullFieldError.checkNotNull(
            autoEnded,
            r'DriverBreak',
            'autoEnded',
          ),
          reviewedById: reviewedById,
          reviewedAt: reviewedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'DriverBreak',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
