//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_version_check_dto.g.dart';

/// AppVersionCheckDto
///
/// Properties:
/// * [platform] 
/// * [version] 
@BuiltValue()
abstract class AppVersionCheckDto implements Built<AppVersionCheckDto, AppVersionCheckDtoBuilder> {
  @BuiltValueField(wireName: r'platform')
  AppVersionCheckDtoPlatformEnum get platform;
  // enum platformEnum {  android,  ios,  };

  @BuiltValueField(wireName: r'version')
  String get version;

  AppVersionCheckDto._();

  factory AppVersionCheckDto([void updates(AppVersionCheckDtoBuilder b)]) = _$AppVersionCheckDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AppVersionCheckDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AppVersionCheckDto> get serializer => _$AppVersionCheckDtoSerializer();
}

class _$AppVersionCheckDtoSerializer implements PrimitiveSerializer<AppVersionCheckDto> {
  @override
  final Iterable<Type> types = const [AppVersionCheckDto, _$AppVersionCheckDto];

  @override
  final String wireName = r'AppVersionCheckDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AppVersionCheckDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(AppVersionCheckDtoPlatformEnum),
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
    AppVersionCheckDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AppVersionCheckDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AppVersionCheckDtoPlatformEnum),
          ) as AppVersionCheckDtoPlatformEnum;
          result.platform = valueDes;
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
  AppVersionCheckDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AppVersionCheckDtoBuilder();
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

class AppVersionCheckDtoPlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'android')
  static const AppVersionCheckDtoPlatformEnum android = _$appVersionCheckDtoPlatformEnum_android;
  @BuiltValueEnumConst(wireName: r'ios')
  static const AppVersionCheckDtoPlatformEnum ios = _$appVersionCheckDtoPlatformEnum_ios;

  static Serializer<AppVersionCheckDtoPlatformEnum> get serializer => _$appVersionCheckDtoPlatformEnumSerializer;

  const AppVersionCheckDtoPlatformEnum._(String name): super(name);

  static BuiltSet<AppVersionCheckDtoPlatformEnum> get values => _$appVersionCheckDtoPlatformEnumValues;
  static AppVersionCheckDtoPlatformEnum valueOf(String name) => _$appVersionCheckDtoPlatformEnumValueOf(name);
}

