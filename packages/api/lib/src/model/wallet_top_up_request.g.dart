// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_top_up_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WalletTopUpRequest extends WalletTopUpRequest {
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

  factory _$WalletTopUpRequest([
    void Function(WalletTopUpRequestBuilder)? updates,
  ]) => (WalletTopUpRequestBuilder()..update(updates))._build();

  _$WalletTopUpRequest._({
    required this.id,
    required this.driverId,
    required this.platformWalletId,
    required this.amount,
    required this.receiptUrl,
    required this.status,
    this.approvedById,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  WalletTopUpRequest rebuild(
    void Function(WalletTopUpRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WalletTopUpRequestBuilder toBuilder() =>
      WalletTopUpRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WalletTopUpRequest &&
        id == other.id &&
        driverId == other.driverId &&
        platformWalletId == other.platformWalletId &&
        amount == other.amount &&
        receiptUrl == other.receiptUrl &&
        status == other.status &&
        approvedById == other.approvedById &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WalletTopUpRequest')
          ..add('id', id)
          ..add('driverId', driverId)
          ..add('platformWalletId', platformWalletId)
          ..add('amount', amount)
          ..add('receiptUrl', receiptUrl)
          ..add('status', status)
          ..add('approvedById', approvedById)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class WalletTopUpRequestBuilder
    implements Builder<WalletTopUpRequest, WalletTopUpRequestBuilder> {
  _$WalletTopUpRequest? _$v;

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

  WalletTopUpRequestBuilder() {
    WalletTopUpRequest._defaults(this);
  }

  WalletTopUpRequestBuilder get _$this {
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
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WalletTopUpRequest other) {
    _$v = other as _$WalletTopUpRequest;
  }

  @override
  void update(void Function(WalletTopUpRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WalletTopUpRequest build() => _build();

  _$WalletTopUpRequest _build() {
    final _$result =
        _$v ??
        _$WalletTopUpRequest._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'WalletTopUpRequest',
            'id',
          ),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'WalletTopUpRequest',
            'driverId',
          ),
          platformWalletId: BuiltValueNullFieldError.checkNotNull(
            platformWalletId,
            r'WalletTopUpRequest',
            'platformWalletId',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'WalletTopUpRequest',
            'amount',
          ),
          receiptUrl: BuiltValueNullFieldError.checkNotNull(
            receiptUrl,
            r'WalletTopUpRequest',
            'receiptUrl',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'WalletTopUpRequest',
            'status',
          ),
          approvedById: approvedById,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'WalletTopUpRequest',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'WalletTopUpRequest',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
