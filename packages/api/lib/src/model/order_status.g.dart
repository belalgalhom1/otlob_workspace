// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OrderStatus _$PENDING = const OrderStatus._('PENDING');
const OrderStatus _$CHANGES_REQUESTED = const OrderStatus._(
  'CHANGES_REQUESTED',
);
const OrderStatus _$ACCEPTED = const OrderStatus._('ACCEPTED');
const OrderStatus _$PREPARING = const OrderStatus._('PREPARING');
const OrderStatus _$LOOKING_FOR_DRIVER = const OrderStatus._(
  'LOOKING_FOR_DRIVER',
);
const OrderStatus _$DRIVER_ASSIGNED = const OrderStatus._('DRIVER_ASSIGNED');
const OrderStatus _$PENDING_PAYMENT = const OrderStatus._('PENDING_PAYMENT');
const OrderStatus _$READY_FOR_PICKUP = const OrderStatus._('READY_FOR_PICKUP');
const OrderStatus _$PARTIALLY_PICKED_UP = const OrderStatus._(
  'PARTIALLY_PICKED_UP',
);
const OrderStatus _$PICKED_UP = const OrderStatus._('PICKED_UP');
const OrderStatus _$DELIVERED = const OrderStatus._('DELIVERED');
const OrderStatus _$CANCELLED = const OrderStatus._('CANCELLED');

OrderStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'CHANGES_REQUESTED':
      return _$CHANGES_REQUESTED;
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'PREPARING':
      return _$PREPARING;
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

final BuiltSet<OrderStatus> _$values =
    BuiltSet<OrderStatus>(const <OrderStatus>[
      _$PENDING,
      _$CHANGES_REQUESTED,
      _$ACCEPTED,
      _$PREPARING,
      _$LOOKING_FOR_DRIVER,
      _$DRIVER_ASSIGNED,
      _$PENDING_PAYMENT,
      _$READY_FOR_PICKUP,
      _$PARTIALLY_PICKED_UP,
      _$PICKED_UP,
      _$DELIVERED,
      _$CANCELLED,
    ]);

class _$OrderStatusMeta {
  const _$OrderStatusMeta();
  OrderStatus get PENDING => _$PENDING;
  OrderStatus get CHANGES_REQUESTED => _$CHANGES_REQUESTED;
  OrderStatus get ACCEPTED => _$ACCEPTED;
  OrderStatus get PREPARING => _$PREPARING;
  OrderStatus get LOOKING_FOR_DRIVER => _$LOOKING_FOR_DRIVER;
  OrderStatus get DRIVER_ASSIGNED => _$DRIVER_ASSIGNED;
  OrderStatus get PENDING_PAYMENT => _$PENDING_PAYMENT;
  OrderStatus get READY_FOR_PICKUP => _$READY_FOR_PICKUP;
  OrderStatus get PARTIALLY_PICKED_UP => _$PARTIALLY_PICKED_UP;
  OrderStatus get PICKED_UP => _$PICKED_UP;
  OrderStatus get DELIVERED => _$DELIVERED;
  OrderStatus get CANCELLED => _$CANCELLED;
  OrderStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<OrderStatus> get values => _$values;
}

mixin _$OrderStatusMixin {
  // ignore: non_constant_identifier_names
  _$OrderStatusMeta get OrderStatus => const _$OrderStatusMeta();
}

Serializer<OrderStatus> _$orderStatusSerializer = _$OrderStatusSerializer();

class _$OrderStatusSerializer implements PrimitiveSerializer<OrderStatus> {
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
  final Iterable<Type> types = const <Type>[OrderStatus];
  @override
  final String wireName = 'OrderStatus';

  @override
  Object serialize(
    Serializers serializers,
    OrderStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  OrderStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => OrderStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
