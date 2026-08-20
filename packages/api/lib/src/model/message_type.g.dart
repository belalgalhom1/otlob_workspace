// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MessageType _$TEXT = const MessageType._('TEXT');
const MessageType _$IMAGE = const MessageType._('IMAGE');
const MessageType _$VIDEO = const MessageType._('VIDEO');
const MessageType _$AUDIO = const MessageType._('AUDIO');
const MessageType _$LOCATION = const MessageType._('LOCATION');
const MessageType _$SYSTEM = const MessageType._('SYSTEM');
const MessageType _$PRODUCT = const MessageType._('PRODUCT');

MessageType _$valueOf(String name) {
  switch (name) {
    case 'TEXT':
      return _$TEXT;
    case 'IMAGE':
      return _$IMAGE;
    case 'VIDEO':
      return _$VIDEO;
    case 'AUDIO':
      return _$AUDIO;
    case 'LOCATION':
      return _$LOCATION;
    case 'SYSTEM':
      return _$SYSTEM;
    case 'PRODUCT':
      return _$PRODUCT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<MessageType> _$values = BuiltSet<MessageType>(
  const <MessageType>[
    _$TEXT,
    _$IMAGE,
    _$VIDEO,
    _$AUDIO,
    _$LOCATION,
    _$SYSTEM,
    _$PRODUCT,
  ],
);

class _$MessageTypeMeta {
  const _$MessageTypeMeta();
  MessageType get TEXT => _$TEXT;
  MessageType get IMAGE => _$IMAGE;
  MessageType get VIDEO => _$VIDEO;
  MessageType get AUDIO => _$AUDIO;
  MessageType get LOCATION => _$LOCATION;
  MessageType get SYSTEM => _$SYSTEM;
  MessageType get PRODUCT => _$PRODUCT;
  MessageType valueOf(String name) => _$valueOf(name);
  BuiltSet<MessageType> get values => _$values;
}

mixin _$MessageTypeMixin {
  // ignore: non_constant_identifier_names
  _$MessageTypeMeta get MessageType => const _$MessageTypeMeta();
}

Serializer<MessageType> _$messageTypeSerializer = _$MessageTypeSerializer();

class _$MessageTypeSerializer implements PrimitiveSerializer<MessageType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'TEXT': 'TEXT',
    'IMAGE': 'IMAGE',
    'VIDEO': 'VIDEO',
    'AUDIO': 'AUDIO',
    'LOCATION': 'LOCATION',
    'SYSTEM': 'SYSTEM',
    'PRODUCT': 'PRODUCT',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'TEXT': 'TEXT',
    'IMAGE': 'IMAGE',
    'VIDEO': 'VIDEO',
    'AUDIO': 'AUDIO',
    'LOCATION': 'LOCATION',
    'SYSTEM': 'SYSTEM',
    'PRODUCT': 'PRODUCT',
  };

  @override
  final Iterable<Type> types = const <Type>[MessageType];
  @override
  final String wireName = 'MessageType';

  @override
  Object serialize(
    Serializers serializers,
    MessageType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  MessageType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => MessageType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
