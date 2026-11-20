//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cancel_order_dto.g.dart';

/// CancelOrderDto
///
/// Properties:
/// * [reason] - Optional reason for cancelling the order
@BuiltValue()
abstract class CancelOrderDto implements Built<CancelOrderDto, CancelOrderDtoBuilder> {
  /// Optional reason for cancelling the order
  @BuiltValueField(wireName: r'reason')
  String? get reason;

  CancelOrderDto._();

  factory CancelOrderDto([void updates(CancelOrderDtoBuilder b)]) = _$CancelOrderDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CancelOrderDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CancelOrderDto> get serializer => _$CancelOrderDtoSerializer();
}

class _$CancelOrderDtoSerializer implements PrimitiveSerializer<CancelOrderDto> {
  @override
  final Iterable<Type> types = const [CancelOrderDto, _$CancelOrderDto];

  @override
  final String wireName = r'CancelOrderDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CancelOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CancelOrderDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CancelOrderDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CancelOrderDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CancelOrderDtoBuilder();
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

