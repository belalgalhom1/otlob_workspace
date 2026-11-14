//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_delivery_group_item.g.dart';

/// OrderDeliveryGroupItem
///
/// Properties:
/// * [id] 
/// * [deliveryGroupId] 
/// * [fulfillmentId] 
/// * [sequence] 
@BuiltValue()
abstract class OrderDeliveryGroupItem implements Built<OrderDeliveryGroupItem, OrderDeliveryGroupItemBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'deliveryGroupId')
  String get deliveryGroupId;

  @BuiltValueField(wireName: r'fulfillmentId')
  String get fulfillmentId;

  @BuiltValueField(wireName: r'sequence')
  num get sequence;

  OrderDeliveryGroupItem._();

  factory OrderDeliveryGroupItem([void updates(OrderDeliveryGroupItemBuilder b)]) = _$OrderDeliveryGroupItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderDeliveryGroupItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderDeliveryGroupItem> get serializer => _$OrderDeliveryGroupItemSerializer();
}

class _$OrderDeliveryGroupItemSerializer implements PrimitiveSerializer<OrderDeliveryGroupItem> {
  @override
  final Iterable<Type> types = const [OrderDeliveryGroupItem, _$OrderDeliveryGroupItem];

  @override
  final String wireName = r'OrderDeliveryGroupItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderDeliveryGroupItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'deliveryGroupId';
    yield serializers.serialize(
      object.deliveryGroupId,
      specifiedType: const FullType(String),
    );
    yield r'fulfillmentId';
    yield serializers.serialize(
      object.fulfillmentId,
      specifiedType: const FullType(String),
    );
    yield r'sequence';
    yield serializers.serialize(
      object.sequence,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderDeliveryGroupItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderDeliveryGroupItemBuilder result,
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
        case r'deliveryGroupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryGroupId = valueDes;
          break;
        case r'fulfillmentId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fulfillmentId = valueDes;
          break;
        case r'sequence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.sequence = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderDeliveryGroupItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderDeliveryGroupItemBuilder();
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

