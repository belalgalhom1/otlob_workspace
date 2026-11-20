//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_ranking_evaluation_run_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_ranking_pagination_meta_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'paginated_ranking_runs_response_dto.g.dart';

/// PaginatedRankingRunsResponseDto
///
/// Properties:
/// * [data] 
/// * [meta] 
@BuiltValue()
abstract class PaginatedRankingRunsResponseDto implements Built<PaginatedRankingRunsResponseDto, PaginatedRankingRunsResponseDtoBuilder> {
  @BuiltValueField(wireName: r'data')
  BuiltList<DriverRankingEvaluationRunDto> get data;

  @BuiltValueField(wireName: r'meta')
  DriverRankingPaginationMetaDto get meta;

  PaginatedRankingRunsResponseDto._();

  factory PaginatedRankingRunsResponseDto([void updates(PaginatedRankingRunsResponseDtoBuilder b)]) = _$PaginatedRankingRunsResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaginatedRankingRunsResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaginatedRankingRunsResponseDto> get serializer => _$PaginatedRankingRunsResponseDtoSerializer();
}

class _$PaginatedRankingRunsResponseDtoSerializer implements PrimitiveSerializer<PaginatedRankingRunsResponseDto> {
  @override
  final Iterable<Type> types = const [PaginatedRankingRunsResponseDto, _$PaginatedRankingRunsResponseDto];

  @override
  final String wireName = r'PaginatedRankingRunsResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaginatedRankingRunsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'data';
    yield serializers.serialize(
      object.data,
      specifiedType: const FullType(BuiltList, [FullType(DriverRankingEvaluationRunDto)]),
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
    PaginatedRankingRunsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaginatedRankingRunsResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverRankingEvaluationRunDto)]),
          ) as BuiltList<DriverRankingEvaluationRunDto>;
          result.data.replace(valueDes);
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
  PaginatedRankingRunsResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaginatedRankingRunsResponseDtoBuilder();
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

