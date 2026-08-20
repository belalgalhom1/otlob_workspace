// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_priority.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TicketPriority _$LOW = const TicketPriority._('LOW');
const TicketPriority _$MEDIUM = const TicketPriority._('MEDIUM');
const TicketPriority _$HIGH = const TicketPriority._('HIGH');
const TicketPriority _$URGENT = const TicketPriority._('URGENT');

TicketPriority _$valueOf(String name) {
  switch (name) {
    case 'LOW':
      return _$LOW;
    case 'MEDIUM':
      return _$MEDIUM;
    case 'HIGH':
      return _$HIGH;
    case 'URGENT':
      return _$URGENT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TicketPriority> _$values = BuiltSet<TicketPriority>(
  const <TicketPriority>[_$LOW, _$MEDIUM, _$HIGH, _$URGENT],
);

class _$TicketPriorityMeta {
  const _$TicketPriorityMeta();
  TicketPriority get LOW => _$LOW;
  TicketPriority get MEDIUM => _$MEDIUM;
  TicketPriority get HIGH => _$HIGH;
  TicketPriority get URGENT => _$URGENT;
  TicketPriority valueOf(String name) => _$valueOf(name);
  BuiltSet<TicketPriority> get values => _$values;
}

mixin _$TicketPriorityMixin {
  // ignore: non_constant_identifier_names
  _$TicketPriorityMeta get TicketPriority => const _$TicketPriorityMeta();
}

Serializer<TicketPriority> _$ticketPrioritySerializer =
    _$TicketPrioritySerializer();

class _$TicketPrioritySerializer
    implements PrimitiveSerializer<TicketPriority> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'LOW': 'LOW',
    'MEDIUM': 'MEDIUM',
    'HIGH': 'HIGH',
    'URGENT': 'URGENT',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'LOW': 'LOW',
    'MEDIUM': 'MEDIUM',
    'HIGH': 'HIGH',
    'URGENT': 'URGENT',
  };

  @override
  final Iterable<Type> types = const <Type>[TicketPriority];
  @override
  final String wireName = 'TicketPriority';

  @override
  Object serialize(
    Serializers serializers,
    TicketPriority object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TicketPriority deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TicketPriority.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
