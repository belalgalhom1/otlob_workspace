// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LoginDto extends LoginDto {
  @override
  final String email;
  @override
  final String password;
  @override
  final String? app;

  factory _$LoginDto([void Function(LoginDtoBuilder)? updates]) =>
      (LoginDtoBuilder()..update(updates))._build();

  _$LoginDto._({required this.email, required this.password, this.app})
    : super._();
  @override
  LoginDto rebuild(void Function(LoginDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LoginDtoBuilder toBuilder() => LoginDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LoginDto &&
        email == other.email &&
        password == other.password &&
        app == other.app;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jc(_$hash, app.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LoginDto')
          ..add('email', email)
          ..add('password', password)
          ..add('app', app))
        .toString();
  }
}

class LoginDtoBuilder implements Builder<LoginDto, LoginDtoBuilder> {
  _$LoginDto? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  String? _app;
  String? get app => _$this._app;
  set app(String? app) => _$this._app = app;

  LoginDtoBuilder() {
    LoginDto._defaults(this);
  }

  LoginDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _password = $v.password;
      _app = $v.app;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LoginDto other) {
    _$v = other as _$LoginDto;
  }

  @override
  void update(void Function(LoginDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LoginDto build() => _build();

  _$LoginDto _build() {
    final _$result =
        _$v ??
        _$LoginDto._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'LoginDto',
            'email',
          ),
          password: BuiltValueNullFieldError.checkNotNull(
            password,
            r'LoginDto',
            'password',
          ),
          app: app,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
