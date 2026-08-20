// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ConversationStatus _$OPEN = const ConversationStatus._('OPEN');
const ConversationStatus _$CLOSED = const ConversationStatus._('CLOSED');
const ConversationStatus _$ARCHIVED = const ConversationStatus._('ARCHIVED');

ConversationStatus _$valueOf(String name) {
  switch (name) {
    case 'OPEN':
      return _$OPEN;
    case 'CLOSED':
      return _$CLOSED;
    case 'ARCHIVED':
      return _$ARCHIVED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ConversationStatus> _$values = BuiltSet<ConversationStatus>(
  const <ConversationStatus>[_$OPEN, _$CLOSED, _$ARCHIVED],
);

class _$ConversationStatusMeta {
  const _$ConversationStatusMeta();
  ConversationStatus get OPEN => _$OPEN;
  ConversationStatus get CLOSED => _$CLOSED;
  ConversationStatus get ARCHIVED => _$ARCHIVED;
  ConversationStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<ConversationStatus> get values => _$values;
}

mixin _$ConversationStatusMixin {
  // ignore: non_constant_identifier_names
  _$ConversationStatusMeta get ConversationStatus =>
      const _$ConversationStatusMeta();
}

Serializer<ConversationStatus> _$conversationStatusSerializer =
    _$ConversationStatusSerializer();

class _$ConversationStatusSerializer
    implements PrimitiveSerializer<ConversationStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OPEN': 'OPEN',
    'CLOSED': 'CLOSED',
    'ARCHIVED': 'ARCHIVED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OPEN': 'OPEN',
    'CLOSED': 'CLOSED',
    'ARCHIVED': 'ARCHIVED',
  };

  @override
  final Iterable<Type> types = const <Type>[ConversationStatus];
  @override
  final String wireName = 'ConversationStatus';

  @override
  Object serialize(
    Serializers serializers,
    ConversationStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ConversationStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ConversationStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
