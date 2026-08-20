// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_weekly_shifts_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BookWeeklyShiftsDto extends BookWeeklyShiftsDto {
  @override
  final BuiltList<String> shiftPoolIds;

  factory _$BookWeeklyShiftsDto([
    void Function(BookWeeklyShiftsDtoBuilder)? updates,
  ]) => (BookWeeklyShiftsDtoBuilder()..update(updates))._build();

  _$BookWeeklyShiftsDto._({required this.shiftPoolIds}) : super._();
  @override
  BookWeeklyShiftsDto rebuild(
    void Function(BookWeeklyShiftsDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  BookWeeklyShiftsDtoBuilder toBuilder() =>
      BookWeeklyShiftsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BookWeeklyShiftsDto && shiftPoolIds == other.shiftPoolIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, shiftPoolIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'BookWeeklyShiftsDto',
    )..add('shiftPoolIds', shiftPoolIds)).toString();
  }
}

class BookWeeklyShiftsDtoBuilder
    implements Builder<BookWeeklyShiftsDto, BookWeeklyShiftsDtoBuilder> {
  _$BookWeeklyShiftsDto? _$v;

  ListBuilder<String>? _shiftPoolIds;
  ListBuilder<String> get shiftPoolIds =>
      _$this._shiftPoolIds ??= ListBuilder<String>();
  set shiftPoolIds(ListBuilder<String>? shiftPoolIds) =>
      _$this._shiftPoolIds = shiftPoolIds;

  BookWeeklyShiftsDtoBuilder() {
    BookWeeklyShiftsDto._defaults(this);
  }

  BookWeeklyShiftsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _shiftPoolIds = $v.shiftPoolIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BookWeeklyShiftsDto other) {
    _$v = other as _$BookWeeklyShiftsDto;
  }

  @override
  void update(void Function(BookWeeklyShiftsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BookWeeklyShiftsDto build() => _build();

  _$BookWeeklyShiftsDto _build() {
    _$BookWeeklyShiftsDto _$result;
    try {
      _$result =
          _$v ?? _$BookWeeklyShiftsDto._(shiftPoolIds: shiftPoolIds.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'shiftPoolIds';
        shiftPoolIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BookWeeklyShiftsDto',
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
