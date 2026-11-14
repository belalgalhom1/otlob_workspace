//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'respond_assist_offer_dto.g.dart';

/// RespondAssistOfferDto
///
/// Properties:
/// * [accept] - True to accept the assist offer, false to decline
@BuiltValue()
abstract class RespondAssistOfferDto implements Built<RespondAssistOfferDto, RespondAssistOfferDtoBuilder> {
  /// True to accept the assist offer, false to decline
  @BuiltValueField(wireName: r'accept')
  bool get accept;

  RespondAssistOfferDto._();

  factory RespondAssistOfferDto([void updates(RespondAssistOfferDtoBuilder b)]) = _$RespondAssistOfferDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RespondAssistOfferDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RespondAssistOfferDto> get serializer => _$RespondAssistOfferDtoSerializer();
}

class _$RespondAssistOfferDtoSerializer implements PrimitiveSerializer<RespondAssistOfferDto> {
  @override
  final Iterable<Type> types = const [RespondAssistOfferDto, _$RespondAssistOfferDto];

  @override
  final String wireName = r'RespondAssistOfferDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RespondAssistOfferDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'accept';
    yield serializers.serialize(
      object.accept,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RespondAssistOfferDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RespondAssistOfferDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'accept':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.accept = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RespondAssistOfferDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RespondAssistOfferDtoBuilder();
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

