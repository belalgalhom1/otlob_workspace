//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'route_coordinate_dto.g.dart';

/// RouteCoordinateDto
///
/// Properties:
/// * [latitude] - Latitude in decimal degrees
/// * [longitude] - Longitude in decimal degrees
@BuiltValue()
abstract class RouteCoordinateDto implements Built<RouteCoordinateDto, RouteCoordinateDtoBuilder> {
  /// Latitude in decimal degrees
  @BuiltValueField(wireName: r'latitude')
  num get latitude;

  /// Longitude in decimal degrees
  @BuiltValueField(wireName: r'longitude')
  num get longitude;

  RouteCoordinateDto._();

  factory RouteCoordinateDto([void updates(RouteCoordinateDtoBuilder b)]) = _$RouteCoordinateDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RouteCoordinateDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RouteCoordinateDto> get serializer => _$RouteCoordinateDtoSerializer();
}

class _$RouteCoordinateDtoSerializer implements PrimitiveSerializer<RouteCoordinateDto> {
  @override
  final Iterable<Type> types = const [RouteCoordinateDto, _$RouteCoordinateDto];

  @override
  final String wireName = r'RouteCoordinateDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RouteCoordinateDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'latitude';
    yield serializers.serialize(
      object.latitude,
      specifiedType: const FullType(num),
    );
    yield r'longitude';
    yield serializers.serialize(
      object.longitude,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RouteCoordinateDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RouteCoordinateDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'latitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.latitude = valueDes;
          break;
        case r'longitude':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.longitude = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RouteCoordinateDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RouteCoordinateDtoBuilder();
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

