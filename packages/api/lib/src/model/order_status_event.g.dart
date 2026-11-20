// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_status_event.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderStatusEvent extends OrderStatusEvent {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final String? fulfillmentId;
  @override
  final String? deliveryGroupId;
  @override
  final String? eventKey;
  @override
  final OrderStatus status;
  @override
  final String? note;
  @override
  final String? createdBy;
  @override
  final String? actorUserId;
  @override
  final Role? actorRole;
  @override
  final String? actorName;
  @override
  final String? actorNameAr;
  @override
  final String? actorAvatar;
  @override
  final String? actorVendorId;
  @override
  final OrderActorSummaryDto? actor;
  @override
  final DateTime createdAt;

  factory _$OrderStatusEvent([
    void Function(OrderStatusEventBuilder)? updates,
  ]) => (OrderStatusEventBuilder()..update(updates))._build();

  _$OrderStatusEvent._({
    required this.id,
    required this.orderId,
    this.fulfillmentId,
    this.deliveryGroupId,
    this.eventKey,
    required this.status,
    this.note,
    this.createdBy,
    this.actorUserId,
    this.actorRole,
    this.actorName,
    this.actorNameAr,
    this.actorAvatar,
    this.actorVendorId,
    this.actor,
    required this.createdAt,
  }) : super._();
  @override
  OrderStatusEvent rebuild(void Function(OrderStatusEventBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrderStatusEventBuilder toBuilder() =>
      OrderStatusEventBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderStatusEvent &&
        id == other.id &&
        orderId == other.orderId &&
        fulfillmentId == other.fulfillmentId &&
        deliveryGroupId == other.deliveryGroupId &&
        eventKey == other.eventKey &&
        status == other.status &&
        note == other.note &&
        createdBy == other.createdBy &&
        actorUserId == other.actorUserId &&
        actorRole == other.actorRole &&
        actorName == other.actorName &&
        actorNameAr == other.actorNameAr &&
        actorAvatar == other.actorAvatar &&
        actorVendorId == other.actorVendorId &&
        actor == other.actor &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, fulfillmentId.hashCode);
    _$hash = $jc(_$hash, deliveryGroupId.hashCode);
    _$hash = $jc(_$hash, eventKey.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, createdBy.hashCode);
    _$hash = $jc(_$hash, actorUserId.hashCode);
    _$hash = $jc(_$hash, actorRole.hashCode);
    _$hash = $jc(_$hash, actorName.hashCode);
    _$hash = $jc(_$hash, actorNameAr.hashCode);
    _$hash = $jc(_$hash, actorAvatar.hashCode);
    _$hash = $jc(_$hash, actorVendorId.hashCode);
    _$hash = $jc(_$hash, actor.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderStatusEvent')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('fulfillmentId', fulfillmentId)
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('eventKey', eventKey)
          ..add('status', status)
          ..add('note', note)
          ..add('createdBy', createdBy)
          ..add('actorUserId', actorUserId)
          ..add('actorRole', actorRole)
          ..add('actorName', actorName)
          ..add('actorNameAr', actorNameAr)
          ..add('actorAvatar', actorAvatar)
          ..add('actorVendorId', actorVendorId)
          ..add('actor', actor)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class OrderStatusEventBuilder
    implements Builder<OrderStatusEvent, OrderStatusEventBuilder> {
  _$OrderStatusEvent? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _fulfillmentId;
  String? get fulfillmentId => _$this._fulfillmentId;
  set fulfillmentId(String? fulfillmentId) =>
      _$this._fulfillmentId = fulfillmentId;

  String? _deliveryGroupId;
  String? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(String? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  String? _eventKey;
  String? get eventKey => _$this._eventKey;
  set eventKey(String? eventKey) => _$this._eventKey = eventKey;

  OrderStatus? _status;
  OrderStatus? get status => _$this._status;
  set status(OrderStatus? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  String? _createdBy;
  String? get createdBy => _$this._createdBy;
  set createdBy(String? createdBy) => _$this._createdBy = createdBy;

  String? _actorUserId;
  String? get actorUserId => _$this._actorUserId;
  set actorUserId(String? actorUserId) => _$this._actorUserId = actorUserId;

  Role? _actorRole;
  Role? get actorRole => _$this._actorRole;
  set actorRole(Role? actorRole) => _$this._actorRole = actorRole;

  String? _actorName;
  String? get actorName => _$this._actorName;
  set actorName(String? actorName) => _$this._actorName = actorName;

  String? _actorNameAr;
  String? get actorNameAr => _$this._actorNameAr;
  set actorNameAr(String? actorNameAr) => _$this._actorNameAr = actorNameAr;

  String? _actorAvatar;
  String? get actorAvatar => _$this._actorAvatar;
  set actorAvatar(String? actorAvatar) => _$this._actorAvatar = actorAvatar;

  String? _actorVendorId;
  String? get actorVendorId => _$this._actorVendorId;
  set actorVendorId(String? actorVendorId) =>
      _$this._actorVendorId = actorVendorId;

  OrderActorSummaryDtoBuilder? _actor;
  OrderActorSummaryDtoBuilder get actor =>
      _$this._actor ??= OrderActorSummaryDtoBuilder();
  set actor(OrderActorSummaryDtoBuilder? actor) => _$this._actor = actor;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  OrderStatusEventBuilder() {
    OrderStatusEvent._defaults(this);
  }

  OrderStatusEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _fulfillmentId = $v.fulfillmentId;
      _deliveryGroupId = $v.deliveryGroupId;
      _eventKey = $v.eventKey;
      _status = $v.status;
      _note = $v.note;
      _createdBy = $v.createdBy;
      _actorUserId = $v.actorUserId;
      _actorRole = $v.actorRole;
      _actorName = $v.actorName;
      _actorNameAr = $v.actorNameAr;
      _actorAvatar = $v.actorAvatar;
      _actorVendorId = $v.actorVendorId;
      _actor = $v.actor?.toBuilder();
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderStatusEvent other) {
    _$v = other as _$OrderStatusEvent;
  }

  @override
  void update(void Function(OrderStatusEventBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderStatusEvent build() => _build();

  _$OrderStatusEvent _build() {
    _$OrderStatusEvent _$result;
    try {
      _$result =
          _$v ??
          _$OrderStatusEvent._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'OrderStatusEvent',
              'id',
            ),
            orderId: BuiltValueNullFieldError.checkNotNull(
              orderId,
              r'OrderStatusEvent',
              'orderId',
            ),
            fulfillmentId: fulfillmentId,
            deliveryGroupId: deliveryGroupId,
            eventKey: eventKey,
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'OrderStatusEvent',
              'status',
            ),
            note: note,
            createdBy: createdBy,
            actorUserId: actorUserId,
            actorRole: actorRole,
            actorName: actorName,
            actorNameAr: actorNameAr,
            actorAvatar: actorAvatar,
            actorVendorId: actorVendorId,
            actor: _actor?.build(),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'OrderStatusEvent',
              'createdAt',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'actor';
        _actor?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderStatusEvent',
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
