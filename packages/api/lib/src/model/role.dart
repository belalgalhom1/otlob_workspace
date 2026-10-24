//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'role.g.dart';

class Role extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CUSTOMER')
  static const Role CUSTOMER = _$CUSTOMER;
  @BuiltValueEnumConst(wireName: r'DRIVER')
  static const Role DRIVER = _$DRIVER;
  @BuiltValueEnumConst(wireName: r'DRIVER_MANAGER')
  static const Role DRIVER_MANAGER = _$DRIVER_MANAGER;
  @BuiltValueEnumConst(wireName: r'VENDOR_MEMBER')
  static const Role VENDOR_MEMBER = _$VENDOR_MEMBER;
  @BuiltValueEnumConst(wireName: r'ADMIN')
  static const Role ADMIN = _$ADMIN;
  @BuiltValueEnumConst(wireName: r'SUPER_ADMIN')
  static const Role SUPER_ADMIN = _$SUPER_ADMIN;

  static Serializer<Role> get serializer => _$roleSerializer;

  const Role._(String name): super(name);

  static BuiltSet<Role> get values => _$values;
  static Role valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class RoleMixin = Object with _$RoleMixin;

