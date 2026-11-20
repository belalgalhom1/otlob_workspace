//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_metrics_snapshot_dto.dart';
import 'package:api/src/model/driver_ranking_outcome.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_tier.dart';
import 'package:api/src/model/driver_rank_change_reason.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_preview_item_dto.g.dart';

/// DriverRankingPreviewItemDto
///
/// Properties:
/// * [driverId] 
/// * [driverName] 
/// * [previousTier] 
/// * [newTier] 
/// * [changeReason] 
/// * [outcome] 
/// * [performancePercentage] 
/// * [acceptanceRate] 
/// * [completionRate] 
/// * [shiftPunctualityRate] 
/// * [metricsSnapshot] 
/// * [explanations] 
@BuiltValue()
abstract class DriverRankingPreviewItemDto implements Built<DriverRankingPreviewItemDto, DriverRankingPreviewItemDtoBuilder> {
  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'driverName')
  String get driverName;

  @BuiltValueField(wireName: r'previousTier')
  DriverTier get previousTier;
  // enum previousTierEnum {  BRONZE,  SILVER,  GOLD,  };

  @BuiltValueField(wireName: r'newTier')
  DriverTier get newTier;
  // enum newTierEnum {  BRONZE,  SILVER,  GOLD,  };

  @BuiltValueField(wireName: r'changeReason')
  DriverRankChangeReason get changeReason;
  // enum changeReasonEnum {  WEEKLY_EVALUATION,  INACTIVE_DRIVER,  ADMIN_OVERRIDE,  };

  @BuiltValueField(wireName: r'outcome')
  DriverRankingOutcome get outcome;
  // enum outcomeEnum {  PROMOTED,  DEMOTED,  UNCHANGED,  INACTIVE_SILVER,  CAPPED_SILVER,  };

  @BuiltValueField(wireName: r'performancePercentage')
  num? get performancePercentage;

  @BuiltValueField(wireName: r'acceptanceRate')
  num? get acceptanceRate;

  @BuiltValueField(wireName: r'completionRate')
  num? get completionRate;

  @BuiltValueField(wireName: r'shiftPunctualityRate')
  num? get shiftPunctualityRate;

  @BuiltValueField(wireName: r'metricsSnapshot')
  DriverMetricsSnapshotDto get metricsSnapshot;

  @BuiltValueField(wireName: r'explanations')
  BuiltList<String> get explanations;

  DriverRankingPreviewItemDto._();

  factory DriverRankingPreviewItemDto([void updates(DriverRankingPreviewItemDtoBuilder b)]) = _$DriverRankingPreviewItemDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankingPreviewItemDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankingPreviewItemDto> get serializer => _$DriverRankingPreviewItemDtoSerializer();
}

class _$DriverRankingPreviewItemDtoSerializer implements PrimitiveSerializer<DriverRankingPreviewItemDto> {
  @override
  final Iterable<Type> types = const [DriverRankingPreviewItemDto, _$DriverRankingPreviewItemDto];

  @override
  final String wireName = r'DriverRankingPreviewItemDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankingPreviewItemDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
    yield r'driverName';
    yield serializers.serialize(
      object.driverName,
      specifiedType: const FullType(String),
    );
    yield r'previousTier';
    yield serializers.serialize(
      object.previousTier,
      specifiedType: const FullType(DriverTier),
    );
    yield r'newTier';
    yield serializers.serialize(
      object.newTier,
      specifiedType: const FullType(DriverTier),
    );
    yield r'changeReason';
    yield serializers.serialize(
      object.changeReason,
      specifiedType: const FullType(DriverRankChangeReason),
    );
    yield r'outcome';
    yield serializers.serialize(
      object.outcome,
      specifiedType: const FullType(DriverRankingOutcome),
    );
    if (object.performancePercentage != null) {
      yield r'performancePercentage';
      yield serializers.serialize(
        object.performancePercentage,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.acceptanceRate != null) {
      yield r'acceptanceRate';
      yield serializers.serialize(
        object.acceptanceRate,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.completionRate != null) {
      yield r'completionRate';
      yield serializers.serialize(
        object.completionRate,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.shiftPunctualityRate != null) {
      yield r'shiftPunctualityRate';
      yield serializers.serialize(
        object.shiftPunctualityRate,
        specifiedType: const FullType.nullable(num),
      );
    }
    yield r'metricsSnapshot';
    yield serializers.serialize(
      object.metricsSnapshot,
      specifiedType: const FullType(DriverMetricsSnapshotDto),
    );
    yield r'explanations';
    yield serializers.serialize(
      object.explanations,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingPreviewItemDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankingPreviewItemDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
        case r'driverName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverName = valueDes;
          break;
        case r'previousTier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverTier),
          ) as DriverTier;
          result.previousTier = valueDes;
          break;
        case r'newTier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverTier),
          ) as DriverTier;
          result.newTier = valueDes;
          break;
        case r'changeReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverRankChangeReason),
          ) as DriverRankChangeReason;
          result.changeReason = valueDes;
          break;
        case r'outcome':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverRankingOutcome),
          ) as DriverRankingOutcome;
          result.outcome = valueDes;
          break;
        case r'performancePercentage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.performancePercentage = valueDes;
          break;
        case r'acceptanceRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.acceptanceRate = valueDes;
          break;
        case r'completionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.completionRate = valueDes;
          break;
        case r'shiftPunctualityRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.shiftPunctualityRate = valueDes;
          break;
        case r'metricsSnapshot':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverMetricsSnapshotDto),
          ) as DriverMetricsSnapshotDto;
          result.metricsSnapshot.replace(valueDes);
          break;
        case r'explanations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.explanations.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverRankingPreviewItemDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankingPreviewItemDtoBuilder();
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

