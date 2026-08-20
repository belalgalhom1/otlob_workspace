//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_offer_dto.g.dart';

/// UpdateOfferDto
///
/// Properties:
/// * [originalPrice] 
/// * [offerPrice] 
/// * [isActive] 
/// * [sortOrder] 
/// * [startDate] 
/// * [endDate] 
@BuiltValue()
abstract class UpdateOfferDto implements Built<UpdateOfferDto, UpdateOfferDtoBuilder> {
  @BuiltValueField(wireName: r'originalPrice')
  num? get originalPrice;

  @BuiltValueField(wireName: r'offerPrice')
  num? get offerPrice;

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  @BuiltValueField(wireName: r'sortOrder')
  num? get sortOrder;

  @BuiltValueField(wireName: r'startDate')
  DateTime? get startDate;

  @BuiltValueField(wireName: r'endDate')
  DateTime? get endDate;

  UpdateOfferDto._();

  factory UpdateOfferDto([void updates(UpdateOfferDtoBuilder b)]) = _$UpdateOfferDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateOfferDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateOfferDto> get serializer => _$UpdateOfferDtoSerializer();
}

class _$UpdateOfferDtoSerializer implements PrimitiveSerializer<UpdateOfferDto> {
  @override
  final Iterable<Type> types = const [UpdateOfferDto, _$UpdateOfferDto];

  @override
  final String wireName = r'UpdateOfferDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateOfferDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.originalPrice != null) {
      yield r'originalPrice';
      yield serializers.serialize(
        object.originalPrice,
        specifiedType: const FullType(num),
      );
    }
    if (object.offerPrice != null) {
      yield r'offerPrice';
      yield serializers.serialize(
        object.offerPrice,
        specifiedType: const FullType(num),
      );
    }
    if (object.isActive != null) {
      yield r'isActive';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
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
    UpdateOfferDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateOfferDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
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
  UpdateOfferDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateOfferDtoBuilder();
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

