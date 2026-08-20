// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_vendor_vertical_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateVendorVerticalDto extends UpdateVendorVerticalDto {
  @override
  final String? name;
  @override
  final String? nameAr;
  @override
  final String? slug;
  @override
  final String? iconUrl;
  @override
  final bool? isActive;
  @override
  final num? sortOrder;

  factory _$UpdateVendorVerticalDto([
    void Function(UpdateVendorVerticalDtoBuilder)? updates,
  ]) => (UpdateVendorVerticalDtoBuilder()..update(updates))._build();

  _$UpdateVendorVerticalDto._({
    this.name,
    this.nameAr,
    this.slug,
    this.iconUrl,
    this.isActive,
    this.sortOrder,
  }) : super._();
  @override
  UpdateVendorVerticalDto rebuild(
    void Function(UpdateVendorVerticalDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateVendorVerticalDtoBuilder toBuilder() =>
      UpdateVendorVerticalDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateVendorVerticalDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        slug == other.slug &&
        iconUrl == other.iconUrl &&
        isActive == other.isActive &&
        sortOrder == other.sortOrder;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, iconUrl.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateVendorVerticalDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('slug', slug)
          ..add('iconUrl', iconUrl)
          ..add('isActive', isActive)
          ..add('sortOrder', sortOrder))
        .toString();
  }
}

class UpdateVendorVerticalDtoBuilder
    implements
        Builder<UpdateVendorVerticalDto, UpdateVendorVerticalDtoBuilder> {
  _$UpdateVendorVerticalDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _iconUrl;
  String? get iconUrl => _$this._iconUrl;
  set iconUrl(String? iconUrl) => _$this._iconUrl = iconUrl;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  num? _sortOrder;
  num? get sortOrder => _$this._sortOrder;
  set sortOrder(num? sortOrder) => _$this._sortOrder = sortOrder;

  UpdateVendorVerticalDtoBuilder() {
    UpdateVendorVerticalDto._defaults(this);
  }

  UpdateVendorVerticalDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _slug = $v.slug;
      _iconUrl = $v.iconUrl;
      _isActive = $v.isActive;
      _sortOrder = $v.sortOrder;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateVendorVerticalDto other) {
    _$v = other as _$UpdateVendorVerticalDto;
  }

  @override
  void update(void Function(UpdateVendorVerticalDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateVendorVerticalDto build() => _build();

  _$UpdateVendorVerticalDto _build() {
    final _$result =
        _$v ??
        _$UpdateVendorVerticalDto._(
          name: name,
          nameAr: nameAr,
          slug: slug,
          iconUrl: iconUrl,
          isActive: isActive,
          sortOrder: sortOrder,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
