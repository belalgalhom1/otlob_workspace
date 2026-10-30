//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_branch_availability.g.dart';

/// ProductBranchAvailability
///
/// Properties:
/// * [productId] 
/// * [branchId] 
/// * [createdAt] 
@BuiltValue()
abstract class ProductBranchAvailability implements Built<ProductBranchAvailability, ProductBranchAvailabilityBuilder> {
  @BuiltValueField(wireName: r'productId')
  String get productId;

  @BuiltValueField(wireName: r'branchId')
  String get branchId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  ProductBranchAvailability._();

  factory ProductBranchAvailability([void updates(ProductBranchAvailabilityBuilder b)]) = _$ProductBranchAvailability;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductBranchAvailabilityBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductBranchAvailability> get serializer => _$ProductBranchAvailabilitySerializer();
}

class _$ProductBranchAvailabilitySerializer implements PrimitiveSerializer<ProductBranchAvailability> {
  @override
  final Iterable<Type> types = const [ProductBranchAvailability, _$ProductBranchAvailability];

  @override
  final String wireName = r'ProductBranchAvailability';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductBranchAvailability object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'productId';
    yield serializers.serialize(
      object.productId,
      specifiedType: const FullType(String),
    );
    yield r'branchId';
    yield serializers.serialize(
      object.branchId,
      specifiedType: const FullType(String),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductBranchAvailability object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductBranchAvailabilityBuilder result,
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
        case r'branchId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.branchId = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductBranchAvailability deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductBranchAvailabilityBuilder();
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

