// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_option.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderItemOption extends OrderItemOption {
  @override
  final String id;
  @override
  final String orderItemId;
  @override
  final String? optionId;
  @override
  final String optionName;
  @override
  final num priceAdded;
  @override
  final JsonObject? option;
  @override
  final JsonObject? orderItem;

  factory _$OrderItemOption([void Function(OrderItemOptionBuilder)? updates]) =>
      (OrderItemOptionBuilder()..update(updates))._build();

  _$OrderItemOption._({
    required this.id,
    required this.orderItemId,
    this.optionId,
    required this.optionName,
    required this.priceAdded,
    this.option,
    this.orderItem,
  }) : super._();
  @override
  OrderItemOption rebuild(void Function(OrderItemOptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrderItemOptionBuilder toBuilder() => OrderItemOptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderItemOption &&
        id == other.id &&
        orderItemId == other.orderItemId &&
        optionId == other.optionId &&
        optionName == other.optionName &&
        priceAdded == other.priceAdded &&
        option == other.option &&
        orderItem == other.orderItem;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderItemId.hashCode);
    _$hash = $jc(_$hash, optionId.hashCode);
    _$hash = $jc(_$hash, optionName.hashCode);
    _$hash = $jc(_$hash, priceAdded.hashCode);
    _$hash = $jc(_$hash, option.hashCode);
    _$hash = $jc(_$hash, orderItem.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderItemOption')
          ..add('id', id)
          ..add('orderItemId', orderItemId)
          ..add('optionId', optionId)
          ..add('optionName', optionName)
          ..add('priceAdded', priceAdded)
          ..add('option', option)
          ..add('orderItem', orderItem))
        .toString();
  }
}

class OrderItemOptionBuilder
    implements Builder<OrderItemOption, OrderItemOptionBuilder> {
  _$OrderItemOption? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderItemId;
  String? get orderItemId => _$this._orderItemId;
  set orderItemId(String? orderItemId) => _$this._orderItemId = orderItemId;

  String? _optionId;
  String? get optionId => _$this._optionId;
  set optionId(String? optionId) => _$this._optionId = optionId;

  String? _optionName;
  String? get optionName => _$this._optionName;
  set optionName(String? optionName) => _$this._optionName = optionName;

  num? _priceAdded;
  num? get priceAdded => _$this._priceAdded;
  set priceAdded(num? priceAdded) => _$this._priceAdded = priceAdded;

  JsonObject? _option;
  JsonObject? get option => _$this._option;
  set option(JsonObject? option) => _$this._option = option;

  JsonObject? _orderItem;
  JsonObject? get orderItem => _$this._orderItem;
  set orderItem(JsonObject? orderItem) => _$this._orderItem = orderItem;

  OrderItemOptionBuilder() {
    OrderItemOption._defaults(this);
  }

  OrderItemOptionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderItemId = $v.orderItemId;
      _optionId = $v.optionId;
      _optionName = $v.optionName;
      _priceAdded = $v.priceAdded;
      _option = $v.option;
      _orderItem = $v.orderItem;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderItemOption other) {
    _$v = other as _$OrderItemOption;
  }

  @override
  void update(void Function(OrderItemOptionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderItemOption build() => _build();

  _$OrderItemOption _build() {
    final _$result =
        _$v ??
        _$OrderItemOption._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'OrderItemOption',
            'id',
          ),
          orderItemId: BuiltValueNullFieldError.checkNotNull(
            orderItemId,
            r'OrderItemOption',
            'orderItemId',
          ),
          optionId: optionId,
          optionName: BuiltValueNullFieldError.checkNotNull(
            optionName,
            r'OrderItemOption',
            'optionName',
          ),
          priceAdded: BuiltValueNullFieldError.checkNotNull(
            priceAdded,
            r'OrderItemOption',
            'priceAdded',
          ),
          option: option,
          orderItem: orderItem,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
