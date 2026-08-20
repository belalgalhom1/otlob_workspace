// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OrderType _$STANDARD = const OrderType._('STANDARD');
const OrderType _$CUSTOM_DELIVERY = const OrderType._('CUSTOM_DELIVERY');
const OrderType _$RIDE = const OrderType._('RIDE');

OrderType _$valueOf(String name) {
  switch (name) {
    case 'STANDARD':
      return _$STANDARD;
    case 'CUSTOM_DELIVERY':
      return _$CUSTOM_DELIVERY;
    case 'RIDE':
      return _$RIDE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OrderType> _$values = BuiltSet<OrderType>(const <OrderType>[
  _$STANDARD,
  _$CUSTOM_DELIVERY,
  _$RIDE,
]);

class _$OrderTypeMeta {
  const _$OrderTypeMeta();
  OrderType get STANDARD => _$STANDARD;
  OrderType get CUSTOM_DELIVERY => _$CUSTOM_DELIVERY;
  OrderType get RIDE => _$RIDE;
  OrderType valueOf(String name) => _$valueOf(name);
  BuiltSet<OrderType> get values => _$values;
}

mixin _$OrderTypeMixin {
  // ignore: non_constant_identifier_names
  _$OrderTypeMeta get OrderType => const _$OrderTypeMeta();
}

Serializer<OrderType> _$orderTypeSerializer = _$OrderTypeSerializer();

class _$OrderTypeSerializer implements PrimitiveSerializer<OrderType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'STANDARD': 'STANDARD',
    'CUSTOM_DELIVERY': 'CUSTOM_DELIVERY',
    'RIDE': 'RIDE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'STANDARD': 'STANDARD',
    'CUSTOM_DELIVERY': 'CUSTOM_DELIVERY',
    'RIDE': 'RIDE',
  };

  @override
  final Iterable<Type> types = const <Type>[OrderType];
  @override
  final String wireName = 'OrderType';

  @override
  Object serialize(
    Serializers serializers,
    OrderType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  OrderType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => OrderType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
