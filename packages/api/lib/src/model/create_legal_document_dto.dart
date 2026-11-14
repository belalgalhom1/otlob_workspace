//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_legal_document_dto.g.dart';

/// CreateLegalDocumentDto
///
/// Properties:
/// * [type] 
/// * [title] 
/// * [titleAr] 
/// * [content] 
/// * [contentAr] 
/// * [version] 
@BuiltValue()
abstract class CreateLegalDocumentDto implements Built<CreateLegalDocumentDto, CreateLegalDocumentDtoBuilder> {
  @BuiltValueField(wireName: r'type')
  CreateLegalDocumentDtoTypeEnum get type;
  // enum typeEnum {  TERMS_OF_USE,  PRIVACY_POLICY,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'titleAr')
  String get titleAr;

  @BuiltValueField(wireName: r'content')
  String get content;

  @BuiltValueField(wireName: r'contentAr')
  String get contentAr;

  @BuiltValueField(wireName: r'version')
  String get version;

  CreateLegalDocumentDto._();

  factory CreateLegalDocumentDto([void updates(CreateLegalDocumentDtoBuilder b)]) = _$CreateLegalDocumentDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateLegalDocumentDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateLegalDocumentDto> get serializer => _$CreateLegalDocumentDtoSerializer();
}

class _$CreateLegalDocumentDtoSerializer implements PrimitiveSerializer<CreateLegalDocumentDto> {
  @override
  final Iterable<Type> types = const [CreateLegalDocumentDto, _$CreateLegalDocumentDto];

  @override
  final String wireName = r'CreateLegalDocumentDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateLegalDocumentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(CreateLegalDocumentDtoTypeEnum),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'titleAr';
    yield serializers.serialize(
      object.titleAr,
      specifiedType: const FullType(String),
    );
    yield r'content';
    yield serializers.serialize(
      object.content,
      specifiedType: const FullType(String),
    );
    yield r'contentAr';
    yield serializers.serialize(
      object.contentAr,
      specifiedType: const FullType(String),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateLegalDocumentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateLegalDocumentDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CreateLegalDocumentDtoTypeEnum),
          ) as CreateLegalDocumentDtoTypeEnum;
          result.type = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'titleAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.titleAr = valueDes;
          break;
        case r'content':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.content = valueDes;
          break;
        case r'contentAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contentAr = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  CreateLegalDocumentDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateLegalDocumentDtoBuilder();
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

class CreateLegalDocumentDtoTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'TERMS_OF_USE')
  static const CreateLegalDocumentDtoTypeEnum TERMS_OF_USE = _$createLegalDocumentDtoTypeEnum_TERMS_OF_USE;
  @BuiltValueEnumConst(wireName: r'PRIVACY_POLICY')
  static const CreateLegalDocumentDtoTypeEnum PRIVACY_POLICY = _$createLegalDocumentDtoTypeEnum_PRIVACY_POLICY;

  static Serializer<CreateLegalDocumentDtoTypeEnum> get serializer => _$createLegalDocumentDtoTypeEnumSerializer;

  const CreateLegalDocumentDtoTypeEnum._(String name): super(name);

  static BuiltSet<CreateLegalDocumentDtoTypeEnum> get values => _$createLegalDocumentDtoTypeEnumValues;
  static CreateLegalDocumentDtoTypeEnum valueOf(String name) => _$createLegalDocumentDtoTypeEnumValueOf(name);
}

