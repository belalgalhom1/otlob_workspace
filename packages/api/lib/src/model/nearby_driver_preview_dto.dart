//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vehicle_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'nearby_driver_preview_dto.g.dart';

/// NearbyDriverPreviewDto
///
/// Properties:
/// * [markerKey] - Anonymized ephemeral marker key scoped to the search session for smooth real-time map tracking without exposing driver IDs or PII
/// * [latitude] 
/// * [longitude] 
/// * [vehicleType] 
/// * [distanceKm] 
@BuiltValue()
abstract class NearbyDriverPreviewDto implements Built<NearbyDriverPreviewDto, NearbyDriverPreviewDtoBuilder> {
  /// Anonymized ephemeral marker key scoped to the search session for smooth real-time map tracking without exposing driver IDs or PII
  @BuiltValueField(wireName: r'markerKey')
  String? get markerKey;

  @BuiltValueField(wireName: r'latitude')
  num get latitude;

  @BuiltValueField(wireName: r'longitude')
  num get longitude;

  @BuiltValueField(wireName: r'vehicleType')
  VehicleType get vehicleType;
  // enum vehicleTypeEnum {  BICYCLE,  MOTORCYCLE,  CAR,  MINIBUS,  TUK_TUK,  MOTOR_TRICYCLE,  QUARTER_TRUCK,  HALF_TRUCK,  };

  @BuiltValueField(wireName: r'distanceKm')
  num get distanceKm;

  NearbyDriverPreviewDto._();

  factory NearbyDriverPreviewDto([void updates(NearbyDriverPreviewDtoBuilder b)]) = _$NearbyDriverPreviewDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NearbyDriverPreviewDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NearbyDriverPreviewDto> get serializer => _$NearbyDriverPreviewDtoSerializer();
}

class _$NearbyDriverPreviewDtoSerializer implements PrimitiveSerializer<NearbyDriverPreviewDto> {
  @override
  final Iterable<Type> types = const [NearbyDriverPreviewDto, _$NearbyDriverPreviewDto];

  @override
  final String wireName = r'NearbyDriverPreviewDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NearbyDriverPreviewDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.markerKey != null) {
      yield r'markerKey';
      yield serializers.serialize(
        object.markerKey,
        specifiedType: const FullType(String),
      );
    }
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
    yield r'vehicleType';
    yield serializers.serialize(
      object.vehicleType,
      specifiedType: const FullType(VehicleType),
    );
    yield r'distanceKm';
    yield serializers.serialize(
      object.distanceKm,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NearbyDriverPreviewDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NearbyDriverPreviewDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'markerKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.markerKey = valueDes;
          break;
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
        case r'vehicleType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(VehicleType),
          ) as VehicleType;
          result.vehicleType = valueDes;
          break;
        case r'distanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.distanceKm = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NearbyDriverPreviewDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NearbyDriverPreviewDtoBuilder();
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

