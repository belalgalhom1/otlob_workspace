//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'confirm_payment_dto.g.dart';

/// ConfirmPaymentDto
///
/// Properties:
/// * [received] 
@BuiltValue()
abstract class ConfirmPaymentDto implements Built<ConfirmPaymentDto, ConfirmPaymentDtoBuilder> {
  @BuiltValueField(wireName: r'received')
  bool get received;

  ConfirmPaymentDto._();

  factory ConfirmPaymentDto([void updates(ConfirmPaymentDtoBuilder b)]) = _$ConfirmPaymentDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConfirmPaymentDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConfirmPaymentDto> get serializer => _$ConfirmPaymentDtoSerializer();
}

class _$ConfirmPaymentDtoSerializer implements PrimitiveSerializer<ConfirmPaymentDto> {
  @override
  final Iterable<Type> types = const [ConfirmPaymentDto, _$ConfirmPaymentDto];

  @override
  final String wireName = r'ConfirmPaymentDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConfirmPaymentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'received';
    yield serializers.serialize(
      object.received,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConfirmPaymentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConfirmPaymentDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'received':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.received = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConfirmPaymentDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConfirmPaymentDtoBuilder();
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

