//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/create_option_group_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_product_variant_dto.g.dart';

/// CreateProductVariantDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [sku] 
/// * [basePrice] 
/// * [comparePrice] 
/// * [stock] 
/// * [isActive] 
/// * [optionGroups] 
@BuiltValue()
abstract class CreateProductVariantDto implements Built<CreateProductVariantDto, CreateProductVariantDtoBuilder> {
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
  bool? get isActive;

  @BuiltValueField(wireName: r'optionGroups')
  BuiltList<CreateOptionGroupDto>? get optionGroups;

  CreateProductVariantDto._();

  factory CreateProductVariantDto([void updates(CreateProductVariantDtoBuilder b)]) = _$CreateProductVariantDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateProductVariantDtoBuilder b) => b
      ..stock = 0
      ..isActive = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateProductVariantDto> get serializer => _$CreateProductVariantDtoSerializer();
}

class _$CreateProductVariantDtoSerializer implements PrimitiveSerializer<CreateProductVariantDto> {
  @override
  final Iterable<Type> types = const [CreateProductVariantDto, _$CreateProductVariantDto];

  @override
  final String wireName = r'CreateProductVariantDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateProductVariantDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    if (object.isActive != null) {
      yield r'isActive';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
    if (object.optionGroups != null) {
      yield r'optionGroups';
      yield serializers.serialize(
        object.optionGroups,
        specifiedType: const FullType(BuiltList, [FullType(CreateOptionGroupDto)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateProductVariantDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateProductVariantDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'optionGroups':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CreateOptionGroupDto)]),
          ) as BuiltList<CreateOptionGroupDto>;
          result.optionGroups.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateProductVariantDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateProductVariantDtoBuilder();
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

