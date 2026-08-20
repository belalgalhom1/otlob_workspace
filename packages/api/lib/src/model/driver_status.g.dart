// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DriverStatus _$OFFLINE = const DriverStatus._('OFFLINE');
const DriverStatus _$ONLINE = const DriverStatus._('ONLINE');
const DriverStatus _$BUSY = const DriverStatus._('BUSY');
const DriverStatus _$ON_DELIVERY = const DriverStatus._('ON_DELIVERY');
const DriverStatus _$ON_BREAK = const DriverStatus._('ON_BREAK');
const DriverStatus _$SUSPENDED = const DriverStatus._('SUSPENDED');

DriverStatus _$valueOf(String name) {
  switch (name) {
    case 'OFFLINE':
      return _$OFFLINE;
    case 'ONLINE':
      return _$ONLINE;
    case 'BUSY':
      return _$BUSY;
    case 'ON_DELIVERY':
      return _$ON_DELIVERY;
    case 'ON_BREAK':
      return _$ON_BREAK;
    case 'SUSPENDED':
      return _$SUSPENDED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DriverStatus> _$values = BuiltSet<DriverStatus>(
  const <DriverStatus>[
    _$OFFLINE,
    _$ONLINE,
    _$BUSY,
    _$ON_DELIVERY,
    _$ON_BREAK,
    _$SUSPENDED,
  ],
);

class _$DriverStatusMeta {
  const _$DriverStatusMeta();
  DriverStatus get OFFLINE => _$OFFLINE;
  DriverStatus get ONLINE => _$ONLINE;
  DriverStatus get BUSY => _$BUSY;
  DriverStatus get ON_DELIVERY => _$ON_DELIVERY;
  DriverStatus get ON_BREAK => _$ON_BREAK;
  DriverStatus get SUSPENDED => _$SUSPENDED;
  DriverStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<DriverStatus> get values => _$values;
}

mixin _$DriverStatusMixin {
  // ignore: non_constant_identifier_names
  _$DriverStatusMeta get DriverStatus => const _$DriverStatusMeta();
}

Serializer<DriverStatus> _$driverStatusSerializer = _$DriverStatusSerializer();

class _$DriverStatusSerializer implements PrimitiveSerializer<DriverStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OFFLINE': 'OFFLINE',
    'ONLINE': 'ONLINE',
    'BUSY': 'BUSY',
    'ON_DELIVERY': 'ON_DELIVERY',
    'ON_BREAK': 'ON_BREAK',
    'SUSPENDED': 'SUSPENDED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OFFLINE': 'OFFLINE',
    'ONLINE': 'ONLINE',
    'BUSY': 'BUSY',
    'ON_DELIVERY': 'ON_DELIVERY',
    'ON_BREAK': 'ON_BREAK',
    'SUSPENDED': 'SUSPENDED',
  };

  @override
  final Iterable<Type> types = const <Type>[DriverStatus];
  @override
  final String wireName = 'DriverStatus';

  @override
  Object serialize(
    Serializers serializers,
    DriverStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DriverStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DriverStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
