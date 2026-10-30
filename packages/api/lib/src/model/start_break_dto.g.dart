// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_break_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const StartBreakDtoReasonEnum _$startBreakDtoReasonEnum_PRAYER =
    const StartBreakDtoReasonEnum._('PRAYER');
const StartBreakDtoReasonEnum _$startBreakDtoReasonEnum_MEAL =
    const StartBreakDtoReasonEnum._('MEAL');
const StartBreakDtoReasonEnum _$startBreakDtoReasonEnum_REST =
    const StartBreakDtoReasonEnum._('REST');
const StartBreakDtoReasonEnum _$startBreakDtoReasonEnum_PERSONAL =
    const StartBreakDtoReasonEnum._('PERSONAL');
const StartBreakDtoReasonEnum _$startBreakDtoReasonEnum_OTHER =
    const StartBreakDtoReasonEnum._('OTHER');

StartBreakDtoReasonEnum _$startBreakDtoReasonEnumValueOf(String name) {
  switch (name) {
    case 'PRAYER':
      return _$startBreakDtoReasonEnum_PRAYER;
    case 'MEAL':
      return _$startBreakDtoReasonEnum_MEAL;
    case 'REST':
      return _$startBreakDtoReasonEnum_REST;
    case 'PERSONAL':
      return _$startBreakDtoReasonEnum_PERSONAL;
    case 'OTHER':
      return _$startBreakDtoReasonEnum_OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<StartBreakDtoReasonEnum> _$startBreakDtoReasonEnumValues =
    BuiltSet<StartBreakDtoReasonEnum>(const <StartBreakDtoReasonEnum>[
      _$startBreakDtoReasonEnum_PRAYER,
      _$startBreakDtoReasonEnum_MEAL,
      _$startBreakDtoReasonEnum_REST,
      _$startBreakDtoReasonEnum_PERSONAL,
      _$startBreakDtoReasonEnum_OTHER,
    ]);

Serializer<StartBreakDtoReasonEnum> _$startBreakDtoReasonEnumSerializer =
    _$StartBreakDtoReasonEnumSerializer();

class _$StartBreakDtoReasonEnumSerializer
    implements PrimitiveSerializer<StartBreakDtoReasonEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PRAYER': 'PRAYER',
    'MEAL': 'MEAL',
    'REST': 'REST',
    'PERSONAL': 'PERSONAL',
    'OTHER': 'OTHER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PRAYER': 'PRAYER',
    'MEAL': 'MEAL',
    'REST': 'REST',
    'PERSONAL': 'PERSONAL',
    'OTHER': 'OTHER',
  };

  @override
  final Iterable<Type> types = const <Type>[StartBreakDtoReasonEnum];
  @override
  final String wireName = 'StartBreakDtoReasonEnum';

  @override
  Object serialize(
    Serializers serializers,
    StartBreakDtoReasonEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  StartBreakDtoReasonEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => StartBreakDtoReasonEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$StartBreakDto extends StartBreakDto {
  @override
  final StartBreakDtoReasonEnum? reason;
  @override
  final String? note;
  @override
  final num? requestedMinutes;

  factory _$StartBreakDto([void Function(StartBreakDtoBuilder)? updates]) =>
      (StartBreakDtoBuilder()..update(updates))._build();

  _$StartBreakDto._({this.reason, this.note, this.requestedMinutes})
    : super._();
  @override
  StartBreakDto rebuild(void Function(StartBreakDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  StartBreakDtoBuilder toBuilder() => StartBreakDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StartBreakDto &&
        reason == other.reason &&
        note == other.note &&
        requestedMinutes == other.requestedMinutes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, requestedMinutes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'StartBreakDto')
          ..add('reason', reason)
          ..add('note', note)
          ..add('requestedMinutes', requestedMinutes))
        .toString();
  }
}

class StartBreakDtoBuilder
    implements Builder<StartBreakDto, StartBreakDtoBuilder> {
  _$StartBreakDto? _$v;

  StartBreakDtoReasonEnum? _reason;
  StartBreakDtoReasonEnum? get reason => _$this._reason;
  set reason(StartBreakDtoReasonEnum? reason) => _$this._reason = reason;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  num? _requestedMinutes;
  num? get requestedMinutes => _$this._requestedMinutes;
  set requestedMinutes(num? requestedMinutes) =>
      _$this._requestedMinutes = requestedMinutes;

  StartBreakDtoBuilder() {
    StartBreakDto._defaults(this);
  }

  StartBreakDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _note = $v.note;
      _requestedMinutes = $v.requestedMinutes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StartBreakDto other) {
    _$v = other as _$StartBreakDto;
  }

  @override
  void update(void Function(StartBreakDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  StartBreakDto build() => _build();

  _$StartBreakDto _build() {
    final _$result =
        _$v ??
        _$StartBreakDto._(
          reason: reason,
          note: note,
          requestedMinutes: requestedMinutes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
