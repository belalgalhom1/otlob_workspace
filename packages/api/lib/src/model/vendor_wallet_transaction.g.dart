// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_wallet_transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VendorWalletTransaction extends VendorWalletTransaction {
  @override
  final String id;
  @override
  final String vendorId;
  @override
  final String? orderId;
  @override
  final VendorTransactionType type;
  @override
  final num amount;
  @override
  final num balanceAfter;
  @override
  final String? description;
  @override
  final String? referenceId;
  @override
  final DateTime createdAt;

  factory _$VendorWalletTransaction([
    void Function(VendorWalletTransactionBuilder)? updates,
  ]) => (VendorWalletTransactionBuilder()..update(updates))._build();

  _$VendorWalletTransaction._({
    required this.id,
    required this.vendorId,
    this.orderId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    required this.createdAt,
  }) : super._();
  @override
  VendorWalletTransaction rebuild(
    void Function(VendorWalletTransactionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  VendorWalletTransactionBuilder toBuilder() =>
      VendorWalletTransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VendorWalletTransaction &&
        id == other.id &&
        vendorId == other.vendorId &&
        orderId == other.orderId &&
        type == other.type &&
        amount == other.amount &&
        balanceAfter == other.balanceAfter &&
        description == other.description &&
        referenceId == other.referenceId &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, balanceAfter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, referenceId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VendorWalletTransaction')
          ..add('id', id)
          ..add('vendorId', vendorId)
          ..add('orderId', orderId)
          ..add('type', type)
          ..add('amount', amount)
          ..add('balanceAfter', balanceAfter)
          ..add('description', description)
          ..add('referenceId', referenceId)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class VendorWalletTransactionBuilder
    implements
        Builder<VendorWalletTransaction, VendorWalletTransactionBuilder> {
  _$VendorWalletTransaction? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  VendorTransactionType? _type;
  VendorTransactionType? get type => _$this._type;
  set type(VendorTransactionType? type) => _$this._type = type;

  num? _amount;
  num? get amount => _$this._amount;
  set amount(num? amount) => _$this._amount = amount;

  num? _balanceAfter;
  num? get balanceAfter => _$this._balanceAfter;
  set balanceAfter(num? balanceAfter) => _$this._balanceAfter = balanceAfter;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _referenceId;
  String? get referenceId => _$this._referenceId;
  set referenceId(String? referenceId) => _$this._referenceId = referenceId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  VendorWalletTransactionBuilder() {
    VendorWalletTransaction._defaults(this);
  }

  VendorWalletTransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _vendorId = $v.vendorId;
      _orderId = $v.orderId;
      _type = $v.type;
      _amount = $v.amount;
      _balanceAfter = $v.balanceAfter;
      _description = $v.description;
      _referenceId = $v.referenceId;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VendorWalletTransaction other) {
    _$v = other as _$VendorWalletTransaction;
  }

  @override
  void update(void Function(VendorWalletTransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VendorWalletTransaction build() => _build();

  _$VendorWalletTransaction _build() {
    final _$result =
        _$v ??
        _$VendorWalletTransaction._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'VendorWalletTransaction',
            'id',
          ),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'VendorWalletTransaction',
            'vendorId',
          ),
          orderId: orderId,
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'VendorWalletTransaction',
            'type',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'VendorWalletTransaction',
            'amount',
          ),
          balanceAfter: BuiltValueNullFieldError.checkNotNull(
            balanceAfter,
            r'VendorWalletTransaction',
            'balanceAfter',
          ),
          description: description,
          referenceId: referenceId,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'VendorWalletTransaction',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
