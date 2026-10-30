// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ProductResponseDtoBranchAvailabilityModeEnum
_$productResponseDtoBranchAvailabilityModeEnum_ALL =
    const ProductResponseDtoBranchAvailabilityModeEnum._('ALL');
const ProductResponseDtoBranchAvailabilityModeEnum
_$productResponseDtoBranchAvailabilityModeEnum_SPECIFIC =
    const ProductResponseDtoBranchAvailabilityModeEnum._('SPECIFIC');

ProductResponseDtoBranchAvailabilityModeEnum
_$productResponseDtoBranchAvailabilityModeEnumValueOf(String name) {
  switch (name) {
    case 'ALL':
      return _$productResponseDtoBranchAvailabilityModeEnum_ALL;
    case 'SPECIFIC':
      return _$productResponseDtoBranchAvailabilityModeEnum_SPECIFIC;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ProductResponseDtoBranchAvailabilityModeEnum>
_$productResponseDtoBranchAvailabilityModeEnumValues =
    BuiltSet<ProductResponseDtoBranchAvailabilityModeEnum>(
      const <ProductResponseDtoBranchAvailabilityModeEnum>[
        _$productResponseDtoBranchAvailabilityModeEnum_ALL,
        _$productResponseDtoBranchAvailabilityModeEnum_SPECIFIC,
      ],
    );

Serializer<ProductResponseDtoBranchAvailabilityModeEnum>
_$productResponseDtoBranchAvailabilityModeEnumSerializer =
    _$ProductResponseDtoBranchAvailabilityModeEnumSerializer();

class _$ProductResponseDtoBranchAvailabilityModeEnumSerializer
    implements
        PrimitiveSerializer<ProductResponseDtoBranchAvailabilityModeEnum> {
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
    ProductResponseDtoBranchAvailabilityModeEnum,
  ];
  @override
  final String wireName = 'ProductResponseDtoBranchAvailabilityModeEnum';

  @override
  Object serialize(
    Serializers serializers,
    ProductResponseDtoBranchAvailabilityModeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ProductResponseDtoBranchAvailabilityModeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ProductResponseDtoBranchAvailabilityModeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ProductResponseDto extends ProductResponseDto {
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
  final ProductResponseDtoBranchAvailabilityModeEnum branchAvailabilityMode;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final BuiltList<CartItem>? cartItems;
  @override
  final BuiltList<FavoriteProduct>? favoritedBy;
  @override
  final BuiltList<OrderItem>? orderItems;
  @override
  final BuiltList<ProductOptionGroup>? optionGroups;
  @override
  final BuiltList<ProductVariant>? variants;
  @override
  final BuiltList<Promotion>? promotions;
  @override
  final BuiltList<Offer>? offers;
  @override
  final BuiltList<ProductBranchAvailability>? branchAvailability;
  @override
  final MenuCategory? category;
  @override
  final Vendor? vendor;

  factory _$ProductResponseDto([
    void Function(ProductResponseDtoBuilder)? updates,
  ]) => (ProductResponseDtoBuilder()..update(updates))._build();

  _$ProductResponseDto._({
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
    required this.branchAvailabilityMode,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.cartItems,
    this.favoritedBy,
    this.orderItems,
    this.optionGroups,
    this.variants,
    this.promotions,
    this.offers,
    this.branchAvailability,
    this.category,
    this.vendor,
  }) : super._();
  @override
  ProductResponseDto rebuild(
    void Function(ProductResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductResponseDtoBuilder toBuilder() =>
      ProductResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductResponseDto &&
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
        branchAvailabilityMode == other.branchAvailabilityMode &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        cartItems == other.cartItems &&
        favoritedBy == other.favoritedBy &&
        orderItems == other.orderItems &&
        optionGroups == other.optionGroups &&
        variants == other.variants &&
        promotions == other.promotions &&
        offers == other.offers &&
        branchAvailability == other.branchAvailability &&
        category == other.category &&
        vendor == other.vendor;
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
    _$hash = $jc(_$hash, branchAvailabilityMode.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, cartItems.hashCode);
    _$hash = $jc(_$hash, favoritedBy.hashCode);
    _$hash = $jc(_$hash, orderItems.hashCode);
    _$hash = $jc(_$hash, optionGroups.hashCode);
    _$hash = $jc(_$hash, variants.hashCode);
    _$hash = $jc(_$hash, promotions.hashCode);
    _$hash = $jc(_$hash, offers.hashCode);
    _$hash = $jc(_$hash, branchAvailability.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductResponseDto')
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
          ..add('branchAvailabilityMode', branchAvailabilityMode)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('cartItems', cartItems)
          ..add('favoritedBy', favoritedBy)
          ..add('orderItems', orderItems)
          ..add('optionGroups', optionGroups)
          ..add('variants', variants)
          ..add('promotions', promotions)
          ..add('offers', offers)
          ..add('branchAvailability', branchAvailability)
          ..add('category', category)
          ..add('vendor', vendor))
        .toString();
  }
}

class ProductResponseDtoBuilder
    implements Builder<ProductResponseDto, ProductResponseDtoBuilder> {
  _$ProductResponseDto? _$v;

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

  ProductResponseDtoBranchAvailabilityModeEnum? _branchAvailabilityMode;
  ProductResponseDtoBranchAvailabilityModeEnum? get branchAvailabilityMode =>
      _$this._branchAvailabilityMode;
  set branchAvailabilityMode(
    ProductResponseDtoBranchAvailabilityModeEnum? branchAvailabilityMode,
  ) => _$this._branchAvailabilityMode = branchAvailabilityMode;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ListBuilder<CartItem>? _cartItems;
  ListBuilder<CartItem> get cartItems =>
      _$this._cartItems ??= ListBuilder<CartItem>();
  set cartItems(ListBuilder<CartItem>? cartItems) =>
      _$this._cartItems = cartItems;

  ListBuilder<FavoriteProduct>? _favoritedBy;
  ListBuilder<FavoriteProduct> get favoritedBy =>
      _$this._favoritedBy ??= ListBuilder<FavoriteProduct>();
  set favoritedBy(ListBuilder<FavoriteProduct>? favoritedBy) =>
      _$this._favoritedBy = favoritedBy;

  ListBuilder<OrderItem>? _orderItems;
  ListBuilder<OrderItem> get orderItems =>
      _$this._orderItems ??= ListBuilder<OrderItem>();
  set orderItems(ListBuilder<OrderItem>? orderItems) =>
      _$this._orderItems = orderItems;

  ListBuilder<ProductOptionGroup>? _optionGroups;
  ListBuilder<ProductOptionGroup> get optionGroups =>
      _$this._optionGroups ??= ListBuilder<ProductOptionGroup>();
  set optionGroups(ListBuilder<ProductOptionGroup>? optionGroups) =>
      _$this._optionGroups = optionGroups;

  ListBuilder<ProductVariant>? _variants;
  ListBuilder<ProductVariant> get variants =>
      _$this._variants ??= ListBuilder<ProductVariant>();
  set variants(ListBuilder<ProductVariant>? variants) =>
      _$this._variants = variants;

  ListBuilder<Promotion>? _promotions;
  ListBuilder<Promotion> get promotions =>
      _$this._promotions ??= ListBuilder<Promotion>();
  set promotions(ListBuilder<Promotion>? promotions) =>
      _$this._promotions = promotions;

  ListBuilder<Offer>? _offers;
  ListBuilder<Offer> get offers => _$this._offers ??= ListBuilder<Offer>();
  set offers(ListBuilder<Offer>? offers) => _$this._offers = offers;

  ListBuilder<ProductBranchAvailability>? _branchAvailability;
  ListBuilder<ProductBranchAvailability> get branchAvailability =>
      _$this._branchAvailability ??= ListBuilder<ProductBranchAvailability>();
  set branchAvailability(
    ListBuilder<ProductBranchAvailability>? branchAvailability,
  ) => _$this._branchAvailability = branchAvailability;

  MenuCategoryBuilder? _category;
  MenuCategoryBuilder get category =>
      _$this._category ??= MenuCategoryBuilder();
  set category(MenuCategoryBuilder? category) => _$this._category = category;

  VendorBuilder? _vendor;
  VendorBuilder get vendor => _$this._vendor ??= VendorBuilder();
  set vendor(VendorBuilder? vendor) => _$this._vendor = vendor;

  ProductResponseDtoBuilder() {
    ProductResponseDto._defaults(this);
  }

  ProductResponseDtoBuilder get _$this {
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
      _branchAvailabilityMode = $v.branchAvailabilityMode;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _cartItems = $v.cartItems?.toBuilder();
      _favoritedBy = $v.favoritedBy?.toBuilder();
      _orderItems = $v.orderItems?.toBuilder();
      _optionGroups = $v.optionGroups?.toBuilder();
      _variants = $v.variants?.toBuilder();
      _promotions = $v.promotions?.toBuilder();
      _offers = $v.offers?.toBuilder();
      _branchAvailability = $v.branchAvailability?.toBuilder();
      _category = $v.category?.toBuilder();
      _vendor = $v.vendor?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductResponseDto other) {
    _$v = other as _$ProductResponseDto;
  }

  @override
  void update(void Function(ProductResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductResponseDto build() => _build();

  _$ProductResponseDto _build() {
    _$ProductResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$ProductResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'ProductResponseDto',
              'id',
            ),
            version: BuiltValueNullFieldError.checkNotNull(
              version,
              r'ProductResponseDto',
              'version',
            ),
            vendorId: BuiltValueNullFieldError.checkNotNull(
              vendorId,
              r'ProductResponseDto',
              'vendorId',
            ),
            categoryId: categoryId,
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ProductResponseDto',
              'name',
            ),
            nameAr: nameAr,
            description: description,
            descriptionAr: descriptionAr,
            imageUrl: imageUrl,
            sellByStrip: BuiltValueNullFieldError.checkNotNull(
              sellByStrip,
              r'ProductResponseDto',
              'sellByStrip',
            ),
            stripsPerPackage: stripsPerPackage,
            hasVariants: BuiltValueNullFieldError.checkNotNull(
              hasVariants,
              r'ProductResponseDto',
              'hasVariants',
            ),
            basePrice: basePrice,
            comparePrice: comparePrice,
            sku: sku,
            stock: stock,
            tracksStock: BuiltValueNullFieldError.checkNotNull(
              tracksStock,
              r'ProductResponseDto',
              'tracksStock',
            ),
            isActive: BuiltValueNullFieldError.checkNotNull(
              isActive,
              r'ProductResponseDto',
              'isActive',
            ),
            isFeatured: BuiltValueNullFieldError.checkNotNull(
              isFeatured,
              r'ProductResponseDto',
              'isFeatured',
            ),
            branchAvailabilityMode: BuiltValueNullFieldError.checkNotNull(
              branchAvailabilityMode,
              r'ProductResponseDto',
              'branchAvailabilityMode',
            ),
            deletedAt: deletedAt,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'ProductResponseDto',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'ProductResponseDto',
              'updatedAt',
            ),
            cartItems: _cartItems?.build(),
            favoritedBy: _favoritedBy?.build(),
            orderItems: _orderItems?.build(),
            optionGroups: _optionGroups?.build(),
            variants: _variants?.build(),
            promotions: _promotions?.build(),
            offers: _offers?.build(),
            branchAvailability: _branchAvailability?.build(),
            category: _category?.build(),
            vendor: _vendor?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'cartItems';
        _cartItems?.build();
        _$failedField = 'favoritedBy';
        _favoritedBy?.build();
        _$failedField = 'orderItems';
        _orderItems?.build();
        _$failedField = 'optionGroups';
        _optionGroups?.build();
        _$failedField = 'variants';
        _variants?.build();
        _$failedField = 'promotions';
        _promotions?.build();
        _$failedField = 'offers';
        _offers?.build();
        _$failedField = 'branchAvailability';
        _branchAvailability?.build();
        _$failedField = 'category';
        _category?.build();
        _$failedField = 'vendor';
        _vendor?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductResponseDto',
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
