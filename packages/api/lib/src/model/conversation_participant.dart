//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/conversation.dart';
import 'package:api/src/model/user.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'conversation_participant.g.dart';

/// ConversationParticipant
///
/// Properties:
/// * [conversationId] 
/// * [userId] 
/// * [joinedAt] 
/// * [lastReadAt] 
/// * [conversation] 
/// * [user] 
@BuiltValue()
abstract class ConversationParticipant implements Built<ConversationParticipant, ConversationParticipantBuilder> {
  @BuiltValueField(wireName: r'conversationId')
  String get conversationId;

  @BuiltValueField(wireName: r'userId')
  String get userId;

  @BuiltValueField(wireName: r'joinedAt')
  DateTime get joinedAt;

  @BuiltValueField(wireName: r'lastReadAt')
  DateTime get lastReadAt;

  @BuiltValueField(wireName: r'conversation')
  JsonObject? get conversation;

  @BuiltValueField(wireName: r'user')
  JsonObject? get user;

  ConversationParticipant._();

  factory ConversationParticipant([void updates(ConversationParticipantBuilder b)]) = _$ConversationParticipant;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConversationParticipantBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConversationParticipant> get serializer => _$ConversationParticipantSerializer();
}

class _$ConversationParticipantSerializer implements PrimitiveSerializer<ConversationParticipant> {
  @override
  final Iterable<Type> types = const [ConversationParticipant, _$ConversationParticipant];

  @override
  final String wireName = r'ConversationParticipant';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConversationParticipant object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'conversationId';
    yield serializers.serialize(
      object.conversationId,
      specifiedType: const FullType(String),
    );
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'joinedAt';
    yield serializers.serialize(
      object.joinedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'lastReadAt';
    yield serializers.serialize(
      object.lastReadAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'conversation';
    yield serializers.serialize(
      object.conversation,
      specifiedType: const FullType(Conversation),
    );
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(User),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConversationParticipant object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConversationParticipantBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'conversationId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.conversationId = valueDes;
          break;
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'joinedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.joinedAt = valueDes;
          break;
        case r'lastReadAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.lastReadAt = valueDes;
          break;
        case r'conversation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.conversation = valueDes;
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.user = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConversationParticipant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConversationParticipantBuilder();
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

