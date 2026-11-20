// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_outcome.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverRankingOutcome _$PROMOTED = const DriverRankingOutcome._(
  'PROMOTED',
);
const DriverRankingOutcome _$DEMOTED = const DriverRankingOutcome._('DEMOTED');
const DriverRankingOutcome _$UNCHANGED = const DriverRankingOutcome._(
  'UNCHANGED',
);
const DriverRankingOutcome _$INACTIVE_SILVER = const DriverRankingOutcome._(
  'INACTIVE_SILVER',
);
const DriverRankingOutcome _$CAPPED_SILVER = const DriverRankingOutcome._(
  'CAPPED_SILVER',
);

DriverRankingOutcome _$valueOf(String name) {
  switch (name) {
    case 'PROMOTED':
      return _$PROMOTED;
    case 'DEMOTED':
      return _$DEMOTED;
    case 'UNCHANGED':
      return _$UNCHANGED;
    case 'INACTIVE_SILVER':
      return _$INACTIVE_SILVER;
    case 'CAPPED_SILVER':
      return _$CAPPED_SILVER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverRankingOutcome> _$values = BuiltSet<DriverRankingOutcome>(
  const <DriverRankingOutcome>[
    _$PROMOTED,
    _$DEMOTED,
    _$UNCHANGED,
    _$INACTIVE_SILVER,
    _$CAPPED_SILVER,
  ],
);

class _$DriverRankingOutcomeMeta {
  const _$DriverRankingOutcomeMeta();
  DriverRankingOutcome get PROMOTED => _$PROMOTED;
  DriverRankingOutcome get DEMOTED => _$DEMOTED;
  DriverRankingOutcome get UNCHANGED => _$UNCHANGED;
  DriverRankingOutcome get INACTIVE_SILVER => _$INACTIVE_SILVER;
  DriverRankingOutcome get CAPPED_SILVER => _$CAPPED_SILVER;
  DriverRankingOutcome valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverRankingOutcome> get values => _$values;
}

mixin _$DriverRankingOutcomeMixin {
  // ignore: non_constant_identifier_names
  _$DriverRankingOutcomeMeta get DriverRankingOutcome =>
      const _$DriverRankingOutcomeMeta();
}

Serializer<DriverRankingOutcome> _$driverRankingOutcomeSerializer =
    _$DriverRankingOutcomeSerializer();

class _$DriverRankingOutcomeSerializer
    implements PrimitiveSerializer<DriverRankingOutcome> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PROMOTED': 'PROMOTED',
    'DEMOTED': 'DEMOTED',
    'UNCHANGED': 'UNCHANGED',
    'INACTIVE_SILVER': 'INACTIVE_SILVER',
    'CAPPED_SILVER': 'CAPPED_SILVER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PROMOTED': 'PROMOTED',
    'DEMOTED': 'DEMOTED',
    'UNCHANGED': 'UNCHANGED',
    'INACTIVE_SILVER': 'INACTIVE_SILVER',
    'CAPPED_SILVER': 'CAPPED_SILVER',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverRankingOutcome];
  @override
  final String wireName = 'DriverRankingOutcome';

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingOutcome object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverRankingOutcome deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverRankingOutcome.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
