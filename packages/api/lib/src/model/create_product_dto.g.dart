// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_product_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateProductDtoBranchAvailabilityModeEnum
_$createProductDtoBranchAvailabilityModeEnum_ALL =
    const CreateProductDtoBranchAvailabilityModeEnum._('ALL');
const CreateProductDtoBranchAvailabilityModeEnum
_$createProductDtoBranchAvailabilityModeEnum_SPECIFIC =
    const CreateProductDtoBranchAvailabilityModeEnum._('SPECIFIC');

CreateProductDtoBranchAvailabilityModeEnum
_$createProductDtoBranchAvailabilityModeEnumValueOf(String name) {
  switch (name) {
    case 'ALL':
      return _$createProductDtoBranchAvailabilityModeEnum_ALL;
    case 'SPECIFIC':
      return _$createProductDtoBranchAvailabilityModeEnum_SPECIFIC;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateProductDtoBranchAvailabilityModeEnum>
_$createProductDtoBranchAvailabilityModeEnumValues =
    BuiltSet<CreateProductDtoBranchAvailabilityModeEnum>(
      const <CreateProductDtoBranchAvailabilityModeEnum>[
        _$createProductDtoBranchAvailabilityModeEnum_ALL,
        _$createProductDtoBranchAvailabilityModeEnum_SPECIFIC,
      ],
    );

Serializer<CreateProductDtoBranchAvailabilityModeEnum>
_$createProductDtoBranchAvailabilityModeEnumSerializer =
    _$CreateProductDtoBranchAvailabilityModeEnumSerializer();

class _$CreateProductDtoBranchAvailabilityModeEnumSerializer
    implements PrimitiveSerializer<CreateProductDtoBranchAvailabilityModeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ALL': 'ALL',
    'SPECIFIC': 'SPECIFIC',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ALL': 'ALL',
    'SPECIFIC': 'SPECIFIC',
  };

  @override
  final Iterable<Type> types = const <Type>[
    CreateProductDtoBranchAvailabilityModeEnum,
  ];
  @override
  final String wireName = 'CreateProductDtoBranchAvailabilityModeEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateProductDtoBranchAvailabilityModeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateProductDtoBranchAvailabilityModeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateProductDtoBranchAvailabilityModeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateProductDto extends CreateProductDto {
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
  final bool? hasVariants;
  @override
  final num? basePrice;
  @override
  final num? comparePrice;
  @override
  final String? sku;
  @override
  final num? stock;
  @override
  final bool? tracksStock;
  @override
  final bool? isActive;
  @override
  final bool? isFeatured;
  @override
  final bool? sellByStrip;
  @override
  final num? stripsPerPackage;
  @override
  final CreateProductDtoBranchAvailabilityModeEnum? branchAvailabilityMode;
  @override
  final BuiltList<String>? branchIds;
  @override
  final BuiltList<CreateOptionGroupDto>? optionGroups;
  @override
  final BuiltList<CreateProductVariantDto>? variants;

  factory _$CreateProductDto([
    void Function(CreateProductDtoBuilder)? updates,
  ]) => (CreateProductDtoBuilder()..update(updates))._build();

  _$CreateProductDto._({
    this.categoryId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.hasVariants,
    this.basePrice,
    this.comparePrice,
    this.sku,
    this.stock,
    this.tracksStock,
    this.isActive,
    this.isFeatured,
    this.sellByStrip,
    this.stripsPerPackage,
    this.branchAvailabilityMode,
    this.branchIds,
    this.optionGroups,
    this.variants,
  }) : super._();
  @override
  CreateProductDto rebuild(void Function(CreateProductDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateProductDtoBuilder toBuilder() =>
      CreateProductDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateProductDto &&
        categoryId == other.categoryId &&
        name == other.name &&
        nameAr == other.nameAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        hasVariants == other.hasVariants &&
        basePrice == other.basePrice &&
        comparePrice == other.comparePrice &&
        sku == other.sku &&
        stock == other.stock &&
        tracksStock == other.tracksStock &&
        isActive == other.isActive &&
        isFeatured == other.isFeatured &&
        sellByStrip == other.sellByStrip &&
        stripsPerPackage == other.stripsPerPackage &&
        branchAvailabilityMode == other.branchAvailabilityMode &&
        branchIds == other.branchIds &&
        optionGroups == other.optionGroups &&
        variants == other.variants;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, hasVariants.hashCode);
    _$hash = $jc(_$hash, basePrice.hashCode);
    _$hash = $jc(_$hash, comparePrice.hashCode);
    _$hash = $jc(_$hash, sku.hashCode);
    _$hash = $jc(_$hash, stock.hashCode);
    _$hash = $jc(_$hash, tracksStock.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, isFeatured.hashCode);
    _$hash = $jc(_$hash, sellByStrip.hashCode);
    _$hash = $jc(_$hash, stripsPerPackage.hashCode);
    _$hash = $jc(_$hash, branchAvailabilityMode.hashCode);
    _$hash = $jc(_$hash, branchIds.hashCode);
    _$hash = $jc(_$hash, optionGroups.hashCode);
    _$hash = $jc(_$hash, variants.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateProductDto')
          ..add('categoryId', categoryId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('hasVariants', hasVariants)
          ..add('basePrice', basePrice)
          ..add('comparePrice', comparePrice)
          ..add('sku', sku)
          ..add('stock', stock)
          ..add('tracksStock', tracksStock)
          ..add('isActive', isActive)
          ..add('isFeatured', isFeatured)
          ..add('sellByStrip', sellByStrip)
          ..add('stripsPerPackage', stripsPerPackage)
          ..add('branchAvailabilityMode', branchAvailabilityMode)
          ..add('branchIds', branchIds)
          ..add('optionGroups', optionGroups)
          ..add('variants', variants))
        .toString();
  }
}

class CreateProductDtoBuilder
    implements Builder<CreateProductDto, CreateProductDtoBuilder> {
  _$CreateProductDto? _$v;

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

  bool? _sellByStrip;
  bool? get sellByStrip => _$this._sellByStrip;
  set sellByStrip(bool? sellByStrip) => _$this._sellByStrip = sellByStrip;

  num? _stripsPerPackage;
  num? get stripsPerPackage => _$this._stripsPerPackage;
  set stripsPerPackage(num? stripsPerPackage) =>
      _$this._stripsPerPackage = stripsPerPackage;

  CreateProductDtoBranchAvailabilityModeEnum? _branchAvailabilityMode;
  CreateProductDtoBranchAvailabilityModeEnum? get branchAvailabilityMode =>
      _$this._branchAvailabilityMode;
  set branchAvailabilityMode(
    CreateProductDtoBranchAvailabilityModeEnum? branchAvailabilityMode,
  ) => _$this._branchAvailabilityMode = branchAvailabilityMode;

  ListBuilder<String>? _branchIds;
  ListBuilder<String> get branchIds =>
      _$this._branchIds ??= ListBuilder<String>();
  set branchIds(ListBuilder<String>? branchIds) =>
      _$this._branchIds = branchIds;

  ListBuilder<CreateOptionGroupDto>? _optionGroups;
  ListBuilder<CreateOptionGroupDto> get optionGroups =>
      _$this._optionGroups ??= ListBuilder<CreateOptionGroupDto>();
  set optionGroups(ListBuilder<CreateOptionGroupDto>? optionGroups) =>
      _$this._optionGroups = optionGroups;

  ListBuilder<CreateProductVariantDto>? _variants;
  ListBuilder<CreateProductVariantDto> get variants =>
      _$this._variants ??= ListBuilder<CreateProductVariantDto>();
  set variants(ListBuilder<CreateProductVariantDto>? variants) =>
      _$this._variants = variants;

  CreateProductDtoBuilder() {
    CreateProductDto._defaults(this);
  }

  CreateProductDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categoryId = $v.categoryId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _hasVariants = $v.hasVariants;
      _basePrice = $v.basePrice;
      _comparePrice = $v.comparePrice;
      _sku = $v.sku;
      _stock = $v.stock;
      _tracksStock = $v.tracksStock;
      _isActive = $v.isActive;
      _isFeatured = $v.isFeatured;
      _sellByStrip = $v.sellByStrip;
      _stripsPerPackage = $v.stripsPerPackage;
      _branchAvailabilityMode = $v.branchAvailabilityMode;
      _branchIds = $v.branchIds?.toBuilder();
      _optionGroups = $v.optionGroups?.toBuilder();
      _variants = $v.variants?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateProductDto other) {
    _$v = other as _$CreateProductDto;
  }

  @override
  void update(void Function(CreateProductDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateProductDto build() => _build();

  _$CreateProductDto _build() {
    _$CreateProductDto _$result;
    try {
      _$result =
          _$v ??
          _$CreateProductDto._(
            categoryId: categoryId,
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'CreateProductDto',
              'name',
            ),
            nameAr: nameAr,
            description: description,
            descriptionAr: descriptionAr,
            hasVariants: hasVariants,
            basePrice: basePrice,
            comparePrice: comparePrice,
            sku: sku,
            stock: stock,
            tracksStock: tracksStock,
            isActive: isActive,
            isFeatured: isFeatured,
            sellByStrip: sellByStrip,
            stripsPerPackage: stripsPerPackage,
            branchAvailabilityMode: branchAvailabilityMode,
            branchIds: _branchIds?.build(),
            optionGroups: _optionGroups?.build(),
            variants: _variants?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'branchIds';
        _branchIds?.build();
        _$failedField = 'optionGroups';
        _optionGroups?.build();
        _$failedField = 'variants';
        _variants?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateProductDto',
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
