//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vendor_member_role.dart';
import 'package:api/src/model/vendor.dart';
import 'package:api/src/model/user.dart';
import 'package:api/src/model/vendor_branch.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'vendor_member.g.dart';

/// VendorMember
///
/// Properties:
/// * [id] 
/// * [vendorId] 
/// * [userId] 
/// * [role] 
/// * [branchId] 
/// * [createdAt] 
/// * [user] 
/// * [vendor] 
/// * [branch] 
@BuiltValue()
abstract class VendorMember implements Built<VendorMember, VendorMemberBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'userId')
  String get userId;

  @BuiltValueField(wireName: r'role')
  JsonObject? get role;
  // enum roleEnum {  OWNER,  MANAGER,  STAFF,  };

  @BuiltValueField(wireName: r'branchId')
  String? get branchId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'user')
  JsonObject? get user;

  @BuiltValueField(wireName: r'vendor')
  JsonObject? get vendor;

  @BuiltValueField(wireName: r'branch')
  JsonObject? get branch;

  VendorMember._();

  factory VendorMember([void updates(VendorMemberBuilder b)]) = _$VendorMember;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VendorMemberBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VendorMember> get serializer => _$VendorMemberSerializer();
}

class _$VendorMemberSerializer implements PrimitiveSerializer<VendorMember> {
  @override
  final Iterable<Type> types = const [VendorMember, _$VendorMember];

  @override
  final String wireName = r'VendorMember';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VendorMember object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
      specifiedType: const FullType(String),
    );
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(VendorMemberRole),
    );
    if (object.branchId != null) {
      yield r'branchId';
      yield serializers.serialize(
        object.branchId,
        specifiedType: const FullType(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(User),
    );
    yield r'vendor';
    yield serializers.serialize(
      object.vendor,
      specifiedType: const FullType(Vendor),
    );
    if (object.branch != null) {
      yield r'branch';
      yield serializers.serialize(
        object.branch,
        specifiedType: const FullType(VendorBranch),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    VendorMember object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VendorMemberBuilder result,
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
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.role = valueDes;
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
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.user = valueDes;
          break;
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.vendor = valueDes;
          break;
        case r'branch':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.branch = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VendorMember deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VendorMemberBuilder();
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

