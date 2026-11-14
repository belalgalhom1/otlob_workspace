//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'accept_legal_document_dto.g.dart';

/// AcceptLegalDocumentDto
///
/// Properties:
/// * [documentId] 
/// * [version] 
@BuiltValue()
abstract class AcceptLegalDocumentDto implements Built<AcceptLegalDocumentDto, AcceptLegalDocumentDtoBuilder> {
  @BuiltValueField(wireName: r'documentId')
  String get documentId;

  @BuiltValueField(wireName: r'version')
  String get version;

  AcceptLegalDocumentDto._();

  factory AcceptLegalDocumentDto([void updates(AcceptLegalDocumentDtoBuilder b)]) = _$AcceptLegalDocumentDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcceptLegalDocumentDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcceptLegalDocumentDto> get serializer => _$AcceptLegalDocumentDtoSerializer();
}

class _$AcceptLegalDocumentDtoSerializer implements PrimitiveSerializer<AcceptLegalDocumentDto> {
  @override
  final Iterable<Type> types = const [AcceptLegalDocumentDto, _$AcceptLegalDocumentDto];

  @override
  final String wireName = r'AcceptLegalDocumentDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcceptLegalDocumentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'documentId';
    yield serializers.serialize(
      object.documentId,
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
    AcceptLegalDocumentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AcceptLegalDocumentDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'documentId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.documentId = valueDes;
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
  AcceptLegalDocumentDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcceptLegalDocumentDtoBuilder();
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

