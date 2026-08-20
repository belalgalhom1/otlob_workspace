// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterDeviceDtoPlatformEnum _$registerDeviceDtoPlatformEnum_ANDROID =
    const RegisterDeviceDtoPlatformEnum._('ANDROID');
const RegisterDeviceDtoPlatformEnum _$registerDeviceDtoPlatformEnum_IOS =
    const RegisterDeviceDtoPlatformEnum._('IOS');
const RegisterDeviceDtoPlatformEnum _$registerDeviceDtoPlatformEnum_WEB =
    const RegisterDeviceDtoPlatformEnum._('WEB');

RegisterDeviceDtoPlatformEnum _$registerDeviceDtoPlatformEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ANDROID':
      return _$registerDeviceDtoPlatformEnum_ANDROID;
    case 'IOS':
      return _$registerDeviceDtoPlatformEnum_IOS;
    case 'WEB':
      return _$registerDeviceDtoPlatformEnum_WEB;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterDeviceDtoPlatformEnum>
_$registerDeviceDtoPlatformEnumValues = BuiltSet<RegisterDeviceDtoPlatformEnum>(
  const <RegisterDeviceDtoPlatformEnum>[
    _$registerDeviceDtoPlatformEnum_ANDROID,
    _$registerDeviceDtoPlatformEnum_IOS,
    _$registerDeviceDtoPlatformEnum_WEB,
  ],
);

Serializer<RegisterDeviceDtoPlatformEnum>
_$registerDeviceDtoPlatformEnumSerializer =
    _$RegisterDeviceDtoPlatformEnumSerializer();

class _$RegisterDeviceDtoPlatformEnumSerializer
    implements PrimitiveSerializer<RegisterDeviceDtoPlatformEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ANDROID': 'ANDROID',
    'IOS': 'IOS',
    'WEB': 'WEB',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ANDROID': 'ANDROID',
    'IOS': 'IOS',
    'WEB': 'WEB',
  };

  @override
  final Iterable<Type> types = const <Type>[RegisterDeviceDtoPlatformEnum];
  @override
  final String wireName = 'RegisterDeviceDtoPlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterDeviceDtoPlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterDeviceDtoPlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterDeviceDtoPlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterDeviceDto extends RegisterDeviceDto {
  @override
  final String token;
  @override
  final RegisterDeviceDtoPlatformEnum platform;

  factory _$RegisterDeviceDto([
    void Function(RegisterDeviceDtoBuilder)? updates,
  ]) => (RegisterDeviceDtoBuilder()..update(updates))._build();

  _$RegisterDeviceDto._({required this.token, required this.platform})
    : super._();
  @override
  RegisterDeviceDto rebuild(void Function(RegisterDeviceDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterDeviceDtoBuilder toBuilder() =>
      RegisterDeviceDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterDeviceDto &&
        token == other.token &&
        platform == other.platform;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterDeviceDto')
          ..add('token', token)
          ..add('platform', platform))
        .toString();
  }
}

class RegisterDeviceDtoBuilder
    implements Builder<RegisterDeviceDto, RegisterDeviceDtoBuilder> {
  _$RegisterDeviceDto? _$v;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  RegisterDeviceDtoPlatformEnum? _platform;
  RegisterDeviceDtoPlatformEnum? get platform => _$this._platform;
  set platform(RegisterDeviceDtoPlatformEnum? platform) =>
      _$this._platform = platform;

  RegisterDeviceDtoBuilder() {
    RegisterDeviceDto._defaults(this);
  }

  RegisterDeviceDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _token = $v.token;
      _platform = $v.platform;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterDeviceDto other) {
    _$v = other as _$RegisterDeviceDto;
  }

  @override
  void update(void Function(RegisterDeviceDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterDeviceDto build() => _build();

  _$RegisterDeviceDto _build() {
    final _$result =
        _$v ??
        _$RegisterDeviceDto._(
          token: BuiltValueNullFieldError.checkNotNull(
            token,
            r'RegisterDeviceDto',
            'token',
          ),
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'RegisterDeviceDto',
            'platform',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
