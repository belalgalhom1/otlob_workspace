//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/order_item_option.dart';
import 'package:api/src/model/product_option_group.dart';
import 'package:api/src/model/cart_item_option.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_option_response_dto.g.dart';

/// ProductOptionResponseDto
///
/// Properties:
/// * [id] 
/// * [groupId] 
/// * [name] 
/// * [nameAr] 
/// * [priceAdded] 
/// * [isActive] 
/// * [cartItemOptions] 
/// * [orderItemOptions] 
/// * [group] 
@BuiltValue()
abstract class ProductOptionResponseDto implements Built<ProductOptionResponseDto, ProductOptionResponseDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'priceAdded')
  num get priceAdded;

  @BuiltValueField(wireName: r'isActive')
  bool get isActive;

  @BuiltValueField(wireName: r'cartItemOptions')
  BuiltList<CartItemOption>? get cartItemOptions;

  @BuiltValueField(wireName: r'orderItemOptions')
  BuiltList<OrderItemOption>? get orderItemOptions;

  @BuiltValueField(wireName: r'group')
  ProductOptionGroup? get group;

  ProductOptionResponseDto._();

  factory ProductOptionResponseDto([void updates(ProductOptionResponseDtoBuilder b)]) = _$ProductOptionResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductOptionResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductOptionResponseDto> get serializer => _$ProductOptionResponseDtoSerializer();
}

class _$ProductOptionResponseDtoSerializer implements PrimitiveSerializer<ProductOptionResponseDto> {
  @override
  final Iterable<Type> types = const [ProductOptionResponseDto, _$ProductOptionResponseDto];

  @override
  final String wireName = r'ProductOptionResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductOptionResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.nameAr != null) {
      yield r'nameAr';
      yield serializers.serialize(
        object.nameAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'priceAdded';
    yield serializers.serialize(
      object.priceAdded,
      specifiedType: const FullType(num),
    );
    yield r'isActive';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
    if (object.cartItemOptions != null) {
      yield r'cartItemOptions';
      yield serializers.serialize(
        object.cartItemOptions,
        specifiedType: const FullType(BuiltList, [FullType(CartItemOption)]),
      );
    }
    if (object.orderItemOptions != null) {
      yield r'orderItemOptions';
      yield serializers.serialize(
        object.orderItemOptions,
        specifiedType: const FullType(BuiltList, [FullType(OrderItemOption)]),
      );
    }
    if (object.group != null) {
      yield r'group';
      yield serializers.serialize(
        object.group,
        specifiedType: const FullType(ProductOptionGroup),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductOptionResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductOptionResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'groupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'nameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nameAr = valueDes;
          break;
        case r'priceAdded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.priceAdded = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'cartItemOptions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CartItemOption)]),
          ) as BuiltList<CartItemOption>;
          result.cartItemOptions.replace(valueDes);
          break;
        case r'orderItemOptions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderItemOption)]),
          ) as BuiltList<OrderItemOption>;
          result.orderItemOptions.replace(valueDes);
          break;
        case r'group':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProductOptionGroup),
          ) as ProductOptionGroup;
          result.group.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductOptionResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductOptionResponseDtoBuilder();
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

