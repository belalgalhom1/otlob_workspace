//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_vendor_fulfillment_status.g.dart';

class OrderVendorFulfillmentStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING')
  static const OrderVendorFulfillmentStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const OrderVendorFulfillmentStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'PREPARING')
  static const OrderVendorFulfillmentStatus PREPARING = _$PREPARING;
  @BuiltValueEnumConst(wireName: r'READY_FOR_PICKUP')
  static const OrderVendorFulfillmentStatus READY_FOR_PICKUP = _$READY_FOR_PICKUP;
  @BuiltValueEnumConst(wireName: r'PICKED_UP')
  static const OrderVendorFulfillmentStatus PICKED_UP = _$PICKED_UP;
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const OrderVendorFulfillmentStatus REJECTED = _$REJECTED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const OrderVendorFulfillmentStatus CANCELLED = _$CANCELLED;

  static Serializer<OrderVendorFulfillmentStatus> get serializer => _$orderVendorFulfillmentStatusSerializer;

  const OrderVendorFulfillmentStatus._(String name): super(name);

  static BuiltSet<OrderVendorFulfillmentStatus> get values => _$values;
  static OrderVendorFulfillmentStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class OrderVendorFulfillmentStatusMixin = Object with _$OrderVendorFulfillmentStatusMixin;

