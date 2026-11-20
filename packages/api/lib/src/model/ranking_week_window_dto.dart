//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ranking_week_window_dto.g.dart';

/// RankingWeekWindowDto
///
/// Properties:
/// * [periodKey] 
/// * [periodStart] 
/// * [periodEnd] 
@BuiltValue()
abstract class RankingWeekWindowDto implements Built<RankingWeekWindowDto, RankingWeekWindowDtoBuilder> {
  @BuiltValueField(wireName: r'periodKey')
  String get periodKey;

  @BuiltValueField(wireName: r'periodStart')
  DateTime get periodStart;

  @BuiltValueField(wireName: r'periodEnd')
  DateTime get periodEnd;

  RankingWeekWindowDto._();

  factory RankingWeekWindowDto([void updates(RankingWeekWindowDtoBuilder b)]) = _$RankingWeekWindowDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RankingWeekWindowDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RankingWeekWindowDto> get serializer => _$RankingWeekWindowDtoSerializer();
}

class _$RankingWeekWindowDtoSerializer implements PrimitiveSerializer<RankingWeekWindowDto> {
  @override
  final Iterable<Type> types = const [RankingWeekWindowDto, _$RankingWeekWindowDto];

  @override
  final String wireName = r'RankingWeekWindowDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RankingWeekWindowDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'periodKey';
    yield serializers.serialize(
      object.periodKey,
      specifiedType: const FullType(String),
    );
    yield r'periodStart';
    yield serializers.serialize(
      object.periodStart,
      specifiedType: const FullType(DateTime),
    );
    yield r'periodEnd';
    yield serializers.serialize(
      object.periodEnd,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RankingWeekWindowDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RankingWeekWindowDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'periodKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.periodKey = valueDes;
          break;
        case r'periodStart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.periodStart = valueDes;
          break;
        case r'periodEnd':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.periodEnd = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RankingWeekWindowDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RankingWeekWindowDtoBuilder();
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

