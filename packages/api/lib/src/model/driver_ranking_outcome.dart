//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_outcome.g.dart';

class DriverRankingOutcome extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PROMOTED')
  static const DriverRankingOutcome PROMOTED = _$PROMOTED;
  @BuiltValueEnumConst(wireName: r'DEMOTED')
  static const DriverRankingOutcome DEMOTED = _$DEMOTED;
  @BuiltValueEnumConst(wireName: r'UNCHANGED')
  static const DriverRankingOutcome UNCHANGED = _$UNCHANGED;
  @BuiltValueEnumConst(wireName: r'INACTIVE_SILVER')
  static const DriverRankingOutcome INACTIVE_SILVER = _$INACTIVE_SILVER;
  @BuiltValueEnumConst(wireName: r'CAPPED_SILVER')
  static const DriverRankingOutcome CAPPED_SILVER = _$CAPPED_SILVER;

  static Serializer<DriverRankingOutcome> get serializer => _$driverRankingOutcomeSerializer;

  const DriverRankingOutcome._(String name): super(name);

  static BuiltSet<DriverRankingOutcome> get values => _$values;
  static DriverRankingOutcome valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverRankingOutcomeMixin = Object with _$DriverRankingOutcomeMixin;

