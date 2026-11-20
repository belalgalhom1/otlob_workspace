//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delivery_incident_type.g.dart';

class DeliveryIncidentType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ORDER_CANCELLED')
  static const DeliveryIncidentType ORDER_CANCELLED = _$ORDER_CANCELLED;
  @BuiltValueEnumConst(wireName: r'DRIVER_REASSIGNED')
  static const DeliveryIncidentType DRIVER_REASSIGNED = _$DRIVER_REASSIGNED;
  @BuiltValueEnumConst(wireName: r'DRIVER_UNASSIGNED')
  static const DeliveryIncidentType DRIVER_UNASSIGNED = _$DRIVER_UNASSIGNED;
  @BuiltValueEnumConst(wireName: r'DELIVERY_FAILURE')
  static const DeliveryIncidentType DELIVERY_FAILURE = _$DELIVERY_FAILURE;

  static Serializer<DeliveryIncidentType> get serializer => _$deliveryIncidentTypeSerializer;

  const DeliveryIncidentType._(String name): super(name);

  static BuiltSet<DeliveryIncidentType> get values => _$values;
  static DeliveryIncidentType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DeliveryIncidentTypeMixin = Object with _$DeliveryIncidentTypeMixin;

