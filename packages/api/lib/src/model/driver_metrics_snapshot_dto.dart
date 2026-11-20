//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/excluded_incidents_summary_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_metrics_snapshot_dto.g.dart';

/// DriverMetricsSnapshotDto
///
/// Properties:
/// * [acceptedDispatches] 
/// * [rejectedDispatches] 
/// * [expiredDispatches] 
/// * [eligibleDispatches] 
/// * [cancelledDispatches] 
/// * [completedOrders] 
/// * [driverFaultFailures] 
/// * [driverResponsibleOrders] 
/// * [excludedIncidents] 
/// * [onTimeShifts] 
/// * [lateShifts] 
/// * [missedShifts] 
/// * [eligibleShifts] 
/// * [cancelledShifts] 
/// * [excusedShifts] 
/// * [acceptanceRate] 
/// * [completionRate] 
/// * [shiftPunctualityRate] 
/// * [applicableMetricsCount] 
/// * [cappedDueToNoOrders] 
/// * [explanations] 
@BuiltValue()
abstract class DriverMetricsSnapshotDto implements Built<DriverMetricsSnapshotDto, DriverMetricsSnapshotDtoBuilder> {
  @BuiltValueField(wireName: r'acceptedDispatches')
  num get acceptedDispatches;

  @BuiltValueField(wireName: r'rejectedDispatches')
  num get rejectedDispatches;

  @BuiltValueField(wireName: r'expiredDispatches')
  num get expiredDispatches;

  @BuiltValueField(wireName: r'eligibleDispatches')
  num get eligibleDispatches;

  @BuiltValueField(wireName: r'cancelledDispatches')
  num get cancelledDispatches;

  @BuiltValueField(wireName: r'completedOrders')
  num get completedOrders;

  @BuiltValueField(wireName: r'driverFaultFailures')
  num get driverFaultFailures;

  @BuiltValueField(wireName: r'driverResponsibleOrders')
  num get driverResponsibleOrders;

  @BuiltValueField(wireName: r'excludedIncidents')
  ExcludedIncidentsSummaryDto get excludedIncidents;

  @BuiltValueField(wireName: r'onTimeShifts')
  num get onTimeShifts;

  @BuiltValueField(wireName: r'lateShifts')
  num get lateShifts;

  @BuiltValueField(wireName: r'missedShifts')
  num get missedShifts;

  @BuiltValueField(wireName: r'eligibleShifts')
  num get eligibleShifts;

  @BuiltValueField(wireName: r'cancelledShifts')
  num get cancelledShifts;

  @BuiltValueField(wireName: r'excusedShifts')
  num get excusedShifts;

  @BuiltValueField(wireName: r'acceptanceRate')
  num? get acceptanceRate;

  @BuiltValueField(wireName: r'completionRate')
  num? get completionRate;

  @BuiltValueField(wireName: r'shiftPunctualityRate')
  num? get shiftPunctualityRate;

  @BuiltValueField(wireName: r'applicableMetricsCount')
  num get applicableMetricsCount;

  @BuiltValueField(wireName: r'cappedDueToNoOrders')
  bool get cappedDueToNoOrders;

  @BuiltValueField(wireName: r'explanations')
  BuiltList<String> get explanations;

  DriverMetricsSnapshotDto._();

  factory DriverMetricsSnapshotDto([void updates(DriverMetricsSnapshotDtoBuilder b)]) = _$DriverMetricsSnapshotDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverMetricsSnapshotDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverMetricsSnapshotDto> get serializer => _$DriverMetricsSnapshotDtoSerializer();
}

class _$DriverMetricsSnapshotDtoSerializer implements PrimitiveSerializer<DriverMetricsSnapshotDto> {
  @override
  final Iterable<Type> types = const [DriverMetricsSnapshotDto, _$DriverMetricsSnapshotDto];

  @override
  final String wireName = r'DriverMetricsSnapshotDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverMetricsSnapshotDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'acceptedDispatches';
    yield serializers.serialize(
      object.acceptedDispatches,
      specifiedType: const FullType(num),
    );
    yield r'rejectedDispatches';
    yield serializers.serialize(
      object.rejectedDispatches,
      specifiedType: const FullType(num),
    );
    yield r'expiredDispatches';
    yield serializers.serialize(
      object.expiredDispatches,
      specifiedType: const FullType(num),
    );
    yield r'eligibleDispatches';
    yield serializers.serialize(
      object.eligibleDispatches,
      specifiedType: const FullType(num),
    );
    yield r'cancelledDispatches';
    yield serializers.serialize(
      object.cancelledDispatches,
      specifiedType: const FullType(num),
    );
    yield r'completedOrders';
    yield serializers.serialize(
      object.completedOrders,
      specifiedType: const FullType(num),
    );
    yield r'driverFaultFailures';
    yield serializers.serialize(
      object.driverFaultFailures,
      specifiedType: const FullType(num),
    );
    yield r'driverResponsibleOrders';
    yield serializers.serialize(
      object.driverResponsibleOrders,
      specifiedType: const FullType(num),
    );
    yield r'excludedIncidents';
    yield serializers.serialize(
      object.excludedIncidents,
      specifiedType: const FullType(ExcludedIncidentsSummaryDto),
    );
    yield r'onTimeShifts';
    yield serializers.serialize(
      object.onTimeShifts,
      specifiedType: const FullType(num),
    );
    yield r'lateShifts';
    yield serializers.serialize(
      object.lateShifts,
      specifiedType: const FullType(num),
    );
    yield r'missedShifts';
    yield serializers.serialize(
      object.missedShifts,
      specifiedType: const FullType(num),
    );
    yield r'eligibleShifts';
    yield serializers.serialize(
      object.eligibleShifts,
      specifiedType: const FullType(num),
    );
    yield r'cancelledShifts';
    yield serializers.serialize(
      object.cancelledShifts,
      specifiedType: const FullType(num),
    );
    yield r'excusedShifts';
    yield serializers.serialize(
      object.excusedShifts,
      specifiedType: const FullType(num),
    );
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
    yield r'applicableMetricsCount';
    yield serializers.serialize(
      object.applicableMetricsCount,
      specifiedType: const FullType(num),
    );
    yield r'cappedDueToNoOrders';
    yield serializers.serialize(
      object.cappedDueToNoOrders,
      specifiedType: const FullType(bool),
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
    DriverMetricsSnapshotDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverMetricsSnapshotDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'acceptedDispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.acceptedDispatches = valueDes;
          break;
        case r'rejectedDispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.rejectedDispatches = valueDes;
          break;
        case r'expiredDispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.expiredDispatches = valueDes;
          break;
        case r'eligibleDispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.eligibleDispatches = valueDes;
          break;
        case r'cancelledDispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.cancelledDispatches = valueDes;
          break;
        case r'completedOrders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.completedOrders = valueDes;
          break;
        case r'driverFaultFailures':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverFaultFailures = valueDes;
          break;
        case r'driverResponsibleOrders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverResponsibleOrders = valueDes;
          break;
        case r'excludedIncidents':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ExcludedIncidentsSummaryDto),
          ) as ExcludedIncidentsSummaryDto;
          result.excludedIncidents.replace(valueDes);
          break;
        case r'onTimeShifts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.onTimeShifts = valueDes;
          break;
        case r'lateShifts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.lateShifts = valueDes;
          break;
        case r'missedShifts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.missedShifts = valueDes;
          break;
        case r'eligibleShifts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.eligibleShifts = valueDes;
          break;
        case r'cancelledShifts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.cancelledShifts = valueDes;
          break;
        case r'excusedShifts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.excusedShifts = valueDes;
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
        case r'applicableMetricsCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.applicableMetricsCount = valueDes;
          break;
        case r'cappedDueToNoOrders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.cappedDueToNoOrders = valueDes;
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
  DriverMetricsSnapshotDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverMetricsSnapshotDtoBuilder();
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

