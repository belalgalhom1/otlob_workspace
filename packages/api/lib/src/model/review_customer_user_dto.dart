//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_customer_user_dto.g.dart';

/// ReviewCustomerUserDto
///
/// Properties:
/// * [name] 
@BuiltValue()
abstract class ReviewCustomerUserDto implements Built<ReviewCustomerUserDto, ReviewCustomerUserDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  ReviewCustomerUserDto._();

  factory ReviewCustomerUserDto([void updates(ReviewCustomerUserDtoBuilder b)]) = _$ReviewCustomerUserDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReviewCustomerUserDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReviewCustomerUserDto> get serializer => _$ReviewCustomerUserDtoSerializer();
}

class _$ReviewCustomerUserDtoSerializer implements PrimitiveSerializer<ReviewCustomerUserDto> {
  @override
  final Iterable<Type> types = const [ReviewCustomerUserDto, _$ReviewCustomerUserDto];

  @override
  final String wireName = r'ReviewCustomerUserDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReviewCustomerUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReviewCustomerUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReviewCustomerUserDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReviewCustomerUserDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReviewCustomerUserDtoBuilder();
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

