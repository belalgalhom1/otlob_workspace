//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delivery_incident_responsibility.g.dart';

class DeliveryIncidentResponsibility extends EnumClass {

  @BuiltValueEnumConst(wireName: r'DRIVER_AT_FAULT')
  static const DeliveryIncidentResponsibility DRIVER_AT_FAULT = _$DRIVER_AT_FAULT;
  @BuiltValueEnumConst(wireName: r'CUSTOMER')
  static const DeliveryIncidentResponsibility CUSTOMER = _$CUSTOMER;
  @BuiltValueEnumConst(wireName: r'VENDOR')
  static const DeliveryIncidentResponsibility VENDOR = _$VENDOR;
  @BuiltValueEnumConst(wireName: r'EXTERNAL_OR_SYSTEM')
  static const DeliveryIncidentResponsibility EXTERNAL_OR_SYSTEM = _$EXTERNAL_OR_SYSTEM;
  @BuiltValueEnumConst(wireName: r'UNDER_REVIEW')
  static const DeliveryIncidentResponsibility UNDER_REVIEW = _$UNDER_REVIEW;

  static Serializer<DeliveryIncidentResponsibility> get serializer => _$deliveryIncidentResponsibilitySerializer;

  const DeliveryIncidentResponsibility._(String name): super(name);

  static BuiltSet<DeliveryIncidentResponsibility> get values => _$values;
  static DeliveryIncidentResponsibility valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DeliveryIncidentResponsibilityMixin = Object with _$DeliveryIncidentResponsibilityMixin;

