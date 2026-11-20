//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_metrics_snapshot_dto.dart';
import 'package:api/src/model/driver_tier.dart';
import 'package:api/src/model/driver_rank_change_reason.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_rank_history_entry_dto.g.dart';

/// DriverRankHistoryEntryDto
///
/// Properties:
/// * [id] 
/// * [driverId] 
/// * [driverName] 
/// * [runId] 
/// * [periodKey] 
/// * [evaluatedAt] 
/// * [periodStart] 
/// * [periodEnd] 
/// * [performancePercentage] 
/// * [metricsSnapshot] 
/// * [previousTier] 
/// * [newTier] 
/// * [changeReason] 
/// * [adminUserId] 
/// * [overrideReason] 
/// * [createdAt] 
@BuiltValue()
abstract class DriverRankHistoryEntryDto implements Built<DriverRankHistoryEntryDto, DriverRankHistoryEntryDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'driverName')
  JsonObject? get driverName;

  @BuiltValueField(wireName: r'runId')
  JsonObject? get runId;

  @BuiltValueField(wireName: r'periodKey')
  JsonObject? get periodKey;

  @BuiltValueField(wireName: r'evaluatedAt')
  DateTime get evaluatedAt;

  @BuiltValueField(wireName: r'periodStart')
  DateTime? get periodStart;

  @BuiltValueField(wireName: r'periodEnd')
  DateTime? get periodEnd;

  @BuiltValueField(wireName: r'performancePercentage')
  num? get performancePercentage;

  @BuiltValueField(wireName: r'metricsSnapshot')
  DriverMetricsSnapshotDto? get metricsSnapshot;

  @BuiltValueField(wireName: r'previousTier')
  DriverTier get previousTier;
  // enum previousTierEnum {  BRONZE,  SILVER,  GOLD,  };

  @BuiltValueField(wireName: r'newTier')
  DriverTier get newTier;
  // enum newTierEnum {  BRONZE,  SILVER,  GOLD,  };

  @BuiltValueField(wireName: r'changeReason')
  DriverRankChangeReason get changeReason;
  // enum changeReasonEnum {  WEEKLY_EVALUATION,  INACTIVE_DRIVER,  ADMIN_OVERRIDE,  };

  @BuiltValueField(wireName: r'adminUserId')
  JsonObject? get adminUserId;

  @BuiltValueField(wireName: r'overrideReason')
  JsonObject? get overrideReason;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  DriverRankHistoryEntryDto._();

  factory DriverRankHistoryEntryDto([void updates(DriverRankHistoryEntryDtoBuilder b)]) = _$DriverRankHistoryEntryDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankHistoryEntryDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankHistoryEntryDto> get serializer => _$DriverRankHistoryEntryDtoSerializer();
}

class _$DriverRankHistoryEntryDtoSerializer implements PrimitiveSerializer<DriverRankHistoryEntryDto> {
  @override
  final Iterable<Type> types = const [DriverRankHistoryEntryDto, _$DriverRankHistoryEntryDto];

  @override
  final String wireName = r'DriverRankHistoryEntryDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankHistoryEntryDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
    if (object.driverName != null) {
      yield r'driverName';
      yield serializers.serialize(
        object.driverName,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.runId != null) {
      yield r'runId';
      yield serializers.serialize(
        object.runId,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.periodKey != null) {
      yield r'periodKey';
      yield serializers.serialize(
        object.periodKey,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'evaluatedAt';
    yield serializers.serialize(
      object.evaluatedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.periodStart != null) {
      yield r'periodStart';
      yield serializers.serialize(
        object.periodStart,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.periodEnd != null) {
      yield r'periodEnd';
      yield serializers.serialize(
        object.periodEnd,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.performancePercentage != null) {
      yield r'performancePercentage';
      yield serializers.serialize(
        object.performancePercentage,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.metricsSnapshot != null) {
      yield r'metricsSnapshot';
      yield serializers.serialize(
        object.metricsSnapshot,
        specifiedType: const FullType.nullable(DriverMetricsSnapshotDto),
      );
    }
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
    if (object.adminUserId != null) {
      yield r'adminUserId';
      yield serializers.serialize(
        object.adminUserId,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    if (object.overrideReason != null) {
      yield r'overrideReason';
      yield serializers.serialize(
        object.overrideReason,
        specifiedType: const FullType.nullable(JsonObject),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverRankHistoryEntryDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankHistoryEntryDtoBuilder result,
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
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.driverName = valueDes;
          break;
        case r'runId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.runId = valueDes;
          break;
        case r'periodKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.periodKey = valueDes;
          break;
        case r'evaluatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.evaluatedAt = valueDes;
          break;
        case r'periodStart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.periodStart = valueDes;
          break;
        case r'periodEnd':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.periodEnd = valueDes;
          break;
        case r'performancePercentage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.performancePercentage = valueDes;
          break;
        case r'metricsSnapshot':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DriverMetricsSnapshotDto),
          ) as DriverMetricsSnapshotDto?;
          if (valueDes == null) continue;
          result.metricsSnapshot.replace(valueDes);
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
        case r'adminUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.adminUserId = valueDes;
          break;
        case r'overrideReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.overrideReason = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverRankHistoryEntryDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankHistoryEntryDtoBuilder();
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

