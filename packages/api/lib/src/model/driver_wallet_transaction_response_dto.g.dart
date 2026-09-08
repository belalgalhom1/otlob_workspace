// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_wallet_transaction_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverWalletTransactionResponseDto
    extends DriverWalletTransactionResponseDto {
  @override
  final String id;
  @override
  final String driverId;
  @override
  final String? orderId;
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
  final String? referenceId;
  @override
  final DateTime createdAt;
  @override
  final Driver? driver;
  @override
  final DriverShift? driverShift;
  @override
  final Order? order;

  factory _$DriverWalletTransactionResponseDto([
    void Function(DriverWalletTransactionResponseDtoBuilder)? updates,
  ]) => (DriverWalletTransactionResponseDtoBuilder()..update(updates))._build();

  _$DriverWalletTransactionResponseDto._({
    required this.id,
    required this.driverId,
    this.orderId,
    this.driverShiftId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceId,
    required this.createdAt,
    this.driver,
    this.driverShift,
    this.order,
  }) : super._();
  @override
  DriverWalletTransactionResponseDto rebuild(
    void Function(DriverWalletTransactionResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverWalletTransactionResponseDtoBuilder toBuilder() =>
      DriverWalletTransactionResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverWalletTransactionResponseDto &&
        id == other.id &&
        driverId == other.driverId &&
        orderId == other.orderId &&
        driverShiftId == other.driverShiftId &&
        type == other.type &&
        amount == other.amount &&
        balanceAfter == other.balanceAfter &&
        description == other.description &&
        referenceId == other.referenceId &&
        createdAt == other.createdAt &&
        driver == other.driver &&
        driverShift == other.driverShift &&
        order == other.order;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, driverShiftId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, balanceAfter.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, referenceId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, driver.hashCode);
    _$hash = $jc(_$hash, driverShift.hashCode);
    _$hash = $jc(_$hash, order.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverWalletTransactionResponseDto')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('orderId', orderId)
          ..add('driverShiftId', driverShiftId)
          ..add('type', type)
          ..add('amount', amount)
          ..add('balanceAfter', balanceAfter)
          ..add('description', description)
          ..add('referenceId', referenceId)
          ..add('createdAt', createdAt)
          ..add('driver', driver)
          ..add('driverShift', driverShift)
          ..add('order', order))
        .toString();
  }
}

class DriverWalletTransactionResponseDtoBuilder
    implements
        Builder<
          DriverWalletTransactionResponseDto,
          DriverWalletTransactionResponseDtoBuilder
        > {
  _$DriverWalletTransactionResponseDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

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

  String? _referenceId;
  String? get referenceId => _$this._referenceId;
  set referenceId(String? referenceId) => _$this._referenceId = referenceId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DriverBuilder? _driver;
  DriverBuilder get driver => _$this._driver ??= DriverBuilder();
  set driver(DriverBuilder? driver) => _$this._driver = driver;

  DriverShiftBuilder? _driverShift;
  DriverShiftBuilder get driverShift =>
      _$this._driverShift ??= DriverShiftBuilder();
  set driverShift(DriverShiftBuilder? driverShift) =>
      _$this._driverShift = driverShift;

  OrderBuilder? _order;
  OrderBuilder get order => _$this._order ??= OrderBuilder();
  set order(OrderBuilder? order) => _$this._order = order;

  DriverWalletTransactionResponseDtoBuilder() {
    DriverWalletTransactionResponseDto._defaults(this);
  }

  DriverWalletTransactionResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverId = $v.driverId;
      _orderId = $v.orderId;
      _driverShiftId = $v.driverShiftId;
      _type = $v.type;
      _amount = $v.amount;
      _balanceAfter = $v.balanceAfter;
      _description = $v.description;
      _referenceId = $v.referenceId;
      _createdAt = $v.createdAt;
      _driver = $v.driver?.toBuilder();
      _driverShift = $v.driverShift?.toBuilder();
      _order = $v.order?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverWalletTransactionResponseDto other) {
    _$v = other as _$DriverWalletTransactionResponseDto;
  }

  @override
  void update(
    void Function(DriverWalletTransactionResponseDtoBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  DriverWalletTransactionResponseDto build() => _build();

  _$DriverWalletTransactionResponseDto _build() {
    _$DriverWalletTransactionResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverWalletTransactionResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'DriverWalletTransactionResponseDto',
              'id',
            ),
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'DriverWalletTransactionResponseDto',
              'driverId',
            ),
            orderId: orderId,
            driverShiftId: driverShiftId,
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'DriverWalletTransactionResponseDto',
              'type',
            ),
            amount: BuiltValueNullFieldError.checkNotNull(
              amount,
              r'DriverWalletTransactionResponseDto',
              'amount',
            ),
            balanceAfter: BuiltValueNullFieldError.checkNotNull(
              balanceAfter,
              r'DriverWalletTransactionResponseDto',
              'balanceAfter',
            ),
            description: description,
            referenceId: referenceId,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'DriverWalletTransactionResponseDto',
              'createdAt',
            ),
            driver: _driver?.build(),
            driverShift: _driverShift?.build(),
            order: _order?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'driver';
        _driver?.build();
        _$failedField = 'driverShift';
        _driverShift?.build();
        _$failedField = 'order';
        _order?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverWalletTransactionResponseDto',
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
