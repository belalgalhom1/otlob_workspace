// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_wallet_transaction_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VendorWalletTransactionResponseDto
    extends VendorWalletTransactionResponseDto {
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
  @override
  final Order? order;
  @override
  final Vendor? vendor;

  factory _$VendorWalletTransactionResponseDto([
    void Function(VendorWalletTransactionResponseDtoBuilder)? updates,
  ]) => (VendorWalletTransactionResponseDtoBuilder()..update(updates))._build();

  _$VendorWalletTransactionResponseDto._({
    required this.id,
    required this.vendorId,
    this.orderId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    required this.createdAt,
    this.order,
    this.vendor,
  }) : super._();
  @override
  VendorWalletTransactionResponseDto rebuild(
    void Function(VendorWalletTransactionResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  VendorWalletTransactionResponseDtoBuilder toBuilder() =>
      VendorWalletTransactionResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VendorWalletTransactionResponseDto &&
        id == other.id &&
        vendorId == other.vendorId &&
        orderId == other.orderId &&
        type == other.type &&
        amount == other.amount &&
        balanceAfter == other.balanceAfter &&
        description == other.description &&
        referenceId == other.referenceId &&
        createdAt == other.createdAt &&
        order == other.order &&
        vendor == other.vendor;
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
    _$hash = $jc(_$hash, order.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VendorWalletTransactionResponseDto')
          ..add('id', id)
          ..add('vendorId', vendorId)
          ..add('orderId', orderId)
          ..add('type', type)
          ..add('amount', amount)
          ..add('balanceAfter', balanceAfter)
          ..add('description', description)
          ..add('referenceId', referenceId)
          ..add('createdAt', createdAt)
          ..add('order', order)
          ..add('vendor', vendor))
        .toString();
  }
}

class VendorWalletTransactionResponseDtoBuilder
    implements
        Builder<
          VendorWalletTransactionResponseDto,
          VendorWalletTransactionResponseDtoBuilder
        > {
  _$VendorWalletTransactionResponseDto? _$v;

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

  OrderBuilder? _order;
  OrderBuilder get order => _$this._order ??= OrderBuilder();
  set order(OrderBuilder? order) => _$this._order = order;

  VendorBuilder? _vendor;
  VendorBuilder get vendor => _$this._vendor ??= VendorBuilder();
  set vendor(VendorBuilder? vendor) => _$this._vendor = vendor;

  VendorWalletTransactionResponseDtoBuilder() {
    VendorWalletTransactionResponseDto._defaults(this);
  }

  VendorWalletTransactionResponseDtoBuilder get _$this {
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
      _order = $v.order?.toBuilder();
      _vendor = $v.vendor?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VendorWalletTransactionResponseDto other) {
    _$v = other as _$VendorWalletTransactionResponseDto;
  }

  @override
  void update(
    void Function(VendorWalletTransactionResponseDtoBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  VendorWalletTransactionResponseDto build() => _build();

  _$VendorWalletTransactionResponseDto _build() {
    _$VendorWalletTransactionResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$VendorWalletTransactionResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'VendorWalletTransactionResponseDto',
              'id',
            ),
            vendorId: BuiltValueNullFieldError.checkNotNull(
              vendorId,
              r'VendorWalletTransactionResponseDto',
              'vendorId',
            ),
            orderId: orderId,
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'VendorWalletTransactionResponseDto',
              'type',
            ),
            amount: BuiltValueNullFieldError.checkNotNull(
              amount,
              r'VendorWalletTransactionResponseDto',
              'amount',
            ),
            balanceAfter: BuiltValueNullFieldError.checkNotNull(
              balanceAfter,
              r'VendorWalletTransactionResponseDto',
              'balanceAfter',
            ),
            description: description,
            referenceId: referenceId,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'VendorWalletTransactionResponseDto',
              'createdAt',
            ),
            order: _order?.build(),
            vendor: _vendor?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'order';
        _order?.build();
        _$failedField = 'vendor';
        _vendor?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'VendorWalletTransactionResponseDto',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
