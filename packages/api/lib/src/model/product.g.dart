// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Product extends Product {
  @override
  final String id;
  @override
  final num version;
  @override
  final String vendorId;
  @override
  final String? categoryId;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final String? imageUrl;
  @override
  final bool sellByStrip;
  @override
  final num? stripsPerPackage;
  @override
  final bool hasVariants;
  @override
  final num? basePrice;
  @override
  final num? comparePrice;
  @override
  final String? sku;
  @override
  final num? stock;
  @override
  final bool tracksStock;
  @override
  final bool isActive;
  @override
  final bool isFeatured;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$Product([void Function(ProductBuilder)? updates]) =>
      (ProductBuilder()..update(updates))._build();

  _$Product._({
    required this.id,
    required this.version,
    required this.vendorId,
    this.categoryId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.imageUrl,
    required this.sellByStrip,
    this.stripsPerPackage,
    required this.hasVariants,
    this.basePrice,
    this.comparePrice,
    this.sku,
    this.stock,
    required this.tracksStock,
    required this.isActive,
    required this.isFeatured,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  Product rebuild(void Function(ProductBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductBuilder toBuilder() => ProductBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Product &&
        id == other.id &&
        version == other.version &&
        vendorId == other.vendorId &&
        categoryId == other.categoryId &&
        name == other.name &&
        nameAr == other.nameAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        imageUrl == other.imageUrl &&
        sellByStrip == other.sellByStrip &&
        stripsPerPackage == other.stripsPerPackage &&
        hasVariants == other.hasVariants &&
        basePrice == other.basePrice &&
        comparePrice == other.comparePrice &&
        sku == other.sku &&
        stock == other.stock &&
        tracksStock == other.tracksStock &&
        isActive == other.isActive &&
        isFeatured == other.isFeatured &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, imageUrl.hashCode);
    _$hash = $jc(_$hash, sellByStrip.hashCode);
    _$hash = $jc(_$hash, stripsPerPackage.hashCode);
    _$hash = $jc(_$hash, hasVariants.hashCode);
    _$hash = $jc(_$hash, basePrice.hashCode);
    _$hash = $jc(_$hash, comparePrice.hashCode);
    _$hash = $jc(_$hash, sku.hashCode);
    _$hash = $jc(_$hash, stock.hashCode);
    _$hash = $jc(_$hash, tracksStock.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, isFeatured.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Product')
          ..add('id', id)
          ..add('version', version)
          ..add('vendorId', vendorId)
          ..add('categoryId', categoryId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('imageUrl', imageUrl)
          ..add('sellByStrip', sellByStrip)
          ..add('stripsPerPackage', stripsPerPackage)
          ..add('hasVariants', hasVariants)
          ..add('basePrice', basePrice)
          ..add('comparePrice', comparePrice)
          ..add('sku', sku)
          ..add('stock', stock)
          ..add('tracksStock', tracksStock)
          ..add('isActive', isActive)
          ..add('isFeatured', isFeatured)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class ProductBuilder implements Builder<Product, ProductBuilder> {
  _$Product? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  num? _version;
  num? get version => _$this._version;
  set version(num? version) => _$this._version = version;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

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

  bool? _sellByStrip;
  bool? get sellByStrip => _$this._sellByStrip;
  set sellByStrip(bool? sellByStrip) => _$this._sellByStrip = sellByStrip;

  num? _stripsPerPackage;
  num? get stripsPerPackage => _$this._stripsPerPackage;
  set stripsPerPackage(num? stripsPerPackage) =>
      _$this._stripsPerPackage = stripsPerPackage;

  bool? _hasVariants;
  bool? get hasVariants => _$this._hasVariants;
  set hasVariants(bool? hasVariants) => _$this._hasVariants = hasVariants;

  num? _basePrice;
  num? get basePrice => _$this._basePrice;
  set basePrice(num? basePrice) => _$this._basePrice = basePrice;

  num? _comparePrice;
  num? get comparePrice => _$this._comparePrice;
  set comparePrice(num? comparePrice) => _$this._comparePrice = comparePrice;

  String? _sku;
  String? get sku => _$this._sku;
  set sku(String? sku) => _$this._sku = sku;

  num? _stock;
  num? get stock => _$this._stock;
  set stock(num? stock) => _$this._stock = stock;

  bool? _tracksStock;
  bool? get tracksStock => _$this._tracksStock;
  set tracksStock(bool? tracksStock) => _$this._tracksStock = tracksStock;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  bool? _isFeatured;
  bool? get isFeatured => _$this._isFeatured;
  set isFeatured(bool? isFeatured) => _$this._isFeatured = isFeatured;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ProductBuilder() {
    Product._defaults(this);
  }

  ProductBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _version = $v.version;
      _vendorId = $v.vendorId;
      _categoryId = $v.categoryId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _imageUrl = $v.imageUrl;
      _sellByStrip = $v.sellByStrip;
      _stripsPerPackage = $v.stripsPerPackage;
      _hasVariants = $v.hasVariants;
      _basePrice = $v.basePrice;
      _comparePrice = $v.comparePrice;
      _sku = $v.sku;
      _stock = $v.stock;
      _tracksStock = $v.tracksStock;
      _isActive = $v.isActive;
      _isFeatured = $v.isFeatured;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Product other) {
    _$v = other as _$Product;
  }

  @override
  void update(void Function(ProductBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Product build() => _build();

  _$Product _build() {
    final _$result =
        _$v ??
        _$Product._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Product', 'id'),
          version: BuiltValueNullFieldError.checkNotNull(
            version,
            r'Product',
            'version',
          ),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'Product',
            'vendorId',
          ),
          categoryId: categoryId,
          name: BuiltValueNullFieldError.checkNotNull(name, r'Product', 'name'),
          nameAr: nameAr,
          description: description,
          descriptionAr: descriptionAr,
          imageUrl: imageUrl,
          sellByStrip: BuiltValueNullFieldError.checkNotNull(
            sellByStrip,
            r'Product',
            'sellByStrip',
          ),
          stripsPerPackage: stripsPerPackage,
          hasVariants: BuiltValueNullFieldError.checkNotNull(
            hasVariants,
            r'Product',
            'hasVariants',
          ),
          basePrice: basePrice,
          comparePrice: comparePrice,
          sku: sku,
          stock: stock,
          tracksStock: BuiltValueNullFieldError.checkNotNull(
            tracksStock,
            r'Product',
            'tracksStock',
          ),
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'Product',
            'isActive',
          ),
          isFeatured: BuiltValueNullFieldError.checkNotNull(
            isFeatured,
            r'Product',
            'isFeatured',
          ),
          deletedAt: deletedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Product',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Product',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
