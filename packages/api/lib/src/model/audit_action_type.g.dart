// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_action_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AuditActionType _$CREATE = const AuditActionType._('CREATE');
const AuditActionType _$UPDATE = const AuditActionType._('UPDATE');
const AuditActionType _$DELETE = const AuditActionType._('DELETE');
const AuditActionType _$OTHER = const AuditActionType._('OTHER');

AuditActionType _$valueOf(String name) {
  switch (name) {
    case 'CREATE':
      return _$CREATE;
    case 'UPDATE':
      return _$UPDATE;
    case 'DELETE':
      return _$DELETE;
    case 'OTHER':
      return _$OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AuditActionType> _$values = BuiltSet<AuditActionType>(
  const <AuditActionType>[_$CREATE, _$UPDATE, _$DELETE, _$OTHER],
);

class _$AuditActionTypeMeta {
  const _$AuditActionTypeMeta();
  AuditActionType get CREATE => _$CREATE;
  AuditActionType get UPDATE => _$UPDATE;
  AuditActionType get DELETE => _$DELETE;
  AuditActionType get OTHER => _$OTHER;
  AuditActionType valueOf(String name) => _$valueOf(name);
  BuiltSet<AuditActionType> get values => _$values;
}

mixin _$AuditActionTypeMixin {
  // ignore: non_constant_identifier_names
  _$AuditActionTypeMeta get AuditActionType => const _$AuditActionTypeMeta();
}

Serializer<AuditActionType> _$auditActionTypeSerializer =
    _$AuditActionTypeSerializer();

class _$AuditActionTypeSerializer
    implements PrimitiveSerializer<AuditActionType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CREATE': 'CREATE',
    'UPDATE': 'UPDATE',
    'DELETE': 'DELETE',
    'OTHER': 'OTHER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CREATE': 'CREATE',
    'UPDATE': 'UPDATE',
    'DELETE': 'DELETE',
    'OTHER': 'OTHER',
  };

  @override
  final Iterable<Type> types = const <Type>[AuditActionType];
  @override
  final String wireName = 'AuditActionType';

  @override
  Object serialize(
    Serializers serializers,
    AuditActionType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AuditActionType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AuditActionType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
