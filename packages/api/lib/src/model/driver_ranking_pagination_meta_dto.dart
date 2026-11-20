//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_pagination_meta_dto.g.dart';

/// DriverRankingPaginationMetaDto
///
/// Properties:
/// * [total] 
/// * [page] 
/// * [limit] 
/// * [totalPages] 
@BuiltValue()
abstract class DriverRankingPaginationMetaDto implements Built<DriverRankingPaginationMetaDto, DriverRankingPaginationMetaDtoBuilder> {
  @BuiltValueField(wireName: r'total')
  num get total;

  @BuiltValueField(wireName: r'page')
  num get page;

  @BuiltValueField(wireName: r'limit')
  num get limit;

  @BuiltValueField(wireName: r'totalPages')
  num get totalPages;

  DriverRankingPaginationMetaDto._();

  factory DriverRankingPaginationMetaDto([void updates(DriverRankingPaginationMetaDtoBuilder b)]) = _$DriverRankingPaginationMetaDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankingPaginationMetaDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankingPaginationMetaDto> get serializer => _$DriverRankingPaginationMetaDtoSerializer();
}

class _$DriverRankingPaginationMetaDtoSerializer implements PrimitiveSerializer<DriverRankingPaginationMetaDto> {
  @override
  final Iterable<Type> types = const [DriverRankingPaginationMetaDto, _$DriverRankingPaginationMetaDto];

  @override
  final String wireName = r'DriverRankingPaginationMetaDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankingPaginationMetaDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(num),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(num),
    );
    yield r'limit';
    yield serializers.serialize(
      object.limit,
      specifiedType: const FullType(num),
    );
    yield r'totalPages';
    yield serializers.serialize(
      object.totalPages,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverRankingPaginationMetaDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankingPaginationMetaDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.total = valueDes;
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.page = valueDes;
          break;
        case r'limit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.limit = valueDes;
          break;
        case r'totalPages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalPages = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverRankingPaginationMetaDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankingPaginationMetaDtoBuilder();
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

