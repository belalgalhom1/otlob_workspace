// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_product_variant_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateProductVariantDto extends UpdateProductVariantDto {
  @override
  final String? name;
  @override
  final String? nameAr;
  @override
  final String? sku;
  @override
  final num? basePrice;
  @override
  final num? comparePrice;
  @override
  final num? stock;
  @override
  final bool? isActive;
  @override
  final num? version;

  factory _$UpdateProductVariantDto([
    void Function(UpdateProductVariantDtoBuilder)? updates,
  ]) => (UpdateProductVariantDtoBuilder()..update(updates))._build();

  _$UpdateProductVariantDto._({
    this.name,
    this.nameAr,
    this.sku,
    this.basePrice,
    this.comparePrice,
    this.stock,
    this.isActive,
    this.version,
  }) : super._();
  @override
  UpdateProductVariantDto rebuild(
    void Function(UpdateProductVariantDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateProductVariantDtoBuilder toBuilder() =>
      UpdateProductVariantDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateProductVariantDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        sku == other.sku &&
        basePrice == other.basePrice &&
        comparePrice == other.comparePrice &&
        stock == other.stock &&
        isActive == other.isActive &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, sku.hashCode);
    _$hash = $jc(_$hash, basePrice.hashCode);
    _$hash = $jc(_$hash, comparePrice.hashCode);
    _$hash = $jc(_$hash, stock.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateProductVariantDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('sku', sku)
          ..add('basePrice', basePrice)
          ..add('comparePrice', comparePrice)
          ..add('stock', stock)
          ..add('isActive', isActive)
          ..add('version', version))
        .toString();
  }
}

class UpdateProductVariantDtoBuilder
    implements
        Builder<UpdateProductVariantDto, UpdateProductVariantDtoBuilder> {
  _$UpdateProductVariantDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  String? _sku;
  String? get sku => _$this._sku;
  set sku(String? sku) => _$this._sku = sku;

  num? _basePrice;
  num? get basePrice => _$this._basePrice;
  set basePrice(num? basePrice) => _$this._basePrice = basePrice;

  num? _comparePrice;
  num? get comparePrice => _$this._comparePrice;
  set comparePrice(num? comparePrice) => _$this._comparePrice = comparePrice;

  num? _stock;
  num? get stock => _$this._stock;
  set stock(num? stock) => _$this._stock = stock;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  num? _version;
  num? get version => _$this._version;
  set version(num? version) => _$this._version = version;

  UpdateProductVariantDtoBuilder() {
    UpdateProductVariantDto._defaults(this);
  }

  UpdateProductVariantDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _sku = $v.sku;
      _basePrice = $v.basePrice;
      _comparePrice = $v.comparePrice;
      _stock = $v.stock;
      _isActive = $v.isActive;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateProductVariantDto other) {
    _$v = other as _$UpdateProductVariantDto;
  }

  @override
  void update(void Function(UpdateProductVariantDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateProductVariantDto build() => _build();

  _$UpdateProductVariantDto _build() {
    final _$result =
        _$v ??
        _$UpdateProductVariantDto._(
          name: name,
          nameAr: nameAr,
          sku: sku,
          basePrice: basePrice,
          comparePrice: comparePrice,
          stock: stock,
          isActive: isActive,
          version: version,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
