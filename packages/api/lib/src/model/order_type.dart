//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_type.g.dart';

class OrderType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'STANDARD')
  static const OrderType STANDARD = _$STANDARD;
  @BuiltValueEnumConst(wireName: r'CUSTOM_DELIVERY')
  static const OrderType CUSTOM_DELIVERY = _$CUSTOM_DELIVERY;
  @BuiltValueEnumConst(wireName: r'RIDE')
  static const OrderType RIDE = _$RIDE;

  static Serializer<OrderType> get serializer => _$orderTypeSerializer;

  const OrderType._(String name): super(name);

  static BuiltSet<OrderType> get values => _$values;
  static OrderType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class OrderTypeMixin = Object with _$OrderTypeMixin;

