// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_option_group_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductOptionGroupResponseDto extends ProductOptionGroupResponseDto {
  @override
  final String id;
  @override
  final String? productId;
  @override
  final String? variantId;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final bool isRequired;
  @override
  final num minSelect;
  @override
  final num maxSelect;
  @override
  final Product? product;
  @override
  final ProductVariant? variant;
  @override
  final BuiltList<ProductOption>? options;

  factory _$ProductOptionGroupResponseDto([
    void Function(ProductOptionGroupResponseDtoBuilder)? updates,
  ]) => (ProductOptionGroupResponseDtoBuilder()..update(updates))._build();

  _$ProductOptionGroupResponseDto._({
    required this.id,
    this.productId,
    this.variantId,
    required this.name,
    this.nameAr,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    this.product,
    this.variant,
    this.options,
  }) : super._();
  @override
  ProductOptionGroupResponseDto rebuild(
    void Function(ProductOptionGroupResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductOptionGroupResponseDtoBuilder toBuilder() =>
      ProductOptionGroupResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductOptionGroupResponseDto &&
        id == other.id &&
        productId == other.productId &&
        variantId == other.variantId &&
        name == other.name &&
        nameAr == other.nameAr &&
        isRequired == other.isRequired &&
        minSelect == other.minSelect &&
        maxSelect == other.maxSelect &&
        product == other.product &&
        variant == other.variant &&
        options == other.options;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, variantId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, isRequired.hashCode);
    _$hash = $jc(_$hash, minSelect.hashCode);
    _$hash = $jc(_$hash, maxSelect.hashCode);
    _$hash = $jc(_$hash, product.hashCode);
    _$hash = $jc(_$hash, variant.hashCode);
    _$hash = $jc(_$hash, options.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductOptionGroupResponseDto')
          ..add('id', id)
          ..add('productId', productId)
          ..add('variantId', variantId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('isRequired', isRequired)
          ..add('minSelect', minSelect)
          ..add('maxSelect', maxSelect)
          ..add('product', product)
          ..add('variant', variant)
          ..add('options', options))
        .toString();
  }
}

class ProductOptionGroupResponseDtoBuilder
    implements
        Builder<
          ProductOptionGroupResponseDto,
          ProductOptionGroupResponseDtoBuilder
        > {
  _$ProductOptionGroupResponseDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _variantId;
  String? get variantId => _$this._variantId;
  set variantId(String? variantId) => _$this._variantId = variantId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  bool? _isRequired;
  bool? get isRequired => _$this._isRequired;
  set isRequired(bool? isRequired) => _$this._isRequired = isRequired;

  num? _minSelect;
  num? get minSelect => _$this._minSelect;
  set minSelect(num? minSelect) => _$this._minSelect = minSelect;

  num? _maxSelect;
  num? get maxSelect => _$this._maxSelect;
  set maxSelect(num? maxSelect) => _$this._maxSelect = maxSelect;

  ProductBuilder? _product;
  ProductBuilder get product => _$this._product ??= ProductBuilder();
  set product(ProductBuilder? product) => _$this._product = product;

  ProductVariantBuilder? _variant;
  ProductVariantBuilder get variant =>
      _$this._variant ??= ProductVariantBuilder();
  set variant(ProductVariantBuilder? variant) => _$this._variant = variant;

  ListBuilder<ProductOption>? _options;
  ListBuilder<ProductOption> get options =>
      _$this._options ??= ListBuilder<ProductOption>();
  set options(ListBuilder<ProductOption>? options) => _$this._options = options;

  ProductOptionGroupResponseDtoBuilder() {
    ProductOptionGroupResponseDto._defaults(this);
  }

  ProductOptionGroupResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _productId = $v.productId;
      _variantId = $v.variantId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _isRequired = $v.isRequired;
      _minSelect = $v.minSelect;
      _maxSelect = $v.maxSelect;
      _product = $v.product?.toBuilder();
      _variant = $v.variant?.toBuilder();
      _options = $v.options?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductOptionGroupResponseDto other) {
    _$v = other as _$ProductOptionGroupResponseDto;
  }

  @override
  void update(void Function(ProductOptionGroupResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductOptionGroupResponseDto build() => _build();

  _$ProductOptionGroupResponseDto _build() {
    _$ProductOptionGroupResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$ProductOptionGroupResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'ProductOptionGroupResponseDto',
              'id',
            ),
            productId: productId,
            variantId: variantId,
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ProductOptionGroupResponseDto',
              'name',
            ),
            nameAr: nameAr,
            isRequired: BuiltValueNullFieldError.checkNotNull(
              isRequired,
              r'ProductOptionGroupResponseDto',
              'isRequired',
            ),
            minSelect: BuiltValueNullFieldError.checkNotNull(
              minSelect,
              r'ProductOptionGroupResponseDto',
              'minSelect',
            ),
            maxSelect: BuiltValueNullFieldError.checkNotNull(
              maxSelect,
              r'ProductOptionGroupResponseDto',
              'maxSelect',
            ),
            product: _product?.build(),
            variant: _variant?.build(),
            options: _options?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'product';
        _product?.build();
        _$failedField = 'variant';
        _variant?.build();
        _$failedField = 'options';
        _options?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductOptionGroupResponseDto',
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
