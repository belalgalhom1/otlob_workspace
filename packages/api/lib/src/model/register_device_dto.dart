//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_device_dto.g.dart';

/// RegisterDeviceDto
///
/// Properties:
/// * [token] 
/// * [platform] 
@BuiltValue()
abstract class RegisterDeviceDto implements Built<RegisterDeviceDto, RegisterDeviceDtoBuilder> {
  @BuiltValueField(wireName: r'token')
  String get token;

  @BuiltValueField(wireName: r'platform')
  RegisterDeviceDtoPlatformEnum get platform;
  // enum platformEnum {  ANDROID,  IOS,  WEB,  };

  RegisterDeviceDto._();

  factory RegisterDeviceDto([void updates(RegisterDeviceDtoBuilder b)]) = _$RegisterDeviceDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterDeviceDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterDeviceDto> get serializer => _$RegisterDeviceDtoSerializer();
}

class _$RegisterDeviceDtoSerializer implements PrimitiveSerializer<RegisterDeviceDto> {
  @override
  final Iterable<Type> types = const [RegisterDeviceDto, _$RegisterDeviceDto];

  @override
  final String wireName = r'RegisterDeviceDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterDeviceDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'token';
    yield serializers.serialize(
      object.token,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(RegisterDeviceDtoPlatformEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterDeviceDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegisterDeviceDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.token = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RegisterDeviceDtoPlatformEnum),
          ) as RegisterDeviceDtoPlatformEnum;
          result.platform = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterDeviceDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterDeviceDtoBuilder();
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

class RegisterDeviceDtoPlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ANDROID')
  static const RegisterDeviceDtoPlatformEnum ANDROID = _$registerDeviceDtoPlatformEnum_ANDROID;
  @BuiltValueEnumConst(wireName: r'IOS')
  static const RegisterDeviceDtoPlatformEnum IOS = _$registerDeviceDtoPlatformEnum_IOS;
  @BuiltValueEnumConst(wireName: r'WEB')
  static const RegisterDeviceDtoPlatformEnum WEB = _$registerDeviceDtoPlatformEnum_WEB;

  static Serializer<RegisterDeviceDtoPlatformEnum> get serializer => _$registerDeviceDtoPlatformEnumSerializer;

  const RegisterDeviceDtoPlatformEnum._(String name): super(name);

  static BuiltSet<RegisterDeviceDtoPlatformEnum> get values => _$registerDeviceDtoPlatformEnumValues;
  static RegisterDeviceDtoPlatformEnum valueOf(String name) => _$registerDeviceDtoPlatformEnumValueOf(name);
}

