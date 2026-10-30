//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delivery_group_status.g.dart';

class DeliveryGroupStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING')
  static const DeliveryGroupStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const DeliveryGroupStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'LOOKING_FOR_DRIVER')
  static const DeliveryGroupStatus LOOKING_FOR_DRIVER = _$LOOKING_FOR_DRIVER;
  @BuiltValueEnumConst(wireName: r'DRIVER_ASSIGNED')
  static const DeliveryGroupStatus DRIVER_ASSIGNED = _$DRIVER_ASSIGNED;
  @BuiltValueEnumConst(wireName: r'PENDING_PAYMENT')
  static const DeliveryGroupStatus PENDING_PAYMENT = _$PENDING_PAYMENT;
  @BuiltValueEnumConst(wireName: r'READY_FOR_PICKUP')
  static const DeliveryGroupStatus READY_FOR_PICKUP = _$READY_FOR_PICKUP;
  @BuiltValueEnumConst(wireName: r'PARTIALLY_PICKED_UP')
  static const DeliveryGroupStatus PARTIALLY_PICKED_UP = _$PARTIALLY_PICKED_UP;
  @BuiltValueEnumConst(wireName: r'PICKED_UP')
  static const DeliveryGroupStatus PICKED_UP = _$PICKED_UP;
  @BuiltValueEnumConst(wireName: r'DELIVERED')
  static const DeliveryGroupStatus DELIVERED = _$DELIVERED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const DeliveryGroupStatus CANCELLED = _$CANCELLED;

  static Serializer<DeliveryGroupStatus> get serializer => _$deliveryGroupStatusSerializer;

  const DeliveryGroupStatus._(String name): super(name);

  static BuiltSet<DeliveryGroupStatus> get values => _$values;
  static DeliveryGroupStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DeliveryGroupStatusMixin = Object with _$DeliveryGroupStatusMixin;

