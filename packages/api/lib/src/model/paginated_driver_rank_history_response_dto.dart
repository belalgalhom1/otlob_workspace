//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_rank_history_entry_dto.dart';
import 'package:api/src/model/driver_ranking_pagination_meta_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'paginated_driver_rank_history_response_dto.g.dart';

/// PaginatedDriverRankHistoryResponseDto
///
/// Properties:
/// * [data] 
/// * [meta] 
@BuiltValue()
abstract class PaginatedDriverRankHistoryResponseDto implements Built<PaginatedDriverRankHistoryResponseDto, PaginatedDriverRankHistoryResponseDtoBuilder> {
  @BuiltValueField(wireName: r'data')
  BuiltList<DriverRankHistoryEntryDto> get data;

  @BuiltValueField(wireName: r'meta')
  DriverRankingPaginationMetaDto get meta;

  PaginatedDriverRankHistoryResponseDto._();

  factory PaginatedDriverRankHistoryResponseDto([void updates(PaginatedDriverRankHistoryResponseDtoBuilder b)]) = _$PaginatedDriverRankHistoryResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaginatedDriverRankHistoryResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaginatedDriverRankHistoryResponseDto> get serializer => _$PaginatedDriverRankHistoryResponseDtoSerializer();
}

class _$PaginatedDriverRankHistoryResponseDtoSerializer implements PrimitiveSerializer<PaginatedDriverRankHistoryResponseDto> {
  @override
  final Iterable<Type> types = const [PaginatedDriverRankHistoryResponseDto, _$PaginatedDriverRankHistoryResponseDto];

  @override
  final String wireName = r'PaginatedDriverRankHistoryResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaginatedDriverRankHistoryResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'data';
    yield serializers.serialize(
      object.data,
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
    PaginatedDriverRankHistoryResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaginatedDriverRankHistoryResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverRankHistoryEntryDto)]),
          ) as BuiltList<DriverRankHistoryEntryDto>;
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
  PaginatedDriverRankHistoryResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaginatedDriverRankHistoryResponseDtoBuilder();
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

