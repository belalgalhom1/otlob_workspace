//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_driver_shift_dto.g.dart';

/// CreateDriverShiftDto
///
/// Properties:
/// * [startTime] 
/// * [endTime] 
/// * [zoneId] 
@BuiltValue()
abstract class CreateDriverShiftDto implements Built<CreateDriverShiftDto, CreateDriverShiftDtoBuilder> {
  @BuiltValueField(wireName: r'startTime')
  String get startTime;

  @BuiltValueField(wireName: r'endTime')
  String get endTime;

  @BuiltValueField(wireName: r'zoneId')
  String? get zoneId;

  CreateDriverShiftDto._();

  factory CreateDriverShiftDto([void updates(CreateDriverShiftDtoBuilder b)]) = _$CreateDriverShiftDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateDriverShiftDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateDriverShiftDto> get serializer => _$CreateDriverShiftDtoSerializer();
}

class _$CreateDriverShiftDtoSerializer implements PrimitiveSerializer<CreateDriverShiftDto> {
  @override
  final Iterable<Type> types = const [CreateDriverShiftDto, _$CreateDriverShiftDto];

  @override
  final String wireName = r'CreateDriverShiftDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateDriverShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'startTime';
    yield serializers.serialize(
      object.startTime,
      specifiedType: const FullType(String),
    );
    yield r'endTime';
    yield serializers.serialize(
      object.endTime,
      specifiedType: const FullType(String),
    );
    if (object.zoneId != null) {
      yield r'zoneId';
      yield serializers.serialize(
        object.zoneId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateDriverShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateDriverShiftDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'startTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.startTime = valueDes;
          break;
        case r'endTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.endTime = valueDes;
          break;
        case r'zoneId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateDriverShiftDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateDriverShiftDtoBuilder();
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

