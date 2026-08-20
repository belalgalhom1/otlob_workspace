// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistic_period.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const StatisticPeriod _$DAILY = const StatisticPeriod._('DAILY');
const StatisticPeriod _$WEEKLY = const StatisticPeriod._('WEEKLY');
const StatisticPeriod _$MONTHLY = const StatisticPeriod._('MONTHLY');
const StatisticPeriod _$YEARLY = const StatisticPeriod._('YEARLY');

StatisticPeriod _$valueOf(String name) {
  switch (name) {
    case 'DAILY':
      return _$DAILY;
    case 'WEEKLY':
      return _$WEEKLY;
    case 'MONTHLY':
      return _$MONTHLY;
    case 'YEARLY':
      return _$YEARLY;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<StatisticPeriod> _$values = BuiltSet<StatisticPeriod>(
  const <StatisticPeriod>[_$DAILY, _$WEEKLY, _$MONTHLY, _$YEARLY],
);

class _$StatisticPeriodMeta {
  const _$StatisticPeriodMeta();
  StatisticPeriod get DAILY => _$DAILY;
  StatisticPeriod get WEEKLY => _$WEEKLY;
  StatisticPeriod get MONTHLY => _$MONTHLY;
  StatisticPeriod get YEARLY => _$YEARLY;
  StatisticPeriod valueOf(String name) => _$valueOf(name);
  BuiltSet<StatisticPeriod> get values => _$values;
}

mixin _$StatisticPeriodMixin {
  // ignore: non_constant_identifier_names
  _$StatisticPeriodMeta get StatisticPeriod => const _$StatisticPeriodMeta();
}

Serializer<StatisticPeriod> _$statisticPeriodSerializer =
    _$StatisticPeriodSerializer();

class _$StatisticPeriodSerializer
    implements PrimitiveSerializer<StatisticPeriod> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DAILY': 'DAILY',
    'WEEKLY': 'WEEKLY',
    'MONTHLY': 'MONTHLY',
    'YEARLY': 'YEARLY',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DAILY': 'DAILY',
    'WEEKLY': 'WEEKLY',
    'MONTHLY': 'MONTHLY',
    'YEARLY': 'YEARLY',
  };

  @override
  final Iterable<Type> types = const <Type>[StatisticPeriod];
  @override
  final String wireName = 'StatisticPeriod';

  @override
  Object serialize(
    Serializers serializers,
    StatisticPeriod object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  StatisticPeriod deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => StatisticPeriod.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
