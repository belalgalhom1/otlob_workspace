// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ConversationType _$ORDER = const ConversationType._('ORDER');
const ConversationType _$SUPPORT = const ConversationType._('SUPPORT');
const ConversationType _$VENDOR = const ConversationType._('VENDOR');

ConversationType _$valueOf(String name) {
  switch (name) {
    case 'ORDER':
      return _$ORDER;
    case 'SUPPORT':
      return _$SUPPORT;
    case 'VENDOR':
      return _$VENDOR;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ConversationType> _$values = BuiltSet<ConversationType>(
  const <ConversationType>[_$ORDER, _$SUPPORT, _$VENDOR],
);

class _$ConversationTypeMeta {
  const _$ConversationTypeMeta();
  ConversationType get ORDER => _$ORDER;
  ConversationType get SUPPORT => _$SUPPORT;
  ConversationType get VENDOR => _$VENDOR;
  ConversationType valueOf(String name) => _$valueOf(name);
  BuiltSet<ConversationType> get values => _$values;
}

mixin _$ConversationTypeMixin {
  // ignore: non_constant_identifier_names
  _$ConversationTypeMeta get ConversationType => const _$ConversationTypeMeta();
}

Serializer<ConversationType> _$conversationTypeSerializer =
    _$ConversationTypeSerializer();

class _$ConversationTypeSerializer
    implements PrimitiveSerializer<ConversationType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ORDER': 'ORDER',
    'SUPPORT': 'SUPPORT',
    'VENDOR': 'VENDOR',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ORDER': 'ORDER',
    'SUPPORT': 'SUPPORT',
    'VENDOR': 'VENDOR',
  };

  @override
  final Iterable<Type> types = const <Type>[ConversationType];
  @override
  final String wireName = 'ConversationType';

  @override
  Object serialize(
    Serializers serializers,
    ConversationType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ConversationType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ConversationType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
