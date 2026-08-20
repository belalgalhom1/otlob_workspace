//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vendor.dart';
import 'package:api/src/model/statistic_period.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'vendor_statistic.g.dart';

/// VendorStatistic
///
/// Properties:
/// * [id] 
/// * [vendorId] 
/// * [period] 
/// * [startDate] 
/// * [endDate] 
/// * [totalOrders] 
/// * [totalRevenue] 
/// * [totalCommission] 
/// * [totalTax] 
/// * [completedOrders] 
/// * [cancelledOrders] 
/// * [avgPrepTimeMins] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [vendor] 
@BuiltValue()
abstract class VendorStatistic implements Built<VendorStatistic, VendorStatisticBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'period')
  JsonObject? get period;
  // enum periodEnum {  DAILY,  WEEKLY,  MONTHLY,  YEARLY,  };

  @BuiltValueField(wireName: r'startDate')
  DateTime get startDate;

  @BuiltValueField(wireName: r'endDate')
  DateTime get endDate;

  @BuiltValueField(wireName: r'totalOrders')
  num get totalOrders;

  @BuiltValueField(wireName: r'totalRevenue')
  num get totalRevenue;

  @BuiltValueField(wireName: r'totalCommission')
  num get totalCommission;

  @BuiltValueField(wireName: r'totalTax')
  num get totalTax;

  @BuiltValueField(wireName: r'completedOrders')
  num get completedOrders;

  @BuiltValueField(wireName: r'cancelledOrders')
  num get cancelledOrders;

  @BuiltValueField(wireName: r'avgPrepTimeMins')
  num? get avgPrepTimeMins;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'vendor')
  JsonObject? get vendor;

  VendorStatistic._();

  factory VendorStatistic([void updates(VendorStatisticBuilder b)]) = _$VendorStatistic;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VendorStatisticBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VendorStatistic> get serializer => _$VendorStatisticSerializer();
}

class _$VendorStatisticSerializer implements PrimitiveSerializer<VendorStatistic> {
  @override
  final Iterable<Type> types = const [VendorStatistic, _$VendorStatistic];

  @override
  final String wireName = r'VendorStatistic';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VendorStatistic object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
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
    yield r'totalRevenue';
    yield serializers.serialize(
      object.totalRevenue,
      specifiedType: const FullType(num),
    );
    yield r'totalCommission';
    yield serializers.serialize(
      object.totalCommission,
      specifiedType: const FullType(num),
    );
    yield r'totalTax';
    yield serializers.serialize(
      object.totalTax,
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
    if (object.avgPrepTimeMins != null) {
      yield r'avgPrepTimeMins';
      yield serializers.serialize(
        object.avgPrepTimeMins,
        specifiedType: const FullType(num),
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
    yield r'vendor';
    yield serializers.serialize(
      object.vendor,
      specifiedType: const FullType(Vendor),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VendorStatistic object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VendorStatisticBuilder result,
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
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
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
        case r'totalRevenue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalRevenue = valueDes;
          break;
        case r'totalCommission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalCommission = valueDes;
          break;
        case r'totalTax':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalTax = valueDes;
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
        case r'avgPrepTimeMins':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.avgPrepTimeMins = valueDes;
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
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.vendor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VendorStatistic deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VendorStatisticBuilder();
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

