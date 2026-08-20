//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'verify_otp_dto.g.dart';

/// VerifyOtpDto
///
/// Properties:
/// * [contact] 
/// * [code] 
/// * [purpose] 
@BuiltValue()
abstract class VerifyOtpDto implements Built<VerifyOtpDto, VerifyOtpDtoBuilder> {
  @BuiltValueField(wireName: r'contact')
  String get contact;

  @BuiltValueField(wireName: r'code')
  String get code;

  @BuiltValueField(wireName: r'purpose')
  VerifyOtpDtoPurposeEnum? get purpose;
  // enum purposeEnum {  VERIFICATION,  PASSWORD_RESET,  };

  VerifyOtpDto._();

  factory VerifyOtpDto([void updates(VerifyOtpDtoBuilder b)]) = _$VerifyOtpDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VerifyOtpDtoBuilder b) => b
      ..purpose = VerifyOtpDtoPurposeEnum.valueOf('VERIFICATION');

  @BuiltValueSerializer(custom: true)
  static Serializer<VerifyOtpDto> get serializer => _$VerifyOtpDtoSerializer();
}

class _$VerifyOtpDtoSerializer implements PrimitiveSerializer<VerifyOtpDto> {
  @override
  final Iterable<Type> types = const [VerifyOtpDto, _$VerifyOtpDto];

  @override
  final String wireName = r'VerifyOtpDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VerifyOtpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'contact';
    yield serializers.serialize(
      object.contact,
      specifiedType: const FullType(String),
    );
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    if (object.purpose != null) {
      yield r'purpose';
      yield serializers.serialize(
        object.purpose,
        specifiedType: const FullType(VerifyOtpDtoPurposeEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    VerifyOtpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VerifyOtpDtoBuilder result,
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
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
        case r'purpose':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(VerifyOtpDtoPurposeEnum),
          ) as VerifyOtpDtoPurposeEnum;
          result.purpose = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VerifyOtpDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VerifyOtpDtoBuilder();
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

class VerifyOtpDtoPurposeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'VERIFICATION')
  static const VerifyOtpDtoPurposeEnum VERIFICATION = _$verifyOtpDtoPurposeEnum_VERIFICATION;
  @BuiltValueEnumConst(wireName: r'PASSWORD_RESET')
  static const VerifyOtpDtoPurposeEnum PASSWORD_RESET = _$verifyOtpDtoPurposeEnum_PASSWORD_RESET;

  static Serializer<VerifyOtpDtoPurposeEnum> get serializer => _$verifyOtpDtoPurposeEnumSerializer;

  const VerifyOtpDtoPurposeEnum._(String name): super(name);

  static BuiltSet<VerifyOtpDtoPurposeEnum> get values => _$verifyOtpDtoPurposeEnumValues;
  static VerifyOtpDtoPurposeEnum valueOf(String name) => _$verifyOtpDtoPurposeEnumValueOf(name);
}

