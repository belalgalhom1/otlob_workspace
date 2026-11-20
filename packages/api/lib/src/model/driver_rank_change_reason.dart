//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_rank_change_reason.g.dart';

class DriverRankChangeReason extends EnumClass {

  @BuiltValueEnumConst(wireName: r'WEEKLY_EVALUATION')
  static const DriverRankChangeReason WEEKLY_EVALUATION = _$WEEKLY_EVALUATION;
  @BuiltValueEnumConst(wireName: r'INACTIVE_DRIVER')
  static const DriverRankChangeReason INACTIVE_DRIVER = _$INACTIVE_DRIVER;
  @BuiltValueEnumConst(wireName: r'ADMIN_OVERRIDE')
  static const DriverRankChangeReason ADMIN_OVERRIDE = _$ADMIN_OVERRIDE;

  static Serializer<DriverRankChangeReason> get serializer => _$driverRankChangeReasonSerializer;

  const DriverRankChangeReason._(String name): super(name);

  static BuiltSet<DriverRankChangeReason> get values => _$values;
  static DriverRankChangeReason valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverRankChangeReasonMixin = Object with _$DriverRankChangeReasonMixin;

