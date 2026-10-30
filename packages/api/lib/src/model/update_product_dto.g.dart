// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_product_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateProductDtoBranchAvailabilityModeEnum
_$updateProductDtoBranchAvailabilityModeEnum_ALL =
    const UpdateProductDtoBranchAvailabilityModeEnum._('ALL');
const UpdateProductDtoBranchAvailabilityModeEnum
_$updateProductDtoBranchAvailabilityModeEnum_SPECIFIC =
    const UpdateProductDtoBranchAvailabilityModeEnum._('SPECIFIC');

UpdateProductDtoBranchAvailabilityModeEnum
_$updateProductDtoBranchAvailabilityModeEnumValueOf(String name) {
  switch (name) {
    case 'ALL':
      return _$updateProductDtoBranchAvailabilityModeEnum_ALL;
    case 'SPECIFIC':
      return _$updateProductDtoBranchAvailabilityModeEnum_SPECIFIC;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateProductDtoBranchAvailabilityModeEnum>
_$updateProductDtoBranchAvailabilityModeEnumValues =
    BuiltSet<UpdateProductDtoBranchAvailabilityModeEnum>(
      const <UpdateProductDtoBranchAvailabilityModeEnum>[
        _$updateProductDtoBranchAvailabilityModeEnum_ALL,
        _$updateProductDtoBranchAvailabilityModeEnum_SPECIFIC,
      ],
    );

Serializer<UpdateProductDtoBranchAvailabilityModeEnum>
_$updateProductDtoBranchAvailabilityModeEnumSerializer =
    _$UpdateProductDtoBranchAvailabilityModeEnumSerializer();

class _$UpdateProductDtoBranchAvailabilityModeEnumSerializer
    implements PrimitiveSerializer<UpdateProductDtoBranchAvailabilityModeEnum> {
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
    UpdateProductDtoBranchAvailabilityModeEnum,
  ];
  @override
  final String wireName = 'UpdateProductDtoBranchAvailabilityModeEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateProductDtoBranchAvailabilityModeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateProductDtoBranchAvailabilityModeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateProductDtoBranchAvailabilityModeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

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
  final UpdateProductDtoBranchAvailabilityModeEnum? branchAvailabilityMode;
  @override
  final BuiltList<String>? branchIds;
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
    this.tracksStock,
    this.isActive,
    this.isFeatured,
    this.sellByStrip,
    this.stripsPerPackage,
    this.branchAvailabilityMode,
    this.branchIds,
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
        tracksStock == other.tracksStock &&
        isActive == other.isActive &&
        isFeatured == other.isFeatured &&
        sellByStrip == other.sellByStrip &&
        stripsPerPackage == other.stripsPerPackage &&
        branchAvailabilityMode == other.branchAvailabilityMode &&
        branchIds == other.branchIds &&
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
    _$hash = $jc(_$hash, tracksStock.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, isFeatured.hashCode);
    _$hash = $jc(_$hash, sellByStrip.hashCode);
    _$hash = $jc(_$hash, stripsPerPackage.hashCode);
    _$hash = $jc(_$hash, branchAvailabilityMode.hashCode);
    _$hash = $jc(_$hash, branchIds.hashCode);
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
          ..add('tracksStock', tracksStock)
          ..add('isActive', isActive)
          ..add('isFeatured', isFeatured)
          ..add('sellByStrip', sellByStrip)
          ..add('stripsPerPackage', stripsPerPackage)
          ..add('branchAvailabilityMode', branchAvailabilityMode)
          ..add('branchIds', branchIds)
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

  UpdateProductDtoBranchAvailabilityModeEnum? _branchAvailabilityMode;
  UpdateProductDtoBranchAvailabilityModeEnum? get branchAvailabilityMode =>
      _$this._branchAvailabilityMode;
  set branchAvailabilityMode(
    UpdateProductDtoBranchAvailabilityModeEnum? branchAvailabilityMode,
  ) => _$this._branchAvailabilityMode = branchAvailabilityMode;

  ListBuilder<String>? _branchIds;
  ListBuilder<String> get branchIds =>
      _$this._branchIds ??= ListBuilder<String>();
  set branchIds(ListBuilder<String>? branchIds) =>
      _$this._branchIds = branchIds;

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
      _tracksStock = $v.tracksStock;
      _isActive = $v.isActive;
      _isFeatured = $v.isFeatured;
      _sellByStrip = $v.sellByStrip;
      _stripsPerPackage = $v.stripsPerPackage;
      _branchAvailabilityMode = $v.branchAvailabilityMode;
      _branchIds = $v.branchIds?.toBuilder();
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
    _$UpdateProductDto _$result;
    try {
      _$result =
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
            tracksStock: tracksStock,
            isActive: isActive,
            isFeatured: isFeatured,
            sellByStrip: sellByStrip,
            stripsPerPackage: stripsPerPackage,
            branchAvailabilityMode: branchAvailabilityMode,
            branchIds: _branchIds?.build(),
            version: version,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'branchIds';
        _branchIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateProductDto',
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
