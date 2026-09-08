// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_option.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductOption extends ProductOption {
  @override
  final String id;
  @override
  final String groupId;
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final num priceAdded;
  @override
  final bool isActive;

  factory _$ProductOption([void Function(ProductOptionBuilder)? updates]) =>
      (ProductOptionBuilder()..update(updates))._build();

  _$ProductOption._({
    required this.id,
    required this.groupId,
    required this.name,
    this.nameAr,
    required this.priceAdded,
    required this.isActive,
  }) : super._();
  @override
  ProductOption rebuild(void Function(ProductOptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductOptionBuilder toBuilder() => ProductOptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductOption &&
        id == other.id &&
        groupId == other.groupId &&
        name == other.name &&
        nameAr == other.nameAr &&
        priceAdded == other.priceAdded &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, priceAdded.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductOption')
          ..add('id', id)
          ..add('groupId', groupId)
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('priceAdded', priceAdded)
          ..add('isActive', isActive))
        .toString();
  }
}

class ProductOptionBuilder
    implements Builder<ProductOption, ProductOptionBuilder> {
  _$ProductOption? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  num? _priceAdded;
  num? get priceAdded => _$this._priceAdded;
  set priceAdded(num? priceAdded) => _$this._priceAdded = priceAdded;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  ProductOptionBuilder() {
    ProductOption._defaults(this);
  }

  ProductOptionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _groupId = $v.groupId;
      _name = $v.name;
      _nameAr = $v.nameAr;
      _priceAdded = $v.priceAdded;
      _isActive = $v.isActive;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductOption other) {
    _$v = other as _$ProductOption;
  }

  @override
  void update(void Function(ProductOptionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductOption build() => _build();

  _$ProductOption _build() {
    final _$result =
        _$v ??
        _$ProductOption._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'ProductOption', 'id'),
          groupId: BuiltValueNullFieldError.checkNotNull(
            groupId,
            r'ProductOption',
            'groupId',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'ProductOption',
            'name',
          ),
          nameAr: nameAr,
          priceAdded: BuiltValueNullFieldError.checkNotNull(
            priceAdded,
            r'ProductOption',
            'priceAdded',
          ),
          isActive: BuiltValueNullFieldError.checkNotNull(
            isActive,
            r'ProductOption',
            'isActive',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
