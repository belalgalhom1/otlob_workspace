//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'place_direct_order_dto.g.dart';

/// PlaceDirectOrderDto
///
/// Properties:
/// * [customerId] 
/// * [vendorId] 
/// * [productId] 
/// * [productName] 
/// * [price] 
/// * [quantity] 
/// * [paymentMethod] 
/// * [deliveryAddress] 
/// * [deliveryLocation] - [longitude, latitude]
/// * [specialRequest] 
@BuiltValue()
abstract class PlaceDirectOrderDto implements Built<PlaceDirectOrderDto, PlaceDirectOrderDtoBuilder> {
  @BuiltValueField(wireName: r'customerId')
  String get customerId;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'productId')
  String? get productId;

  @BuiltValueField(wireName: r'productName')
  String? get productName;

  @BuiltValueField(wireName: r'price')
  num get price;

  @BuiltValueField(wireName: r'quantity')
  num get quantity;

  @BuiltValueField(wireName: r'paymentMethod')
  PlaceDirectOrderDtoPaymentMethodEnum get paymentMethod;
  // enum paymentMethodEnum {  CASH_ON_DELIVERY,  MOBILE_WALLET,  };

  @BuiltValueField(wireName: r'deliveryAddress')
  String? get deliveryAddress;

  /// [longitude, latitude]
  @BuiltValueField(wireName: r'deliveryLocation')
  BuiltList<num>? get deliveryLocation;

  @BuiltValueField(wireName: r'specialRequest')
  String? get specialRequest;

  PlaceDirectOrderDto._();

  factory PlaceDirectOrderDto([void updates(PlaceDirectOrderDtoBuilder b)]) = _$PlaceDirectOrderDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlaceDirectOrderDtoBuilder b) => b
      ..quantity = 1
      ..paymentMethod = PlaceDirectOrderDtoPaymentMethodEnum.valueOf('CASH_ON_DELIVERY');

  @BuiltValueSerializer(custom: true)
  static Serializer<PlaceDirectOrderDto> get serializer => _$PlaceDirectOrderDtoSerializer();
}

class _$PlaceDirectOrderDtoSerializer implements PrimitiveSerializer<PlaceDirectOrderDto> {
  @override
  final Iterable<Type> types = const [PlaceDirectOrderDto, _$PlaceDirectOrderDto];

  @override
  final String wireName = r'PlaceDirectOrderDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlaceDirectOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'customerId';
    yield serializers.serialize(
      object.customerId,
      specifiedType: const FullType(String),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
    if (object.productId != null) {
      yield r'productId';
      yield serializers.serialize(
        object.productId,
        specifiedType: const FullType(String),
      );
    }
    if (object.productName != null) {
      yield r'productName';
      yield serializers.serialize(
        object.productName,
        specifiedType: const FullType(String),
      );
    }
    yield r'price';
    yield serializers.serialize(
      object.price,
      specifiedType: const FullType(num),
    );
    yield r'quantity';
    yield serializers.serialize(
      object.quantity,
      specifiedType: const FullType(num),
    );
    yield r'paymentMethod';
    yield serializers.serialize(
      object.paymentMethod,
      specifiedType: const FullType(PlaceDirectOrderDtoPaymentMethodEnum),
    );
    if (object.deliveryAddress != null) {
      yield r'deliveryAddress';
      yield serializers.serialize(
        object.deliveryAddress,
        specifiedType: const FullType(String),
      );
    }
    if (object.deliveryLocation != null) {
      yield r'deliveryLocation';
      yield serializers.serialize(
        object.deliveryLocation,
        specifiedType: const FullType(BuiltList, [FullType(num)]),
      );
    }
    if (object.specialRequest != null) {
      yield r'specialRequest';
      yield serializers.serialize(
        object.specialRequest,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PlaceDirectOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlaceDirectOrderDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'productId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.productId = valueDes;
          break;
        case r'productName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.productName = valueDes;
          break;
        case r'price':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.price = valueDes;
          break;
        case r'quantity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.quantity = valueDes;
          break;
        case r'paymentMethod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlaceDirectOrderDtoPaymentMethodEnum),
          ) as PlaceDirectOrderDtoPaymentMethodEnum;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlaceDirectOrderDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlaceDirectOrderDtoBuilder();
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

class PlaceDirectOrderDtoPaymentMethodEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CASH_ON_DELIVERY')
  static const PlaceDirectOrderDtoPaymentMethodEnum CASH_ON_DELIVERY = _$placeDirectOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY;
  @BuiltValueEnumConst(wireName: r'MOBILE_WALLET')
  static const PlaceDirectOrderDtoPaymentMethodEnum MOBILE_WALLET = _$placeDirectOrderDtoPaymentMethodEnum_MOBILE_WALLET;

  static Serializer<PlaceDirectOrderDtoPaymentMethodEnum> get serializer => _$placeDirectOrderDtoPaymentMethodEnumSerializer;

  const PlaceDirectOrderDtoPaymentMethodEnum._(String name): super(name);

  static BuiltSet<PlaceDirectOrderDtoPaymentMethodEnum> get values => _$placeDirectOrderDtoPaymentMethodEnumValues;
  static PlaceDirectOrderDtoPaymentMethodEnum valueOf(String name) => _$placeDirectOrderDtoPaymentMethodEnumValueOf(name);
}

