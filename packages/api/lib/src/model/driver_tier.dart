//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_tier.g.dart';

class DriverTier extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BRONZE')
  static const DriverTier BRONZE = _$BRONZE;
  @BuiltValueEnumConst(wireName: r'SILVER')
  static const DriverTier SILVER = _$SILVER;
  @BuiltValueEnumConst(wireName: r'GOLD')
  static const DriverTier GOLD = _$GOLD;

  static Serializer<DriverTier> get serializer => _$driverTierSerializer;

  const DriverTier._(String name): super(name);

  static BuiltSet<DriverTier> get values => _$values;
  static DriverTier valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverTierMixin = Object with _$DriverTierMixin;

