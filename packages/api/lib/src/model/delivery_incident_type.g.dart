// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_incident_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeliveryIncidentType _$ORDER_CANCELLED = const DeliveryIncidentType._(
  'ORDER_CANCELLED',
);
const DeliveryIncidentType _$DRIVER_REASSIGNED = const DeliveryIncidentType._(
  'DRIVER_REASSIGNED',
);
const DeliveryIncidentType _$DRIVER_UNASSIGNED = const DeliveryIncidentType._(
  'DRIVER_UNASSIGNED',
);
const DeliveryIncidentType _$DELIVERY_FAILURE = const DeliveryIncidentType._(
  'DELIVERY_FAILURE',
);

DeliveryIncidentType _$valueOf(String name) {
  switch (name) {
    case 'ORDER_CANCELLED':
      return _$ORDER_CANCELLED;
    case 'DRIVER_REASSIGNED':
      return _$DRIVER_REASSIGNED;
    case 'DRIVER_UNASSIGNED':
      return _$DRIVER_UNASSIGNED;
    case 'DELIVERY_FAILURE':
      return _$DELIVERY_FAILURE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DeliveryIncidentType> _$values =
    BuiltSet<DeliveryIncidentType>(const <DeliveryIncidentType>[
      _$ORDER_CANCELLED,
      _$DRIVER_REASSIGNED,
      _$DRIVER_UNASSIGNED,
      _$DELIVERY_FAILURE,
    ]);

class _$DeliveryIncidentTypeMeta {
  const _$DeliveryIncidentTypeMeta();
  DeliveryIncidentType get ORDER_CANCELLED => _$ORDER_CANCELLED;
  DeliveryIncidentType get DRIVER_REASSIGNED => _$DRIVER_REASSIGNED;
  DeliveryIncidentType get DRIVER_UNASSIGNED => _$DRIVER_UNASSIGNED;
  DeliveryIncidentType get DELIVERY_FAILURE => _$DELIVERY_FAILURE;
  DeliveryIncidentType valueOf(String name) => _$valueOf(name);
  BuiltSet<DeliveryIncidentType> get values => _$values;
}

mixin _$DeliveryIncidentTypeMixin {
  // ignore: non_constant_identifier_names
  _$DeliveryIncidentTypeMeta get DeliveryIncidentType =>
      const _$DeliveryIncidentTypeMeta();
}

Serializer<DeliveryIncidentType> _$deliveryIncidentTypeSerializer =
    _$DeliveryIncidentTypeSerializer();

class _$DeliveryIncidentTypeSerializer
    implements PrimitiveSerializer<DeliveryIncidentType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ORDER_CANCELLED': 'ORDER_CANCELLED',
    'DRIVER_REASSIGNED': 'DRIVER_REASSIGNED',
    'DRIVER_UNASSIGNED': 'DRIVER_UNASSIGNED',
    'DELIVERY_FAILURE': 'DELIVERY_FAILURE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ORDER_CANCELLED': 'ORDER_CANCELLED',
    'DRIVER_REASSIGNED': 'DRIVER_REASSIGNED',
    'DRIVER_UNASSIGNED': 'DRIVER_UNASSIGNED',
    'DELIVERY_FAILURE': 'DELIVERY_FAILURE',
  };

  @override
  final Iterable<Type> types = const <Type>[DeliveryIncidentType];
  @override
  final String wireName = 'DeliveryIncidentType';

  @override
  Object serialize(
    Serializers serializers,
    DeliveryIncidentType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DeliveryIncidentType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DeliveryIncidentType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
