// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_vendor_vertical_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateVendorVerticalDto extends CreateVendorVerticalDto {
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String slug;
  @override
  final String? iconUrl;
  @override
  final bool? isActive;
  @override
  final num? sortOrder;

  factory _$CreateVendorVerticalDto([
    void Function(CreateVendorVerticalDtoBuilder)? updates,
  ]) => (CreateVendorVerticalDtoBuilder()..update(updates))._build();

  _$CreateVendorVerticalDto._({
    required this.name,
    this.nameAr,
    required this.slug,
    this.iconUrl,
    this.isActive,
    this.sortOrder,
  }) : super._();
  @override
  CreateVendorVerticalDto rebuild(
    void Function(CreateVendorVerticalDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateVendorVerticalDtoBuilder toBuilder() =>
      CreateVendorVerticalDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateVendorVerticalDto &&
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
    return (newBuiltValueToStringHelper(r'CreateVendorVerticalDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('slug', slug)
          ..add('iconUrl', iconUrl)
          ..add('isActive', isActive)
          ..add('sortOrder', sortOrder))
        .toString();
  }
}

class CreateVendorVerticalDtoBuilder
    implements
        Builder<CreateVendorVerticalDto, CreateVendorVerticalDtoBuilder> {
  _$CreateVendorVerticalDto? _$v;

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

  CreateVendorVerticalDtoBuilder() {
    CreateVendorVerticalDto._defaults(this);
  }

  CreateVendorVerticalDtoBuilder get _$this {
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
  void replace(CreateVendorVerticalDto other) {
    _$v = other as _$CreateVendorVerticalDto;
  }

  @override
  void update(void Function(CreateVendorVerticalDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateVendorVerticalDto build() => _build();

  _$CreateVendorVerticalDto _build() {
    final _$result =
        _$v ??
        _$CreateVendorVerticalDto._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateVendorVerticalDto',
            'name',
          ),
          nameAr: nameAr,
          slug: BuiltValueNullFieldError.checkNotNull(
            slug,
            r'CreateVendorVerticalDto',
            'slug',
          ),
          iconUrl: iconUrl,
          isActive: isActive,
          sortOrder: sortOrder,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
