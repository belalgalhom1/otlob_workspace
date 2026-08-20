// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterDtoRoleEnum _$registerDtoRoleEnum_CUSTOMER =
    const RegisterDtoRoleEnum._('CUSTOMER');
const RegisterDtoRoleEnum _$registerDtoRoleEnum_DRIVER =
    const RegisterDtoRoleEnum._('DRIVER');
const RegisterDtoRoleEnum _$registerDtoRoleEnum_VENDOR_MEMBER =
    const RegisterDtoRoleEnum._('VENDOR_MEMBER');
const RegisterDtoRoleEnum _$registerDtoRoleEnum_ADMIN =
    const RegisterDtoRoleEnum._('ADMIN');
const RegisterDtoRoleEnum _$registerDtoRoleEnum_SUPER_ADMIN =
    const RegisterDtoRoleEnum._('SUPER_ADMIN');

RegisterDtoRoleEnum _$registerDtoRoleEnumValueOf(String name) {
  switch (name) {
    case 'CUSTOMER':
      return _$registerDtoRoleEnum_CUSTOMER;
    case 'DRIVER':
      return _$registerDtoRoleEnum_DRIVER;
    case 'VENDOR_MEMBER':
      return _$registerDtoRoleEnum_VENDOR_MEMBER;
    case 'ADMIN':
      return _$registerDtoRoleEnum_ADMIN;
    case 'SUPER_ADMIN':
      return _$registerDtoRoleEnum_SUPER_ADMIN;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterDtoRoleEnum> _$registerDtoRoleEnumValues =
    BuiltSet<RegisterDtoRoleEnum>(const <RegisterDtoRoleEnum>[
      _$registerDtoRoleEnum_CUSTOMER,
      _$registerDtoRoleEnum_DRIVER,
      _$registerDtoRoleEnum_VENDOR_MEMBER,
      _$registerDtoRoleEnum_ADMIN,
      _$registerDtoRoleEnum_SUPER_ADMIN,
    ]);

const RegisterDtoVendorRoleEnum _$registerDtoVendorRoleEnum_OWNER =
    const RegisterDtoVendorRoleEnum._('OWNER');
const RegisterDtoVendorRoleEnum _$registerDtoVendorRoleEnum_MANAGER =
    const RegisterDtoVendorRoleEnum._('MANAGER');
const RegisterDtoVendorRoleEnum _$registerDtoVendorRoleEnum_STAFF =
    const RegisterDtoVendorRoleEnum._('STAFF');

RegisterDtoVendorRoleEnum _$registerDtoVendorRoleEnumValueOf(String name) {
  switch (name) {
    case 'OWNER':
      return _$registerDtoVendorRoleEnum_OWNER;
    case 'MANAGER':
      return _$registerDtoVendorRoleEnum_MANAGER;
    case 'STAFF':
      return _$registerDtoVendorRoleEnum_STAFF;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterDtoVendorRoleEnum> _$registerDtoVendorRoleEnumValues =
    BuiltSet<RegisterDtoVendorRoleEnum>(const <RegisterDtoVendorRoleEnum>[
      _$registerDtoVendorRoleEnum_OWNER,
      _$registerDtoVendorRoleEnum_MANAGER,
      _$registerDtoVendorRoleEnum_STAFF,
    ]);

Serializer<RegisterDtoRoleEnum> _$registerDtoRoleEnumSerializer =
    _$RegisterDtoRoleEnumSerializer();
Serializer<RegisterDtoVendorRoleEnum> _$registerDtoVendorRoleEnumSerializer =
    _$RegisterDtoVendorRoleEnumSerializer();

class _$RegisterDtoRoleEnumSerializer
    implements PrimitiveSerializer<RegisterDtoRoleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CUSTOMER': 'CUSTOMER',
    'DRIVER': 'DRIVER',
    'VENDOR_MEMBER': 'VENDOR_MEMBER',
    'ADMIN': 'ADMIN',
    'SUPER_ADMIN': 'SUPER_ADMIN',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CUSTOMER': 'CUSTOMER',
    'DRIVER': 'DRIVER',
    'VENDOR_MEMBER': 'VENDOR_MEMBER',
    'ADMIN': 'ADMIN',
    'SUPER_ADMIN': 'SUPER_ADMIN',
  };

  @override
  final Iterable<Type> types = const <Type>[RegisterDtoRoleEnum];
  @override
  final String wireName = 'RegisterDtoRoleEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterDtoRoleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterDtoRoleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterDtoRoleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterDtoVendorRoleEnumSerializer
    implements PrimitiveSerializer<RegisterDtoVendorRoleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OWNER': 'OWNER',
    'MANAGER': 'MANAGER',
    'STAFF': 'STAFF',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OWNER': 'OWNER',
    'MANAGER': 'MANAGER',
    'STAFF': 'STAFF',
  };

  @override
  final Iterable<Type> types = const <Type>[RegisterDtoVendorRoleEnum];
  @override
  final String wireName = 'RegisterDtoVendorRoleEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterDtoVendorRoleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterDtoVendorRoleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterDtoVendorRoleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterDto extends RegisterDto {
  @override
  final String email;
  @override
  final String password;
  @override
  final String name;
  @override
  final String? phone;
  @override
  final RegisterDtoRoleEnum? role;
  @override
  final String? vendorId;
  @override
  final RegisterDtoVendorRoleEnum? vendorRole;

  factory _$RegisterDto([void Function(RegisterDtoBuilder)? updates]) =>
      (RegisterDtoBuilder()..update(updates))._build();

  _$RegisterDto._({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    this.role,
    this.vendorId,
    this.vendorRole,
  }) : super._();
  @override
  RegisterDto rebuild(void Function(RegisterDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterDtoBuilder toBuilder() => RegisterDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterDto &&
        email == other.email &&
        password == other.password &&
        name == other.name &&
        phone == other.phone &&
        role == other.role &&
        vendorId == other.vendorId &&
        vendorRole == other.vendorRole;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, vendorRole.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterDto')
          ..add('email', email)
          ..add('password', password)
          ..add('name', name)
          ..add('phone', phone)
          ..add('role', role)
          ..add('vendorId', vendorId)
          ..add('vendorRole', vendorRole))
        .toString();
  }
}

class RegisterDtoBuilder implements Builder<RegisterDto, RegisterDtoBuilder> {
  _$RegisterDto? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  RegisterDtoRoleEnum? _role;
  RegisterDtoRoleEnum? get role => _$this._role;
  set role(RegisterDtoRoleEnum? role) => _$this._role = role;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  RegisterDtoVendorRoleEnum? _vendorRole;
  RegisterDtoVendorRoleEnum? get vendorRole => _$this._vendorRole;
  set vendorRole(RegisterDtoVendorRoleEnum? vendorRole) =>
      _$this._vendorRole = vendorRole;

  RegisterDtoBuilder() {
    RegisterDto._defaults(this);
  }

  RegisterDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _name = $v.name;
      _phone = $v.phone;
      _role = $v.role;
      _vendorId = $v.vendorId;
      _vendorRole = $v.vendorRole;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterDto other) {
    _$v = other as _$RegisterDto;
  }

  @override
  void update(void Function(RegisterDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterDto build() => _build();

  _$RegisterDto _build() {
    final _$result =
        _$v ??
        _$RegisterDto._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'RegisterDto',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'RegisterDto',
            'password',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'RegisterDto',
            'name',
          ),
          phone: phone,
          role: role,
          vendorId: vendorId,
          vendorRole: vendorRole,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
