// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_bulk_remove_shifts_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminBulkRemoveShiftsDto extends AdminBulkRemoveShiftsDto {
  @override
  final String driverId;
  @override
  final BuiltList<String> shiftPoolIds;

  factory _$AdminBulkRemoveShiftsDto([
    void Function(AdminBulkRemoveShiftsDtoBuilder)? updates,
  ]) => (AdminBulkRemoveShiftsDtoBuilder()..update(updates))._build();

  _$AdminBulkRemoveShiftsDto._({
    required this.driverId,
    required this.shiftPoolIds,
  }) : super._();
  @override
  AdminBulkRemoveShiftsDto rebuild(
    void Function(AdminBulkRemoveShiftsDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminBulkRemoveShiftsDtoBuilder toBuilder() =>
      AdminBulkRemoveShiftsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminBulkRemoveShiftsDto &&
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
    return (newBuiltValueToStringHelper(r'AdminBulkRemoveShiftsDto')
          ..add('driverId', driverId)
          ..add('shiftPoolIds', shiftPoolIds))
        .toString();
  }
}

class AdminBulkRemoveShiftsDtoBuilder
    implements
        Builder<AdminBulkRemoveShiftsDto, AdminBulkRemoveShiftsDtoBuilder> {
  _$AdminBulkRemoveShiftsDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  ListBuilder<String>? _shiftPoolIds;
  ListBuilder<String> get shiftPoolIds =>
      _$this._shiftPoolIds ??= ListBuilder<String>();
  set shiftPoolIds(ListBuilder<String>? shiftPoolIds) =>
      _$this._shiftPoolIds = shiftPoolIds;

  AdminBulkRemoveShiftsDtoBuilder() {
    AdminBulkRemoveShiftsDto._defaults(this);
  }

  AdminBulkRemoveShiftsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _shiftPoolIds = $v.shiftPoolIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminBulkRemoveShiftsDto other) {
    _$v = other as _$AdminBulkRemoveShiftsDto;
  }

  @override
  void update(void Function(AdminBulkRemoveShiftsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminBulkRemoveShiftsDto build() => _build();

  _$AdminBulkRemoveShiftsDto _build() {
    _$AdminBulkRemoveShiftsDto _$result;
    try {
      _$result =
          _$v ??
          _$AdminBulkRemoveShiftsDto._(
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'AdminBulkRemoveShiftsDto',
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
          r'AdminBulkRemoveShiftsDto',
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
