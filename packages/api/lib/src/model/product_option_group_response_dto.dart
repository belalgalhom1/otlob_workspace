//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/product_variant.dart';
import 'package:api/src/model/product.dart';
import 'package:api/src/model/product_option.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_option_group_response_dto.g.dart';

/// ProductOptionGroupResponseDto
///
/// Properties:
/// * [id] 
/// * [productId] 
/// * [variantId] 
/// * [name] 
/// * [nameAr] 
/// * [isRequired] 
/// * [minSelect] 
/// * [maxSelect] 
/// * [product] 
/// * [variant] 
/// * [options] 
@BuiltValue()
abstract class ProductOptionGroupResponseDto implements Built<ProductOptionGroupResponseDto, ProductOptionGroupResponseDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'productId')
  String? get productId;

  @BuiltValueField(wireName: r'variantId')
  String? get variantId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'isRequired')
  bool get isRequired;

  @BuiltValueField(wireName: r'minSelect')
  num get minSelect;

  @BuiltValueField(wireName: r'maxSelect')
  num get maxSelect;

  @BuiltValueField(wireName: r'product')
  Product? get product;

  @BuiltValueField(wireName: r'variant')
  ProductVariant? get variant;

  @BuiltValueField(wireName: r'options')
  BuiltList<ProductOption>? get options;

  ProductOptionGroupResponseDto._();

  factory ProductOptionGroupResponseDto([void updates(ProductOptionGroupResponseDtoBuilder b)]) = _$ProductOptionGroupResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductOptionGroupResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductOptionGroupResponseDto> get serializer => _$ProductOptionGroupResponseDtoSerializer();
}

class _$ProductOptionGroupResponseDtoSerializer implements PrimitiveSerializer<ProductOptionGroupResponseDto> {
  @override
  final Iterable<Type> types = const [ProductOptionGroupResponseDto, _$ProductOptionGroupResponseDto];

  @override
  final String wireName = r'ProductOptionGroupResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductOptionGroupResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.productId != null) {
      yield r'productId';
      yield serializers.serialize(
        object.productId,
        specifiedType: const FullType(String),
      );
    }
    if (object.variantId != null) {
      yield r'variantId';
      yield serializers.serialize(
        object.variantId,
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
    yield r'isRequired';
    yield serializers.serialize(
      object.isRequired,
      specifiedType: const FullType(bool),
    );
    yield r'minSelect';
    yield serializers.serialize(
      object.minSelect,
      specifiedType: const FullType(num),
    );
    yield r'maxSelect';
    yield serializers.serialize(
      object.maxSelect,
      specifiedType: const FullType(num),
    );
    if (object.product != null) {
      yield r'product';
      yield serializers.serialize(
        object.product,
        specifiedType: const FullType(Product),
      );
    }
    if (object.variant != null) {
      yield r'variant';
      yield serializers.serialize(
        object.variant,
        specifiedType: const FullType(ProductVariant),
      );
    }
    if (object.options != null) {
      yield r'options';
      yield serializers.serialize(
        object.options,
        specifiedType: const FullType(BuiltList, [FullType(ProductOption)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductOptionGroupResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductOptionGroupResponseDtoBuilder result,
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
        case r'variantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.variantId = valueDes;
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
        case r'isRequired':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isRequired = valueDes;
          break;
        case r'minSelect':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minSelect = valueDes;
          break;
        case r'maxSelect':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxSelect = valueDes;
          break;
        case r'product':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Product),
          ) as Product;
          result.product.replace(valueDes);
          break;
        case r'variant':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProductVariant),
          ) as ProductVariant;
          result.variant.replace(valueDes);
          break;
        case r'options':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ProductOption)]),
          ) as BuiltList<ProductOption>;
          result.options.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductOptionGroupResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductOptionGroupResponseDtoBuilder();
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

