//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_break_reason.g.dart';

class DriverBreakReason extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PRAYER')
  static const DriverBreakReason PRAYER = _$PRAYER;
  @BuiltValueEnumConst(wireName: r'MEAL')
  static const DriverBreakReason MEAL = _$MEAL;
  @BuiltValueEnumConst(wireName: r'REST')
  static const DriverBreakReason REST = _$REST;
  @BuiltValueEnumConst(wireName: r'PERSONAL')
  static const DriverBreakReason PERSONAL = _$PERSONAL;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const DriverBreakReason OTHER = _$OTHER;

  static Serializer<DriverBreakReason> get serializer => _$driverBreakReasonSerializer;

  const DriverBreakReason._(String name): super(name);

  static BuiltSet<DriverBreakReason> get values => _$values;
  static DriverBreakReason valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverBreakReasonMixin = Object with _$DriverBreakReasonMixin;

