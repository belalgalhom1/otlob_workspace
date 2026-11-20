// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_rank_change_reason.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverRankChangeReason _$WEEKLY_EVALUATION =
    const DriverRankChangeReason._('WEEKLY_EVALUATION');
const DriverRankChangeReason _$INACTIVE_DRIVER = const DriverRankChangeReason._(
  'INACTIVE_DRIVER',
);
const DriverRankChangeReason _$ADMIN_OVERRIDE = const DriverRankChangeReason._(
  'ADMIN_OVERRIDE',
);

DriverRankChangeReason _$valueOf(String name) {
  switch (name) {
    case 'WEEKLY_EVALUATION':
      return _$WEEKLY_EVALUATION;
    case 'INACTIVE_DRIVER':
      return _$INACTIVE_DRIVER;
    case 'ADMIN_OVERRIDE':
      return _$ADMIN_OVERRIDE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverRankChangeReason> _$values =
    BuiltSet<DriverRankChangeReason>(const <DriverRankChangeReason>[
      _$WEEKLY_EVALUATION,
      _$INACTIVE_DRIVER,
      _$ADMIN_OVERRIDE,
    ]);

class _$DriverRankChangeReasonMeta {
  const _$DriverRankChangeReasonMeta();
  DriverRankChangeReason get WEEKLY_EVALUATION => _$WEEKLY_EVALUATION;
  DriverRankChangeReason get INACTIVE_DRIVER => _$INACTIVE_DRIVER;
  DriverRankChangeReason get ADMIN_OVERRIDE => _$ADMIN_OVERRIDE;
  DriverRankChangeReason valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverRankChangeReason> get values => _$values;
}

mixin _$DriverRankChangeReasonMixin {
  // ignore: non_constant_identifier_names
  _$DriverRankChangeReasonMeta get DriverRankChangeReason =>
      const _$DriverRankChangeReasonMeta();
}

Serializer<DriverRankChangeReason> _$driverRankChangeReasonSerializer =
    _$DriverRankChangeReasonSerializer();

class _$DriverRankChangeReasonSerializer
    implements PrimitiveSerializer<DriverRankChangeReason> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'WEEKLY_EVALUATION': 'WEEKLY_EVALUATION',
    'INACTIVE_DRIVER': 'INACTIVE_DRIVER',
    'ADMIN_OVERRIDE': 'ADMIN_OVERRIDE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'WEEKLY_EVALUATION': 'WEEKLY_EVALUATION',
    'INACTIVE_DRIVER': 'INACTIVE_DRIVER',
    'ADMIN_OVERRIDE': 'ADMIN_OVERRIDE',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverRankChangeReason];
  @override
  final String wireName = 'DriverRankChangeReason';

  @override
  Object serialize(
    Serializers serializers,
    DriverRankChangeReason object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverRankChangeReason deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverRankChangeReason.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
