//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_product_option_dto.g.dart';

/// UpdateProductOptionDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [priceAdded] 
/// * [isActive] 
@BuiltValue()
abstract class UpdateProductOptionDto implements Built<UpdateProductOptionDto, UpdateProductOptionDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'priceAdded')
  num? get priceAdded;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  UpdateProductOptionDto._();

  factory UpdateProductOptionDto([void updates(UpdateProductOptionDtoBuilder b)]) = _$UpdateProductOptionDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateProductOptionDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateProductOptionDto> get serializer => _$UpdateProductOptionDtoSerializer();
}

class _$UpdateProductOptionDtoSerializer implements PrimitiveSerializer<UpdateProductOptionDto> {
  @override
  final Iterable<Type> types = const [UpdateProductOptionDto, _$UpdateProductOptionDto];

  @override
  final String wireName = r'UpdateProductOptionDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateProductOptionDto object, {
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
    if (object.priceAdded != null) {
      yield r'priceAdded';
      yield serializers.serialize(
        object.priceAdded,
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
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateProductOptionDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateProductOptionDtoBuilder result,
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
        case r'priceAdded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.priceAdded = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateProductOptionDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateProductOptionDtoBuilder();
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

