// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_assist_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RequestAssistDriverDto extends RequestAssistDriverDto {
  @override
  final String reason;
  @override
  final String? note;

  factory _$RequestAssistDriverDto([
    void Function(RequestAssistDriverDtoBuilder)? updates,
  ]) => (RequestAssistDriverDtoBuilder()..update(updates))._build();

  _$RequestAssistDriverDto._({required this.reason, this.note}) : super._();
  @override
  RequestAssistDriverDto rebuild(
    void Function(RequestAssistDriverDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RequestAssistDriverDtoBuilder toBuilder() =>
      RequestAssistDriverDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RequestAssistDriverDto &&
        reason == other.reason &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RequestAssistDriverDto')
          ..add('reason', reason)
          ..add('note', note))
        .toString();
  }
}

class RequestAssistDriverDtoBuilder
    implements Builder<RequestAssistDriverDto, RequestAssistDriverDtoBuilder> {
  _$RequestAssistDriverDto? _$v;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  RequestAssistDriverDtoBuilder() {
    RequestAssistDriverDto._defaults(this);
  }

  RequestAssistDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RequestAssistDriverDto other) {
    _$v = other as _$RequestAssistDriverDto;
  }

  @override
  void update(void Function(RequestAssistDriverDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RequestAssistDriverDto build() => _build();

  _$RequestAssistDriverDto _build() {
    final _$result =
        _$v ??
        _$RequestAssistDriverDto._(
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'RequestAssistDriverDto',
            'reason',
          ),
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
