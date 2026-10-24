//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'request_assist_driver_dto.g.dart';

/// RequestAssistDriverDto
///
/// Properties:
/// * [reason] - Why this delivery needs a second pair of hands
/// * [note]
@BuiltValue()
abstract class RequestAssistDriverDto implements Built<RequestAssistDriverDto, RequestAssistDriverDtoBuilder> {
  @BuiltValueField(wireName: r'reason')
  String get reason;

  @BuiltValueField(wireName: r'note')
  String? get note;

  RequestAssistDriverDto._();

  factory RequestAssistDriverDto([void updates(RequestAssistDriverDtoBuilder b)]) = _$RequestAssistDriverDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RequestAssistDriverDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RequestAssistDriverDto> get serializer => _$RequestAssistDriverDtoSerializer();
}

class _$RequestAssistDriverDtoSerializer implements PrimitiveSerializer<RequestAssistDriverDto> {
  @override
  final Iterable<Type> types = const [RequestAssistDriverDto, _$RequestAssistDriverDto];

  @override
  final String wireName = r'RequestAssistDriverDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RequestAssistDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RequestAssistDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  RequestAssistDriverDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RequestAssistDriverDtoBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          result.reason = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          break;
        case r'note':
          result.note = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String?;
          break;
      }
    }
    return result.build();
  }
}
