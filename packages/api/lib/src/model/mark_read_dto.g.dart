// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_read_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MarkReadDto extends MarkReadDto {
  @override
  final String? lastReadMessageId;

  factory _$MarkReadDto([void Function(MarkReadDtoBuilder)? updates]) =>
      (MarkReadDtoBuilder()..update(updates))._build();

  _$MarkReadDto._({this.lastReadMessageId}) : super._();
  @override
  MarkReadDto rebuild(void Function(MarkReadDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MarkReadDtoBuilder toBuilder() => MarkReadDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MarkReadDto && lastReadMessageId == other.lastReadMessageId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, lastReadMessageId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'MarkReadDto',
    )..add('lastReadMessageId', lastReadMessageId)).toString();
  }
}

class MarkReadDtoBuilder implements Builder<MarkReadDto, MarkReadDtoBuilder> {
  _$MarkReadDto? _$v;

  String? _lastReadMessageId;
  String? get lastReadMessageId => _$this._lastReadMessageId;
  set lastReadMessageId(String? lastReadMessageId) =>
      _$this._lastReadMessageId = lastReadMessageId;

  MarkReadDtoBuilder() {
    MarkReadDto._defaults(this);
  }

  MarkReadDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lastReadMessageId = $v.lastReadMessageId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MarkReadDto other) {
    _$v = other as _$MarkReadDto;
  }

  @override
  void update(void Function(MarkReadDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MarkReadDto build() => _build();

  _$MarkReadDto _build() {
    final _$result =
        _$v ?? _$MarkReadDto._(lastReadMessageId: lastReadMessageId);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
