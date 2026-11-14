// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_delivery_group_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderDeliveryGroupItem extends OrderDeliveryGroupItem {
  @override
  final String id;
  @override
  final String deliveryGroupId;
  @override
  final String fulfillmentId;
  @override
  final num sequence;

  factory _$OrderDeliveryGroupItem([
    void Function(OrderDeliveryGroupItemBuilder)? updates,
  ]) => (OrderDeliveryGroupItemBuilder()..update(updates))._build();

  _$OrderDeliveryGroupItem._({
    required this.id,
    required this.deliveryGroupId,
    required this.fulfillmentId,
    required this.sequence,
  }) : super._();
  @override
  OrderDeliveryGroupItem rebuild(
    void Function(OrderDeliveryGroupItemBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderDeliveryGroupItemBuilder toBuilder() =>
      OrderDeliveryGroupItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderDeliveryGroupItem &&
        id == other.id &&
        deliveryGroupId == other.deliveryGroupId &&
        fulfillmentId == other.fulfillmentId &&
        sequence == other.sequence;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, deliveryGroupId.hashCode);
    _$hash = $jc(_$hash, fulfillmentId.hashCode);
    _$hash = $jc(_$hash, sequence.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderDeliveryGroupItem')
          ..add('id', id)
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('fulfillmentId', fulfillmentId)
          ..add('sequence', sequence))
        .toString();
  }
}

class OrderDeliveryGroupItemBuilder
    implements Builder<OrderDeliveryGroupItem, OrderDeliveryGroupItemBuilder> {
  _$OrderDeliveryGroupItem? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _deliveryGroupId;
  String? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(String? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  String? _fulfillmentId;
  String? get fulfillmentId => _$this._fulfillmentId;
  set fulfillmentId(String? fulfillmentId) =>
      _$this._fulfillmentId = fulfillmentId;

  num? _sequence;
  num? get sequence => _$this._sequence;
  set sequence(num? sequence) => _$this._sequence = sequence;

  OrderDeliveryGroupItemBuilder() {
    OrderDeliveryGroupItem._defaults(this);
  }

  OrderDeliveryGroupItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _deliveryGroupId = $v.deliveryGroupId;
      _fulfillmentId = $v.fulfillmentId;
      _sequence = $v.sequence;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderDeliveryGroupItem other) {
    _$v = other as _$OrderDeliveryGroupItem;
  }

  @override
  void update(void Function(OrderDeliveryGroupItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderDeliveryGroupItem build() => _build();

  _$OrderDeliveryGroupItem _build() {
    final _$result =
        _$v ??
        _$OrderDeliveryGroupItem._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'OrderDeliveryGroupItem',
            'id',
          ),
          deliveryGroupId: BuiltValueNullFieldError.checkNotNull(
            deliveryGroupId,
            r'OrderDeliveryGroupItem',
            'deliveryGroupId',
          ),
          fulfillmentId: BuiltValueNullFieldError.checkNotNull(
            fulfillmentId,
            r'OrderDeliveryGroupItem',
            'fulfillmentId',
          ),
          sequence: BuiltValueNullFieldError.checkNotNull(
            sequence,
            r'OrderDeliveryGroupItem',
            'sequence',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
