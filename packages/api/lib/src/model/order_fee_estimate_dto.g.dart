// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_fee_estimate_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderFeeEstimateDto extends OrderFeeEstimateDto {
  @override
  final num distanceKm;
  @override
  final num deliveryFee;
  @override
  final num serviceFee;
  @override
  final num driverBonusFee;
  @override
  final num tax;
  @override
  final num coinsUsed;
  @override
  final num discount;
  @override
  final num coinsEarned;
  @override
  final num grandTotal;
  @override
  final num upfrontAmount;
  @override
  final num? subtotal;
  @override
  final bool? isSplit;
  @override
  final num? vendorCount;
  @override
  final num? branchCount;
  @override
  final num? deliveryCount;
  @override
  final bool? driverBonusPaidByCustomer;

  factory _$OrderFeeEstimateDto([
    void Function(OrderFeeEstimateDtoBuilder)? updates,
  ]) => (OrderFeeEstimateDtoBuilder()..update(updates))._build();

  _$OrderFeeEstimateDto._({
    required this.distanceKm,
    required this.deliveryFee,
    required this.serviceFee,
    required this.driverBonusFee,
    required this.tax,
    required this.coinsUsed,
    required this.discount,
    required this.coinsEarned,
    required this.grandTotal,
    required this.upfrontAmount,
    this.subtotal,
    this.isSplit,
    this.vendorCount,
    this.branchCount,
    this.deliveryCount,
    this.driverBonusPaidByCustomer,
  }) : super._();
  @override
  OrderFeeEstimateDto rebuild(
    void Function(OrderFeeEstimateDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderFeeEstimateDtoBuilder toBuilder() =>
      OrderFeeEstimateDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderFeeEstimateDto &&
        distanceKm == other.distanceKm &&
        deliveryFee == other.deliveryFee &&
        serviceFee == other.serviceFee &&
        driverBonusFee == other.driverBonusFee &&
        tax == other.tax &&
        coinsUsed == other.coinsUsed &&
        discount == other.discount &&
        coinsEarned == other.coinsEarned &&
        grandTotal == other.grandTotal &&
        upfrontAmount == other.upfrontAmount &&
        subtotal == other.subtotal &&
        isSplit == other.isSplit &&
        vendorCount == other.vendorCount &&
        branchCount == other.branchCount &&
        deliveryCount == other.deliveryCount &&
        driverBonusPaidByCustomer == other.driverBonusPaidByCustomer;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, distanceKm.hashCode);
    _$hash = $jc(_$hash, deliveryFee.hashCode);
    _$hash = $jc(_$hash, serviceFee.hashCode);
    _$hash = $jc(_$hash, driverBonusFee.hashCode);
    _$hash = $jc(_$hash, tax.hashCode);
    _$hash = $jc(_$hash, coinsUsed.hashCode);
    _$hash = $jc(_$hash, discount.hashCode);
    _$hash = $jc(_$hash, coinsEarned.hashCode);
    _$hash = $jc(_$hash, grandTotal.hashCode);
    _$hash = $jc(_$hash, upfrontAmount.hashCode);
    _$hash = $jc(_$hash, subtotal.hashCode);
    _$hash = $jc(_$hash, isSplit.hashCode);
    _$hash = $jc(_$hash, vendorCount.hashCode);
    _$hash = $jc(_$hash, branchCount.hashCode);
    _$hash = $jc(_$hash, deliveryCount.hashCode);
    _$hash = $jc(_$hash, driverBonusPaidByCustomer.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderFeeEstimateDto')
          ..add('distanceKm', distanceKm)
          ..add('deliveryFee', deliveryFee)
          ..add('serviceFee', serviceFee)
          ..add('driverBonusFee', driverBonusFee)
          ..add('tax', tax)
          ..add('coinsUsed', coinsUsed)
          ..add('discount', discount)
          ..add('coinsEarned', coinsEarned)
          ..add('grandTotal', grandTotal)
          ..add('upfrontAmount', upfrontAmount)
          ..add('subtotal', subtotal)
          ..add('isSplit', isSplit)
          ..add('vendorCount', vendorCount)
          ..add('branchCount', branchCount)
          ..add('deliveryCount', deliveryCount)
          ..add('driverBonusPaidByCustomer', driverBonusPaidByCustomer))
        .toString();
  }
}

class OrderFeeEstimateDtoBuilder
    implements Builder<OrderFeeEstimateDto, OrderFeeEstimateDtoBuilder> {
  _$OrderFeeEstimateDto? _$v;

  num? _distanceKm;
  num? get distanceKm => _$this._distanceKm;
  set distanceKm(num? distanceKm) => _$this._distanceKm = distanceKm;

  num? _deliveryFee;
  num? get deliveryFee => _$this._deliveryFee;
  set deliveryFee(num? deliveryFee) => _$this._deliveryFee = deliveryFee;

  num? _serviceFee;
  num? get serviceFee => _$this._serviceFee;
  set serviceFee(num? serviceFee) => _$this._serviceFee = serviceFee;

  num? _driverBonusFee;
  num? get driverBonusFee => _$this._driverBonusFee;
  set driverBonusFee(num? driverBonusFee) =>
      _$this._driverBonusFee = driverBonusFee;

  num? _tax;
  num? get tax => _$this._tax;
  set tax(num? tax) => _$this._tax = tax;

  num? _coinsUsed;
  num? get coinsUsed => _$this._coinsUsed;
  set coinsUsed(num? coinsUsed) => _$this._coinsUsed = coinsUsed;

  num? _discount;
  num? get discount => _$this._discount;
  set discount(num? discount) => _$this._discount = discount;

  num? _coinsEarned;
  num? get coinsEarned => _$this._coinsEarned;
  set coinsEarned(num? coinsEarned) => _$this._coinsEarned = coinsEarned;

  num? _grandTotal;
  num? get grandTotal => _$this._grandTotal;
  set grandTotal(num? grandTotal) => _$this._grandTotal = grandTotal;

  num? _upfrontAmount;
  num? get upfrontAmount => _$this._upfrontAmount;
  set upfrontAmount(num? upfrontAmount) =>
      _$this._upfrontAmount = upfrontAmount;

  num? _subtotal;
  num? get subtotal => _$this._subtotal;
  set subtotal(num? subtotal) => _$this._subtotal = subtotal;

  bool? _isSplit;
  bool? get isSplit => _$this._isSplit;
  set isSplit(bool? isSplit) => _$this._isSplit = isSplit;

  num? _vendorCount;
  num? get vendorCount => _$this._vendorCount;
  set vendorCount(num? vendorCount) => _$this._vendorCount = vendorCount;

  num? _branchCount;
  num? get branchCount => _$this._branchCount;
  set branchCount(num? branchCount) => _$this._branchCount = branchCount;

  num? _deliveryCount;
  num? get deliveryCount => _$this._deliveryCount;
  set deliveryCount(num? deliveryCount) =>
      _$this._deliveryCount = deliveryCount;

  bool? _driverBonusPaidByCustomer;
  bool? get driverBonusPaidByCustomer => _$this._driverBonusPaidByCustomer;
  set driverBonusPaidByCustomer(bool? driverBonusPaidByCustomer) =>
      _$this._driverBonusPaidByCustomer = driverBonusPaidByCustomer;

  OrderFeeEstimateDtoBuilder() {
    OrderFeeEstimateDto._defaults(this);
  }

  OrderFeeEstimateDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _distanceKm = $v.distanceKm;
      _deliveryFee = $v.deliveryFee;
      _serviceFee = $v.serviceFee;
      _driverBonusFee = $v.driverBonusFee;
      _tax = $v.tax;
      _coinsUsed = $v.coinsUsed;
      _discount = $v.discount;
      _coinsEarned = $v.coinsEarned;
      _grandTotal = $v.grandTotal;
      _upfrontAmount = $v.upfrontAmount;
      _subtotal = $v.subtotal;
      _isSplit = $v.isSplit;
      _vendorCount = $v.vendorCount;
      _branchCount = $v.branchCount;
      _deliveryCount = $v.deliveryCount;
      _driverBonusPaidByCustomer = $v.driverBonusPaidByCustomer;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderFeeEstimateDto other) {
    _$v = other as _$OrderFeeEstimateDto;
  }

  @override
  void update(void Function(OrderFeeEstimateDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderFeeEstimateDto build() => _build();

  _$OrderFeeEstimateDto _build() {
    final _$result =
        _$v ??
        _$OrderFeeEstimateDto._(
          distanceKm: BuiltValueNullFieldError.checkNotNull(
            distanceKm,
            r'OrderFeeEstimateDto',
            'distanceKm',
          ),
          deliveryFee: BuiltValueNullFieldError.checkNotNull(
            deliveryFee,
            r'OrderFeeEstimateDto',
            'deliveryFee',
          ),
          serviceFee: BuiltValueNullFieldError.checkNotNull(
            serviceFee,
            r'OrderFeeEstimateDto',
            'serviceFee',
          ),
          driverBonusFee: BuiltValueNullFieldError.checkNotNull(
            driverBonusFee,
            r'OrderFeeEstimateDto',
            'driverBonusFee',
          ),
          tax: BuiltValueNullFieldError.checkNotNull(
            tax,
            r'OrderFeeEstimateDto',
            'tax',
          ),
          coinsUsed: BuiltValueNullFieldError.checkNotNull(
            coinsUsed,
            r'OrderFeeEstimateDto',
            'coinsUsed',
          ),
          discount: BuiltValueNullFieldError.checkNotNull(
            discount,
            r'OrderFeeEstimateDto',
            'discount',
          ),
          coinsEarned: BuiltValueNullFieldError.checkNotNull(
            coinsEarned,
            r'OrderFeeEstimateDto',
            'coinsEarned',
          ),
          grandTotal: BuiltValueNullFieldError.checkNotNull(
            grandTotal,
            r'OrderFeeEstimateDto',
            'grandTotal',
          ),
          upfrontAmount: BuiltValueNullFieldError.checkNotNull(
            upfrontAmount,
            r'OrderFeeEstimateDto',
            'upfrontAmount',
          ),
          subtotal: subtotal,
          isSplit: isSplit,
          vendorCount: vendorCount,
          branchCount: branchCount,
          deliveryCount: deliveryCount,
          driverBonusPaidByCustomer: driverBonusPaidByCustomer,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
