// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_order_items_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EditOrderItemsDto extends EditOrderItemsDto {
  @override
  final BuiltList<OrderItemUpdateDto> items;

  factory _$EditOrderItemsDto([
    void Function(EditOrderItemsDtoBuilder)? updates,
  ]) => (EditOrderItemsDtoBuilder()..update(updates))._build();

  _$EditOrderItemsDto._({required this.items}) : super._();
  @override
  EditOrderItemsDto rebuild(void Function(EditOrderItemsDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EditOrderItemsDtoBuilder toBuilder() =>
      EditOrderItemsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EditOrderItemsDto && items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'EditOrderItemsDto',
    )..add('items', items)).toString();
  }
}

class EditOrderItemsDtoBuilder
    implements Builder<EditOrderItemsDto, EditOrderItemsDtoBuilder> {
  _$EditOrderItemsDto? _$v;

  ListBuilder<OrderItemUpdateDto>? _items;
  ListBuilder<OrderItemUpdateDto> get items =>
      _$this._items ??= ListBuilder<OrderItemUpdateDto>();
  set items(ListBuilder<OrderItemUpdateDto>? items) => _$this._items = items;

  EditOrderItemsDtoBuilder() {
    EditOrderItemsDto._defaults(this);
  }

  EditOrderItemsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EditOrderItemsDto other) {
    _$v = other as _$EditOrderItemsDto;
  }

  @override
  void update(void Function(EditOrderItemsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EditOrderItemsDto build() => _build();

  _$EditOrderItemsDto _build() {
    _$EditOrderItemsDto _$result;
    try {
      _$result = _$v ?? _$EditOrderItemsDto._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'EditOrderItemsDto',
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
