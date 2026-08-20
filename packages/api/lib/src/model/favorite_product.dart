//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/product.dart';
import 'package:api/src/model/customer.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'favorite_product.g.dart';

/// FavoriteProduct
///
/// Properties:
/// * [id] 
/// * [customerId] 
/// * [productId] 
/// * [createdAt] 
/// * [customer] 
/// * [product] 
@BuiltValue()
abstract class FavoriteProduct implements Built<FavoriteProduct, FavoriteProductBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'customerId')
  String get customerId;

  @BuiltValueField(wireName: r'productId')
  String get productId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'customer')
  JsonObject? get customer;

  @BuiltValueField(wireName: r'product')
  JsonObject? get product;

  FavoriteProduct._();

  factory FavoriteProduct([void updates(FavoriteProductBuilder b)]) = _$FavoriteProduct;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FavoriteProductBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FavoriteProduct> get serializer => _$FavoriteProductSerializer();
}

class _$FavoriteProductSerializer implements PrimitiveSerializer<FavoriteProduct> {
  @override
  final Iterable<Type> types = const [FavoriteProduct, _$FavoriteProduct];

  @override
  final String wireName = r'FavoriteProduct';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FavoriteProduct object, {
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
    yield r'productId';
    yield serializers.serialize(
      object.productId,
      specifiedType: const FullType(String),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'customer';
    yield serializers.serialize(
      object.customer,
      specifiedType: const FullType(Customer),
    );
    yield r'product';
    yield serializers.serialize(
      object.product,
      specifiedType: const FullType(Product),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FavoriteProduct object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FavoriteProductBuilder result,
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
        case r'productId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.productId = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'customer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.customer = valueDes;
          break;
        case r'product':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.product = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FavoriteProduct deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FavoriteProductBuilder();
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

