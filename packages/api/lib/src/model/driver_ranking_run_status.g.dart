// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_ranking_run_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverRankingRunStatus _$RUNNING = const DriverRankingRunStatus._(
  'RUNNING',
);
const DriverRankingRunStatus _$COMPLETED = const DriverRankingRunStatus._(
  'COMPLETED',
);
const DriverRankingRunStatus _$FAILED = const DriverRankingRunStatus._(
  'FAILED',
);

DriverRankingRunStatus _$valueOf(String name) {
  switch (name) {
    case 'RUNNING':
      return _$RUNNING;
    case 'COMPLETED':
      return _$COMPLETED;
    case 'FAILED':
      return _$FAILED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverRankingRunStatus> _$values =
    BuiltSet<DriverRankingRunStatus>(const <DriverRankingRunStatus>[
      _$RUNNING,
      _$COMPLETED,
      _$FAILED,
    ]);

class _$DriverRankingRunStatusMeta {
  const _$DriverRankingRunStatusMeta();
  DriverRankingRunStatus get RUNNING => _$RUNNING;
  DriverRankingRunStatus get COMPLETED => _$COMPLETED;
  DriverRankingRunStatus get FAILED => _$FAILED;
  DriverRankingRunStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverRankingRunStatus> get values => _$values;
}

mixin _$DriverRankingRunStatusMixin {
  // ignore: non_constant_identifier_names
  _$DriverRankingRunStatusMeta get DriverRankingRunStatus =>
      const _$DriverRankingRunStatusMeta();
}

Serializer<DriverRankingRunStatus> _$driverRankingRunStatusSerializer =
    _$DriverRankingRunStatusSerializer();

class _$DriverRankingRunStatusSerializer
    implements PrimitiveSerializer<DriverRankingRunStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'RUNNING': 'RUNNING',
    'COMPLETED': 'COMPLETED',
    'FAILED': 'FAILED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'RUNNING': 'RUNNING',
    'COMPLETED': 'COMPLETED',
    'FAILED': 'FAILED',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverRankingRunStatus];
  @override
  final String wireName = 'DriverRankingRunStatus';

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingRunStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverRankingRunStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverRankingRunStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
