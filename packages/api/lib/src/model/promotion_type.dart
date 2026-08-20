//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'promotion_type.g.dart';

class PromotionType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BANNER')
  static const PromotionType BANNER = _$BANNER;
  @BuiltValueEnumConst(wireName: r'VENDOR')
  static const PromotionType VENDOR = _$VENDOR;
  @BuiltValueEnumConst(wireName: r'PRODUCT')
  static const PromotionType PRODUCT = _$PRODUCT;
  @BuiltValueEnumConst(wireName: r'EXTERNAL_LINK')
  static const PromotionType EXTERNAL_LINK = _$EXTERNAL_LINK;
  @BuiltValueEnumConst(wireName: r'POPUP')
  static const PromotionType POPUP = _$POPUP;
  @BuiltValueEnumConst(wireName: r'NOTIFICATION')
  static const PromotionType NOTIFICATION = _$NOTIFICATION;

  static Serializer<PromotionType> get serializer => _$promotionTypeSerializer;

  const PromotionType._(String name): super(name);

  static BuiltSet<PromotionType> get values => _$values;
  static PromotionType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class PromotionTypeMixin = Object with _$PromotionTypeMixin;

