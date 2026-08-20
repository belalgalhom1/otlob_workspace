// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_assign_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminAssignDriverDto extends AdminAssignDriverDto {
  @override
  final String driverId;

  factory _$AdminAssignDriverDto([
    void Function(AdminAssignDriverDtoBuilder)? updates,
  ]) => (AdminAssignDriverDtoBuilder()..update(updates))._build();

  _$AdminAssignDriverDto._({required this.driverId}) : super._();
  @override
  AdminAssignDriverDto rebuild(
    void Function(AdminAssignDriverDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminAssignDriverDtoBuilder toBuilder() =>
      AdminAssignDriverDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminAssignDriverDto && driverId == other.driverId;
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
      r'AdminAssignDriverDto',
    )..add('driverId', driverId)).toString();
  }
}

class AdminAssignDriverDtoBuilder
    implements Builder<AdminAssignDriverDto, AdminAssignDriverDtoBuilder> {
  _$AdminAssignDriverDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  AdminAssignDriverDtoBuilder() {
    AdminAssignDriverDto._defaults(this);
  }

  AdminAssignDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminAssignDriverDto other) {
    _$v = other as _$AdminAssignDriverDto;
  }

  @override
  void update(void Function(AdminAssignDriverDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminAssignDriverDto build() => _build();

  _$AdminAssignDriverDto _build() {
    final _$result =
        _$v ??
        _$AdminAssignDriverDto._(
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'AdminAssignDriverDto',
            'driverId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
