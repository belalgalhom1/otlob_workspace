//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/order_item_update_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'edit_order_items_dto.g.dart';

/// EditOrderItemsDto
///
/// Properties:
/// * [items] 
@BuiltValue()
abstract class EditOrderItemsDto implements Built<EditOrderItemsDto, EditOrderItemsDtoBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<OrderItemUpdateDto> get items;

  EditOrderItemsDto._();

  factory EditOrderItemsDto([void updates(EditOrderItemsDtoBuilder b)]) = _$EditOrderItemsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EditOrderItemsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EditOrderItemsDto> get serializer => _$EditOrderItemsDtoSerializer();
}

class _$EditOrderItemsDtoSerializer implements PrimitiveSerializer<EditOrderItemsDto> {
  @override
  final Iterable<Type> types = const [EditOrderItemsDto, _$EditOrderItemsDto];

  @override
  final String wireName = r'EditOrderItemsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EditOrderItemsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(OrderItemUpdateDto)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EditOrderItemsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EditOrderItemsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderItemUpdateDto)]),
          ) as BuiltList<OrderItemUpdateDto>;
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
  EditOrderItemsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EditOrderItemsDtoBuilder();
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

