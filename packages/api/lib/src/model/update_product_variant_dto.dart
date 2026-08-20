//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_product_variant_dto.g.dart';

/// UpdateProductVariantDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [sku] 
/// * [basePrice] 
/// * [comparePrice] 
/// * [stock] 
/// * [isActive] 
/// * [version] 
@BuiltValue()
abstract class UpdateProductVariantDto implements Built<UpdateProductVariantDto, UpdateProductVariantDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'sku')
  String? get sku;

  @BuiltValueField(wireName: r'basePrice')
  num? get basePrice;

  @BuiltValueField(wireName: r'comparePrice')
  num? get comparePrice;

  @BuiltValueField(wireName: r'stock')
  num? get stock;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'version')
  num? get version;

  UpdateProductVariantDto._();

  factory UpdateProductVariantDto([void updates(UpdateProductVariantDtoBuilder b)]) = _$UpdateProductVariantDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateProductVariantDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateProductVariantDto> get serializer => _$UpdateProductVariantDtoSerializer();
}

class _$UpdateProductVariantDtoSerializer implements PrimitiveSerializer<UpdateProductVariantDto> {
  @override
  final Iterable<Type> types = const [UpdateProductVariantDto, _$UpdateProductVariantDto];

  @override
  final String wireName = r'UpdateProductVariantDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateProductVariantDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    if (object.sku != null) {
      yield r'sku';
      yield serializers.serialize(
        object.sku,
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
    UpdateProductVariantDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateProductVariantDtoBuilder result,
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
  UpdateProductVariantDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateProductVariantDtoBuilder();
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

