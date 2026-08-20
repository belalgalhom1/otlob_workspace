//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/conversation.dart';
import 'package:api/src/model/user.dart';
import 'package:api/src/model/message_type.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'message.g.dart';

/// Message
///
/// Properties:
/// * [id] 
/// * [conversationId] 
/// * [senderId] 
/// * [type] 
/// * [text] 
/// * [mediaUrl] 
/// * [metadata] 
/// * [replyToId] 
/// * [createdAt] 
/// * [deletedAt] 
/// * [conversation] 
/// * [replyTo] 
/// * [replies] 
/// * [sender] 
@BuiltValue()
abstract class Message implements Built<Message, MessageBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'conversationId')
  String get conversationId;

  @BuiltValueField(wireName: r'senderId')
  String get senderId;

  @BuiltValueField(wireName: r'type')
  JsonObject? get type;
  // enum typeEnum {  TEXT,  IMAGE,  VIDEO,  AUDIO,  LOCATION,  SYSTEM,  PRODUCT,  };

  @BuiltValueField(wireName: r'text')
  String? get text;

  @BuiltValueField(wireName: r'mediaUrl')
  String? get mediaUrl;

  @BuiltValueField(wireName: r'metadata')
  JsonObject? get metadata;

  @BuiltValueField(wireName: r'replyToId')
  String? get replyToId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'deletedAt')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'conversation')
  JsonObject? get conversation;

  @BuiltValueField(wireName: r'replyTo')
  Message? get replyTo;

  @BuiltValueField(wireName: r'replies')
  BuiltList<Message> get replies;

  @BuiltValueField(wireName: r'sender')
  JsonObject? get sender;

  Message._();

  factory Message([void updates(MessageBuilder b)]) = _$Message;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MessageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Message> get serializer => _$MessageSerializer();
}

class _$MessageSerializer implements PrimitiveSerializer<Message> {
  @override
  final Iterable<Type> types = const [Message, _$Message];

  @override
  final String wireName = r'Message';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Message object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'conversationId';
    yield serializers.serialize(
      object.conversationId,
      specifiedType: const FullType(String),
    );
    yield r'senderId';
    yield serializers.serialize(
      object.senderId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(MessageType),
    );
    if (object.text != null) {
      yield r'text';
      yield serializers.serialize(
        object.text,
        specifiedType: const FullType(String),
      );
    }
    if (object.mediaUrl != null) {
      yield r'mediaUrl';
      yield serializers.serialize(
        object.mediaUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.metadata != null) {
      yield r'metadata';
      yield serializers.serialize(
        object.metadata,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.replyToId != null) {
      yield r'replyToId';
      yield serializers.serialize(
        object.replyToId,
        specifiedType: const FullType(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.deletedAt != null) {
      yield r'deletedAt';
      yield serializers.serialize(
        object.deletedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'conversation';
    yield serializers.serialize(
      object.conversation,
      specifiedType: const FullType(Conversation),
    );
    if (object.replyTo != null) {
      yield r'replyTo';
      yield serializers.serialize(
        object.replyTo,
        specifiedType: const FullType(Message),
      );
    }
    yield r'replies';
    yield serializers.serialize(
      object.replies,
      specifiedType: const FullType(BuiltList, [FullType(Message)]),
    );
    yield r'sender';
    yield serializers.serialize(
      object.sender,
      specifiedType: const FullType(User),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Message object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MessageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'conversationId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.conversationId = valueDes;
          break;
        case r'senderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.senderId = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.type = valueDes;
          break;
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        case r'mediaUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mediaUrl = valueDes;
          break;
        case r'metadata':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.metadata = valueDes;
          break;
        case r'replyToId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.replyToId = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'deletedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deletedAt = valueDes;
          break;
        case r'conversation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.conversation = valueDes;
          break;
        case r'replyTo':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Message),
          ) as Message;
          result.replyTo.replace(valueDes);
          break;
        case r'replies':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Message)]),
          ) as BuiltList<Message>;
          result.replies.replace(valueDes);
          break;
        case r'sender':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.sender = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Message deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MessageBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

