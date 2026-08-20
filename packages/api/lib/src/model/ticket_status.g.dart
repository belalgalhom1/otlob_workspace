// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TicketStatus _$OPEN = const TicketStatus._('OPEN');
const TicketStatus _$IN_PROGRESS = const TicketStatus._('IN_PROGRESS');
const TicketStatus _$WAITING_ON_USER = const TicketStatus._('WAITING_ON_USER');
const TicketStatus _$ESCALATED = const TicketStatus._('ESCALATED');
const TicketStatus _$RESOLVED = const TicketStatus._('RESOLVED');
const TicketStatus _$CLOSED = const TicketStatus._('CLOSED');

TicketStatus _$valueOf(String name) {
  switch (name) {
    case 'OPEN':
      return _$OPEN;
    case 'IN_PROGRESS':
      return _$IN_PROGRESS;
    case 'WAITING_ON_USER':
      return _$WAITING_ON_USER;
    case 'ESCALATED':
      return _$ESCALATED;
    case 'RESOLVED':
      return _$RESOLVED;
    case 'CLOSED':
      return _$CLOSED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TicketStatus> _$values = BuiltSet<TicketStatus>(
  const <TicketStatus>[
    _$OPEN,
    _$IN_PROGRESS,
    _$WAITING_ON_USER,
    _$ESCALATED,
    _$RESOLVED,
    _$CLOSED,
  ],
);

class _$TicketStatusMeta {
  const _$TicketStatusMeta();
  TicketStatus get OPEN => _$OPEN;
  TicketStatus get IN_PROGRESS => _$IN_PROGRESS;
  TicketStatus get WAITING_ON_USER => _$WAITING_ON_USER;
  TicketStatus get ESCALATED => _$ESCALATED;
  TicketStatus get RESOLVED => _$RESOLVED;
  TicketStatus get CLOSED => _$CLOSED;
  TicketStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<TicketStatus> get values => _$values;
}

mixin _$TicketStatusMixin {
  // ignore: non_constant_identifier_names
  _$TicketStatusMeta get TicketStatus => const _$TicketStatusMeta();
}

Serializer<TicketStatus> _$ticketStatusSerializer = _$TicketStatusSerializer();

class _$TicketStatusSerializer implements PrimitiveSerializer<TicketStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OPEN': 'OPEN',
    'IN_PROGRESS': 'IN_PROGRESS',
    'WAITING_ON_USER': 'WAITING_ON_USER',
    'ESCALATED': 'ESCALATED',
    'RESOLVED': 'RESOLVED',
    'CLOSED': 'CLOSED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OPEN': 'OPEN',
    'IN_PROGRESS': 'IN_PROGRESS',
    'WAITING_ON_USER': 'WAITING_ON_USER',
    'ESCALATED': 'ESCALATED',
    'RESOLVED': 'RESOLVED',
    'CLOSED': 'CLOSED',
  };

  @override
  final Iterable<Type> types = const <Type>[TicketStatus];
  @override
  final String wireName = 'TicketStatus';

  @override
  Object serialize(
    Serializers serializers,
    TicketStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TicketStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TicketStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
