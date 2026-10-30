// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_book_weekly_shifts_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminBookWeeklyShiftsDto extends AdminBookWeeklyShiftsDto {
  @override
  final String driverId;
  @override
  final BuiltList<String> shiftPoolIds;

  factory _$AdminBookWeeklyShiftsDto([
    void Function(AdminBookWeeklyShiftsDtoBuilder)? updates,
  ]) => (AdminBookWeeklyShiftsDtoBuilder()..update(updates))._build();

  _$AdminBookWeeklyShiftsDto._({
    required this.driverId,
    required this.shiftPoolIds,
  }) : super._();
  @override
  AdminBookWeeklyShiftsDto rebuild(
    void Function(AdminBookWeeklyShiftsDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminBookWeeklyShiftsDtoBuilder toBuilder() =>
      AdminBookWeeklyShiftsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminBookWeeklyShiftsDto &&
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
    return (newBuiltValueToStringHelper(r'AdminBookWeeklyShiftsDto')
          ..add('driverId', driverId)
          ..add('shiftPoolIds', shiftPoolIds))
        .toString();
  }
}

class AdminBookWeeklyShiftsDtoBuilder
    implements
        Builder<AdminBookWeeklyShiftsDto, AdminBookWeeklyShiftsDtoBuilder> {
  _$AdminBookWeeklyShiftsDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  ListBuilder<String>? _shiftPoolIds;
  ListBuilder<String> get shiftPoolIds =>
      _$this._shiftPoolIds ??= ListBuilder<String>();
  set shiftPoolIds(ListBuilder<String>? shiftPoolIds) =>
      _$this._shiftPoolIds = shiftPoolIds;

  AdminBookWeeklyShiftsDtoBuilder() {
    AdminBookWeeklyShiftsDto._defaults(this);
  }

  AdminBookWeeklyShiftsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _shiftPoolIds = $v.shiftPoolIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminBookWeeklyShiftsDto other) {
    _$v = other as _$AdminBookWeeklyShiftsDto;
  }

  @override
  void update(void Function(AdminBookWeeklyShiftsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminBookWeeklyShiftsDto build() => _build();

  _$AdminBookWeeklyShiftsDto _build() {
    _$AdminBookWeeklyShiftsDto _$result;
    try {
      _$result =
          _$v ??
          _$AdminBookWeeklyShiftsDto._(
            driverId: BuiltValueNullFieldError.checkNotNull(
              driverId,
              r'AdminBookWeeklyShiftsDto',
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
          r'AdminBookWeeklyShiftsDto',
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
