// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Role _$CUSTOMER = const Role._('CUSTOMER');
const Role _$DRIVER = const Role._('DRIVER');
const Role _$VENDOR_MEMBER = const Role._('VENDOR_MEMBER');
const Role _$ADMIN = const Role._('ADMIN');
const Role _$SUPER_ADMIN = const Role._('SUPER_ADMIN');

Role _$valueOf(String name) {
  switch (name) {
    case 'CUSTOMER':
      return _$CUSTOMER;
    case 'DRIVER':
      return _$DRIVER;
    case 'VENDOR_MEMBER':
      return _$VENDOR_MEMBER;
    case 'ADMIN':
      return _$ADMIN;
    case 'SUPER_ADMIN':
      return _$SUPER_ADMIN;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<Role> _$values = BuiltSet<Role>(const <Role>[
  _$CUSTOMER,
  _$DRIVER,
  _$VENDOR_MEMBER,
  _$ADMIN,
  _$SUPER_ADMIN,
]);

class _$RoleMeta {
  const _$RoleMeta();
  Role get CUSTOMER => _$CUSTOMER;
  Role get DRIVER => _$DRIVER;
  Role get VENDOR_MEMBER => _$VENDOR_MEMBER;
  Role get ADMIN => _$ADMIN;
  Role get SUPER_ADMIN => _$SUPER_ADMIN;
  Role valueOf(String name) => _$valueOf(name);
  BuiltSet<Role> get values => _$values;
}

mixin _$RoleMixin {
  // ignore: non_constant_identifier_names
  _$RoleMeta get Role => const _$RoleMeta();
}

Serializer<Role> _$roleSerializer = _$RoleSerializer();

class _$RoleSerializer implements PrimitiveSerializer<Role> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CUSTOMER': 'CUSTOMER',
    'DRIVER': 'DRIVER',
    'VENDOR_MEMBER': 'VENDOR_MEMBER',
    'ADMIN': 'ADMIN',
    'SUPER_ADMIN': 'SUPER_ADMIN',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CUSTOMER': 'CUSTOMER',
    'DRIVER': 'DRIVER',
    'VENDOR_MEMBER': 'VENDOR_MEMBER',
    'ADMIN': 'ADMIN',
    'SUPER_ADMIN': 'SUPER_ADMIN',
  };

  @override
  final Iterable<Type> types = const <Type>[Role];
  @override
  final String wireName = 'Role';

  @override
  Object serialize(
    Serializers serializers,
    Role object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  Role deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Role.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
