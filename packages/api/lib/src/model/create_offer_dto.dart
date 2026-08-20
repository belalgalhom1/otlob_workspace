//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_offer_dto.g.dart';

/// CreateOfferDto
///
/// Properties:
/// * [productId] 
/// * [vendorId] 
/// * [originalPrice] 
/// * [offerPrice] 
/// * [sortOrder] 
/// * [startDate] 
/// * [endDate] 
@BuiltValue()
abstract class CreateOfferDto implements Built<CreateOfferDto, CreateOfferDtoBuilder> {
  @BuiltValueField(wireName: r'productId')
  String get productId;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'originalPrice')
  num get originalPrice;

  @BuiltValueField(wireName: r'offerPrice')
  num get offerPrice;

  @BuiltValueField(wireName: r'sortOrder')
  num? get sortOrder;

  @BuiltValueField(wireName: r'startDate')
  DateTime? get startDate;

  @BuiltValueField(wireName: r'endDate')
  DateTime? get endDate;

  CreateOfferDto._();

  factory CreateOfferDto([void updates(CreateOfferDtoBuilder b)]) = _$CreateOfferDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateOfferDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateOfferDto> get serializer => _$CreateOfferDtoSerializer();
}

class _$CreateOfferDtoSerializer implements PrimitiveSerializer<CreateOfferDto> {
  @override
  final Iterable<Type> types = const [CreateOfferDto, _$CreateOfferDto];

  @override
  final String wireName = r'CreateOfferDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateOfferDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'productId';
    yield serializers.serialize(
      object.productId,
      specifiedType: const FullType(String),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
    yield r'originalPrice';
    yield serializers.serialize(
      object.originalPrice,
      specifiedType: const FullType(num),
    );
    yield r'offerPrice';
    yield serializers.serialize(
      object.offerPrice,
      specifiedType: const FullType(num),
    );
    if (object.sortOrder != null) {
      yield r'sortOrder';
      yield serializers.serialize(
        object.sortOrder,
        specifiedType: const FullType(num),
      );
    }
    if (object.startDate != null) {
      yield r'startDate';
      yield serializers.serialize(
        object.startDate,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.endDate != null) {
      yield r'endDate';
      yield serializers.serialize(
        object.endDate,
        specifiedType: const FullType(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateOfferDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateOfferDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'productId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.productId = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'originalPrice':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.originalPrice = valueDes;
          break;
        case r'offerPrice':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.offerPrice = valueDes;
          break;
        case r'sortOrder':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.sortOrder = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateOfferDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateOfferDtoBuilder();
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

