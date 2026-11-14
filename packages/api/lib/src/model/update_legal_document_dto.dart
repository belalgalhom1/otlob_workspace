//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_legal_document_dto.g.dart';

/// UpdateLegalDocumentDto
///
/// Properties:
/// * [title] 
/// * [titleAr] 
/// * [content] 
/// * [contentAr] 
/// * [version] 
@BuiltValue()
abstract class UpdateLegalDocumentDto implements Built<UpdateLegalDocumentDto, UpdateLegalDocumentDtoBuilder> {
  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'titleAr')
  String? get titleAr;

  @BuiltValueField(wireName: r'content')
  String? get content;

  @BuiltValueField(wireName: r'contentAr')
  String? get contentAr;

  @BuiltValueField(wireName: r'version')
  String? get version;

  UpdateLegalDocumentDto._();

  factory UpdateLegalDocumentDto([void updates(UpdateLegalDocumentDtoBuilder b)]) = _$UpdateLegalDocumentDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateLegalDocumentDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateLegalDocumentDto> get serializer => _$UpdateLegalDocumentDtoSerializer();
}

class _$UpdateLegalDocumentDtoSerializer implements PrimitiveSerializer<UpdateLegalDocumentDto> {
  @override
  final Iterable<Type> types = const [UpdateLegalDocumentDto, _$UpdateLegalDocumentDto];

  @override
  final String wireName = r'UpdateLegalDocumentDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateLegalDocumentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType(String),
      );
    }
    if (object.titleAr != null) {
      yield r'titleAr';
      yield serializers.serialize(
        object.titleAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.content != null) {
      yield r'content';
      yield serializers.serialize(
        object.content,
        specifiedType: const FullType(String),
      );
    }
    if (object.contentAr != null) {
      yield r'contentAr';
      yield serializers.serialize(
        object.contentAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.version != null) {
      yield r'version';
      yield serializers.serialize(
        object.version,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateLegalDocumentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateLegalDocumentDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
  UpdateLegalDocumentDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateLegalDocumentDtoBuilder();
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

