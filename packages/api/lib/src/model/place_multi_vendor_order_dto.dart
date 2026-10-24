//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'place_multi_vendor_order_dto.g.dart';

/// PlaceMultiVendorOrderDto
///
/// Properties:
/// * [vendorIds] - Vendors being checked out together (2 or more)
/// * [paymentMethod] - CASH_ON_DELIVERY or MOBILE_WALLET
/// * [deliveryAddress]
/// * [deliveryLocation] - [longitude, latitude]
/// * [specialRequest]
/// * [coinsToUse]
@BuiltValue()
abstract class PlaceMultiVendorOrderDto implements Built<PlaceMultiVendorOrderDto, PlaceMultiVendorOrderDtoBuilder> {
  @BuiltValueField(wireName: r'vendorIds')
  BuiltList<String> get vendorIds;

  @BuiltValueField(wireName: r'paymentMethod')
  String get paymentMethod;

  @BuiltValueField(wireName: r'deliveryAddress')
  String get deliveryAddress;

  /// [longitude, latitude]
  @BuiltValueField(wireName: r'deliveryLocation')
  BuiltList<num> get deliveryLocation;

  @BuiltValueField(wireName: r'specialRequest')
  String? get specialRequest;

  @BuiltValueField(wireName: r'coinsToUse')
  num? get coinsToUse;

  PlaceMultiVendorOrderDto._();

  factory PlaceMultiVendorOrderDto([void updates(PlaceMultiVendorOrderDtoBuilder b)]) = _$PlaceMultiVendorOrderDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlaceMultiVendorOrderDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlaceMultiVendorOrderDto> get serializer => _$PlaceMultiVendorOrderDtoSerializer();
}

class _$PlaceMultiVendorOrderDtoSerializer implements PrimitiveSerializer<PlaceMultiVendorOrderDto> {
  @override
  final Iterable<Type> types = const [PlaceMultiVendorOrderDto, _$PlaceMultiVendorOrderDto];

  @override
  final String wireName = r'PlaceMultiVendorOrderDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlaceMultiVendorOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'vendorIds';
    yield serializers.serialize(
      object.vendorIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'paymentMethod';
    yield serializers.serialize(
      object.paymentMethod,
      specifiedType: const FullType(String),
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
    PlaceMultiVendorOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlaceMultiVendorOrderDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'vendorIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.vendorIds.replace(valueDes);
          break;
        case r'paymentMethod':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  PlaceMultiVendorOrderDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlaceMultiVendorOrderDtoBuilder();
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
