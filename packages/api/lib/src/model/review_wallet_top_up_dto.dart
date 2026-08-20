//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'review_wallet_top_up_dto.g.dart';

/// ReviewWalletTopUpDto
///
/// Properties:
/// * [status] 
@BuiltValue()
abstract class ReviewWalletTopUpDto implements Built<ReviewWalletTopUpDto, ReviewWalletTopUpDtoBuilder> {
  @BuiltValueField(wireName: r'status')
  String get status;

  ReviewWalletTopUpDto._();

  factory ReviewWalletTopUpDto([void updates(ReviewWalletTopUpDtoBuilder b)]) = _$ReviewWalletTopUpDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReviewWalletTopUpDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReviewWalletTopUpDto> get serializer => _$ReviewWalletTopUpDtoSerializer();
}

class _$ReviewWalletTopUpDtoSerializer implements PrimitiveSerializer<ReviewWalletTopUpDto> {
  @override
  final Iterable<Type> types = const [ReviewWalletTopUpDto, _$ReviewWalletTopUpDto];

  @override
  final String wireName = r'ReviewWalletTopUpDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReviewWalletTopUpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReviewWalletTopUpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReviewWalletTopUpDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReviewWalletTopUpDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReviewWalletTopUpDtoBuilder();
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

