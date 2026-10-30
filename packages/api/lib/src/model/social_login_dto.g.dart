// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_login_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SocialLoginDtoProviderEnum _$socialLoginDtoProviderEnum_GOOGLE =
    const SocialLoginDtoProviderEnum._('GOOGLE');
const SocialLoginDtoProviderEnum _$socialLoginDtoProviderEnum_APPLE =
    const SocialLoginDtoProviderEnum._('APPLE');

SocialLoginDtoProviderEnum _$socialLoginDtoProviderEnumValueOf(String name) {
  switch (name) {
    case 'GOOGLE':
      return _$socialLoginDtoProviderEnum_GOOGLE;
    case 'APPLE':
      return _$socialLoginDtoProviderEnum_APPLE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SocialLoginDtoProviderEnum> _$socialLoginDtoProviderEnumValues =
    BuiltSet<SocialLoginDtoProviderEnum>(const <SocialLoginDtoProviderEnum>[
      _$socialLoginDtoProviderEnum_GOOGLE,
      _$socialLoginDtoProviderEnum_APPLE,
    ]);

const SocialLoginDtoAppEnum _$socialLoginDtoAppEnum_customer =
    const SocialLoginDtoAppEnum._('customer');
const SocialLoginDtoAppEnum _$socialLoginDtoAppEnum_driver =
    const SocialLoginDtoAppEnum._('driver');
const SocialLoginDtoAppEnum _$socialLoginDtoAppEnum_vendor =
    const SocialLoginDtoAppEnum._('vendor');

SocialLoginDtoAppEnum _$socialLoginDtoAppEnumValueOf(String name) {
  switch (name) {
    case 'customer':
      return _$socialLoginDtoAppEnum_customer;
    case 'driver':
      return _$socialLoginDtoAppEnum_driver;
    case 'vendor':
      return _$socialLoginDtoAppEnum_vendor;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SocialLoginDtoAppEnum> _$socialLoginDtoAppEnumValues =
    BuiltSet<SocialLoginDtoAppEnum>(const <SocialLoginDtoAppEnum>[
      _$socialLoginDtoAppEnum_customer,
      _$socialLoginDtoAppEnum_driver,
      _$socialLoginDtoAppEnum_vendor,
    ]);

Serializer<SocialLoginDtoProviderEnum> _$socialLoginDtoProviderEnumSerializer =
    _$SocialLoginDtoProviderEnumSerializer();
Serializer<SocialLoginDtoAppEnum> _$socialLoginDtoAppEnumSerializer =
    _$SocialLoginDtoAppEnumSerializer();

class _$SocialLoginDtoProviderEnumSerializer
    implements PrimitiveSerializer<SocialLoginDtoProviderEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'GOOGLE': 'GOOGLE',
    'APPLE': 'APPLE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'GOOGLE': 'GOOGLE',
    'APPLE': 'APPLE',
  };

  @override
  final Iterable<Type> types = const <Type>[SocialLoginDtoProviderEnum];
  @override
  final String wireName = 'SocialLoginDtoProviderEnum';

  @override
  Object serialize(
    Serializers serializers,
    SocialLoginDtoProviderEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SocialLoginDtoProviderEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SocialLoginDtoProviderEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$SocialLoginDtoAppEnumSerializer
    implements PrimitiveSerializer<SocialLoginDtoAppEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'customer': 'customer',
    'driver': 'driver',
    'vendor': 'vendor',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'customer': 'customer',
    'driver': 'driver',
    'vendor': 'vendor',
  };

  @override
  final Iterable<Type> types = const <Type>[SocialLoginDtoAppEnum];
  @override
  final String wireName = 'SocialLoginDtoAppEnum';

  @override
  Object serialize(
    Serializers serializers,
    SocialLoginDtoAppEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SocialLoginDtoAppEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SocialLoginDtoAppEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$SocialLoginDto extends SocialLoginDto {
  @override
  final SocialLoginDtoProviderEnum provider;
  @override
  final String? providerAccountId;
  @override
  final String idToken;
  @override
  final String? email;
  @override
  final String? name;
  @override
  final SocialLoginDtoAppEnum app;

  factory _$SocialLoginDto([void Function(SocialLoginDtoBuilder)? updates]) =>
      (SocialLoginDtoBuilder()..update(updates))._build();

  _$SocialLoginDto._({
    required this.provider,
    this.providerAccountId,
    required this.idToken,
    this.email,
    this.name,
    required this.app,
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

  SocialLoginDtoProviderEnum? _provider;
  SocialLoginDtoProviderEnum? get provider => _$this._provider;
  set provider(SocialLoginDtoProviderEnum? provider) =>
      _$this._provider = provider;

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

  SocialLoginDtoAppEnum? _app;
  SocialLoginDtoAppEnum? get app => _$this._app;
  set app(SocialLoginDtoAppEnum? app) => _$this._app = app;

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
          app: BuiltValueNullFieldError.checkNotNull(
            app,
            r'SocialLoginDto',
            'app',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
