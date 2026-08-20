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
  final JsonObject? status;
  @override
  final String? note;
  @override
  final String? createdBy;
  @override
  final DateTime createdAt;
  @override
  final JsonObject? order;

  factory _$OrderStatusEvent([
    void Function(OrderStatusEventBuilder)? updates,
  ]) => (OrderStatusEventBuilder()..update(updates))._build();

  _$OrderStatusEvent._({
    required this.id,
    required this.orderId,
    this.status,
    this.note,
    this.createdBy,
    required this.createdAt,
    this.order,
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
        status == other.status &&
        note == other.note &&
        createdBy == other.createdBy &&
        createdAt == other.createdAt &&
        order == other.order;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, createdBy.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, order.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderStatusEvent')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('status', status)
          ..add('note', note)
          ..add('createdBy', createdBy)
          ..add('createdAt', createdAt)
          ..add('order', order))
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

  JsonObject? _status;
  JsonObject? get status => _$this._status;
  set status(JsonObject? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  String? _createdBy;
  String? get createdBy => _$this._createdBy;
  set createdBy(String? createdBy) => _$this._createdBy = createdBy;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  JsonObject? _order;
  JsonObject? get order => _$this._order;
  set order(JsonObject? order) => _$this._order = order;

  OrderStatusEventBuilder() {
    OrderStatusEvent._defaults(this);
  }

  OrderStatusEventBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _status = $v.status;
      _note = $v.note;
      _createdBy = $v.createdBy;
      _createdAt = $v.createdAt;
      _order = $v.order;
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
    final _$result =
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
          status: status,
          note: note,
          createdBy: createdBy,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'OrderStatusEvent',
            'createdAt',
          ),
          order: order,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
