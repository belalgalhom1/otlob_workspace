//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver.dart';
import 'package:api/src/model/statistic_period.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'driver_statistic.g.dart';

/// DriverStatistic
///
/// Properties:
/// * [id] 
/// * [driverId] 
/// * [period] 
/// * [startDate] 
/// * [endDate] 
/// * [totalOrders] 
/// * [totalEarnings] 
/// * [completedOrders] 
/// * [cancelledOrders] 
/// * [onlineHours] 
/// * [totalDispatchesReceived] 
/// * [dispatchesAccepted] 
/// * [dispatchesRejected] 
/// * [dispatchesExpired] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [driver] 
@BuiltValue()
abstract class DriverStatistic implements Built<DriverStatistic, DriverStatisticBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'period')
  JsonObject? get period;
  // enum periodEnum {  DAILY,  WEEKLY,  MONTHLY,  YEARLY,  };

  @BuiltValueField(wireName: r'startDate')
  DateTime get startDate;

  @BuiltValueField(wireName: r'endDate')
  DateTime get endDate;

  @BuiltValueField(wireName: r'totalOrders')
  num get totalOrders;

  @BuiltValueField(wireName: r'totalEarnings')
  num get totalEarnings;

  @BuiltValueField(wireName: r'completedOrders')
  num get completedOrders;

  @BuiltValueField(wireName: r'cancelledOrders')
  num get cancelledOrders;

  @BuiltValueField(wireName: r'onlineHours')
  num? get onlineHours;

  @BuiltValueField(wireName: r'totalDispatchesReceived')
  num get totalDispatchesReceived;

  @BuiltValueField(wireName: r'dispatchesAccepted')
  num get dispatchesAccepted;

  @BuiltValueField(wireName: r'dispatchesRejected')
  num get dispatchesRejected;

  @BuiltValueField(wireName: r'dispatchesExpired')
  num get dispatchesExpired;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'driver')
  JsonObject? get driver;

  DriverStatistic._();

  factory DriverStatistic([void updates(DriverStatisticBuilder b)]) = _$DriverStatistic;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverStatisticBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverStatistic> get serializer => _$DriverStatisticSerializer();
}

class _$DriverStatisticSerializer implements PrimitiveSerializer<DriverStatistic> {
  @override
  final Iterable<Type> types = const [DriverStatistic, _$DriverStatistic];

  @override
  final String wireName = r'DriverStatistic';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverStatistic object, {
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
    yield r'period';
    yield serializers.serialize(
      object.period,
      specifiedType: const FullType(StatisticPeriod),
    );
    yield r'startDate';
    yield serializers.serialize(
      object.startDate,
      specifiedType: const FullType(DateTime),
    );
    yield r'endDate';
    yield serializers.serialize(
      object.endDate,
      specifiedType: const FullType(DateTime),
    );
    yield r'totalOrders';
    yield serializers.serialize(
      object.totalOrders,
      specifiedType: const FullType(num),
    );
    yield r'totalEarnings';
    yield serializers.serialize(
      object.totalEarnings,
      specifiedType: const FullType(num),
    );
    yield r'completedOrders';
    yield serializers.serialize(
      object.completedOrders,
      specifiedType: const FullType(num),
    );
    yield r'cancelledOrders';
    yield serializers.serialize(
      object.cancelledOrders,
      specifiedType: const FullType(num),
    );
    if (object.onlineHours != null) {
      yield r'onlineHours';
      yield serializers.serialize(
        object.onlineHours,
        specifiedType: const FullType(num),
      );
    }
    yield r'totalDispatchesReceived';
    yield serializers.serialize(
      object.totalDispatchesReceived,
      specifiedType: const FullType(num),
    );
    yield r'dispatchesAccepted';
    yield serializers.serialize(
      object.dispatchesAccepted,
      specifiedType: const FullType(num),
    );
    yield r'dispatchesRejected';
    yield serializers.serialize(
      object.dispatchesRejected,
      specifiedType: const FullType(num),
    );
    yield r'dispatchesExpired';
    yield serializers.serialize(
      object.dispatchesExpired,
      specifiedType: const FullType(num),
    );
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
    yield r'driver';
    yield serializers.serialize(
      object.driver,
      specifiedType: const FullType(Driver),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverStatistic object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverStatisticBuilder result,
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
        case r'period':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.period = valueDes;
          break;
        case r'startDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startDate = valueDes;
          break;
        case r'endDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.endDate = valueDes;
          break;
        case r'totalOrders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalOrders = valueDes;
          break;
        case r'totalEarnings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalEarnings = valueDes;
          break;
        case r'completedOrders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.completedOrders = valueDes;
          break;
        case r'cancelledOrders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.cancelledOrders = valueDes;
          break;
        case r'onlineHours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.onlineHours = valueDes;
          break;
        case r'totalDispatchesReceived':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalDispatchesReceived = valueDes;
          break;
        case r'dispatchesAccepted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.dispatchesAccepted = valueDes;
          break;
        case r'dispatchesRejected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.dispatchesRejected = valueDes;
          break;
        case r'dispatchesExpired':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.dispatchesExpired = valueDes;
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
        case r'driver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.driver = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverStatistic deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverStatisticBuilder();
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

