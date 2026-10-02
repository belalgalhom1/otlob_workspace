// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_cart_item_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AddCartItemDto extends AddCartItemDto {
  @override
  final String? productId;
  @override
  final String? variantId;
  @override
  final num quantity;
  @override
  final BuiltList<String>? optionIds;
  @override
  final String? specialRequest;
  @override
  final String? selectedUnit;
  @override
  final String? offerMessageId;

  factory _$AddCartItemDto([void Function(AddCartItemDtoBuilder)? updates]) =>
      (AddCartItemDtoBuilder()..update(updates))._build();

  _$AddCartItemDto._({
    this.productId,
    this.variantId,
    required this.quantity,
    this.optionIds,
    this.specialRequest,
    this.selectedUnit,
    this.offerMessageId,
  }) : super._();
  @override
  AddCartItemDto rebuild(void Function(AddCartItemDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AddCartItemDtoBuilder toBuilder() => AddCartItemDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AddCartItemDto &&
        productId == other.productId &&
        variantId == other.variantId &&
        quantity == other.quantity &&
        optionIds == other.optionIds &&
        specialRequest == other.specialRequest &&
        selectedUnit == other.selectedUnit &&
        offerMessageId == other.offerMessageId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, variantId.hashCode);
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, optionIds.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jc(_$hash, selectedUnit.hashCode);
    _$hash = $jc(_$hash, offerMessageId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AddCartItemDto')
          ..add('productId', productId)
          ..add('variantId', variantId)
          ..add('quantity', quantity)
          ..add('optionIds', optionIds)
          ..add('specialRequest', specialRequest)
          ..add('selectedUnit', selectedUnit)
          ..add('offerMessageId', offerMessageId))
        .toString();
  }
}

class AddCartItemDtoBuilder
    implements Builder<AddCartItemDto, AddCartItemDtoBuilder> {
  _$AddCartItemDto? _$v;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _variantId;
  String? get variantId => _$this._variantId;
  set variantId(String? variantId) => _$this._variantId = variantId;

  num? _quantity;
  num? get quantity => _$this._quantity;
  set quantity(num? quantity) => _$this._quantity = quantity;

  ListBuilder<String>? _optionIds;
  ListBuilder<String> get optionIds =>
      _$this._optionIds ??= ListBuilder<String>();
  set optionIds(ListBuilder<String>? optionIds) =>
      _$this._optionIds = optionIds;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  String? _selectedUnit;
  String? get selectedUnit => _$this._selectedUnit;
  set selectedUnit(String? selectedUnit) => _$this._selectedUnit = selectedUnit;

  String? _offerMessageId;
  String? get offerMessageId => _$this._offerMessageId;
  set offerMessageId(String? offerMessageId) =>
      _$this._offerMessageId = offerMessageId;

  AddCartItemDtoBuilder() {
    AddCartItemDto._defaults(this);
  }

  AddCartItemDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _productId = $v.productId;
      _variantId = $v.variantId;
      _quantity = $v.quantity;
      _optionIds = $v.optionIds?.toBuilder();
      _specialRequest = $v.specialRequest;
      _selectedUnit = $v.selectedUnit;
      _offerMessageId = $v.offerMessageId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AddCartItemDto other) {
    _$v = other as _$AddCartItemDto;
  }

  @override
  void update(void Function(AddCartItemDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AddCartItemDto build() => _build();

  _$AddCartItemDto _build() {
    _$AddCartItemDto _$result;
    try {
      _$result =
          _$v ??
          _$AddCartItemDto._(
            productId: productId,
            variantId: variantId,
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'AddCartItemDto',
              'quantity',
            ),
            optionIds: _optionIds?.build(),
            specialRequest: specialRequest,
            selectedUnit: selectedUnit,
            offerMessageId: offerMessageId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'optionIds';
        _optionIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AddCartItemDto',
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
