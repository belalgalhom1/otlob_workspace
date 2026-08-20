//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_option_group_dto.g.dart';

/// UpdateOptionGroupDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [isRequired] 
/// * [minSelect] 
/// * [maxSelect] 
@BuiltValue()
abstract class UpdateOptionGroupDto implements Built<UpdateOptionGroupDto, UpdateOptionGroupDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'isRequired')
  bool? get isRequired;

  @BuiltValueField(wireName: r'minSelect')
  num? get minSelect;

  @BuiltValueField(wireName: r'maxSelect')
  num? get maxSelect;

  UpdateOptionGroupDto._();

  factory UpdateOptionGroupDto([void updates(UpdateOptionGroupDtoBuilder b)]) = _$UpdateOptionGroupDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateOptionGroupDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateOptionGroupDto> get serializer => _$UpdateOptionGroupDtoSerializer();
}

class _$UpdateOptionGroupDtoSerializer implements PrimitiveSerializer<UpdateOptionGroupDto> {
  @override
  final Iterable<Type> types = const [UpdateOptionGroupDto, _$UpdateOptionGroupDto];

  @override
  final String wireName = r'UpdateOptionGroupDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateOptionGroupDto object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateOptionGroupDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateOptionGroupDtoBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateOptionGroupDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateOptionGroupDtoBuilder();
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

