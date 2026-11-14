//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/review_customer_dto.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_dto.g.dart';

/// ReviewDto
///
/// Properties:
/// * [id] 
/// * [orderId] 
/// * [customerId] 
/// * [targetType] 
/// * [fulfillmentId] 
/// * [deliveryGroupId] 
/// * [vendorId] 
/// * [driverId] 
/// * [rating] - Rating out of 5
/// * [vendorRating] - Vendor rating out of 5
/// * [driverRating] - Driver rating out of 5
/// * [comment] 
/// * [createdAt] 
/// * [customer] 
@BuiltValue()
abstract class ReviewDto implements Built<ReviewDto, ReviewDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'customerId')
  String get customerId;

  @BuiltValueField(wireName: r'targetType')
  ReviewDtoTargetTypeEnum get targetType;
  // enum targetTypeEnum {  VENDOR_FULFILLMENT,  DELIVERY_GROUP,  };

  @BuiltValueField(wireName: r'fulfillmentId')
  JsonObject? get fulfillmentId;

  @BuiltValueField(wireName: r'deliveryGroupId')
  JsonObject? get deliveryGroupId;

  @BuiltValueField(wireName: r'vendorId')
  JsonObject? get vendorId;

  @BuiltValueField(wireName: r'driverId')
  JsonObject? get driverId;

  /// Rating out of 5
  @BuiltValueField(wireName: r'rating')
  num get rating;

  /// Vendor rating out of 5
  @BuiltValueField(wireName: r'vendorRating')
  num? get vendorRating;

  /// Driver rating out of 5
  @BuiltValueField(wireName: r'driverRating')
  num? get driverRating;

  @BuiltValueField(wireName: r'comment')
  JsonObject? get comment;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'customer')
  ReviewCustomerDto? get customer;

  ReviewDto._();

  factory ReviewDto([void updates(ReviewDtoBuilder b)]) = _$ReviewDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReviewDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReviewDto> get serializer => _$ReviewDtoSerializer();
}

class _$ReviewDtoSerializer implements PrimitiveSerializer<ReviewDto> {
  @override
  final Iterable<Type> types = const [ReviewDto, _$ReviewDto];

  @override
  final String wireName = r'ReviewDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReviewDto object, {
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
    yield r'customerId';
    yield serializers.serialize(
      object.customerId,
      specifiedType: const FullType(String),
    );
    yield r'targetType';
    yield serializers.serialize(
      object.targetType,
      specifiedType: const FullType(ReviewDtoTargetTypeEnum),
    );
    if (object.fulfillmentId != null) {
      yield r'fulfillmentId';
      yield serializers.serialize(
        object.fulfillmentId,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.deliveryGroupId != null) {
      yield r'deliveryGroupId';
      yield serializers.serialize(
        object.deliveryGroupId,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.driverId != null) {
      yield r'driverId';
      yield serializers.serialize(
        object.driverId,
        specifiedType: const FullType(JsonObject),
      );
    }
    yield r'rating';
    yield serializers.serialize(
      object.rating,
      specifiedType: const FullType(num),
    );
    if (object.vendorRating != null) {
      yield r'vendorRating';
      yield serializers.serialize(
        object.vendorRating,
        specifiedType: const FullType(num),
      );
    }
    if (object.driverRating != null) {
      yield r'driverRating';
      yield serializers.serialize(
        object.driverRating,
        specifiedType: const FullType(num),
      );
    }
    if (object.comment != null) {
      yield r'comment';
      yield serializers.serialize(
        object.comment,
        specifiedType: const FullType(JsonObject),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.customer != null) {
      yield r'customer';
      yield serializers.serialize(
        object.customer,
        specifiedType: const FullType(ReviewCustomerDto),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ReviewDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReviewDtoBuilder result,
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
        case r'customerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.customerId = valueDes;
          break;
        case r'targetType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReviewDtoTargetTypeEnum),
          ) as ReviewDtoTargetTypeEnum;
          result.targetType = valueDes;
          break;
        case r'fulfillmentId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.fulfillmentId = valueDes;
          break;
        case r'deliveryGroupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.deliveryGroupId = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.vendorId = valueDes;
          break;
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.driverId = valueDes;
          break;
        case r'rating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.rating = valueDes;
          break;
        case r'vendorRating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.vendorRating = valueDes;
          break;
        case r'driverRating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.driverRating = valueDes;
          break;
        case r'comment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.comment = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'customer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReviewCustomerDto),
          ) as ReviewCustomerDto;
          result.customer.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReviewDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReviewDtoBuilder();
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

class ReviewDtoTargetTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'VENDOR_FULFILLMENT')
  static const ReviewDtoTargetTypeEnum VENDOR_FULFILLMENT = _$reviewDtoTargetTypeEnum_VENDOR_FULFILLMENT;
  @BuiltValueEnumConst(wireName: r'DELIVERY_GROUP')
  static const ReviewDtoTargetTypeEnum DELIVERY_GROUP = _$reviewDtoTargetTypeEnum_DELIVERY_GROUP;

  static Serializer<ReviewDtoTargetTypeEnum> get serializer => _$reviewDtoTargetTypeEnumSerializer;

  const ReviewDtoTargetTypeEnum._(String name): super(name);

  static BuiltSet<ReviewDtoTargetTypeEnum> get values => _$reviewDtoTargetTypeEnumValues;
  static ReviewDtoTargetTypeEnum valueOf(String name) => _$reviewDtoTargetTypeEnumValueOf(name);
}

