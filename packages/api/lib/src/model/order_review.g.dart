// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_review.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderReview extends OrderReview {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final String customerId;
  @override
  final ReviewTargetType targetType;
  @override
  final String? fulfillmentId;
  @override
  final String? deliveryGroupId;
  @override
  final String? vendorId;
  @override
  final String? driverId;
  @override
  final num rating;
  @override
  final String? comment;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$OrderReview([void Function(OrderReviewBuilder)? updates]) =>
      (OrderReviewBuilder()..update(updates))._build();

  _$OrderReview._({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.targetType,
    this.fulfillmentId,
    this.deliveryGroupId,
    this.vendorId,
    this.driverId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  OrderReview rebuild(void Function(OrderReviewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrderReviewBuilder toBuilder() => OrderReviewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderReview &&
        id == other.id &&
        orderId == other.orderId &&
        customerId == other.customerId &&
        targetType == other.targetType &&
        fulfillmentId == other.fulfillmentId &&
        deliveryGroupId == other.deliveryGroupId &&
        vendorId == other.vendorId &&
        driverId == other.driverId &&
        rating == other.rating &&
        comment == other.comment &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, customerId.hashCode);
    _$hash = $jc(_$hash, targetType.hashCode);
    _$hash = $jc(_$hash, fulfillmentId.hashCode);
    _$hash = $jc(_$hash, deliveryGroupId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderReview')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('customerId', customerId)
          ..add('targetType', targetType)
          ..add('fulfillmentId', fulfillmentId)
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('vendorId', vendorId)
          ..add('driverId', driverId)
          ..add('rating', rating)
          ..add('comment', comment)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class OrderReviewBuilder implements Builder<OrderReview, OrderReviewBuilder> {
  _$OrderReview? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  ReviewTargetType? _targetType;
  ReviewTargetType? get targetType => _$this._targetType;
  set targetType(ReviewTargetType? targetType) =>
      _$this._targetType = targetType;

  String? _fulfillmentId;
  String? get fulfillmentId => _$this._fulfillmentId;
  set fulfillmentId(String? fulfillmentId) =>
      _$this._fulfillmentId = fulfillmentId;

  String? _deliveryGroupId;
  String? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(String? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  num? _rating;
  num? get rating => _$this._rating;
  set rating(num? rating) => _$this._rating = rating;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  OrderReviewBuilder() {
    OrderReview._defaults(this);
  }

  OrderReviewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _customerId = $v.customerId;
      _targetType = $v.targetType;
      _fulfillmentId = $v.fulfillmentId;
      _deliveryGroupId = $v.deliveryGroupId;
      _vendorId = $v.vendorId;
      _driverId = $v.driverId;
      _rating = $v.rating;
      _comment = $v.comment;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderReview other) {
    _$v = other as _$OrderReview;
  }

  @override
  void update(void Function(OrderReviewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderReview build() => _build();

  _$OrderReview _build() {
    final _$result =
        _$v ??
        _$OrderReview._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'OrderReview', 'id'),
          orderId: BuiltValueNullFieldError.checkNotNull(
            orderId,
            r'OrderReview',
            'orderId',
          ),
          customerId: BuiltValueNullFieldError.checkNotNull(
            customerId,
            r'OrderReview',
            'customerId',
          ),
          targetType: BuiltValueNullFieldError.checkNotNull(
            targetType,
            r'OrderReview',
            'targetType',
          ),
          fulfillmentId: fulfillmentId,
          deliveryGroupId: deliveryGroupId,
          vendorId: vendorId,
          driverId: driverId,
          rating: BuiltValueNullFieldError.checkNotNull(
            rating,
            r'OrderReview',
            'rating',
          ),
          comment: comment,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'OrderReview',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'OrderReview',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
