// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_option_group_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateOptionGroupDto extends UpdateOptionGroupDto {
  @override
  final String? name;
  @override
  final String? nameAr;
  @override
  final bool? isRequired;
  @override
  final num? minSelect;
  @override
  final num? maxSelect;

  factory _$UpdateOptionGroupDto([
    void Function(UpdateOptionGroupDtoBuilder)? updates,
  ]) => (UpdateOptionGroupDtoBuilder()..update(updates))._build();

  _$UpdateOptionGroupDto._({
    this.name,
    this.nameAr,
    this.isRequired,
    this.minSelect,
    this.maxSelect,
  }) : super._();
  @override
  UpdateOptionGroupDto rebuild(
    void Function(UpdateOptionGroupDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateOptionGroupDtoBuilder toBuilder() =>
      UpdateOptionGroupDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateOptionGroupDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        isRequired == other.isRequired &&
        minSelect == other.minSelect &&
        maxSelect == other.maxSelect;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, isRequired.hashCode);
    _$hash = $jc(_$hash, minSelect.hashCode);
    _$hash = $jc(_$hash, maxSelect.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateOptionGroupDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('isRequired', isRequired)
          ..add('minSelect', minSelect)
          ..add('maxSelect', maxSelect))
        .toString();
  }
}

class UpdateOptionGroupDtoBuilder
    implements Builder<UpdateOptionGroupDto, UpdateOptionGroupDtoBuilder> {
  _$UpdateOptionGroupDto? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _nameAr;
  String? get nameAr => _$this._nameAr;
  set nameAr(String? nameAr) => _$this._nameAr = nameAr;

  bool? _isRequired;
  bool? get isRequired => _$this._isRequired;
  set isRequired(bool? isRequired) => _$this._isRequired = isRequired;

  num? _minSelect;
  num? get minSelect => _$this._minSelect;
  set minSelect(num? minSelect) => _$this._minSelect = minSelect;

  num? _maxSelect;
  num? get maxSelect => _$this._maxSelect;
  set maxSelect(num? maxSelect) => _$this._maxSelect = maxSelect;

  UpdateOptionGroupDtoBuilder() {
    UpdateOptionGroupDto._defaults(this);
  }

  UpdateOptionGroupDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _isRequired = $v.isRequired;
      _minSelect = $v.minSelect;
      _maxSelect = $v.maxSelect;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateOptionGroupDto other) {
    _$v = other as _$UpdateOptionGroupDto;
  }

  @override
  void update(void Function(UpdateOptionGroupDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateOptionGroupDto build() => _build();

  _$UpdateOptionGroupDto _build() {
    final _$result =
        _$v ??
        _$UpdateOptionGroupDto._(
          name: name,
          nameAr: nameAr,
          isRequired: isRequired,
          minSelect: minSelect,
          maxSelect: maxSelect,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
