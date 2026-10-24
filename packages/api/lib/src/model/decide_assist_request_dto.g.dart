// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decide_assist_request_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DecideAssistRequestDto extends DecideAssistRequestDto {
  @override
  final String status;

  factory _$DecideAssistRequestDto([
    void Function(DecideAssistRequestDtoBuilder)? updates,
  ]) => (DecideAssistRequestDtoBuilder()..update(updates))._build();

  _$DecideAssistRequestDto._({required this.status}) : super._();
  @override
  DecideAssistRequestDto rebuild(
    void Function(DecideAssistRequestDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DecideAssistRequestDtoBuilder toBuilder() =>
      DecideAssistRequestDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecideAssistRequestDto && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'DecideAssistRequestDto',
    )..add('status', status)).toString();
  }
}

class DecideAssistRequestDtoBuilder
    implements Builder<DecideAssistRequestDto, DecideAssistRequestDtoBuilder> {
  _$DecideAssistRequestDto? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  DecideAssistRequestDtoBuilder() {
    DecideAssistRequestDto._defaults(this);
  }

  DecideAssistRequestDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecideAssistRequestDto other) {
    _$v = other as _$DecideAssistRequestDto;
  }

  @override
  void update(void Function(DecideAssistRequestDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecideAssistRequestDto build() => _build();

  _$DecideAssistRequestDto _build() {
    final _$result =
        _$v ??
        _$DecideAssistRequestDto._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'DecideAssistRequestDto',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
