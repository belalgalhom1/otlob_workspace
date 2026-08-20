//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'check_location_dto.g.dart';

/// CheckLocationDto
///
/// Properties:
/// * [longitude] 
/// * [latitude] 
@BuiltValue()
abstract class CheckLocationDto implements Built<CheckLocationDto, CheckLocationDtoBuilder> {
  @BuiltValueField(wireName: r'longitude')
  num get longitude;

  @BuiltValueField(wireName: r'latitude')
  num get latitude;

  CheckLocationDto._();

  factory CheckLocationDto([void updates(CheckLocationDtoBuilder b)]) = _$CheckLocationDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CheckLocationDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CheckLocationDto> get serializer => _$CheckLocationDtoSerializer();
}

class _$CheckLocationDtoSerializer implements PrimitiveSerializer<CheckLocationDto> {
  @override
  final Iterable<Type> types = const [CheckLocationDto, _$CheckLocationDto];

  @override
  final String wireName = r'CheckLocationDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CheckLocationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'longitude';
    yield serializers.serialize(
      object.longitude,
      specifiedType: const FullType(num),
    );
    yield r'latitude';
    yield serializers.serialize(
      object.latitude,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CheckLocationDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CheckLocationDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'longitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.longitude = valueDes;
          break;
        case r'latitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.latitude = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CheckLocationDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CheckLocationDtoBuilder();
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

