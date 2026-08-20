//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_item_update_dto.g.dart';

/// OrderItemUpdateDto
///
/// Properties:
/// * [productId] 
/// * [variantId] 
/// * [quantity] 
/// * [optionIds] 
/// * [specialRequest] 
@BuiltValue()
abstract class OrderItemUpdateDto implements Built<OrderItemUpdateDto, OrderItemUpdateDtoBuilder> {
  @BuiltValueField(wireName: r'productId')
  String get productId;

  @BuiltValueField(wireName: r'variantId')
  String? get variantId;

  @BuiltValueField(wireName: r'quantity')
  num get quantity;

  @BuiltValueField(wireName: r'optionIds')
  BuiltList<String>? get optionIds;

  @BuiltValueField(wireName: r'specialRequest')
  String? get specialRequest;

  OrderItemUpdateDto._();

  factory OrderItemUpdateDto([void updates(OrderItemUpdateDtoBuilder b)]) = _$OrderItemUpdateDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderItemUpdateDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderItemUpdateDto> get serializer => _$OrderItemUpdateDtoSerializer();
}

class _$OrderItemUpdateDtoSerializer implements PrimitiveSerializer<OrderItemUpdateDto> {
  @override
  final Iterable<Type> types = const [OrderItemUpdateDto, _$OrderItemUpdateDto];

  @override
  final String wireName = r'OrderItemUpdateDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderItemUpdateDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'productId';
    yield serializers.serialize(
      object.productId,
      specifiedType: const FullType(String),
    );
    if (object.variantId != null) {
      yield r'variantId';
      yield serializers.serialize(
        object.variantId,
        specifiedType: const FullType(String),
      );
    }
    yield r'quantity';
    yield serializers.serialize(
      object.quantity,
      specifiedType: const FullType(num),
    );
    if (object.optionIds != null) {
      yield r'optionIds';
      yield serializers.serialize(
        object.optionIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
    if (object.specialRequest != null) {
      yield r'specialRequest';
      yield serializers.serialize(
        object.specialRequest,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderItemUpdateDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderItemUpdateDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'productId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.productId = valueDes;
          break;
        case r'variantId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.variantId = valueDes;
          break;
        case r'quantity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.quantity = valueDes;
          break;
        case r'optionIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.optionIds.replace(valueDes);
          break;
        case r'specialRequest':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.specialRequest = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderItemUpdateDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderItemUpdateDtoBuilder();
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

