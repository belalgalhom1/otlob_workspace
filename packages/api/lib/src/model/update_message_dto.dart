//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_message_dto.g.dart';

/// UpdateMessageDto
///
/// Properties:
/// * [text] 
@BuiltValue()
abstract class UpdateMessageDto implements Built<UpdateMessageDto, UpdateMessageDtoBuilder> {
  @BuiltValueField(wireName: r'text')
  String get text;

  UpdateMessageDto._();

  factory UpdateMessageDto([void updates(UpdateMessageDtoBuilder b)]) = _$UpdateMessageDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateMessageDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateMessageDto> get serializer => _$UpdateMessageDtoSerializer();
}

class _$UpdateMessageDtoSerializer implements PrimitiveSerializer<UpdateMessageDto> {
  @override
  final Iterable<Type> types = const [UpdateMessageDto, _$UpdateMessageDto];

  @override
  final String wireName = r'UpdateMessageDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateMessageDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateMessageDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateMessageDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateMessageDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateMessageDtoBuilder();
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

