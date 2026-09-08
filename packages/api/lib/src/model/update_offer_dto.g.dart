// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_offer_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateOfferDto extends UpdateOfferDto {
  @override
  final String? variantId;
  @override
  final num? originalPrice;
  @override
  final num? offerPrice;
  @override
  final bool? isActive;
  @override
  final num? sortOrder;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;

  factory _$UpdateOfferDto([void Function(UpdateOfferDtoBuilder)? updates]) =>
      (UpdateOfferDtoBuilder()..update(updates))._build();

  _$UpdateOfferDto._({
    this.variantId,
    this.originalPrice,
    this.offerPrice,
    this.isActive,
    this.sortOrder,
    this.startDate,
    this.endDate,
  }) : super._();
  @override
  UpdateOfferDto rebuild(void Function(UpdateOfferDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateOfferDtoBuilder toBuilder() => UpdateOfferDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateOfferDto &&
        variantId == other.variantId &&
        originalPrice == other.originalPrice &&
        offerPrice == other.offerPrice &&
        isActive == other.isActive &&
        sortOrder == other.sortOrder &&
        startDate == other.startDate &&
        endDate == other.endDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, variantId.hashCode);
    _$hash = $jc(_$hash, originalPrice.hashCode);
    _$hash = $jc(_$hash, offerPrice.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateOfferDto')
          ..add('variantId', variantId)
          ..add('originalPrice', originalPrice)
          ..add('offerPrice', offerPrice)
          ..add('isActive', isActive)
          ..add('sortOrder', sortOrder)
          ..add('startDate', startDate)
          ..add('endDate', endDate))
        .toString();
  }
}

class UpdateOfferDtoBuilder
    implements Builder<UpdateOfferDto, UpdateOfferDtoBuilder> {
  _$UpdateOfferDto? _$v;

  String? _variantId;
  String? get variantId => _$this._variantId;
  set variantId(String? variantId) => _$this._variantId = variantId;

  num? _originalPrice;
  num? get originalPrice => _$this._originalPrice;
  set originalPrice(num? originalPrice) =>
      _$this._originalPrice = originalPrice;

  num? _offerPrice;
  num? get offerPrice => _$this._offerPrice;
  set offerPrice(num? offerPrice) => _$this._offerPrice = offerPrice;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  num? _sortOrder;
  num? get sortOrder => _$this._sortOrder;
  set sortOrder(num? sortOrder) => _$this._sortOrder = sortOrder;

  DateTime? _startDate;
  DateTime? get startDate => _$this._startDate;
  set startDate(DateTime? startDate) => _$this._startDate = startDate;

  DateTime? _endDate;
  DateTime? get endDate => _$this._endDate;
  set endDate(DateTime? endDate) => _$this._endDate = endDate;

  UpdateOfferDtoBuilder() {
    UpdateOfferDto._defaults(this);
  }

  UpdateOfferDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _variantId = $v.variantId;
      _originalPrice = $v.originalPrice;
      _offerPrice = $v.offerPrice;
      _isActive = $v.isActive;
      _sortOrder = $v.sortOrder;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateOfferDto other) {
    _$v = other as _$UpdateOfferDto;
  }

  @override
  void update(void Function(UpdateOfferDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateOfferDto build() => _build();

  _$UpdateOfferDto _build() {
    final _$result =
        _$v ??
        _$UpdateOfferDto._(
          variantId: variantId,
          originalPrice: originalPrice,
          offerPrice: offerPrice,
          isActive: isActive,
          sortOrder: sortOrder,
          startDate: startDate,
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
