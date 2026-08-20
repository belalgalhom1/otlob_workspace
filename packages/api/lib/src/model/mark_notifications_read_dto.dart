//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mark_notifications_read_dto.g.dart';

/// MarkNotificationsReadDto
///
/// Properties:
/// * [ids] 
@BuiltValue()
abstract class MarkNotificationsReadDto implements Built<MarkNotificationsReadDto, MarkNotificationsReadDtoBuilder> {
  @BuiltValueField(wireName: r'ids')
  BuiltList<String>? get ids;

  MarkNotificationsReadDto._();

  factory MarkNotificationsReadDto([void updates(MarkNotificationsReadDtoBuilder b)]) = _$MarkNotificationsReadDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MarkNotificationsReadDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MarkNotificationsReadDto> get serializer => _$MarkNotificationsReadDtoSerializer();
}

class _$MarkNotificationsReadDtoSerializer implements PrimitiveSerializer<MarkNotificationsReadDto> {
  @override
  final Iterable<Type> types = const [MarkNotificationsReadDto, _$MarkNotificationsReadDto];

  @override
  final String wireName = r'MarkNotificationsReadDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MarkNotificationsReadDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.ids != null) {
      yield r'ids';
      yield serializers.serialize(
        object.ids,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MarkNotificationsReadDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MarkNotificationsReadDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.ids.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MarkNotificationsReadDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MarkNotificationsReadDtoBuilder();
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

