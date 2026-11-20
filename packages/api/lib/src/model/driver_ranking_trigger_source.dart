//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_trigger_source.g.dart';

class DriverRankingTriggerSource extends EnumClass {

  @BuiltValueEnumConst(wireName: r'SCHEDULED')
  static const DriverRankingTriggerSource SCHEDULED = _$SCHEDULED;
  @BuiltValueEnumConst(wireName: r'MANUAL')
  static const DriverRankingTriggerSource MANUAL = _$MANUAL;

  static Serializer<DriverRankingTriggerSource> get serializer => _$driverRankingTriggerSourceSerializer;

  const DriverRankingTriggerSource._(String name): super(name);

  static BuiltSet<DriverRankingTriggerSource> get values => _$values;
  static DriverRankingTriggerSource valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverRankingTriggerSourceMixin = Object with _$DriverRankingTriggerSourceMixin;

