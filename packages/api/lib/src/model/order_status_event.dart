//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/order_actor_summary_dto.dart';
import 'package:api/src/model/order_status.dart';
import 'package:api/src/model/role.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_status_event.g.dart';

/// OrderStatusEvent
///
/// Properties:
/// * [id] 
/// * [orderId] 
/// * [fulfillmentId] 
/// * [deliveryGroupId] 
/// * [eventKey] 
/// * [status] 
/// * [note] 
/// * [createdBy] 
/// * [actorUserId] 
/// * [actorRole] 
/// * [actorName] 
/// * [actorNameAr] 
/// * [actorAvatar] 
/// * [actorVendorId] 
/// * [actor] 
/// * [createdAt] 
@BuiltValue()
abstract class OrderStatusEvent implements Built<OrderStatusEvent, OrderStatusEventBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'fulfillmentId')
  String? get fulfillmentId;

  @BuiltValueField(wireName: r'deliveryGroupId')
  String? get deliveryGroupId;

  @BuiltValueField(wireName: r'eventKey')
  String? get eventKey;

  @BuiltValueField(wireName: r'status')
  OrderStatus get status;
  // enum statusEnum {  PENDING,  CHANGES_REQUESTED,  ACCEPTED,  PREPARING,  LOOKING_FOR_DRIVER,  DRIVER_ASSIGNED,  PENDING_PAYMENT,  READY_FOR_PICKUP,  PARTIALLY_PICKED_UP,  PICKED_UP,  DELIVERED,  CANCELLED,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'createdBy')
  String? get createdBy;

  @BuiltValueField(wireName: r'actorUserId')
  String? get actorUserId;

  @BuiltValueField(wireName: r'actorRole')
  Role? get actorRole;
  // enum actorRoleEnum {  CUSTOMER,  DRIVER,  DRIVER_MANAGER,  VENDOR_MEMBER,  ADMIN,  SUPER_ADMIN,  };

  @BuiltValueField(wireName: r'actorName')
  String? get actorName;

  @BuiltValueField(wireName: r'actorNameAr')
  String? get actorNameAr;

  @BuiltValueField(wireName: r'actorAvatar')
  String? get actorAvatar;

  @BuiltValueField(wireName: r'actorVendorId')
  String? get actorVendorId;

  @BuiltValueField(wireName: r'actor')
  OrderActorSummaryDto? get actor;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  OrderStatusEvent._();

  factory OrderStatusEvent([void updates(OrderStatusEventBuilder b)]) = _$OrderStatusEvent;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderStatusEventBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderStatusEvent> get serializer => _$OrderStatusEventSerializer();
}

class _$OrderStatusEventSerializer implements PrimitiveSerializer<OrderStatusEvent> {
  @override
  final Iterable<Type> types = const [OrderStatusEvent, _$OrderStatusEvent];

  @override
  final String wireName = r'OrderStatusEvent';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderStatusEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'orderId';
    yield serializers.serialize(
      object.orderId,
      specifiedType: const FullType(String),
    );
    if (object.fulfillmentId != null) {
      yield r'fulfillmentId';
      yield serializers.serialize(
        object.fulfillmentId,
        specifiedType: const FullType(String),
      );
    }
    if (object.deliveryGroupId != null) {
      yield r'deliveryGroupId';
      yield serializers.serialize(
        object.deliveryGroupId,
        specifiedType: const FullType(String),
      );
    }
    if (object.eventKey != null) {
      yield r'eventKey';
      yield serializers.serialize(
        object.eventKey,
        specifiedType: const FullType(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(OrderStatus),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
    if (object.createdBy != null) {
      yield r'createdBy';
      yield serializers.serialize(
        object.createdBy,
        specifiedType: const FullType(String),
      );
    }
    if (object.actorUserId != null) {
      yield r'actorUserId';
      yield serializers.serialize(
        object.actorUserId,
        specifiedType: const FullType(String),
      );
    }
    if (object.actorRole != null) {
      yield r'actorRole';
      yield serializers.serialize(
        object.actorRole,
        specifiedType: const FullType(Role),
      );
    }
    if (object.actorName != null) {
      yield r'actorName';
      yield serializers.serialize(
        object.actorName,
        specifiedType: const FullType(String),
      );
    }
    if (object.actorNameAr != null) {
      yield r'actorNameAr';
      yield serializers.serialize(
        object.actorNameAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.actorAvatar != null) {
      yield r'actorAvatar';
      yield serializers.serialize(
        object.actorAvatar,
        specifiedType: const FullType(String),
      );
    }
    if (object.actorVendorId != null) {
      yield r'actorVendorId';
      yield serializers.serialize(
        object.actorVendorId,
        specifiedType: const FullType(String),
      );
    }
    if (object.actor != null) {
      yield r'actor';
      yield serializers.serialize(
        object.actor,
        specifiedType: const FullType(OrderActorSummaryDto),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderStatusEvent object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderStatusEventBuilder result,
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
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'fulfillmentId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fulfillmentId = valueDes;
          break;
        case r'deliveryGroupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryGroupId = valueDes;
          break;
        case r'eventKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.eventKey = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderStatus),
          ) as OrderStatus;
          result.status = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.note = valueDes;
          break;
        case r'createdBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdBy = valueDes;
          break;
        case r'actorUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.actorUserId = valueDes;
          break;
        case r'actorRole':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Role),
          ) as Role;
          result.actorRole = valueDes;
          break;
        case r'actorName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.actorName = valueDes;
          break;
        case r'actorNameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.actorNameAr = valueDes;
          break;
        case r'actorAvatar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.actorAvatar = valueDes;
          break;
        case r'actorVendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.actorVendorId = valueDes;
          break;
        case r'actor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderActorSummaryDto),
          ) as OrderActorSummaryDto;
          result.actor.replace(valueDes);
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderStatusEvent deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderStatusEventBuilder();
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

