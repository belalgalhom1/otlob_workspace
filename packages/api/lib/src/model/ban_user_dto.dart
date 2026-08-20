//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ban_user_dto.g.dart';

/// BanUserDto
///
/// Properties:
/// * [reason] 
@BuiltValue()
abstract class BanUserDto implements Built<BanUserDto, BanUserDtoBuilder> {
  @BuiltValueField(wireName: r'reason')
  String? get reason;

  BanUserDto._();

  factory BanUserDto([void updates(BanUserDtoBuilder b)]) = _$BanUserDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BanUserDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BanUserDto> get serializer => _$BanUserDtoSerializer();
}

class _$BanUserDtoSerializer implements PrimitiveSerializer<BanUserDto> {
  @override
  final Iterable<Type> types = const [BanUserDto, _$BanUserDto];

  @override
  final String wireName = r'BanUserDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BanUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BanUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BanUserDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BanUserDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BanUserDtoBuilder();
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

