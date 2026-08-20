//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/product_option.dart';
import 'package:api/src/model/cart_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'cart_item_option.g.dart';

/// CartItemOption
///
/// Properties:
/// * [id] 
/// * [cartItemId] 
/// * [optionId] 
/// * [cartItem] 
/// * [option] 
@BuiltValue()
abstract class CartItemOption implements Built<CartItemOption, CartItemOptionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'cartItemId')
  String get cartItemId;

  @BuiltValueField(wireName: r'optionId')
  String get optionId;

  @BuiltValueField(wireName: r'cartItem')
  JsonObject? get cartItem;

  @BuiltValueField(wireName: r'option')
  JsonObject? get option;

  CartItemOption._();

  factory CartItemOption([void updates(CartItemOptionBuilder b)]) = _$CartItemOption;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CartItemOptionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CartItemOption> get serializer => _$CartItemOptionSerializer();
}

class _$CartItemOptionSerializer implements PrimitiveSerializer<CartItemOption> {
  @override
  final Iterable<Type> types = const [CartItemOption, _$CartItemOption];

  @override
  final String wireName = r'CartItemOption';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CartItemOption object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'cartItemId';
    yield serializers.serialize(
      object.cartItemId,
      specifiedType: const FullType(String),
    );
    yield r'optionId';
    yield serializers.serialize(
      object.optionId,
      specifiedType: const FullType(String),
    );
    yield r'cartItem';
    yield serializers.serialize(
      object.cartItem,
      specifiedType: const FullType(CartItem),
    );
    yield r'option';
    yield serializers.serialize(
      object.option,
      specifiedType: const FullType(ProductOption),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CartItemOption object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CartItemOptionBuilder result,
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
        case r'cartItemId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cartItemId = valueDes;
          break;
        case r'optionId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.optionId = valueDes;
          break;
        case r'cartItem':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.cartItem = valueDes;
          break;
        case r'option':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.option = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CartItemOption deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CartItemOptionBuilder();
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

