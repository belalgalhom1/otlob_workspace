// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_order_status_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateOrderStatusDtoStatusEnum _$updateOrderStatusDtoStatusEnum_PENDING =
    const UpdateOrderStatusDtoStatusEnum._('PENDING');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_CHANGES_REQUESTED =
    const UpdateOrderStatusDtoStatusEnum._('CHANGES_REQUESTED');
const UpdateOrderStatusDtoStatusEnum _$updateOrderStatusDtoStatusEnum_ACCEPTED =
    const UpdateOrderStatusDtoStatusEnum._('ACCEPTED');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_PREPARING =
    const UpdateOrderStatusDtoStatusEnum._('PREPARING');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_LOOKING_FOR_DRIVER =
    const UpdateOrderStatusDtoStatusEnum._('LOOKING_FOR_DRIVER');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_DRIVER_ASSIGNED =
    const UpdateOrderStatusDtoStatusEnum._('DRIVER_ASSIGNED');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_PENDING_PAYMENT =
    const UpdateOrderStatusDtoStatusEnum._('PENDING_PAYMENT');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_READY_FOR_PICKUP =
    const UpdateOrderStatusDtoStatusEnum._('READY_FOR_PICKUP');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_PARTIALLY_PICKED_UP =
    const UpdateOrderStatusDtoStatusEnum._('PARTIALLY_PICKED_UP');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_PICKED_UP =
    const UpdateOrderStatusDtoStatusEnum._('PICKED_UP');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_DELIVERED =
    const UpdateOrderStatusDtoStatusEnum._('DELIVERED');
const UpdateOrderStatusDtoStatusEnum
_$updateOrderStatusDtoStatusEnum_CANCELLED =
    const UpdateOrderStatusDtoStatusEnum._('CANCELLED');

UpdateOrderStatusDtoStatusEnum _$updateOrderStatusDtoStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'PENDING':
      return _$updateOrderStatusDtoStatusEnum_PENDING;
    case 'CHANGES_REQUESTED':
      return _$updateOrderStatusDtoStatusEnum_CHANGES_REQUESTED;
    case 'ACCEPTED':
      return _$updateOrderStatusDtoStatusEnum_ACCEPTED;
    case 'PREPARING':
      return _$updateOrderStatusDtoStatusEnum_PREPARING;
    case 'LOOKING_FOR_DRIVER':
      return _$updateOrderStatusDtoStatusEnum_LOOKING_FOR_DRIVER;
    case 'DRIVER_ASSIGNED':
      return _$updateOrderStatusDtoStatusEnum_DRIVER_ASSIGNED;
    case 'PENDING_PAYMENT':
      return _$updateOrderStatusDtoStatusEnum_PENDING_PAYMENT;
    case 'READY_FOR_PICKUP':
      return _$updateOrderStatusDtoStatusEnum_READY_FOR_PICKUP;
    case 'PARTIALLY_PICKED_UP':
      return _$updateOrderStatusDtoStatusEnum_PARTIALLY_PICKED_UP;
    case 'PICKED_UP':
      return _$updateOrderStatusDtoStatusEnum_PICKED_UP;
    case 'DELIVERED':
      return _$updateOrderStatusDtoStatusEnum_DELIVERED;
    case 'CANCELLED':
      return _$updateOrderStatusDtoStatusEnum_CANCELLED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateOrderStatusDtoStatusEnum>
_$updateOrderStatusDtoStatusEnumValues =
    BuiltSet<UpdateOrderStatusDtoStatusEnum>(
      const <UpdateOrderStatusDtoStatusEnum>[
        _$updateOrderStatusDtoStatusEnum_PENDING,
        _$updateOrderStatusDtoStatusEnum_CHANGES_REQUESTED,
        _$updateOrderStatusDtoStatusEnum_ACCEPTED,
        _$updateOrderStatusDtoStatusEnum_PREPARING,
        _$updateOrderStatusDtoStatusEnum_LOOKING_FOR_DRIVER,
        _$updateOrderStatusDtoStatusEnum_DRIVER_ASSIGNED,
        _$updateOrderStatusDtoStatusEnum_PENDING_PAYMENT,
        _$updateOrderStatusDtoStatusEnum_READY_FOR_PICKUP,
        _$updateOrderStatusDtoStatusEnum_PARTIALLY_PICKED_UP,
        _$updateOrderStatusDtoStatusEnum_PICKED_UP,
        _$updateOrderStatusDtoStatusEnum_DELIVERED,
        _$updateOrderStatusDtoStatusEnum_CANCELLED,
      ],
    );

Serializer<UpdateOrderStatusDtoStatusEnum>
_$updateOrderStatusDtoStatusEnumSerializer =
    _$UpdateOrderStatusDtoStatusEnumSerializer();

class _$UpdateOrderStatusDtoStatusEnumSerializer
    implements PrimitiveSerializer<UpdateOrderStatusDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'CHANGES_REQUESTED': 'CHANGES_REQUESTED',
    'ACCEPTED': 'ACCEPTED',
    'PREPARING': 'PREPARING',
    'LOOKING_FOR_DRIVER': 'LOOKING_FOR_DRIVER',
    'DRIVER_ASSIGNED': 'DRIVER_ASSIGNED',
    'PENDING_PAYMENT': 'PENDING_PAYMENT',
    'READY_FOR_PICKUP': 'READY_FOR_PICKUP',
    'PARTIALLY_PICKED_UP': 'PARTIALLY_PICKED_UP',
    'PICKED_UP': 'PICKED_UP',
    'DELIVERED': 'DELIVERED',
    'CANCELLED': 'CANCELLED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING': 'PENDING',
    'CHANGES_REQUESTED': 'CHANGES_REQUESTED',
    'ACCEPTED': 'ACCEPTED',
    'PREPARING': 'PREPARING',
    'LOOKING_FOR_DRIVER': 'LOOKING_FOR_DRIVER',
    'DRIVER_ASSIGNED': 'DRIVER_ASSIGNED',
    'PENDING_PAYMENT': 'PENDING_PAYMENT',
    'READY_FOR_PICKUP': 'READY_FOR_PICKUP',
    'PARTIALLY_PICKED_UP': 'PARTIALLY_PICKED_UP',
    'PICKED_UP': 'PICKED_UP',
    'DELIVERED': 'DELIVERED',
    'CANCELLED': 'CANCELLED',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateOrderStatusDtoStatusEnum];
  @override
  final String wireName = 'UpdateOrderStatusDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateOrderStatusDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateOrderStatusDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateOrderStatusDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateOrderStatusDto extends UpdateOrderStatusDto {
  @override
  final UpdateOrderStatusDtoStatusEnum status;
  @override
  final String? note;
  @override
  final num? estimatedPrepTime;
  @override
  final String? pickupImageUrl;
  @override
  final String? deliveryImageUrl;

  factory _$UpdateOrderStatusDto([
    void Function(UpdateOrderStatusDtoBuilder)? updates,
  ]) => (UpdateOrderStatusDtoBuilder()..update(updates))._build();

  _$UpdateOrderStatusDto._({
    required this.status,
    this.note,
    this.estimatedPrepTime,
    this.pickupImageUrl,
    this.deliveryImageUrl,
  }) : super._();
  @override
  UpdateOrderStatusDto rebuild(
    void Function(UpdateOrderStatusDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateOrderStatusDtoBuilder toBuilder() =>
      UpdateOrderStatusDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateOrderStatusDto &&
        status == other.status &&
        note == other.note &&
        estimatedPrepTime == other.estimatedPrepTime &&
        pickupImageUrl == other.pickupImageUrl &&
        deliveryImageUrl == other.deliveryImageUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, estimatedPrepTime.hashCode);
    _$hash = $jc(_$hash, pickupImageUrl.hashCode);
    _$hash = $jc(_$hash, deliveryImageUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateOrderStatusDto')
          ..add('status', status)
          ..add('note', note)
          ..add('estimatedPrepTime', estimatedPrepTime)
          ..add('pickupImageUrl', pickupImageUrl)
          ..add('deliveryImageUrl', deliveryImageUrl))
        .toString();
  }
}

class UpdateOrderStatusDtoBuilder
    implements Builder<UpdateOrderStatusDto, UpdateOrderStatusDtoBuilder> {
  _$UpdateOrderStatusDto? _$v;

  UpdateOrderStatusDtoStatusEnum? _status;
  UpdateOrderStatusDtoStatusEnum? get status => _$this._status;
  set status(UpdateOrderStatusDtoStatusEnum? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  num? _estimatedPrepTime;
  num? get estimatedPrepTime => _$this._estimatedPrepTime;
  set estimatedPrepTime(num? estimatedPrepTime) =>
      _$this._estimatedPrepTime = estimatedPrepTime;

  String? _pickupImageUrl;
  String? get pickupImageUrl => _$this._pickupImageUrl;
  set pickupImageUrl(String? pickupImageUrl) =>
      _$this._pickupImageUrl = pickupImageUrl;

  String? _deliveryImageUrl;
  String? get deliveryImageUrl => _$this._deliveryImageUrl;
  set deliveryImageUrl(String? deliveryImageUrl) =>
      _$this._deliveryImageUrl = deliveryImageUrl;

  UpdateOrderStatusDtoBuilder() {
    UpdateOrderStatusDto._defaults(this);
  }

  UpdateOrderStatusDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _note = $v.note;
      _estimatedPrepTime = $v.estimatedPrepTime;
      _pickupImageUrl = $v.pickupImageUrl;
      _deliveryImageUrl = $v.deliveryImageUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateOrderStatusDto other) {
    _$v = other as _$UpdateOrderStatusDto;
  }

  @override
  void update(void Function(UpdateOrderStatusDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateOrderStatusDto build() => _build();

  _$UpdateOrderStatusDto _build() {
    final _$result =
        _$v ??
        _$UpdateOrderStatusDto._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'UpdateOrderStatusDto',
            'status',
          ),
          note: note,
          estimatedPrepTime: estimatedPrepTime,
          pickupImageUrl: pickupImageUrl,
          deliveryImageUrl: deliveryImageUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
