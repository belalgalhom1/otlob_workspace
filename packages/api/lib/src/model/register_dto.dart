//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_dto.g.dart';

/// RegisterDto
///
/// Properties:
/// * [email] 
/// * [password] 
/// * [name] 
/// * [phone] 
/// * [role] 
/// * [vendorId] 
/// * [vendorRole] 
@BuiltValue()
abstract class RegisterDto implements Built<RegisterDto, RegisterDtoBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'password')
  String get password;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'role')
  RegisterDtoRoleEnum? get role;
  // enum roleEnum {  CUSTOMER,  DRIVER,  VENDOR_MEMBER,  ADMIN,  SUPER_ADMIN,  };

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  @BuiltValueField(wireName: r'vendorRole')
  RegisterDtoVendorRoleEnum? get vendorRole;
  // enum vendorRoleEnum {  OWNER,  MANAGER,  STAFF,  };

  RegisterDto._();

  factory RegisterDto([void updates(RegisterDtoBuilder b)]) = _$RegisterDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterDto> get serializer => _$RegisterDtoSerializer();
}

class _$RegisterDtoSerializer implements PrimitiveSerializer<RegisterDto> {
  @override
  final Iterable<Type> types = const [RegisterDto, _$RegisterDto];

  @override
  final String wireName = r'RegisterDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    if (object.role != null) {
      yield r'role';
      yield serializers.serialize(
        object.role,
        specifiedType: const FullType(RegisterDtoRoleEnum),
      );
    }
    if (object.vendorId != null) {
      yield r'vendorId';
      yield serializers.serialize(
        object.vendorId,
        specifiedType: const FullType(String),
      );
    }
    if (object.vendorRole != null) {
      yield r'vendorRole';
      yield serializers.serialize(
        object.vendorRole,
        specifiedType: const FullType(RegisterDtoVendorRoleEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RegisterDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegisterDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RegisterDtoRoleEnum),
          ) as RegisterDtoRoleEnum;
          result.role = valueDes;
          break;
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
          break;
        case r'vendorRole':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RegisterDtoVendorRoleEnum),
          ) as RegisterDtoVendorRoleEnum;
          result.vendorRole = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegisterDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterDtoBuilder();
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

class RegisterDtoRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CUSTOMER')
  static const RegisterDtoRoleEnum CUSTOMER = _$registerDtoRoleEnum_CUSTOMER;
  @BuiltValueEnumConst(wireName: r'DRIVER')
  static const RegisterDtoRoleEnum DRIVER = _$registerDtoRoleEnum_DRIVER;
  @BuiltValueEnumConst(wireName: r'VENDOR_MEMBER')
  static const RegisterDtoRoleEnum VENDOR_MEMBER = _$registerDtoRoleEnum_VENDOR_MEMBER;
  @BuiltValueEnumConst(wireName: r'ADMIN')
  static const RegisterDtoRoleEnum ADMIN = _$registerDtoRoleEnum_ADMIN;
  @BuiltValueEnumConst(wireName: r'SUPER_ADMIN')
  static const RegisterDtoRoleEnum SUPER_ADMIN = _$registerDtoRoleEnum_SUPER_ADMIN;

  static Serializer<RegisterDtoRoleEnum> get serializer => _$registerDtoRoleEnumSerializer;

  const RegisterDtoRoleEnum._(String name): super(name);

  static BuiltSet<RegisterDtoRoleEnum> get values => _$registerDtoRoleEnumValues;
  static RegisterDtoRoleEnum valueOf(String name) => _$registerDtoRoleEnumValueOf(name);
}

class RegisterDtoVendorRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWNER')
  static const RegisterDtoVendorRoleEnum OWNER = _$registerDtoVendorRoleEnum_OWNER;
  @BuiltValueEnumConst(wireName: r'MANAGER')
  static const RegisterDtoVendorRoleEnum MANAGER = _$registerDtoVendorRoleEnum_MANAGER;
  @BuiltValueEnumConst(wireName: r'STAFF')
  static const RegisterDtoVendorRoleEnum STAFF = _$registerDtoVendorRoleEnum_STAFF;

  static Serializer<RegisterDtoVendorRoleEnum> get serializer => _$registerDtoVendorRoleEnumSerializer;

  const RegisterDtoVendorRoleEnum._(String name): super(name);

  static BuiltSet<RegisterDtoVendorRoleEnum> get values => _$registerDtoVendorRoleEnumValues;
  static RegisterDtoVendorRoleEnum valueOf(String name) => _$registerDtoVendorRoleEnumValueOf(name);
}

