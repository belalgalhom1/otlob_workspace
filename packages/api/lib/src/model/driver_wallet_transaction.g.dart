// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_wallet_transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverWalletTransaction extends DriverWalletTransaction {
  @override
  final String id;
  @override
  final String driverId;
  @override
  final String? orderId;
  @override
  final String? deliveryGroupId;
  @override
  final String? driverShiftId;
  @override
  final WalletTransactionType type;
  @override
  final num amount;
  @override
  final num balanceAfter;
  @override
  final String? description;
  @override
  final String? note;
  @override
  final bool isManualAdjustment;
  @override
  final String? referenceId;
  @override
  final DateTime createdAt;

  factory _$DriverWalletTransaction([
    void Function(DriverWalletTransactionBuilder)? updates,
  ]) => (DriverWalletTransactionBuilder()..update(updates))._build();

  _$DriverWalletTransaction._({
    required this.id,
    required this.driverId,
    this.orderId,
    this.deliveryGroupId,
    this.driverShiftId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.note,
    required this.isManualAdjustment,
    this.referenceId,
    required this.createdAt,
  }) : super._();
  @override
  DriverWalletTransaction rebuild(
    void Function(DriverWalletTransactionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverWalletTransactionBuilder toBuilder() =>
      DriverWalletTransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverWalletTransaction &&
        id == other.id &&
        driverId == other.driverId &&
        orderId == other.orderId &&
        deliveryGroupId == other.deliveryGroupId &&
        driverShiftId == other.driverShiftId &&
        type == other.type &&
        amount == other.amount &&
        balanceAfter == other.balanceAfter &&
        description == other.description &&
        note == other.note &&
        isManualAdjustment == other.isManualAdjustment &&
        referenceId == other.referenceId &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, deliveryGroupId.hashCode);
    _$hash = $jc(_$hash, driverShiftId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, balanceAfter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, isManualAdjustment.hashCode);
    _$hash = $jc(_$hash, referenceId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverWalletTransaction')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('orderId', orderId)
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('driverShiftId', driverShiftId)
          ..add('type', type)
          ..add('amount', amount)
          ..add('balanceAfter', balanceAfter)
          ..add('description', description)
          ..add('note', note)
          ..add('isManualAdjustment', isManualAdjustment)
          ..add('referenceId', referenceId)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class DriverWalletTransactionBuilder
    implements
        Builder<DriverWalletTransaction, DriverWalletTransactionBuilder> {
  _$DriverWalletTransaction? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _deliveryGroupId;
  String? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(String? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  String? _driverShiftId;
  String? get driverShiftId => _$this._driverShiftId;
  set driverShiftId(String? driverShiftId) =>
      _$this._driverShiftId = driverShiftId;

  WalletTransactionType? _type;
  WalletTransactionType? get type => _$this._type;
  set type(WalletTransactionType? type) => _$this._type = type;

  num? _amount;
  num? get amount => _$this._amount;
  set amount(num? amount) => _$this._amount = amount;

  num? _balanceAfter;
  num? get balanceAfter => _$this._balanceAfter;
  set balanceAfter(num? balanceAfter) => _$this._balanceAfter = balanceAfter;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  bool? _isManualAdjustment;
  bool? get isManualAdjustment => _$this._isManualAdjustment;
  set isManualAdjustment(bool? isManualAdjustment) =>
      _$this._isManualAdjustment = isManualAdjustment;

  String? _referenceId;
  String? get referenceId => _$this._referenceId;
  set referenceId(String? referenceId) => _$this._referenceId = referenceId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DriverWalletTransactionBuilder() {
    DriverWalletTransaction._defaults(this);
  }

  DriverWalletTransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverId = $v.driverId;
      _orderId = $v.orderId;
      _deliveryGroupId = $v.deliveryGroupId;
      _driverShiftId = $v.driverShiftId;
      _type = $v.type;
      _amount = $v.amount;
      _balanceAfter = $v.balanceAfter;
      _description = $v.description;
      _note = $v.note;
      _isManualAdjustment = $v.isManualAdjustment;
      _referenceId = $v.referenceId;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverWalletTransaction other) {
    _$v = other as _$DriverWalletTransaction;
  }

  @override
  void update(void Function(DriverWalletTransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverWalletTransaction build() => _build();

  _$DriverWalletTransaction _build() {
    final _$result =
        _$v ??
        _$DriverWalletTransaction._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'DriverWalletTransaction',
            'id',
          ),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'DriverWalletTransaction',
            'driverId',
          ),
          orderId: orderId,
          deliveryGroupId: deliveryGroupId,
          driverShiftId: driverShiftId,
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'DriverWalletTransaction',
            'type',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'DriverWalletTransaction',
            'amount',
          ),
          balanceAfter: BuiltValueNullFieldError.checkNotNull(
            balanceAfter,
            r'DriverWalletTransaction',
            'balanceAfter',
          ),
          description: description,
          note: note,
          isManualAdjustment: BuiltValueNullFieldError.checkNotNull(
            isManualAdjustment,
            r'DriverWalletTransaction',
            'isManualAdjustment',
          ),
          referenceId: referenceId,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'DriverWalletTransaction',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
