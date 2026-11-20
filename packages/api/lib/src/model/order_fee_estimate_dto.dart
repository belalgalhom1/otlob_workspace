//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_fee_estimate_dto.g.dart';

/// OrderFeeEstimateDto
///
/// Properties:
/// * [distanceKm] - Vendor branch to delivery distance in km
/// * [deliveryFee] 
/// * [serviceFee] 
/// * [driverBonusFee] 
/// * [tax] 
/// * [coinsUsed] 
/// * [discount] 
/// * [coinsEarned] 
/// * [grandTotal] 
/// * [upfrontAmount] 
/// * [subtotal] 
/// * [isSplit] 
/// * [vendorCount] 
/// * [branchCount] 
/// * [deliveryCount] 
/// * [driverBonusPaidByCustomer] - Whether the customer pays driverBonusFee inside grandTotal (false when platform-funded)
@BuiltValue()
abstract class OrderFeeEstimateDto implements Built<OrderFeeEstimateDto, OrderFeeEstimateDtoBuilder> {
  /// Vendor branch to delivery distance in km
  @BuiltValueField(wireName: r'distanceKm')
  num get distanceKm;

  @BuiltValueField(wireName: r'deliveryFee')
  num get deliveryFee;

  @BuiltValueField(wireName: r'serviceFee')
  num get serviceFee;

  @BuiltValueField(wireName: r'driverBonusFee')
  num get driverBonusFee;

  @BuiltValueField(wireName: r'tax')
  num get tax;

  @BuiltValueField(wireName: r'coinsUsed')
  num get coinsUsed;

  @BuiltValueField(wireName: r'discount')
  num get discount;

  @BuiltValueField(wireName: r'coinsEarned')
  num get coinsEarned;

  @BuiltValueField(wireName: r'grandTotal')
  num get grandTotal;

  @BuiltValueField(wireName: r'upfrontAmount')
  num get upfrontAmount;

  @BuiltValueField(wireName: r'subtotal')
  num? get subtotal;

  @BuiltValueField(wireName: r'isSplit')
  bool? get isSplit;

  @BuiltValueField(wireName: r'vendorCount')
  num? get vendorCount;

  @BuiltValueField(wireName: r'branchCount')
  num? get branchCount;

  @BuiltValueField(wireName: r'deliveryCount')
  num? get deliveryCount;

  /// Whether the customer pays driverBonusFee inside grandTotal (false when platform-funded)
  @BuiltValueField(wireName: r'driverBonusPaidByCustomer')
  bool? get driverBonusPaidByCustomer;

  OrderFeeEstimateDto._();

  factory OrderFeeEstimateDto([void updates(OrderFeeEstimateDtoBuilder b)]) = _$OrderFeeEstimateDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderFeeEstimateDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderFeeEstimateDto> get serializer => _$OrderFeeEstimateDtoSerializer();
}

class _$OrderFeeEstimateDtoSerializer implements PrimitiveSerializer<OrderFeeEstimateDto> {
  @override
  final Iterable<Type> types = const [OrderFeeEstimateDto, _$OrderFeeEstimateDto];

  @override
  final String wireName = r'OrderFeeEstimateDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderFeeEstimateDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'distanceKm';
    yield serializers.serialize(
      object.distanceKm,
      specifiedType: const FullType(num),
    );
    yield r'deliveryFee';
    yield serializers.serialize(
      object.deliveryFee,
      specifiedType: const FullType(num),
    );
    yield r'serviceFee';
    yield serializers.serialize(
      object.serviceFee,
      specifiedType: const FullType(num),
    );
    yield r'driverBonusFee';
    yield serializers.serialize(
      object.driverBonusFee,
      specifiedType: const FullType(num),
    );
    yield r'tax';
    yield serializers.serialize(
      object.tax,
      specifiedType: const FullType(num),
    );
    yield r'coinsUsed';
    yield serializers.serialize(
      object.coinsUsed,
      specifiedType: const FullType(num),
    );
    yield r'discount';
    yield serializers.serialize(
      object.discount,
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
    if (object.subtotal != null) {
      yield r'subtotal';
      yield serializers.serialize(
        object.subtotal,
        specifiedType: const FullType(num),
      );
    }
    if (object.isSplit != null) {
      yield r'isSplit';
      yield serializers.serialize(
        object.isSplit,
        specifiedType: const FullType(bool),
      );
    }
    if (object.vendorCount != null) {
      yield r'vendorCount';
      yield serializers.serialize(
        object.vendorCount,
        specifiedType: const FullType(num),
      );
    }
    if (object.branchCount != null) {
      yield r'branchCount';
      yield serializers.serialize(
        object.branchCount,
        specifiedType: const FullType(num),
      );
    }
    if (object.deliveryCount != null) {
      yield r'deliveryCount';
      yield serializers.serialize(
        object.deliveryCount,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverBonusPaidByCustomer != null) {
      yield r'driverBonusPaidByCustomer';
      yield serializers.serialize(
        object.driverBonusPaidByCustomer,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderFeeEstimateDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderFeeEstimateDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'serviceFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.serviceFee = valueDes;
          break;
        case r'driverBonusFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverBonusFee = valueDes;
          break;
        case r'tax':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.tax = valueDes;
          break;
        case r'coinsUsed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.coinsUsed = valueDes;
          break;
        case r'discount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.discount = valueDes;
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
        case r'subtotal':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.subtotal = valueDes;
          break;
        case r'isSplit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isSplit = valueDes;
          break;
        case r'vendorCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.vendorCount = valueDes;
          break;
        case r'branchCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.branchCount = valueDes;
          break;
        case r'deliveryCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.deliveryCount = valueDes;
          break;
        case r'driverBonusPaidByCustomer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.driverBonusPaidByCustomer = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderFeeEstimateDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderFeeEstimateDtoBuilder();
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

