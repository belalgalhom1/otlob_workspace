// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_cart_item_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateCartItemDto extends UpdateCartItemDto {
  @override
  final num quantity;
  @override
  final BuiltList<String>? optionIds;
  @override
  final String? specialRequest;

  factory _$UpdateCartItemDto([
    void Function(UpdateCartItemDtoBuilder)? updates,
  ]) => (UpdateCartItemDtoBuilder()..update(updates))._build();

  _$UpdateCartItemDto._({
    required this.quantity,
    this.optionIds,
    this.specialRequest,
  }) : super._();
  @override
  UpdateCartItemDto rebuild(void Function(UpdateCartItemDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateCartItemDtoBuilder toBuilder() =>
      UpdateCartItemDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateCartItemDto &&
        quantity == other.quantity &&
        optionIds == other.optionIds &&
        specialRequest == other.specialRequest;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, optionIds.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateCartItemDto')
          ..add('quantity', quantity)
          ..add('optionIds', optionIds)
          ..add('specialRequest', specialRequest))
        .toString();
  }
}

class UpdateCartItemDtoBuilder
    implements Builder<UpdateCartItemDto, UpdateCartItemDtoBuilder> {
  _$UpdateCartItemDto? _$v;

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

  UpdateCartItemDtoBuilder() {
    UpdateCartItemDto._defaults(this);
  }

  UpdateCartItemDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _quantity = $v.quantity;
      _optionIds = $v.optionIds?.toBuilder();
      _specialRequest = $v.specialRequest;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateCartItemDto other) {
    _$v = other as _$UpdateCartItemDto;
  }

  @override
  void update(void Function(UpdateCartItemDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateCartItemDto build() => _build();

  _$UpdateCartItemDto _build() {
    _$UpdateCartItemDto _$result;
    try {
      _$result =
          _$v ??
          _$UpdateCartItemDto._(
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'UpdateCartItemDto',
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
          r'UpdateCartItemDto',
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
