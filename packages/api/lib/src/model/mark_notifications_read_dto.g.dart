// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_notifications_read_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MarkNotificationsReadDto extends MarkNotificationsReadDto {
  @override
  final BuiltList<String>? ids;

  factory _$MarkNotificationsReadDto([
    void Function(MarkNotificationsReadDtoBuilder)? updates,
  ]) => (MarkNotificationsReadDtoBuilder()..update(updates))._build();

  _$MarkNotificationsReadDto._({this.ids}) : super._();
  @override
  MarkNotificationsReadDto rebuild(
    void Function(MarkNotificationsReadDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  MarkNotificationsReadDtoBuilder toBuilder() =>
      MarkNotificationsReadDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MarkNotificationsReadDto && ids == other.ids;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ids.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'MarkNotificationsReadDto',
    )..add('ids', ids)).toString();
  }
}

class MarkNotificationsReadDtoBuilder
    implements
        Builder<MarkNotificationsReadDto, MarkNotificationsReadDtoBuilder> {
  _$MarkNotificationsReadDto? _$v;

  ListBuilder<String>? _ids;
  ListBuilder<String> get ids => _$this._ids ??= ListBuilder<String>();
  set ids(ListBuilder<String>? ids) => _$this._ids = ids;

  MarkNotificationsReadDtoBuilder() {
    MarkNotificationsReadDto._defaults(this);
  }

  MarkNotificationsReadDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ids = $v.ids?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MarkNotificationsReadDto other) {
    _$v = other as _$MarkNotificationsReadDto;
  }

  @override
  void update(void Function(MarkNotificationsReadDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MarkNotificationsReadDto build() => _build();

  _$MarkNotificationsReadDto _build() {
    _$MarkNotificationsReadDto _$result;
    try {
      _$result = _$v ?? _$MarkNotificationsReadDto._(ids: _ids?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ids';
        _ids?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'MarkNotificationsReadDto',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
