//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'book_overtime_shift_dto.g.dart';

/// BookOvertimeShiftDto
///
/// Properties:
/// * [shiftPoolId] 
@BuiltValue()
abstract class BookOvertimeShiftDto implements Built<BookOvertimeShiftDto, BookOvertimeShiftDtoBuilder> {
  @BuiltValueField(wireName: r'shiftPoolId')
  String get shiftPoolId;

  BookOvertimeShiftDto._();

  factory BookOvertimeShiftDto([void updates(BookOvertimeShiftDtoBuilder b)]) = _$BookOvertimeShiftDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BookOvertimeShiftDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BookOvertimeShiftDto> get serializer => _$BookOvertimeShiftDtoSerializer();
}

class _$BookOvertimeShiftDtoSerializer implements PrimitiveSerializer<BookOvertimeShiftDto> {
  @override
  final Iterable<Type> types = const [BookOvertimeShiftDto, _$BookOvertimeShiftDto];

  @override
  final String wireName = r'BookOvertimeShiftDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BookOvertimeShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'shiftPoolId';
    yield serializers.serialize(
      object.shiftPoolId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BookOvertimeShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BookOvertimeShiftDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'shiftPoolId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shiftPoolId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BookOvertimeShiftDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BookOvertimeShiftDtoBuilder();
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

