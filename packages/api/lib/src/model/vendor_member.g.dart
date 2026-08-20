// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_member.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VendorMember extends VendorMember {
  @override
  final String id;
  @override
  final String vendorId;
  @override
  final String userId;
  @override
  final JsonObject? role;
  @override
  final String? branchId;
  @override
  final DateTime createdAt;
  @override
  final JsonObject? user;
  @override
  final JsonObject? vendor;
  @override
  final JsonObject? branch;

  factory _$VendorMember([void Function(VendorMemberBuilder)? updates]) =>
      (VendorMemberBuilder()..update(updates))._build();

  _$VendorMember._({
    required this.id,
    required this.vendorId,
    required this.userId,
    this.role,
    this.branchId,
    required this.createdAt,
    this.user,
    this.vendor,
    this.branch,
  }) : super._();
  @override
  VendorMember rebuild(void Function(VendorMemberBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VendorMemberBuilder toBuilder() => VendorMemberBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VendorMember &&
        id == other.id &&
        vendorId == other.vendorId &&
        userId == other.userId &&
        role == other.role &&
        branchId == other.branchId &&
        createdAt == other.createdAt &&
        user == other.user &&
        vendor == other.vendor &&
        branch == other.branch;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, branchId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jc(_$hash, branch.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VendorMember')
          ..add('id', id)
          ..add('vendorId', vendorId)
          ..add('userId', userId)
          ..add('role', role)
          ..add('branchId', branchId)
          ..add('createdAt', createdAt)
          ..add('user', user)
          ..add('vendor', vendor)
          ..add('branch', branch))
        .toString();
  }
}

class VendorMemberBuilder
    implements Builder<VendorMember, VendorMemberBuilder> {
  _$VendorMember? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  JsonObject? _role;
  JsonObject? get role => _$this._role;
  set role(JsonObject? role) => _$this._role = role;

  String? _branchId;
  String? get branchId => _$this._branchId;
  set branchId(String? branchId) => _$this._branchId = branchId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  JsonObject? _user;
  JsonObject? get user => _$this._user;
  set user(JsonObject? user) => _$this._user = user;

  JsonObject? _vendor;
  JsonObject? get vendor => _$this._vendor;
  set vendor(JsonObject? vendor) => _$this._vendor = vendor;

  JsonObject? _branch;
  JsonObject? get branch => _$this._branch;
  set branch(JsonObject? branch) => _$this._branch = branch;

  VendorMemberBuilder() {
    VendorMember._defaults(this);
  }

  VendorMemberBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _vendorId = $v.vendorId;
      _userId = $v.userId;
      _role = $v.role;
      _branchId = $v.branchId;
      _createdAt = $v.createdAt;
      _user = $v.user;
      _vendor = $v.vendor;
      _branch = $v.branch;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VendorMember other) {
    _$v = other as _$VendorMember;
  }

  @override
  void update(void Function(VendorMemberBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VendorMember build() => _build();

  _$VendorMember _build() {
    final _$result =
        _$v ??
        _$VendorMember._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'VendorMember', 'id'),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'VendorMember',
            'vendorId',
          ),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'VendorMember',
            'userId',
          ),
          role: role,
          branchId: branchId,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'VendorMember',
            'createdAt',
          ),
          user: user,
          vendor: vendor,
          branch: branch,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
