//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'place_order_dto.g.dart';

/// PlaceOrderDto
///
/// Properties:
/// * [vendorId] 
/// * [paymentMethod] 
/// * [deliveryAddress] 
/// * [deliveryLocation] - [longitude, latitude]
/// * [specialRequest] 
/// * [coinsToUse] - Number of coins to use for partial or full payment
@BuiltValue()
abstract class PlaceOrderDto implements Built<PlaceOrderDto, PlaceOrderDtoBuilder> {
  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'paymentMethod')
  PlaceOrderDtoPaymentMethodEnum get paymentMethod;
  // enum paymentMethodEnum {  CASH_ON_DELIVERY,  MOBILE_WALLET,  };

  @BuiltValueField(wireName: r'deliveryAddress')
  String get deliveryAddress;

  /// [longitude, latitude]
  @BuiltValueField(wireName: r'deliveryLocation')
  BuiltList<num> get deliveryLocation;

  @BuiltValueField(wireName: r'specialRequest')
  String? get specialRequest;

  /// Number of coins to use for partial or full payment
  @BuiltValueField(wireName: r'coinsToUse')
  num? get coinsToUse;

  PlaceOrderDto._();

  factory PlaceOrderDto([void updates(PlaceOrderDtoBuilder b)]) = _$PlaceOrderDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlaceOrderDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlaceOrderDto> get serializer => _$PlaceOrderDtoSerializer();
}

class _$PlaceOrderDtoSerializer implements PrimitiveSerializer<PlaceOrderDto> {
  @override
  final Iterable<Type> types = const [PlaceOrderDto, _$PlaceOrderDto];

  @override
  final String wireName = r'PlaceOrderDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlaceOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
    yield r'paymentMethod';
    yield serializers.serialize(
      object.paymentMethod,
      specifiedType: const FullType(PlaceOrderDtoPaymentMethodEnum),
    );
    yield r'deliveryAddress';
    yield serializers.serialize(
      object.deliveryAddress,
      specifiedType: const FullType(String),
    );
    yield r'deliveryLocation';
    yield serializers.serialize(
      object.deliveryLocation,
      specifiedType: const FullType(BuiltList, [FullType(num)]),
    );
    if (object.specialRequest != null) {
      yield r'specialRequest';
      yield serializers.serialize(
        object.specialRequest,
        specifiedType: const FullType(String),
      );
    }
    if (object.coinsToUse != null) {
      yield r'coinsToUse';
      yield serializers.serialize(
        object.coinsToUse,
        specifiedType: const FullType(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlaceOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlaceOrderDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'paymentMethod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlaceOrderDtoPaymentMethodEnum),
          ) as PlaceOrderDtoPaymentMethodEnum;
          result.paymentMethod = valueDes;
          break;
        case r'deliveryAddress':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryAddress = valueDes;
          break;
        case r'deliveryLocation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(num)]),
          ) as BuiltList<num>;
          result.deliveryLocation.replace(valueDes);
          break;
        case r'specialRequest':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.specialRequest = valueDes;
          break;
        case r'coinsToUse':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.coinsToUse = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlaceOrderDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlaceOrderDtoBuilder();
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

class PlaceOrderDtoPaymentMethodEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CASH_ON_DELIVERY')
  static const PlaceOrderDtoPaymentMethodEnum CASH_ON_DELIVERY = _$placeOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY;
  @BuiltValueEnumConst(wireName: r'MOBILE_WALLET')
  static const PlaceOrderDtoPaymentMethodEnum MOBILE_WALLET = _$placeOrderDtoPaymentMethodEnum_MOBILE_WALLET;

  static Serializer<PlaceOrderDtoPaymentMethodEnum> get serializer => _$placeOrderDtoPaymentMethodEnumSerializer;

  const PlaceOrderDtoPaymentMethodEnum._(String name): super(name);

  static BuiltSet<PlaceOrderDtoPaymentMethodEnum> get values => _$placeOrderDtoPaymentMethodEnumValues;
  static PlaceOrderDtoPaymentMethodEnum valueOf(String name) => _$placeOrderDtoPaymentMethodEnumValueOf(name);
}

