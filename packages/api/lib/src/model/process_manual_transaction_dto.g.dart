// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_manual_transaction_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProcessManualTransactionDto extends ProcessManualTransactionDto {
  @override
  final num amount;
  @override
  final String type;
  @override
  final String? description;
  @override
  final String? referenceId;

  factory _$ProcessManualTransactionDto([
    void Function(ProcessManualTransactionDtoBuilder)? updates,
  ]) => (ProcessManualTransactionDtoBuilder()..update(updates))._build();

  _$ProcessManualTransactionDto._({
    required this.amount,
    required this.type,
    this.description,
    this.referenceId,
  }) : super._();
  @override
  ProcessManualTransactionDto rebuild(
    void Function(ProcessManualTransactionDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProcessManualTransactionDtoBuilder toBuilder() =>
      ProcessManualTransactionDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProcessManualTransactionDto &&
        amount == other.amount &&
        type == other.type &&
        description == other.description &&
        referenceId == other.referenceId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, referenceId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProcessManualTransactionDto')
          ..add('amount', amount)
          ..add('type', type)
          ..add('description', description)
          ..add('referenceId', referenceId))
        .toString();
  }
}

class ProcessManualTransactionDtoBuilder
    implements
        Builder<
          ProcessManualTransactionDto,
          ProcessManualTransactionDtoBuilder
        > {
  _$ProcessManualTransactionDto? _$v;

  num? _amount;
  num? get amount => _$this._amount;
  set amount(num? amount) => _$this._amount = amount;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _referenceId;
  String? get referenceId => _$this._referenceId;
  set referenceId(String? referenceId) => _$this._referenceId = referenceId;

  ProcessManualTransactionDtoBuilder() {
    ProcessManualTransactionDto._defaults(this);
  }

  ProcessManualTransactionDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amount = $v.amount;
      _type = $v.type;
      _description = $v.description;
      _referenceId = $v.referenceId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProcessManualTransactionDto other) {
    _$v = other as _$ProcessManualTransactionDto;
  }

  @override
  void update(void Function(ProcessManualTransactionDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProcessManualTransactionDto build() => _build();

  _$ProcessManualTransactionDto _build() {
    final _$result =
        _$v ??
        _$ProcessManualTransactionDto._(
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'ProcessManualTransactionDto',
            'amount',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'ProcessManualTransactionDto',
            'type',
          ),
          description: description,
          referenceId: referenceId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
