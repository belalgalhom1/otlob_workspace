// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'respond_to_dispatch_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RespondToDispatchDtoResponseEnum
_$respondToDispatchDtoResponseEnum_ACCEPTED =
    const RespondToDispatchDtoResponseEnum._('ACCEPTED');
const RespondToDispatchDtoResponseEnum
_$respondToDispatchDtoResponseEnum_REJECTED =
    const RespondToDispatchDtoResponseEnum._('REJECTED');

RespondToDispatchDtoResponseEnum _$respondToDispatchDtoResponseEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ACCEPTED':
      return _$respondToDispatchDtoResponseEnum_ACCEPTED;
    case 'REJECTED':
      return _$respondToDispatchDtoResponseEnum_REJECTED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RespondToDispatchDtoResponseEnum>
_$respondToDispatchDtoResponseEnumValues =
    BuiltSet<RespondToDispatchDtoResponseEnum>(
      const <RespondToDispatchDtoResponseEnum>[
        _$respondToDispatchDtoResponseEnum_ACCEPTED,
        _$respondToDispatchDtoResponseEnum_REJECTED,
      ],
    );

Serializer<RespondToDispatchDtoResponseEnum>
_$respondToDispatchDtoResponseEnumSerializer =
    _$RespondToDispatchDtoResponseEnumSerializer();

class _$RespondToDispatchDtoResponseEnumSerializer
    implements PrimitiveSerializer<RespondToDispatchDtoResponseEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ACCEPTED': 'ACCEPTED',
    'REJECTED': 'REJECTED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ACCEPTED': 'ACCEPTED',
    'REJECTED': 'REJECTED',
  };

  @override
  final Iterable<Type> types = const <Type>[RespondToDispatchDtoResponseEnum];
  @override
  final String wireName = 'RespondToDispatchDtoResponseEnum';

  @override
  Object serialize(
    Serializers serializers,
    RespondToDispatchDtoResponseEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RespondToDispatchDtoResponseEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RespondToDispatchDtoResponseEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RespondToDispatchDto extends RespondToDispatchDto {
  @override
  final RespondToDispatchDtoResponseEnum response;

  factory _$RespondToDispatchDto([
    void Function(RespondToDispatchDtoBuilder)? updates,
  ]) => (RespondToDispatchDtoBuilder()..update(updates))._build();

  _$RespondToDispatchDto._({required this.response}) : super._();
  @override
  RespondToDispatchDto rebuild(
    void Function(RespondToDispatchDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RespondToDispatchDtoBuilder toBuilder() =>
      RespondToDispatchDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RespondToDispatchDto && response == other.response;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, response.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'RespondToDispatchDto',
    )..add('response', response)).toString();
  }
}

class RespondToDispatchDtoBuilder
    implements Builder<RespondToDispatchDto, RespondToDispatchDtoBuilder> {
  _$RespondToDispatchDto? _$v;

  RespondToDispatchDtoResponseEnum? _response;
  RespondToDispatchDtoResponseEnum? get response => _$this._response;
  set response(RespondToDispatchDtoResponseEnum? response) =>
      _$this._response = response;

  RespondToDispatchDtoBuilder() {
    RespondToDispatchDto._defaults(this);
  }

  RespondToDispatchDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _response = $v.response;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RespondToDispatchDto other) {
    _$v = other as _$RespondToDispatchDto;
  }

  @override
  void update(void Function(RespondToDispatchDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RespondToDispatchDto build() => _build();

  _$RespondToDispatchDto _build() {
    final _$result =
        _$v ??
        _$RespondToDispatchDto._(
          response: BuiltValueNullFieldError.checkNotNull(
            response,
            r'RespondToDispatchDto',
            'response',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
