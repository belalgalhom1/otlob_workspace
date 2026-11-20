// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_wallet_transactions_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverWalletTransactionsResponseDto
    extends DriverWalletTransactionsResponseDto {
  @override
  final num walletBalance;
  @override
  final BuiltList<DriverWalletTransactionResponseDto> transactions;
  @override
  final num total;
  @override
  final num page;
  @override
  final num limit;
  @override
  final num totalPages;

  factory _$DriverWalletTransactionsResponseDto([
    void Function(DriverWalletTransactionsResponseDtoBuilder)? updates,
  ]) =>
      (DriverWalletTransactionsResponseDtoBuilder()..update(updates))._build();

  _$DriverWalletTransactionsResponseDto._({
    required this.walletBalance,
    required this.transactions,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  }) : super._();
  @override
  DriverWalletTransactionsResponseDto rebuild(
    void Function(DriverWalletTransactionsResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverWalletTransactionsResponseDtoBuilder toBuilder() =>
      DriverWalletTransactionsResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverWalletTransactionsResponseDto &&
        walletBalance == other.walletBalance &&
        transactions == other.transactions &&
        total == other.total &&
        page == other.page &&
        limit == other.limit &&
        totalPages == other.totalPages;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, walletBalance.hashCode);
    _$hash = $jc(_$hash, transactions.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, limit.hashCode);
    _$hash = $jc(_$hash, totalPages.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverWalletTransactionsResponseDto')
          ..add('walletBalance', walletBalance)
          ..add('transactions', transactions)
          ..add('total', total)
          ..add('page', page)
          ..add('limit', limit)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class DriverWalletTransactionsResponseDtoBuilder
    implements
        Builder<
          DriverWalletTransactionsResponseDto,
          DriverWalletTransactionsResponseDtoBuilder
        > {
  _$DriverWalletTransactionsResponseDto? _$v;

  num? _walletBalance;
  num? get walletBalance => _$this._walletBalance;
  set walletBalance(num? walletBalance) =>
      _$this._walletBalance = walletBalance;

  ListBuilder<DriverWalletTransactionResponseDto>? _transactions;
  ListBuilder<DriverWalletTransactionResponseDto> get transactions =>
      _$this._transactions ??=
          ListBuilder<DriverWalletTransactionResponseDto>();
  set transactions(
    ListBuilder<DriverWalletTransactionResponseDto>? transactions,
  ) => _$this._transactions = transactions;

  num? _total;
  num? get total => _$this._total;
  set total(num? total) => _$this._total = total;

  num? _page;
  num? get page => _$this._page;
  set page(num? page) => _$this._page = page;

  num? _limit;
  num? get limit => _$this._limit;
  set limit(num? limit) => _$this._limit = limit;

  num? _totalPages;
  num? get totalPages => _$this._totalPages;
  set totalPages(num? totalPages) => _$this._totalPages = totalPages;

  DriverWalletTransactionsResponseDtoBuilder() {
    DriverWalletTransactionsResponseDto._defaults(this);
  }

  DriverWalletTransactionsResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _walletBalance = $v.walletBalance;
      _transactions = $v.transactions.toBuilder();
      _total = $v.total;
      _page = $v.page;
      _limit = $v.limit;
      _totalPages = $v.totalPages;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverWalletTransactionsResponseDto other) {
    _$v = other as _$DriverWalletTransactionsResponseDto;
  }

  @override
  void update(
    void Function(DriverWalletTransactionsResponseDtoBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  DriverWalletTransactionsResponseDto build() => _build();

  _$DriverWalletTransactionsResponseDto _build() {
    _$DriverWalletTransactionsResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$DriverWalletTransactionsResponseDto._(
            walletBalance: BuiltValueNullFieldError.checkNotNull(
              walletBalance,
              r'DriverWalletTransactionsResponseDto',
              'walletBalance',
            ),
            transactions: transactions.build(),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'DriverWalletTransactionsResponseDto',
              'total',
            ),
            page: BuiltValueNullFieldError.checkNotNull(
              page,
              r'DriverWalletTransactionsResponseDto',
              'page',
            ),
            limit: BuiltValueNullFieldError.checkNotNull(
              limit,
              r'DriverWalletTransactionsResponseDto',
              'limit',
            ),
            totalPages: BuiltValueNullFieldError.checkNotNull(
              totalPages,
              r'DriverWalletTransactionsResponseDto',
              'totalPages',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'transactions';
        transactions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DriverWalletTransactionsResponseDto',
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
