//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_tier.dart';
import 'package:api/src/model/driver.dart';
import 'package:api/src/model/delivery_group_status.dart';
import 'package:api/src/model/order_delivery_group_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_delivery_group.g.dart';

/// OrderDeliveryGroup
///
/// Properties:
/// * [id] 
/// * [orderId] 
/// * [sequence] 
/// * [status] 
/// * [primaryDriverId] 
/// * [primaryDriverShiftId] 
/// * [assistDriverId] 
/// * [assistDriverShiftId] 
/// * [assistFee] 
/// * [assistCustomerApproved] 
/// * [assistApprovedAt] 
/// * [isStacked] 
/// * [isPaymentCollector] 
/// * [assignedByUserId] 
/// * [assignedAt] 
/// * [distanceKm] 
/// * [deliveryFee] 
/// * [goldSurchargeAmount] 
/// * [primaryDriverTierSnapshot] 
/// * [settledGoldBonusAmount] 
/// * [settledGoldPlatformRetainedAmount] 
/// * [settledBronzeDriverDeduction] 
/// * [settledBronzeSupervisorDeduction] 
/// * [settledPrimaryManagerId] 
/// * [estimatedPrepTime] 
/// * [pickupImageUrl] 
/// * [deliveryImageUrl] 
/// * [pickedUpAt] 
/// * [deliveredAt] 
/// * [primaryDriver] 
/// * [assistDriver] 
/// * [items] 
@BuiltValue()
abstract class OrderDeliveryGroup implements Built<OrderDeliveryGroup, OrderDeliveryGroupBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'sequence')
  num get sequence;

  @BuiltValueField(wireName: r'status')
  DeliveryGroupStatus get status;
  // enum statusEnum {  PENDING,  ACCEPTED,  PREPARING,  LOOKING_FOR_DRIVER,  DRIVER_ASSIGNED,  PENDING_PAYMENT,  READY_FOR_PICKUP,  PARTIALLY_PICKED_UP,  PICKED_UP,  DELIVERED,  CANCELLED,  };

  @BuiltValueField(wireName: r'primaryDriverId')
  String? get primaryDriverId;

  @BuiltValueField(wireName: r'primaryDriverShiftId')
  String? get primaryDriverShiftId;

  @BuiltValueField(wireName: r'assistDriverId')
  String? get assistDriverId;

  @BuiltValueField(wireName: r'assistDriverShiftId')
  String? get assistDriverShiftId;

  @BuiltValueField(wireName: r'assistFee')
  num? get assistFee;

  @BuiltValueField(wireName: r'assistCustomerApproved')
  bool? get assistCustomerApproved;

  @BuiltValueField(wireName: r'assistApprovedAt')
  DateTime? get assistApprovedAt;

  @BuiltValueField(wireName: r'isStacked')
  bool get isStacked;

  @BuiltValueField(wireName: r'isPaymentCollector')
  bool get isPaymentCollector;

  @BuiltValueField(wireName: r'assignedByUserId')
  String? get assignedByUserId;

  @BuiltValueField(wireName: r'assignedAt')
  DateTime? get assignedAt;

  @BuiltValueField(wireName: r'distanceKm')
  num? get distanceKm;

  @BuiltValueField(wireName: r'deliveryFee')
  num get deliveryFee;

  @BuiltValueField(wireName: r'goldSurchargeAmount')
  num get goldSurchargeAmount;

  @BuiltValueField(wireName: r'primaryDriverTierSnapshot')
  DriverTier? get primaryDriverTierSnapshot;
  // enum primaryDriverTierSnapshotEnum {  BRONZE,  SILVER,  GOLD,  };

  @BuiltValueField(wireName: r'settledGoldBonusAmount')
  num get settledGoldBonusAmount;

  @BuiltValueField(wireName: r'settledGoldPlatformRetainedAmount')
  num get settledGoldPlatformRetainedAmount;

  @BuiltValueField(wireName: r'settledBronzeDriverDeduction')
  num get settledBronzeDriverDeduction;

  @BuiltValueField(wireName: r'settledBronzeSupervisorDeduction')
  num get settledBronzeSupervisorDeduction;

  @BuiltValueField(wireName: r'settledPrimaryManagerId')
  String? get settledPrimaryManagerId;

  @BuiltValueField(wireName: r'estimatedPrepTime')
  num? get estimatedPrepTime;

  @BuiltValueField(wireName: r'pickupImageUrl')
  String? get pickupImageUrl;

  @BuiltValueField(wireName: r'deliveryImageUrl')
  String? get deliveryImageUrl;

  @BuiltValueField(wireName: r'pickedUpAt')
  DateTime? get pickedUpAt;

  @BuiltValueField(wireName: r'deliveredAt')
  DateTime? get deliveredAt;

  @BuiltValueField(wireName: r'primaryDriver')
  Driver? get primaryDriver;

  @BuiltValueField(wireName: r'assistDriver')
  Driver? get assistDriver;

  @BuiltValueField(wireName: r'items')
  BuiltList<OrderDeliveryGroupItem>? get items;

  OrderDeliveryGroup._();

  factory OrderDeliveryGroup([void updates(OrderDeliveryGroupBuilder b)]) = _$OrderDeliveryGroup;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderDeliveryGroupBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderDeliveryGroup> get serializer => _$OrderDeliveryGroupSerializer();
}

class _$OrderDeliveryGroupSerializer implements PrimitiveSerializer<OrderDeliveryGroup> {
  @override
  final Iterable<Type> types = const [OrderDeliveryGroup, _$OrderDeliveryGroup];

  @override
  final String wireName = r'OrderDeliveryGroup';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderDeliveryGroup object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'orderId';
    yield serializers.serialize(
      object.orderId,
      specifiedType: const FullType(String),
    );
    yield r'sequence';
    yield serializers.serialize(
      object.sequence,
      specifiedType: const FullType(num),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DeliveryGroupStatus),
    );
    if (object.primaryDriverId != null) {
      yield r'primaryDriverId';
      yield serializers.serialize(
        object.primaryDriverId,
        specifiedType: const FullType(String),
      );
    }
    if (object.primaryDriverShiftId != null) {
      yield r'primaryDriverShiftId';
      yield serializers.serialize(
        object.primaryDriverShiftId,
        specifiedType: const FullType(String),
      );
    }
    if (object.assistDriverId != null) {
      yield r'assistDriverId';
      yield serializers.serialize(
        object.assistDriverId,
        specifiedType: const FullType(String),
      );
    }
    if (object.assistDriverShiftId != null) {
      yield r'assistDriverShiftId';
      yield serializers.serialize(
        object.assistDriverShiftId,
        specifiedType: const FullType(String),
      );
    }
    if (object.assistFee != null) {
      yield r'assistFee';
      yield serializers.serialize(
        object.assistFee,
        specifiedType: const FullType(num),
      );
    }
    if (object.assistCustomerApproved != null) {
      yield r'assistCustomerApproved';
      yield serializers.serialize(
        object.assistCustomerApproved,
        specifiedType: const FullType(bool),
      );
    }
    if (object.assistApprovedAt != null) {
      yield r'assistApprovedAt';
      yield serializers.serialize(
        object.assistApprovedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'isStacked';
    yield serializers.serialize(
      object.isStacked,
      specifiedType: const FullType(bool),
    );
    yield r'isPaymentCollector';
    yield serializers.serialize(
      object.isPaymentCollector,
      specifiedType: const FullType(bool),
    );
    if (object.assignedByUserId != null) {
      yield r'assignedByUserId';
      yield serializers.serialize(
        object.assignedByUserId,
        specifiedType: const FullType(String),
      );
    }
    if (object.assignedAt != null) {
      yield r'assignedAt';
      yield serializers.serialize(
        object.assignedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.distanceKm != null) {
      yield r'distanceKm';
      yield serializers.serialize(
        object.distanceKm,
        specifiedType: const FullType(num),
      );
    }
    yield r'deliveryFee';
    yield serializers.serialize(
      object.deliveryFee,
      specifiedType: const FullType(num),
    );
    yield r'goldSurchargeAmount';
    yield serializers.serialize(
      object.goldSurchargeAmount,
      specifiedType: const FullType(num),
    );
    if (object.primaryDriverTierSnapshot != null) {
      yield r'primaryDriverTierSnapshot';
      yield serializers.serialize(
        object.primaryDriverTierSnapshot,
        specifiedType: const FullType(DriverTier),
      );
    }
    yield r'settledGoldBonusAmount';
    yield serializers.serialize(
      object.settledGoldBonusAmount,
      specifiedType: const FullType(num),
    );
    yield r'settledGoldPlatformRetainedAmount';
    yield serializers.serialize(
      object.settledGoldPlatformRetainedAmount,
      specifiedType: const FullType(num),
    );
    yield r'settledBronzeDriverDeduction';
    yield serializers.serialize(
      object.settledBronzeDriverDeduction,
      specifiedType: const FullType(num),
    );
    yield r'settledBronzeSupervisorDeduction';
    yield serializers.serialize(
      object.settledBronzeSupervisorDeduction,
      specifiedType: const FullType(num),
    );
    if (object.settledPrimaryManagerId != null) {
      yield r'settledPrimaryManagerId';
      yield serializers.serialize(
        object.settledPrimaryManagerId,
        specifiedType: const FullType(String),
      );
    }
    if (object.estimatedPrepTime != null) {
      yield r'estimatedPrepTime';
      yield serializers.serialize(
        object.estimatedPrepTime,
        specifiedType: const FullType(num),
      );
    }
    if (object.pickupImageUrl != null) {
      yield r'pickupImageUrl';
      yield serializers.serialize(
        object.pickupImageUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.deliveryImageUrl != null) {
      yield r'deliveryImageUrl';
      yield serializers.serialize(
        object.deliveryImageUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.pickedUpAt != null) {
      yield r'pickedUpAt';
      yield serializers.serialize(
        object.pickedUpAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.deliveredAt != null) {
      yield r'deliveredAt';
      yield serializers.serialize(
        object.deliveredAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.primaryDriver != null) {
      yield r'primaryDriver';
      yield serializers.serialize(
        object.primaryDriver,
        specifiedType: const FullType(Driver),
      );
    }
    if (object.assistDriver != null) {
      yield r'assistDriver';
      yield serializers.serialize(
        object.assistDriver,
        specifiedType: const FullType(Driver),
      );
    }
    if (object.items != null) {
      yield r'items';
      yield serializers.serialize(
        object.items,
        specifiedType: const FullType(BuiltList, [FullType(OrderDeliveryGroupItem)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderDeliveryGroup object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderDeliveryGroupBuilder result,
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
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'sequence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.sequence = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeliveryGroupStatus),
          ) as DeliveryGroupStatus;
          result.status = valueDes;
          break;
        case r'primaryDriverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.primaryDriverId = valueDes;
          break;
        case r'primaryDriverShiftId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.primaryDriverShiftId = valueDes;
          break;
        case r'assistDriverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assistDriverId = valueDes;
          break;
        case r'assistDriverShiftId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assistDriverShiftId = valueDes;
          break;
        case r'assistFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.assistFee = valueDes;
          break;
        case r'assistCustomerApproved':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.assistCustomerApproved = valueDes;
          break;
        case r'assistApprovedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.assistApprovedAt = valueDes;
          break;
        case r'isStacked':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isStacked = valueDes;
          break;
        case r'isPaymentCollector':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isPaymentCollector = valueDes;
          break;
        case r'assignedByUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.assignedByUserId = valueDes;
          break;
        case r'assignedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.assignedAt = valueDes;
          break;
        case r'distanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.distanceKm = valueDes;
          break;
        case r'deliveryFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.deliveryFee = valueDes;
          break;
        case r'goldSurchargeAmount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.goldSurchargeAmount = valueDes;
          break;
        case r'primaryDriverTierSnapshot':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverTier),
          ) as DriverTier;
          result.primaryDriverTierSnapshot = valueDes;
          break;
        case r'settledGoldBonusAmount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.settledGoldBonusAmount = valueDes;
          break;
        case r'settledGoldPlatformRetainedAmount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.settledGoldPlatformRetainedAmount = valueDes;
          break;
        case r'settledBronzeDriverDeduction':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.settledBronzeDriverDeduction = valueDes;
          break;
        case r'settledBronzeSupervisorDeduction':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.settledBronzeSupervisorDeduction = valueDes;
          break;
        case r'settledPrimaryManagerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.settledPrimaryManagerId = valueDes;
          break;
        case r'estimatedPrepTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.estimatedPrepTime = valueDes;
          break;
        case r'pickupImageUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pickupImageUrl = valueDes;
          break;
        case r'deliveryImageUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryImageUrl = valueDes;
          break;
        case r'pickedUpAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.pickedUpAt = valueDes;
          break;
        case r'deliveredAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deliveredAt = valueDes;
          break;
        case r'primaryDriver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Driver),
          ) as Driver;
          result.primaryDriver.replace(valueDes);
          break;
        case r'assistDriver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Driver),
          ) as Driver;
          result.assistDriver.replace(valueDes);
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderDeliveryGroupItem)]),
          ) as BuiltList<OrderDeliveryGroupItem>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderDeliveryGroup deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderDeliveryGroupBuilder();
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

