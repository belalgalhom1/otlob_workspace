// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_offer_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateOfferDto extends CreateOfferDto {
  @override
  final String productId;
  @override
  final String vendorId;
  @override
  final num originalPrice;
  @override
  final num offerPrice;
  @override
  final num? sortOrder;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;

  factory _$CreateOfferDto([void Function(CreateOfferDtoBuilder)? updates]) =>
      (CreateOfferDtoBuilder()..update(updates))._build();

  _$CreateOfferDto._({
    required this.productId,
    required this.vendorId,
    required this.originalPrice,
    required this.offerPrice,
    this.sortOrder,
    this.startDate,
    this.endDate,
  }) : super._();
  @override
  CreateOfferDto rebuild(void Function(CreateOfferDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateOfferDtoBuilder toBuilder() => CreateOfferDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateOfferDto &&
        productId == other.productId &&
        vendorId == other.vendorId &&
        originalPrice == other.originalPrice &&
        offerPrice == other.offerPrice &&
        sortOrder == other.sortOrder &&
        startDate == other.startDate &&
        endDate == other.endDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, originalPrice.hashCode);
    _$hash = $jc(_$hash, offerPrice.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateOfferDto')
          ..add('productId', productId)
          ..add('vendorId', vendorId)
          ..add('originalPrice', originalPrice)
          ..add('offerPrice', offerPrice)
          ..add('sortOrder', sortOrder)
          ..add('startDate', startDate)
          ..add('endDate', endDate))
        .toString();
  }
}

class CreateOfferDtoBuilder
    implements Builder<CreateOfferDto, CreateOfferDtoBuilder> {
  _$CreateOfferDto? _$v;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  num? _originalPrice;
  num? get originalPrice => _$this._originalPrice;
  set originalPrice(num? originalPrice) =>
      _$this._originalPrice = originalPrice;

  num? _offerPrice;
  num? get offerPrice => _$this._offerPrice;
  set offerPrice(num? offerPrice) => _$this._offerPrice = offerPrice;

  num? _sortOrder;
  num? get sortOrder => _$this._sortOrder;
  set sortOrder(num? sortOrder) => _$this._sortOrder = sortOrder;

  DateTime? _startDate;
  DateTime? get startDate => _$this._startDate;
  set startDate(DateTime? startDate) => _$this._startDate = startDate;

  DateTime? _endDate;
  DateTime? get endDate => _$this._endDate;
  set endDate(DateTime? endDate) => _$this._endDate = endDate;

  CreateOfferDtoBuilder() {
    CreateOfferDto._defaults(this);
  }

  CreateOfferDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _productId = $v.productId;
      _vendorId = $v.vendorId;
      _originalPrice = $v.originalPrice;
      _offerPrice = $v.offerPrice;
      _sortOrder = $v.sortOrder;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateOfferDto other) {
    _$v = other as _$CreateOfferDto;
  }

  @override
  void update(void Function(CreateOfferDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateOfferDto build() => _build();

  _$CreateOfferDto _build() {
    final _$result =
        _$v ??
        _$CreateOfferDto._(
          productId: BuiltValueNullFieldError.checkNotNull(
            productId,
            r'CreateOfferDto',
            'productId',
          ),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'CreateOfferDto',
            'vendorId',
          ),
          originalPrice: BuiltValueNullFieldError.checkNotNull(
            originalPrice,
            r'CreateOfferDto',
            'originalPrice',
          ),
          offerPrice: BuiltValueNullFieldError.checkNotNull(
            offerPrice,
            r'CreateOfferDto',
            'offerPrice',
          ),
          sortOrder: sortOrder,
          startDate: startDate,
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
