// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decide_assist_request_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DecideAssistRequestDtoStatusEnum
_$decideAssistRequestDtoStatusEnum_APPROVED =
    const DecideAssistRequestDtoStatusEnum._('APPROVED');
const DecideAssistRequestDtoStatusEnum
_$decideAssistRequestDtoStatusEnum_REJECTED =
    const DecideAssistRequestDtoStatusEnum._('REJECTED');

DecideAssistRequestDtoStatusEnum _$decideAssistRequestDtoStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'APPROVED':
      return _$decideAssistRequestDtoStatusEnum_APPROVED;
    case 'REJECTED':
      return _$decideAssistRequestDtoStatusEnum_REJECTED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DecideAssistRequestDtoStatusEnum>
_$decideAssistRequestDtoStatusEnumValues =
    BuiltSet<DecideAssistRequestDtoStatusEnum>(
      const <DecideAssistRequestDtoStatusEnum>[
        _$decideAssistRequestDtoStatusEnum_APPROVED,
        _$decideAssistRequestDtoStatusEnum_REJECTED,
      ],
    );

Serializer<DecideAssistRequestDtoStatusEnum>
_$decideAssistRequestDtoStatusEnumSerializer =
    _$DecideAssistRequestDtoStatusEnumSerializer();

class _$DecideAssistRequestDtoStatusEnumSerializer
    implements PrimitiveSerializer<DecideAssistRequestDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
  };

  @override
  final Iterable<Type> types = const <Type>[DecideAssistRequestDtoStatusEnum];
  @override
  final String wireName = 'DecideAssistRequestDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    DecideAssistRequestDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DecideAssistRequestDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DecideAssistRequestDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$DecideAssistRequestDto extends DecideAssistRequestDto {
  @override
  final DecideAssistRequestDtoStatusEnum status;

  factory _$DecideAssistRequestDto([
    void Function(DecideAssistRequestDtoBuilder)? updates,
  ]) => (DecideAssistRequestDtoBuilder()..update(updates))._build();

  _$DecideAssistRequestDto._({required this.status}) : super._();
  @override
  DecideAssistRequestDto rebuild(
    void Function(DecideAssistRequestDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DecideAssistRequestDtoBuilder toBuilder() =>
      DecideAssistRequestDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecideAssistRequestDto && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'DecideAssistRequestDto',
    )..add('status', status)).toString();
  }
}

class DecideAssistRequestDtoBuilder
    implements Builder<DecideAssistRequestDto, DecideAssistRequestDtoBuilder> {
  _$DecideAssistRequestDto? _$v;

  DecideAssistRequestDtoStatusEnum? _status;
  DecideAssistRequestDtoStatusEnum? get status => _$this._status;
  set status(DecideAssistRequestDtoStatusEnum? status) =>
      _$this._status = status;

  DecideAssistRequestDtoBuilder() {
    DecideAssistRequestDto._defaults(this);
  }

  DecideAssistRequestDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecideAssistRequestDto other) {
    _$v = other as _$DecideAssistRequestDto;
  }

  @override
  void update(void Function(DecideAssistRequestDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecideAssistRequestDto build() => _build();

  _$DecideAssistRequestDto _build() {
    final _$result =
        _$v ??
        _$DecideAssistRequestDto._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'DecideAssistRequestDto',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
