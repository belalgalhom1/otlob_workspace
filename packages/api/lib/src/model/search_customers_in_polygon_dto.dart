//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'search_customers_in_polygon_dto.g.dart';

/// SearchCustomersInPolygonDto
///
/// Properties:
/// * [polygon] - GeoJSON Polygon coordinates: array of linear rings (arrays of [lng, lat])
@BuiltValue()
abstract class SearchCustomersInPolygonDto implements Built<SearchCustomersInPolygonDto, SearchCustomersInPolygonDtoBuilder> {
  /// GeoJSON Polygon coordinates: array of linear rings (arrays of [lng, lat])
  @BuiltValueField(wireName: r'polygon')
  BuiltList<String> get polygon;

  SearchCustomersInPolygonDto._();

  factory SearchCustomersInPolygonDto([void updates(SearchCustomersInPolygonDtoBuilder b)]) = _$SearchCustomersInPolygonDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SearchCustomersInPolygonDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SearchCustomersInPolygonDto> get serializer => _$SearchCustomersInPolygonDtoSerializer();
}

class _$SearchCustomersInPolygonDtoSerializer implements PrimitiveSerializer<SearchCustomersInPolygonDto> {
  @override
  final Iterable<Type> types = const [SearchCustomersInPolygonDto, _$SearchCustomersInPolygonDto];

  @override
  final String wireName = r'SearchCustomersInPolygonDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SearchCustomersInPolygonDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'polygon';
    yield serializers.serialize(
      object.polygon,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SearchCustomersInPolygonDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SearchCustomersInPolygonDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'polygon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.polygon.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SearchCustomersInPolygonDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SearchCustomersInPolygonDtoBuilder();
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

