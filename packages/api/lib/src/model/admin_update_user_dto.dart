//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_update_user_dto.g.dart';

/// AdminUpdateUserDto
///
/// Properties:
/// * [name] 
/// * [email] 
/// * [phone] 
/// * [language] 
/// * [role] 
/// * [title] 
/// * [titleAr] 
/// * [permissions] - Replaces entire permissions array. Only for ADMIN role.
/// * [isEmailVerified] 
/// * [isPhoneVerified] 
/// * [vendorId] 
/// * [vendorRole] 
/// * [password] 
/// * [autoReplyMessage] 
@BuiltValue()
abstract class AdminUpdateUserDto implements Built<AdminUpdateUserDto, AdminUpdateUserDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'language')
  AdminUpdateUserDtoLanguageEnum? get language;
  // enum languageEnum {  EN,  AR,  };

  @BuiltValueField(wireName: r'role')
  AdminUpdateUserDtoRoleEnum? get role;
  // enum roleEnum {  CUSTOMER,  DRIVER,  DRIVER_MANAGER,  VENDOR_MEMBER,  ADMIN,  SUPER_ADMIN,  };

  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'titleAr')
  String? get titleAr;

  /// Replaces entire permissions array. Only for ADMIN role.
  @BuiltValueField(wireName: r'permissions')
  BuiltList<AdminUpdateUserDtoPermissionsEnum>? get permissions;
  // enum permissionsEnum {  MANAGE_ORDERS,  MANAGE_PRODUCTS,  MANAGE_VENDORS,  MANAGE_DRIVERS,  MANAGE_CUSTOMERS,  MANAGE_TICKETS,  MANAGE_CONVERSATIONS,  VIEW_STATISTICS,  MANAGE_SETTINGS,  MANAGE_USERS,  VIEW_FINANCIALS,  MANAGE_FINANCE,  MANAGE_PROMOTIONS,  MANAGE_ANNOUNCEMENTS,  VIEW_AUDIT_LOGS,  };

  @BuiltValueField(wireName: r'isEmailVerified')
  bool? get isEmailVerified;

  @BuiltValueField(wireName: r'isPhoneVerified')
  bool? get isPhoneVerified;

  @BuiltValueField(wireName: r'vendorId')
  String? get vendorId;

  @BuiltValueField(wireName: r'vendorRole')
  AdminUpdateUserDtoVendorRoleEnum? get vendorRole;
  // enum vendorRoleEnum {  OWNER,  MANAGER,  STAFF,  };

  @BuiltValueField(wireName: r'password')
  String? get password;

  @BuiltValueField(wireName: r'autoReplyMessage')
  String? get autoReplyMessage;

  AdminUpdateUserDto._();

  factory AdminUpdateUserDto([void updates(AdminUpdateUserDtoBuilder b)]) = _$AdminUpdateUserDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminUpdateUserDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminUpdateUserDto> get serializer => _$AdminUpdateUserDtoSerializer();
}

class _$AdminUpdateUserDtoSerializer implements PrimitiveSerializer<AdminUpdateUserDto> {
  @override
  final Iterable<Type> types = const [AdminUpdateUserDto, _$AdminUpdateUserDto];

  @override
  final String wireName = r'AdminUpdateUserDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminUpdateUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType(String),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    if (object.language != null) {
      yield r'language';
      yield serializers.serialize(
        object.language,
        specifiedType: const FullType(AdminUpdateUserDtoLanguageEnum),
      );
    }
    if (object.role != null) {
      yield r'role';
      yield serializers.serialize(
        object.role,
        specifiedType: const FullType(AdminUpdateUserDtoRoleEnum),
      );
    }
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType(String),
      );
    }
    if (object.titleAr != null) {
      yield r'titleAr';
      yield serializers.serialize(
        object.titleAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.permissions != null) {
      yield r'permissions';
      yield serializers.serialize(
        object.permissions,
        specifiedType: const FullType(BuiltList, [FullType(AdminUpdateUserDtoPermissionsEnum)]),
      );
    }
    if (object.isEmailVerified != null) {
      yield r'isEmailVerified';
      yield serializers.serialize(
        object.isEmailVerified,
        specifiedType: const FullType(bool),
      );
    }
    if (object.isPhoneVerified != null) {
      yield r'isPhoneVerified';
      yield serializers.serialize(
        object.isPhoneVerified,
        specifiedType: const FullType(bool),
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
        specifiedType: const FullType(AdminUpdateUserDtoVendorRoleEnum),
      );
    }
    if (object.password != null) {
      yield r'password';
      yield serializers.serialize(
        object.password,
        specifiedType: const FullType(String),
      );
    }
    if (object.autoReplyMessage != null) {
      yield r'autoReplyMessage';
      yield serializers.serialize(
        object.autoReplyMessage,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminUpdateUserDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminUpdateUserDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'language':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AdminUpdateUserDtoLanguageEnum),
          ) as AdminUpdateUserDtoLanguageEnum;
          result.language = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AdminUpdateUserDtoRoleEnum),
          ) as AdminUpdateUserDtoRoleEnum;
          result.role = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'titleAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.titleAr = valueDes;
          break;
        case r'permissions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AdminUpdateUserDtoPermissionsEnum)]),
          ) as BuiltList<AdminUpdateUserDtoPermissionsEnum>;
          result.permissions.replace(valueDes);
          break;
        case r'isEmailVerified':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isEmailVerified = valueDes;
          break;
        case r'isPhoneVerified':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isPhoneVerified = valueDes;
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
            specifiedType: const FullType(AdminUpdateUserDtoVendorRoleEnum),
          ) as AdminUpdateUserDtoVendorRoleEnum;
          result.vendorRole = valueDes;
          break;
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
        case r'autoReplyMessage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.autoReplyMessage = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminUpdateUserDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminUpdateUserDtoBuilder();
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

class AdminUpdateUserDtoLanguageEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'EN')
  static const AdminUpdateUserDtoLanguageEnum EN = _$adminUpdateUserDtoLanguageEnum_EN;
  @BuiltValueEnumConst(wireName: r'AR')
  static const AdminUpdateUserDtoLanguageEnum AR = _$adminUpdateUserDtoLanguageEnum_AR;

  static Serializer<AdminUpdateUserDtoLanguageEnum> get serializer => _$adminUpdateUserDtoLanguageEnumSerializer;

  const AdminUpdateUserDtoLanguageEnum._(String name): super(name);

  static BuiltSet<AdminUpdateUserDtoLanguageEnum> get values => _$adminUpdateUserDtoLanguageEnumValues;
  static AdminUpdateUserDtoLanguageEnum valueOf(String name) => _$adminUpdateUserDtoLanguageEnumValueOf(name);
}

class AdminUpdateUserDtoRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CUSTOMER')
  static const AdminUpdateUserDtoRoleEnum CUSTOMER = _$adminUpdateUserDtoRoleEnum_CUSTOMER;
  @BuiltValueEnumConst(wireName: r'DRIVER')
  static const AdminUpdateUserDtoRoleEnum DRIVER = _$adminUpdateUserDtoRoleEnum_DRIVER;
  @BuiltValueEnumConst(wireName: r'DRIVER_MANAGER')
  static const AdminUpdateUserDtoRoleEnum DRIVER_MANAGER = _$adminUpdateUserDtoRoleEnum_DRIVER_MANAGER;
  @BuiltValueEnumConst(wireName: r'VENDOR_MEMBER')
  static const AdminUpdateUserDtoRoleEnum VENDOR_MEMBER = _$adminUpdateUserDtoRoleEnum_VENDOR_MEMBER;
  @BuiltValueEnumConst(wireName: r'ADMIN')
  static const AdminUpdateUserDtoRoleEnum ADMIN = _$adminUpdateUserDtoRoleEnum_ADMIN;
  @BuiltValueEnumConst(wireName: r'SUPER_ADMIN')
  static const AdminUpdateUserDtoRoleEnum SUPER_ADMIN = _$adminUpdateUserDtoRoleEnum_SUPER_ADMIN;

  static Serializer<AdminUpdateUserDtoRoleEnum> get serializer => _$adminUpdateUserDtoRoleEnumSerializer;

  const AdminUpdateUserDtoRoleEnum._(String name): super(name);

  static BuiltSet<AdminUpdateUserDtoRoleEnum> get values => _$adminUpdateUserDtoRoleEnumValues;
  static AdminUpdateUserDtoRoleEnum valueOf(String name) => _$adminUpdateUserDtoRoleEnumValueOf(name);
}

class AdminUpdateUserDtoPermissionsEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'MANAGE_ORDERS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_ORDERS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_ORDERS;
  @BuiltValueEnumConst(wireName: r'MANAGE_PRODUCTS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_PRODUCTS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_PRODUCTS;
  @BuiltValueEnumConst(wireName: r'MANAGE_VENDORS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_VENDORS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_VENDORS;
  @BuiltValueEnumConst(wireName: r'MANAGE_DRIVERS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_DRIVERS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_DRIVERS;
  @BuiltValueEnumConst(wireName: r'MANAGE_CUSTOMERS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_CUSTOMERS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_CUSTOMERS;
  @BuiltValueEnumConst(wireName: r'MANAGE_TICKETS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_TICKETS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_TICKETS;
  @BuiltValueEnumConst(wireName: r'MANAGE_CONVERSATIONS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_CONVERSATIONS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_CONVERSATIONS;
  @BuiltValueEnumConst(wireName: r'VIEW_STATISTICS')
  static const AdminUpdateUserDtoPermissionsEnum VIEW_STATISTICS = _$adminUpdateUserDtoPermissionsEnum_VIEW_STATISTICS;
  @BuiltValueEnumConst(wireName: r'MANAGE_SETTINGS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_SETTINGS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_SETTINGS;
  @BuiltValueEnumConst(wireName: r'MANAGE_USERS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_USERS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_USERS;
  @BuiltValueEnumConst(wireName: r'VIEW_FINANCIALS')
  static const AdminUpdateUserDtoPermissionsEnum VIEW_FINANCIALS = _$adminUpdateUserDtoPermissionsEnum_VIEW_FINANCIALS;
  @BuiltValueEnumConst(wireName: r'MANAGE_FINANCE')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_FINANCE = _$adminUpdateUserDtoPermissionsEnum_MANAGE_FINANCE;
  @BuiltValueEnumConst(wireName: r'MANAGE_PROMOTIONS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_PROMOTIONS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_PROMOTIONS;
  @BuiltValueEnumConst(wireName: r'MANAGE_ANNOUNCEMENTS')
  static const AdminUpdateUserDtoPermissionsEnum MANAGE_ANNOUNCEMENTS = _$adminUpdateUserDtoPermissionsEnum_MANAGE_ANNOUNCEMENTS;
  @BuiltValueEnumConst(wireName: r'VIEW_AUDIT_LOGS')
  static const AdminUpdateUserDtoPermissionsEnum VIEW_AUDIT_LOGS = _$adminUpdateUserDtoPermissionsEnum_VIEW_AUDIT_LOGS;

  static Serializer<AdminUpdateUserDtoPermissionsEnum> get serializer => _$adminUpdateUserDtoPermissionsEnumSerializer;

  const AdminUpdateUserDtoPermissionsEnum._(String name): super(name);

  static BuiltSet<AdminUpdateUserDtoPermissionsEnum> get values => _$adminUpdateUserDtoPermissionsEnumValues;
  static AdminUpdateUserDtoPermissionsEnum valueOf(String name) => _$adminUpdateUserDtoPermissionsEnumValueOf(name);
}

class AdminUpdateUserDtoVendorRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWNER')
  static const AdminUpdateUserDtoVendorRoleEnum OWNER = _$adminUpdateUserDtoVendorRoleEnum_OWNER;
  @BuiltValueEnumConst(wireName: r'MANAGER')
  static const AdminUpdateUserDtoVendorRoleEnum MANAGER = _$adminUpdateUserDtoVendorRoleEnum_MANAGER;
  @BuiltValueEnumConst(wireName: r'STAFF')
  static const AdminUpdateUserDtoVendorRoleEnum STAFF = _$adminUpdateUserDtoVendorRoleEnum_STAFF;

  static Serializer<AdminUpdateUserDtoVendorRoleEnum> get serializer => _$adminUpdateUserDtoVendorRoleEnumSerializer;

  const AdminUpdateUserDtoVendorRoleEnum._(String name): super(name);

  static BuiltSet<AdminUpdateUserDtoVendorRoleEnum> get values => _$adminUpdateUserDtoVendorRoleEnumValues;
  static AdminUpdateUserDtoVendorRoleEnum valueOf(String name) => _$adminUpdateUserDtoVendorRoleEnumValueOf(name);
}

