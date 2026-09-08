//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/ticket_category.dart';
import 'package:api/src/model/ticket_status.dart';
import 'package:api/src/model/ticket_priority.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'support_ticket.g.dart';

/// SupportTicket
///
/// Properties:
/// * [id] 
/// * [ticketNumber] 
/// * [subject] 
/// * [description] 
/// * [status] 
/// * [category] 
/// * [subCategory] 
/// * [priority] 
/// * [creatorId] 
/// * [assigneeId] 
/// * [orderId] 
/// * [vendorId] 
/// * [conversationId] 
/// * [lastStatusUpdateAt] 
/// * [escalatedAt] 
/// * [metadata] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class SupportTicket implements Built<SupportTicket, SupportTicketBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'ticketNumber')
  String get ticketNumber;

  @BuiltValueField(wireName: r'subject')
  String get subject;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'status')
  TicketStatus get status;
  // enum statusEnum {  OPEN,  IN_PROGRESS,  WAITING_ON_USER,  ESCALATED,  RESOLVED,  CLOSED,  };

  @BuiltValueField(wireName: r'category')
  TicketCategory get category;
  // enum categoryEnum {  DELIVERY,  VENDOR,  PAYMENT,  ACCOUNT,  RETURN_COMPLAINT,  OTHER,  };

  @BuiltValueField(wireName: r'subCategory')
  String? get subCategory;

  @BuiltValueField(wireName: r'priority')
  TicketPriority get priority;
  // enum priorityEnum {  LOW,  MEDIUM,  HIGH,  URGENT,  };

  @BuiltValueField(wireName: r'creatorId')
  String get creatorId;

  @BuiltValueField(wireName: r'assigneeId')
  String? get assigneeId;

  @BuiltValueField(wireName: r'orderId')
  String? get orderId;

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  @BuiltValueField(wireName: r'conversationId')
  String? get conversationId;

  @BuiltValueField(wireName: r'lastStatusUpdateAt')
  DateTime get lastStatusUpdateAt;

  @BuiltValueField(wireName: r'escalatedAt')
  DateTime? get escalatedAt;

  @BuiltValueField(wireName: r'metadata')
  JsonObject? get metadata;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  SupportTicket._();

  factory SupportTicket([void updates(SupportTicketBuilder b)]) = _$SupportTicket;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SupportTicketBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SupportTicket> get serializer => _$SupportTicketSerializer();
}

class _$SupportTicketSerializer implements PrimitiveSerializer<SupportTicket> {
  @override
  final Iterable<Type> types = const [SupportTicket, _$SupportTicket];

  @override
  final String wireName = r'SupportTicket';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SupportTicket object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'ticketNumber';
    yield serializers.serialize(
      object.ticketNumber,
      specifiedType: const FullType(String),
    );
    yield r'subject';
    yield serializers.serialize(
      object.subject,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TicketStatus),
    );
    yield r'category';
    yield serializers.serialize(
      object.category,
      specifiedType: const FullType(TicketCategory),
    );
    if (object.subCategory != null) {
      yield r'subCategory';
      yield serializers.serialize(
        object.subCategory,
        specifiedType: const FullType(String),
      );
    }
    yield r'priority';
    yield serializers.serialize(
      object.priority,
      specifiedType: const FullType(TicketPriority),
    );
    yield r'creatorId';
    yield serializers.serialize(
      object.creatorId,
      specifiedType: const FullType(String),
    );
    if (object.assigneeId != null) {
      yield r'assigneeId';
      yield serializers.serialize(
        object.assigneeId,
        specifiedType: const FullType(String),
      );
    }
    if (object.orderId != null) {
      yield r'orderId';
      yield serializers.serialize(
        object.orderId,
        specifiedType: const FullType(String),
      );
    }
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(String),
      );
    }
    if (object.conversationId != null) {
      yield r'conversationId';
      yield serializers.serialize(
        object.conversationId,
        specifiedType: const FullType(String),
      );
    }
    yield r'lastStatusUpdateAt';
    yield serializers.serialize(
      object.lastStatusUpdateAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.escalatedAt != null) {
      yield r'escalatedAt';
      yield serializers.serialize(
        object.escalatedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.metadata != null) {
      yield r'metadata';
      yield serializers.serialize(
        object.metadata,
        specifiedType: const FullType(JsonObject),
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
  }

  @override
  Object serialize(
    Serializers serializers,
    SupportTicket object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SupportTicketBuilder result,
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
        case r'ticketNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.ticketNumber = valueDes;
          break;
        case r'subject':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subject = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TicketStatus),
          ) as TicketStatus;
          result.status = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TicketCategory),
          ) as TicketCategory;
          result.category = valueDes;
          break;
        case r'subCategory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subCategory = valueDes;
          break;
        case r'priority':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TicketPriority),
          ) as TicketPriority;
          result.priority = valueDes;
          break;
        case r'creatorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.creatorId = valueDes;
          break;
        case r'assigneeId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assigneeId = valueDes;
          break;
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'conversationId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.conversationId = valueDes;
          break;
        case r'lastStatusUpdateAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.lastStatusUpdateAt = valueDes;
          break;
        case r'escalatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.escalatedAt = valueDes;
          break;
        case r'metadata':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.metadata = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SupportTicket deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SupportTicketBuilder();
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

