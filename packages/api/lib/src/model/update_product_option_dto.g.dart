// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_product_option_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateProductOptionDto extends UpdateProductOptionDto {
  @override
  final String? name;
  @override
  final String? nameAr;
  @override
  final num? priceAdded;
  @override
  final bool? isActive;

  factory _$UpdateProductOptionDto([
    void Function(UpdateProductOptionDtoBuilder)? updates,
  ]) => (UpdateProductOptionDtoBuilder()..update(updates))._build();

  _$UpdateProductOptionDto._({
    this.name,
    this.nameAr,
    this.priceAdded,
    this.isActive,
  }) : super._();
  @override
  UpdateProductOptionDto rebuild(
    void Function(UpdateProductOptionDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateProductOptionDtoBuilder toBuilder() =>
      UpdateProductOptionDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateProductOptionDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        priceAdded == other.priceAdded &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, priceAdded.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateProductOptionDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('priceAdded', priceAdded)
          ..add('isActive', isActive))
        .toString();
  }
}

class UpdateProductOptionDtoBuilder
    implements Builder<UpdateProductOptionDto, UpdateProductOptionDtoBuilder> {
  _$UpdateProductOptionDto? _$v;

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

  UpdateProductOptionDtoBuilder() {
    UpdateProductOptionDto._defaults(this);
  }

  UpdateProductOptionDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _priceAdded = $v.priceAdded;
      _isActive = $v.isActive;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateProductOptionDto other) {
    _$v = other as _$UpdateProductOptionDto;
  }

  @override
  void update(void Function(UpdateProductOptionDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateProductOptionDto build() => _build();

  _$UpdateProductOptionDto _build() {
    final _$result =
        _$v ??
        _$UpdateProductOptionDto._(
          name: name,
          nameAr: nameAr,
          priceAdded: priceAdded,
          isActive: isActive,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
