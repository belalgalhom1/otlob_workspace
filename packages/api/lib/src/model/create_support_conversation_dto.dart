//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_support_conversation_dto.g.dart';

/// CreateSupportConversationDto
///
/// Properties:
/// * [vendorId] 
@BuiltValue()
abstract class CreateSupportConversationDto implements Built<CreateSupportConversationDto, CreateSupportConversationDtoBuilder> {
  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  CreateSupportConversationDto._();

  factory CreateSupportConversationDto([void updates(CreateSupportConversationDtoBuilder b)]) = _$CreateSupportConversationDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateSupportConversationDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateSupportConversationDto> get serializer => _$CreateSupportConversationDtoSerializer();
}

class _$CreateSupportConversationDtoSerializer implements PrimitiveSerializer<CreateSupportConversationDto> {
  @override
  final Iterable<Type> types = const [CreateSupportConversationDto, _$CreateSupportConversationDto];

  @override
  final String wireName = r'CreateSupportConversationDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateSupportConversationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateSupportConversationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateSupportConversationDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateSupportConversationDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateSupportConversationDtoBuilder();
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

