// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MenuCategory extends MenuCategory {
  @override
  final String id;
  @override
  final String vendorId;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final String? iconUrl;
  @override
  final num sortOrder;
  @override
  final bool isActive;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$MenuCategory([void Function(MenuCategoryBuilder)? updates]) =>
      (MenuCategoryBuilder()..update(updates))._build();

  _$MenuCategory._({
    required this.id,
    required this.vendorId,
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.iconUrl,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  MenuCategory rebuild(void Function(MenuCategoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MenuCategoryBuilder toBuilder() => MenuCategoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MenuCategory &&
        id == other.id &&
        vendorId == other.vendorId &&
        name == other.name &&
        nameAr == other.nameAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        iconUrl == other.iconUrl &&
        sortOrder == other.sortOrder &&
        isActive == other.isActive &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, iconUrl.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MenuCategory')
          ..add('id', id)
          ..add('vendorId', vendorId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('iconUrl', iconUrl)
          ..add('sortOrder', sortOrder)
          ..add('isActive', isActive)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class MenuCategoryBuilder
    implements Builder<MenuCategory, MenuCategoryBuilder> {
  _$MenuCategory? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _descriptionAr;
  String? get descriptionAr => _$this._descriptionAr;
  set descriptionAr(String? descriptionAr) =>
      _$this._descriptionAr = descriptionAr;

  String? _iconUrl;
  String? get iconUrl => _$this._iconUrl;
  set iconUrl(String? iconUrl) => _$this._iconUrl = iconUrl;

  num? _sortOrder;
  num? get sortOrder => _$this._sortOrder;
  set sortOrder(num? sortOrder) => _$this._sortOrder = sortOrder;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  MenuCategoryBuilder() {
    MenuCategory._defaults(this);
  }

  MenuCategoryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _vendorId = $v.vendorId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _iconUrl = $v.iconUrl;
      _sortOrder = $v.sortOrder;
      _isActive = $v.isActive;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MenuCategory other) {
    _$v = other as _$MenuCategory;
  }

  @override
  void update(void Function(MenuCategoryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MenuCategory build() => _build();

  _$MenuCategory _build() {
    final _$result =
        _$v ??
        _$MenuCategory._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'MenuCategory', 'id'),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'MenuCategory',
            'vendorId',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'MenuCategory',
            'name',
          ),
          nameAr: nameAr,
          description: description,
          descriptionAr: descriptionAr,
          iconUrl: iconUrl,
          sortOrder: BuiltValueNullFieldError.checkNotNull(
            sortOrder,
            r'MenuCategory',
            'sortOrder',
          ),
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'MenuCategory',
            'isActive',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'MenuCategory',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'MenuCategory',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
