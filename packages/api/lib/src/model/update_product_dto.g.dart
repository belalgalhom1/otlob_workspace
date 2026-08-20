// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_product_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateProductDto extends UpdateProductDto {
  @override
  final JsonObject? categoryId;
  @override
  final String? name;
  @override
  final String? nameAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final num? basePrice;
  @override
  final num? comparePrice;
  @override
  final String? sku;
  @override
  final num? stock;
  @override
  final bool? isActive;
  @override
  final bool? isFeatured;
  @override
  final bool? sellByStrip;
  @override
  final num? stripsPerPackage;
  @override
  final num? version;

  factory _$UpdateProductDto([
    void Function(UpdateProductDtoBuilder)? updates,
  ]) => (UpdateProductDtoBuilder()..update(updates))._build();

  _$UpdateProductDto._({
    this.categoryId,
    this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.basePrice,
    this.comparePrice,
    this.sku,
    this.stock,
    this.isActive,
    this.isFeatured,
    this.sellByStrip,
    this.stripsPerPackage,
    this.version,
  }) : super._();
  @override
  UpdateProductDto rebuild(void Function(UpdateProductDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateProductDtoBuilder toBuilder() =>
      UpdateProductDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateProductDto &&
        categoryId == other.categoryId &&
        name == other.name &&
        nameAr == other.nameAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        basePrice == other.basePrice &&
        comparePrice == other.comparePrice &&
        sku == other.sku &&
        stock == other.stock &&
        isActive == other.isActive &&
        isFeatured == other.isFeatured &&
        sellByStrip == other.sellByStrip &&
        stripsPerPackage == other.stripsPerPackage &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, basePrice.hashCode);
    _$hash = $jc(_$hash, comparePrice.hashCode);
    _$hash = $jc(_$hash, sku.hashCode);
    _$hash = $jc(_$hash, stock.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, isFeatured.hashCode);
    _$hash = $jc(_$hash, sellByStrip.hashCode);
    _$hash = $jc(_$hash, stripsPerPackage.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateProductDto')
          ..add('categoryId', categoryId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('basePrice', basePrice)
          ..add('comparePrice', comparePrice)
          ..add('sku', sku)
          ..add('stock', stock)
          ..add('isActive', isActive)
          ..add('isFeatured', isFeatured)
          ..add('sellByStrip', sellByStrip)
          ..add('stripsPerPackage', stripsPerPackage)
          ..add('version', version))
        .toString();
  }
}

class UpdateProductDtoBuilder
    implements Builder<UpdateProductDto, UpdateProductDtoBuilder> {
  _$UpdateProductDto? _$v;

  JsonObject? _categoryId;
  JsonObject? get categoryId => _$this._categoryId;
  set categoryId(JsonObject? categoryId) => _$this._categoryId = categoryId;

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

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  bool? _isFeatured;
  bool? get isFeatured => _$this._isFeatured;
  set isFeatured(bool? isFeatured) => _$this._isFeatured = isFeatured;

  bool? _sellByStrip;
  bool? get sellByStrip => _$this._sellByStrip;
  set sellByStrip(bool? sellByStrip) => _$this._sellByStrip = sellByStrip;

  num? _stripsPerPackage;
  num? get stripsPerPackage => _$this._stripsPerPackage;
  set stripsPerPackage(num? stripsPerPackage) =>
      _$this._stripsPerPackage = stripsPerPackage;

  num? _version;
  num? get version => _$this._version;
  set version(num? version) => _$this._version = version;

  UpdateProductDtoBuilder() {
    UpdateProductDto._defaults(this);
  }

  UpdateProductDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categoryId = $v.categoryId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _basePrice = $v.basePrice;
      _comparePrice = $v.comparePrice;
      _sku = $v.sku;
      _stock = $v.stock;
      _isActive = $v.isActive;
      _isFeatured = $v.isFeatured;
      _sellByStrip = $v.sellByStrip;
      _stripsPerPackage = $v.stripsPerPackage;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateProductDto other) {
    _$v = other as _$UpdateProductDto;
  }

  @override
  void update(void Function(UpdateProductDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateProductDto build() => _build();

  _$UpdateProductDto _build() {
    final _$result =
        _$v ??
        _$UpdateProductDto._(
          categoryId: categoryId,
          name: name,
          nameAr: nameAr,
          description: description,
          descriptionAr: descriptionAr,
          basePrice: basePrice,
          comparePrice: comparePrice,
          sku: sku,
          stock: stock,
          isActive: isActive,
          isFeatured: isFeatured,
          sellByStrip: sellByStrip,
          stripsPerPackage: stripsPerPackage,
          version: version,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
