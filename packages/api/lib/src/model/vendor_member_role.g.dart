// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_member_role.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VendorMemberRole _$OWNER = const VendorMemberRole._('OWNER');
const VendorMemberRole _$MANAGER = const VendorMemberRole._('MANAGER');
const VendorMemberRole _$STAFF = const VendorMemberRole._('STAFF');

VendorMemberRole _$valueOf(String name) {
  switch (name) {
    case 'OWNER':
      return _$OWNER;
    case 'MANAGER':
      return _$MANAGER;
    case 'STAFF':
      return _$STAFF;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<VendorMemberRole> _$values = BuiltSet<VendorMemberRole>(
  const <VendorMemberRole>[_$OWNER, _$MANAGER, _$STAFF],
);

class _$VendorMemberRoleMeta {
  const _$VendorMemberRoleMeta();
  VendorMemberRole get OWNER => _$OWNER;
  VendorMemberRole get MANAGER => _$MANAGER;
  VendorMemberRole get STAFF => _$STAFF;
  VendorMemberRole valueOf(String name) => _$valueOf(name);
  BuiltSet<VendorMemberRole> get values => _$values;
}

mixin _$VendorMemberRoleMixin {
  // ignore: non_constant_identifier_names
  _$VendorMemberRoleMeta get VendorMemberRole => const _$VendorMemberRoleMeta();
}

Serializer<VendorMemberRole> _$vendorMemberRoleSerializer =
    _$VendorMemberRoleSerializer();

class _$VendorMemberRoleSerializer
    implements PrimitiveSerializer<VendorMemberRole> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OWNER': 'OWNER',
    'MANAGER': 'MANAGER',
    'STAFF': 'STAFF',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OWNER': 'OWNER',
    'MANAGER': 'MANAGER',
    'STAFF': 'STAFF',
  };

  @override
  final Iterable<Type> types = const <Type>[VendorMemberRole];
  @override
  final String wireName = 'VendorMemberRole';

  @override
  Object serialize(
    Serializers serializers,
    VendorMemberRole object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  VendorMemberRole deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => VendorMemberRole.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
