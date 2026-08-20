//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mark_read_dto.g.dart';

/// MarkReadDto
///
/// Properties:
/// * [lastReadMessageId] 
@BuiltValue()
abstract class MarkReadDto implements Built<MarkReadDto, MarkReadDtoBuilder> {
  @BuiltValueField(wireName: r'lastReadMessageId')
  String? get lastReadMessageId;

  MarkReadDto._();

  factory MarkReadDto([void updates(MarkReadDtoBuilder b)]) = _$MarkReadDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MarkReadDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MarkReadDto> get serializer => _$MarkReadDtoSerializer();
}

class _$MarkReadDtoSerializer implements PrimitiveSerializer<MarkReadDto> {
  @override
  final Iterable<Type> types = const [MarkReadDto, _$MarkReadDto];

  @override
  final String wireName = r'MarkReadDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MarkReadDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.lastReadMessageId != null) {
      yield r'lastReadMessageId';
      yield serializers.serialize(
        object.lastReadMessageId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MarkReadDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MarkReadDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'lastReadMessageId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.lastReadMessageId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MarkReadDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MarkReadDtoBuilder();
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

