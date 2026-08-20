// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_support_conversation_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateSupportConversationDto extends CreateSupportConversationDto {
  @override
  final String? vendorId;

  factory _$CreateSupportConversationDto([
    void Function(CreateSupportConversationDtoBuilder)? updates,
  ]) => (CreateSupportConversationDtoBuilder()..update(updates))._build();

  _$CreateSupportConversationDto._({this.vendorId}) : super._();
  @override
  CreateSupportConversationDto rebuild(
    void Function(CreateSupportConversationDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateSupportConversationDtoBuilder toBuilder() =>
      CreateSupportConversationDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateSupportConversationDto && vendorId == other.vendorId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreateSupportConversationDto',
    )..add('vendorId', vendorId)).toString();
  }
}

class CreateSupportConversationDtoBuilder
    implements
        Builder<
          CreateSupportConversationDto,
          CreateSupportConversationDtoBuilder
        > {
  _$CreateSupportConversationDto? _$v;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  CreateSupportConversationDtoBuilder() {
    CreateSupportConversationDto._defaults(this);
  }

  CreateSupportConversationDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vendorId = $v.vendorId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateSupportConversationDto other) {
    _$v = other as _$CreateSupportConversationDto;
  }

  @override
  void update(void Function(CreateSupportConversationDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateSupportConversationDto build() => _build();

  _$CreateSupportConversationDto _build() {
    final _$result =
        _$v ?? _$CreateSupportConversationDto._(vendorId: vendorId);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
