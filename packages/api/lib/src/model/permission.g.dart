// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Permission _$MANAGE_ORDERS = const Permission._('MANAGE_ORDERS');
const Permission _$MANAGE_PRODUCTS = const Permission._('MANAGE_PRODUCTS');
const Permission _$MANAGE_VENDORS = const Permission._('MANAGE_VENDORS');
const Permission _$MANAGE_DRIVERS = const Permission._('MANAGE_DRIVERS');
const Permission _$MANAGE_CUSTOMERS = const Permission._('MANAGE_CUSTOMERS');
const Permission _$MANAGE_TICKETS = const Permission._('MANAGE_TICKETS');
const Permission _$MANAGE_CONVERSATIONS = const Permission._(
  'MANAGE_CONVERSATIONS',
);
const Permission _$VIEW_STATISTICS = const Permission._('VIEW_STATISTICS');
const Permission _$MANAGE_SETTINGS = const Permission._('MANAGE_SETTINGS');
const Permission _$MANAGE_USERS = const Permission._('MANAGE_USERS');
const Permission _$VIEW_FINANCIALS = const Permission._('VIEW_FINANCIALS');
const Permission _$MANAGE_FINANCE = const Permission._('MANAGE_FINANCE');
const Permission _$MANAGE_PROMOTIONS = const Permission._('MANAGE_PROMOTIONS');
const Permission _$MANAGE_ANNOUNCEMENTS = const Permission._(
  'MANAGE_ANNOUNCEMENTS',
);
const Permission _$VIEW_AUDIT_LOGS = const Permission._('VIEW_AUDIT_LOGS');

Permission _$valueOf(String name) {
  switch (name) {
    case 'MANAGE_ORDERS':
      return _$MANAGE_ORDERS;
    case 'MANAGE_PRODUCTS':
      return _$MANAGE_PRODUCTS;
    case 'MANAGE_VENDORS':
      return _$MANAGE_VENDORS;
    case 'MANAGE_DRIVERS':
      return _$MANAGE_DRIVERS;
    case 'MANAGE_CUSTOMERS':
      return _$MANAGE_CUSTOMERS;
    case 'MANAGE_TICKETS':
      return _$MANAGE_TICKETS;
    case 'MANAGE_CONVERSATIONS':
      return _$MANAGE_CONVERSATIONS;
    case 'VIEW_STATISTICS':
      return _$VIEW_STATISTICS;
    case 'MANAGE_SETTINGS':
      return _$MANAGE_SETTINGS;
    case 'MANAGE_USERS':
      return _$MANAGE_USERS;
    case 'VIEW_FINANCIALS':
      return _$VIEW_FINANCIALS;
    case 'MANAGE_FINANCE':
      return _$MANAGE_FINANCE;
    case 'MANAGE_PROMOTIONS':
      return _$MANAGE_PROMOTIONS;
    case 'MANAGE_ANNOUNCEMENTS':
      return _$MANAGE_ANNOUNCEMENTS;
    case 'VIEW_AUDIT_LOGS':
      return _$VIEW_AUDIT_LOGS;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<Permission> _$values = BuiltSet<Permission>(const <Permission>[
  _$MANAGE_ORDERS,
  _$MANAGE_PRODUCTS,
  _$MANAGE_VENDORS,
  _$MANAGE_DRIVERS,
  _$MANAGE_CUSTOMERS,
  _$MANAGE_TICKETS,
  _$MANAGE_CONVERSATIONS,
  _$VIEW_STATISTICS,
  _$MANAGE_SETTINGS,
  _$MANAGE_USERS,
  _$VIEW_FINANCIALS,
  _$MANAGE_FINANCE,
  _$MANAGE_PROMOTIONS,
  _$MANAGE_ANNOUNCEMENTS,
  _$VIEW_AUDIT_LOGS,
]);

class _$PermissionMeta {
  const _$PermissionMeta();
  Permission get MANAGE_ORDERS => _$MANAGE_ORDERS;
  Permission get MANAGE_PRODUCTS => _$MANAGE_PRODUCTS;
  Permission get MANAGE_VENDORS => _$MANAGE_VENDORS;
  Permission get MANAGE_DRIVERS => _$MANAGE_DRIVERS;
  Permission get MANAGE_CUSTOMERS => _$MANAGE_CUSTOMERS;
  Permission get MANAGE_TICKETS => _$MANAGE_TICKETS;
  Permission get MANAGE_CONVERSATIONS => _$MANAGE_CONVERSATIONS;
  Permission get VIEW_STATISTICS => _$VIEW_STATISTICS;
  Permission get MANAGE_SETTINGS => _$MANAGE_SETTINGS;
  Permission get MANAGE_USERS => _$MANAGE_USERS;
  Permission get VIEW_FINANCIALS => _$VIEW_FINANCIALS;
  Permission get MANAGE_FINANCE => _$MANAGE_FINANCE;
  Permission get MANAGE_PROMOTIONS => _$MANAGE_PROMOTIONS;
  Permission get MANAGE_ANNOUNCEMENTS => _$MANAGE_ANNOUNCEMENTS;
  Permission get VIEW_AUDIT_LOGS => _$VIEW_AUDIT_LOGS;
  Permission valueOf(String name) => _$valueOf(name);
  BuiltSet<Permission> get values => _$values;
}

mixin _$PermissionMixin {
  // ignore: non_constant_identifier_names
  _$PermissionMeta get Permission => const _$PermissionMeta();
}

Serializer<Permission> _$permissionSerializer = _$PermissionSerializer();

class _$PermissionSerializer implements PrimitiveSerializer<Permission> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'MANAGE_ORDERS': 'MANAGE_ORDERS',
    'MANAGE_PRODUCTS': 'MANAGE_PRODUCTS',
    'MANAGE_VENDORS': 'MANAGE_VENDORS',
    'MANAGE_DRIVERS': 'MANAGE_DRIVERS',
    'MANAGE_CUSTOMERS': 'MANAGE_CUSTOMERS',
    'MANAGE_TICKETS': 'MANAGE_TICKETS',
    'MANAGE_CONVERSATIONS': 'MANAGE_CONVERSATIONS',
    'VIEW_STATISTICS': 'VIEW_STATISTICS',
    'MANAGE_SETTINGS': 'MANAGE_SETTINGS',
    'MANAGE_USERS': 'MANAGE_USERS',
    'VIEW_FINANCIALS': 'VIEW_FINANCIALS',
    'MANAGE_FINANCE': 'MANAGE_FINANCE',
    'MANAGE_PROMOTIONS': 'MANAGE_PROMOTIONS',
    'MANAGE_ANNOUNCEMENTS': 'MANAGE_ANNOUNCEMENTS',
    'VIEW_AUDIT_LOGS': 'VIEW_AUDIT_LOGS',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MANAGE_ORDERS': 'MANAGE_ORDERS',
    'MANAGE_PRODUCTS': 'MANAGE_PRODUCTS',
    'MANAGE_VENDORS': 'MANAGE_VENDORS',
    'MANAGE_DRIVERS': 'MANAGE_DRIVERS',
    'MANAGE_CUSTOMERS': 'MANAGE_CUSTOMERS',
    'MANAGE_TICKETS': 'MANAGE_TICKETS',
    'MANAGE_CONVERSATIONS': 'MANAGE_CONVERSATIONS',
    'VIEW_STATISTICS': 'VIEW_STATISTICS',
    'MANAGE_SETTINGS': 'MANAGE_SETTINGS',
    'MANAGE_USERS': 'MANAGE_USERS',
    'VIEW_FINANCIALS': 'VIEW_FINANCIALS',
    'MANAGE_FINANCE': 'MANAGE_FINANCE',
    'MANAGE_PROMOTIONS': 'MANAGE_PROMOTIONS',
    'MANAGE_ANNOUNCEMENTS': 'MANAGE_ANNOUNCEMENTS',
    'VIEW_AUDIT_LOGS': 'VIEW_AUDIT_LOGS',
  };

  @override
  final Iterable<Type> types = const <Type>[Permission];
  @override
  final String wireName = 'Permission';

  @override
  Object serialize(
    Serializers serializers,
    Permission object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  Permission deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Permission.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
