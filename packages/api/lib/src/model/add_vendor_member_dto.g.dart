// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_vendor_member_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AddVendorMemberDtoRoleEnum _$addVendorMemberDtoRoleEnum_OWNER =
    const AddVendorMemberDtoRoleEnum._('OWNER');
const AddVendorMemberDtoRoleEnum _$addVendorMemberDtoRoleEnum_MANAGER =
    const AddVendorMemberDtoRoleEnum._('MANAGER');
const AddVendorMemberDtoRoleEnum _$addVendorMemberDtoRoleEnum_STAFF =
    const AddVendorMemberDtoRoleEnum._('STAFF');

AddVendorMemberDtoRoleEnum _$addVendorMemberDtoRoleEnumValueOf(String name) {
  switch (name) {
    case 'OWNER':
      return _$addVendorMemberDtoRoleEnum_OWNER;
    case 'MANAGER':
      return _$addVendorMemberDtoRoleEnum_MANAGER;
    case 'STAFF':
      return _$addVendorMemberDtoRoleEnum_STAFF;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AddVendorMemberDtoRoleEnum> _$addVendorMemberDtoRoleEnumValues =
    BuiltSet<AddVendorMemberDtoRoleEnum>(const <AddVendorMemberDtoRoleEnum>[
      _$addVendorMemberDtoRoleEnum_OWNER,
      _$addVendorMemberDtoRoleEnum_MANAGER,
      _$addVendorMemberDtoRoleEnum_STAFF,
    ]);

Serializer<AddVendorMemberDtoRoleEnum> _$addVendorMemberDtoRoleEnumSerializer =
    _$AddVendorMemberDtoRoleEnumSerializer();

class _$AddVendorMemberDtoRoleEnumSerializer
    implements PrimitiveSerializer<AddVendorMemberDtoRoleEnum> {
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
  final Iterable<Type> types = const <Type>[AddVendorMemberDtoRoleEnum];
  @override
  final String wireName = 'AddVendorMemberDtoRoleEnum';

  @override
  Object serialize(
    Serializers serializers,
    AddVendorMemberDtoRoleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AddVendorMemberDtoRoleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AddVendorMemberDtoRoleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AddVendorMemberDto extends AddVendorMemberDto {
  @override
  final String userId;
  @override
  final AddVendorMemberDtoRoleEnum role;
  @override
  final String? branchId;

  factory _$AddVendorMemberDto([
    void Function(AddVendorMemberDtoBuilder)? updates,
  ]) => (AddVendorMemberDtoBuilder()..update(updates))._build();

  _$AddVendorMemberDto._({
    required this.userId,
    required this.role,
    this.branchId,
  }) : super._();
  @override
  AddVendorMemberDto rebuild(
    void Function(AddVendorMemberDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AddVendorMemberDtoBuilder toBuilder() =>
      AddVendorMemberDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AddVendorMemberDto &&
        userId == other.userId &&
        role == other.role &&
        branchId == other.branchId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, branchId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AddVendorMemberDto')
          ..add('userId', userId)
          ..add('role', role)
          ..add('branchId', branchId))
        .toString();
  }
}

class AddVendorMemberDtoBuilder
    implements Builder<AddVendorMemberDto, AddVendorMemberDtoBuilder> {
  _$AddVendorMemberDto? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  AddVendorMemberDtoRoleEnum? _role;
  AddVendorMemberDtoRoleEnum? get role => _$this._role;
  set role(AddVendorMemberDtoRoleEnum? role) => _$this._role = role;

  String? _branchId;
  String? get branchId => _$this._branchId;
  set branchId(String? branchId) => _$this._branchId = branchId;

  AddVendorMemberDtoBuilder() {
    AddVendorMemberDto._defaults(this);
  }

  AddVendorMemberDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _role = $v.role;
      _branchId = $v.branchId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AddVendorMemberDto other) {
    _$v = other as _$AddVendorMemberDto;
  }

  @override
  void update(void Function(AddVendorMemberDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AddVendorMemberDto build() => _build();

  _$AddVendorMemberDto _build() {
    final _$result =
        _$v ??
        _$AddVendorMemberDto._(
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'AddVendorMemberDto',
            'userId',
          ),
          role: BuiltValueNullFieldError.checkNotNull(
            role,
            r'AddVendorMemberDto',
            'role',
          ),
          branchId: branchId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
