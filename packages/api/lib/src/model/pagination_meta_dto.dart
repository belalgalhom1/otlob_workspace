//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pagination_meta_dto.g.dart';

/// PaginationMetaDto
///
/// Properties:
/// * [total] 
/// * [page] 
/// * [limit] 
/// * [totalPages] 
@BuiltValue()
abstract class PaginationMetaDto implements Built<PaginationMetaDto, PaginationMetaDtoBuilder> {
  @BuiltValueField(wireName: r'total')
  num get total;

  @BuiltValueField(wireName: r'page')
  num get page;

  @BuiltValueField(wireName: r'limit')
  num get limit;

  @BuiltValueField(wireName: r'totalPages')
  num get totalPages;

  PaginationMetaDto._();

  factory PaginationMetaDto([void updates(PaginationMetaDtoBuilder b)]) = _$PaginationMetaDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaginationMetaDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaginationMetaDto> get serializer => _$PaginationMetaDtoSerializer();
}

class _$PaginationMetaDtoSerializer implements PrimitiveSerializer<PaginationMetaDto> {
  @override
  final Iterable<Type> types = const [PaginationMetaDto, _$PaginationMetaDto];

  @override
  final String wireName = r'PaginationMetaDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaginationMetaDto object, {
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
    PaginationMetaDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaginationMetaDtoBuilder result,
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
  PaginationMetaDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaginationMetaDtoBuilder();
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

