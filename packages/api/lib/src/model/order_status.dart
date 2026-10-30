//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_status.g.dart';

class OrderStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING')
  static const OrderStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'CHANGES_REQUESTED')
  static const OrderStatus CHANGES_REQUESTED = _$CHANGES_REQUESTED;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const OrderStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'PREPARING')
  static const OrderStatus PREPARING = _$PREPARING;
  @BuiltValueEnumConst(wireName: r'LOOKING_FOR_DRIVER')
  static const OrderStatus LOOKING_FOR_DRIVER = _$LOOKING_FOR_DRIVER;
  @BuiltValueEnumConst(wireName: r'DRIVER_ASSIGNED')
  static const OrderStatus DRIVER_ASSIGNED = _$DRIVER_ASSIGNED;
  @BuiltValueEnumConst(wireName: r'PENDING_PAYMENT')
  static const OrderStatus PENDING_PAYMENT = _$PENDING_PAYMENT;
  @BuiltValueEnumConst(wireName: r'READY_FOR_PICKUP')
  static const OrderStatus READY_FOR_PICKUP = _$READY_FOR_PICKUP;
  @BuiltValueEnumConst(wireName: r'PARTIALLY_PICKED_UP')
  static const OrderStatus PARTIALLY_PICKED_UP = _$PARTIALLY_PICKED_UP;
  @BuiltValueEnumConst(wireName: r'PICKED_UP')
  static const OrderStatus PICKED_UP = _$PICKED_UP;
  @BuiltValueEnumConst(wireName: r'DELIVERED')
  static const OrderStatus DELIVERED = _$DELIVERED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const OrderStatus CANCELLED = _$CANCELLED;

  static Serializer<OrderStatus> get serializer => _$orderStatusSerializer;

  const OrderStatus._(String name): super(name);

  static BuiltSet<OrderStatus> get values => _$values;
  static OrderStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class OrderStatusMixin = Object with _$OrderStatusMixin;

