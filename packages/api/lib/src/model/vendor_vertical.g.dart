// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_vertical.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VendorVertical extends VendorVertical {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String slug;
  @override
  final String? iconUrl;
  @override
  final bool isActive;
  @override
  final num sortOrder;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final BuiltList<Vendor> vendors;

  factory _$VendorVertical([void Function(VendorVerticalBuilder)? updates]) =>
      (VendorVerticalBuilder()..update(updates))._build();

  _$VendorVertical._({
    required this.id,
    required this.name,
    this.nameAr,
    required this.slug,
    this.iconUrl,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.vendors,
  }) : super._();
  @override
  VendorVertical rebuild(void Function(VendorVerticalBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VendorVerticalBuilder toBuilder() => VendorVerticalBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VendorVertical &&
        id == other.id &&
        name == other.name &&
        nameAr == other.nameAr &&
        slug == other.slug &&
        iconUrl == other.iconUrl &&
        isActive == other.isActive &&
        sortOrder == other.sortOrder &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        vendors == other.vendors;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, iconUrl.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, vendors.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VendorVertical')
          ..add('id', id)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('slug', slug)
          ..add('iconUrl', iconUrl)
          ..add('isActive', isActive)
          ..add('sortOrder', sortOrder)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('vendors', vendors))
        .toString();
  }
}

class VendorVerticalBuilder
    implements Builder<VendorVertical, VendorVerticalBuilder> {
  _$VendorVertical? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

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

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ListBuilder<Vendor>? _vendors;
  ListBuilder<Vendor> get vendors => _$this._vendors ??= ListBuilder<Vendor>();
  set vendors(ListBuilder<Vendor>? vendors) => _$this._vendors = vendors;

  VendorVerticalBuilder() {
    VendorVertical._defaults(this);
  }

  VendorVerticalBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _slug = $v.slug;
      _iconUrl = $v.iconUrl;
      _isActive = $v.isActive;
      _sortOrder = $v.sortOrder;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _vendors = $v.vendors.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VendorVertical other) {
    _$v = other as _$VendorVertical;
  }

  @override
  void update(void Function(VendorVerticalBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VendorVertical build() => _build();

  _$VendorVertical _build() {
    _$VendorVertical _$result;
    try {
      _$result =
          _$v ??
          _$VendorVertical._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'VendorVertical',
              'id',
            ),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'VendorVertical',
              'name',
            ),
            nameAr: nameAr,
            slug: BuiltValueNullFieldError.checkNotNull(
              slug,
              r'VendorVertical',
              'slug',
            ),
            iconUrl: iconUrl,
            isActive: BuiltValueNullFieldError.checkNotNull(
              isActive,
              r'VendorVertical',
              'isActive',
            ),
            sortOrder: BuiltValueNullFieldError.checkNotNull(
              sortOrder,
              r'VendorVertical',
              'sortOrder',
            ),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'VendorVertical',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'VendorVertical',
              'updatedAt',
            ),
            vendors: vendors.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vendors';
        vendors.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'VendorVertical',
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
