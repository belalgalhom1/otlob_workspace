//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'add_cart_item_dto.g.dart';

/// AddCartItemDto
///
/// Properties:
/// * [productId] 
/// * [variantId] 
/// * [quantity] 
/// * [optionIds] - Selected option IDs
/// * [specialRequest] 
/// * [selectedUnit] 
/// * [offerMessageId] 
@BuiltValue()
abstract class AddCartItemDto implements Built<AddCartItemDto, AddCartItemDtoBuilder> {
  @BuiltValueField(wireName: r'productId')
  String? get productId;

  @BuiltValueField(wireName: r'variantId')
  String? get variantId;

  @BuiltValueField(wireName: r'quantity')
  num get quantity;

  /// Selected option IDs
  @BuiltValueField(wireName: r'optionIds')
  BuiltList<String>? get optionIds;

  @BuiltValueField(wireName: r'specialRequest')
  String? get specialRequest;

  @BuiltValueField(wireName: r'selectedUnit')
  String? get selectedUnit;

  @BuiltValueField(wireName: r'offerMessageId')
  String? get offerMessageId;

  AddCartItemDto._();

  factory AddCartItemDto([void updates(AddCartItemDtoBuilder b)]) = _$AddCartItemDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AddCartItemDtoBuilder b) => b
      ..quantity = 1
      ..selectedUnit = 'package';

  @BuiltValueSerializer(custom: true)
  static Serializer<AddCartItemDto> get serializer => _$AddCartItemDtoSerializer();
}

class _$AddCartItemDtoSerializer implements PrimitiveSerializer<AddCartItemDto> {
  @override
  final Iterable<Type> types = const [AddCartItemDto, _$AddCartItemDto];

  @override
  final String wireName = r'AddCartItemDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AddCartItemDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.productId != null) {
      yield r'productId';
      yield serializers.serialize(
        object.productId,
        specifiedType: const FullType(String),
      );
    }
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
    if (object.selectedUnit != null) {
      yield r'selectedUnit';
      yield serializers.serialize(
        object.selectedUnit,
        specifiedType: const FullType(String),
      );
    }
    if (object.offerMessageId != null) {
      yield r'offerMessageId';
      yield serializers.serialize(
        object.offerMessageId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AddCartItemDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AddCartItemDtoBuilder result,
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
        case r'selectedUnit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.selectedUnit = valueDes;
          break;
        case r'offerMessageId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offerMessageId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AddCartItemDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AddCartItemDtoBuilder();
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

