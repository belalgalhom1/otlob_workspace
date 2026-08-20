//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'generate_shift_pools_dto.g.dart';

/// GenerateShiftPoolsDto
///
/// Properties:
/// * [startDate] 
/// * [endDate] 
/// * [startTime] 
/// * [endTime] 
/// * [maxDrivers] 
/// * [zoneId] 
@BuiltValue()
abstract class GenerateShiftPoolsDto implements Built<GenerateShiftPoolsDto, GenerateShiftPoolsDtoBuilder> {
  @BuiltValueField(wireName: r'startDate')
  String get startDate;

  @BuiltValueField(wireName: r'endDate')
  String get endDate;

  @BuiltValueField(wireName: r'startTime')
  String get startTime;

  @BuiltValueField(wireName: r'endTime')
  String get endTime;

  @BuiltValueField(wireName: r'maxDrivers')
  num get maxDrivers;

  @BuiltValueField(wireName: r'zoneId')
  String? get zoneId;

  GenerateShiftPoolsDto._();

  factory GenerateShiftPoolsDto([void updates(GenerateShiftPoolsDtoBuilder b)]) = _$GenerateShiftPoolsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GenerateShiftPoolsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GenerateShiftPoolsDto> get serializer => _$GenerateShiftPoolsDtoSerializer();
}

class _$GenerateShiftPoolsDtoSerializer implements PrimitiveSerializer<GenerateShiftPoolsDto> {
  @override
  final Iterable<Type> types = const [GenerateShiftPoolsDto, _$GenerateShiftPoolsDto];

  @override
  final String wireName = r'GenerateShiftPoolsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GenerateShiftPoolsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'startDate';
    yield serializers.serialize(
      object.startDate,
      specifiedType: const FullType(String),
    );
    yield r'endDate';
    yield serializers.serialize(
      object.endDate,
      specifiedType: const FullType(String),
    );
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
    yield r'maxDrivers';
    yield serializers.serialize(
      object.maxDrivers,
      specifiedType: const FullType(num),
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
    GenerateShiftPoolsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GenerateShiftPoolsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'startDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.startDate = valueDes;
          break;
        case r'endDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.endDate = valueDes;
          break;
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
        case r'maxDrivers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDrivers = valueDes;
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
  GenerateShiftPoolsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GenerateShiftPoolsDtoBuilder();
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

