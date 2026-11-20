//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_ranking_evaluation_run_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_rank_history_entry_dto.dart';
import 'package:api/src/model/driver_ranking_pagination_meta_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_run_details_response_dto.g.dart';

/// DriverRankingRunDetailsResponseDto
///
/// Properties:
/// * [run] 
/// * [entries] 
/// * [meta] 
@BuiltValue()
abstract class DriverRankingRunDetailsResponseDto implements Built<DriverRankingRunDetailsResponseDto, DriverRankingRunDetailsResponseDtoBuilder> {
  @BuiltValueField(wireName: r'run')
  DriverRankingEvaluationRunDto get run;

  @BuiltValueField(wireName: r'entries')
  BuiltList<DriverRankHistoryEntryDto> get entries;

  @BuiltValueField(wireName: r'meta')
  DriverRankingPaginationMetaDto get meta;

  DriverRankingRunDetailsResponseDto._();

  factory DriverRankingRunDetailsResponseDto([void updates(DriverRankingRunDetailsResponseDtoBuilder b)]) = _$DriverRankingRunDetailsResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankingRunDetailsResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankingRunDetailsResponseDto> get serializer => _$DriverRankingRunDetailsResponseDtoSerializer();
}

class _$DriverRankingRunDetailsResponseDtoSerializer implements PrimitiveSerializer<DriverRankingRunDetailsResponseDto> {
  @override
  final Iterable<Type> types = const [DriverRankingRunDetailsResponseDto, _$DriverRankingRunDetailsResponseDto];

  @override
  final String wireName = r'DriverRankingRunDetailsResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankingRunDetailsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'run';
    yield serializers.serialize(
      object.run,
      specifiedType: const FullType(DriverRankingEvaluationRunDto),
    );
    yield r'entries';
    yield serializers.serialize(
      object.entries,
      specifiedType: const FullType(BuiltList, [FullType(DriverRankHistoryEntryDto)]),
    );
    yield r'meta';
    yield serializers.serialize(
      object.meta,
      specifiedType: const FullType(DriverRankingPaginationMetaDto),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingRunDetailsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankingRunDetailsResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'run':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverRankingEvaluationRunDto),
          ) as DriverRankingEvaluationRunDto;
          result.run.replace(valueDes);
          break;
        case r'entries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverRankHistoryEntryDto)]),
          ) as BuiltList<DriverRankHistoryEntryDto>;
          result.entries.replace(valueDes);
          break;
        case r'meta':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverRankingPaginationMetaDto),
          ) as DriverRankingPaginationMetaDto;
          result.meta.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverRankingRunDetailsResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankingRunDetailsResponseDtoBuilder();
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

