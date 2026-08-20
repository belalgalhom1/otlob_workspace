//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'permission.g.dart';

class Permission extends EnumClass {

  @BuiltValueEnumConst(wireName: r'MANAGE_ORDERS')
  static const Permission MANAGE_ORDERS = _$MANAGE_ORDERS;
  @BuiltValueEnumConst(wireName: r'MANAGE_PRODUCTS')
  static const Permission MANAGE_PRODUCTS = _$MANAGE_PRODUCTS;
  @BuiltValueEnumConst(wireName: r'MANAGE_VENDORS')
  static const Permission MANAGE_VENDORS = _$MANAGE_VENDORS;
  @BuiltValueEnumConst(wireName: r'MANAGE_DRIVERS')
  static const Permission MANAGE_DRIVERS = _$MANAGE_DRIVERS;
  @BuiltValueEnumConst(wireName: r'MANAGE_CUSTOMERS')
  static const Permission MANAGE_CUSTOMERS = _$MANAGE_CUSTOMERS;
  @BuiltValueEnumConst(wireName: r'MANAGE_TICKETS')
  static const Permission MANAGE_TICKETS = _$MANAGE_TICKETS;
  @BuiltValueEnumConst(wireName: r'MANAGE_CONVERSATIONS')
  static const Permission MANAGE_CONVERSATIONS = _$MANAGE_CONVERSATIONS;
  @BuiltValueEnumConst(wireName: r'VIEW_STATISTICS')
  static const Permission VIEW_STATISTICS = _$VIEW_STATISTICS;
  @BuiltValueEnumConst(wireName: r'MANAGE_SETTINGS')
  static const Permission MANAGE_SETTINGS = _$MANAGE_SETTINGS;
  @BuiltValueEnumConst(wireName: r'MANAGE_USERS')
  static const Permission MANAGE_USERS = _$MANAGE_USERS;
  @BuiltValueEnumConst(wireName: r'VIEW_FINANCIALS')
  static const Permission VIEW_FINANCIALS = _$VIEW_FINANCIALS;
  @BuiltValueEnumConst(wireName: r'MANAGE_FINANCE')
  static const Permission MANAGE_FINANCE = _$MANAGE_FINANCE;
  @BuiltValueEnumConst(wireName: r'MANAGE_PROMOTIONS')
  static const Permission MANAGE_PROMOTIONS = _$MANAGE_PROMOTIONS;
  @BuiltValueEnumConst(wireName: r'MANAGE_ANNOUNCEMENTS')
  static const Permission MANAGE_ANNOUNCEMENTS = _$MANAGE_ANNOUNCEMENTS;
  @BuiltValueEnumConst(wireName: r'VIEW_AUDIT_LOGS')
  static const Permission VIEW_AUDIT_LOGS = _$VIEW_AUDIT_LOGS;

  static Serializer<Permission> get serializer => _$permissionSerializer;

  const Permission._(String name): super(name);

  static BuiltSet<Permission> get values => _$values;
  static Permission valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class PermissionMixin = Object with _$PermissionMixin;

