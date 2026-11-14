//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fulfillment_rating_input_dto.g.dart';

/// FulfillmentRatingInputDto
///
/// Properties:
/// * [fulfillmentId] 
/// * [rating] 
/// * [comment] 
@BuiltValue()
abstract class FulfillmentRatingInputDto implements Built<FulfillmentRatingInputDto, FulfillmentRatingInputDtoBuilder> {
  @BuiltValueField(wireName: r'fulfillmentId')
  String get fulfillmentId;

  @BuiltValueField(wireName: r'rating')
  num get rating;

  @BuiltValueField(wireName: r'comment')
  String? get comment;

  FulfillmentRatingInputDto._();

  factory FulfillmentRatingInputDto([void updates(FulfillmentRatingInputDtoBuilder b)]) = _$FulfillmentRatingInputDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FulfillmentRatingInputDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FulfillmentRatingInputDto> get serializer => _$FulfillmentRatingInputDtoSerializer();
}

class _$FulfillmentRatingInputDtoSerializer implements PrimitiveSerializer<FulfillmentRatingInputDto> {
  @override
  final Iterable<Type> types = const [FulfillmentRatingInputDto, _$FulfillmentRatingInputDto];

  @override
  final String wireName = r'FulfillmentRatingInputDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FulfillmentRatingInputDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'fulfillmentId';
    yield serializers.serialize(
      object.fulfillmentId,
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
    FulfillmentRatingInputDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FulfillmentRatingInputDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fulfillmentId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fulfillmentId = valueDes;
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
  FulfillmentRatingInputDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FulfillmentRatingInputDtoBuilder();
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

