// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_vendor_fulfillment_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OrderVendorFulfillmentStatus _$PENDING =
    const OrderVendorFulfillmentStatus._('PENDING');
const OrderVendorFulfillmentStatus _$ACCEPTED =
    const OrderVendorFulfillmentStatus._('ACCEPTED');
const OrderVendorFulfillmentStatus _$PREPARING =
    const OrderVendorFulfillmentStatus._('PREPARING');
const OrderVendorFulfillmentStatus _$READY_FOR_PICKUP =
    const OrderVendorFulfillmentStatus._('READY_FOR_PICKUP');
const OrderVendorFulfillmentStatus _$PICKED_UP =
    const OrderVendorFulfillmentStatus._('PICKED_UP');
const OrderVendorFulfillmentStatus _$REJECTED =
    const OrderVendorFulfillmentStatus._('REJECTED');
const OrderVendorFulfillmentStatus _$CANCELLED =
    const OrderVendorFulfillmentStatus._('CANCELLED');

OrderVendorFulfillmentStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'PREPARING':
      return _$PREPARING;
    case 'READY_FOR_PICKUP':
      return _$READY_FOR_PICKUP;
    case 'PICKED_UP':
      return _$PICKED_UP;
    case 'REJECTED':
      return _$REJECTED;
    case 'CANCELLED':
      return _$CANCELLED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OrderVendorFulfillmentStatus> _$values =
    BuiltSet<OrderVendorFulfillmentStatus>(const <OrderVendorFulfillmentStatus>[
      _$PENDING,
      _$ACCEPTED,
      _$PREPARING,
      _$READY_FOR_PICKUP,
      _$PICKED_UP,
      _$REJECTED,
      _$CANCELLED,
    ]);

class _$OrderVendorFulfillmentStatusMeta {
  const _$OrderVendorFulfillmentStatusMeta();
  OrderVendorFulfillmentStatus get PENDING => _$PENDING;
  OrderVendorFulfillmentStatus get ACCEPTED => _$ACCEPTED;
  OrderVendorFulfillmentStatus get PREPARING => _$PREPARING;
  OrderVendorFulfillmentStatus get READY_FOR_PICKUP => _$READY_FOR_PICKUP;
  OrderVendorFulfillmentStatus get PICKED_UP => _$PICKED_UP;
  OrderVendorFulfillmentStatus get REJECTED => _$REJECTED;
  OrderVendorFulfillmentStatus get CANCELLED => _$CANCELLED;
  OrderVendorFulfillmentStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<OrderVendorFulfillmentStatus> get values => _$values;
}

mixin _$OrderVendorFulfillmentStatusMixin {
  // ignore: non_constant_identifier_names
  _$OrderVendorFulfillmentStatusMeta get OrderVendorFulfillmentStatus =>
      const _$OrderVendorFulfillmentStatusMeta();
}

Serializer<OrderVendorFulfillmentStatus>
_$orderVendorFulfillmentStatusSerializer =
    _$OrderVendorFulfillmentStatusSerializer();

class _$OrderVendorFulfillmentStatusSerializer
    implements PrimitiveSerializer<OrderVendorFulfillmentStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'PREPARING': 'PREPARING',
    'READY_FOR_PICKUP': 'READY_FOR_PICKUP',
    'PICKED_UP': 'PICKED_UP',
    'REJECTED': 'REJECTED',
    'CANCELLED': 'CANCELLED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'PREPARING': 'PREPARING',
    'READY_FOR_PICKUP': 'READY_FOR_PICKUP',
    'PICKED_UP': 'PICKED_UP',
    'REJECTED': 'REJECTED',
    'CANCELLED': 'CANCELLED',
  };

  @override
  final Iterable<Type> types = const <Type>[OrderVendorFulfillmentStatus];
  @override
  final String wireName = 'OrderVendorFulfillmentStatus';

  @override
  Object serialize(
    Serializers serializers,
    OrderVendorFulfillmentStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  OrderVendorFulfillmentStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => OrderVendorFulfillmentStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
