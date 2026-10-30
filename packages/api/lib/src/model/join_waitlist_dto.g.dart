// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_waitlist_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JoinWaitlistDto extends JoinWaitlistDto {
  @override
  final String shiftPoolId;

  factory _$JoinWaitlistDto([void Function(JoinWaitlistDtoBuilder)? updates]) =>
      (JoinWaitlistDtoBuilder()..update(updates))._build();

  _$JoinWaitlistDto._({required this.shiftPoolId}) : super._();
  @override
  JoinWaitlistDto rebuild(void Function(JoinWaitlistDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JoinWaitlistDtoBuilder toBuilder() => JoinWaitlistDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JoinWaitlistDto && shiftPoolId == other.shiftPoolId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, shiftPoolId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'JoinWaitlistDto',
    )..add('shiftPoolId', shiftPoolId)).toString();
  }
}

class JoinWaitlistDtoBuilder
    implements Builder<JoinWaitlistDto, JoinWaitlistDtoBuilder> {
  _$JoinWaitlistDto? _$v;

  String? _shiftPoolId;
  String? get shiftPoolId => _$this._shiftPoolId;
  set shiftPoolId(String? shiftPoolId) => _$this._shiftPoolId = shiftPoolId;

  JoinWaitlistDtoBuilder() {
    JoinWaitlistDto._defaults(this);
  }

  JoinWaitlistDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shiftPoolId = $v.shiftPoolId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JoinWaitlistDto other) {
    _$v = other as _$JoinWaitlistDto;
  }

  @override
  void update(void Function(JoinWaitlistDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JoinWaitlistDto build() => _build();

  _$JoinWaitlistDto _build() {
    final _$result =
        _$v ??
        _$JoinWaitlistDto._(
          shiftPoolId: BuiltValueNullFieldError.checkNotNull(
            shiftPoolId,
            r'JoinWaitlistDto',
            'shiftPoolId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
