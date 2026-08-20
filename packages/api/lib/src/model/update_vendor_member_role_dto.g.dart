// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_vendor_member_role_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateVendorMemberRoleDtoRoleEnum
_$updateVendorMemberRoleDtoRoleEnum_OWNER =
    const UpdateVendorMemberRoleDtoRoleEnum._('OWNER');
const UpdateVendorMemberRoleDtoRoleEnum
_$updateVendorMemberRoleDtoRoleEnum_MANAGER =
    const UpdateVendorMemberRoleDtoRoleEnum._('MANAGER');
const UpdateVendorMemberRoleDtoRoleEnum
_$updateVendorMemberRoleDtoRoleEnum_STAFF =
    const UpdateVendorMemberRoleDtoRoleEnum._('STAFF');

UpdateVendorMemberRoleDtoRoleEnum _$updateVendorMemberRoleDtoRoleEnumValueOf(
  String name,
) {
  switch (name) {
    case 'OWNER':
      return _$updateVendorMemberRoleDtoRoleEnum_OWNER;
    case 'MANAGER':
      return _$updateVendorMemberRoleDtoRoleEnum_MANAGER;
    case 'STAFF':
      return _$updateVendorMemberRoleDtoRoleEnum_STAFF;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateVendorMemberRoleDtoRoleEnum>
_$updateVendorMemberRoleDtoRoleEnumValues =
    BuiltSet<UpdateVendorMemberRoleDtoRoleEnum>(
      const <UpdateVendorMemberRoleDtoRoleEnum>[
        _$updateVendorMemberRoleDtoRoleEnum_OWNER,
        _$updateVendorMemberRoleDtoRoleEnum_MANAGER,
        _$updateVendorMemberRoleDtoRoleEnum_STAFF,
      ],
    );

Serializer<UpdateVendorMemberRoleDtoRoleEnum>
_$updateVendorMemberRoleDtoRoleEnumSerializer =
    _$UpdateVendorMemberRoleDtoRoleEnumSerializer();

class _$UpdateVendorMemberRoleDtoRoleEnumSerializer
    implements PrimitiveSerializer<UpdateVendorMemberRoleDtoRoleEnum> {
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
  final Iterable<Type> types = const <Type>[UpdateVendorMemberRoleDtoRoleEnum];
  @override
  final String wireName = 'UpdateVendorMemberRoleDtoRoleEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateVendorMemberRoleDtoRoleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateVendorMemberRoleDtoRoleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateVendorMemberRoleDtoRoleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateVendorMemberRoleDto extends UpdateVendorMemberRoleDto {
  @override
  final UpdateVendorMemberRoleDtoRoleEnum role;
  @override
  final String? branchId;

  factory _$UpdateVendorMemberRoleDto([
    void Function(UpdateVendorMemberRoleDtoBuilder)? updates,
  ]) => (UpdateVendorMemberRoleDtoBuilder()..update(updates))._build();

  _$UpdateVendorMemberRoleDto._({required this.role, this.branchId})
    : super._();
  @override
  UpdateVendorMemberRoleDto rebuild(
    void Function(UpdateVendorMemberRoleDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateVendorMemberRoleDtoBuilder toBuilder() =>
      UpdateVendorMemberRoleDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateVendorMemberRoleDto &&
        role == other.role &&
        branchId == other.branchId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, branchId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateVendorMemberRoleDto')
          ..add('role', role)
          ..add('branchId', branchId))
        .toString();
  }
}

class UpdateVendorMemberRoleDtoBuilder
    implements
        Builder<UpdateVendorMemberRoleDto, UpdateVendorMemberRoleDtoBuilder> {
  _$UpdateVendorMemberRoleDto? _$v;

  UpdateVendorMemberRoleDtoRoleEnum? _role;
  UpdateVendorMemberRoleDtoRoleEnum? get role => _$this._role;
  set role(UpdateVendorMemberRoleDtoRoleEnum? role) => _$this._role = role;

  String? _branchId;
  String? get branchId => _$this._branchId;
  set branchId(String? branchId) => _$this._branchId = branchId;

  UpdateVendorMemberRoleDtoBuilder() {
    UpdateVendorMemberRoleDto._defaults(this);
  }

  UpdateVendorMemberRoleDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _role = $v.role;
      _branchId = $v.branchId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateVendorMemberRoleDto other) {
    _$v = other as _$UpdateVendorMemberRoleDto;
  }

  @override
  void update(void Function(UpdateVendorMemberRoleDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateVendorMemberRoleDto build() => _build();

  _$UpdateVendorMemberRoleDto _build() {
    final _$result =
        _$v ??
        _$UpdateVendorMemberRoleDto._(
          role: BuiltValueNullFieldError.checkNotNull(
            role,
            r'UpdateVendorMemberRoleDto',
            'role',
          ),
          branchId: branchId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
