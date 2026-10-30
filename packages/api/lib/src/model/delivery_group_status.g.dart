// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_group_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeliveryGroupStatus _$PENDING = const DeliveryGroupStatus._('PENDING');
const DeliveryGroupStatus _$ACCEPTED = const DeliveryGroupStatus._('ACCEPTED');
const DeliveryGroupStatus _$LOOKING_FOR_DRIVER = const DeliveryGroupStatus._(
  'LOOKING_FOR_DRIVER',
);
const DeliveryGroupStatus _$DRIVER_ASSIGNED = const DeliveryGroupStatus._(
  'DRIVER_ASSIGNED',
);
const DeliveryGroupStatus _$PENDING_PAYMENT = const DeliveryGroupStatus._(
  'PENDING_PAYMENT',
);
const DeliveryGroupStatus _$READY_FOR_PICKUP = const DeliveryGroupStatus._(
  'READY_FOR_PICKUP',
);
const DeliveryGroupStatus _$PARTIALLY_PICKED_UP = const DeliveryGroupStatus._(
  'PARTIALLY_PICKED_UP',
);
const DeliveryGroupStatus _$PICKED_UP = const DeliveryGroupStatus._(
  'PICKED_UP',
);
const DeliveryGroupStatus _$DELIVERED = const DeliveryGroupStatus._(
  'DELIVERED',
);
const DeliveryGroupStatus _$CANCELLED = const DeliveryGroupStatus._(
  'CANCELLED',
);

DeliveryGroupStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'LOOKING_FOR_DRIVER':
      return _$LOOKING_FOR_DRIVER;
    case 'DRIVER_ASSIGNED':
      return _$DRIVER_ASSIGNED;
    case 'PENDING_PAYMENT':
      return _$PENDING_PAYMENT;
    case 'READY_FOR_PICKUP':
      return _$READY_FOR_PICKUP;
    case 'PARTIALLY_PICKED_UP':
      return _$PARTIALLY_PICKED_UP;
    case 'PICKED_UP':
      return _$PICKED_UP;
    case 'DELIVERED':
      return _$DELIVERED;
    case 'CANCELLED':
      return _$CANCELLED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DeliveryGroupStatus> _$values =
    BuiltSet<DeliveryGroupStatus>(const <DeliveryGroupStatus>[
      _$PENDING,
      _$ACCEPTED,
      _$LOOKING_FOR_DRIVER,
      _$DRIVER_ASSIGNED,
      _$PENDING_PAYMENT,
      _$READY_FOR_PICKUP,
      _$PARTIALLY_PICKED_UP,
      _$PICKED_UP,
      _$DELIVERED,
      _$CANCELLED,
    ]);

class _$DeliveryGroupStatusMeta {
  const _$DeliveryGroupStatusMeta();
  DeliveryGroupStatus get PENDING => _$PENDING;
  DeliveryGroupStatus get ACCEPTED => _$ACCEPTED;
  DeliveryGroupStatus get LOOKING_FOR_DRIVER => _$LOOKING_FOR_DRIVER;
  DeliveryGroupStatus get DRIVER_ASSIGNED => _$DRIVER_ASSIGNED;
  DeliveryGroupStatus get PENDING_PAYMENT => _$PENDING_PAYMENT;
  DeliveryGroupStatus get READY_FOR_PICKUP => _$READY_FOR_PICKUP;
  DeliveryGroupStatus get PARTIALLY_PICKED_UP => _$PARTIALLY_PICKED_UP;
  DeliveryGroupStatus get PICKED_UP => _$PICKED_UP;
  DeliveryGroupStatus get DELIVERED => _$DELIVERED;
  DeliveryGroupStatus get CANCELLED => _$CANCELLED;
  DeliveryGroupStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DeliveryGroupStatus> get values => _$values;
}

mixin _$DeliveryGroupStatusMixin {
  // ignore: non_constant_identifier_names
  _$DeliveryGroupStatusMeta get DeliveryGroupStatus =>
      const _$DeliveryGroupStatusMeta();
}

Serializer<DeliveryGroupStatus> _$deliveryGroupStatusSerializer =
    _$DeliveryGroupStatusSerializer();

class _$DeliveryGroupStatusSerializer
    implements PrimitiveSerializer<DeliveryGroupStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
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
    'ACCEPTED': 'ACCEPTED',
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
  final Iterable<Type> types = const <Type>[DeliveryGroupStatus];
  @override
  final String wireName = 'DeliveryGroupStatus';

  @override
  Object serialize(
    Serializers serializers,
    DeliveryGroupStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DeliveryGroupStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DeliveryGroupStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
