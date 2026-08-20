//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/review_customer_user_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_customer_dto.g.dart';

/// ReviewCustomerDto
///
/// Properties:
/// * [user] 
@BuiltValue()
abstract class ReviewCustomerDto implements Built<ReviewCustomerDto, ReviewCustomerDtoBuilder> {
  @BuiltValueField(wireName: r'user')
  ReviewCustomerUserDto get user;

  ReviewCustomerDto._();

  factory ReviewCustomerDto([void updates(ReviewCustomerDtoBuilder b)]) = _$ReviewCustomerDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReviewCustomerDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReviewCustomerDto> get serializer => _$ReviewCustomerDtoSerializer();
}

class _$ReviewCustomerDtoSerializer implements PrimitiveSerializer<ReviewCustomerDto> {
  @override
  final Iterable<Type> types = const [ReviewCustomerDto, _$ReviewCustomerDto];

  @override
  final String wireName = r'ReviewCustomerDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReviewCustomerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(ReviewCustomerUserDto),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReviewCustomerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReviewCustomerDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ReviewCustomerUserDto),
          ) as ReviewCustomerUserDto;
          result.user.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReviewCustomerDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReviewCustomerDtoBuilder();
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

