//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/product_option_group.dart';
import 'package:api/src/model/order_item.dart';
import 'package:api/src/model/cart_item.dart';
import 'package:api/src/model/product.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'product_variant.g.dart';

/// ProductVariant
///
/// Properties:
/// * [id] 
/// * [productId] 
/// * [name] 
/// * [nameAr] 
/// * [sku] 
/// * [basePrice] 
/// * [comparePrice] 
/// * [stock] 
/// * [isActive] 
/// * [version] 
/// * [cartItems] 
/// * [orderItems] 
/// * [optionGroups] 
/// * [product] 
@BuiltValue()
abstract class ProductVariant implements Built<ProductVariant, ProductVariantBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'productId')
  String get productId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'sku')
  String? get sku;

  @BuiltValueField(wireName: r'basePrice')
  num get basePrice;

  @BuiltValueField(wireName: r'comparePrice')
  num? get comparePrice;

  @BuiltValueField(wireName: r'stock')
  num? get stock;

  @BuiltValueField(wireName: r'isActive')
  bool get isActive;

  @BuiltValueField(wireName: r'version')
  num get version;

  @BuiltValueField(wireName: r'cartItems')
  BuiltList<CartItem> get cartItems;

  @BuiltValueField(wireName: r'orderItems')
  BuiltList<OrderItem> get orderItems;

  @BuiltValueField(wireName: r'optionGroups')
  BuiltList<ProductOptionGroup> get optionGroups;

  @BuiltValueField(wireName: r'product')
  JsonObject? get product;

  ProductVariant._();

  factory ProductVariant([void updates(ProductVariantBuilder b)]) = _$ProductVariant;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductVariantBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductVariant> get serializer => _$ProductVariantSerializer();
}

class _$ProductVariantSerializer implements PrimitiveSerializer<ProductVariant> {
  @override
  final Iterable<Type> types = const [ProductVariant, _$ProductVariant];

  @override
  final String wireName = r'ProductVariant';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductVariant object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'productId';
    yield serializers.serialize(
      object.productId,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.nameAr != null) {
      yield r'nameAr';
      yield serializers.serialize(
        object.nameAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.sku != null) {
      yield r'sku';
      yield serializers.serialize(
        object.sku,
        specifiedType: const FullType(String),
      );
    }
    yield r'basePrice';
    yield serializers.serialize(
      object.basePrice,
      specifiedType: const FullType(num),
    );
    if (object.comparePrice != null) {
      yield r'comparePrice';
      yield serializers.serialize(
        object.comparePrice,
        specifiedType: const FullType(num),
      );
    }
    if (object.stock != null) {
      yield r'stock';
      yield serializers.serialize(
        object.stock,
        specifiedType: const FullType(num),
      );
    }
    yield r'isActive';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(num),
    );
    yield r'cartItems';
    yield serializers.serialize(
      object.cartItems,
      specifiedType: const FullType(BuiltList, [FullType(CartItem)]),
    );
    yield r'orderItems';
    yield serializers.serialize(
      object.orderItems,
      specifiedType: const FullType(BuiltList, [FullType(OrderItem)]),
    );
    yield r'optionGroups';
    yield serializers.serialize(
      object.optionGroups,
      specifiedType: const FullType(BuiltList, [FullType(ProductOptionGroup)]),
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
    ProductVariant object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductVariantBuilder result,
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
        case r'productId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.productId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'nameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nameAr = valueDes;
          break;
        case r'sku':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sku = valueDes;
          break;
        case r'basePrice':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.basePrice = valueDes;
          break;
        case r'comparePrice':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.comparePrice = valueDes;
          break;
        case r'stock':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.stock = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.version = valueDes;
          break;
        case r'cartItems':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CartItem)]),
          ) as BuiltList<CartItem>;
          result.cartItems.replace(valueDes);
          break;
        case r'orderItems':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderItem)]),
          ) as BuiltList<OrderItem>;
          result.orderItems.replace(valueDes);
          break;
        case r'optionGroups':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ProductOptionGroup)]),
          ) as BuiltList<ProductOptionGroup>;
          result.optionGroups.replace(valueDes);
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
  ProductVariant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductVariantBuilder();
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

