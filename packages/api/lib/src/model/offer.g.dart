// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Offer extends Offer {
  @override
  final String id;
  @override
  final String productId;
  @override
  final String vendorId;
  @override
  final num originalPrice;
  @override
  final num offerPrice;
  @override
  final bool isActive;
  @override
  final num sortOrder;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$Offer([void Function(OfferBuilder)? updates]) =>
      (OfferBuilder()..update(updates))._build();

  _$Offer._({
    required this.id,
    required this.productId,
    required this.vendorId,
    required this.originalPrice,
    required this.offerPrice,
    required this.isActive,
    required this.sortOrder,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  Offer rebuild(void Function(OfferBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OfferBuilder toBuilder() => OfferBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Offer &&
        id == other.id &&
        productId == other.productId &&
        vendorId == other.vendorId &&
        originalPrice == other.originalPrice &&
        offerPrice == other.offerPrice &&
        isActive == other.isActive &&
        sortOrder == other.sortOrder &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, originalPrice.hashCode);
    _$hash = $jc(_$hash, offerPrice.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Offer')
          ..add('id', id)
          ..add('productId', productId)
          ..add('vendorId', vendorId)
          ..add('originalPrice', originalPrice)
          ..add('offerPrice', offerPrice)
          ..add('isActive', isActive)
          ..add('sortOrder', sortOrder)
          ..add('startDate', startDate)
          ..add('endDate', endDate)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class OfferBuilder implements Builder<Offer, OfferBuilder> {
  _$Offer? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

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

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  OfferBuilder() {
    Offer._defaults(this);
  }

  OfferBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _productId = $v.productId;
      _vendorId = $v.vendorId;
      _originalPrice = $v.originalPrice;
      _offerPrice = $v.offerPrice;
      _isActive = $v.isActive;
      _sortOrder = $v.sortOrder;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Offer other) {
    _$v = other as _$Offer;
  }

  @override
  void update(void Function(OfferBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Offer build() => _build();

  _$Offer _build() {
    final _$result =
        _$v ??
        _$Offer._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Offer', 'id'),
          productId: BuiltValueNullFieldError.checkNotNull(
            productId,
            r'Offer',
            'productId',
          ),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'Offer',
            'vendorId',
          ),
          originalPrice: BuiltValueNullFieldError.checkNotNull(
            originalPrice,
            r'Offer',
            'originalPrice',
          ),
          offerPrice: BuiltValueNullFieldError.checkNotNull(
            offerPrice,
            r'Offer',
            'offerPrice',
          ),
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'Offer',
            'isActive',
          ),
          sortOrder: BuiltValueNullFieldError.checkNotNull(
            sortOrder,
            r'Offer',
            'sortOrder',
          ),
          startDate: startDate,
          endDate: endDate,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Offer',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Offer',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
