//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'place_custom_order_dto.g.dart';

/// PlaceCustomOrderDto
///
/// Properties:
/// * [type] 
/// * [paymentMethod] 
/// * [pickupAddress] 
/// * [pickupLocation] - [longitude, latitude]
/// * [deliveryAddress] 
/// * [deliveryLocation] - [longitude, latitude]
/// * [vehicleType] 
/// * [itemDetails] 
/// * [specialRequest] 
/// * [coinsToUse] - Number of coins to use for partial or full payment
@BuiltValue()
abstract class PlaceCustomOrderDto implements Built<PlaceCustomOrderDto, PlaceCustomOrderDtoBuilder> {
  @BuiltValueField(wireName: r'type')
  PlaceCustomOrderDtoTypeEnum get type;
  // enum typeEnum {  CUSTOM_DELIVERY,  RIDE,  };

  @BuiltValueField(wireName: r'paymentMethod')
  PlaceCustomOrderDtoPaymentMethodEnum get paymentMethod;
  // enum paymentMethodEnum {  CASH_ON_DELIVERY,  MOBILE_WALLET,  };

  @BuiltValueField(wireName: r'pickupAddress')
  String get pickupAddress;

  /// [longitude, latitude]
  @BuiltValueField(wireName: r'pickupLocation')
  BuiltList<num> get pickupLocation;

  @BuiltValueField(wireName: r'deliveryAddress')
  String get deliveryAddress;

  /// [longitude, latitude]
  @BuiltValueField(wireName: r'deliveryLocation')
  BuiltList<num> get deliveryLocation;

  @BuiltValueField(wireName: r'vehicleType')
  PlaceCustomOrderDtoVehicleTypeEnum get vehicleType;
  // enum vehicleTypeEnum {  BICYCLE,  MOTORCYCLE,  CAR,  VAN,  TRUCK,  MOTOR_TRICYCLE,  };

  @BuiltValueField(wireName: r'itemDetails')
  String? get itemDetails;

  @BuiltValueField(wireName: r'specialRequest')
  String? get specialRequest;

  /// Number of coins to use for partial or full payment
  @BuiltValueField(wireName: r'coinsToUse')
  num? get coinsToUse;

  PlaceCustomOrderDto._();

  factory PlaceCustomOrderDto([void updates(PlaceCustomOrderDtoBuilder b)]) = _$PlaceCustomOrderDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlaceCustomOrderDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlaceCustomOrderDto> get serializer => _$PlaceCustomOrderDtoSerializer();
}

class _$PlaceCustomOrderDtoSerializer implements PrimitiveSerializer<PlaceCustomOrderDto> {
  @override
  final Iterable<Type> types = const [PlaceCustomOrderDto, _$PlaceCustomOrderDto];

  @override
  final String wireName = r'PlaceCustomOrderDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlaceCustomOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(PlaceCustomOrderDtoTypeEnum),
    );
    yield r'paymentMethod';
    yield serializers.serialize(
      object.paymentMethod,
      specifiedType: const FullType(PlaceCustomOrderDtoPaymentMethodEnum),
    );
    yield r'pickupAddress';
    yield serializers.serialize(
      object.pickupAddress,
      specifiedType: const FullType(String),
    );
    yield r'pickupLocation';
    yield serializers.serialize(
      object.pickupLocation,
      specifiedType: const FullType(BuiltList, [FullType(num)]),
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
    yield r'vehicleType';
    yield serializers.serialize(
      object.vehicleType,
      specifiedType: const FullType(PlaceCustomOrderDtoVehicleTypeEnum),
    );
    if (object.itemDetails != null) {
      yield r'itemDetails';
      yield serializers.serialize(
        object.itemDetails,
        specifiedType: const FullType(String),
      );
    }
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
    PlaceCustomOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlaceCustomOrderDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlaceCustomOrderDtoTypeEnum),
          ) as PlaceCustomOrderDtoTypeEnum;
          result.type = valueDes;
          break;
        case r'paymentMethod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlaceCustomOrderDtoPaymentMethodEnum),
          ) as PlaceCustomOrderDtoPaymentMethodEnum;
          result.paymentMethod = valueDes;
          break;
        case r'pickupAddress':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pickupAddress = valueDes;
          break;
        case r'pickupLocation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(num)]),
          ) as BuiltList<num>;
          result.pickupLocation.replace(valueDes);
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
        case r'vehicleType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlaceCustomOrderDtoVehicleTypeEnum),
          ) as PlaceCustomOrderDtoVehicleTypeEnum;
          result.vehicleType = valueDes;
          break;
        case r'itemDetails':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.itemDetails = valueDes;
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
  PlaceCustomOrderDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlaceCustomOrderDtoBuilder();
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

class PlaceCustomOrderDtoTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CUSTOM_DELIVERY')
  static const PlaceCustomOrderDtoTypeEnum CUSTOM_DELIVERY = _$placeCustomOrderDtoTypeEnum_CUSTOM_DELIVERY;
  @BuiltValueEnumConst(wireName: r'RIDE')
  static const PlaceCustomOrderDtoTypeEnum RIDE = _$placeCustomOrderDtoTypeEnum_RIDE;

  static Serializer<PlaceCustomOrderDtoTypeEnum> get serializer => _$placeCustomOrderDtoTypeEnumSerializer;

  const PlaceCustomOrderDtoTypeEnum._(String name): super(name);

  static BuiltSet<PlaceCustomOrderDtoTypeEnum> get values => _$placeCustomOrderDtoTypeEnumValues;
  static PlaceCustomOrderDtoTypeEnum valueOf(String name) => _$placeCustomOrderDtoTypeEnumValueOf(name);
}

class PlaceCustomOrderDtoPaymentMethodEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CASH_ON_DELIVERY')
  static const PlaceCustomOrderDtoPaymentMethodEnum CASH_ON_DELIVERY = _$placeCustomOrderDtoPaymentMethodEnum_CASH_ON_DELIVERY;
  @BuiltValueEnumConst(wireName: r'MOBILE_WALLET')
  static const PlaceCustomOrderDtoPaymentMethodEnum MOBILE_WALLET = _$placeCustomOrderDtoPaymentMethodEnum_MOBILE_WALLET;

  static Serializer<PlaceCustomOrderDtoPaymentMethodEnum> get serializer => _$placeCustomOrderDtoPaymentMethodEnumSerializer;

  const PlaceCustomOrderDtoPaymentMethodEnum._(String name): super(name);

  static BuiltSet<PlaceCustomOrderDtoPaymentMethodEnum> get values => _$placeCustomOrderDtoPaymentMethodEnumValues;
  static PlaceCustomOrderDtoPaymentMethodEnum valueOf(String name) => _$placeCustomOrderDtoPaymentMethodEnumValueOf(name);
}

class PlaceCustomOrderDtoVehicleTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BICYCLE')
  static const PlaceCustomOrderDtoVehicleTypeEnum BICYCLE = _$placeCustomOrderDtoVehicleTypeEnum_BICYCLE;
  @BuiltValueEnumConst(wireName: r'MOTORCYCLE')
  static const PlaceCustomOrderDtoVehicleTypeEnum MOTORCYCLE = _$placeCustomOrderDtoVehicleTypeEnum_MOTORCYCLE;
  @BuiltValueEnumConst(wireName: r'CAR')
  static const PlaceCustomOrderDtoVehicleTypeEnum CAR = _$placeCustomOrderDtoVehicleTypeEnum_CAR;
  @BuiltValueEnumConst(wireName: r'VAN')
  static const PlaceCustomOrderDtoVehicleTypeEnum VAN = _$placeCustomOrderDtoVehicleTypeEnum_VAN;
  @BuiltValueEnumConst(wireName: r'TRUCK')
  static const PlaceCustomOrderDtoVehicleTypeEnum TRUCK = _$placeCustomOrderDtoVehicleTypeEnum_TRUCK;
  @BuiltValueEnumConst(wireName: r'MOTOR_TRICYCLE')
  static const PlaceCustomOrderDtoVehicleTypeEnum MOTOR_TRICYCLE = _$placeCustomOrderDtoVehicleTypeEnum_MOTOR_TRICYCLE;

  static Serializer<PlaceCustomOrderDtoVehicleTypeEnum> get serializer => _$placeCustomOrderDtoVehicleTypeEnumSerializer;

  const PlaceCustomOrderDtoVehicleTypeEnum._(String name): super(name);

  static BuiltSet<PlaceCustomOrderDtoVehicleTypeEnum> get values => _$placeCustomOrderDtoVehicleTypeEnumValues;
  static PlaceCustomOrderDtoVehicleTypeEnum valueOf(String name) => _$placeCustomOrderDtoVehicleTypeEnumValueOf(name);
}

