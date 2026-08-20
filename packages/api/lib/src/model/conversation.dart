//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/support_ticket.dart';
import 'package:api/src/model/vendor.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/conversation_participant.dart';
import 'package:api/src/model/conversation_status.dart';
import 'package:api/src/model/user.dart';
import 'package:api/src/model/message.dart';
import 'package:api/src/model/conversation_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'conversation.g.dart';

/// Conversation
///
/// Properties:
/// * [id] 
/// * [type] 
/// * [orderId] 
/// * [status] 
/// * [vendorId] 
/// * [creatorId] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [participants] 
/// * [creator] 
/// * [vendor] 
/// * [messages] 
/// * [supportTicket] 
@BuiltValue()
abstract class Conversation implements Built<Conversation, ConversationBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'type')
  JsonObject? get type;
  // enum typeEnum {  ORDER,  SUPPORT,  VENDOR,  };

  @BuiltValueField(wireName: r'orderId')
  String? get orderId;

  @BuiltValueField(wireName: r'status')
  JsonObject? get status;
  // enum statusEnum {  OPEN,  CLOSED,  ARCHIVED,  };

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  @BuiltValueField(wireName: r'creatorId')
  String? get creatorId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'participants')
  BuiltList<ConversationParticipant> get participants;

  @BuiltValueField(wireName: r'creator')
  JsonObject? get creator;

  @BuiltValueField(wireName: r'vendor')
  JsonObject? get vendor;

  @BuiltValueField(wireName: r'messages')
  BuiltList<Message> get messages;

  @BuiltValueField(wireName: r'supportTicket')
  JsonObject? get supportTicket;

  Conversation._();

  factory Conversation([void updates(ConversationBuilder b)]) = _$Conversation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConversationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Conversation> get serializer => _$ConversationSerializer();
}

class _$ConversationSerializer implements PrimitiveSerializer<Conversation> {
  @override
  final Iterable<Type> types = const [Conversation, _$Conversation];

  @override
  final String wireName = r'Conversation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Conversation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(ConversationType),
    );
    if (object.orderId != null) {
      yield r'orderId';
      yield serializers.serialize(
        object.orderId,
        specifiedType: const FullType(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ConversationStatus),
    );
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(String),
      );
    }
    if (object.creatorId != null) {
      yield r'creatorId';
      yield serializers.serialize(
        object.creatorId,
        specifiedType: const FullType(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'participants';
    yield serializers.serialize(
      object.participants,
      specifiedType: const FullType(BuiltList, [FullType(ConversationParticipant)]),
    );
    if (object.creator != null) {
      yield r'creator';
      yield serializers.serialize(
        object.creator,
        specifiedType: const FullType(User),
      );
    }
    if (object.vendor != null) {
      yield r'vendor';
      yield serializers.serialize(
        object.vendor,
        specifiedType: const FullType(Vendor),
      );
    }
    yield r'messages';
    yield serializers.serialize(
      object.messages,
      specifiedType: const FullType(BuiltList, [FullType(Message)]),
    );
    if (object.supportTicket != null) {
      yield r'supportTicket';
      yield serializers.serialize(
        object.supportTicket,
        specifiedType: const FullType(SupportTicket),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Conversation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConversationBuilder result,
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
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.type = valueDes;
          break;
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.status = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'creatorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.creatorId = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'participants':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ConversationParticipant)]),
          ) as BuiltList<ConversationParticipant>;
          result.participants.replace(valueDes);
          break;
        case r'creator':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.creator = valueDes;
          break;
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.vendor = valueDes;
          break;
        case r'messages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Message)]),
          ) as BuiltList<Message>;
          result.messages.replace(valueDes);
          break;
        case r'supportTicket':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.supportTicket = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Conversation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConversationBuilder();
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

