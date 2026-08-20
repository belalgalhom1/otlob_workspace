//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'logout_dto.g.dart';

/// LogoutDto
///
/// Properties:
/// * [fcmToken] 
@BuiltValue()
abstract class LogoutDto implements Built<LogoutDto, LogoutDtoBuilder> {
  @BuiltValueField(wireName: r'fcmToken')
  String? get fcmToken;

  LogoutDto._();

  factory LogoutDto([void updates(LogoutDtoBuilder b)]) = _$LogoutDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LogoutDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LogoutDto> get serializer => _$LogoutDtoSerializer();
}

class _$LogoutDtoSerializer implements PrimitiveSerializer<LogoutDto> {
  @override
  final Iterable<Type> types = const [LogoutDto, _$LogoutDto];

  @override
  final String wireName = r'LogoutDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LogoutDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.fcmToken != null) {
      yield r'fcmToken';
      yield serializers.serialize(
        object.fcmToken,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    LogoutDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LogoutDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fcmToken':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fcmToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LogoutDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LogoutDtoBuilder();
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

