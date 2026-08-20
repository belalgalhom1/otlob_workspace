// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_option_group.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductOptionGroup extends ProductOptionGroup {
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
  final JsonObject? product;
  @override
  final JsonObject? variant;
  @override
  final BuiltList<ProductOption> options;

  factory _$ProductOptionGroup([
    void Function(ProductOptionGroupBuilder)? updates,
  ]) => (ProductOptionGroupBuilder()..update(updates))._build();

  _$ProductOptionGroup._({
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
    required this.options,
  }) : super._();
  @override
  ProductOptionGroup rebuild(
    void Function(ProductOptionGroupBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductOptionGroupBuilder toBuilder() =>
      ProductOptionGroupBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductOptionGroup &&
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
    return (newBuiltValueToStringHelper(r'ProductOptionGroup')
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

class ProductOptionGroupBuilder
    implements Builder<ProductOptionGroup, ProductOptionGroupBuilder> {
  _$ProductOptionGroup? _$v;

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

  JsonObject? _product;
  JsonObject? get product => _$this._product;
  set product(JsonObject? product) => _$this._product = product;

  JsonObject? _variant;
  JsonObject? get variant => _$this._variant;
  set variant(JsonObject? variant) => _$this._variant = variant;

  ListBuilder<ProductOption>? _options;
  ListBuilder<ProductOption> get options =>
      _$this._options ??= ListBuilder<ProductOption>();
  set options(ListBuilder<ProductOption>? options) => _$this._options = options;

  ProductOptionGroupBuilder() {
    ProductOptionGroup._defaults(this);
  }

  ProductOptionGroupBuilder get _$this {
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
      _product = $v.product;
      _variant = $v.variant;
      _options = $v.options.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductOptionGroup other) {
    _$v = other as _$ProductOptionGroup;
  }

  @override
  void update(void Function(ProductOptionGroupBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductOptionGroup build() => _build();

  _$ProductOptionGroup _build() {
    _$ProductOptionGroup _$result;
    try {
      _$result =
          _$v ??
          _$ProductOptionGroup._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'ProductOptionGroup',
              'id',
            ),
            productId: productId,
            variantId: variantId,
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ProductOptionGroup',
              'name',
            ),
            nameAr: nameAr,
            isRequired: BuiltValueNullFieldError.checkNotNull(
              isRequired,
              r'ProductOptionGroup',
              'isRequired',
            ),
            minSelect: BuiltValueNullFieldError.checkNotNull(
              minSelect,
              r'ProductOptionGroup',
              'minSelect',
            ),
            maxSelect: BuiltValueNullFieldError.checkNotNull(
              maxSelect,
              r'ProductOptionGroup',
              'maxSelect',
            ),
            product: product,
            variant: variant,
            options: options.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'options';
        options.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductOptionGroup',
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
