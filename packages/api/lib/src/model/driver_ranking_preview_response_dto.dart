//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_ranking_preview_item_dto.dart';
import 'package:api/src/model/driver_ranking_pagination_meta_dto.dart';
import 'package:api/src/model/ranking_week_window_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_preview_response_dto.g.dart';

/// DriverRankingPreviewResponseDto
///
/// Properties:
/// * [week] 
/// * [alreadyExecuted] 
/// * [totalDrivers] 
/// * [promotedCount] 
/// * [demotedCount] 
/// * [unchangedCount] 
/// * [inactiveCount] 
/// * [drivers] 
/// * [meta] 
@BuiltValue()
abstract class DriverRankingPreviewResponseDto implements Built<DriverRankingPreviewResponseDto, DriverRankingPreviewResponseDtoBuilder> {
  @BuiltValueField(wireName: r'week')
  RankingWeekWindowDto get week;

  @BuiltValueField(wireName: r'alreadyExecuted')
  bool get alreadyExecuted;

  @BuiltValueField(wireName: r'totalDrivers')
  num get totalDrivers;

  @BuiltValueField(wireName: r'promotedCount')
  num get promotedCount;

  @BuiltValueField(wireName: r'demotedCount')
  num get demotedCount;

  @BuiltValueField(wireName: r'unchangedCount')
  num get unchangedCount;

  @BuiltValueField(wireName: r'inactiveCount')
  num get inactiveCount;

  @BuiltValueField(wireName: r'drivers')
  BuiltList<DriverRankingPreviewItemDto> get drivers;

  @BuiltValueField(wireName: r'meta')
  DriverRankingPaginationMetaDto get meta;

  DriverRankingPreviewResponseDto._();

  factory DriverRankingPreviewResponseDto([void updates(DriverRankingPreviewResponseDtoBuilder b)]) = _$DriverRankingPreviewResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankingPreviewResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankingPreviewResponseDto> get serializer => _$DriverRankingPreviewResponseDtoSerializer();
}

class _$DriverRankingPreviewResponseDtoSerializer implements PrimitiveSerializer<DriverRankingPreviewResponseDto> {
  @override
  final Iterable<Type> types = const [DriverRankingPreviewResponseDto, _$DriverRankingPreviewResponseDto];

  @override
  final String wireName = r'DriverRankingPreviewResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankingPreviewResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'week';
    yield serializers.serialize(
      object.week,
      specifiedType: const FullType(RankingWeekWindowDto),
    );
    yield r'alreadyExecuted';
    yield serializers.serialize(
      object.alreadyExecuted,
      specifiedType: const FullType(bool),
    );
    yield r'totalDrivers';
    yield serializers.serialize(
      object.totalDrivers,
      specifiedType: const FullType(num),
    );
    yield r'promotedCount';
    yield serializers.serialize(
      object.promotedCount,
      specifiedType: const FullType(num),
    );
    yield r'demotedCount';
    yield serializers.serialize(
      object.demotedCount,
      specifiedType: const FullType(num),
    );
    yield r'unchangedCount';
    yield serializers.serialize(
      object.unchangedCount,
      specifiedType: const FullType(num),
    );
    yield r'inactiveCount';
    yield serializers.serialize(
      object.inactiveCount,
      specifiedType: const FullType(num),
    );
    yield r'drivers';
    yield serializers.serialize(
      object.drivers,
      specifiedType: const FullType(BuiltList, [FullType(DriverRankingPreviewItemDto)]),
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
    DriverRankingPreviewResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankingPreviewResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'week':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RankingWeekWindowDto),
          ) as RankingWeekWindowDto;
          result.week.replace(valueDes);
          break;
        case r'alreadyExecuted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.alreadyExecuted = valueDes;
          break;
        case r'totalDrivers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalDrivers = valueDes;
          break;
        case r'promotedCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.promotedCount = valueDes;
          break;
        case r'demotedCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.demotedCount = valueDes;
          break;
        case r'unchangedCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.unchangedCount = valueDes;
          break;
        case r'inactiveCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.inactiveCount = valueDes;
          break;
        case r'drivers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverRankingPreviewItemDto)]),
          ) as BuiltList<DriverRankingPreviewItemDto>;
          result.drivers.replace(valueDes);
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
  DriverRankingPreviewResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankingPreviewResponseDtoBuilder();
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

