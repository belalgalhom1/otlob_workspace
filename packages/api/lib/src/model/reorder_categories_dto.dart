//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reorder_categories_dto.g.dart';

/// ReorderCategoriesDto
///
/// Properties:
/// * [items] 
@BuiltValue()
abstract class ReorderCategoriesDto implements Built<ReorderCategoriesDto, ReorderCategoriesDtoBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<String> get items;

  ReorderCategoriesDto._();

  factory ReorderCategoriesDto([void updates(ReorderCategoriesDtoBuilder b)]) = _$ReorderCategoriesDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReorderCategoriesDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReorderCategoriesDto> get serializer => _$ReorderCategoriesDtoSerializer();
}

class _$ReorderCategoriesDtoSerializer implements PrimitiveSerializer<ReorderCategoriesDto> {
  @override
  final Iterable<Type> types = const [ReorderCategoriesDto, _$ReorderCategoriesDto];

  @override
  final String wireName = r'ReorderCategoriesDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReorderCategoriesDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ReorderCategoriesDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReorderCategoriesDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ReorderCategoriesDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReorderCategoriesDtoBuilder();
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

