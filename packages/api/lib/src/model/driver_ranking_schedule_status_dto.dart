//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_ranking_evaluation_run_dto.dart';
import 'package:api/src/model/ranking_week_window_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_schedule_status_dto.g.dart';

/// DriverRankingScheduleStatusDto
///
/// Properties:
/// * [enabled] 
/// * [evalTime] 
/// * [frequency] 
/// * [evaluationDay] 
/// * [timezone] 
/// * [nextEvaluationAt] 
/// * [currentWeek] 
/// * [lastCompletedWeek] 
/// * [latestRun] 
/// * [lastCompletedWeekRun] 
@BuiltValue()
abstract class DriverRankingScheduleStatusDto implements Built<DriverRankingScheduleStatusDto, DriverRankingScheduleStatusDtoBuilder> {
  @BuiltValueField(wireName: r'enabled')
  bool get enabled;

  @BuiltValueField(wireName: r'evalTime')
  String get evalTime;

  @BuiltValueField(wireName: r'frequency')
  String get frequency;

  @BuiltValueField(wireName: r'evaluationDay')
  String get evaluationDay;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'nextEvaluationAt')
  DateTime get nextEvaluationAt;

  @BuiltValueField(wireName: r'currentWeek')
  RankingWeekWindowDto get currentWeek;

  @BuiltValueField(wireName: r'lastCompletedWeek')
  RankingWeekWindowDto get lastCompletedWeek;

  @BuiltValueField(wireName: r'latestRun')
  DriverRankingEvaluationRunDto? get latestRun;

  @BuiltValueField(wireName: r'lastCompletedWeekRun')
  DriverRankingEvaluationRunDto? get lastCompletedWeekRun;

  DriverRankingScheduleStatusDto._();

  factory DriverRankingScheduleStatusDto([void updates(DriverRankingScheduleStatusDtoBuilder b)]) = _$DriverRankingScheduleStatusDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankingScheduleStatusDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankingScheduleStatusDto> get serializer => _$DriverRankingScheduleStatusDtoSerializer();
}

class _$DriverRankingScheduleStatusDtoSerializer implements PrimitiveSerializer<DriverRankingScheduleStatusDto> {
  @override
  final Iterable<Type> types = const [DriverRankingScheduleStatusDto, _$DriverRankingScheduleStatusDto];

  @override
  final String wireName = r'DriverRankingScheduleStatusDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankingScheduleStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'enabled';
    yield serializers.serialize(
      object.enabled,
      specifiedType: const FullType(bool),
    );
    yield r'evalTime';
    yield serializers.serialize(
      object.evalTime,
      specifiedType: const FullType(String),
    );
    yield r'frequency';
    yield serializers.serialize(
      object.frequency,
      specifiedType: const FullType(String),
    );
    yield r'evaluationDay';
    yield serializers.serialize(
      object.evaluationDay,
      specifiedType: const FullType(String),
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
    yield r'lastCompletedWeek';
    yield serializers.serialize(
      object.lastCompletedWeek,
      specifiedType: const FullType(RankingWeekWindowDto),
    );
    if (object.latestRun != null) {
      yield r'latestRun';
      yield serializers.serialize(
        object.latestRun,
        specifiedType: const FullType.nullable(DriverRankingEvaluationRunDto),
      );
    }
    if (object.lastCompletedWeekRun != null) {
      yield r'lastCompletedWeekRun';
      yield serializers.serialize(
        object.lastCompletedWeekRun,
        specifiedType: const FullType.nullable(DriverRankingEvaluationRunDto),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingScheduleStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankingScheduleStatusDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enabled = valueDes;
          break;
        case r'evalTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.evalTime = valueDes;
          break;
        case r'frequency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.frequency = valueDes;
          break;
        case r'evaluationDay':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.evaluationDay = valueDes;
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
        case r'lastCompletedWeek':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RankingWeekWindowDto),
          ) as RankingWeekWindowDto;
          result.lastCompletedWeek.replace(valueDes);
          break;
        case r'latestRun':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DriverRankingEvaluationRunDto),
          ) as DriverRankingEvaluationRunDto?;
          if (valueDes == null) continue;
          result.latestRun.replace(valueDes);
          break;
        case r'lastCompletedWeekRun':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DriverRankingEvaluationRunDto),
          ) as DriverRankingEvaluationRunDto?;
          if (valueDes == null) continue;
          result.lastCompletedWeekRun.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverRankingScheduleStatusDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankingScheduleStatusDtoBuilder();
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

