// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_payment_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConfirmPaymentDto extends ConfirmPaymentDto {
  @override
  final bool received;

  factory _$ConfirmPaymentDto([
    void Function(ConfirmPaymentDtoBuilder)? updates,
  ]) => (ConfirmPaymentDtoBuilder()..update(updates))._build();

  _$ConfirmPaymentDto._({required this.received}) : super._();
  @override
  ConfirmPaymentDto rebuild(void Function(ConfirmPaymentDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConfirmPaymentDtoBuilder toBuilder() =>
      ConfirmPaymentDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConfirmPaymentDto && received == other.received;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, received.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ConfirmPaymentDto',
    )..add('received', received)).toString();
  }
}

class ConfirmPaymentDtoBuilder
    implements Builder<ConfirmPaymentDto, ConfirmPaymentDtoBuilder> {
  _$ConfirmPaymentDto? _$v;

  bool? _received;
  bool? get received => _$this._received;
  set received(bool? received) => _$this._received = received;

  ConfirmPaymentDtoBuilder() {
    ConfirmPaymentDto._defaults(this);
  }

  ConfirmPaymentDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _received = $v.received;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConfirmPaymentDto other) {
    _$v = other as _$ConfirmPaymentDto;
  }

  @override
  void update(void Function(ConfirmPaymentDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConfirmPaymentDto build() => _build();

  _$ConfirmPaymentDto _build() {
    final _$result =
        _$v ??
        _$ConfirmPaymentDto._(
          received: BuiltValueNullFieldError.checkNotNull(
            received,
            r'ConfirmPaymentDto',
            'received',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
