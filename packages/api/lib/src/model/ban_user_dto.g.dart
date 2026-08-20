// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ban_user_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BanUserDto extends BanUserDto {
  @override
  final String? reason;

  factory _$BanUserDto([void Function(BanUserDtoBuilder)? updates]) =>
      (BanUserDtoBuilder()..update(updates))._build();

  _$BanUserDto._({this.reason}) : super._();
  @override
  BanUserDto rebuild(void Function(BanUserDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BanUserDtoBuilder toBuilder() => BanUserDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BanUserDto && reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'BanUserDto',
    )..add('reason', reason)).toString();
  }
}

class BanUserDtoBuilder implements Builder<BanUserDto, BanUserDtoBuilder> {
  _$BanUserDto? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  BanUserDtoBuilder() {
    BanUserDto._defaults(this);
  }

  BanUserDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BanUserDto other) {
    _$v = other as _$BanUserDto;
  }

  @override
  void update(void Function(BanUserDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BanUserDto build() => _build();

  _$BanUserDto _build() {
    final _$result = _$v ?? _$BanUserDto._(reason: reason);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
