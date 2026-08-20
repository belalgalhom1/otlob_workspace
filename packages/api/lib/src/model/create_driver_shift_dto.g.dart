// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_driver_shift_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateDriverShiftDto extends CreateDriverShiftDto {
  @override
  final String startTime;
  @override
  final String endTime;
  @override
  final String? zoneId;

  factory _$CreateDriverShiftDto([
    void Function(CreateDriverShiftDtoBuilder)? updates,
  ]) => (CreateDriverShiftDtoBuilder()..update(updates))._build();

  _$CreateDriverShiftDto._({
    required this.startTime,
    required this.endTime,
    this.zoneId,
  }) : super._();
  @override
  CreateDriverShiftDto rebuild(
    void Function(CreateDriverShiftDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateDriverShiftDtoBuilder toBuilder() =>
      CreateDriverShiftDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateDriverShiftDto &&
        startTime == other.startTime &&
        endTime == other.endTime &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, startTime.hashCode);
    _$hash = $jc(_$hash, endTime.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateDriverShiftDto')
          ..add('startTime', startTime)
          ..add('endTime', endTime)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class CreateDriverShiftDtoBuilder
    implements Builder<CreateDriverShiftDto, CreateDriverShiftDtoBuilder> {
  _$CreateDriverShiftDto? _$v;

  String? _startTime;
  String? get startTime => _$this._startTime;
  set startTime(String? startTime) => _$this._startTime = startTime;

  String? _endTime;
  String? get endTime => _$this._endTime;
  set endTime(String? endTime) => _$this._endTime = endTime;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  CreateDriverShiftDtoBuilder() {
    CreateDriverShiftDto._defaults(this);
  }

  CreateDriverShiftDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _startTime = $v.startTime;
      _endTime = $v.endTime;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateDriverShiftDto other) {
    _$v = other as _$CreateDriverShiftDto;
  }

  @override
  void update(void Function(CreateDriverShiftDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateDriverShiftDto build() => _build();

  _$CreateDriverShiftDto _build() {
    final _$result =
        _$v ??
        _$CreateDriverShiftDto._(
          startTime: BuiltValueNullFieldError.checkNotNull(
            startTime,
            r'CreateDriverShiftDto',
            'startTime',
          ),
          endTime: BuiltValueNullFieldError.checkNotNull(
            endTime,
            r'CreateDriverShiftDto',
            'endTime',
          ),
          zoneId: zoneId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
