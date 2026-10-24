//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'assign_assist_driver_dto.g.dart';

/// AssignAssistDriverDto
///
/// Properties:
/// * [driverId] - Driver to assign as the assisting driver.
@BuiltValue()
abstract class AssignAssistDriverDto implements Built<AssignAssistDriverDto, AssignAssistDriverDtoBuilder> {
  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  AssignAssistDriverDto._();

  factory AssignAssistDriverDto([void updates(AssignAssistDriverDtoBuilder b)]) = _$AssignAssistDriverDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AssignAssistDriverDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AssignAssistDriverDto> get serializer => _$AssignAssistDriverDtoSerializer();
}

class _$AssignAssistDriverDtoSerializer implements PrimitiveSerializer<AssignAssistDriverDto> {
  @override
  final Iterable<Type> types = const [AssignAssistDriverDto, _$AssignAssistDriverDto];

  @override
  final String wireName = r'AssignAssistDriverDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AssignAssistDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AssignAssistDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  AssignAssistDriverDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssignAssistDriverDtoBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'driverId':
          result.driverId = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          break;
      }
    }
    return result.build();
  }
}
