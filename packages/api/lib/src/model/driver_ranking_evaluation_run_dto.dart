//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_ranking_trigger_source.dart';
import 'package:api/src/model/driver_ranking_run_status.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_evaluation_run_dto.g.dart';

/// DriverRankingEvaluationRunDto
///
/// Properties:
/// * [id] 
/// * [periodKey] 
/// * [status] 
/// * [triggerSource] 
/// * [triggeredByUserId] 
/// * [scheduledFor] 
/// * [executedAt] 
/// * [periodStart] 
/// * [periodEnd] 
/// * [totalDrivers] 
/// * [promotedCount] 
/// * [demotedCount] 
/// * [unchangedCount] 
/// * [inactiveCount] 
/// * [errorMessage] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class DriverRankingEvaluationRunDto implements Built<DriverRankingEvaluationRunDto, DriverRankingEvaluationRunDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'periodKey')
  String get periodKey;

  @BuiltValueField(wireName: r'status')
  DriverRankingRunStatus get status;
  // enum statusEnum {  RUNNING,  COMPLETED,  FAILED,  };

  @BuiltValueField(wireName: r'triggerSource')
  DriverRankingTriggerSource get triggerSource;
  // enum triggerSourceEnum {  SCHEDULED,  MANUAL,  };

  @BuiltValueField(wireName: r'triggeredByUserId')
  JsonObject? get triggeredByUserId;

  @BuiltValueField(wireName: r'scheduledFor')
  DateTime get scheduledFor;

  @BuiltValueField(wireName: r'executedAt')
  DateTime? get executedAt;

  @BuiltValueField(wireName: r'periodStart')
  DateTime get periodStart;

  @BuiltValueField(wireName: r'periodEnd')
  DateTime get periodEnd;

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

  @BuiltValueField(wireName: r'errorMessage')
  JsonObject? get errorMessage;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  DriverRankingEvaluationRunDto._();

  factory DriverRankingEvaluationRunDto([void updates(DriverRankingEvaluationRunDtoBuilder b)]) = _$DriverRankingEvaluationRunDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankingEvaluationRunDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankingEvaluationRunDto> get serializer => _$DriverRankingEvaluationRunDtoSerializer();
}

class _$DriverRankingEvaluationRunDtoSerializer implements PrimitiveSerializer<DriverRankingEvaluationRunDto> {
  @override
  final Iterable<Type> types = const [DriverRankingEvaluationRunDto, _$DriverRankingEvaluationRunDto];

  @override
  final String wireName = r'DriverRankingEvaluationRunDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankingEvaluationRunDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'periodKey';
    yield serializers.serialize(
      object.periodKey,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DriverRankingRunStatus),
    );
    yield r'triggerSource';
    yield serializers.serialize(
      object.triggerSource,
      specifiedType: const FullType(DriverRankingTriggerSource),
    );
    if (object.triggeredByUserId != null) {
      yield r'triggeredByUserId';
      yield serializers.serialize(
        object.triggeredByUserId,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'scheduledFor';
    yield serializers.serialize(
      object.scheduledFor,
      specifiedType: const FullType(DateTime),
    );
    if (object.executedAt != null) {
      yield r'executedAt';
      yield serializers.serialize(
        object.executedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'periodStart';
    yield serializers.serialize(
      object.periodStart,
      specifiedType: const FullType(DateTime),
    );
    yield r'periodEnd';
    yield serializers.serialize(
      object.periodEnd,
      specifiedType: const FullType(DateTime),
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
    if (object.errorMessage != null) {
      yield r'errorMessage';
      yield serializers.serialize(
        object.errorMessage,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingEvaluationRunDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankingEvaluationRunDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'periodKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.periodKey = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverRankingRunStatus),
          ) as DriverRankingRunStatus;
          result.status = valueDes;
          break;
        case r'triggerSource':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverRankingTriggerSource),
          ) as DriverRankingTriggerSource;
          result.triggerSource = valueDes;
          break;
        case r'triggeredByUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.triggeredByUserId = valueDes;
          break;
        case r'scheduledFor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.scheduledFor = valueDes;
          break;
        case r'executedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.executedAt = valueDes;
          break;
        case r'periodStart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.periodStart = valueDes;
          break;
        case r'periodEnd':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.periodEnd = valueDes;
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
        case r'errorMessage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.errorMessage = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverRankingEvaluationRunDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankingEvaluationRunDtoBuilder();
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

