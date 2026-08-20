// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_dispatch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderDispatch extends OrderDispatch {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final String driverId;
  @override
  final String? driverShiftId;
  @override
  final OrderType type;
  @override
  final DispatchStatus status;
  @override
  final num? distanceKm;
  @override
  final num? estimatedEarnings;
  @override
  final DateTime expiresAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$OrderDispatch([void Function(OrderDispatchBuilder)? updates]) =>
      (OrderDispatchBuilder()..update(updates))._build();

  _$OrderDispatch._({
    required this.id,
    required this.orderId,
    required this.driverId,
    this.driverShiftId,
    required this.type,
    required this.status,
    this.distanceKm,
    this.estimatedEarnings,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  OrderDispatch rebuild(void Function(OrderDispatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrderDispatchBuilder toBuilder() => OrderDispatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderDispatch &&
        id == other.id &&
        orderId == other.orderId &&
        driverId == other.driverId &&
        driverShiftId == other.driverShiftId &&
        type == other.type &&
        status == other.status &&
        distanceKm == other.distanceKm &&
        estimatedEarnings == other.estimatedEarnings &&
        expiresAt == other.expiresAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, driverShiftId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, distanceKm.hashCode);
    _$hash = $jc(_$hash, estimatedEarnings.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderDispatch')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('driverId', driverId)
          ..add('driverShiftId', driverShiftId)
          ..add('type', type)
          ..add('status', status)
          ..add('distanceKm', distanceKm)
          ..add('estimatedEarnings', estimatedEarnings)
          ..add('expiresAt', expiresAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class OrderDispatchBuilder
    implements Builder<OrderDispatch, OrderDispatchBuilder> {
  _$OrderDispatch? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _driverShiftId;
  String? get driverShiftId => _$this._driverShiftId;
  set driverShiftId(String? driverShiftId) =>
      _$this._driverShiftId = driverShiftId;

  OrderType? _type;
  OrderType? get type => _$this._type;
  set type(OrderType? type) => _$this._type = type;

  DispatchStatus? _status;
  DispatchStatus? get status => _$this._status;
  set status(DispatchStatus? status) => _$this._status = status;

  num? _distanceKm;
  num? get distanceKm => _$this._distanceKm;
  set distanceKm(num? distanceKm) => _$this._distanceKm = distanceKm;

  num? _estimatedEarnings;
  num? get estimatedEarnings => _$this._estimatedEarnings;
  set estimatedEarnings(num? estimatedEarnings) =>
      _$this._estimatedEarnings = estimatedEarnings;

  DateTime? _expiresAt;
  DateTime? get expiresAt => _$this._expiresAt;
  set expiresAt(DateTime? expiresAt) => _$this._expiresAt = expiresAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  OrderDispatchBuilder() {
    OrderDispatch._defaults(this);
  }

  OrderDispatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _driverId = $v.driverId;
      _driverShiftId = $v.driverShiftId;
      _type = $v.type;
      _status = $v.status;
      _distanceKm = $v.distanceKm;
      _estimatedEarnings = $v.estimatedEarnings;
      _expiresAt = $v.expiresAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderDispatch other) {
    _$v = other as _$OrderDispatch;
  }

  @override
  void update(void Function(OrderDispatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderDispatch build() => _build();

  _$OrderDispatch _build() {
    final _$result =
        _$v ??
        _$OrderDispatch._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'OrderDispatch', 'id'),
          orderId: BuiltValueNullFieldError.checkNotNull(
            orderId,
            r'OrderDispatch',
            'orderId',
          ),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'OrderDispatch',
            'driverId',
          ),
          driverShiftId: driverShiftId,
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'OrderDispatch',
            'type',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'OrderDispatch',
            'status',
          ),
          distanceKm: distanceKm,
          estimatedEarnings: estimatedEarnings,
          expiresAt: BuiltValueNullFieldError.checkNotNull(
            expiresAt,
            r'OrderDispatch',
            'expiresAt',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'OrderDispatch',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'OrderDispatch',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
