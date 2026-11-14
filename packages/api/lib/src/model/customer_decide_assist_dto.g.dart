// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_decide_assist_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CustomerDecideAssistDto extends CustomerDecideAssistDto {
  @override
  final bool approved;

  factory _$CustomerDecideAssistDto([
    void Function(CustomerDecideAssistDtoBuilder)? updates,
  ]) => (CustomerDecideAssistDtoBuilder()..update(updates))._build();

  _$CustomerDecideAssistDto._({required this.approved}) : super._();
  @override
  CustomerDecideAssistDto rebuild(
    void Function(CustomerDecideAssistDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CustomerDecideAssistDtoBuilder toBuilder() =>
      CustomerDecideAssistDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CustomerDecideAssistDto && approved == other.approved;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, approved.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CustomerDecideAssistDto',
    )..add('approved', approved)).toString();
  }
}

class CustomerDecideAssistDtoBuilder
    implements
        Builder<CustomerDecideAssistDto, CustomerDecideAssistDtoBuilder> {
  _$CustomerDecideAssistDto? _$v;

  bool? _approved;
  bool? get approved => _$this._approved;
  set approved(bool? approved) => _$this._approved = approved;

  CustomerDecideAssistDtoBuilder() {
    CustomerDecideAssistDto._defaults(this);
  }

  CustomerDecideAssistDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _approved = $v.approved;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CustomerDecideAssistDto other) {
    _$v = other as _$CustomerDecideAssistDto;
  }

  @override
  void update(void Function(CustomerDecideAssistDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CustomerDecideAssistDto build() => _build();

  _$CustomerDecideAssistDto _build() {
    final _$result =
        _$v ??
        _$CustomerDecideAssistDto._(
          approved: BuiltValueNullFieldError.checkNotNull(
            approved,
            r'CustomerDecideAssistDto',
            'approved',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
