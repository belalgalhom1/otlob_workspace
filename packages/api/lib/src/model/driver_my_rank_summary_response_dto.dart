//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_ranking_preview_item_dto.dart';
import 'package:api/src/model/driver_rank_history_entry_dto.dart';
import 'package:api/src/model/driver_tier.dart';
import 'package:api/src/model/ranking_week_window_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_my_rank_summary_response_dto.g.dart';

/// DriverMyRankSummaryResponseDto
///
/// Properties:
/// * [driverId] 
/// * [currentTier] 
/// * [timezone] 
/// * [nextEvaluationAt] 
/// * [currentWeek] 
/// * [currentWeekProgress] 
/// * [latestEvaluation] 
/// * [recentHistory] 
@BuiltValue()
abstract class DriverMyRankSummaryResponseDto implements Built<DriverMyRankSummaryResponseDto, DriverMyRankSummaryResponseDtoBuilder> {
  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'currentTier')
  DriverTier get currentTier;
  // enum currentTierEnum {  BRONZE,  SILVER,  GOLD,  };

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'nextEvaluationAt')
  DateTime get nextEvaluationAt;

  @BuiltValueField(wireName: r'currentWeek')
  RankingWeekWindowDto get currentWeek;

  @BuiltValueField(wireName: r'currentWeekProgress')
  DriverRankingPreviewItemDto? get currentWeekProgress;

  @BuiltValueField(wireName: r'latestEvaluation')
  DriverRankHistoryEntryDto? get latestEvaluation;

  @BuiltValueField(wireName: r'recentHistory')
  BuiltList<DriverRankHistoryEntryDto> get recentHistory;

  DriverMyRankSummaryResponseDto._();

  factory DriverMyRankSummaryResponseDto([void updates(DriverMyRankSummaryResponseDtoBuilder b)]) = _$DriverMyRankSummaryResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverMyRankSummaryResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverMyRankSummaryResponseDto> get serializer => _$DriverMyRankSummaryResponseDtoSerializer();
}

class _$DriverMyRankSummaryResponseDtoSerializer implements PrimitiveSerializer<DriverMyRankSummaryResponseDto> {
  @override
  final Iterable<Type> types = const [DriverMyRankSummaryResponseDto, _$DriverMyRankSummaryResponseDto];

  @override
  final String wireName = r'DriverMyRankSummaryResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverMyRankSummaryResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
    yield r'currentTier';
    yield serializers.serialize(
      object.currentTier,
      specifiedType: const FullType(DriverTier),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
    yield r'nextEvaluationAt';
    yield serializers.serialize(
      object.nextEvaluationAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'currentWeek';
    yield serializers.serialize(
      object.currentWeek,
      specifiedType: const FullType(RankingWeekWindowDto),
    );
    if (object.currentWeekProgress != null) {
      yield r'currentWeekProgress';
      yield serializers.serialize(
        object.currentWeekProgress,
        specifiedType: const FullType.nullable(DriverRankingPreviewItemDto),
      );
    }
    if (object.latestEvaluation != null) {
      yield r'latestEvaluation';
      yield serializers.serialize(
        object.latestEvaluation,
        specifiedType: const FullType.nullable(DriverRankHistoryEntryDto),
      );
    }
    yield r'recentHistory';
    yield serializers.serialize(
      object.recentHistory,
      specifiedType: const FullType(BuiltList, [FullType(DriverRankHistoryEntryDto)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverMyRankSummaryResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverMyRankSummaryResponseDtoBuilder result,
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
        case r'currentTier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverTier),
          ) as DriverTier;
          result.currentTier = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        case r'nextEvaluationAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.nextEvaluationAt = valueDes;
          break;
        case r'currentWeek':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RankingWeekWindowDto),
          ) as RankingWeekWindowDto;
          result.currentWeek.replace(valueDes);
          break;
        case r'currentWeekProgress':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DriverRankingPreviewItemDto),
          ) as DriverRankingPreviewItemDto?;
          if (valueDes == null) continue;
          result.currentWeekProgress.replace(valueDes);
          break;
        case r'latestEvaluation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DriverRankHistoryEntryDto),
          ) as DriverRankHistoryEntryDto?;
          if (valueDes == null) continue;
          result.latestEvaluation.replace(valueDes);
          break;
        case r'recentHistory':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverRankHistoryEntryDto)]),
          ) as BuiltList<DriverRankHistoryEntryDto>;
          result.recentHistory.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverMyRankSummaryResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverMyRankSummaryResponseDtoBuilder();
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

