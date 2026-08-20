// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Promotion extends Promotion {
  @override
  final String id;
  @override
  final String title;
  @override
  final String? titleAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final String imageUrl;
  @override
  final JsonObject? type;
  @override
  final String? vendorId;
  @override
  final String? productId;
  @override
  final String? externalUrl;
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
  @override
  final JsonObject? vendor;
  @override
  final JsonObject? product;

  factory _$Promotion([void Function(PromotionBuilder)? updates]) =>
      (PromotionBuilder()..update(updates))._build();

  _$Promotion._({
    required this.id,
    required this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    required this.imageUrl,
    this.type,
    this.vendorId,
    this.productId,
    this.externalUrl,
    required this.isActive,
    required this.sortOrder,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.vendor,
    this.product,
  }) : super._();
  @override
  Promotion rebuild(void Function(PromotionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PromotionBuilder toBuilder() => PromotionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Promotion &&
        id == other.id &&
        title == other.title &&
        titleAr == other.titleAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        imageUrl == other.imageUrl &&
        type == other.type &&
        vendorId == other.vendorId &&
        productId == other.productId &&
        externalUrl == other.externalUrl &&
        isActive == other.isActive &&
        sortOrder == other.sortOrder &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        vendor == other.vendor &&
        product == other.product;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, imageUrl.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, externalUrl.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jc(_$hash, product.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Promotion')
          ..add('id', id)
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('imageUrl', imageUrl)
          ..add('type', type)
          ..add('vendorId', vendorId)
          ..add('productId', productId)
          ..add('externalUrl', externalUrl)
          ..add('isActive', isActive)
          ..add('sortOrder', sortOrder)
          ..add('startDate', startDate)
          ..add('endDate', endDate)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('vendor', vendor)
          ..add('product', product))
        .toString();
  }
}

class PromotionBuilder implements Builder<Promotion, PromotionBuilder> {
  _$Promotion? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _descriptionAr;
  String? get descriptionAr => _$this._descriptionAr;
  set descriptionAr(String? descriptionAr) =>
      _$this._descriptionAr = descriptionAr;

  String? _imageUrl;
  String? get imageUrl => _$this._imageUrl;
  set imageUrl(String? imageUrl) => _$this._imageUrl = imageUrl;

  JsonObject? _type;
  JsonObject? get type => _$this._type;
  set type(JsonObject? type) => _$this._type = type;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _externalUrl;
  String? get externalUrl => _$this._externalUrl;
  set externalUrl(String? externalUrl) => _$this._externalUrl = externalUrl;

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

  JsonObject? _vendor;
  JsonObject? get vendor => _$this._vendor;
  set vendor(JsonObject? vendor) => _$this._vendor = vendor;

  JsonObject? _product;
  JsonObject? get product => _$this._product;
  set product(JsonObject? product) => _$this._product = product;

  PromotionBuilder() {
    Promotion._defaults(this);
  }

  PromotionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _title = $v.title;
      _titleAr = $v.titleAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _imageUrl = $v.imageUrl;
      _type = $v.type;
      _vendorId = $v.vendorId;
      _productId = $v.productId;
      _externalUrl = $v.externalUrl;
      _isActive = $v.isActive;
      _sortOrder = $v.sortOrder;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _vendor = $v.vendor;
      _product = $v.product;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Promotion other) {
    _$v = other as _$Promotion;
  }

  @override
  void update(void Function(PromotionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Promotion build() => _build();

  _$Promotion _build() {
    final _$result =
        _$v ??
        _$Promotion._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Promotion', 'id'),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'Promotion',
            'title',
          ),
          titleAr: titleAr,
          description: description,
          descriptionAr: descriptionAr,
          imageUrl: BuiltValueNullFieldError.checkNotNull(
            imageUrl,
            r'Promotion',
            'imageUrl',
          ),
          type: type,
          vendorId: vendorId,
          productId: productId,
          externalUrl: externalUrl,
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'Promotion',
            'isActive',
          ),
          sortOrder: BuiltValueNullFieldError.checkNotNull(
            sortOrder,
            r'Promotion',
            'sortOrder',
          ),
          startDate: startDate,
          endDate: endDate,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Promotion',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Promotion',
            'updatedAt',
          ),
          vendor: vendor,
          product: product,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
