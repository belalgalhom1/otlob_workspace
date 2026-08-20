// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NotificationType _$ORDER_UPDATE = const NotificationType._(
  'ORDER_UPDATE',
);
const NotificationType _$CHAT_MESSAGE = const NotificationType._(
  'CHAT_MESSAGE',
);
const NotificationType _$PROMOTION = const NotificationType._('PROMOTION');
const NotificationType _$SYSTEM = const NotificationType._('SYSTEM');
const NotificationType _$PAYMENT = const NotificationType._('PAYMENT');
const NotificationType _$TICKET_UPDATE = const NotificationType._(
  'TICKET_UPDATE',
);
const NotificationType _$ANNOUNCEMENT = const NotificationType._(
  'ANNOUNCEMENT',
);

NotificationType _$valueOf(String name) {
  switch (name) {
    case 'ORDER_UPDATE':
      return _$ORDER_UPDATE;
    case 'CHAT_MESSAGE':
      return _$CHAT_MESSAGE;
    case 'PROMOTION':
      return _$PROMOTION;
    case 'SYSTEM':
      return _$SYSTEM;
    case 'PAYMENT':
      return _$PAYMENT;
    case 'TICKET_UPDATE':
      return _$TICKET_UPDATE;
    case 'ANNOUNCEMENT':
      return _$ANNOUNCEMENT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<NotificationType> _$values =
    BuiltSet<NotificationType>(const <NotificationType>[
      _$ORDER_UPDATE,
      _$CHAT_MESSAGE,
      _$PROMOTION,
      _$SYSTEM,
      _$PAYMENT,
      _$TICKET_UPDATE,
      _$ANNOUNCEMENT,
    ]);

class _$NotificationTypeMeta {
  const _$NotificationTypeMeta();
  NotificationType get ORDER_UPDATE => _$ORDER_UPDATE;
  NotificationType get CHAT_MESSAGE => _$CHAT_MESSAGE;
  NotificationType get PROMOTION => _$PROMOTION;
  NotificationType get SYSTEM => _$SYSTEM;
  NotificationType get PAYMENT => _$PAYMENT;
  NotificationType get TICKET_UPDATE => _$TICKET_UPDATE;
  NotificationType get ANNOUNCEMENT => _$ANNOUNCEMENT;
  NotificationType valueOf(String name) => _$valueOf(name);
  BuiltSet<NotificationType> get values => _$values;
}

mixin _$NotificationTypeMixin {
  // ignore: non_constant_identifier_names
  _$NotificationTypeMeta get NotificationType => const _$NotificationTypeMeta();
}

Serializer<NotificationType> _$notificationTypeSerializer =
    _$NotificationTypeSerializer();

class _$NotificationTypeSerializer
    implements PrimitiveSerializer<NotificationType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ORDER_UPDATE': 'ORDER_UPDATE',
    'CHAT_MESSAGE': 'CHAT_MESSAGE',
    'PROMOTION': 'PROMOTION',
    'SYSTEM': 'SYSTEM',
    'PAYMENT': 'PAYMENT',
    'TICKET_UPDATE': 'TICKET_UPDATE',
    'ANNOUNCEMENT': 'ANNOUNCEMENT',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ORDER_UPDATE': 'ORDER_UPDATE',
    'CHAT_MESSAGE': 'CHAT_MESSAGE',
    'PROMOTION': 'PROMOTION',
    'SYSTEM': 'SYSTEM',
    'PAYMENT': 'PAYMENT',
    'TICKET_UPDATE': 'TICKET_UPDATE',
    'ANNOUNCEMENT': 'ANNOUNCEMENT',
  };

  @override
  final Iterable<Type> types = const <Type>[NotificationType];
  @override
  final String wireName = 'NotificationType';

  @override
  Object serialize(
    Serializers serializers,
    NotificationType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  NotificationType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => NotificationType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
