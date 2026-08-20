//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_product_dto.g.dart';

/// UpdateProductDto
///
/// Properties:
/// * [categoryId] 
/// * [name] 
/// * [nameAr] 
/// * [description] 
/// * [descriptionAr] 
/// * [basePrice] 
/// * [comparePrice] 
/// * [sku] 
/// * [stock] 
/// * [isActive] 
/// * [isFeatured] 
/// * [sellByStrip] 
/// * [stripsPerPackage] 
/// * [version] 
@BuiltValue()
abstract class UpdateProductDto implements Built<UpdateProductDto, UpdateProductDtoBuilder> {
  @BuiltValueField(wireName: r'categoryId')
  JsonObject? get categoryId;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'descriptionAr')
  String? get descriptionAr;

  @BuiltValueField(wireName: r'basePrice')
  num? get basePrice;

  @BuiltValueField(wireName: r'comparePrice')
  num? get comparePrice;

  @BuiltValueField(wireName: r'sku')
  String? get sku;

  @BuiltValueField(wireName: r'stock')
  num? get stock;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'isFeatured')
  bool? get isFeatured;

  @BuiltValueField(wireName: r'sellByStrip')
  bool? get sellByStrip;

  @BuiltValueField(wireName: r'stripsPerPackage')
  num? get stripsPerPackage;

  @BuiltValueField(wireName: r'version')
  num? get version;

  UpdateProductDto._();

  factory UpdateProductDto([void updates(UpdateProductDtoBuilder b)]) = _$UpdateProductDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateProductDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateProductDto> get serializer => _$UpdateProductDtoSerializer();
}

class _$UpdateProductDtoSerializer implements PrimitiveSerializer<UpdateProductDto> {
  @override
  final Iterable<Type> types = const [UpdateProductDto, _$UpdateProductDto];

  @override
  final String wireName = r'UpdateProductDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateProductDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.categoryId != null) {
      yield r'categoryId';
      yield serializers.serialize(
        object.categoryId,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
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
    if (object.isActive != null) {
      yield r'isActive';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
    if (object.isFeatured != null) {
      yield r'isFeatured';
      yield serializers.serialize(
        object.isFeatured,
        specifiedType: const FullType(bool),
      );
    }
    if (object.sellByStrip != null) {
      yield r'sellByStrip';
      yield serializers.serialize(
        object.sellByStrip,
        specifiedType: const FullType(bool),
      );
    }
    if (object.stripsPerPackage != null) {
      yield r'stripsPerPackage';
      yield serializers.serialize(
        object.stripsPerPackage,
        specifiedType: const FullType(num),
      );
    }
    if (object.version != null) {
      yield r'version';
      yield serializers.serialize(
        object.version,
        specifiedType: const FullType(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateProductDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateProductDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'categoryId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
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
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.version = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateProductDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateProductDtoBuilder();
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

