// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_drivers_to_manager_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AssignDriversToManagerDto extends AssignDriversToManagerDto {
  @override
  final String driverManagerUserId;
  @override
  final BuiltList<String>? driverIds;
  @override
  final bool? manageAllDrivers;

  factory _$AssignDriversToManagerDto([
    void Function(AssignDriversToManagerDtoBuilder)? updates,
  ]) => (AssignDriversToManagerDtoBuilder()..update(updates))._build();

  _$AssignDriversToManagerDto._({
    required this.driverManagerUserId,
    this.driverIds,
    this.manageAllDrivers,
  }) : super._();
  @override
  AssignDriversToManagerDto rebuild(
    void Function(AssignDriversToManagerDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AssignDriversToManagerDtoBuilder toBuilder() =>
      AssignDriversToManagerDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssignDriversToManagerDto &&
        driverManagerUserId == other.driverManagerUserId &&
        driverIds == other.driverIds &&
        manageAllDrivers == other.manageAllDrivers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driverManagerUserId.hashCode);
    _$hash = $jc(_$hash, driverIds.hashCode);
    _$hash = $jc(_$hash, manageAllDrivers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AssignDriversToManagerDto')
          ..add('driverManagerUserId', driverManagerUserId)
          ..add('driverIds', driverIds)
          ..add('manageAllDrivers', manageAllDrivers))
        .toString();
  }
}

class AssignDriversToManagerDtoBuilder
    implements
        Builder<AssignDriversToManagerDto, AssignDriversToManagerDtoBuilder> {
  _$AssignDriversToManagerDto? _$v;

  String? _driverManagerUserId;
  String? get driverManagerUserId => _$this._driverManagerUserId;
  set driverManagerUserId(String? driverManagerUserId) =>
      _$this._driverManagerUserId = driverManagerUserId;

  ListBuilder<String>? _driverIds;
  ListBuilder<String> get driverIds =>
      _$this._driverIds ??= ListBuilder<String>();
  set driverIds(ListBuilder<String>? driverIds) =>
      _$this._driverIds = driverIds;

  bool? _manageAllDrivers;
  bool? get manageAllDrivers => _$this._manageAllDrivers;
  set manageAllDrivers(bool? manageAllDrivers) =>
      _$this._manageAllDrivers = manageAllDrivers;

  AssignDriversToManagerDtoBuilder() {
    AssignDriversToManagerDto._defaults(this);
  }

  AssignDriversToManagerDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverManagerUserId = $v.driverManagerUserId;
      _driverIds = $v.driverIds?.toBuilder();
      _manageAllDrivers = $v.manageAllDrivers;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssignDriversToManagerDto other) {
    _$v = other as _$AssignDriversToManagerDto;
  }

  @override
  void update(void Function(AssignDriversToManagerDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssignDriversToManagerDto build() => _build();

  _$AssignDriversToManagerDto _build() {
    _$AssignDriversToManagerDto _$result;
    try {
      _$result =
          _$v ??
          _$AssignDriversToManagerDto._(
            driverManagerUserId: BuiltValueNullFieldError.checkNotNull(
              driverManagerUserId,
              r'AssignDriversToManagerDto',
              'driverManagerUserId',
            ),
            driverIds: _driverIds?.build(),
            manageAllDrivers: manageAllDrivers,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'driverIds';
        _driverIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AssignDriversToManagerDto',
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
