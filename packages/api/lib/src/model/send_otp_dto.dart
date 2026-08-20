//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'send_otp_dto.g.dart';

/// SendOtpDto
///
/// Properties:
/// * [contact] 
/// * [method] 
@BuiltValue()
abstract class SendOtpDto implements Built<SendOtpDto, SendOtpDtoBuilder> {
  @BuiltValueField(wireName: r'contact')
  String get contact;

  @BuiltValueField(wireName: r'method')
  SendOtpDtoMethodEnum get method;
  // enum methodEnum {  EMAIL,  SMS,  };

  SendOtpDto._();

  factory SendOtpDto([void updates(SendOtpDtoBuilder b)]) = _$SendOtpDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SendOtpDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SendOtpDto> get serializer => _$SendOtpDtoSerializer();
}

class _$SendOtpDtoSerializer implements PrimitiveSerializer<SendOtpDto> {
  @override
  final Iterable<Type> types = const [SendOtpDto, _$SendOtpDto];

  @override
  final String wireName = r'SendOtpDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SendOtpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'contact';
    yield serializers.serialize(
      object.contact,
      specifiedType: const FullType(String),
    );
    yield r'method';
    yield serializers.serialize(
      object.method,
      specifiedType: const FullType(SendOtpDtoMethodEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SendOtpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SendOtpDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'contact':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contact = valueDes;
          break;
        case r'method':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SendOtpDtoMethodEnum),
          ) as SendOtpDtoMethodEnum;
          result.method = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SendOtpDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SendOtpDtoBuilder();
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

class SendOtpDtoMethodEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'EMAIL')
  static const SendOtpDtoMethodEnum EMAIL = _$sendOtpDtoMethodEnum_EMAIL;
  @BuiltValueEnumConst(wireName: r'SMS')
  static const SendOtpDtoMethodEnum SMS = _$sendOtpDtoMethodEnum_SMS;

  static Serializer<SendOtpDtoMethodEnum> get serializer => _$sendOtpDtoMethodEnumSerializer;

  const SendOtpDtoMethodEnum._(String name): super(name);

  static BuiltSet<SendOtpDtoMethodEnum> get values => _$sendOtpDtoMethodEnumValues;
  static SendOtpDtoMethodEnum valueOf(String name) => _$sendOtpDtoMethodEnumValueOf(name);
}

