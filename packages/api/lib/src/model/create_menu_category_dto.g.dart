// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_menu_category_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateMenuCategoryDto extends CreateMenuCategoryDto {
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final num? sortOrder;
  @override
  final bool? isActive;
  @override
  final String? iconUrl;
  @override
  final String? branchAvailabilityMode;
  @override
  final BuiltList<String>? branchIds;

  factory _$CreateMenuCategoryDto([
    void Function(CreateMenuCategoryDtoBuilder)? updates,
  ]) => (CreateMenuCategoryDtoBuilder()..update(updates))._build();

  _$CreateMenuCategoryDto._({
    required this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.sortOrder,
    this.isActive,
    this.iconUrl,
    this.branchAvailabilityMode,
    this.branchIds,
  }) : super._();
  @override
  CreateMenuCategoryDto rebuild(
    void Function(CreateMenuCategoryDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateMenuCategoryDtoBuilder toBuilder() =>
      CreateMenuCategoryDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateMenuCategoryDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        sortOrder == other.sortOrder &&
        isActive == other.isActive &&
        iconUrl == other.iconUrl &&
        branchAvailabilityMode == other.branchAvailabilityMode &&
        branchIds == other.branchIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, iconUrl.hashCode);
    _$hash = $jc(_$hash, branchAvailabilityMode.hashCode);
    _$hash = $jc(_$hash, branchIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateMenuCategoryDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('sortOrder', sortOrder)
          ..add('isActive', isActive)
          ..add('iconUrl', iconUrl)
          ..add('branchAvailabilityMode', branchAvailabilityMode)
          ..add('branchIds', branchIds))
        .toString();
  }
}

class CreateMenuCategoryDtoBuilder
    implements Builder<CreateMenuCategoryDto, CreateMenuCategoryDtoBuilder> {
  _$CreateMenuCategoryDto? _$v;

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

  num? _sortOrder;
  num? get sortOrder => _$this._sortOrder;
  set sortOrder(num? sortOrder) => _$this._sortOrder = sortOrder;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  String? _iconUrl;
  String? get iconUrl => _$this._iconUrl;
  set iconUrl(String? iconUrl) => _$this._iconUrl = iconUrl;

  String? _branchAvailabilityMode;
  String? get branchAvailabilityMode => _$this._branchAvailabilityMode;
  set branchAvailabilityMode(String? branchAvailabilityMode) =>
      _$this._branchAvailabilityMode = branchAvailabilityMode;

  ListBuilder<String>? _branchIds;
  ListBuilder<String> get branchIds =>
      _$this._branchIds ??= ListBuilder<String>();
  set branchIds(ListBuilder<String>? branchIds) =>
      _$this._branchIds = branchIds;

  CreateMenuCategoryDtoBuilder() {
    CreateMenuCategoryDto._defaults(this);
  }

  CreateMenuCategoryDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _sortOrder = $v.sortOrder;
      _isActive = $v.isActive;
      _iconUrl = $v.iconUrl;
      _branchAvailabilityMode = $v.branchAvailabilityMode;
      _branchIds = $v.branchIds?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateMenuCategoryDto other) {
    _$v = other as _$CreateMenuCategoryDto;
  }

  @override
  void update(void Function(CreateMenuCategoryDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateMenuCategoryDto build() => _build();

  _$CreateMenuCategoryDto _build() {
    _$CreateMenuCategoryDto _$result;
    try {
      _$result =
          _$v ??
          _$CreateMenuCategoryDto._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'CreateMenuCategoryDto',
              'name',
            ),
            nameAr: nameAr,
            description: description,
            descriptionAr: descriptionAr,
            sortOrder: sortOrder,
            isActive: isActive,
            iconUrl: iconUrl,
            branchAvailabilityMode: branchAvailabilityMode,
            branchIds: _branchIds?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'branchIds';
        _branchIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateMenuCategoryDto',
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
