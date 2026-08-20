// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_coin_transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CustomerCoinTransaction extends CustomerCoinTransaction {
  @override
  final String id;
  @override
  final String customerId;
  @override
  final String? orderId;
  @override
  final JsonObject? type;
  @override
  final num amount;
  @override
  final num balanceAfter;
  @override
  final String? description;
  @override
  final DateTime createdAt;
  @override
  final JsonObject? customer;

  factory _$CustomerCoinTransaction([
    void Function(CustomerCoinTransactionBuilder)? updates,
  ]) => (CustomerCoinTransactionBuilder()..update(updates))._build();

  _$CustomerCoinTransaction._({
    required this.id,
    required this.customerId,
    this.orderId,
    this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
    this.customer,
  }) : super._();
  @override
  CustomerCoinTransaction rebuild(
    void Function(CustomerCoinTransactionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CustomerCoinTransactionBuilder toBuilder() =>
      CustomerCoinTransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CustomerCoinTransaction &&
        id == other.id &&
        customerId == other.customerId &&
        orderId == other.orderId &&
        type == other.type &&
        amount == other.amount &&
        balanceAfter == other.balanceAfter &&
        description == other.description &&
        createdAt == other.createdAt &&
        customer == other.customer;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, customerId.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, balanceAfter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CustomerCoinTransaction')
          ..add('id', id)
          ..add('customerId', customerId)
          ..add('orderId', orderId)
          ..add('type', type)
          ..add('amount', amount)
          ..add('balanceAfter', balanceAfter)
          ..add('description', description)
          ..add('createdAt', createdAt)
          ..add('customer', customer))
        .toString();
  }
}

class CustomerCoinTransactionBuilder
    implements
        Builder<CustomerCoinTransaction, CustomerCoinTransactionBuilder> {
  _$CustomerCoinTransaction? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  JsonObject? _type;
  JsonObject? get type => _$this._type;
  set type(JsonObject? type) => _$this._type = type;

  num? _amount;
  num? get amount => _$this._amount;
  set amount(num? amount) => _$this._amount = amount;

  num? _balanceAfter;
  num? get balanceAfter => _$this._balanceAfter;
  set balanceAfter(num? balanceAfter) => _$this._balanceAfter = balanceAfter;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  JsonObject? _customer;
  JsonObject? get customer => _$this._customer;
  set customer(JsonObject? customer) => _$this._customer = customer;

  CustomerCoinTransactionBuilder() {
    CustomerCoinTransaction._defaults(this);
  }

  CustomerCoinTransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _customerId = $v.customerId;
      _orderId = $v.orderId;
      _type = $v.type;
      _amount = $v.amount;
      _balanceAfter = $v.balanceAfter;
      _description = $v.description;
      _createdAt = $v.createdAt;
      _customer = $v.customer;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CustomerCoinTransaction other) {
    _$v = other as _$CustomerCoinTransaction;
  }

  @override
  void update(void Function(CustomerCoinTransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CustomerCoinTransaction build() => _build();

  _$CustomerCoinTransaction _build() {
    final _$result =
        _$v ??
        _$CustomerCoinTransaction._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'CustomerCoinTransaction',
            'id',
          ),
          customerId: BuiltValueNullFieldError.checkNotNull(
            customerId,
            r'CustomerCoinTransaction',
            'customerId',
          ),
          orderId: orderId,
          type: type,
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'CustomerCoinTransaction',
            'amount',
          ),
          balanceAfter: BuiltValueNullFieldError.checkNotNull(
            balanceAfter,
            r'CustomerCoinTransaction',
            'balanceAfter',
          ),
          description: description,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'CustomerCoinTransaction',
            'createdAt',
          ),
          customer: customer,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
