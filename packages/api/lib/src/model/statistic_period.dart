//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'statistic_period.g.dart';

class StatisticPeriod extends EnumClass {

  @BuiltValueEnumConst(wireName: r'DAILY')
  static const StatisticPeriod DAILY = _$DAILY;
  @BuiltValueEnumConst(wireName: r'WEEKLY')
  static const StatisticPeriod WEEKLY = _$WEEKLY;
  @BuiltValueEnumConst(wireName: r'MONTHLY')
  static const StatisticPeriod MONTHLY = _$MONTHLY;
  @BuiltValueEnumConst(wireName: r'YEARLY')
  static const StatisticPeriod YEARLY = _$YEARLY;

  static Serializer<StatisticPeriod> get serializer => _$statisticPeriodSerializer;

  const StatisticPeriod._(String name): super(name);

  static BuiltSet<StatisticPeriod> get values => _$values;
  static StatisticPeriod valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class StatisticPeriodMixin = Object with _$StatisticPeriodMixin;

