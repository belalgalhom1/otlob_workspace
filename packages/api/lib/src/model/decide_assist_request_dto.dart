//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decide_assist_request_dto.g.dart';

/// DecideAssistRequestDto
///
/// Properties:
/// * [status] - Support decision on the assistance request: APPROVED or REJECTED
@BuiltValue()
abstract class DecideAssistRequestDto implements Built<DecideAssistRequestDto, DecideAssistRequestDtoBuilder> {
  @BuiltValueField(wireName: r'status')
  String get status;

  DecideAssistRequestDto._();

  factory DecideAssistRequestDto([void updates(DecideAssistRequestDtoBuilder b)]) = _$DecideAssistRequestDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecideAssistRequestDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecideAssistRequestDto> get serializer => _$DecideAssistRequestDtoSerializer();
}

class _$DecideAssistRequestDtoSerializer implements PrimitiveSerializer<DecideAssistRequestDto> {
  @override
  final Iterable<Type> types = const [DecideAssistRequestDto, _$DecideAssistRequestDto];

  @override
  final String wireName = r'DecideAssistRequestDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecideAssistRequestDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DecideAssistRequestDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  DecideAssistRequestDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecideAssistRequestDtoBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          result.status = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          break;
      }
    }
    return result.build();
  }
}
