//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/order_item.dart';
import 'package:api/src/model/product_option.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'order_item_option.g.dart';

/// OrderItemOption
///
/// Properties:
/// * [id] 
/// * [orderItemId] 
/// * [optionId] 
/// * [optionName] 
/// * [priceAdded] 
/// * [option] 
/// * [orderItem] 
@BuiltValue()
abstract class OrderItemOption implements Built<OrderItemOption, OrderItemOptionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderItemId')
  String get orderItemId;

  @BuiltValueField(wireName: r'optionId')
  String? get optionId;

  @BuiltValueField(wireName: r'optionName')
  String get optionName;

  @BuiltValueField(wireName: r'priceAdded')
  num get priceAdded;

  @BuiltValueField(wireName: r'option')
  JsonObject? get option;

  @BuiltValueField(wireName: r'orderItem')
  JsonObject? get orderItem;

  OrderItemOption._();

  factory OrderItemOption([void updates(OrderItemOptionBuilder b)]) = _$OrderItemOption;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderItemOptionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderItemOption> get serializer => _$OrderItemOptionSerializer();
}

class _$OrderItemOptionSerializer implements PrimitiveSerializer<OrderItemOption> {
  @override
  final Iterable<Type> types = const [OrderItemOption, _$OrderItemOption];

  @override
  final String wireName = r'OrderItemOption';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderItemOption object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'orderItemId';
    yield serializers.serialize(
      object.orderItemId,
      specifiedType: const FullType(String),
    );
    if (object.optionId != null) {
      yield r'optionId';
      yield serializers.serialize(
        object.optionId,
        specifiedType: const FullType(String),
      );
    }
    yield r'optionName';
    yield serializers.serialize(
      object.optionName,
      specifiedType: const FullType(String),
    );
    yield r'priceAdded';
    yield serializers.serialize(
      object.priceAdded,
      specifiedType: const FullType(num),
    );
    if (object.option != null) {
      yield r'option';
      yield serializers.serialize(
        object.option,
        specifiedType: const FullType(ProductOption),
      );
    }
    yield r'orderItem';
    yield serializers.serialize(
      object.orderItem,
      specifiedType: const FullType(OrderItem),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderItemOption object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderItemOptionBuilder result,
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
        case r'orderItemId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderItemId = valueDes;
          break;
        case r'optionId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.optionId = valueDes;
          break;
        case r'optionName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.optionName = valueDes;
          break;
        case r'priceAdded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.priceAdded = valueDes;
          break;
        case r'option':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.option = valueDes;
          break;
        case r'orderItem':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.orderItem = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderItemOption deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderItemOptionBuilder();
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

