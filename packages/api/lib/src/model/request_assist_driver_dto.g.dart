// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_assist_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RequestAssistDriverDtoReasonEnum
_$requestAssistDriverDtoReasonEnum_TOO_LARGE =
    const RequestAssistDriverDtoReasonEnum._('TOO_LARGE');
const RequestAssistDriverDtoReasonEnum
_$requestAssistDriverDtoReasonEnum_TOO_HEAVY =
    const RequestAssistDriverDtoReasonEnum._('TOO_HEAVY');
const RequestAssistDriverDtoReasonEnum
_$requestAssistDriverDtoReasonEnum_MULTI_STOP_COMPLEXITY =
    const RequestAssistDriverDtoReasonEnum._('MULTI_STOP_COMPLEXITY');
const RequestAssistDriverDtoReasonEnum
_$requestAssistDriverDtoReasonEnum_LONG_DISTANCE =
    const RequestAssistDriverDtoReasonEnum._('LONG_DISTANCE');
const RequestAssistDriverDtoReasonEnum
_$requestAssistDriverDtoReasonEnum_ACCESS_RESTRICTED =
    const RequestAssistDriverDtoReasonEnum._('ACCESS_RESTRICTED');
const RequestAssistDriverDtoReasonEnum
_$requestAssistDriverDtoReasonEnum_OTHER =
    const RequestAssistDriverDtoReasonEnum._('OTHER');

RequestAssistDriverDtoReasonEnum _$requestAssistDriverDtoReasonEnumValueOf(
  String name,
) {
  switch (name) {
    case 'TOO_LARGE':
      return _$requestAssistDriverDtoReasonEnum_TOO_LARGE;
    case 'TOO_HEAVY':
      return _$requestAssistDriverDtoReasonEnum_TOO_HEAVY;
    case 'MULTI_STOP_COMPLEXITY':
      return _$requestAssistDriverDtoReasonEnum_MULTI_STOP_COMPLEXITY;
    case 'LONG_DISTANCE':
      return _$requestAssistDriverDtoReasonEnum_LONG_DISTANCE;
    case 'ACCESS_RESTRICTED':
      return _$requestAssistDriverDtoReasonEnum_ACCESS_RESTRICTED;
    case 'OTHER':
      return _$requestAssistDriverDtoReasonEnum_OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RequestAssistDriverDtoReasonEnum>
_$requestAssistDriverDtoReasonEnumValues =
    BuiltSet<RequestAssistDriverDtoReasonEnum>(
      const <RequestAssistDriverDtoReasonEnum>[
        _$requestAssistDriverDtoReasonEnum_TOO_LARGE,
        _$requestAssistDriverDtoReasonEnum_TOO_HEAVY,
        _$requestAssistDriverDtoReasonEnum_MULTI_STOP_COMPLEXITY,
        _$requestAssistDriverDtoReasonEnum_LONG_DISTANCE,
        _$requestAssistDriverDtoReasonEnum_ACCESS_RESTRICTED,
        _$requestAssistDriverDtoReasonEnum_OTHER,
      ],
    );

Serializer<RequestAssistDriverDtoReasonEnum>
_$requestAssistDriverDtoReasonEnumSerializer =
    _$RequestAssistDriverDtoReasonEnumSerializer();

class _$RequestAssistDriverDtoReasonEnumSerializer
    implements PrimitiveSerializer<RequestAssistDriverDtoReasonEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'TOO_LARGE': 'TOO_LARGE',
    'TOO_HEAVY': 'TOO_HEAVY',
    'MULTI_STOP_COMPLEXITY': 'MULTI_STOP_COMPLEXITY',
    'LONG_DISTANCE': 'LONG_DISTANCE',
    'ACCESS_RESTRICTED': 'ACCESS_RESTRICTED',
    'OTHER': 'OTHER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'TOO_LARGE': 'TOO_LARGE',
    'TOO_HEAVY': 'TOO_HEAVY',
    'MULTI_STOP_COMPLEXITY': 'MULTI_STOP_COMPLEXITY',
    'LONG_DISTANCE': 'LONG_DISTANCE',
    'ACCESS_RESTRICTED': 'ACCESS_RESTRICTED',
    'OTHER': 'OTHER',
  };

  @override
  final Iterable<Type> types = const <Type>[RequestAssistDriverDtoReasonEnum];
  @override
  final String wireName = 'RequestAssistDriverDtoReasonEnum';

  @override
  Object serialize(
    Serializers serializers,
    RequestAssistDriverDtoReasonEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RequestAssistDriverDtoReasonEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RequestAssistDriverDtoReasonEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RequestAssistDriverDto extends RequestAssistDriverDto {
  @override
  final RequestAssistDriverDtoReasonEnum reason;
  @override
  final String? note;

  factory _$RequestAssistDriverDto([
    void Function(RequestAssistDriverDtoBuilder)? updates,
  ]) => (RequestAssistDriverDtoBuilder()..update(updates))._build();

  _$RequestAssistDriverDto._({required this.reason, this.note}) : super._();
  @override
  RequestAssistDriverDto rebuild(
    void Function(RequestAssistDriverDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RequestAssistDriverDtoBuilder toBuilder() =>
      RequestAssistDriverDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RequestAssistDriverDto &&
        reason == other.reason &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RequestAssistDriverDto')
          ..add('reason', reason)
          ..add('note', note))
        .toString();
  }
}

class RequestAssistDriverDtoBuilder
    implements Builder<RequestAssistDriverDto, RequestAssistDriverDtoBuilder> {
  _$RequestAssistDriverDto? _$v;

  RequestAssistDriverDtoReasonEnum? _reason;
  RequestAssistDriverDtoReasonEnum? get reason => _$this._reason;
  set reason(RequestAssistDriverDtoReasonEnum? reason) =>
      _$this._reason = reason;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  RequestAssistDriverDtoBuilder() {
    RequestAssistDriverDto._defaults(this);
  }

  RequestAssistDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RequestAssistDriverDto other) {
    _$v = other as _$RequestAssistDriverDto;
  }

  @override
  void update(void Function(RequestAssistDriverDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RequestAssistDriverDto build() => _build();

  _$RequestAssistDriverDto _build() {
    final _$result =
        _$v ??
        _$RequestAssistDriverDto._(
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'RequestAssistDriverDto',
            'reason',
          ),
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
