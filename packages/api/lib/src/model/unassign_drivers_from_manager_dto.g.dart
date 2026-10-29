// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unassign_drivers_from_manager_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UnassignDriversFromManagerDto extends UnassignDriversFromManagerDto {
  @override
  final BuiltList<String> driverIds;

  factory _$UnassignDriversFromManagerDto([
    void Function(UnassignDriversFromManagerDtoBuilder)? updates,
  ]) => (UnassignDriversFromManagerDtoBuilder()..update(updates))._build();

  _$UnassignDriversFromManagerDto._({required this.driverIds}) : super._();
  @override
  UnassignDriversFromManagerDto rebuild(
    void Function(UnassignDriversFromManagerDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UnassignDriversFromManagerDtoBuilder toBuilder() =>
      UnassignDriversFromManagerDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UnassignDriversFromManagerDto &&
        driverIds == other.driverIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driverIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'UnassignDriversFromManagerDto',
    )..add('driverIds', driverIds)).toString();
  }
}

class UnassignDriversFromManagerDtoBuilder
    implements
        Builder<
          UnassignDriversFromManagerDto,
          UnassignDriversFromManagerDtoBuilder
        > {
  _$UnassignDriversFromManagerDto? _$v;

  ListBuilder<String>? _driverIds;
  ListBuilder<String> get driverIds =>
      _$this._driverIds ??= ListBuilder<String>();
  set driverIds(ListBuilder<String>? driverIds) =>
      _$this._driverIds = driverIds;

  UnassignDriversFromManagerDtoBuilder() {
    UnassignDriversFromManagerDto._defaults(this);
  }

  UnassignDriversFromManagerDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverIds = $v.driverIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UnassignDriversFromManagerDto other) {
    _$v = other as _$UnassignDriversFromManagerDto;
  }

  @override
  void update(void Function(UnassignDriversFromManagerDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UnassignDriversFromManagerDto build() => _build();

  _$UnassignDriversFromManagerDto _build() {
    _$UnassignDriversFromManagerDto _$result;
    try {
      _$result =
          _$v ??
          _$UnassignDriversFromManagerDto._(driverIds: driverIds.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'driverIds';
        driverIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UnassignDriversFromManagerDto',
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
