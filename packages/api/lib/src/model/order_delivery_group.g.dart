// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_delivery_group.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderDeliveryGroup extends OrderDeliveryGroup {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final num sequence;
  @override
  final DeliveryGroupStatus status;
  @override
  final String? primaryDriverId;
  @override
  final String? assistDriverId;
  @override
  final num? distanceKm;
  @override
  final num deliveryFee;
  @override
  final String? pickupImageUrl;
  @override
  final String? deliveryImageUrl;
  @override
  final DateTime? pickedUpAt;
  @override
  final DateTime? deliveredAt;
  @override
  final Driver? primaryDriver;
  @override
  final Driver? assistDriver;

  factory _$OrderDeliveryGroup([
    void Function(OrderDeliveryGroupBuilder)? updates,
  ]) => (OrderDeliveryGroupBuilder()..update(updates))._build();

  _$OrderDeliveryGroup._({
    required this.id,
    required this.orderId,
    required this.sequence,
    required this.status,
    this.primaryDriverId,
    this.assistDriverId,
    this.distanceKm,
    required this.deliveryFee,
    this.pickupImageUrl,
    this.deliveryImageUrl,
    this.pickedUpAt,
    this.deliveredAt,
    this.primaryDriver,
    this.assistDriver,
  }) : super._();
  @override
  OrderDeliveryGroup rebuild(
    void Function(OrderDeliveryGroupBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderDeliveryGroupBuilder toBuilder() =>
      OrderDeliveryGroupBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderDeliveryGroup &&
        id == other.id &&
        orderId == other.orderId &&
        sequence == other.sequence &&
        status == other.status &&
        primaryDriverId == other.primaryDriverId &&
        assistDriverId == other.assistDriverId &&
        distanceKm == other.distanceKm &&
        deliveryFee == other.deliveryFee &&
        pickupImageUrl == other.pickupImageUrl &&
        deliveryImageUrl == other.deliveryImageUrl &&
        pickedUpAt == other.pickedUpAt &&
        deliveredAt == other.deliveredAt &&
        primaryDriver == other.primaryDriver &&
        assistDriver == other.assistDriver;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, sequence.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, primaryDriverId.hashCode);
    _$hash = $jc(_$hash, assistDriverId.hashCode);
    _$hash = $jc(_$hash, distanceKm.hashCode);
    _$hash = $jc(_$hash, deliveryFee.hashCode);
    _$hash = $jc(_$hash, pickupImageUrl.hashCode);
    _$hash = $jc(_$hash, deliveryImageUrl.hashCode);
    _$hash = $jc(_$hash, pickedUpAt.hashCode);
    _$hash = $jc(_$hash, deliveredAt.hashCode);
    _$hash = $jc(_$hash, primaryDriver.hashCode);
    _$hash = $jc(_$hash, assistDriver.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderDeliveryGroup')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('sequence', sequence)
          ..add('status', status)
          ..add('primaryDriverId', primaryDriverId)
          ..add('assistDriverId', assistDriverId)
          ..add('distanceKm', distanceKm)
          ..add('deliveryFee', deliveryFee)
          ..add('pickupImageUrl', pickupImageUrl)
          ..add('deliveryImageUrl', deliveryImageUrl)
          ..add('pickedUpAt', pickedUpAt)
          ..add('deliveredAt', deliveredAt)
          ..add('primaryDriver', primaryDriver)
          ..add('assistDriver', assistDriver))
        .toString();
  }
}

class OrderDeliveryGroupBuilder
    implements Builder<OrderDeliveryGroup, OrderDeliveryGroupBuilder> {
  _$OrderDeliveryGroup? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  num? _sequence;
  num? get sequence => _$this._sequence;
  set sequence(num? sequence) => _$this._sequence = sequence;

  DeliveryGroupStatus? _status;
  DeliveryGroupStatus? get status => _$this._status;
  set status(DeliveryGroupStatus? status) => _$this._status = status;

  String? _primaryDriverId;
  String? get primaryDriverId => _$this._primaryDriverId;
  set primaryDriverId(String? primaryDriverId) =>
      _$this._primaryDriverId = primaryDriverId;

  String? _assistDriverId;
  String? get assistDriverId => _$this._assistDriverId;
  set assistDriverId(String? assistDriverId) =>
      _$this._assistDriverId = assistDriverId;

  num? _distanceKm;
  num? get distanceKm => _$this._distanceKm;
  set distanceKm(num? distanceKm) => _$this._distanceKm = distanceKm;

  num? _deliveryFee;
  num? get deliveryFee => _$this._deliveryFee;
  set deliveryFee(num? deliveryFee) => _$this._deliveryFee = deliveryFee;

  String? _pickupImageUrl;
  String? get pickupImageUrl => _$this._pickupImageUrl;
  set pickupImageUrl(String? pickupImageUrl) =>
      _$this._pickupImageUrl = pickupImageUrl;

  String? _deliveryImageUrl;
  String? get deliveryImageUrl => _$this._deliveryImageUrl;
  set deliveryImageUrl(String? deliveryImageUrl) =>
      _$this._deliveryImageUrl = deliveryImageUrl;

  DateTime? _pickedUpAt;
  DateTime? get pickedUpAt => _$this._pickedUpAt;
  set pickedUpAt(DateTime? pickedUpAt) => _$this._pickedUpAt = pickedUpAt;

  DateTime? _deliveredAt;
  DateTime? get deliveredAt => _$this._deliveredAt;
  set deliveredAt(DateTime? deliveredAt) => _$this._deliveredAt = deliveredAt;

  DriverBuilder? _primaryDriver;
  DriverBuilder get primaryDriver => _$this._primaryDriver ??= DriverBuilder();
  set primaryDriver(DriverBuilder? primaryDriver) =>
      _$this._primaryDriver = primaryDriver;

  DriverBuilder? _assistDriver;
  DriverBuilder get assistDriver => _$this._assistDriver ??= DriverBuilder();
  set assistDriver(DriverBuilder? assistDriver) =>
      _$this._assistDriver = assistDriver;

  OrderDeliveryGroupBuilder() {
    OrderDeliveryGroup._defaults(this);
  }

  OrderDeliveryGroupBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _sequence = $v.sequence;
      _status = $v.status;
      _primaryDriverId = $v.primaryDriverId;
      _assistDriverId = $v.assistDriverId;
      _distanceKm = $v.distanceKm;
      _deliveryFee = $v.deliveryFee;
      _pickupImageUrl = $v.pickupImageUrl;
      _deliveryImageUrl = $v.deliveryImageUrl;
      _pickedUpAt = $v.pickedUpAt;
      _deliveredAt = $v.deliveredAt;
      _primaryDriver = $v.primaryDriver?.toBuilder();
      _assistDriver = $v.assistDriver?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderDeliveryGroup other) {
    _$v = other as _$OrderDeliveryGroup;
  }

  @override
  void update(void Function(OrderDeliveryGroupBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderDeliveryGroup build() => _build();

  _$OrderDeliveryGroup _build() {
    _$OrderDeliveryGroup _$result;
    try {
      _$result =
          _$v ??
          _$OrderDeliveryGroup._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'OrderDeliveryGroup',
              'id',
            ),
            orderId: BuiltValueNullFieldError.checkNotNull(
              orderId,
              r'OrderDeliveryGroup',
              'orderId',
            ),
            sequence: BuiltValueNullFieldError.checkNotNull(
              sequence,
              r'OrderDeliveryGroup',
              'sequence',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'OrderDeliveryGroup',
              'status',
            ),
            primaryDriverId: primaryDriverId,
            assistDriverId: assistDriverId,
            distanceKm: distanceKm,
            deliveryFee: BuiltValueNullFieldError.checkNotNull(
              deliveryFee,
              r'OrderDeliveryGroup',
              'deliveryFee',
            ),
            pickupImageUrl: pickupImageUrl,
            deliveryImageUrl: deliveryImageUrl,
            pickedUpAt: pickedUpAt,
            deliveredAt: deliveredAt,
            primaryDriver: _primaryDriver?.build(),
            assistDriver: _assistDriver?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'primaryDriver';
        _primaryDriver?.build();
        _$failedField = 'assistDriver';
        _assistDriver?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderDeliveryGroup',
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
