// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_trigger_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverRankingTriggerSource _$SCHEDULED =
    const DriverRankingTriggerSource._('SCHEDULED');
const DriverRankingTriggerSource _$MANUAL = const DriverRankingTriggerSource._(
  'MANUAL',
);

DriverRankingTriggerSource _$valueOf(String name) {
  switch (name) {
    case 'SCHEDULED':
      return _$SCHEDULED;
    case 'MANUAL':
      return _$MANUAL;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverRankingTriggerSource> _$values =
    BuiltSet<DriverRankingTriggerSource>(const <DriverRankingTriggerSource>[
      _$SCHEDULED,
      _$MANUAL,
    ]);

class _$DriverRankingTriggerSourceMeta {
  const _$DriverRankingTriggerSourceMeta();
  DriverRankingTriggerSource get SCHEDULED => _$SCHEDULED;
  DriverRankingTriggerSource get MANUAL => _$MANUAL;
  DriverRankingTriggerSource valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverRankingTriggerSource> get values => _$values;
}

mixin _$DriverRankingTriggerSourceMixin {
  // ignore: non_constant_identifier_names
  _$DriverRankingTriggerSourceMeta get DriverRankingTriggerSource =>
      const _$DriverRankingTriggerSourceMeta();
}

Serializer<DriverRankingTriggerSource> _$driverRankingTriggerSourceSerializer =
    _$DriverRankingTriggerSourceSerializer();

class _$DriverRankingTriggerSourceSerializer
    implements PrimitiveSerializer<DriverRankingTriggerSource> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'SCHEDULED': 'SCHEDULED',
    'MANUAL': 'MANUAL',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'SCHEDULED': 'SCHEDULED',
    'MANUAL': 'MANUAL',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverRankingTriggerSource];
  @override
  final String wireName = 'DriverRankingTriggerSource';

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingTriggerSource object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverRankingTriggerSource deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverRankingTriggerSource.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
