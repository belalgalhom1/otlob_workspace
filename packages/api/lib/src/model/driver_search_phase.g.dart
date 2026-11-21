// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_search_phase.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverSearchPhase _$QUEUED = const DriverSearchPhase._('QUEUED');
const DriverSearchPhase _$FINDING_DRIVERS = const DriverSearchPhase._(
  'FINDING_DRIVERS',
);
const DriverSearchPhase _$CONTACTING_DRIVERS = const DriverSearchPhase._(
  'CONTACTING_DRIVERS',
);
const DriverSearchPhase _$WAITING_DRIVER_RESPONSE = const DriverSearchPhase._(
  'WAITING_DRIVER_RESPONSE',
);
const DriverSearchPhase _$NO_DRIVERS_IN_WAVE = const DriverSearchPhase._(
  'NO_DRIVERS_IN_WAVE',
);
const DriverSearchPhase _$DRIVER_FOUND = const DriverSearchPhase._(
  'DRIVER_FOUND',
);
const DriverSearchPhase _$SEARCH_TIMEOUT = const DriverSearchPhase._(
  'SEARCH_TIMEOUT',
);
const DriverSearchPhase _$NO_DRIVERS_AVAILABLE = const DriverSearchPhase._(
  'NO_DRIVERS_AVAILABLE',
);
const DriverSearchPhase _$CANCELLED = const DriverSearchPhase._('CANCELLED');

DriverSearchPhase _$valueOf(String name) {
  switch (name) {
    case 'QUEUED':
      return _$QUEUED;
    case 'FINDING_DRIVERS':
      return _$FINDING_DRIVERS;
    case 'CONTACTING_DRIVERS':
      return _$CONTACTING_DRIVERS;
    case 'WAITING_DRIVER_RESPONSE':
      return _$WAITING_DRIVER_RESPONSE;
    case 'NO_DRIVERS_IN_WAVE':
      return _$NO_DRIVERS_IN_WAVE;
    case 'DRIVER_FOUND':
      return _$DRIVER_FOUND;
    case 'SEARCH_TIMEOUT':
      return _$SEARCH_TIMEOUT;
    case 'NO_DRIVERS_AVAILABLE':
      return _$NO_DRIVERS_AVAILABLE;
    case 'CANCELLED':
      return _$CANCELLED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverSearchPhase> _$values =
    BuiltSet<DriverSearchPhase>(const <DriverSearchPhase>[
      _$QUEUED,
      _$FINDING_DRIVERS,
      _$CONTACTING_DRIVERS,
      _$WAITING_DRIVER_RESPONSE,
      _$NO_DRIVERS_IN_WAVE,
      _$DRIVER_FOUND,
      _$SEARCH_TIMEOUT,
      _$NO_DRIVERS_AVAILABLE,
      _$CANCELLED,
    ]);

class _$DriverSearchPhaseMeta {
  const _$DriverSearchPhaseMeta();
  DriverSearchPhase get QUEUED => _$QUEUED;
  DriverSearchPhase get FINDING_DRIVERS => _$FINDING_DRIVERS;
  DriverSearchPhase get CONTACTING_DRIVERS => _$CONTACTING_DRIVERS;
  DriverSearchPhase get WAITING_DRIVER_RESPONSE => _$WAITING_DRIVER_RESPONSE;
  DriverSearchPhase get NO_DRIVERS_IN_WAVE => _$NO_DRIVERS_IN_WAVE;
  DriverSearchPhase get DRIVER_FOUND => _$DRIVER_FOUND;
  DriverSearchPhase get SEARCH_TIMEOUT => _$SEARCH_TIMEOUT;
  DriverSearchPhase get NO_DRIVERS_AVAILABLE => _$NO_DRIVERS_AVAILABLE;
  DriverSearchPhase get CANCELLED => _$CANCELLED;
  DriverSearchPhase valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverSearchPhase> get values => _$values;
}

mixin _$DriverSearchPhaseMixin {
  // ignore: non_constant_identifier_names
  _$DriverSearchPhaseMeta get DriverSearchPhase =>
      const _$DriverSearchPhaseMeta();
}

Serializer<DriverSearchPhase> _$driverSearchPhaseSerializer =
    _$DriverSearchPhaseSerializer();

class _$DriverSearchPhaseSerializer
    implements PrimitiveSerializer<DriverSearchPhase> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'QUEUED': 'QUEUED',
    'FINDING_DRIVERS': 'FINDING_DRIVERS',
    'CONTACTING_DRIVERS': 'CONTACTING_DRIVERS',
    'WAITING_DRIVER_RESPONSE': 'WAITING_DRIVER_RESPONSE',
    'NO_DRIVERS_IN_WAVE': 'NO_DRIVERS_IN_WAVE',
    'DRIVER_FOUND': 'DRIVER_FOUND',
    'SEARCH_TIMEOUT': 'SEARCH_TIMEOUT',
    'NO_DRIVERS_AVAILABLE': 'NO_DRIVERS_AVAILABLE',
    'CANCELLED': 'CANCELLED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'QUEUED': 'QUEUED',
    'FINDING_DRIVERS': 'FINDING_DRIVERS',
    'CONTACTING_DRIVERS': 'CONTACTING_DRIVERS',
    'WAITING_DRIVER_RESPONSE': 'WAITING_DRIVER_RESPONSE',
    'NO_DRIVERS_IN_WAVE': 'NO_DRIVERS_IN_WAVE',
    'DRIVER_FOUND': 'DRIVER_FOUND',
    'SEARCH_TIMEOUT': 'SEARCH_TIMEOUT',
    'NO_DRIVERS_AVAILABLE': 'NO_DRIVERS_AVAILABLE',
    'CANCELLED': 'CANCELLED',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverSearchPhase];
  @override
  final String wireName = 'DriverSearchPhase';

  @override
  Object serialize(
    Serializers serializers,
    DriverSearchPhase object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverSearchPhase deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverSearchPhase.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
