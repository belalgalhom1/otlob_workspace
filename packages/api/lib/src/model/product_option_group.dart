//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_option_group.g.dart';

/// ProductOptionGroup
///
/// Properties:
/// * [id] 
/// * [productId] 
/// * [variantId] 
/// * [name] 
/// * [nameAr] 
/// * [isRequired] 
/// * [minSelect] 
/// * [maxSelect] 
@BuiltValue()
abstract class ProductOptionGroup implements Built<ProductOptionGroup, ProductOptionGroupBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'productId')
  String? get productId;

  @BuiltValueField(wireName: r'variantId')
  String? get variantId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'isRequired')
  bool get isRequired;

  @BuiltValueField(wireName: r'minSelect')
  num get minSelect;

  @BuiltValueField(wireName: r'maxSelect')
  num get maxSelect;

  ProductOptionGroup._();

  factory ProductOptionGroup([void updates(ProductOptionGroupBuilder b)]) = _$ProductOptionGroup;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductOptionGroupBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductOptionGroup> get serializer => _$ProductOptionGroupSerializer();
}

class _$ProductOptionGroupSerializer implements PrimitiveSerializer<ProductOptionGroup> {
  @override
  final Iterable<Type> types = const [ProductOptionGroup, _$ProductOptionGroup];

  @override
  final String wireName = r'ProductOptionGroup';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductOptionGroup object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
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
    yield r'isRequired';
    yield serializers.serialize(
      object.isRequired,
      specifiedType: const FullType(bool),
    );
    yield r'minSelect';
    yield serializers.serialize(
      object.minSelect,
      specifiedType: const FullType(num),
    );
    yield r'maxSelect';
    yield serializers.serialize(
      object.maxSelect,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductOptionGroup object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductOptionGroupBuilder result,
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
        case r'isRequired':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isRequired = valueDes;
          break;
        case r'minSelect':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minSelect = valueDes;
          break;
        case r'maxSelect':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxSelect = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductOptionGroup deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductOptionGroupBuilder();
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

