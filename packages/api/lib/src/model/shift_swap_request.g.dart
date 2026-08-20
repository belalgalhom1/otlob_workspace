// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_swap_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ShiftSwapRequest extends ShiftSwapRequest {
  @override
  final String id;
  @override
  final String driverShiftId;
  @override
  final String offeredByDriverId;
  @override
  final JsonObject? status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final JsonObject? driverShift;

  factory _$ShiftSwapRequest([
    void Function(ShiftSwapRequestBuilder)? updates,
  ]) => (ShiftSwapRequestBuilder()..update(updates))._build();

  _$ShiftSwapRequest._({
    required this.id,
    required this.driverShiftId,
    required this.offeredByDriverId,
    this.status,
    required this.createdAt,
    required this.updatedAt,
    this.driverShift,
  }) : super._();
  @override
  ShiftSwapRequest rebuild(void Function(ShiftSwapRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShiftSwapRequestBuilder toBuilder() =>
      ShiftSwapRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShiftSwapRequest &&
        id == other.id &&
        driverShiftId == other.driverShiftId &&
        offeredByDriverId == other.offeredByDriverId &&
        status == other.status &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        driverShift == other.driverShift;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverShiftId.hashCode);
    _$hash = $jc(_$hash, offeredByDriverId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, driverShift.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShiftSwapRequest')
          ..add('id', id)
          ..add('driverShiftId', driverShiftId)
          ..add('offeredByDriverId', offeredByDriverId)
          ..add('status', status)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('driverShift', driverShift))
        .toString();
  }
}

class ShiftSwapRequestBuilder
    implements Builder<ShiftSwapRequest, ShiftSwapRequestBuilder> {
  _$ShiftSwapRequest? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverShiftId;
  String? get driverShiftId => _$this._driverShiftId;
  set driverShiftId(String? driverShiftId) =>
      _$this._driverShiftId = driverShiftId;

  String? _offeredByDriverId;
  String? get offeredByDriverId => _$this._offeredByDriverId;
  set offeredByDriverId(String? offeredByDriverId) =>
      _$this._offeredByDriverId = offeredByDriverId;

  JsonObject? _status;
  JsonObject? get status => _$this._status;
  set status(JsonObject? status) => _$this._status = status;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  JsonObject? _driverShift;
  JsonObject? get driverShift => _$this._driverShift;
  set driverShift(JsonObject? driverShift) => _$this._driverShift = driverShift;

  ShiftSwapRequestBuilder() {
    ShiftSwapRequest._defaults(this);
  }

  ShiftSwapRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverShiftId = $v.driverShiftId;
      _offeredByDriverId = $v.offeredByDriverId;
      _status = $v.status;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _driverShift = $v.driverShift;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShiftSwapRequest other) {
    _$v = other as _$ShiftSwapRequest;
  }

  @override
  void update(void Function(ShiftSwapRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShiftSwapRequest build() => _build();

  _$ShiftSwapRequest _build() {
    final _$result =
        _$v ??
        _$ShiftSwapRequest._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'ShiftSwapRequest',
            'id',
          ),
          driverShiftId: BuiltValueNullFieldError.checkNotNull(
            driverShiftId,
            r'ShiftSwapRequest',
            'driverShiftId',
          ),
          offeredByDriverId: BuiltValueNullFieldError.checkNotNull(
            offeredByDriverId,
            r'ShiftSwapRequest',
            'offeredByDriverId',
          ),
          status: status,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'ShiftSwapRequest',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'ShiftSwapRequest',
            'updatedAt',
          ),
          driverShift: driverShift,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
