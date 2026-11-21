//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_wallet_transaction.dart';
import 'package:api/src/model/customer.dart';
import 'package:api/src/model/order_delivery_group.dart';
import 'package:api/src/model/vendor.dart';
import 'package:api/src/model/zone.dart';
import 'package:api/src/model/payment_method.dart';
import 'package:api/src/model/role.dart';
import 'package:api/src/model/order_cancelled_by_dto.dart';
import 'package:api/src/model/order_dispatch.dart';
import 'package:api/src/model/order_vendor_fulfillment.dart';
import 'package:api/src/model/order_item.dart';
import 'package:api/src/model/vehicle_type.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/order_status_event.dart';
import 'package:api/src/model/vendor_wallet_transaction.dart';
import 'package:api/src/model/order_type.dart';
import 'package:api/src/model/order_status.dart';
import 'package:api/src/model/vendor_branch.dart';
import 'package:api/src/model/driver.dart';
import 'package:api/src/model/support_ticket.dart';
import 'package:api/src/model/payment_status.dart';
import 'package:api/src/model/order_review.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_response_dto.g.dart';

/// OrderResponseDto
///
/// Properties:
/// * [id] 
/// * [orderNumber] 
/// * [clientOrderKey] 
/// * [type] 
/// * [customerId] 
/// * [vendorId] 
/// * [vendorBranchId] 
/// * [driverId] 
/// * [zoneId] 
/// * [status] 
/// * [revision] 
/// * [paymentMethod] 
/// * [paymentStatus] 
/// * [deliveryAddress] 
/// * [pickupAddress] 
/// * [itemDetails] 
/// * [requestedVehicleType] 
/// * [subtotal] 
/// * [deliveryFee] 
/// * [goldSurchargeAmount] 
/// * [driverBonusFee] 
/// * [serviceFee] 
/// * [tax] 
/// * [discount] 
/// * [coinsUsed] 
/// * [coinsEarned] 
/// * [grandTotal] 
/// * [upfrontAmount] 
/// * [specialRequest] 
/// * [distanceKm] 
/// * [deletedAt] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [paymentReceiptUrl] 
/// * [actualDeliveryTime] 
/// * [settledAt] 
/// * [settledGoldBonusAmount] 
/// * [settledGoldPlatformRetainedAmount] 
/// * [settledBronzeDriverDeduction] 
/// * [settledBronzeSupervisorDeduction] 
/// * [settledBronzeDriverDeductionRate] 
/// * [settledBronzeSupervisorDeductionRate] 
/// * [cancelledByUserId] 
/// * [cancelledByRole] 
/// * [cancelledByName] 
/// * [cancelledByNameAr] 
/// * [cancelledByAvatar] 
/// * [cancelReason] 
/// * [cancelledAt] 
/// * [driverTransactions] 
/// * [dispatches] 
/// * [items] 
/// * [statusEvents] 
/// * [customer] 
/// * [driver] 
/// * [vendor] 
/// * [vendorBranch] 
/// * [zone] 
/// * [supportTickets] 
/// * [vendorTransactions] 
/// * [reviews] 
/// * [vendorFulfillments] 
/// * [deliveryGroups] 
/// * [fulfillmentSummary] 
/// * [cancelledBy] 
@BuiltValue()
abstract class OrderResponseDto implements Built<OrderResponseDto, OrderResponseDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderNumber')
  String get orderNumber;

  @BuiltValueField(wireName: r'clientOrderKey')
  String? get clientOrderKey;

  @BuiltValueField(wireName: r'type')
  OrderType get type;
  // enum typeEnum {  STANDARD,  CUSTOM_DELIVERY,  RIDE,  };

  @BuiltValueField(wireName: r'customerId')
  String get customerId;

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  @BuiltValueField(wireName: r'vendorBranchId')
  String? get vendorBranchId;

  @BuiltValueField(wireName: r'driverId')
  String? get driverId;

  @BuiltValueField(wireName: r'zoneId')
  String? get zoneId;

  @BuiltValueField(wireName: r'status')
  OrderStatus get status;
  // enum statusEnum {  PENDING,  CHANGES_REQUESTED,  ACCEPTED,  PREPARING,  LOOKING_FOR_DRIVER,  DRIVER_ASSIGNED,  PENDING_PAYMENT,  READY_FOR_PICKUP,  PARTIALLY_PICKED_UP,  PICKED_UP,  DELIVERED,  CANCELLED,  };

  @BuiltValueField(wireName: r'revision')
  num get revision;

  @BuiltValueField(wireName: r'paymentMethod')
  PaymentMethod get paymentMethod;
  // enum paymentMethodEnum {  CASH_ON_DELIVERY,  MOBILE_WALLET,  };

  @BuiltValueField(wireName: r'paymentStatus')
  PaymentStatus get paymentStatus;
  // enum paymentStatusEnum {  PENDING,  FAILED,  PAID,  COMPLETED,  };

  @BuiltValueField(wireName: r'deliveryAddress')
  String get deliveryAddress;

  @BuiltValueField(wireName: r'pickupAddress')
  String? get pickupAddress;

  @BuiltValueField(wireName: r'itemDetails')
  String? get itemDetails;

  @BuiltValueField(wireName: r'requestedVehicleType')
  VehicleType? get requestedVehicleType;
  // enum requestedVehicleTypeEnum {  BICYCLE,  MOTORCYCLE,  CAR,  MINIBUS,  TUK_TUK,  MOTOR_TRICYCLE,  QUARTER_TRUCK,  HALF_TRUCK,  };

  @BuiltValueField(wireName: r'subtotal')
  num get subtotal;

  @BuiltValueField(wireName: r'deliveryFee')
  num get deliveryFee;

  @BuiltValueField(wireName: r'goldSurchargeAmount')
  num get goldSurchargeAmount;

  @BuiltValueField(wireName: r'driverBonusFee')
  num get driverBonusFee;

  @BuiltValueField(wireName: r'serviceFee')
  num get serviceFee;

  @BuiltValueField(wireName: r'tax')
  num get tax;

  @BuiltValueField(wireName: r'discount')
  num get discount;

  @BuiltValueField(wireName: r'coinsUsed')
  num get coinsUsed;

  @BuiltValueField(wireName: r'coinsEarned')
  num get coinsEarned;

  @BuiltValueField(wireName: r'grandTotal')
  num get grandTotal;

  @BuiltValueField(wireName: r'upfrontAmount')
  num get upfrontAmount;

  @BuiltValueField(wireName: r'specialRequest')
  String? get specialRequest;

  @BuiltValueField(wireName: r'distanceKm')
  num? get distanceKm;

  @BuiltValueField(wireName: r'deletedAt')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'paymentReceiptUrl')
  String? get paymentReceiptUrl;

  @BuiltValueField(wireName: r'actualDeliveryTime')
  DateTime? get actualDeliveryTime;

  @BuiltValueField(wireName: r'settledAt')
  DateTime? get settledAt;

  @BuiltValueField(wireName: r'settledGoldBonusAmount')
  num get settledGoldBonusAmount;

  @BuiltValueField(wireName: r'settledGoldPlatformRetainedAmount')
  num get settledGoldPlatformRetainedAmount;

  @BuiltValueField(wireName: r'settledBronzeDriverDeduction')
  num get settledBronzeDriverDeduction;

  @BuiltValueField(wireName: r'settledBronzeSupervisorDeduction')
  num get settledBronzeSupervisorDeduction;

  @BuiltValueField(wireName: r'settledBronzeDriverDeductionRate')
  num? get settledBronzeDriverDeductionRate;

  @BuiltValueField(wireName: r'settledBronzeSupervisorDeductionRate')
  num? get settledBronzeSupervisorDeductionRate;

  @BuiltValueField(wireName: r'cancelledByUserId')
  String? get cancelledByUserId;

  @BuiltValueField(wireName: r'cancelledByRole')
  Role? get cancelledByRole;
  // enum cancelledByRoleEnum {  CUSTOMER,  DRIVER,  DRIVER_MANAGER,  VENDOR_MEMBER,  ADMIN,  SUPER_ADMIN,  };

  @BuiltValueField(wireName: r'cancelledByName')
  String? get cancelledByName;

  @BuiltValueField(wireName: r'cancelledByNameAr')
  String? get cancelledByNameAr;

  @BuiltValueField(wireName: r'cancelledByAvatar')
  String? get cancelledByAvatar;

  @BuiltValueField(wireName: r'cancelReason')
  String? get cancelReason;

  @BuiltValueField(wireName: r'cancelledAt')
  DateTime? get cancelledAt;

  @BuiltValueField(wireName: r'driverTransactions')
  BuiltList<DriverWalletTransaction>? get driverTransactions;

  @BuiltValueField(wireName: r'dispatches')
  BuiltList<OrderDispatch>? get dispatches;

  @BuiltValueField(wireName: r'items')
  BuiltList<OrderItem>? get items;

  @BuiltValueField(wireName: r'statusEvents')
  BuiltList<OrderStatusEvent>? get statusEvents;

  @BuiltValueField(wireName: r'customer')
  Customer? get customer;

  @BuiltValueField(wireName: r'driver')
  Driver? get driver;

  @BuiltValueField(wireName: r'vendor')
  Vendor? get vendor;

  @BuiltValueField(wireName: r'vendorBranch')
  VendorBranch? get vendorBranch;

  @BuiltValueField(wireName: r'zone')
  Zone? get zone;

  @BuiltValueField(wireName: r'supportTickets')
  BuiltList<SupportTicket>? get supportTickets;

  @BuiltValueField(wireName: r'vendorTransactions')
  BuiltList<VendorWalletTransaction>? get vendorTransactions;

  @BuiltValueField(wireName: r'reviews')
  BuiltList<OrderReview>? get reviews;

  @BuiltValueField(wireName: r'vendorFulfillments')
  BuiltList<OrderVendorFulfillment>? get vendorFulfillments;

  @BuiltValueField(wireName: r'deliveryGroups')
  BuiltList<OrderDeliveryGroup>? get deliveryGroups;

  @BuiltValueField(wireName: r'fulfillmentSummary')
  JsonObject? get fulfillmentSummary;

  @BuiltValueField(wireName: r'cancelledBy')
  OrderCancelledByDto? get cancelledBy;

  OrderResponseDto._();

  factory OrderResponseDto([void updates(OrderResponseDtoBuilder b)]) = _$OrderResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderResponseDto> get serializer => _$OrderResponseDtoSerializer();
}

class _$OrderResponseDtoSerializer implements PrimitiveSerializer<OrderResponseDto> {
  @override
  final Iterable<Type> types = const [OrderResponseDto, _$OrderResponseDto];

  @override
  final String wireName = r'OrderResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'orderNumber';
    yield serializers.serialize(
      object.orderNumber,
      specifiedType: const FullType(String),
    );
    if (object.clientOrderKey != null) {
      yield r'clientOrderKey';
      yield serializers.serialize(
        object.clientOrderKey,
        specifiedType: const FullType(String),
      );
    }
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(OrderType),
    );
    yield r'customerId';
    yield serializers.serialize(
      object.customerId,
      specifiedType: const FullType(String),
    );
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(String),
      );
    }
    if (object.vendorBranchId != null) {
      yield r'vendorBranchId';
      yield serializers.serialize(
        object.vendorBranchId,
        specifiedType: const FullType(String),
      );
    }
    if (object.driverId != null) {
      yield r'driverId';
      yield serializers.serialize(
        object.driverId,
        specifiedType: const FullType(String),
      );
    }
    if (object.zoneId != null) {
      yield r'zoneId';
      yield serializers.serialize(
        object.zoneId,
        specifiedType: const FullType(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(OrderStatus),
    );
    yield r'revision';
    yield serializers.serialize(
      object.revision,
      specifiedType: const FullType(num),
    );
    yield r'paymentMethod';
    yield serializers.serialize(
      object.paymentMethod,
      specifiedType: const FullType(PaymentMethod),
    );
    yield r'paymentStatus';
    yield serializers.serialize(
      object.paymentStatus,
      specifiedType: const FullType(PaymentStatus),
    );
    yield r'deliveryAddress';
    yield serializers.serialize(
      object.deliveryAddress,
      specifiedType: const FullType(String),
    );
    if (object.pickupAddress != null) {
      yield r'pickupAddress';
      yield serializers.serialize(
        object.pickupAddress,
        specifiedType: const FullType(String),
      );
    }
    if (object.itemDetails != null) {
      yield r'itemDetails';
      yield serializers.serialize(
        object.itemDetails,
        specifiedType: const FullType(String),
      );
    }
    if (object.requestedVehicleType != null) {
      yield r'requestedVehicleType';
      yield serializers.serialize(
        object.requestedVehicleType,
        specifiedType: const FullType(VehicleType),
      );
    }
    yield r'subtotal';
    yield serializers.serialize(
      object.subtotal,
      specifiedType: const FullType(num),
    );
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
    yield r'driverBonusFee';
    yield serializers.serialize(
      object.driverBonusFee,
      specifiedType: const FullType(num),
    );
    yield r'serviceFee';
    yield serializers.serialize(
      object.serviceFee,
      specifiedType: const FullType(num),
    );
    yield r'tax';
    yield serializers.serialize(
      object.tax,
      specifiedType: const FullType(num),
    );
    yield r'discount';
    yield serializers.serialize(
      object.discount,
      specifiedType: const FullType(num),
    );
    yield r'coinsUsed';
    yield serializers.serialize(
      object.coinsUsed,
      specifiedType: const FullType(num),
    );
    yield r'coinsEarned';
    yield serializers.serialize(
      object.coinsEarned,
      specifiedType: const FullType(num),
    );
    yield r'grandTotal';
    yield serializers.serialize(
      object.grandTotal,
      specifiedType: const FullType(num),
    );
    yield r'upfrontAmount';
    yield serializers.serialize(
      object.upfrontAmount,
      specifiedType: const FullType(num),
    );
    if (object.specialRequest != null) {
      yield r'specialRequest';
      yield serializers.serialize(
        object.specialRequest,
        specifiedType: const FullType(String),
      );
    }
    if (object.distanceKm != null) {
      yield r'distanceKm';
      yield serializers.serialize(
        object.distanceKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.deletedAt != null) {
      yield r'deletedAt';
      yield serializers.serialize(
        object.deletedAt,
        specifiedType: const FullType(DateTime),
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
    if (object.paymentReceiptUrl != null) {
      yield r'paymentReceiptUrl';
      yield serializers.serialize(
        object.paymentReceiptUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.actualDeliveryTime != null) {
      yield r'actualDeliveryTime';
      yield serializers.serialize(
        object.actualDeliveryTime,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.settledAt != null) {
      yield r'settledAt';
      yield serializers.serialize(
        object.settledAt,
        specifiedType: const FullType(DateTime),
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
    if (object.settledBronzeDriverDeductionRate != null) {
      yield r'settledBronzeDriverDeductionRate';
      yield serializers.serialize(
        object.settledBronzeDriverDeductionRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.settledBronzeSupervisorDeductionRate != null) {
      yield r'settledBronzeSupervisorDeductionRate';
      yield serializers.serialize(
        object.settledBronzeSupervisorDeductionRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.cancelledByUserId != null) {
      yield r'cancelledByUserId';
      yield serializers.serialize(
        object.cancelledByUserId,
        specifiedType: const FullType(String),
      );
    }
    if (object.cancelledByRole != null) {
      yield r'cancelledByRole';
      yield serializers.serialize(
        object.cancelledByRole,
        specifiedType: const FullType(Role),
      );
    }
    if (object.cancelledByName != null) {
      yield r'cancelledByName';
      yield serializers.serialize(
        object.cancelledByName,
        specifiedType: const FullType(String),
      );
    }
    if (object.cancelledByNameAr != null) {
      yield r'cancelledByNameAr';
      yield serializers.serialize(
        object.cancelledByNameAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.cancelledByAvatar != null) {
      yield r'cancelledByAvatar';
      yield serializers.serialize(
        object.cancelledByAvatar,
        specifiedType: const FullType(String),
      );
    }
    if (object.cancelReason != null) {
      yield r'cancelReason';
      yield serializers.serialize(
        object.cancelReason,
        specifiedType: const FullType(String),
      );
    }
    if (object.cancelledAt != null) {
      yield r'cancelledAt';
      yield serializers.serialize(
        object.cancelledAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.driverTransactions != null) {
      yield r'driverTransactions';
      yield serializers.serialize(
        object.driverTransactions,
        specifiedType: const FullType(BuiltList, [FullType(DriverWalletTransaction)]),
      );
    }
    if (object.dispatches != null) {
      yield r'dispatches';
      yield serializers.serialize(
        object.dispatches,
        specifiedType: const FullType(BuiltList, [FullType(OrderDispatch)]),
      );
    }
    if (object.items != null) {
      yield r'items';
      yield serializers.serialize(
        object.items,
        specifiedType: const FullType(BuiltList, [FullType(OrderItem)]),
      );
    }
    if (object.statusEvents != null) {
      yield r'statusEvents';
      yield serializers.serialize(
        object.statusEvents,
        specifiedType: const FullType(BuiltList, [FullType(OrderStatusEvent)]),
      );
    }
    if (object.customer != null) {
      yield r'customer';
      yield serializers.serialize(
        object.customer,
        specifiedType: const FullType(Customer),
      );
    }
    if (object.driver != null) {
      yield r'driver';
      yield serializers.serialize(
        object.driver,
        specifiedType: const FullType(Driver),
      );
    }
    if (object.vendor != null) {
      yield r'vendor';
      yield serializers.serialize(
        object.vendor,
        specifiedType: const FullType(Vendor),
      );
    }
    if (object.vendorBranch != null) {
      yield r'vendorBranch';
      yield serializers.serialize(
        object.vendorBranch,
        specifiedType: const FullType(VendorBranch),
      );
    }
    if (object.zone != null) {
      yield r'zone';
      yield serializers.serialize(
        object.zone,
        specifiedType: const FullType(Zone),
      );
    }
    if (object.supportTickets != null) {
      yield r'supportTickets';
      yield serializers.serialize(
        object.supportTickets,
        specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
      );
    }
    if (object.vendorTransactions != null) {
      yield r'vendorTransactions';
      yield serializers.serialize(
        object.vendorTransactions,
        specifiedType: const FullType(BuiltList, [FullType(VendorWalletTransaction)]),
      );
    }
    if (object.reviews != null) {
      yield r'reviews';
      yield serializers.serialize(
        object.reviews,
        specifiedType: const FullType(BuiltList, [FullType(OrderReview)]),
      );
    }
    if (object.vendorFulfillments != null) {
      yield r'vendorFulfillments';
      yield serializers.serialize(
        object.vendorFulfillments,
        specifiedType: const FullType(BuiltList, [FullType(OrderVendorFulfillment)]),
      );
    }
    if (object.deliveryGroups != null) {
      yield r'deliveryGroups';
      yield serializers.serialize(
        object.deliveryGroups,
        specifiedType: const FullType(BuiltList, [FullType(OrderDeliveryGroup)]),
      );
    }
    if (object.fulfillmentSummary != null) {
      yield r'fulfillmentSummary';
      yield serializers.serialize(
        object.fulfillmentSummary,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.cancelledBy != null) {
      yield r'cancelledBy';
      yield serializers.serialize(
        object.cancelledBy,
        specifiedType: const FullType(OrderCancelledByDto),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderResponseDtoBuilder result,
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
        case r'orderNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderNumber = valueDes;
          break;
        case r'clientOrderKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.clientOrderKey = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderType),
          ) as OrderType;
          result.type = valueDes;
          break;
        case r'customerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.customerId = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'vendorBranchId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorBranchId = valueDes;
          break;
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
        case r'zoneId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderStatus),
          ) as OrderStatus;
          result.status = valueDes;
          break;
        case r'revision':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.revision = valueDes;
          break;
        case r'paymentMethod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PaymentMethod),
          ) as PaymentMethod;
          result.paymentMethod = valueDes;
          break;
        case r'paymentStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PaymentStatus),
          ) as PaymentStatus;
          result.paymentStatus = valueDes;
          break;
        case r'deliveryAddress':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryAddress = valueDes;
          break;
        case r'pickupAddress':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pickupAddress = valueDes;
          break;
        case r'itemDetails':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.itemDetails = valueDes;
          break;
        case r'requestedVehicleType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(VehicleType),
          ) as VehicleType;
          result.requestedVehicleType = valueDes;
          break;
        case r'subtotal':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.subtotal = valueDes;
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
        case r'driverBonusFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverBonusFee = valueDes;
          break;
        case r'serviceFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.serviceFee = valueDes;
          break;
        case r'tax':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.tax = valueDes;
          break;
        case r'discount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.discount = valueDes;
          break;
        case r'coinsUsed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.coinsUsed = valueDes;
          break;
        case r'coinsEarned':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.coinsEarned = valueDes;
          break;
        case r'grandTotal':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.grandTotal = valueDes;
          break;
        case r'upfrontAmount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.upfrontAmount = valueDes;
          break;
        case r'specialRequest':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.specialRequest = valueDes;
          break;
        case r'distanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.distanceKm = valueDes;
          break;
        case r'deletedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deletedAt = valueDes;
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
        case r'paymentReceiptUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.paymentReceiptUrl = valueDes;
          break;
        case r'actualDeliveryTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.actualDeliveryTime = valueDes;
          break;
        case r'settledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.settledAt = valueDes;
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
        case r'settledBronzeDriverDeductionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.settledBronzeDriverDeductionRate = valueDes;
          break;
        case r'settledBronzeSupervisorDeductionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.settledBronzeSupervisorDeductionRate = valueDes;
          break;
        case r'cancelledByUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cancelledByUserId = valueDes;
          break;
        case r'cancelledByRole':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Role),
          ) as Role;
          result.cancelledByRole = valueDes;
          break;
        case r'cancelledByName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cancelledByName = valueDes;
          break;
        case r'cancelledByNameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cancelledByNameAr = valueDes;
          break;
        case r'cancelledByAvatar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cancelledByAvatar = valueDes;
          break;
        case r'cancelReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cancelReason = valueDes;
          break;
        case r'cancelledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.cancelledAt = valueDes;
          break;
        case r'driverTransactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverWalletTransaction)]),
          ) as BuiltList<DriverWalletTransaction>;
          result.driverTransactions.replace(valueDes);
          break;
        case r'dispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderDispatch)]),
          ) as BuiltList<OrderDispatch>;
          result.dispatches.replace(valueDes);
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderItem)]),
          ) as BuiltList<OrderItem>;
          result.items.replace(valueDes);
          break;
        case r'statusEvents':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderStatusEvent)]),
          ) as BuiltList<OrderStatusEvent>;
          result.statusEvents.replace(valueDes);
          break;
        case r'customer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Customer),
          ) as Customer;
          result.customer.replace(valueDes);
          break;
        case r'driver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Driver),
          ) as Driver;
          result.driver.replace(valueDes);
          break;
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Vendor),
          ) as Vendor;
          result.vendor.replace(valueDes);
          break;
        case r'vendorBranch':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(VendorBranch),
          ) as VendorBranch;
          result.vendorBranch.replace(valueDes);
          break;
        case r'zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Zone),
          ) as Zone;
          result.zone.replace(valueDes);
          break;
        case r'supportTickets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
          ) as BuiltList<SupportTicket>;
          result.supportTickets.replace(valueDes);
          break;
        case r'vendorTransactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VendorWalletTransaction)]),
          ) as BuiltList<VendorWalletTransaction>;
          result.vendorTransactions.replace(valueDes);
          break;
        case r'reviews':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderReview)]),
          ) as BuiltList<OrderReview>;
          result.reviews.replace(valueDes);
          break;
        case r'vendorFulfillments':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderVendorFulfillment)]),
          ) as BuiltList<OrderVendorFulfillment>;
          result.vendorFulfillments.replace(valueDes);
          break;
        case r'deliveryGroups':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderDeliveryGroup)]),
          ) as BuiltList<OrderDeliveryGroup>;
          result.deliveryGroups.replace(valueDes);
          break;
        case r'fulfillmentSummary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.fulfillmentSummary = valueDes;
          break;
        case r'cancelledBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderCancelledByDto),
          ) as OrderCancelledByDto;
          result.cancelledBy.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderResponseDtoBuilder();
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

