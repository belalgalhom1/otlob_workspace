//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/create_product_variant_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/create_option_group_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_product_dto.g.dart';

/// CreateProductDto
///
/// Properties:
/// * [categoryId] 
/// * [name] 
/// * [nameAr] 
/// * [description] 
/// * [descriptionAr] 
/// * [hasVariants] 
/// * [basePrice] 
/// * [comparePrice] 
/// * [sku] 
/// * [stock] 
/// * [tracksStock] 
/// * [isActive] 
/// * [isFeatured] 
/// * [sellByStrip] 
/// * [stripsPerPackage] 
/// * [branchAvailabilityMode] - ALL includes every current and future branch. SPECIFIC uses branchIds.
/// * [branchIds] - Branch IDs when branchAvailabilityMode is SPECIFIC. One ID means one branch.
/// * [optionGroups] 
/// * [variants] 
@BuiltValue()
abstract class CreateProductDto implements Built<CreateProductDto, CreateProductDtoBuilder> {
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

  @BuiltValueField(wireName: r'hasVariants')
  bool? get hasVariants;

  @BuiltValueField(wireName: r'basePrice')
  num? get basePrice;

  @BuiltValueField(wireName: r'comparePrice')
  num? get comparePrice;

  @BuiltValueField(wireName: r'sku')
  String? get sku;

  @BuiltValueField(wireName: r'stock')
  num? get stock;

  @BuiltValueField(wireName: r'tracksStock')
  bool? get tracksStock;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'isFeatured')
  bool? get isFeatured;

  @BuiltValueField(wireName: r'sellByStrip')
  bool? get sellByStrip;

  @BuiltValueField(wireName: r'stripsPerPackage')
  num? get stripsPerPackage;

  /// ALL includes every current and future branch. SPECIFIC uses branchIds.
  @BuiltValueField(wireName: r'branchAvailabilityMode')
  CreateProductDtoBranchAvailabilityModeEnum? get branchAvailabilityMode;
  // enum branchAvailabilityModeEnum {  ALL,  SPECIFIC,  };

  /// Branch IDs when branchAvailabilityMode is SPECIFIC. One ID means one branch.
  @BuiltValueField(wireName: r'branchIds')
  BuiltList<String>? get branchIds;

  @BuiltValueField(wireName: r'optionGroups')
  BuiltList<CreateOptionGroupDto>? get optionGroups;

  @BuiltValueField(wireName: r'variants')
  BuiltList<CreateProductVariantDto>? get variants;

  CreateProductDto._();

  factory CreateProductDto([void updates(CreateProductDtoBuilder b)]) = _$CreateProductDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateProductDtoBuilder b) => b
      ..hasVariants = false
      ..stock = 0
      ..tracksStock = true
      ..isActive = true
      ..isFeatured = false
      ..sellByStrip = false
      ..branchAvailabilityMode = CreateProductDtoBranchAvailabilityModeEnum.valueOf('ALL');

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateProductDto> get serializer => _$CreateProductDtoSerializer();
}

class _$CreateProductDtoSerializer implements PrimitiveSerializer<CreateProductDto> {
  @override
  final Iterable<Type> types = const [CreateProductDto, _$CreateProductDto];

  @override
  final String wireName = r'CreateProductDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateProductDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    if (object.hasVariants != null) {
      yield r'hasVariants';
      yield serializers.serialize(
        object.hasVariants,
        specifiedType: const FullType(bool),
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
    if (object.tracksStock != null) {
      yield r'tracksStock';
      yield serializers.serialize(
        object.tracksStock,
        specifiedType: const FullType(bool),
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
    if (object.branchAvailabilityMode != null) {
      yield r'branchAvailabilityMode';
      yield serializers.serialize(
        object.branchAvailabilityMode,
        specifiedType: const FullType(CreateProductDtoBranchAvailabilityModeEnum),
      );
    }
    if (object.branchIds != null) {
      yield r'branchIds';
      yield serializers.serialize(
        object.branchIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
    if (object.optionGroups != null) {
      yield r'optionGroups';
      yield serializers.serialize(
        object.optionGroups,
        specifiedType: const FullType(BuiltList, [FullType(CreateOptionGroupDto)]),
      );
    }
    if (object.variants != null) {
      yield r'variants';
      yield serializers.serialize(
        object.variants,
        specifiedType: const FullType(BuiltList, [FullType(CreateProductVariantDto)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateProductDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateProductDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'tracksStock':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.tracksStock = valueDes;
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
        case r'branchAvailabilityMode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CreateProductDtoBranchAvailabilityModeEnum),
          ) as CreateProductDtoBranchAvailabilityModeEnum;
          result.branchAvailabilityMode = valueDes;
          break;
        case r'branchIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.branchIds.replace(valueDes);
          break;
        case r'optionGroups':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CreateOptionGroupDto)]),
          ) as BuiltList<CreateOptionGroupDto>;
          result.optionGroups.replace(valueDes);
          break;
        case r'variants':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CreateProductVariantDto)]),
          ) as BuiltList<CreateProductVariantDto>;
          result.variants.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateProductDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateProductDtoBuilder();
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

class CreateProductDtoBranchAvailabilityModeEnum extends EnumClass {

  /// ALL includes every current and future branch. SPECIFIC uses branchIds.
  @BuiltValueEnumConst(wireName: r'ALL')
  static const CreateProductDtoBranchAvailabilityModeEnum ALL = _$createProductDtoBranchAvailabilityModeEnum_ALL;
  /// ALL includes every current and future branch. SPECIFIC uses branchIds.
  @BuiltValueEnumConst(wireName: r'SPECIFIC')
  static const CreateProductDtoBranchAvailabilityModeEnum SPECIFIC = _$createProductDtoBranchAvailabilityModeEnum_SPECIFIC;

  static Serializer<CreateProductDtoBranchAvailabilityModeEnum> get serializer => _$createProductDtoBranchAvailabilityModeEnumSerializer;

  const CreateProductDtoBranchAvailabilityModeEnum._(String name): super(name);

  static BuiltSet<CreateProductDtoBranchAvailabilityModeEnum> get values => _$createProductDtoBranchAvailabilityModeEnumValues;
  static CreateProductDtoBranchAvailabilityModeEnum valueOf(String name) => _$createProductDtoBranchAvailabilityModeEnumValueOf(name);
}

