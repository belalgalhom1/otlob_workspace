// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_vendor_conversation_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateVendorConversationDto extends CreateVendorConversationDto {
  @override
  final String vendorId;

  factory _$CreateVendorConversationDto([
    void Function(CreateVendorConversationDtoBuilder)? updates,
  ]) => (CreateVendorConversationDtoBuilder()..update(updates))._build();

  _$CreateVendorConversationDto._({required this.vendorId}) : super._();
  @override
  CreateVendorConversationDto rebuild(
    void Function(CreateVendorConversationDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateVendorConversationDtoBuilder toBuilder() =>
      CreateVendorConversationDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateVendorConversationDto && vendorId == other.vendorId;
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
      r'CreateVendorConversationDto',
    )..add('vendorId', vendorId)).toString();
  }
}

class CreateVendorConversationDtoBuilder
    implements
        Builder<
          CreateVendorConversationDto,
          CreateVendorConversationDtoBuilder
        > {
  _$CreateVendorConversationDto? _$v;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  CreateVendorConversationDtoBuilder() {
    CreateVendorConversationDto._defaults(this);
  }

  CreateVendorConversationDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vendorId = $v.vendorId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateVendorConversationDto other) {
    _$v = other as _$CreateVendorConversationDto;
  }

  @override
  void update(void Function(CreateVendorConversationDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateVendorConversationDto build() => _build();

  _$CreateVendorConversationDto _build() {
    final _$result =
        _$v ??
        _$CreateVendorConversationDto._(
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'CreateVendorConversationDto',
            'vendorId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
