// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_login_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SocialLoginDto extends SocialLoginDto {
  @override
  final String provider;
  @override
  final String? providerAccountId;
  @override
  final String idToken;
  @override
  final String? email;
  @override
  final String? name;
  @override
  final String? app;

  factory _$SocialLoginDto([void Function(SocialLoginDtoBuilder)? updates]) =>
      (SocialLoginDtoBuilder()..update(updates))._build();

  _$SocialLoginDto._({
    required this.provider,
    this.providerAccountId,
    required this.idToken,
    this.email,
    this.name,
    this.app,
  }) : super._();
  @override
  SocialLoginDto rebuild(void Function(SocialLoginDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SocialLoginDtoBuilder toBuilder() => SocialLoginDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SocialLoginDto &&
        provider == other.provider &&
        providerAccountId == other.providerAccountId &&
        idToken == other.idToken &&
        email == other.email &&
        name == other.name &&
        app == other.app;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, providerAccountId.hashCode);
    _$hash = $jc(_$hash, idToken.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, app.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SocialLoginDto')
          ..add('provider', provider)
          ..add('providerAccountId', providerAccountId)
          ..add('idToken', idToken)
          ..add('email', email)
          ..add('name', name)
          ..add('app', app))
        .toString();
  }
}

class SocialLoginDtoBuilder
    implements Builder<SocialLoginDto, SocialLoginDtoBuilder> {
  _$SocialLoginDto? _$v;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _providerAccountId;
  String? get providerAccountId => _$this._providerAccountId;
  set providerAccountId(String? providerAccountId) =>
      _$this._providerAccountId = providerAccountId;

  String? _idToken;
  String? get idToken => _$this._idToken;
  set idToken(String? idToken) => _$this._idToken = idToken;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _app;
  String? get app => _$this._app;
  set app(String? app) => _$this._app = app;

  SocialLoginDtoBuilder() {
    SocialLoginDto._defaults(this);
  }

  SocialLoginDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _provider = $v.provider;
      _providerAccountId = $v.providerAccountId;
      _idToken = $v.idToken;
      _email = $v.email;
      _name = $v.name;
      _app = $v.app;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SocialLoginDto other) {
    _$v = other as _$SocialLoginDto;
  }

  @override
  void update(void Function(SocialLoginDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SocialLoginDto build() => _build();

  _$SocialLoginDto _build() {
    final _$result =
        _$v ??
        _$SocialLoginDto._(
          provider: BuiltValueNullFieldError.checkNotNull(
            provider,
            r'SocialLoginDto',
            'provider',
          ),
          providerAccountId: providerAccountId,
          idToken: BuiltValueNullFieldError.checkNotNull(
            idToken,
            r'SocialLoginDto',
            'idToken',
          ),
          email: email,
          name: name,
          app: app,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
