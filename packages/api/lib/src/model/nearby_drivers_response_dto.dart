//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/nearby_driver_preview_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'nearby_drivers_response_dto.g.dart';

/// NearbyDriversResponseDto
///
/// Properties:
/// * [radiusKm] 
/// * [count] 
/// * [drivers] 
/// * [fetchedAt] 
@BuiltValue()
abstract class NearbyDriversResponseDto implements Built<NearbyDriversResponseDto, NearbyDriversResponseDtoBuilder> {
  @BuiltValueField(wireName: r'radiusKm')
  num get radiusKm;

  @BuiltValueField(wireName: r'count')
  num get count;

  @BuiltValueField(wireName: r'drivers')
  BuiltList<NearbyDriverPreviewDto> get drivers;

  @BuiltValueField(wireName: r'fetchedAt')
  String get fetchedAt;

  NearbyDriversResponseDto._();

  factory NearbyDriversResponseDto([void updates(NearbyDriversResponseDtoBuilder b)]) = _$NearbyDriversResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NearbyDriversResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NearbyDriversResponseDto> get serializer => _$NearbyDriversResponseDtoSerializer();
}

class _$NearbyDriversResponseDtoSerializer implements PrimitiveSerializer<NearbyDriversResponseDto> {
  @override
  final Iterable<Type> types = const [NearbyDriversResponseDto, _$NearbyDriversResponseDto];

  @override
  final String wireName = r'NearbyDriversResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NearbyDriversResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'radiusKm';
    yield serializers.serialize(
      object.radiusKm,
      specifiedType: const FullType(num),
    );
    yield r'count';
    yield serializers.serialize(
      object.count,
      specifiedType: const FullType(num),
    );
    yield r'drivers';
    yield serializers.serialize(
      object.drivers,
      specifiedType: const FullType(BuiltList, [FullType(NearbyDriverPreviewDto)]),
    );
    yield r'fetchedAt';
    yield serializers.serialize(
      object.fetchedAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NearbyDriversResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NearbyDriversResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'radiusKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.radiusKm = valueDes;
          break;
        case r'count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.count = valueDes;
          break;
        case r'drivers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(NearbyDriverPreviewDto)]),
          ) as BuiltList<NearbyDriverPreviewDto>;
          result.drivers.replace(valueDes);
          break;
        case r'fetchedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fetchedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NearbyDriversResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NearbyDriversResponseDtoBuilder();
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

