//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vendor.dart';
import 'package:api/src/model/order_item.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/vendor_branch.dart';
import 'package:api/src/model/order_vendor_fulfillment_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_vendor_fulfillment.g.dart';

/// OrderVendorFulfillment
///
/// Properties:
/// * [id] 
/// * [orderId] 
/// * [vendorId] 
/// * [vendorBranchId] 
/// * [status] 
/// * [stage] 
/// * [subtotal] 
/// * [commissionRate] 
/// * [rejectionCode] 
/// * [rejectionReason] 
/// * [rejectionReasonAr] 
/// * [preparingAt] 
/// * [readyAt] 
/// * [pickupImageUrl] 
/// * [pickedUpAt] 
/// * [deliveredAt] 
/// * [vendor] 
/// * [vendorBranch] 
/// * [items] 
@BuiltValue()
abstract class OrderVendorFulfillment implements Built<OrderVendorFulfillment, OrderVendorFulfillmentBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'vendorBranchId')
  String? get vendorBranchId;

  @BuiltValueField(wireName: r'status')
  OrderVendorFulfillmentStatus get status;
  // enum statusEnum {  PENDING,  ACCEPTED,  PREPARING,  READY_FOR_PICKUP,  PICKED_UP,  REJECTED,  CANCELLED,  };

  @BuiltValueField(wireName: r'stage')
  String? get stage;

  @BuiltValueField(wireName: r'subtotal')
  num get subtotal;

  @BuiltValueField(wireName: r'commissionRate')
  num get commissionRate;

  @BuiltValueField(wireName: r'rejectionCode')
  String? get rejectionCode;

  @BuiltValueField(wireName: r'rejectionReason')
  String? get rejectionReason;

  @BuiltValueField(wireName: r'rejectionReasonAr')
  String? get rejectionReasonAr;

  @BuiltValueField(wireName: r'preparingAt')
  DateTime? get preparingAt;

  @BuiltValueField(wireName: r'readyAt')
  DateTime? get readyAt;

  @BuiltValueField(wireName: r'pickupImageUrl')
  String? get pickupImageUrl;

  @BuiltValueField(wireName: r'pickedUpAt')
  DateTime? get pickedUpAt;

  @BuiltValueField(wireName: r'deliveredAt')
  DateTime? get deliveredAt;

  @BuiltValueField(wireName: r'vendor')
  Vendor? get vendor;

  @BuiltValueField(wireName: r'vendorBranch')
  VendorBranch? get vendorBranch;

  @BuiltValueField(wireName: r'items')
  BuiltList<OrderItem>? get items;

  OrderVendorFulfillment._();

  factory OrderVendorFulfillment([void updates(OrderVendorFulfillmentBuilder b)]) = _$OrderVendorFulfillment;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderVendorFulfillmentBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderVendorFulfillment> get serializer => _$OrderVendorFulfillmentSerializer();
}

class _$OrderVendorFulfillmentSerializer implements PrimitiveSerializer<OrderVendorFulfillment> {
  @override
  final Iterable<Type> types = const [OrderVendorFulfillment, _$OrderVendorFulfillment];

  @override
  final String wireName = r'OrderVendorFulfillment';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderVendorFulfillment object, {
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
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
    if (object.vendorBranchId != null) {
      yield r'vendorBranchId';
      yield serializers.serialize(
        object.vendorBranchId,
        specifiedType: const FullType(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(OrderVendorFulfillmentStatus),
    );
    if (object.stage != null) {
      yield r'stage';
      yield serializers.serialize(
        object.stage,
        specifiedType: const FullType(String),
      );
    }
    yield r'subtotal';
    yield serializers.serialize(
      object.subtotal,
      specifiedType: const FullType(num),
    );
    yield r'commissionRate';
    yield serializers.serialize(
      object.commissionRate,
      specifiedType: const FullType(num),
    );
    if (object.rejectionCode != null) {
      yield r'rejectionCode';
      yield serializers.serialize(
        object.rejectionCode,
        specifiedType: const FullType(String),
      );
    }
    if (object.rejectionReason != null) {
      yield r'rejectionReason';
      yield serializers.serialize(
        object.rejectionReason,
        specifiedType: const FullType(String),
      );
    }
    if (object.rejectionReasonAr != null) {
      yield r'rejectionReasonAr';
      yield serializers.serialize(
        object.rejectionReasonAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.preparingAt != null) {
      yield r'preparingAt';
      yield serializers.serialize(
        object.preparingAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.readyAt != null) {
      yield r'readyAt';
      yield serializers.serialize(
        object.readyAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.pickupImageUrl != null) {
      yield r'pickupImageUrl';
      yield serializers.serialize(
        object.pickupImageUrl,
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
    if (object.items != null) {
      yield r'items';
      yield serializers.serialize(
        object.items,
        specifiedType: const FullType(BuiltList, [FullType(OrderItem)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderVendorFulfillment object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderVendorFulfillmentBuilder result,
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
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderVendorFulfillmentStatus),
          ) as OrderVendorFulfillmentStatus;
          result.status = valueDes;
          break;
        case r'stage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.stage = valueDes;
          break;
        case r'subtotal':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.subtotal = valueDes;
          break;
        case r'commissionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.commissionRate = valueDes;
          break;
        case r'rejectionCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.rejectionCode = valueDes;
          break;
        case r'rejectionReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.rejectionReason = valueDes;
          break;
        case r'rejectionReasonAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.rejectionReasonAr = valueDes;
          break;
        case r'preparingAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.preparingAt = valueDes;
          break;
        case r'readyAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.readyAt = valueDes;
          break;
        case r'pickupImageUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pickupImageUrl = valueDes;
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
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderItem)]),
          ) as BuiltList<OrderItem>;
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
  OrderVendorFulfillment deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderVendorFulfillmentBuilder();
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

