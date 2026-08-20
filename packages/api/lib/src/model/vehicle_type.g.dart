// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VehicleType _$BICYCLE = const VehicleType._('BICYCLE');
const VehicleType _$MOTORCYCLE = const VehicleType._('MOTORCYCLE');
const VehicleType _$CAR = const VehicleType._('CAR');
const VehicleType _$VAN = const VehicleType._('VAN');
const VehicleType _$TRUCK = const VehicleType._('TRUCK');
const VehicleType _$MOTOR_TRICYCLE = const VehicleType._('MOTOR_TRICYCLE');

VehicleType _$valueOf(String name) {
  switch (name) {
    case 'BICYCLE':
      return _$BICYCLE;
    case 'MOTORCYCLE':
      return _$MOTORCYCLE;
    case 'CAR':
      return _$CAR;
    case 'VAN':
      return _$VAN;
    case 'TRUCK':
      return _$TRUCK;
    case 'MOTOR_TRICYCLE':
      return _$MOTOR_TRICYCLE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<VehicleType> _$values = BuiltSet<VehicleType>(
  const <VehicleType>[
    _$BICYCLE,
    _$MOTORCYCLE,
    _$CAR,
    _$VAN,
    _$TRUCK,
    _$MOTOR_TRICYCLE,
  ],
);

class _$VehicleTypeMeta {
  const _$VehicleTypeMeta();
  VehicleType get BICYCLE => _$BICYCLE;
  VehicleType get MOTORCYCLE => _$MOTORCYCLE;
  VehicleType get CAR => _$CAR;
  VehicleType get VAN => _$VAN;
  VehicleType get TRUCK => _$TRUCK;
  VehicleType get MOTOR_TRICYCLE => _$MOTOR_TRICYCLE;
  VehicleType valueOf(String name) => _$valueOf(name);
  BuiltSet<VehicleType> get values => _$values;
}

mixin _$VehicleTypeMixin {
  // ignore: non_constant_identifier_names
  _$VehicleTypeMeta get VehicleType => const _$VehicleTypeMeta();
}

Serializer<VehicleType> _$vehicleTypeSerializer = _$VehicleTypeSerializer();

class _$VehicleTypeSerializer implements PrimitiveSerializer<VehicleType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'BICYCLE': 'BICYCLE',
    'MOTORCYCLE': 'MOTORCYCLE',
    'CAR': 'CAR',
    'VAN': 'VAN',
    'TRUCK': 'TRUCK',
    'MOTOR_TRICYCLE': 'MOTOR_TRICYCLE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'BICYCLE': 'BICYCLE',
    'MOTORCYCLE': 'MOTORCYCLE',
    'CAR': 'CAR',
    'VAN': 'VAN',
    'TRUCK': 'TRUCK',
    'MOTOR_TRICYCLE': 'MOTOR_TRICYCLE',
  };

  @override
  final Iterable<Type> types = const <Type>[VehicleType];
  @override
  final String wireName = 'VehicleType';

  @override
  Object serialize(
    Serializers serializers,
    VehicleType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  VehicleType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => VehicleType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
