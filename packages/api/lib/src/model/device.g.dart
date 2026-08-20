// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Device extends Device {
  @override
  final String id;
  @override
  final String token;
  @override
  final JsonObject? platform;
  @override
  final String userId;
  @override
  final DateTime lastActive;
  @override
  final JsonObject? user;

  factory _$Device([void Function(DeviceBuilder)? updates]) =>
      (DeviceBuilder()..update(updates))._build();

  _$Device._({
    required this.id,
    required this.token,
    this.platform,
    required this.userId,
    required this.lastActive,
    this.user,
  }) : super._();
  @override
  Device rebuild(void Function(DeviceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceBuilder toBuilder() => DeviceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Device &&
        id == other.id &&
        token == other.token &&
        platform == other.platform &&
        userId == other.userId &&
        lastActive == other.lastActive &&
        user == other.user;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, lastActive.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Device')
          ..add('id', id)
          ..add('token', token)
          ..add('platform', platform)
          ..add('userId', userId)
          ..add('lastActive', lastActive)
          ..add('user', user))
        .toString();
  }
}

class DeviceBuilder implements Builder<Device, DeviceBuilder> {
  _$Device? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  JsonObject? _platform;
  JsonObject? get platform => _$this._platform;
  set platform(JsonObject? platform) => _$this._platform = platform;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  DateTime? _lastActive;
  DateTime? get lastActive => _$this._lastActive;
  set lastActive(DateTime? lastActive) => _$this._lastActive = lastActive;

  JsonObject? _user;
  JsonObject? get user => _$this._user;
  set user(JsonObject? user) => _$this._user = user;

  DeviceBuilder() {
    Device._defaults(this);
  }

  DeviceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _token = $v.token;
      _platform = $v.platform;
      _userId = $v.userId;
      _lastActive = $v.lastActive;
      _user = $v.user;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Device other) {
    _$v = other as _$Device;
  }

  @override
  void update(void Function(DeviceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Device build() => _build();

  _$Device _build() {
    final _$result =
        _$v ??
        _$Device._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Device', 'id'),
          token: BuiltValueNullFieldError.checkNotNull(
            token,
            r'Device',
            'token',
          ),
          platform: platform,
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'Device',
            'userId',
          ),
          lastActive: BuiltValueNullFieldError.checkNotNull(
            lastActive,
            r'Device',
            'lastActive',
          ),
          user: user,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
