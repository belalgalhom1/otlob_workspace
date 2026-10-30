//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'join_waitlist_dto.g.dart';

/// JoinWaitlistDto
///
/// Properties:
/// * [shiftPoolId] 
@BuiltValue()
abstract class JoinWaitlistDto implements Built<JoinWaitlistDto, JoinWaitlistDtoBuilder> {
  @BuiltValueField(wireName: r'shiftPoolId')
  String get shiftPoolId;

  JoinWaitlistDto._();

  factory JoinWaitlistDto([void updates(JoinWaitlistDtoBuilder b)]) = _$JoinWaitlistDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JoinWaitlistDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JoinWaitlistDto> get serializer => _$JoinWaitlistDtoSerializer();
}

class _$JoinWaitlistDtoSerializer implements PrimitiveSerializer<JoinWaitlistDto> {
  @override
  final Iterable<Type> types = const [JoinWaitlistDto, _$JoinWaitlistDto];

  @override
  final String wireName = r'JoinWaitlistDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JoinWaitlistDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'shiftPoolId';
    yield serializers.serialize(
      object.shiftPoolId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    JoinWaitlistDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JoinWaitlistDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'shiftPoolId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shiftPoolId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JoinWaitlistDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JoinWaitlistDtoBuilder();
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

