//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'custom_order_preview_type.g.dart';

class CustomOrderPreviewType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CUSTOM_DELIVERY')
  static const CustomOrderPreviewType CUSTOM_DELIVERY = _$CUSTOM_DELIVERY;
  @BuiltValueEnumConst(wireName: r'RIDE')
  static const CustomOrderPreviewType RIDE = _$RIDE;

  static Serializer<CustomOrderPreviewType> get serializer => _$customOrderPreviewTypeSerializer;

  const CustomOrderPreviewType._(String name): super(name);

  static BuiltSet<CustomOrderPreviewType> get values => _$values;
  static CustomOrderPreviewType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class CustomOrderPreviewTypeMixin = Object with _$CustomOrderPreviewTypeMixin;

