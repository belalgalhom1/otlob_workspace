// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_actor_summary_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderActorSummaryDto extends OrderActorSummaryDto {
  @override
  final String? id;
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
  final bool isSystem;

  factory _$OrderActorSummaryDto([
    void Function(OrderActorSummaryDtoBuilder)? updates,
  ]) => (OrderActorSummaryDtoBuilder()..update(updates))._build();

  _$OrderActorSummaryDto._({
    this.id,
    required this.name,
    this.nameAr,
    this.role,
    this.avatar,
    this.vendorId,
    required this.isSystem,
  }) : super._();
  @override
  OrderActorSummaryDto rebuild(
    void Function(OrderActorSummaryDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderActorSummaryDtoBuilder toBuilder() =>
      OrderActorSummaryDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderActorSummaryDto &&
        id == other.id &&
        name == other.name &&
        nameAr == other.nameAr &&
        role == other.role &&
        avatar == other.avatar &&
        vendorId == other.vendorId &&
        isSystem == other.isSystem;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, avatar.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, isSystem.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderActorSummaryDto')
          ..add('id', id)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('role', role)
          ..add('avatar', avatar)
          ..add('vendorId', vendorId)
          ..add('isSystem', isSystem))
        .toString();
  }
}

class OrderActorSummaryDtoBuilder
    implements Builder<OrderActorSummaryDto, OrderActorSummaryDtoBuilder> {
  _$OrderActorSummaryDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

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

  bool? _isSystem;
  bool? get isSystem => _$this._isSystem;
  set isSystem(bool? isSystem) => _$this._isSystem = isSystem;

  OrderActorSummaryDtoBuilder() {
    OrderActorSummaryDto._defaults(this);
  }

  OrderActorSummaryDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _role = $v.role;
      _avatar = $v.avatar;
      _vendorId = $v.vendorId;
      _isSystem = $v.isSystem;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderActorSummaryDto other) {
    _$v = other as _$OrderActorSummaryDto;
  }

  @override
  void update(void Function(OrderActorSummaryDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderActorSummaryDto build() => _build();

  _$OrderActorSummaryDto _build() {
    final _$result =
        _$v ??
        _$OrderActorSummaryDto._(
          id: id,
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'OrderActorSummaryDto',
            'name',
          ),
          nameAr: nameAr,
          role: role,
          avatar: avatar,
          vendorId: vendorId,
          isSystem: BuiltValueNullFieldError.checkNotNull(
            isSystem,
            r'OrderActorSummaryDto',
            'isSystem',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
