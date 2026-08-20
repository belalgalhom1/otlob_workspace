//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_order_conversation_dto.g.dart';

/// CreateOrderConversationDto
///
/// Properties:
/// * [orderId] 
@BuiltValue()
abstract class CreateOrderConversationDto implements Built<CreateOrderConversationDto, CreateOrderConversationDtoBuilder> {
  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  CreateOrderConversationDto._();

  factory CreateOrderConversationDto([void updates(CreateOrderConversationDtoBuilder b)]) = _$CreateOrderConversationDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateOrderConversationDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateOrderConversationDto> get serializer => _$CreateOrderConversationDtoSerializer();
}

class _$CreateOrderConversationDtoSerializer implements PrimitiveSerializer<CreateOrderConversationDto> {
  @override
  final Iterable<Type> types = const [CreateOrderConversationDto, _$CreateOrderConversationDto];

  @override
  final String wireName = r'CreateOrderConversationDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateOrderConversationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'orderId';
    yield serializers.serialize(
      object.orderId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateOrderConversationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateOrderConversationDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateOrderConversationDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateOrderConversationDtoBuilder();
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

