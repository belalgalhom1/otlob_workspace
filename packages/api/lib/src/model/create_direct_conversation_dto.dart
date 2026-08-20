//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_direct_conversation_dto.g.dart';

/// CreateDirectConversationDto
///
/// Properties:
/// * [userId] 
@BuiltValue()
abstract class CreateDirectConversationDto implements Built<CreateDirectConversationDto, CreateDirectConversationDtoBuilder> {
  @BuiltValueField(wireName: r'userId')
  String get userId;

  CreateDirectConversationDto._();

  factory CreateDirectConversationDto([void updates(CreateDirectConversationDtoBuilder b)]) = _$CreateDirectConversationDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateDirectConversationDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateDirectConversationDto> get serializer => _$CreateDirectConversationDtoSerializer();
}

class _$CreateDirectConversationDtoSerializer implements PrimitiveSerializer<CreateDirectConversationDto> {
  @override
  final Iterable<Type> types = const [CreateDirectConversationDto, _$CreateDirectConversationDto];

  @override
  final String wireName = r'CreateDirectConversationDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateDirectConversationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateDirectConversationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateDirectConversationDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateDirectConversationDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateDirectConversationDtoBuilder();
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

