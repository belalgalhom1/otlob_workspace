// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_wallet_top_up_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateWalletTopUpDto extends CreateWalletTopUpDto {
  @override
  final String platformWalletId;
  @override
  final num amount;
  @override
  final String receiptUrl;

  factory _$CreateWalletTopUpDto([
    void Function(CreateWalletTopUpDtoBuilder)? updates,
  ]) => (CreateWalletTopUpDtoBuilder()..update(updates))._build();

  _$CreateWalletTopUpDto._({
    required this.platformWalletId,
    required this.amount,
    required this.receiptUrl,
  }) : super._();
  @override
  CreateWalletTopUpDto rebuild(
    void Function(CreateWalletTopUpDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateWalletTopUpDtoBuilder toBuilder() =>
      CreateWalletTopUpDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateWalletTopUpDto &&
        platformWalletId == other.platformWalletId &&
        amount == other.amount &&
        receiptUrl == other.receiptUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platformWalletId.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, receiptUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateWalletTopUpDto')
          ..add('platformWalletId', platformWalletId)
          ..add('amount', amount)
          ..add('receiptUrl', receiptUrl))
        .toString();
  }
}

class CreateWalletTopUpDtoBuilder
    implements Builder<CreateWalletTopUpDto, CreateWalletTopUpDtoBuilder> {
  _$CreateWalletTopUpDto? _$v;

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

  CreateWalletTopUpDtoBuilder() {
    CreateWalletTopUpDto._defaults(this);
  }

  CreateWalletTopUpDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platformWalletId = $v.platformWalletId;
      _amount = $v.amount;
      _receiptUrl = $v.receiptUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateWalletTopUpDto other) {
    _$v = other as _$CreateWalletTopUpDto;
  }

  @override
  void update(void Function(CreateWalletTopUpDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateWalletTopUpDto build() => _build();

  _$CreateWalletTopUpDto _build() {
    final _$result =
        _$v ??
        _$CreateWalletTopUpDto._(
          platformWalletId: BuiltValueNullFieldError.checkNotNull(
            platformWalletId,
            r'CreateWalletTopUpDto',
            'platformWalletId',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'CreateWalletTopUpDto',
            'amount',
          ),
          receiptUrl: BuiltValueNullFieldError.checkNotNull(
            receiptUrl,
            r'CreateWalletTopUpDto',
            'receiptUrl',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
