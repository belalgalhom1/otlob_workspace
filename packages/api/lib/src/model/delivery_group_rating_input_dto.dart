//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delivery_group_rating_input_dto.g.dart';

/// DeliveryGroupRatingInputDto
///
/// Properties:
/// * [deliveryGroupId] 
/// * [rating] 
/// * [comment] 
@BuiltValue()
abstract class DeliveryGroupRatingInputDto implements Built<DeliveryGroupRatingInputDto, DeliveryGroupRatingInputDtoBuilder> {
  @BuiltValueField(wireName: r'deliveryGroupId')
  String get deliveryGroupId;

  @BuiltValueField(wireName: r'rating')
  num get rating;

  @BuiltValueField(wireName: r'comment')
  String? get comment;

  DeliveryGroupRatingInputDto._();

  factory DeliveryGroupRatingInputDto([void updates(DeliveryGroupRatingInputDtoBuilder b)]) = _$DeliveryGroupRatingInputDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeliveryGroupRatingInputDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeliveryGroupRatingInputDto> get serializer => _$DeliveryGroupRatingInputDtoSerializer();
}

class _$DeliveryGroupRatingInputDtoSerializer implements PrimitiveSerializer<DeliveryGroupRatingInputDto> {
  @override
  final Iterable<Type> types = const [DeliveryGroupRatingInputDto, _$DeliveryGroupRatingInputDto];

  @override
  final String wireName = r'DeliveryGroupRatingInputDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeliveryGroupRatingInputDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'deliveryGroupId';
    yield serializers.serialize(
      object.deliveryGroupId,
      specifiedType: const FullType(String),
    );
    yield r'rating';
    yield serializers.serialize(
      object.rating,
      specifiedType: const FullType(num),
    );
    if (object.comment != null) {
      yield r'comment';
      yield serializers.serialize(
        object.comment,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DeliveryGroupRatingInputDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeliveryGroupRatingInputDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'deliveryGroupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryGroupId = valueDes;
          break;
        case r'rating':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.rating = valueDes;
          break;
        case r'comment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.comment = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeliveryGroupRatingInputDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeliveryGroupRatingInputDtoBuilder();
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

