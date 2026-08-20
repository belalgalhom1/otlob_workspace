//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'add_vendor_member_dto.g.dart';

/// AddVendorMemberDto
///
/// Properties:
/// * [userId] 
/// * [role] 
/// * [branchId] 
@BuiltValue()
abstract class AddVendorMemberDto implements Built<AddVendorMemberDto, AddVendorMemberDtoBuilder> {
  @BuiltValueField(wireName: r'userId')
  String get userId;

  @BuiltValueField(wireName: r'role')
  AddVendorMemberDtoRoleEnum get role;
  // enum roleEnum {  OWNER,  MANAGER,  STAFF,  };

  @BuiltValueField(wireName: r'branchId')
  String? get branchId;

  AddVendorMemberDto._();

  factory AddVendorMemberDto([void updates(AddVendorMemberDtoBuilder b)]) = _$AddVendorMemberDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AddVendorMemberDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AddVendorMemberDto> get serializer => _$AddVendorMemberDtoSerializer();
}

class _$AddVendorMemberDtoSerializer implements PrimitiveSerializer<AddVendorMemberDto> {
  @override
  final Iterable<Type> types = const [AddVendorMemberDto, _$AddVendorMemberDto];

  @override
  final String wireName = r'AddVendorMemberDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AddVendorMemberDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'role';
    yield serializers.serialize(
      object.role,
      specifiedType: const FullType(AddVendorMemberDtoRoleEnum),
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
    AddVendorMemberDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AddVendorMemberDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
            specifiedType: const FullType(AddVendorMemberDtoRoleEnum),
          ) as AddVendorMemberDtoRoleEnum;
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
  AddVendorMemberDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AddVendorMemberDtoBuilder();
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

class AddVendorMemberDtoRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWNER')
  static const AddVendorMemberDtoRoleEnum OWNER = _$addVendorMemberDtoRoleEnum_OWNER;
  @BuiltValueEnumConst(wireName: r'MANAGER')
  static const AddVendorMemberDtoRoleEnum MANAGER = _$addVendorMemberDtoRoleEnum_MANAGER;
  @BuiltValueEnumConst(wireName: r'STAFF')
  static const AddVendorMemberDtoRoleEnum STAFF = _$addVendorMemberDtoRoleEnum_STAFF;

  static Serializer<AddVendorMemberDtoRoleEnum> get serializer => _$addVendorMemberDtoRoleEnumSerializer;

  const AddVendorMemberDtoRoleEnum._(String name): super(name);

  static BuiltSet<AddVendorMemberDtoRoleEnum> get values => _$addVendorMemberDtoRoleEnumValues;
  static AddVendorMemberDtoRoleEnum valueOf(String name) => _$addVendorMemberDtoRoleEnumValueOf(name);
}

