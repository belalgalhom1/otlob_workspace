// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_delivery_incident_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DriverDeliveryIncidentDto extends DriverDeliveryIncidentDto {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final JsonObject? orderNumber;
  @override
  final String deliveryGroupId;
  @override
  final String driverId;
  @override
  final JsonObject? driverName;
  @override
  final DeliveryIncidentType incidentType;
  @override
  final DeliveryIncidentResponsibility responsibility;
  @override
  final JsonObject? reason;
  @override
  final JsonObject? reportedByUserId;
  @override
  final JsonObject? reviewedByUserId;
  @override
  final DateTime? reviewedAt;
  @override
  final JsonObject? reviewNote;
  @override
  final DateTime occurredAt;
  @override
  final DateTime createdAt;

  factory _$DriverDeliveryIncidentDto([
    void Function(DriverDeliveryIncidentDtoBuilder)? updates,
  ]) => (DriverDeliveryIncidentDtoBuilder()..update(updates))._build();

  _$DriverDeliveryIncidentDto._({
    required this.id,
    required this.orderId,
    this.orderNumber,
    required this.deliveryGroupId,
    required this.driverId,
    this.driverName,
    required this.incidentType,
    required this.responsibility,
    this.reason,
    this.reportedByUserId,
    this.reviewedByUserId,
    this.reviewedAt,
    this.reviewNote,
    required this.occurredAt,
    required this.createdAt,
  }) : super._();
  @override
  DriverDeliveryIncidentDto rebuild(
    void Function(DriverDeliveryIncidentDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DriverDeliveryIncidentDtoBuilder toBuilder() =>
      DriverDeliveryIncidentDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DriverDeliveryIncidentDto &&
        id == other.id &&
        orderId == other.orderId &&
        orderNumber == other.orderNumber &&
        deliveryGroupId == other.deliveryGroupId &&
        driverId == other.driverId &&
        driverName == other.driverName &&
        incidentType == other.incidentType &&
        responsibility == other.responsibility &&
        reason == other.reason &&
        reportedByUserId == other.reportedByUserId &&
        reviewedByUserId == other.reviewedByUserId &&
        reviewedAt == other.reviewedAt &&
        reviewNote == other.reviewNote &&
        occurredAt == other.occurredAt &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, orderNumber.hashCode);
    _$hash = $jc(_$hash, deliveryGroupId.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, driverName.hashCode);
    _$hash = $jc(_$hash, incidentType.hashCode);
    _$hash = $jc(_$hash, responsibility.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, reportedByUserId.hashCode);
    _$hash = $jc(_$hash, reviewedByUserId.hashCode);
    _$hash = $jc(_$hash, reviewedAt.hashCode);
    _$hash = $jc(_$hash, reviewNote.hashCode);
    _$hash = $jc(_$hash, occurredAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DriverDeliveryIncidentDto')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('orderNumber', orderNumber)
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('driverId', driverId)
          ..add('driverName', driverName)
          ..add('incidentType', incidentType)
          ..add('responsibility', responsibility)
          ..add('reason', reason)
          ..add('reportedByUserId', reportedByUserId)
          ..add('reviewedByUserId', reviewedByUserId)
          ..add('reviewedAt', reviewedAt)
          ..add('reviewNote', reviewNote)
          ..add('occurredAt', occurredAt)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class DriverDeliveryIncidentDtoBuilder
    implements
        Builder<DriverDeliveryIncidentDto, DriverDeliveryIncidentDtoBuilder> {
  _$DriverDeliveryIncidentDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  JsonObject? _orderNumber;
  JsonObject? get orderNumber => _$this._orderNumber;
  set orderNumber(JsonObject? orderNumber) => _$this._orderNumber = orderNumber;

  String? _deliveryGroupId;
  String? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(String? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  JsonObject? _driverName;
  JsonObject? get driverName => _$this._driverName;
  set driverName(JsonObject? driverName) => _$this._driverName = driverName;

  DeliveryIncidentType? _incidentType;
  DeliveryIncidentType? get incidentType => _$this._incidentType;
  set incidentType(DeliveryIncidentType? incidentType) =>
      _$this._incidentType = incidentType;

  DeliveryIncidentResponsibility? _responsibility;
  DeliveryIncidentResponsibility? get responsibility => _$this._responsibility;
  set responsibility(DeliveryIncidentResponsibility? responsibility) =>
      _$this._responsibility = responsibility;

  JsonObject? _reason;
  JsonObject? get reason => _$this._reason;
  set reason(JsonObject? reason) => _$this._reason = reason;

  JsonObject? _reportedByUserId;
  JsonObject? get reportedByUserId => _$this._reportedByUserId;
  set reportedByUserId(JsonObject? reportedByUserId) =>
      _$this._reportedByUserId = reportedByUserId;

  JsonObject? _reviewedByUserId;
  JsonObject? get reviewedByUserId => _$this._reviewedByUserId;
  set reviewedByUserId(JsonObject? reviewedByUserId) =>
      _$this._reviewedByUserId = reviewedByUserId;

  DateTime? _reviewedAt;
  DateTime? get reviewedAt => _$this._reviewedAt;
  set reviewedAt(DateTime? reviewedAt) => _$this._reviewedAt = reviewedAt;

  JsonObject? _reviewNote;
  JsonObject? get reviewNote => _$this._reviewNote;
  set reviewNote(JsonObject? reviewNote) => _$this._reviewNote = reviewNote;

  DateTime? _occurredAt;
  DateTime? get occurredAt => _$this._occurredAt;
  set occurredAt(DateTime? occurredAt) => _$this._occurredAt = occurredAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DriverDeliveryIncidentDtoBuilder() {
    DriverDeliveryIncidentDto._defaults(this);
  }

  DriverDeliveryIncidentDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _orderNumber = $v.orderNumber;
      _deliveryGroupId = $v.deliveryGroupId;
      _driverId = $v.driverId;
      _driverName = $v.driverName;
      _incidentType = $v.incidentType;
      _responsibility = $v.responsibility;
      _reason = $v.reason;
      _reportedByUserId = $v.reportedByUserId;
      _reviewedByUserId = $v.reviewedByUserId;
      _reviewedAt = $v.reviewedAt;
      _reviewNote = $v.reviewNote;
      _occurredAt = $v.occurredAt;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DriverDeliveryIncidentDto other) {
    _$v = other as _$DriverDeliveryIncidentDto;
  }

  @override
  void update(void Function(DriverDeliveryIncidentDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DriverDeliveryIncidentDto build() => _build();

  _$DriverDeliveryIncidentDto _build() {
    final _$result =
        _$v ??
        _$DriverDeliveryIncidentDto._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'DriverDeliveryIncidentDto',
            'id',
          ),
          orderId: BuiltValueNullFieldError.checkNotNull(
            orderId,
            r'DriverDeliveryIncidentDto',
            'orderId',
          ),
          orderNumber: orderNumber,
          deliveryGroupId: BuiltValueNullFieldError.checkNotNull(
            deliveryGroupId,
            r'DriverDeliveryIncidentDto',
            'deliveryGroupId',
          ),
          driverId: BuiltValueNullFieldError.checkNotNull(
            driverId,
            r'DriverDeliveryIncidentDto',
            'driverId',
          ),
          driverName: driverName,
          incidentType: BuiltValueNullFieldError.checkNotNull(
            incidentType,
            r'DriverDeliveryIncidentDto',
            'incidentType',
          ),
          responsibility: BuiltValueNullFieldError.checkNotNull(
            responsibility,
            r'DriverDeliveryIncidentDto',
            'responsibility',
          ),
          reason: reason,
          reportedByUserId: reportedByUserId,
          reviewedByUserId: reviewedByUserId,
          reviewedAt: reviewedAt,
          reviewNote: reviewNote,
          occurredAt: BuiltValueNullFieldError.checkNotNull(
            occurredAt,
            r'DriverDeliveryIncidentDto',
            'occurredAt',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'DriverDeliveryIncidentDto',
            'createdAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
