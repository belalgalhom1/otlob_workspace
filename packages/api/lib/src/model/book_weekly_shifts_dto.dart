//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'book_weekly_shifts_dto.g.dart';

/// BookWeeklyShiftsDto
///
/// Properties:
/// * [shiftPoolIds] 
@BuiltValue()
abstract class BookWeeklyShiftsDto implements Built<BookWeeklyShiftsDto, BookWeeklyShiftsDtoBuilder> {
  @BuiltValueField(wireName: r'shiftPoolIds')
  BuiltList<String> get shiftPoolIds;

  BookWeeklyShiftsDto._();

  factory BookWeeklyShiftsDto([void updates(BookWeeklyShiftsDtoBuilder b)]) = _$BookWeeklyShiftsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BookWeeklyShiftsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BookWeeklyShiftsDto> get serializer => _$BookWeeklyShiftsDtoSerializer();
}

class _$BookWeeklyShiftsDtoSerializer implements PrimitiveSerializer<BookWeeklyShiftsDto> {
  @override
  final Iterable<Type> types = const [BookWeeklyShiftsDto, _$BookWeeklyShiftsDto];

  @override
  final String wireName = r'BookWeeklyShiftsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BookWeeklyShiftsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'shiftPoolIds';
    yield serializers.serialize(
      object.shiftPoolIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BookWeeklyShiftsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BookWeeklyShiftsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'shiftPoolIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.shiftPoolIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BookWeeklyShiftsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BookWeeklyShiftsDtoBuilder();
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

