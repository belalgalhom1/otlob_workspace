//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/route_coordinate_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'compute_route_dto.g.dart';

/// ComputeRouteDto
///
/// Properties:
/// * [waypoints] - Ordered driving waypoints (origin, optional stops, destination).
@BuiltValue()
abstract class ComputeRouteDto implements Built<ComputeRouteDto, ComputeRouteDtoBuilder> {
  /// Ordered driving waypoints (origin, optional stops, destination).
  @BuiltValueField(wireName: r'waypoints')
  BuiltList<RouteCoordinateDto> get waypoints;

  ComputeRouteDto._();

  factory ComputeRouteDto([void updates(ComputeRouteDtoBuilder b)]) = _$ComputeRouteDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ComputeRouteDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ComputeRouteDto> get serializer => _$ComputeRouteDtoSerializer();
}

class _$ComputeRouteDtoSerializer implements PrimitiveSerializer<ComputeRouteDto> {
  @override
  final Iterable<Type> types = const [ComputeRouteDto, _$ComputeRouteDto];

  @override
  final String wireName = r'ComputeRouteDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ComputeRouteDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'waypoints';
    yield serializers.serialize(
      object.waypoints,
      specifiedType: const FullType(BuiltList, [FullType(RouteCoordinateDto)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ComputeRouteDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ComputeRouteDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'waypoints':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RouteCoordinateDto)]),
          ) as BuiltList<RouteCoordinateDto>;
          result.waypoints.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ComputeRouteDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ComputeRouteDtoBuilder();
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

