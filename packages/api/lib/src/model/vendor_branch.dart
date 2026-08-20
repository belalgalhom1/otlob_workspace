//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/order.dart';
import 'package:api/src/model/vendor_member.dart';
import 'package:api/src/model/vendor.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/zone.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'vendor_branch.g.dart';

/// VendorBranch
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [nameAr] 
/// * [address] 
/// * [phone] 
/// * [isOpen] 
/// * [vendorId] 
/// * [zoneId] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [vendor] 
/// * [zone] 
/// * [vendorMembers] 
/// * [orders] 
@BuiltValue()
abstract class VendorBranch implements Built<VendorBranch, VendorBranchBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'address')
  String get address;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'isOpen')
  bool get isOpen;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'zoneId')
  String get zoneId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'vendor')
  JsonObject? get vendor;

  @BuiltValueField(wireName: r'zone')
  JsonObject? get zone;

  @BuiltValueField(wireName: r'vendorMembers')
  BuiltList<VendorMember> get vendorMembers;

  @BuiltValueField(wireName: r'orders')
  BuiltList<Order> get orders;

  VendorBranch._();

  factory VendorBranch([void updates(VendorBranchBuilder b)]) = _$VendorBranch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VendorBranchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VendorBranch> get serializer => _$VendorBranchSerializer();
}

class _$VendorBranchSerializer implements PrimitiveSerializer<VendorBranch> {
  @override
  final Iterable<Type> types = const [VendorBranch, _$VendorBranch];

  @override
  final String wireName = r'VendorBranch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VendorBranch object, {
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
    yield r'address';
    yield serializers.serialize(
      object.address,
      specifiedType: const FullType(String),
    );
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    yield r'isOpen';
    yield serializers.serialize(
      object.isOpen,
      specifiedType: const FullType(bool),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
    yield r'zoneId';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
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
    yield r'vendor';
    yield serializers.serialize(
      object.vendor,
      specifiedType: const FullType(Vendor),
    );
    yield r'zone';
    yield serializers.serialize(
      object.zone,
      specifiedType: const FullType(Zone),
    );
    yield r'vendorMembers';
    yield serializers.serialize(
      object.vendorMembers,
      specifiedType: const FullType(BuiltList, [FullType(VendorMember)]),
    );
    yield r'orders';
    yield serializers.serialize(
      object.orders,
      specifiedType: const FullType(BuiltList, [FullType(Order)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VendorBranch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VendorBranchBuilder result,
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
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.address = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'isOpen':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isOpen = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'zoneId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
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
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.vendor = valueDes;
          break;
        case r'zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.zone = valueDes;
          break;
        case r'vendorMembers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VendorMember)]),
          ) as BuiltList<VendorMember>;
          result.vendorMembers.replace(valueDes);
          break;
        case r'orders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Order)]),
          ) as BuiltList<Order>;
          result.orders.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VendorBranch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VendorBranchBuilder();
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

