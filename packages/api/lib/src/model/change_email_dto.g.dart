// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_email_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChangeEmailDto extends ChangeEmailDto {
  @override
  final String currentPassword;
  @override
  final String newEmail;

  factory _$ChangeEmailDto([void Function(ChangeEmailDtoBuilder)? updates]) =>
      (ChangeEmailDtoBuilder()..update(updates))._build();

  _$ChangeEmailDto._({required this.currentPassword, required this.newEmail})
    : super._();
  @override
  ChangeEmailDto rebuild(void Function(ChangeEmailDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChangeEmailDtoBuilder toBuilder() => ChangeEmailDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChangeEmailDto &&
        currentPassword == other.currentPassword &&
        newEmail == other.newEmail;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currentPassword.hashCode);
    _$hash = $jc(_$hash, newEmail.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChangeEmailDto')
          ..add('currentPassword', currentPassword)
          ..add('newEmail', newEmail))
        .toString();
  }
}

class ChangeEmailDtoBuilder
    implements Builder<ChangeEmailDto, ChangeEmailDtoBuilder> {
  _$ChangeEmailDto? _$v;

  String? _currentPassword;
  String? get currentPassword => _$this._currentPassword;
  set currentPassword(String? currentPassword) =>
      _$this._currentPassword = currentPassword;

  String? _newEmail;
  String? get newEmail => _$this._newEmail;
  set newEmail(String? newEmail) => _$this._newEmail = newEmail;

  ChangeEmailDtoBuilder() {
    ChangeEmailDto._defaults(this);
  }

  ChangeEmailDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currentPassword = $v.currentPassword;
      _newEmail = $v.newEmail;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChangeEmailDto other) {
    _$v = other as _$ChangeEmailDto;
  }

  @override
  void update(void Function(ChangeEmailDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChangeEmailDto build() => _build();

  _$ChangeEmailDto _build() {
    final _$result =
        _$v ??
        _$ChangeEmailDto._(
          currentPassword: BuiltValueNullFieldError.checkNotNull(
            currentPassword,
            r'ChangeEmailDto',
            'currentPassword',
          ),
          newEmail: BuiltValueNullFieldError.checkNotNull(
            newEmail,
            r'ChangeEmailDto',
            'newEmail',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
