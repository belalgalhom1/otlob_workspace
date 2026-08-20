//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_vendor_member_role_dto.g.dart';

/// UpdateVendorMemberRoleDto
///
/// Properties:
/// * [role] 
/// * [branchId] 
@BuiltValue()
abstract class UpdateVendorMemberRoleDto implements Built<UpdateVendorMemberRoleDto, UpdateVendorMemberRoleDtoBuilder> {
  @BuiltValueField(wireName: r'role')
  UpdateVendorMemberRoleDtoRoleEnum get role;
  // enum roleEnum {  OWNER,  MANAGER,  STAFF,  };

  @BuiltValueField(wireName: r'branchId')
  String? get branchId;

  UpdateVendorMemberRoleDto._();

  factory UpdateVendorMemberRoleDto([void updates(UpdateVendorMemberRoleDtoBuilder b)]) = _$UpdateVendorMemberRoleDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateVendorMemberRoleDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateVendorMemberRoleDto> get serializer => _$UpdateVendorMemberRoleDtoSerializer();
}

class _$UpdateVendorMemberRoleDtoSerializer implements PrimitiveSerializer<UpdateVendorMemberRoleDto> {
  @override
  final Iterable<Type> types = const [UpdateVendorMemberRoleDto, _$UpdateVendorMemberRoleDto];

  @override
  final String wireName = r'UpdateVendorMemberRoleDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateVendorMemberRoleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(UpdateVendorMemberRoleDtoRoleEnum),
    );
    if (object.branchId != null) {
      yield r'branchId';
      yield serializers.serialize(
        object.branchId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateVendorMemberRoleDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateVendorMemberRoleDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateVendorMemberRoleDtoRoleEnum),
          ) as UpdateVendorMemberRoleDtoRoleEnum;
          result.role = valueDes;
          break;
        case r'branchId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.branchId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateVendorMemberRoleDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateVendorMemberRoleDtoBuilder();
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

class UpdateVendorMemberRoleDtoRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWNER')
  static const UpdateVendorMemberRoleDtoRoleEnum OWNER = _$updateVendorMemberRoleDtoRoleEnum_OWNER;
  @BuiltValueEnumConst(wireName: r'MANAGER')
  static const UpdateVendorMemberRoleDtoRoleEnum MANAGER = _$updateVendorMemberRoleDtoRoleEnum_MANAGER;
  @BuiltValueEnumConst(wireName: r'STAFF')
  static const UpdateVendorMemberRoleDtoRoleEnum STAFF = _$updateVendorMemberRoleDtoRoleEnum_STAFF;

  static Serializer<UpdateVendorMemberRoleDtoRoleEnum> get serializer => _$updateVendorMemberRoleDtoRoleEnumSerializer;

  const UpdateVendorMemberRoleDtoRoleEnum._(String name): super(name);

  static BuiltSet<UpdateVendorMemberRoleDtoRoleEnum> get values => _$updateVendorMemberRoleDtoRoleEnumValues;
  static UpdateVendorMemberRoleDtoRoleEnum valueOf(String name) => _$updateVendorMemberRoleDtoRoleEnumValueOf(name);
}

