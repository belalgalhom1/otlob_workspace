// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_assist_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AssignAssistDriverDto extends AssignAssistDriverDto {
  @override
  final String driverId;

  factory _$AssignAssistDriverDto([
    void Function(AssignAssistDriverDtoBuilder)? updates,
  ]) => (AssignAssistDriverDtoBuilder()..update(updates))._build();

  _$AssignAssistDriverDto._({required this.driverId}) : super._();
  @override
  AssignAssistDriverDto rebuild(
    void Function(AssignAssistDriverDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AssignAssistDriverDtoBuilder toBuilder() =>
      AssignAssistDriverDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssignAssistDriverDto && driverId == other.driverId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'AssignAssistDriverDto',
    )..add('driverId', driverId)).toString();
  }
}

class AssignAssistDriverDtoBuilder
    implements Builder<AssignAssistDriverDto, AssignAssistDriverDtoBuilder> {
  _$AssignAssistDriverDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  AssignAssistDriverDtoBuilder() {
    AssignAssistDriverDto._defaults(this);
  }

  AssignAssistDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssignAssistDriverDto other) {
    _$v = other as _$AssignAssistDriverDto;
  }

  @override
  void update(void Function(AssignAssistDriverDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssignAssistDriverDto build() => _build();

  _$AssignAssistDriverDto _build() {
    final _$result =
        _$v ??
        _$AssignAssistDriverDto._(
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'AssignAssistDriverDto',
            'driverId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
