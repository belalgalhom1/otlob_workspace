// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_cancelled_by_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderCancelledByDto extends OrderCancelledByDto {
  @override
  final String? userId;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final Role? role;
  @override
  final String? avatar;
  @override
  final String? vendorId;
  @override
  final String? reason;
  @override
  final DateTime? cancelledAt;
  @override
  final bool isSystem;

  factory _$OrderCancelledByDto([
    void Function(OrderCancelledByDtoBuilder)? updates,
  ]) => (OrderCancelledByDtoBuilder()..update(updates))._build();

  _$OrderCancelledByDto._({
    this.userId,
    required this.name,
    this.nameAr,
    this.role,
    this.avatar,
    this.vendorId,
    this.reason,
    this.cancelledAt,
    required this.isSystem,
  }) : super._();
  @override
  OrderCancelledByDto rebuild(
    void Function(OrderCancelledByDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderCancelledByDtoBuilder toBuilder() =>
      OrderCancelledByDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderCancelledByDto &&
        userId == other.userId &&
        name == other.name &&
        nameAr == other.nameAr &&
        role == other.role &&
        avatar == other.avatar &&
        vendorId == other.vendorId &&
        reason == other.reason &&
        cancelledAt == other.cancelledAt &&
        isSystem == other.isSystem;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, avatar.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, cancelledAt.hashCode);
    _$hash = $jc(_$hash, isSystem.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderCancelledByDto')
          ..add('userId', userId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('role', role)
          ..add('avatar', avatar)
          ..add('vendorId', vendorId)
          ..add('reason', reason)
          ..add('cancelledAt', cancelledAt)
          ..add('isSystem', isSystem))
        .toString();
  }
}

class OrderCancelledByDtoBuilder
    implements Builder<OrderCancelledByDto, OrderCancelledByDtoBuilder> {
  _$OrderCancelledByDto? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  Role? _role;
  Role? get role => _$this._role;
  set role(Role? role) => _$this._role = role;

  String? _avatar;
  String? get avatar => _$this._avatar;
  set avatar(String? avatar) => _$this._avatar = avatar;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _$this._cancelledAt;
  set cancelledAt(DateTime? cancelledAt) => _$this._cancelledAt = cancelledAt;

  bool? _isSystem;
  bool? get isSystem => _$this._isSystem;
  set isSystem(bool? isSystem) => _$this._isSystem = isSystem;

  OrderCancelledByDtoBuilder() {
    OrderCancelledByDto._defaults(this);
  }

  OrderCancelledByDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _role = $v.role;
      _avatar = $v.avatar;
      _vendorId = $v.vendorId;
      _reason = $v.reason;
      _cancelledAt = $v.cancelledAt;
      _isSystem = $v.isSystem;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderCancelledByDto other) {
    _$v = other as _$OrderCancelledByDto;
  }

  @override
  void update(void Function(OrderCancelledByDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderCancelledByDto build() => _build();

  _$OrderCancelledByDto _build() {
    final _$result =
        _$v ??
        _$OrderCancelledByDto._(
          userId: userId,
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'OrderCancelledByDto',
            'name',
          ),
          nameAr: nameAr,
          role: role,
          avatar: avatar,
          vendorId: vendorId,
          reason: reason,
          cancelledAt: cancelledAt,
          isSystem: BuiltValueNullFieldError.checkNotNull(
            isSystem,
            r'OrderCancelledByDto',
            'isSystem',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
