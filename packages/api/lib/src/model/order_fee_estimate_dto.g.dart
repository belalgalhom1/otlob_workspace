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
        upfrontAmount == other.upfrontAmount;
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
          ..add('upfrontAmount', upfrontAmount))
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
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
