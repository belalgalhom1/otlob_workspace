// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VehicleType _$BICYCLE = const VehicleType._('BICYCLE');
const VehicleType _$MOTORCYCLE = const VehicleType._('MOTORCYCLE');
const VehicleType _$CAR = const VehicleType._('CAR');
const VehicleType _$MINIBUS = const VehicleType._('MINIBUS');
const VehicleType _$TUK_TUK = const VehicleType._('TUK_TUK');
const VehicleType _$MOTOR_TRICYCLE = const VehicleType._('MOTOR_TRICYCLE');
const VehicleType _$QUARTER_TRUCK = const VehicleType._('QUARTER_TRUCK');
const VehicleType _$HALF_TRUCK = const VehicleType._('HALF_TRUCK');

VehicleType _$valueOf(String name) {
  switch (name) {
    case 'BICYCLE':
      return _$BICYCLE;
    case 'MOTORCYCLE':
      return _$MOTORCYCLE;
    case 'CAR':
      return _$CAR;
    case 'MINIBUS':
      return _$MINIBUS;
    case 'TUK_TUK':
      return _$TUK_TUK;
    case 'MOTOR_TRICYCLE':
      return _$MOTOR_TRICYCLE;
    case 'QUARTER_TRUCK':
      return _$QUARTER_TRUCK;
    case 'HALF_TRUCK':
      return _$HALF_TRUCK;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<VehicleType> _$values =
    BuiltSet<VehicleType>(const <VehicleType>[
      _$BICYCLE,
      _$MOTORCYCLE,
      _$CAR,
      _$MINIBUS,
      _$TUK_TUK,
      _$MOTOR_TRICYCLE,
      _$QUARTER_TRUCK,
      _$HALF_TRUCK,
    ]);

class _$VehicleTypeMeta {
  const _$VehicleTypeMeta();
  VehicleType get BICYCLE => _$BICYCLE;
  VehicleType get MOTORCYCLE => _$MOTORCYCLE;
  VehicleType get CAR => _$CAR;
  VehicleType get MINIBUS => _$MINIBUS;
  VehicleType get TUK_TUK => _$TUK_TUK;
  VehicleType get MOTOR_TRICYCLE => _$MOTOR_TRICYCLE;
  VehicleType get QUARTER_TRUCK => _$QUARTER_TRUCK;
  VehicleType get HALF_TRUCK => _$HALF_TRUCK;
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
    'MINIBUS': 'MINIBUS',
    'TUK_TUK': 'TUK_TUK',
    'MOTOR_TRICYCLE': 'MOTOR_TRICYCLE',
    'QUARTER_TRUCK': 'QUARTER_TRUCK',
    'HALF_TRUCK': 'HALF_TRUCK',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'BICYCLE': 'BICYCLE',
    'MOTORCYCLE': 'MOTORCYCLE',
    'CAR': 'CAR',
    'MINIBUS': 'MINIBUS',
    'TUK_TUK': 'TUK_TUK',
    'MOTOR_TRICYCLE': 'MOTOR_TRICYCLE',
    'QUARTER_TRUCK': 'QUARTER_TRUCK',
    'HALF_TRUCK': 'HALF_TRUCK',
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
