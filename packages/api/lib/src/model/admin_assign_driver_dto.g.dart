// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_assign_driver_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminAssignDriverDto extends AdminAssignDriverDto {
  @override
  final String driverId;
  @override
  final String? deliveryGroupId;
  @override
  final DeliveryIncidentResponsibility? previousDriverResponsibility;
  @override
  final String? reassignmentReason;

  factory _$AdminAssignDriverDto([
    void Function(AdminAssignDriverDtoBuilder)? updates,
  ]) => (AdminAssignDriverDtoBuilder()..update(updates))._build();

  _$AdminAssignDriverDto._({
    required this.driverId,
    this.deliveryGroupId,
    this.previousDriverResponsibility,
    this.reassignmentReason,
  }) : super._();
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
    return other is AdminAssignDriverDto &&
        driverId == other.driverId &&
        deliveryGroupId == other.deliveryGroupId &&
        previousDriverResponsibility == other.previousDriverResponsibility &&
        reassignmentReason == other.reassignmentReason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, deliveryGroupId.hashCode);
    _$hash = $jc(_$hash, previousDriverResponsibility.hashCode);
    _$hash = $jc(_$hash, reassignmentReason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AdminAssignDriverDto')
          ..add('driverId', driverId)
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('previousDriverResponsibility', previousDriverResponsibility)
          ..add('reassignmentReason', reassignmentReason))
        .toString();
  }
}

class AdminAssignDriverDtoBuilder
    implements Builder<AdminAssignDriverDto, AdminAssignDriverDtoBuilder> {
  _$AdminAssignDriverDto? _$v;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _deliveryGroupId;
  String? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(String? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  DeliveryIncidentResponsibility? _previousDriverResponsibility;
  DeliveryIncidentResponsibility? get previousDriverResponsibility =>
      _$this._previousDriverResponsibility;
  set previousDriverResponsibility(
    DeliveryIncidentResponsibility? previousDriverResponsibility,
  ) => _$this._previousDriverResponsibility = previousDriverResponsibility;

  String? _reassignmentReason;
  String? get reassignmentReason => _$this._reassignmentReason;
  set reassignmentReason(String? reassignmentReason) =>
      _$this._reassignmentReason = reassignmentReason;

  AdminAssignDriverDtoBuilder() {
    AdminAssignDriverDto._defaults(this);
  }

  AdminAssignDriverDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _driverId = $v.driverId;
      _deliveryGroupId = $v.deliveryGroupId;
      _previousDriverResponsibility = $v.previousDriverResponsibility;
      _reassignmentReason = $v.reassignmentReason;
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
          deliveryGroupId: deliveryGroupId,
          previousDriverResponsibility: previousDriverResponsibility,
          reassignmentReason: reassignmentReason,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
