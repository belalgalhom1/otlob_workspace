// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_product_variant_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateProductVariantDto extends CreateProductVariantDto {
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String? sku;
  @override
  final num basePrice;
  @override
  final num? comparePrice;
  @override
  final num? stock;
  @override
  final bool? isActive;
  @override
  final BuiltList<CreateOptionGroupDto>? optionGroups;

  factory _$CreateProductVariantDto([
    void Function(CreateProductVariantDtoBuilder)? updates,
  ]) => (CreateProductVariantDtoBuilder()..update(updates))._build();

  _$CreateProductVariantDto._({
    required this.name,
    this.nameAr,
    this.sku,
    required this.basePrice,
    this.comparePrice,
    this.stock,
    this.isActive,
    this.optionGroups,
  }) : super._();
  @override
  CreateProductVariantDto rebuild(
    void Function(CreateProductVariantDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateProductVariantDtoBuilder toBuilder() =>
      CreateProductVariantDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateProductVariantDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        sku == other.sku &&
        basePrice == other.basePrice &&
        comparePrice == other.comparePrice &&
        stock == other.stock &&
        isActive == other.isActive &&
        optionGroups == other.optionGroups;
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
    _$hash = $jc(_$hash, optionGroups.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateProductVariantDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('sku', sku)
          ..add('basePrice', basePrice)
          ..add('comparePrice', comparePrice)
          ..add('stock', stock)
          ..add('isActive', isActive)
          ..add('optionGroups', optionGroups))
        .toString();
  }
}

class CreateProductVariantDtoBuilder
    implements
        Builder<CreateProductVariantDto, CreateProductVariantDtoBuilder> {
  _$CreateProductVariantDto? _$v;

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

  ListBuilder<CreateOptionGroupDto>? _optionGroups;
  ListBuilder<CreateOptionGroupDto> get optionGroups =>
      _$this._optionGroups ??= ListBuilder<CreateOptionGroupDto>();
  set optionGroups(ListBuilder<CreateOptionGroupDto>? optionGroups) =>
      _$this._optionGroups = optionGroups;

  CreateProductVariantDtoBuilder() {
    CreateProductVariantDto._defaults(this);
  }

  CreateProductVariantDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _sku = $v.sku;
      _basePrice = $v.basePrice;
      _comparePrice = $v.comparePrice;
      _stock = $v.stock;
      _isActive = $v.isActive;
      _optionGroups = $v.optionGroups?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateProductVariantDto other) {
    _$v = other as _$CreateProductVariantDto;
  }

  @override
  void update(void Function(CreateProductVariantDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateProductVariantDto build() => _build();

  _$CreateProductVariantDto _build() {
    _$CreateProductVariantDto _$result;
    try {
      _$result =
          _$v ??
          _$CreateProductVariantDto._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'CreateProductVariantDto',
              'name',
            ),
            nameAr: nameAr,
            sku: sku,
            basePrice: BuiltValueNullFieldError.checkNotNull(
              basePrice,
              r'CreateProductVariantDto',
              'basePrice',
            ),
            comparePrice: comparePrice,
            stock: stock,
            isActive: isActive,
            optionGroups: _optionGroups?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'optionGroups';
        _optionGroups?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateProductVariantDto',
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
