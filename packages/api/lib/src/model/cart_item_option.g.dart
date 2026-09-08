// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_option.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CartItemOption extends CartItemOption {
  @override
  final String id;
  @override
  final String cartItemId;
  @override
  final String optionId;

  factory _$CartItemOption([void Function(CartItemOptionBuilder)? updates]) =>
      (CartItemOptionBuilder()..update(updates))._build();

  _$CartItemOption._({
    required this.id,
    required this.cartItemId,
    required this.optionId,
  }) : super._();
  @override
  CartItemOption rebuild(void Function(CartItemOptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CartItemOptionBuilder toBuilder() => CartItemOptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CartItemOption &&
        id == other.id &&
        cartItemId == other.cartItemId &&
        optionId == other.optionId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, cartItemId.hashCode);
    _$hash = $jc(_$hash, optionId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CartItemOption')
          ..add('id', id)
          ..add('cartItemId', cartItemId)
          ..add('optionId', optionId))
        .toString();
  }
}

class CartItemOptionBuilder
    implements Builder<CartItemOption, CartItemOptionBuilder> {
  _$CartItemOption? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _cartItemId;
  String? get cartItemId => _$this._cartItemId;
  set cartItemId(String? cartItemId) => _$this._cartItemId = cartItemId;

  String? _optionId;
  String? get optionId => _$this._optionId;
  set optionId(String? optionId) => _$this._optionId = optionId;

  CartItemOptionBuilder() {
    CartItemOption._defaults(this);
  }

  CartItemOptionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _cartItemId = $v.cartItemId;
      _optionId = $v.optionId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CartItemOption other) {
    _$v = other as _$CartItemOption;
  }

  @override
  void update(void Function(CartItemOptionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CartItemOption build() => _build();

  _$CartItemOption _build() {
    final _$result =
        _$v ??
        _$CartItemOption._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'CartItemOption',
            'id',
          ),
          cartItemId: BuiltValueNullFieldError.checkNotNull(
            cartItemId,
            r'CartItemOption',
            'cartItemId',
          ),
          optionId: BuiltValueNullFieldError.checkNotNull(
            optionId,
            r'CartItemOption',
            'optionId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
