// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_message_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateMessageDto extends UpdateMessageDto {
  @override
  final String text;

  factory _$UpdateMessageDto([
    void Function(UpdateMessageDtoBuilder)? updates,
  ]) => (UpdateMessageDtoBuilder()..update(updates))._build();

  _$UpdateMessageDto._({required this.text}) : super._();
  @override
  UpdateMessageDto rebuild(void Function(UpdateMessageDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateMessageDtoBuilder toBuilder() =>
      UpdateMessageDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateMessageDto && text == other.text;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'UpdateMessageDto',
    )..add('text', text)).toString();
  }
}

class UpdateMessageDtoBuilder
    implements Builder<UpdateMessageDto, UpdateMessageDtoBuilder> {
  _$UpdateMessageDto? _$v;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  UpdateMessageDtoBuilder() {
    UpdateMessageDto._defaults(this);
  }

  UpdateMessageDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _text = $v.text;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateMessageDto other) {
    _$v = other as _$UpdateMessageDto;
  }

  @override
  void update(void Function(UpdateMessageDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateMessageDto build() => _build();

  _$UpdateMessageDto _build() {
    final _$result =
        _$v ??
        _$UpdateMessageDto._(
          text: BuiltValueNullFieldError.checkNotNull(
            text,
            r'UpdateMessageDto',
            'text',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
