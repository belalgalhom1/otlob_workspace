//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'send_message_dto.g.dart';

/// SendMessageDto
///
/// Properties:
/// * [type] 
/// * [text] 
/// * [mediaUrl] 
/// * [metadata] 
/// * [replyToId] 
@BuiltValue()
abstract class SendMessageDto implements Built<SendMessageDto, SendMessageDtoBuilder> {
  @BuiltValueField(wireName: r'type')
  SendMessageDtoTypeEnum get type;
  // enum typeEnum {  TEXT,  IMAGE,  VIDEO,  AUDIO,  LOCATION,  SYSTEM,  PRODUCT,  };

  @BuiltValueField(wireName: r'text')
  String? get text;

  @BuiltValueField(wireName: r'mediaUrl')
  String? get mediaUrl;

  @BuiltValueField(wireName: r'metadata')
  JsonObject? get metadata;

  @BuiltValueField(wireName: r'replyToId')
  String? get replyToId;

  SendMessageDto._();

  factory SendMessageDto([void updates(SendMessageDtoBuilder b)]) = _$SendMessageDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SendMessageDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SendMessageDto> get serializer => _$SendMessageDtoSerializer();
}

class _$SendMessageDtoSerializer implements PrimitiveSerializer<SendMessageDto> {
  @override
  final Iterable<Type> types = const [SendMessageDto, _$SendMessageDto];

  @override
  final String wireName = r'SendMessageDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SendMessageDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(SendMessageDtoTypeEnum),
    );
    if (object.text != null) {
      yield r'text';
      yield serializers.serialize(
        object.text,
        specifiedType: const FullType(String),
      );
    }
    if (object.mediaUrl != null) {
      yield r'mediaUrl';
      yield serializers.serialize(
        object.mediaUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.metadata != null) {
      yield r'metadata';
      yield serializers.serialize(
        object.metadata,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.replyToId != null) {
      yield r'replyToId';
      yield serializers.serialize(
        object.replyToId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SendMessageDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SendMessageDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SendMessageDtoTypeEnum),
          ) as SendMessageDtoTypeEnum;
          result.type = valueDes;
          break;
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        case r'mediaUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mediaUrl = valueDes;
          break;
        case r'metadata':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.metadata = valueDes;
          break;
        case r'replyToId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.replyToId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SendMessageDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SendMessageDtoBuilder();
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

class SendMessageDtoTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'TEXT')
  static const SendMessageDtoTypeEnum TEXT = _$sendMessageDtoTypeEnum_TEXT;
  @BuiltValueEnumConst(wireName: r'IMAGE')
  static const SendMessageDtoTypeEnum IMAGE = _$sendMessageDtoTypeEnum_IMAGE;
  @BuiltValueEnumConst(wireName: r'VIDEO')
  static const SendMessageDtoTypeEnum VIDEO = _$sendMessageDtoTypeEnum_VIDEO;
  @BuiltValueEnumConst(wireName: r'AUDIO')
  static const SendMessageDtoTypeEnum AUDIO = _$sendMessageDtoTypeEnum_AUDIO;
  @BuiltValueEnumConst(wireName: r'LOCATION')
  static const SendMessageDtoTypeEnum LOCATION = _$sendMessageDtoTypeEnum_LOCATION;
  @BuiltValueEnumConst(wireName: r'SYSTEM')
  static const SendMessageDtoTypeEnum SYSTEM = _$sendMessageDtoTypeEnum_SYSTEM;
  @BuiltValueEnumConst(wireName: r'PRODUCT')
  static const SendMessageDtoTypeEnum PRODUCT = _$sendMessageDtoTypeEnum_PRODUCT;

  static Serializer<SendMessageDtoTypeEnum> get serializer => _$sendMessageDtoTypeEnumSerializer;

  const SendMessageDtoTypeEnum._(String name): super(name);

  static BuiltSet<SendMessageDtoTypeEnum> get values => _$sendMessageDtoTypeEnumValues;
  static SendMessageDtoTypeEnum valueOf(String name) => _$sendMessageDtoTypeEnumValueOf(name);
}

