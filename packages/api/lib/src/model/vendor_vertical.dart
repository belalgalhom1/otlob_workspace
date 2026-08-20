//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vendor.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vendor_vertical.g.dart';

/// VendorVertical
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [nameAr] 
/// * [slug] 
/// * [iconUrl] 
/// * [isActive] 
/// * [sortOrder] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [vendors] 
@BuiltValue()
abstract class VendorVertical implements Built<VendorVertical, VendorVerticalBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'iconUrl')
  String? get iconUrl;

  @BuiltValueField(wireName: r'isActive')
  bool get isActive;

  @BuiltValueField(wireName: r'sortOrder')
  num get sortOrder;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'vendors')
  BuiltList<Vendor> get vendors;

  VendorVertical._();

  factory VendorVertical([void updates(VendorVerticalBuilder b)]) = _$VendorVertical;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VendorVerticalBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VendorVertical> get serializer => _$VendorVerticalSerializer();
}

class _$VendorVerticalSerializer implements PrimitiveSerializer<VendorVertical> {
  @override
  final Iterable<Type> types = const [VendorVertical, _$VendorVertical];

  @override
  final String wireName = r'VendorVertical';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VendorVertical object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
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
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    if (object.iconUrl != null) {
      yield r'iconUrl';
      yield serializers.serialize(
        object.iconUrl,
        specifiedType: const FullType(String),
      );
    }
    yield r'isActive';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
    yield r'sortOrder';
    yield serializers.serialize(
      object.sortOrder,
      specifiedType: const FullType(num),
    );
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'vendors';
    yield serializers.serialize(
      object.vendors,
      specifiedType: const FullType(BuiltList, [FullType(Vendor)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VendorVertical object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VendorVerticalBuilder result,
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
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'iconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.iconUrl = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'sortOrder':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.sortOrder = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'vendors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Vendor)]),
          ) as BuiltList<Vendor>;
          result.vendors.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VendorVertical deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VendorVerticalBuilder();
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

