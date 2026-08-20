//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_product_option_dto.g.dart';

/// CreateProductOptionDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [priceAdded] 
/// * [isActive] 
@BuiltValue()
abstract class CreateProductOptionDto implements Built<CreateProductOptionDto, CreateProductOptionDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'priceAdded')
  num? get priceAdded;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  CreateProductOptionDto._();

  factory CreateProductOptionDto([void updates(CreateProductOptionDtoBuilder b)]) = _$CreateProductOptionDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateProductOptionDtoBuilder b) => b
      ..priceAdded = 0
      ..isActive = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateProductOptionDto> get serializer => _$CreateProductOptionDtoSerializer();
}

class _$CreateProductOptionDtoSerializer implements PrimitiveSerializer<CreateProductOptionDto> {
  @override
  final Iterable<Type> types = const [CreateProductOptionDto, _$CreateProductOptionDto];

  @override
  final String wireName = r'CreateProductOptionDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateProductOptionDto object, {
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
    CreateProductOptionDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateProductOptionDtoBuilder result,
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
  CreateProductOptionDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateProductOptionDtoBuilder();
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

