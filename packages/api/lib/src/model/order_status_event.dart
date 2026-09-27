//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/order_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_status_event.g.dart';

/// OrderStatusEvent
///
/// Properties:
/// * [id] 
/// * [orderId] 
/// * [status] 
/// * [note] 
/// * [createdBy] 
/// * [createdAt] 
@BuiltValue()
abstract class OrderStatusEvent implements Built<OrderStatusEvent, OrderStatusEventBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'status')
  OrderStatus get status;
  // enum statusEnum {  PENDING,  CHANGES_REQUESTED,  ACCEPTED,  PREPARING,  LOOKING_FOR_DRIVER,  DRIVER_ASSIGNED,  PENDING_PAYMENT,  READY_FOR_PICKUP,  PICKED_UP,  DELIVERED,  CANCELLED,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'createdBy')
  String? get createdBy;

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

