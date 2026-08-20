//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vendor_member_role.g.dart';

class VendorMemberRole extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWNER')
  static const VendorMemberRole OWNER = _$OWNER;
  @BuiltValueEnumConst(wireName: r'MANAGER')
  static const VendorMemberRole MANAGER = _$MANAGER;
  @BuiltValueEnumConst(wireName: r'STAFF')
  static const VendorMemberRole STAFF = _$STAFF;

  static Serializer<VendorMemberRole> get serializer => _$vendorMemberRoleSerializer;

  const VendorMemberRole._(String name): super(name);

  static BuiltSet<VendorMemberRole> get values => _$values;
  static VendorMemberRole valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class VendorMemberRoleMixin = Object with _$VendorMemberRoleMixin;

