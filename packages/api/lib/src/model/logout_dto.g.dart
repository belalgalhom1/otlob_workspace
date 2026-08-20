// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LogoutDto extends LogoutDto {
  @override
  final String? fcmToken;

  factory _$LogoutDto([void Function(LogoutDtoBuilder)? updates]) =>
      (LogoutDtoBuilder()..update(updates))._build();

  _$LogoutDto._({this.fcmToken}) : super._();
  @override
  LogoutDto rebuild(void Function(LogoutDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LogoutDtoBuilder toBuilder() => LogoutDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LogoutDto && fcmToken == other.fcmToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fcmToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'LogoutDto',
    )..add('fcmToken', fcmToken)).toString();
  }
}

class LogoutDtoBuilder implements Builder<LogoutDto, LogoutDtoBuilder> {
  _$LogoutDto? _$v;

  String? _fcmToken;
  String? get fcmToken => _$this._fcmToken;
  set fcmToken(String? fcmToken) => _$this._fcmToken = fcmToken;

  LogoutDtoBuilder() {
    LogoutDto._defaults(this);
  }

  LogoutDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fcmToken = $v.fcmToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LogoutDto other) {
    _$v = other as _$LogoutDto;
  }

  @override
  void update(void Function(LogoutDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LogoutDto build() => _build();

  _$LogoutDto _build() {
    final _$result = _$v ?? _$LogoutDto._(fcmToken: fcmToken);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
