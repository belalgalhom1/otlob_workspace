// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_check_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AppVersionCheckDtoPlatformEnum _$appVersionCheckDtoPlatformEnum_android =
    const AppVersionCheckDtoPlatformEnum._('android');
const AppVersionCheckDtoPlatformEnum _$appVersionCheckDtoPlatformEnum_ios =
    const AppVersionCheckDtoPlatformEnum._('ios');

AppVersionCheckDtoPlatformEnum _$appVersionCheckDtoPlatformEnumValueOf(
  String name,
) {
  switch (name) {
    case 'android':
      return _$appVersionCheckDtoPlatformEnum_android;
    case 'ios':
      return _$appVersionCheckDtoPlatformEnum_ios;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AppVersionCheckDtoPlatformEnum>
_$appVersionCheckDtoPlatformEnumValues =
    BuiltSet<AppVersionCheckDtoPlatformEnum>(
      const <AppVersionCheckDtoPlatformEnum>[
        _$appVersionCheckDtoPlatformEnum_android,
        _$appVersionCheckDtoPlatformEnum_ios,
      ],
    );

Serializer<AppVersionCheckDtoPlatformEnum>
_$appVersionCheckDtoPlatformEnumSerializer =
    _$AppVersionCheckDtoPlatformEnumSerializer();

class _$AppVersionCheckDtoPlatformEnumSerializer
    implements PrimitiveSerializer<AppVersionCheckDtoPlatformEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'android': 'android',
    'ios': 'ios',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'android': 'android',
    'ios': 'ios',
  };

  @override
  final Iterable<Type> types = const <Type>[AppVersionCheckDtoPlatformEnum];
  @override
  final String wireName = 'AppVersionCheckDtoPlatformEnum';

  @override
  Object serialize(
    Serializers serializers,
    AppVersionCheckDtoPlatformEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AppVersionCheckDtoPlatformEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AppVersionCheckDtoPlatformEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AppVersionCheckDto extends AppVersionCheckDto {
  @override
  final AppVersionCheckDtoPlatformEnum platform;
  @override
  final String version;

  factory _$AppVersionCheckDto([
    void Function(AppVersionCheckDtoBuilder)? updates,
  ]) => (AppVersionCheckDtoBuilder()..update(updates))._build();

  _$AppVersionCheckDto._({required this.platform, required this.version})
    : super._();
  @override
  AppVersionCheckDto rebuild(
    void Function(AppVersionCheckDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AppVersionCheckDtoBuilder toBuilder() =>
      AppVersionCheckDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppVersionCheckDto &&
        platform == other.platform &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AppVersionCheckDto')
          ..add('platform', platform)
          ..add('version', version))
        .toString();
  }
}

class AppVersionCheckDtoBuilder
    implements Builder<AppVersionCheckDto, AppVersionCheckDtoBuilder> {
  _$AppVersionCheckDto? _$v;

  AppVersionCheckDtoPlatformEnum? _platform;
  AppVersionCheckDtoPlatformEnum? get platform => _$this._platform;
  set platform(AppVersionCheckDtoPlatformEnum? platform) =>
      _$this._platform = platform;

  String? _version;
  String? get version => _$this._version;
  set version(String? version) => _$this._version = version;

  AppVersionCheckDtoBuilder() {
    AppVersionCheckDto._defaults(this);
  }

  AppVersionCheckDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppVersionCheckDto other) {
    _$v = other as _$AppVersionCheckDto;
  }

  @override
  void update(void Function(AppVersionCheckDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AppVersionCheckDto build() => _build();

  _$AppVersionCheckDto _build() {
    final _$result =
        _$v ??
        _$AppVersionCheckDto._(
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'AppVersionCheckDto',
            'platform',
          ),
          version: BuiltValueNullFieldError.checkNotNull(
            version,
            r'AppVersionCheckDto',
            'version',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
