//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_user_dto.g.dart';

/// UpdateUserDto
///
/// Properties:
/// * [name] 
/// * [email] 
/// * [phone] 
/// * [language] 
/// * [autoReplyMessage] 
@BuiltValue()
abstract class UpdateUserDto implements Built<UpdateUserDto, UpdateUserDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'language')
  UpdateUserDtoLanguageEnum? get language;
  // enum languageEnum {  EN,  AR,  };

  @BuiltValueField(wireName: r'autoReplyMessage')
  String? get autoReplyMessage;

  UpdateUserDto._();

  factory UpdateUserDto([void updates(UpdateUserDtoBuilder b)]) = _$UpdateUserDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateUserDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateUserDto> get serializer => _$UpdateUserDtoSerializer();
}

class _$UpdateUserDtoSerializer implements PrimitiveSerializer<UpdateUserDto> {
  @override
  final Iterable<Type> types = const [UpdateUserDto, _$UpdateUserDto];

  @override
  final String wireName = r'UpdateUserDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType(String),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    if (object.language != null) {
      yield r'language';
      yield serializers.serialize(
        object.language,
        specifiedType: const FullType(UpdateUserDtoLanguageEnum),
      );
    }
    if (object.autoReplyMessage != null) {
      yield r'autoReplyMessage';
      yield serializers.serialize(
        object.autoReplyMessage,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateUserDtoBuilder result,
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
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'language':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateUserDtoLanguageEnum),
          ) as UpdateUserDtoLanguageEnum;
          result.language = valueDes;
          break;
        case r'autoReplyMessage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.autoReplyMessage = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateUserDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateUserDtoBuilder();
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

class UpdateUserDtoLanguageEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'EN')
  static const UpdateUserDtoLanguageEnum EN = _$updateUserDtoLanguageEnum_EN;
  @BuiltValueEnumConst(wireName: r'AR')
  static const UpdateUserDtoLanguageEnum AR = _$updateUserDtoLanguageEnum_AR;

  static Serializer<UpdateUserDtoLanguageEnum> get serializer => _$updateUserDtoLanguageEnumSerializer;

  const UpdateUserDtoLanguageEnum._(String name): super(name);

  static BuiltSet<UpdateUserDtoLanguageEnum> get values => _$updateUserDtoLanguageEnumValues;
  static UpdateUserDtoLanguageEnum valueOf(String name) => _$updateUserDtoLanguageEnumValueOf(name);
}

