//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_ranking_pagination_meta_dto.dart';
import 'package:api/src/model/driver_delivery_incident_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'paginated_delivery_incidents_response_dto.g.dart';

/// PaginatedDeliveryIncidentsResponseDto
///
/// Properties:
/// * [data] 
/// * [meta] 
@BuiltValue()
abstract class PaginatedDeliveryIncidentsResponseDto implements Built<PaginatedDeliveryIncidentsResponseDto, PaginatedDeliveryIncidentsResponseDtoBuilder> {
  @BuiltValueField(wireName: r'data')
  BuiltList<DriverDeliveryIncidentDto> get data;

  @BuiltValueField(wireName: r'meta')
  DriverRankingPaginationMetaDto get meta;

  PaginatedDeliveryIncidentsResponseDto._();

  factory PaginatedDeliveryIncidentsResponseDto([void updates(PaginatedDeliveryIncidentsResponseDtoBuilder b)]) = _$PaginatedDeliveryIncidentsResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaginatedDeliveryIncidentsResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaginatedDeliveryIncidentsResponseDto> get serializer => _$PaginatedDeliveryIncidentsResponseDtoSerializer();
}

class _$PaginatedDeliveryIncidentsResponseDtoSerializer implements PrimitiveSerializer<PaginatedDeliveryIncidentsResponseDto> {
  @override
  final Iterable<Type> types = const [PaginatedDeliveryIncidentsResponseDto, _$PaginatedDeliveryIncidentsResponseDto];

  @override
  final String wireName = r'PaginatedDeliveryIncidentsResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaginatedDeliveryIncidentsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'data';
    yield serializers.serialize(
      object.data,
      specifiedType: const FullType(BuiltList, [FullType(DriverDeliveryIncidentDto)]),
    );
    yield r'meta';
    yield serializers.serialize(
      object.meta,
      specifiedType: const FullType(DriverRankingPaginationMetaDto),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PaginatedDeliveryIncidentsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaginatedDeliveryIncidentsResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverDeliveryIncidentDto)]),
          ) as BuiltList<DriverDeliveryIncidentDto>;
          result.data.replace(valueDes);
          break;
        case r'meta':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverRankingPaginationMetaDto),
          ) as DriverRankingPaginationMetaDto;
          result.meta.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PaginatedDeliveryIncidentsResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaginatedDeliveryIncidentsResponseDtoBuilder();
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

