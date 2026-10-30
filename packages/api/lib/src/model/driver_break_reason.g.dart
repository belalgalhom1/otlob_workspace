// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_break_reason.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverBreakReason _$PRAYER = const DriverBreakReason._('PRAYER');
const DriverBreakReason _$MEAL = const DriverBreakReason._('MEAL');
const DriverBreakReason _$REST = const DriverBreakReason._('REST');
const DriverBreakReason _$PERSONAL = const DriverBreakReason._('PERSONAL');
const DriverBreakReason _$OTHER = const DriverBreakReason._('OTHER');

DriverBreakReason _$valueOf(String name) {
  switch (name) {
    case 'PRAYER':
      return _$PRAYER;
    case 'MEAL':
      return _$MEAL;
    case 'REST':
      return _$REST;
    case 'PERSONAL':
      return _$PERSONAL;
    case 'OTHER':
      return _$OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverBreakReason> _$values = BuiltSet<DriverBreakReason>(
  const <DriverBreakReason>[_$PRAYER, _$MEAL, _$REST, _$PERSONAL, _$OTHER],
);

class _$DriverBreakReasonMeta {
  const _$DriverBreakReasonMeta();
  DriverBreakReason get PRAYER => _$PRAYER;
  DriverBreakReason get MEAL => _$MEAL;
  DriverBreakReason get REST => _$REST;
  DriverBreakReason get PERSONAL => _$PERSONAL;
  DriverBreakReason get OTHER => _$OTHER;
  DriverBreakReason valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverBreakReason> get values => _$values;
}

mixin _$DriverBreakReasonMixin {
  // ignore: non_constant_identifier_names
  _$DriverBreakReasonMeta get DriverBreakReason =>
      const _$DriverBreakReasonMeta();
}

Serializer<DriverBreakReason> _$driverBreakReasonSerializer =
    _$DriverBreakReasonSerializer();

class _$DriverBreakReasonSerializer
    implements PrimitiveSerializer<DriverBreakReason> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PRAYER': 'PRAYER',
    'MEAL': 'MEAL',
    'REST': 'REST',
    'PERSONAL': 'PERSONAL',
    'OTHER': 'OTHER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PRAYER': 'PRAYER',
    'MEAL': 'MEAL',
    'REST': 'REST',
    'PERSONAL': 'PERSONAL',
    'OTHER': 'OTHER',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverBreakReason];
  @override
  final String wireName = 'DriverBreakReason';

  @override
  Object serialize(
    Serializers serializers,
    DriverBreakReason object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverBreakReason deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverBreakReason.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
