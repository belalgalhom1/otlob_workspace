// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_product_option_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateProductOptionDto extends CreateProductOptionDto {
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final num? priceAdded;
  @override
  final bool? isActive;

  factory _$CreateProductOptionDto([
    void Function(CreateProductOptionDtoBuilder)? updates,
  ]) => (CreateProductOptionDtoBuilder()..update(updates))._build();

  _$CreateProductOptionDto._({
    required this.name,
    this.nameAr,
    this.priceAdded,
    this.isActive,
  }) : super._();
  @override
  CreateProductOptionDto rebuild(
    void Function(CreateProductOptionDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateProductOptionDtoBuilder toBuilder() =>
      CreateProductOptionDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateProductOptionDto &&
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
    return (newBuiltValueToStringHelper(r'CreateProductOptionDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('priceAdded', priceAdded)
          ..add('isActive', isActive))
        .toString();
  }
}

class CreateProductOptionDtoBuilder
    implements Builder<CreateProductOptionDto, CreateProductOptionDtoBuilder> {
  _$CreateProductOptionDto? _$v;

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

  CreateProductOptionDtoBuilder() {
    CreateProductOptionDto._defaults(this);
  }

  CreateProductOptionDtoBuilder get _$this {
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
  void replace(CreateProductOptionDto other) {
    _$v = other as _$CreateProductOptionDto;
  }

  @override
  void update(void Function(CreateProductOptionDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateProductOptionDto build() => _build();

  _$CreateProductOptionDto _build() {
    final _$result =
        _$v ??
        _$CreateProductOptionDto._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateProductOptionDto',
            'name',
          ),
          nameAr: nameAr,
          priceAdded: priceAdded,
          isActive: isActive,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
