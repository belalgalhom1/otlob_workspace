//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vendor.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/cart_item.dart';
import 'package:api/src/model/customer.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'cart.g.dart';

/// Cart
///
/// Properties:
/// * [id] 
/// * [customerId] 
/// * [vendorId] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [items] 
/// * [customer] 
/// * [vendor] 
@BuiltValue()
abstract class Cart implements Built<Cart, CartBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'customerId')
  String get customerId;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'items')
  BuiltList<CartItem> get items;

  @BuiltValueField(wireName: r'customer')
  JsonObject? get customer;

  @BuiltValueField(wireName: r'vendor')
  JsonObject? get vendor;

  Cart._();

  factory Cart([void updates(CartBuilder b)]) = _$Cart;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CartBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Cart> get serializer => _$CartSerializer();
}

class _$CartSerializer implements PrimitiveSerializer<Cart> {
  @override
  final Iterable<Type> types = const [Cart, _$Cart];

  @override
  final String wireName = r'Cart';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Cart object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'customerId';
    yield serializers.serialize(
      object.customerId,
      specifiedType: const FullType(String),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
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
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(CartItem)]),
    );
    yield r'customer';
    yield serializers.serialize(
      object.customer,
      specifiedType: const FullType(Customer),
    );
    yield r'vendor';
    yield serializers.serialize(
      object.vendor,
      specifiedType: const FullType(Vendor),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Cart object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CartBuilder result,
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
        case r'customerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.customerId = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
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
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CartItem)]),
          ) as BuiltList<CartItem>;
          result.items.replace(valueDes);
          break;
        case r'customer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.customer = valueDes;
          break;
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.vendor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Cart deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CartBuilder();
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

