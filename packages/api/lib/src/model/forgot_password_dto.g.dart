// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ForgotPasswordDto extends ForgotPasswordDto {
  @override
  final String contact;

  factory _$ForgotPasswordDto([
    void Function(ForgotPasswordDtoBuilder)? updates,
  ]) => (ForgotPasswordDtoBuilder()..update(updates))._build();

  _$ForgotPasswordDto._({required this.contact}) : super._();
  @override
  ForgotPasswordDto rebuild(void Function(ForgotPasswordDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ForgotPasswordDtoBuilder toBuilder() =>
      ForgotPasswordDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ForgotPasswordDto && contact == other.contact;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contact.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ForgotPasswordDto',
    )..add('contact', contact)).toString();
  }
}

class ForgotPasswordDtoBuilder
    implements Builder<ForgotPasswordDto, ForgotPasswordDtoBuilder> {
  _$ForgotPasswordDto? _$v;

  String? _contact;
  String? get contact => _$this._contact;
  set contact(String? contact) => _$this._contact = contact;

  ForgotPasswordDtoBuilder() {
    ForgotPasswordDto._defaults(this);
  }

  ForgotPasswordDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contact = $v.contact;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ForgotPasswordDto other) {
    _$v = other as _$ForgotPasswordDto;
  }

  @override
  void update(void Function(ForgotPasswordDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ForgotPasswordDto build() => _build();

  _$ForgotPasswordDto _build() {
    final _$result =
        _$v ??
        _$ForgotPasswordDto._(
          contact: BuiltValueNullFieldError.checkNotNull(
            contact,
            r'ForgotPasswordDto',
            'contact',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
