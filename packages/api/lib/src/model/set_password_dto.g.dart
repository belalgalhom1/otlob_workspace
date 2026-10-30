// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_password_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SetPasswordDto extends SetPasswordDto {
  @override
  final String newPassword;

  factory _$SetPasswordDto([void Function(SetPasswordDtoBuilder)? updates]) =>
      (SetPasswordDtoBuilder()..update(updates))._build();

  _$SetPasswordDto._({required this.newPassword}) : super._();
  @override
  SetPasswordDto rebuild(void Function(SetPasswordDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SetPasswordDtoBuilder toBuilder() => SetPasswordDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetPasswordDto && newPassword == other.newPassword;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, newPassword.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'SetPasswordDto',
    )..add('newPassword', newPassword)).toString();
  }
}

class SetPasswordDtoBuilder
    implements Builder<SetPasswordDto, SetPasswordDtoBuilder> {
  _$SetPasswordDto? _$v;

  String? _newPassword;
  String? get newPassword => _$this._newPassword;
  set newPassword(String? newPassword) => _$this._newPassword = newPassword;

  SetPasswordDtoBuilder() {
    SetPasswordDto._defaults(this);
  }

  SetPasswordDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _newPassword = $v.newPassword;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetPasswordDto other) {
    _$v = other as _$SetPasswordDto;
  }

  @override
  void update(void Function(SetPasswordDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SetPasswordDto build() => _build();

  _$SetPasswordDto _build() {
    final _$result =
        _$v ??
        _$SetPasswordDto._(
          newPassword: BuiltValueNullFieldError.checkNotNull(
            newPassword,
            r'SetPasswordDto',
            'newPassword',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
