// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_direct_conversation_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateDirectConversationDto extends CreateDirectConversationDto {
  @override
  final String userId;

  factory _$CreateDirectConversationDto([
    void Function(CreateDirectConversationDtoBuilder)? updates,
  ]) => (CreateDirectConversationDtoBuilder()..update(updates))._build();

  _$CreateDirectConversationDto._({required this.userId}) : super._();
  @override
  CreateDirectConversationDto rebuild(
    void Function(CreateDirectConversationDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateDirectConversationDtoBuilder toBuilder() =>
      CreateDirectConversationDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateDirectConversationDto && userId == other.userId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreateDirectConversationDto',
    )..add('userId', userId)).toString();
  }
}

class CreateDirectConversationDtoBuilder
    implements
        Builder<
          CreateDirectConversationDto,
          CreateDirectConversationDtoBuilder
        > {
  _$CreateDirectConversationDto? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  CreateDirectConversationDtoBuilder() {
    CreateDirectConversationDto._defaults(this);
  }

  CreateDirectConversationDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateDirectConversationDto other) {
    _$v = other as _$CreateDirectConversationDto;
  }

  @override
  void update(void Function(CreateDirectConversationDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateDirectConversationDto build() => _build();

  _$CreateDirectConversationDto _build() {
    final _$result =
        _$v ??
        _$CreateDirectConversationDto._(
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'CreateDirectConversationDto',
            'userId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
