// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_order_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CancelOrderDto extends CancelOrderDto {
  @override
  final String? reason;

  factory _$CancelOrderDto([void Function(CancelOrderDtoBuilder)? updates]) =>
      (CancelOrderDtoBuilder()..update(updates))._build();

  _$CancelOrderDto._({this.reason}) : super._();
  @override
  CancelOrderDto rebuild(void Function(CancelOrderDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CancelOrderDtoBuilder toBuilder() => CancelOrderDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CancelOrderDto && reason == other.reason;
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
      r'CancelOrderDto',
    )..add('reason', reason)).toString();
  }
}

class CancelOrderDtoBuilder
    implements Builder<CancelOrderDto, CancelOrderDtoBuilder> {
  _$CancelOrderDto? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  CancelOrderDtoBuilder() {
    CancelOrderDto._defaults(this);
  }

  CancelOrderDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CancelOrderDto other) {
    _$v = other as _$CancelOrderDto;
  }

  @override
  void update(void Function(CancelOrderDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CancelOrderDto build() => _build();

  _$CancelOrderDto _build() {
    final _$result = _$v ?? _$CancelOrderDto._(reason: reason);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
