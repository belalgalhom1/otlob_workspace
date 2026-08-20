// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_customers_in_polygon_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SearchCustomersInPolygonDto extends SearchCustomersInPolygonDto {
  @override
  final BuiltList<String> polygon;

  factory _$SearchCustomersInPolygonDto([
    void Function(SearchCustomersInPolygonDtoBuilder)? updates,
  ]) => (SearchCustomersInPolygonDtoBuilder()..update(updates))._build();

  _$SearchCustomersInPolygonDto._({required this.polygon}) : super._();
  @override
  SearchCustomersInPolygonDto rebuild(
    void Function(SearchCustomersInPolygonDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SearchCustomersInPolygonDtoBuilder toBuilder() =>
      SearchCustomersInPolygonDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SearchCustomersInPolygonDto && polygon == other.polygon;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, polygon.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'SearchCustomersInPolygonDto',
    )..add('polygon', polygon)).toString();
  }
}

class SearchCustomersInPolygonDtoBuilder
    implements
        Builder<
          SearchCustomersInPolygonDto,
          SearchCustomersInPolygonDtoBuilder
        > {
  _$SearchCustomersInPolygonDto? _$v;

  ListBuilder<String>? _polygon;
  ListBuilder<String> get polygon => _$this._polygon ??= ListBuilder<String>();
  set polygon(ListBuilder<String>? polygon) => _$this._polygon = polygon;

  SearchCustomersInPolygonDtoBuilder() {
    SearchCustomersInPolygonDto._defaults(this);
  }

  SearchCustomersInPolygonDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _polygon = $v.polygon.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SearchCustomersInPolygonDto other) {
    _$v = other as _$SearchCustomersInPolygonDto;
  }

  @override
  void update(void Function(SearchCustomersInPolygonDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SearchCustomersInPolygonDto build() => _build();

  _$SearchCustomersInPolygonDto _build() {
    _$SearchCustomersInPolygonDto _$result;
    try {
      _$result =
          _$v ?? _$SearchCustomersInPolygonDto._(polygon: polygon.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'polygon';
        polygon.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SearchCustomersInPolygonDto',
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
