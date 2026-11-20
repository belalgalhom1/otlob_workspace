//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_run_status.g.dart';

class DriverRankingRunStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'RUNNING')
  static const DriverRankingRunStatus RUNNING = _$RUNNING;
  @BuiltValueEnumConst(wireName: r'COMPLETED')
  static const DriverRankingRunStatus COMPLETED = _$COMPLETED;
  @BuiltValueEnumConst(wireName: r'FAILED')
  static const DriverRankingRunStatus FAILED = _$FAILED;

  static Serializer<DriverRankingRunStatus> get serializer => _$driverRankingRunStatusSerializer;

  const DriverRankingRunStatus._(String name): super(name);

  static BuiltSet<DriverRankingRunStatus> get values => _$values;
  static DriverRankingRunStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverRankingRunStatusMixin = Object with _$DriverRankingRunStatusMixin;

