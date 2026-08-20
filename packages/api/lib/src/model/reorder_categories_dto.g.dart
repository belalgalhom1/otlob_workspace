// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_categories_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReorderCategoriesDto extends ReorderCategoriesDto {
  @override
  final BuiltList<String> items;

  factory _$ReorderCategoriesDto([
    void Function(ReorderCategoriesDtoBuilder)? updates,
  ]) => (ReorderCategoriesDtoBuilder()..update(updates))._build();

  _$ReorderCategoriesDto._({required this.items}) : super._();
  @override
  ReorderCategoriesDto rebuild(
    void Function(ReorderCategoriesDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ReorderCategoriesDtoBuilder toBuilder() =>
      ReorderCategoriesDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReorderCategoriesDto && items == other.items;
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
      r'ReorderCategoriesDto',
    )..add('items', items)).toString();
  }
}

class ReorderCategoriesDtoBuilder
    implements Builder<ReorderCategoriesDto, ReorderCategoriesDtoBuilder> {
  _$ReorderCategoriesDto? _$v;

  ListBuilder<String>? _items;
  ListBuilder<String> get items => _$this._items ??= ListBuilder<String>();
  set items(ListBuilder<String>? items) => _$this._items = items;

  ReorderCategoriesDtoBuilder() {
    ReorderCategoriesDto._defaults(this);
  }

  ReorderCategoriesDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReorderCategoriesDto other) {
    _$v = other as _$ReorderCategoriesDto;
  }

  @override
  void update(void Function(ReorderCategoriesDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReorderCategoriesDto build() => _build();

  _$ReorderCategoriesDto _build() {
    _$ReorderCategoriesDto _$result;
    try {
      _$result = _$v ?? _$ReorderCategoriesDto._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ReorderCategoriesDto',
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
