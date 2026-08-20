//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/menu_category.dart';
import 'package:api/src/model/product_variant.dart';
import 'package:api/src/model/vendor.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/offer.dart';
import 'package:api/src/model/product_option_group.dart';
import 'package:api/src/model/order_item.dart';
import 'package:api/src/model/cart_item.dart';
import 'package:api/src/model/favorite_product.dart';
import 'package:api/src/model/promotion.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'product.g.dart';

/// Product
///
/// Properties:
/// * [id] 
/// * [version] 
/// * [vendorId] 
/// * [categoryId] 
/// * [name] 
/// * [nameAr] 
/// * [description] 
/// * [descriptionAr] 
/// * [imageUrl] 
/// * [sellByStrip] 
/// * [stripsPerPackage] 
/// * [hasVariants] 
/// * [basePrice] 
/// * [comparePrice] 
/// * [sku] 
/// * [stock] 
/// * [isActive] 
/// * [isFeatured] 
/// * [deletedAt] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [cartItems] 
/// * [favoritedBy] 
/// * [orderItems] 
/// * [optionGroups] 
/// * [variants] 
/// * [promotions] 
/// * [offers] 
/// * [category] 
/// * [vendor] 
@BuiltValue()
abstract class Product implements Built<Product, ProductBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'version')
  num get version;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'categoryId')
  String? get categoryId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'descriptionAr')
  String? get descriptionAr;

  @BuiltValueField(wireName: r'imageUrl')
  String? get imageUrl;

  @BuiltValueField(wireName: r'sellByStrip')
  bool get sellByStrip;

  @BuiltValueField(wireName: r'stripsPerPackage')
  num? get stripsPerPackage;

  @BuiltValueField(wireName: r'hasVariants')
  bool get hasVariants;

  @BuiltValueField(wireName: r'basePrice')
  num? get basePrice;

  @BuiltValueField(wireName: r'comparePrice')
  num? get comparePrice;

  @BuiltValueField(wireName: r'sku')
  String? get sku;

  @BuiltValueField(wireName: r'stock')
  num? get stock;

  @BuiltValueField(wireName: r'isActive')
  bool get isActive;

  @BuiltValueField(wireName: r'isFeatured')
  bool get isFeatured;

  @BuiltValueField(wireName: r'deletedAt')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'cartItems')
  BuiltList<CartItem> get cartItems;

  @BuiltValueField(wireName: r'favoritedBy')
  BuiltList<FavoriteProduct> get favoritedBy;

  @BuiltValueField(wireName: r'orderItems')
  BuiltList<OrderItem> get orderItems;

  @BuiltValueField(wireName: r'optionGroups')
  BuiltList<ProductOptionGroup> get optionGroups;

  @BuiltValueField(wireName: r'variants')
  BuiltList<ProductVariant> get variants;

  @BuiltValueField(wireName: r'promotions')
  BuiltList<Promotion> get promotions;

  @BuiltValueField(wireName: r'offers')
  BuiltList<Offer> get offers;

  @BuiltValueField(wireName: r'category')
  JsonObject? get category;

  @BuiltValueField(wireName: r'vendor')
  JsonObject? get vendor;

  Product._();

  factory Product([void updates(ProductBuilder b)]) = _$Product;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Product> get serializer => _$ProductSerializer();
}

class _$ProductSerializer implements PrimitiveSerializer<Product> {
  @override
  final Iterable<Type> types = const [Product, _$Product];

  @override
  final String wireName = r'Product';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Product object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(num),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
    if (object.categoryId != null) {
      yield r'categoryId';
      yield serializers.serialize(
        object.categoryId,
        specifiedType: const FullType(String),
      );
    }
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
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.descriptionAr != null) {
      yield r'descriptionAr';
      yield serializers.serialize(
        object.descriptionAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.imageUrl != null) {
      yield r'imageUrl';
      yield serializers.serialize(
        object.imageUrl,
        specifiedType: const FullType(String),
      );
    }
    yield r'sellByStrip';
    yield serializers.serialize(
      object.sellByStrip,
      specifiedType: const FullType(bool),
    );
    if (object.stripsPerPackage != null) {
      yield r'stripsPerPackage';
      yield serializers.serialize(
        object.stripsPerPackage,
        specifiedType: const FullType(num),
      );
    }
    yield r'hasVariants';
    yield serializers.serialize(
      object.hasVariants,
      specifiedType: const FullType(bool),
    );
    if (object.basePrice != null) {
      yield r'basePrice';
      yield serializers.serialize(
        object.basePrice,
        specifiedType: const FullType(num),
      );
    }
    if (object.comparePrice != null) {
      yield r'comparePrice';
      yield serializers.serialize(
        object.comparePrice,
        specifiedType: const FullType(num),
      );
    }
    if (object.sku != null) {
      yield r'sku';
      yield serializers.serialize(
        object.sku,
        specifiedType: const FullType(String),
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
    yield r'isFeatured';
    yield serializers.serialize(
      object.isFeatured,
      specifiedType: const FullType(bool),
    );
    if (object.deletedAt != null) {
      yield r'deletedAt';
      yield serializers.serialize(
        object.deletedAt,
        specifiedType: const FullType(DateTime),
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
    yield r'cartItems';
    yield serializers.serialize(
      object.cartItems,
      specifiedType: const FullType(BuiltList, [FullType(CartItem)]),
    );
    yield r'favoritedBy';
    yield serializers.serialize(
      object.favoritedBy,
      specifiedType: const FullType(BuiltList, [FullType(FavoriteProduct)]),
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
    yield r'variants';
    yield serializers.serialize(
      object.variants,
      specifiedType: const FullType(BuiltList, [FullType(ProductVariant)]),
    );
    yield r'promotions';
    yield serializers.serialize(
      object.promotions,
      specifiedType: const FullType(BuiltList, [FullType(Promotion)]),
    );
    yield r'offers';
    yield serializers.serialize(
      object.offers,
      specifiedType: const FullType(BuiltList, [FullType(Offer)]),
    );
    if (object.category != null) {
      yield r'category';
      yield serializers.serialize(
        object.category,
        specifiedType: const FullType(MenuCategory),
      );
    }
    yield r'vendor';
    yield serializers.serialize(
      object.vendor,
      specifiedType: const FullType(Vendor),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Product object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductBuilder result,
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
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.version = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'categoryId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.categoryId = valueDes;
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
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'descriptionAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.descriptionAr = valueDes;
          break;
        case r'imageUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.imageUrl = valueDes;
          break;
        case r'sellByStrip':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.sellByStrip = valueDes;
          break;
        case r'stripsPerPackage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.stripsPerPackage = valueDes;
          break;
        case r'hasVariants':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasVariants = valueDes;
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
        case r'sku':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sku = valueDes;
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
        case r'isFeatured':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isFeatured = valueDes;
          break;
        case r'deletedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deletedAt = valueDes;
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
        case r'cartItems':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CartItem)]),
          ) as BuiltList<CartItem>;
          result.cartItems.replace(valueDes);
          break;
        case r'favoritedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FavoriteProduct)]),
          ) as BuiltList<FavoriteProduct>;
          result.favoritedBy.replace(valueDes);
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
        case r'variants':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ProductVariant)]),
          ) as BuiltList<ProductVariant>;
          result.variants.replace(valueDes);
          break;
        case r'promotions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Promotion)]),
          ) as BuiltList<Promotion>;
          result.promotions.replace(valueDes);
          break;
        case r'offers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Offer)]),
          ) as BuiltList<Offer>;
          result.offers.replace(valueDes);
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.category = valueDes;
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
  Product deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductBuilder();
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

