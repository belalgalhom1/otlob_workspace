//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'set_password_dto.g.dart';

/// SetPasswordDto
///
/// Properties:
/// * [newPassword] 
@BuiltValue()
abstract class SetPasswordDto implements Built<SetPasswordDto, SetPasswordDtoBuilder> {
  @BuiltValueField(wireName: r'newPassword')
  String get newPassword;

  SetPasswordDto._();

  factory SetPasswordDto([void updates(SetPasswordDtoBuilder b)]) = _$SetPasswordDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SetPasswordDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SetPasswordDto> get serializer => _$SetPasswordDtoSerializer();
}

class _$SetPasswordDtoSerializer implements PrimitiveSerializer<SetPasswordDto> {
  @override
  final Iterable<Type> types = const [SetPasswordDto, _$SetPasswordDto];

  @override
  final String wireName = r'SetPasswordDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SetPasswordDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'newPassword';
    yield serializers.serialize(
      object.newPassword,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SetPasswordDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SetPasswordDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'newPassword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.newPassword = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SetPasswordDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SetPasswordDtoBuilder();
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

