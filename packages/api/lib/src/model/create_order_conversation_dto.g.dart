// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_order_conversation_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateOrderConversationDto extends CreateOrderConversationDto {
  @override
  final String orderId;

  factory _$CreateOrderConversationDto([
    void Function(CreateOrderConversationDtoBuilder)? updates,
  ]) => (CreateOrderConversationDtoBuilder()..update(updates))._build();

  _$CreateOrderConversationDto._({required this.orderId}) : super._();
  @override
  CreateOrderConversationDto rebuild(
    void Function(CreateOrderConversationDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateOrderConversationDtoBuilder toBuilder() =>
      CreateOrderConversationDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateOrderConversationDto && orderId == other.orderId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreateOrderConversationDto',
    )..add('orderId', orderId)).toString();
  }
}

class CreateOrderConversationDtoBuilder
    implements
        Builder<CreateOrderConversationDto, CreateOrderConversationDtoBuilder> {
  _$CreateOrderConversationDto? _$v;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  CreateOrderConversationDtoBuilder() {
    CreateOrderConversationDto._defaults(this);
  }

  CreateOrderConversationDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _orderId = $v.orderId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateOrderConversationDto other) {
    _$v = other as _$CreateOrderConversationDto;
  }

  @override
  void update(void Function(CreateOrderConversationDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateOrderConversationDto build() => _build();

  _$CreateOrderConversationDto _build() {
    final _$result =
        _$v ??
        _$CreateOrderConversationDto._(
          orderId: BuiltValueNullFieldError.checkNotNull(
            orderId,
            r'CreateOrderConversationDto',
            'orderId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
