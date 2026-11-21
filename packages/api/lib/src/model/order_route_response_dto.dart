//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/route_coordinate_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_route_response_dto.g.dart';

/// OrderRouteResponseDto
///
/// Properties:
/// * [orderId] 
/// * [orderStatus] 
/// * [encodedPolyline] - Google Encoded Polyline string (precision 5).
/// * [coordinates] - Decoded road-following coordinates in traversal order.
/// * [waypoints] - Ordered waypoints used to compute the route.
/// * [distanceMeters] - Total route distance in meters.
/// * [durationSeconds] - Estimated driving duration in seconds (0 when fallback).
/// * [isRoadRoute] - True when geometry follows real driving roads; false only when fallback straight chord is returned.
/// * [source_] 
/// * [driverLocation] - Live assigned driver location included as route origin when available.
/// * [destination] - Resolved route destination point.
@BuiltValue()
abstract class OrderRouteResponseDto implements Built<OrderRouteResponseDto, OrderRouteResponseDtoBuilder> {
  @BuiltValueField(wireName: r'orderId')
  JsonObject? get orderId;

  @BuiltValueField(wireName: r'orderStatus')
  JsonObject? get orderStatus;

  /// Google Encoded Polyline string (precision 5).
  @BuiltValueField(wireName: r'encodedPolyline')
  String get encodedPolyline;

  /// Decoded road-following coordinates in traversal order.
  @BuiltValueField(wireName: r'coordinates')
  BuiltList<RouteCoordinateDto> get coordinates;

  /// Ordered waypoints used to compute the route.
  @BuiltValueField(wireName: r'waypoints')
  BuiltList<RouteCoordinateDto> get waypoints;

  /// Total route distance in meters.
  @BuiltValueField(wireName: r'distanceMeters')
  num get distanceMeters;

  /// Estimated driving duration in seconds (0 when fallback).
  @BuiltValueField(wireName: r'durationSeconds')
  num get durationSeconds;

  /// True when geometry follows real driving roads; false only when fallback straight chord is returned.
  @BuiltValueField(wireName: r'isRoadRoute')
  bool get isRoadRoute;

  @BuiltValueField(wireName: r'source')
  OrderRouteResponseDtoSource_Enum get source_;
  // enum source_Enum {  osrm,  fallback,  };

  /// Live assigned driver location included as route origin when available.
  @BuiltValueField(wireName: r'driverLocation')
  RouteCoordinateDto? get driverLocation;

  /// Resolved route destination point.
  @BuiltValueField(wireName: r'destination')
  RouteCoordinateDto? get destination;

  OrderRouteResponseDto._();

  factory OrderRouteResponseDto([void updates(OrderRouteResponseDtoBuilder b)]) = _$OrderRouteResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderRouteResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderRouteResponseDto> get serializer => _$OrderRouteResponseDtoSerializer();
}

class _$OrderRouteResponseDtoSerializer implements PrimitiveSerializer<OrderRouteResponseDto> {
  @override
  final Iterable<Type> types = const [OrderRouteResponseDto, _$OrderRouteResponseDto];

  @override
  final String wireName = r'OrderRouteResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderRouteResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.orderId != null) {
      yield r'orderId';
      yield serializers.serialize(
        object.orderId,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.orderStatus != null) {
      yield r'orderStatus';
      yield serializers.serialize(
        object.orderStatus,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'encodedPolyline';
    yield serializers.serialize(
      object.encodedPolyline,
      specifiedType: const FullType(String),
    );
    yield r'coordinates';
    yield serializers.serialize(
      object.coordinates,
      specifiedType: const FullType(BuiltList, [FullType(RouteCoordinateDto)]),
    );
    yield r'waypoints';
    yield serializers.serialize(
      object.waypoints,
      specifiedType: const FullType(BuiltList, [FullType(RouteCoordinateDto)]),
    );
    yield r'distanceMeters';
    yield serializers.serialize(
      object.distanceMeters,
      specifiedType: const FullType(num),
    );
    yield r'durationSeconds';
    yield serializers.serialize(
      object.durationSeconds,
      specifiedType: const FullType(num),
    );
    yield r'isRoadRoute';
    yield serializers.serialize(
      object.isRoadRoute,
      specifiedType: const FullType(bool),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(OrderRouteResponseDtoSource_Enum),
    );
    if (object.driverLocation != null) {
      yield r'driverLocation';
      yield serializers.serialize(
        object.driverLocation,
        specifiedType: const FullType.nullable(RouteCoordinateDto),
      );
    }
    if (object.destination != null) {
      yield r'destination';
      yield serializers.serialize(
        object.destination,
        specifiedType: const FullType.nullable(RouteCoordinateDto),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderRouteResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderRouteResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.orderId = valueDes;
          break;
        case r'orderStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.orderStatus = valueDes;
          break;
        case r'encodedPolyline':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.encodedPolyline = valueDes;
          break;
        case r'coordinates':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RouteCoordinateDto)]),
          ) as BuiltList<RouteCoordinateDto>;
          result.coordinates.replace(valueDes);
          break;
        case r'waypoints':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RouteCoordinateDto)]),
          ) as BuiltList<RouteCoordinateDto>;
          result.waypoints.replace(valueDes);
          break;
        case r'distanceMeters':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.distanceMeters = valueDes;
          break;
        case r'durationSeconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.durationSeconds = valueDes;
          break;
        case r'isRoadRoute':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isRoadRoute = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderRouteResponseDtoSource_Enum),
          ) as OrderRouteResponseDtoSource_Enum;
          result.source_ = valueDes;
          break;
        case r'driverLocation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(RouteCoordinateDto),
          ) as RouteCoordinateDto?;
          if (valueDes == null) continue;
          result.driverLocation.replace(valueDes);
          break;
        case r'destination':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(RouteCoordinateDto),
          ) as RouteCoordinateDto?;
          if (valueDes == null) continue;
          result.destination.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderRouteResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderRouteResponseDtoBuilder();
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

class OrderRouteResponseDtoSource_Enum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'osrm')
  static const OrderRouteResponseDtoSource_Enum osrm = _$orderRouteResponseDtoSourceEnum_osrm;
  @BuiltValueEnumConst(wireName: r'fallback')
  static const OrderRouteResponseDtoSource_Enum fallback = _$orderRouteResponseDtoSourceEnum_fallback;

  static Serializer<OrderRouteResponseDtoSource_Enum> get serializer => _$orderRouteResponseDtoSourceEnumSerializer;

  const OrderRouteResponseDtoSource_Enum._(String name): super(name);

  static BuiltSet<OrderRouteResponseDtoSource_Enum> get values => _$orderRouteResponseDtoSourceEnumValues;
  static OrderRouteResponseDtoSource_Enum valueOf(String name) => _$orderRouteResponseDtoSourceEnumValueOf(name);
}

