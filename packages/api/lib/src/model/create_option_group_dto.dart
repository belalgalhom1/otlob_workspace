//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/create_product_option_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_option_group_dto.g.dart';

/// CreateOptionGroupDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [isRequired] 
/// * [minSelect] 
/// * [maxSelect] 
/// * [options] 
@BuiltValue()
abstract class CreateOptionGroupDto implements Built<CreateOptionGroupDto, CreateOptionGroupDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'isRequired')
  bool? get isRequired;

  @BuiltValueField(wireName: r'minSelect')
  num? get minSelect;

  @BuiltValueField(wireName: r'maxSelect')
  num? get maxSelect;

  @BuiltValueField(wireName: r'options')
  BuiltList<CreateProductOptionDto>? get options;

  CreateOptionGroupDto._();

  factory CreateOptionGroupDto([void updates(CreateOptionGroupDtoBuilder b)]) = _$CreateOptionGroupDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateOptionGroupDtoBuilder b) => b
      ..isRequired = false
      ..minSelect = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateOptionGroupDto> get serializer => _$CreateOptionGroupDtoSerializer();
}

class _$CreateOptionGroupDtoSerializer implements PrimitiveSerializer<CreateOptionGroupDto> {
  @override
  final Iterable<Type> types = const [CreateOptionGroupDto, _$CreateOptionGroupDto];

  @override
  final String wireName = r'CreateOptionGroupDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateOptionGroupDto object, {
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
    if (object.isRequired != null) {
      yield r'isRequired';
      yield serializers.serialize(
        object.isRequired,
        specifiedType: const FullType(bool),
      );
    }
    if (object.minSelect != null) {
      yield r'minSelect';
      yield serializers.serialize(
        object.minSelect,
        specifiedType: const FullType(num),
      );
    }
    if (object.maxSelect != null) {
      yield r'maxSelect';
      yield serializers.serialize(
        object.maxSelect,
        specifiedType: const FullType(num),
      );
    }
    if (object.options != null) {
      yield r'options';
      yield serializers.serialize(
        object.options,
        specifiedType: const FullType(BuiltList, [FullType(CreateProductOptionDto)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateOptionGroupDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateOptionGroupDtoBuilder result,
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
        case r'options':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CreateProductOptionDto)]),
          ) as BuiltList<CreateProductOptionDto>;
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
  CreateOptionGroupDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateOptionGroupDtoBuilder();
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

