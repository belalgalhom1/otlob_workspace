// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_bulk_assign_shifts_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminBulkAssignShiftsDto extends AdminBulkAssignShiftsDto {
  @override
  final String driverId;
  @override
  final BuiltList<String> shiftPoolIds;

  factory _$AdminBulkAssignShiftsDto([
    void Function(AdminBulkAssignShiftsDtoBuilder)? updates,
  ]) => (AdminBulkAssignShiftsDtoBuilder()..update(updates))._build();

  _$AdminBulkAssignShiftsDto._({
    required this.driverId,
    required this.shiftPoolIds,
  }) : super._();
  @override
  AdminBulkAssignShiftsDto rebuild(
    void Function(AdminBulkAssignShiftsDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminBulkAssignShiftsDtoBuilder toBuilder() =>
      AdminBulkAssignShiftsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminBulkAssignShiftsDto &&
        driverId == other.driverId &&
        shiftPoolIds == other.shiftPoolIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, shiftPoolIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminBulkAssignShiftsDto')
          ..add('driverId', driverId)
          ..add('shiftPoolIds', shiftPoolIds))
        .toString();
  }
}

class AdminBulkAssignShiftsDtoBuilder
    implements
        Builder<AdminBulkAssignShiftsDto, AdminBulkAssignShiftsDtoBuilder> {
  _$AdminBulkAssignShiftsDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  ListBuilder<String>? _shiftPoolIds;
  ListBuilder<String> get shiftPoolIds =>
      _$this._shiftPoolIds ??= ListBuilder<String>();
  set shiftPoolIds(ListBuilder<String>? shiftPoolIds) =>
      _$this._shiftPoolIds = shiftPoolIds;

  AdminBulkAssignShiftsDtoBuilder() {
    AdminBulkAssignShiftsDto._defaults(this);
  }

  AdminBulkAssignShiftsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _shiftPoolIds = $v.shiftPoolIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminBulkAssignShiftsDto other) {
    _$v = other as _$AdminBulkAssignShiftsDto;
  }

  @override
  void update(void Function(AdminBulkAssignShiftsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminBulkAssignShiftsDto build() => _build();

  _$AdminBulkAssignShiftsDto _build() {
    _$AdminBulkAssignShiftsDto _$result;
    try {
      _$result =
          _$v ??
          _$AdminBulkAssignShiftsDto._(
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'AdminBulkAssignShiftsDto',
              'driverId',
            ),
            shiftPoolIds: shiftPoolIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'shiftPoolIds';
        shiftPoolIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AdminBulkAssignShiftsDto',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
