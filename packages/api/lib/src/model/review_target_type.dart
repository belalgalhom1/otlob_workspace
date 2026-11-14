//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_target_type.g.dart';

class ReviewTargetType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'VENDOR_FULFILLMENT')
  static const ReviewTargetType VENDOR_FULFILLMENT = _$VENDOR_FULFILLMENT;
  @BuiltValueEnumConst(wireName: r'DELIVERY_GROUP')
  static const ReviewTargetType DELIVERY_GROUP = _$DELIVERY_GROUP;

  static Serializer<ReviewTargetType> get serializer => _$reviewTargetTypeSerializer;

  const ReviewTargetType._(String name): super(name);

  static BuiltSet<ReviewTargetType> get values => _$values;
  static ReviewTargetType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ReviewTargetTypeMixin = Object with _$ReviewTargetTypeMixin;

