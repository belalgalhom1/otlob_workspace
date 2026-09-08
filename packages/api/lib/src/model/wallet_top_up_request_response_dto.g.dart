// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_top_up_request_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WalletTopUpRequestResponseDto extends WalletTopUpRequestResponseDto {
  @override
  final String id;
  @override
  final String driverId;
  @override
  final String platformWalletId;
  @override
  final num amount;
  @override
  final String receiptUrl;
  @override
  final TopUpStatus status;
  @override
  final String? approvedById;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final Driver? driver;
  @override
  final MobileWallet? platformWallet;
  @override
  final User? approvedBy;

  factory _$WalletTopUpRequestResponseDto([
    void Function(WalletTopUpRequestResponseDtoBuilder)? updates,
  ]) => (WalletTopUpRequestResponseDtoBuilder()..update(updates))._build();

  _$WalletTopUpRequestResponseDto._({
    required this.id,
    required this.driverId,
    required this.platformWalletId,
    required this.amount,
    required this.receiptUrl,
    required this.status,
    this.approvedById,
    required this.createdAt,
    required this.updatedAt,
    this.driver,
    this.platformWallet,
    this.approvedBy,
  }) : super._();
  @override
  WalletTopUpRequestResponseDto rebuild(
    void Function(WalletTopUpRequestResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WalletTopUpRequestResponseDtoBuilder toBuilder() =>
      WalletTopUpRequestResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WalletTopUpRequestResponseDto &&
        id == other.id &&
        driverId == other.driverId &&
        platformWalletId == other.platformWalletId &&
        amount == other.amount &&
        receiptUrl == other.receiptUrl &&
        status == other.status &&
        approvedById == other.approvedById &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        driver == other.driver &&
        platformWallet == other.platformWallet &&
        approvedBy == other.approvedBy;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, platformWalletId.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, receiptUrl.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, approvedById.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, driver.hashCode);
    _$hash = $jc(_$hash, platformWallet.hashCode);
    _$hash = $jc(_$hash, approvedBy.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WalletTopUpRequestResponseDto')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('platformWalletId', platformWalletId)
          ..add('amount', amount)
          ..add('receiptUrl', receiptUrl)
          ..add('status', status)
          ..add('approvedById', approvedById)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('driver', driver)
          ..add('platformWallet', platformWallet)
          ..add('approvedBy', approvedBy))
        .toString();
  }
}

class WalletTopUpRequestResponseDtoBuilder
    implements
        Builder<
          WalletTopUpRequestResponseDto,
          WalletTopUpRequestResponseDtoBuilder
        > {
  _$WalletTopUpRequestResponseDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _platformWalletId;
  String? get platformWalletId => _$this._platformWalletId;
  set platformWalletId(String? platformWalletId) =>
      _$this._platformWalletId = platformWalletId;

  num? _amount;
  num? get amount => _$this._amount;
  set amount(num? amount) => _$this._amount = amount;

  String? _receiptUrl;
  String? get receiptUrl => _$this._receiptUrl;
  set receiptUrl(String? receiptUrl) => _$this._receiptUrl = receiptUrl;

  TopUpStatus? _status;
  TopUpStatus? get status => _$this._status;
  set status(TopUpStatus? status) => _$this._status = status;

  String? _approvedById;
  String? get approvedById => _$this._approvedById;
  set approvedById(String? approvedById) => _$this._approvedById = approvedById;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DriverBuilder? _driver;
  DriverBuilder get driver => _$this._driver ??= DriverBuilder();
  set driver(DriverBuilder? driver) => _$this._driver = driver;

  MobileWalletBuilder? _platformWallet;
  MobileWalletBuilder get platformWallet =>
      _$this._platformWallet ??= MobileWalletBuilder();
  set platformWallet(MobileWalletBuilder? platformWallet) =>
      _$this._platformWallet = platformWallet;

  UserBuilder? _approvedBy;
  UserBuilder get approvedBy => _$this._approvedBy ??= UserBuilder();
  set approvedBy(UserBuilder? approvedBy) => _$this._approvedBy = approvedBy;

  WalletTopUpRequestResponseDtoBuilder() {
    WalletTopUpRequestResponseDto._defaults(this);
  }

  WalletTopUpRequestResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _driverId = $v.driverId;
      _platformWalletId = $v.platformWalletId;
      _amount = $v.amount;
      _receiptUrl = $v.receiptUrl;
      _status = $v.status;
      _approvedById = $v.approvedById;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _driver = $v.driver?.toBuilder();
      _platformWallet = $v.platformWallet?.toBuilder();
      _approvedBy = $v.approvedBy?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WalletTopUpRequestResponseDto other) {
    _$v = other as _$WalletTopUpRequestResponseDto;
  }

  @override
  void update(void Function(WalletTopUpRequestResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WalletTopUpRequestResponseDto build() => _build();

  _$WalletTopUpRequestResponseDto _build() {
    _$WalletTopUpRequestResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$WalletTopUpRequestResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'WalletTopUpRequestResponseDto',
              'id',
            ),
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'WalletTopUpRequestResponseDto',
              'driverId',
            ),
            platformWalletId: BuiltValueNullFieldError.checkNotNull(
              platformWalletId,
              r'WalletTopUpRequestResponseDto',
              'platformWalletId',
            ),
            amount: BuiltValueNullFieldError.checkNotNull(
              amount,
              r'WalletTopUpRequestResponseDto',
              'amount',
            ),
            receiptUrl: BuiltValueNullFieldError.checkNotNull(
              receiptUrl,
              r'WalletTopUpRequestResponseDto',
              'receiptUrl',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'WalletTopUpRequestResponseDto',
              'status',
            ),
            approvedById: approvedById,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'WalletTopUpRequestResponseDto',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'WalletTopUpRequestResponseDto',
              'updatedAt',
            ),
            driver: _driver?.build(),
            platformWallet: _platformWallet?.build(),
            approvedBy: _approvedBy?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'driver';
        _driver?.build();
        _$failedField = 'platformWallet';
        _platformWallet?.build();
        _$failedField = 'approvedBy';
        _approvedBy?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'WalletTopUpRequestResponseDto',
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
