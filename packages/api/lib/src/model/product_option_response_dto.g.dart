// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_option_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductOptionResponseDto extends ProductOptionResponseDto {
  @override
  final String id;
  @override
  final String groupId;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final num priceAdded;
  @override
  final bool isActive;
  @override
  final BuiltList<CartItemOption>? cartItemOptions;
  @override
  final BuiltList<OrderItemOption>? orderItemOptions;
  @override
  final ProductOptionGroup? group;

  factory _$ProductOptionResponseDto([
    void Function(ProductOptionResponseDtoBuilder)? updates,
  ]) => (ProductOptionResponseDtoBuilder()..update(updates))._build();

  _$ProductOptionResponseDto._({
    required this.id,
    required this.groupId,
    required this.name,
    this.nameAr,
    required this.priceAdded,
    required this.isActive,
    this.cartItemOptions,
    this.orderItemOptions,
    this.group,
  }) : super._();
  @override
  ProductOptionResponseDto rebuild(
    void Function(ProductOptionResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductOptionResponseDtoBuilder toBuilder() =>
      ProductOptionResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductOptionResponseDto &&
        id == other.id &&
        groupId == other.groupId &&
        name == other.name &&
        nameAr == other.nameAr &&
        priceAdded == other.priceAdded &&
        isActive == other.isActive &&
        cartItemOptions == other.cartItemOptions &&
        orderItemOptions == other.orderItemOptions &&
        group == other.group;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, priceAdded.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, cartItemOptions.hashCode);
    _$hash = $jc(_$hash, orderItemOptions.hashCode);
    _$hash = $jc(_$hash, group.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductOptionResponseDto')
          ..add('id', id)
          ..add('groupId', groupId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('priceAdded', priceAdded)
          ..add('isActive', isActive)
          ..add('cartItemOptions', cartItemOptions)
          ..add('orderItemOptions', orderItemOptions)
          ..add('group', group))
        .toString();
  }
}

class ProductOptionResponseDtoBuilder
    implements
        Builder<ProductOptionResponseDto, ProductOptionResponseDtoBuilder> {
  _$ProductOptionResponseDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  num? _priceAdded;
  num? get priceAdded => _$this._priceAdded;
  set priceAdded(num? priceAdded) => _$this._priceAdded = priceAdded;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  ListBuilder<CartItemOption>? _cartItemOptions;
  ListBuilder<CartItemOption> get cartItemOptions =>
      _$this._cartItemOptions ??= ListBuilder<CartItemOption>();
  set cartItemOptions(ListBuilder<CartItemOption>? cartItemOptions) =>
      _$this._cartItemOptions = cartItemOptions;

  ListBuilder<OrderItemOption>? _orderItemOptions;
  ListBuilder<OrderItemOption> get orderItemOptions =>
      _$this._orderItemOptions ??= ListBuilder<OrderItemOption>();
  set orderItemOptions(ListBuilder<OrderItemOption>? orderItemOptions) =>
      _$this._orderItemOptions = orderItemOptions;

  ProductOptionGroupBuilder? _group;
  ProductOptionGroupBuilder get group =>
      _$this._group ??= ProductOptionGroupBuilder();
  set group(ProductOptionGroupBuilder? group) => _$this._group = group;

  ProductOptionResponseDtoBuilder() {
    ProductOptionResponseDto._defaults(this);
  }

  ProductOptionResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _groupId = $v.groupId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _priceAdded = $v.priceAdded;
      _isActive = $v.isActive;
      _cartItemOptions = $v.cartItemOptions?.toBuilder();
      _orderItemOptions = $v.orderItemOptions?.toBuilder();
      _group = $v.group?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductOptionResponseDto other) {
    _$v = other as _$ProductOptionResponseDto;
  }

  @override
  void update(void Function(ProductOptionResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductOptionResponseDto build() => _build();

  _$ProductOptionResponseDto _build() {
    _$ProductOptionResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$ProductOptionResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'ProductOptionResponseDto',
              'id',
            ),
            groupId: BuiltValueNullFieldError.checkNotNull(
              groupId,
              r'ProductOptionResponseDto',
              'groupId',
            ),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ProductOptionResponseDto',
              'name',
            ),
            nameAr: nameAr,
            priceAdded: BuiltValueNullFieldError.checkNotNull(
              priceAdded,
              r'ProductOptionResponseDto',
              'priceAdded',
            ),
            isActive: BuiltValueNullFieldError.checkNotNull(
              isActive,
              r'ProductOptionResponseDto',
              'isActive',
            ),
            cartItemOptions: _cartItemOptions?.build(),
            orderItemOptions: _orderItemOptions?.build(),
            group: _group?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'cartItemOptions';
        _cartItemOptions?.build();
        _$failedField = 'orderItemOptions';
        _orderItemOptions?.build();
        _$failedField = 'group';
        _group?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductOptionResponseDto',
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
