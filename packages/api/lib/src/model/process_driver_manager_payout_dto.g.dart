// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_driver_manager_payout_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProcessDriverManagerPayoutDto extends ProcessDriverManagerPayoutDto {
  @override
  final num? amount;
  @override
  final bool? settleFullBalance;
  @override
  final String? receiptUrl;
  @override
  final String? description;
  @override
  final String? idempotencyKey;

  factory _$ProcessDriverManagerPayoutDto([
    void Function(ProcessDriverManagerPayoutDtoBuilder)? updates,
  ]) => (ProcessDriverManagerPayoutDtoBuilder()..update(updates))._build();

  _$ProcessDriverManagerPayoutDto._({
    this.amount,
    this.settleFullBalance,
    this.receiptUrl,
    this.description,
    this.idempotencyKey,
  }) : super._();
  @override
  ProcessDriverManagerPayoutDto rebuild(
    void Function(ProcessDriverManagerPayoutDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProcessDriverManagerPayoutDtoBuilder toBuilder() =>
      ProcessDriverManagerPayoutDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProcessDriverManagerPayoutDto &&
        amount == other.amount &&
        settleFullBalance == other.settleFullBalance &&
        receiptUrl == other.receiptUrl &&
        description == other.description &&
        idempotencyKey == other.idempotencyKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, settleFullBalance.hashCode);
    _$hash = $jc(_$hash, receiptUrl.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, idempotencyKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProcessDriverManagerPayoutDto')
          ..add('amount', amount)
          ..add('settleFullBalance', settleFullBalance)
          ..add('receiptUrl', receiptUrl)
          ..add('description', description)
          ..add('idempotencyKey', idempotencyKey))
        .toString();
  }
}

class ProcessDriverManagerPayoutDtoBuilder
    implements
        Builder<
          ProcessDriverManagerPayoutDto,
          ProcessDriverManagerPayoutDtoBuilder
        > {
  _$ProcessDriverManagerPayoutDto? _$v;

  num? _amount;
  num? get amount => _$this._amount;
  set amount(num? amount) => _$this._amount = amount;

  bool? _settleFullBalance;
  bool? get settleFullBalance => _$this._settleFullBalance;
  set settleFullBalance(bool? settleFullBalance) =>
      _$this._settleFullBalance = settleFullBalance;

  String? _receiptUrl;
  String? get receiptUrl => _$this._receiptUrl;
  set receiptUrl(String? receiptUrl) => _$this._receiptUrl = receiptUrl;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _idempotencyKey;
  String? get idempotencyKey => _$this._idempotencyKey;
  set idempotencyKey(String? idempotencyKey) =>
      _$this._idempotencyKey = idempotencyKey;

  ProcessDriverManagerPayoutDtoBuilder() {
    ProcessDriverManagerPayoutDto._defaults(this);
  }

  ProcessDriverManagerPayoutDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amount = $v.amount;
      _settleFullBalance = $v.settleFullBalance;
      _receiptUrl = $v.receiptUrl;
      _description = $v.description;
      _idempotencyKey = $v.idempotencyKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProcessDriverManagerPayoutDto other) {
    _$v = other as _$ProcessDriverManagerPayoutDto;
  }

  @override
  void update(void Function(ProcessDriverManagerPayoutDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProcessDriverManagerPayoutDto build() => _build();

  _$ProcessDriverManagerPayoutDto _build() {
    final _$result =
        _$v ??
        _$ProcessDriverManagerPayoutDto._(
          amount: amount,
          settleFullBalance: settleFullBalance,
          receiptUrl: receiptUrl,
          description: description,
          idempotencyKey: idempotencyKey,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
