// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_incident_responsibility.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeliveryIncidentResponsibility _$DRIVER_AT_FAULT =
    const DeliveryIncidentResponsibility._('DRIVER_AT_FAULT');
const DeliveryIncidentResponsibility _$CUSTOMER =
    const DeliveryIncidentResponsibility._('CUSTOMER');
const DeliveryIncidentResponsibility _$VENDOR =
    const DeliveryIncidentResponsibility._('VENDOR');
const DeliveryIncidentResponsibility _$EXTERNAL_OR_SYSTEM =
    const DeliveryIncidentResponsibility._('EXTERNAL_OR_SYSTEM');
const DeliveryIncidentResponsibility _$UNDER_REVIEW =
    const DeliveryIncidentResponsibility._('UNDER_REVIEW');

DeliveryIncidentResponsibility _$valueOf(String name) {
  switch (name) {
    case 'DRIVER_AT_FAULT':
      return _$DRIVER_AT_FAULT;
    case 'CUSTOMER':
      return _$CUSTOMER;
    case 'VENDOR':
      return _$VENDOR;
    case 'EXTERNAL_OR_SYSTEM':
      return _$EXTERNAL_OR_SYSTEM;
    case 'UNDER_REVIEW':
      return _$UNDER_REVIEW;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DeliveryIncidentResponsibility> _$values =
    BuiltSet<DeliveryIncidentResponsibility>(
      const <DeliveryIncidentResponsibility>[
        _$DRIVER_AT_FAULT,
        _$CUSTOMER,
        _$VENDOR,
        _$EXTERNAL_OR_SYSTEM,
        _$UNDER_REVIEW,
      ],
    );

class _$DeliveryIncidentResponsibilityMeta {
  const _$DeliveryIncidentResponsibilityMeta();
  DeliveryIncidentResponsibility get DRIVER_AT_FAULT => _$DRIVER_AT_FAULT;
  DeliveryIncidentResponsibility get CUSTOMER => _$CUSTOMER;
  DeliveryIncidentResponsibility get VENDOR => _$VENDOR;
  DeliveryIncidentResponsibility get EXTERNAL_OR_SYSTEM => _$EXTERNAL_OR_SYSTEM;
  DeliveryIncidentResponsibility get UNDER_REVIEW => _$UNDER_REVIEW;
  DeliveryIncidentResponsibility valueOf(String name) => _$valueOf(name);
  BuiltSet<DeliveryIncidentResponsibility> get values => _$values;
}

mixin _$DeliveryIncidentResponsibilityMixin {
  // ignore: non_constant_identifier_names
  _$DeliveryIncidentResponsibilityMeta get DeliveryIncidentResponsibility =>
      const _$DeliveryIncidentResponsibilityMeta();
}

Serializer<DeliveryIncidentResponsibility>
_$deliveryIncidentResponsibilitySerializer =
    _$DeliveryIncidentResponsibilitySerializer();

class _$DeliveryIncidentResponsibilitySerializer
    implements PrimitiveSerializer<DeliveryIncidentResponsibility> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DRIVER_AT_FAULT': 'DRIVER_AT_FAULT',
    'CUSTOMER': 'CUSTOMER',
    'VENDOR': 'VENDOR',
    'EXTERNAL_OR_SYSTEM': 'EXTERNAL_OR_SYSTEM',
    'UNDER_REVIEW': 'UNDER_REVIEW',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DRIVER_AT_FAULT': 'DRIVER_AT_FAULT',
    'CUSTOMER': 'CUSTOMER',
    'VENDOR': 'VENDOR',
    'EXTERNAL_OR_SYSTEM': 'EXTERNAL_OR_SYSTEM',
    'UNDER_REVIEW': 'UNDER_REVIEW',
  };

  @override
  final Iterable<Type> types = const <Type>[DeliveryIncidentResponsibility];
  @override
  final String wireName = 'DeliveryIncidentResponsibility';

  @override
  Object serialize(
    Serializers serializers,
    DeliveryIncidentResponsibility object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DeliveryIncidentResponsibility deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DeliveryIncidentResponsibility.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
