// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_shift_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverShiftStatus _$SCHEDULED = const DriverShiftStatus._('SCHEDULED');
const DriverShiftStatus _$ACTIVE = const DriverShiftStatus._('ACTIVE');
const DriverShiftStatus _$COMPLETED = const DriverShiftStatus._('COMPLETED');
const DriverShiftStatus _$CANCELLED = const DriverShiftStatus._('CANCELLED');
const DriverShiftStatus _$MISSED = const DriverShiftStatus._('MISSED');

DriverShiftStatus _$valueOf(String name) {
  switch (name) {
    case 'SCHEDULED':
      return _$SCHEDULED;
    case 'ACTIVE':
      return _$ACTIVE;
    case 'COMPLETED':
      return _$COMPLETED;
    case 'CANCELLED':
      return _$CANCELLED;
    case 'MISSED':
      return _$MISSED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverShiftStatus> _$values = BuiltSet<DriverShiftStatus>(
  const <DriverShiftStatus>[
    _$SCHEDULED,
    _$ACTIVE,
    _$COMPLETED,
    _$CANCELLED,
    _$MISSED,
  ],
);

class _$DriverShiftStatusMeta {
  const _$DriverShiftStatusMeta();
  DriverShiftStatus get SCHEDULED => _$SCHEDULED;
  DriverShiftStatus get ACTIVE => _$ACTIVE;
  DriverShiftStatus get COMPLETED => _$COMPLETED;
  DriverShiftStatus get CANCELLED => _$CANCELLED;
  DriverShiftStatus get MISSED => _$MISSED;
  DriverShiftStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverShiftStatus> get values => _$values;
}

mixin _$DriverShiftStatusMixin {
  // ignore: non_constant_identifier_names
  _$DriverShiftStatusMeta get DriverShiftStatus =>
      const _$DriverShiftStatusMeta();
}

Serializer<DriverShiftStatus> _$driverShiftStatusSerializer =
    _$DriverShiftStatusSerializer();

class _$DriverShiftStatusSerializer
    implements PrimitiveSerializer<DriverShiftStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'SCHEDULED': 'SCHEDULED',
    'ACTIVE': 'ACTIVE',
    'COMPLETED': 'COMPLETED',
    'CANCELLED': 'CANCELLED',
    'MISSED': 'MISSED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'SCHEDULED': 'SCHEDULED',
    'ACTIVE': 'ACTIVE',
    'COMPLETED': 'COMPLETED',
    'CANCELLED': 'CANCELLED',
    'MISSED': 'MISSED',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverShiftStatus];
  @override
  final String wireName = 'DriverShiftStatus';

  @override
  Object serialize(
    Serializers serializers,
    DriverShiftStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverShiftStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverShiftStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
