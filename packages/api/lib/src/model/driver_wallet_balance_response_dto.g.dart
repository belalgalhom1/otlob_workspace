// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_wallet_balance_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverWalletBalanceResponseDto extends DriverWalletBalanceResponseDto {
  @override
  final num walletBalance;

  factory _$DriverWalletBalanceResponseDto([
    void Function(DriverWalletBalanceResponseDtoBuilder)? updates,
  ]) => (DriverWalletBalanceResponseDtoBuilder()..update(updates))._build();

  _$DriverWalletBalanceResponseDto._({required this.walletBalance}) : super._();
  @override
  DriverWalletBalanceResponseDto rebuild(
    void Function(DriverWalletBalanceResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverWalletBalanceResponseDtoBuilder toBuilder() =>
      DriverWalletBalanceResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverWalletBalanceResponseDto &&
        walletBalance == other.walletBalance;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, walletBalance.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'DriverWalletBalanceResponseDto',
    )..add('walletBalance', walletBalance)).toString();
  }
}

class DriverWalletBalanceResponseDtoBuilder
    implements
        Builder<
          DriverWalletBalanceResponseDto,
          DriverWalletBalanceResponseDtoBuilder
        > {
  _$DriverWalletBalanceResponseDto? _$v;

  num? _walletBalance;
  num? get walletBalance => _$this._walletBalance;
  set walletBalance(num? walletBalance) =>
      _$this._walletBalance = walletBalance;

  DriverWalletBalanceResponseDtoBuilder() {
    DriverWalletBalanceResponseDto._defaults(this);
  }

  DriverWalletBalanceResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _walletBalance = $v.walletBalance;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverWalletBalanceResponseDto other) {
    _$v = other as _$DriverWalletBalanceResponseDto;
  }

  @override
  void update(void Function(DriverWalletBalanceResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverWalletBalanceResponseDto build() => _build();

  _$DriverWalletBalanceResponseDto _build() {
    final _$result =
        _$v ??
        _$DriverWalletBalanceResponseDto._(
          walletBalance: BuiltValueNullFieldError.checkNotNull(
            walletBalance,
            r'DriverWalletBalanceResponseDto',
            'walletBalance',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
