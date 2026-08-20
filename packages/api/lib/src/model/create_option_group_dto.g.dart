// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_option_group_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateOptionGroupDto extends CreateOptionGroupDto {
  @override
  final String name;
  @override
  final String? nameAr;
  @override
  final bool? isRequired;
  @override
  final num? minSelect;
  @override
  final num? maxSelect;
  @override
  final BuiltList<CreateProductOptionDto>? options;

  factory _$CreateOptionGroupDto([
    void Function(CreateOptionGroupDtoBuilder)? updates,
  ]) => (CreateOptionGroupDtoBuilder()..update(updates))._build();

  _$CreateOptionGroupDto._({
    required this.name,
    this.nameAr,
    this.isRequired,
    this.minSelect,
    this.maxSelect,
    this.options,
  }) : super._();
  @override
  CreateOptionGroupDto rebuild(
    void Function(CreateOptionGroupDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateOptionGroupDtoBuilder toBuilder() =>
      CreateOptionGroupDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateOptionGroupDto &&
        name == other.name &&
        nameAr == other.nameAr &&
        isRequired == other.isRequired &&
        minSelect == other.minSelect &&
        maxSelect == other.maxSelect &&
        options == other.options;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, nameAr.hashCode);
    _$hash = $jc(_$hash, isRequired.hashCode);
    _$hash = $jc(_$hash, minSelect.hashCode);
    _$hash = $jc(_$hash, maxSelect.hashCode);
    _$hash = $jc(_$hash, options.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateOptionGroupDto')
          ..add('name', name)
          ..add('nameAr', nameAr)
          ..add('isRequired', isRequired)
          ..add('minSelect', minSelect)
          ..add('maxSelect', maxSelect)
          ..add('options', options))
        .toString();
  }
}

class CreateOptionGroupDtoBuilder
    implements Builder<CreateOptionGroupDto, CreateOptionGroupDtoBuilder> {
  _$CreateOptionGroupDto? _$v;

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

  ListBuilder<CreateProductOptionDto>? _options;
  ListBuilder<CreateProductOptionDto> get options =>
      _$this._options ??= ListBuilder<CreateProductOptionDto>();
  set options(ListBuilder<CreateProductOptionDto>? options) =>
      _$this._options = options;

  CreateOptionGroupDtoBuilder() {
    CreateOptionGroupDto._defaults(this);
  }

  CreateOptionGroupDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _nameAr = $v.nameAr;
      _isRequired = $v.isRequired;
      _minSelect = $v.minSelect;
      _maxSelect = $v.maxSelect;
      _options = $v.options?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateOptionGroupDto other) {
    _$v = other as _$CreateOptionGroupDto;
  }

  @override
  void update(void Function(CreateOptionGroupDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateOptionGroupDto build() => _build();

  _$CreateOptionGroupDto _build() {
    _$CreateOptionGroupDto _$result;
    try {
      _$result =
          _$v ??
          _$CreateOptionGroupDto._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'CreateOptionGroupDto',
              'name',
            ),
            nameAr: nameAr,
            isRequired: isRequired,
            minSelect: minSelect,
            maxSelect: maxSelect,
            options: _options?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'options';
        _options?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateOptionGroupDto',
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
