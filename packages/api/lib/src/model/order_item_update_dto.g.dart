// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_update_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderItemUpdateDto extends OrderItemUpdateDto {
  @override
  final String productId;
  @override
  final String? variantId;
  @override
  final num quantity;
  @override
  final BuiltList<String>? optionIds;
  @override
  final String? specialRequest;

  factory _$OrderItemUpdateDto([
    void Function(OrderItemUpdateDtoBuilder)? updates,
  ]) => (OrderItemUpdateDtoBuilder()..update(updates))._build();

  _$OrderItemUpdateDto._({
    required this.productId,
    this.variantId,
    required this.quantity,
    this.optionIds,
    this.specialRequest,
  }) : super._();
  @override
  OrderItemUpdateDto rebuild(
    void Function(OrderItemUpdateDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderItemUpdateDtoBuilder toBuilder() =>
      OrderItemUpdateDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderItemUpdateDto &&
        productId == other.productId &&
        variantId == other.variantId &&
        quantity == other.quantity &&
        optionIds == other.optionIds &&
        specialRequest == other.specialRequest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, variantId.hashCode);
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, optionIds.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderItemUpdateDto')
          ..add('productId', productId)
          ..add('variantId', variantId)
          ..add('quantity', quantity)
          ..add('optionIds', optionIds)
          ..add('specialRequest', specialRequest))
        .toString();
  }
}

class OrderItemUpdateDtoBuilder
    implements Builder<OrderItemUpdateDto, OrderItemUpdateDtoBuilder> {
  _$OrderItemUpdateDto? _$v;

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

  OrderItemUpdateDtoBuilder() {
    OrderItemUpdateDto._defaults(this);
  }

  OrderItemUpdateDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _productId = $v.productId;
      _variantId = $v.variantId;
      _quantity = $v.quantity;
      _optionIds = $v.optionIds?.toBuilder();
      _specialRequest = $v.specialRequest;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderItemUpdateDto other) {
    _$v = other as _$OrderItemUpdateDto;
  }

  @override
  void update(void Function(OrderItemUpdateDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderItemUpdateDto build() => _build();

  _$OrderItemUpdateDto _build() {
    _$OrderItemUpdateDto _$result;
    try {
      _$result =
          _$v ??
          _$OrderItemUpdateDto._(
            productId: BuiltValueNullFieldError.checkNotNull(
              productId,
              r'OrderItemUpdateDto',
              'productId',
            ),
            variantId: variantId,
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'OrderItemUpdateDto',
              'quantity',
            ),
            optionIds: _optionIds?.build(),
            specialRequest: specialRequest,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'optionIds';
        _optionIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderItemUpdateDto',
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
