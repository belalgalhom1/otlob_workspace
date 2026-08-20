//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_review_dto.g.dart';

/// CreateReviewDto
///
/// Properties:
/// * [vendorRating] - Rating out of 5
/// * [driverRating] - Rating out of 5
/// * [comment] 
@BuiltValue()
abstract class CreateReviewDto implements Built<CreateReviewDto, CreateReviewDtoBuilder> {
  /// Rating out of 5
  @BuiltValueField(wireName: r'vendorRating')
  num? get vendorRating;

  /// Rating out of 5
  @BuiltValueField(wireName: r'driverRating')
  num? get driverRating;

  @BuiltValueField(wireName: r'comment')
  String? get comment;

  CreateReviewDto._();

  factory CreateReviewDto([void updates(CreateReviewDtoBuilder b)]) = _$CreateReviewDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateReviewDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateReviewDto> get serializer => _$CreateReviewDtoSerializer();
}

class _$CreateReviewDtoSerializer implements PrimitiveSerializer<CreateReviewDto> {
  @override
  final Iterable<Type> types = const [CreateReviewDto, _$CreateReviewDto];

  @override
  final String wireName = r'CreateReviewDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateReviewDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateReviewDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateReviewDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
  CreateReviewDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateReviewDtoBuilder();
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

