// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Customer extends Customer {
  @override
  final String id;
  @override
  final String userId;
  @override
  final bool canOrder;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final num coinBalance;

  factory _$Customer([void Function(CustomerBuilder)? updates]) =>
      (CustomerBuilder()..update(updates))._build();

  _$Customer._({
    required this.id,
    required this.userId,
    required this.canOrder,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.coinBalance,
  }) : super._();
  @override
  Customer rebuild(void Function(CustomerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CustomerBuilder toBuilder() => CustomerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Customer &&
        id == other.id &&
        userId == other.userId &&
        canOrder == other.canOrder &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        coinBalance == other.coinBalance;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, canOrder.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, coinBalance.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Customer')
          ..add('id', id)
          ..add('userId', userId)
          ..add('canOrder', canOrder)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('coinBalance', coinBalance))
        .toString();
  }
}

class CustomerBuilder implements Builder<Customer, CustomerBuilder> {
  _$Customer? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  bool? _canOrder;
  bool? get canOrder => _$this._canOrder;
  set canOrder(bool? canOrder) => _$this._canOrder = canOrder;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  num? _coinBalance;
  num? get coinBalance => _$this._coinBalance;
  set coinBalance(num? coinBalance) => _$this._coinBalance = coinBalance;

  CustomerBuilder() {
    Customer._defaults(this);
  }

  CustomerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _canOrder = $v.canOrder;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _coinBalance = $v.coinBalance;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Customer other) {
    _$v = other as _$Customer;
  }

  @override
  void update(void Function(CustomerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Customer build() => _build();

  _$Customer _build() {
    final _$result =
        _$v ??
        _$Customer._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Customer', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'Customer',
            'userId',
          ),
          canOrder: BuiltValueNullFieldError.checkNotNull(
            canOrder,
            r'Customer',
            'canOrder',
          ),
          deletedAt: deletedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Customer',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Customer',
            'updatedAt',
          ),
          coinBalance: BuiltValueNullFieldError.checkNotNull(
            coinBalance,
            r'Customer',
            'coinBalance',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
