// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_assign_shift_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminAssignShiftDto extends AdminAssignShiftDto {
  @override
  final String shiftPoolId;
  @override
  final String driverId;

  factory _$AdminAssignShiftDto([
    void Function(AdminAssignShiftDtoBuilder)? updates,
  ]) => (AdminAssignShiftDtoBuilder()..update(updates))._build();

  _$AdminAssignShiftDto._({required this.shiftPoolId, required this.driverId})
    : super._();
  @override
  AdminAssignShiftDto rebuild(
    void Function(AdminAssignShiftDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminAssignShiftDtoBuilder toBuilder() =>
      AdminAssignShiftDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminAssignShiftDto &&
        shiftPoolId == other.shiftPoolId &&
        driverId == other.driverId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, shiftPoolId.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminAssignShiftDto')
          ..add('shiftPoolId', shiftPoolId)
          ..add('driverId', driverId))
        .toString();
  }
}

class AdminAssignShiftDtoBuilder
    implements Builder<AdminAssignShiftDto, AdminAssignShiftDtoBuilder> {
  _$AdminAssignShiftDto? _$v;

  String? _shiftPoolId;
  String? get shiftPoolId => _$this._shiftPoolId;
  set shiftPoolId(String? shiftPoolId) => _$this._shiftPoolId = shiftPoolId;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  AdminAssignShiftDtoBuilder() {
    AdminAssignShiftDto._defaults(this);
  }

  AdminAssignShiftDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shiftPoolId = $v.shiftPoolId;
      _driverId = $v.driverId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminAssignShiftDto other) {
    _$v = other as _$AdminAssignShiftDto;
  }

  @override
  void update(void Function(AdminAssignShiftDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminAssignShiftDto build() => _build();

  _$AdminAssignShiftDto _build() {
    final _$result =
        _$v ??
        _$AdminAssignShiftDto._(
          shiftPoolId: BuiltValueNullFieldError.checkNotNull(
            shiftPoolId,
            r'AdminAssignShiftDto',
            'shiftPoolId',
          ),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'AdminAssignShiftDto',
            'driverId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
