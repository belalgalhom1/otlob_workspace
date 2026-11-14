// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReviewDtoTargetTypeEnum _$reviewDtoTargetTypeEnum_VENDOR_FULFILLMENT =
    const ReviewDtoTargetTypeEnum._('VENDOR_FULFILLMENT');
const ReviewDtoTargetTypeEnum _$reviewDtoTargetTypeEnum_DELIVERY_GROUP =
    const ReviewDtoTargetTypeEnum._('DELIVERY_GROUP');

ReviewDtoTargetTypeEnum _$reviewDtoTargetTypeEnumValueOf(String name) {
  switch (name) {
    case 'VENDOR_FULFILLMENT':
      return _$reviewDtoTargetTypeEnum_VENDOR_FULFILLMENT;
    case 'DELIVERY_GROUP':
      return _$reviewDtoTargetTypeEnum_DELIVERY_GROUP;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ReviewDtoTargetTypeEnum> _$reviewDtoTargetTypeEnumValues =
    BuiltSet<ReviewDtoTargetTypeEnum>(const <ReviewDtoTargetTypeEnum>[
      _$reviewDtoTargetTypeEnum_VENDOR_FULFILLMENT,
      _$reviewDtoTargetTypeEnum_DELIVERY_GROUP,
    ]);

Serializer<ReviewDtoTargetTypeEnum> _$reviewDtoTargetTypeEnumSerializer =
    _$ReviewDtoTargetTypeEnumSerializer();

class _$ReviewDtoTargetTypeEnumSerializer
    implements PrimitiveSerializer<ReviewDtoTargetTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'VENDOR_FULFILLMENT': 'VENDOR_FULFILLMENT',
    'DELIVERY_GROUP': 'DELIVERY_GROUP',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'VENDOR_FULFILLMENT': 'VENDOR_FULFILLMENT',
    'DELIVERY_GROUP': 'DELIVERY_GROUP',
  };

  @override
  final Iterable<Type> types = const <Type>[ReviewDtoTargetTypeEnum];
  @override
  final String wireName = 'ReviewDtoTargetTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    ReviewDtoTargetTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ReviewDtoTargetTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ReviewDtoTargetTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ReviewDto extends ReviewDto {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final String customerId;
  @override
  final ReviewDtoTargetTypeEnum targetType;
  @override
  final JsonObject? fulfillmentId;
  @override
  final JsonObject? deliveryGroupId;
  @override
  final JsonObject? vendorId;
  @override
  final JsonObject? driverId;
  @override
  final num rating;
  @override
  final num? vendorRating;
  @override
  final num? driverRating;
  @override
  final JsonObject? comment;
  @override
  final DateTime createdAt;
  @override
  final ReviewCustomerDto? customer;

  factory _$ReviewDto([void Function(ReviewDtoBuilder)? updates]) =>
      (ReviewDtoBuilder()..update(updates))._build();

  _$ReviewDto._({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.targetType,
    this.fulfillmentId,
    this.deliveryGroupId,
    this.vendorId,
    this.driverId,
    required this.rating,
    this.vendorRating,
    this.driverRating,
    this.comment,
    required this.createdAt,
    this.customer,
  }) : super._();
  @override
  ReviewDto rebuild(void Function(ReviewDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReviewDtoBuilder toBuilder() => ReviewDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewDto &&
        id == other.id &&
        orderId == other.orderId &&
        customerId == other.customerId &&
        targetType == other.targetType &&
        fulfillmentId == other.fulfillmentId &&
        deliveryGroupId == other.deliveryGroupId &&
        vendorId == other.vendorId &&
        driverId == other.driverId &&
        rating == other.rating &&
        vendorRating == other.vendorRating &&
        driverRating == other.driverRating &&
        comment == other.comment &&
        createdAt == other.createdAt &&
        customer == other.customer;
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
    _$hash = $jc(_$hash, vendorRating.hashCode);
    _$hash = $jc(_$hash, driverRating.hashCode);
    _$hash = $jc(_$hash, comment.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReviewDto')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('customerId', customerId)
          ..add('targetType', targetType)
          ..add('fulfillmentId', fulfillmentId)
          ..add('deliveryGroupId', deliveryGroupId)
          ..add('vendorId', vendorId)
          ..add('driverId', driverId)
          ..add('rating', rating)
          ..add('vendorRating', vendorRating)
          ..add('driverRating', driverRating)
          ..add('comment', comment)
          ..add('createdAt', createdAt)
          ..add('customer', customer))
        .toString();
  }
}

class ReviewDtoBuilder implements Builder<ReviewDto, ReviewDtoBuilder> {
  _$ReviewDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  ReviewDtoTargetTypeEnum? _targetType;
  ReviewDtoTargetTypeEnum? get targetType => _$this._targetType;
  set targetType(ReviewDtoTargetTypeEnum? targetType) =>
      _$this._targetType = targetType;

  JsonObject? _fulfillmentId;
  JsonObject? get fulfillmentId => _$this._fulfillmentId;
  set fulfillmentId(JsonObject? fulfillmentId) =>
      _$this._fulfillmentId = fulfillmentId;

  JsonObject? _deliveryGroupId;
  JsonObject? get deliveryGroupId => _$this._deliveryGroupId;
  set deliveryGroupId(JsonObject? deliveryGroupId) =>
      _$this._deliveryGroupId = deliveryGroupId;

  JsonObject? _vendorId;
  JsonObject? get vendorId => _$this._vendorId;
  set vendorId(JsonObject? vendorId) => _$this._vendorId = vendorId;

  JsonObject? _driverId;
  JsonObject? get driverId => _$this._driverId;
  set driverId(JsonObject? driverId) => _$this._driverId = driverId;

  num? _rating;
  num? get rating => _$this._rating;
  set rating(num? rating) => _$this._rating = rating;

  num? _vendorRating;
  num? get vendorRating => _$this._vendorRating;
  set vendorRating(num? vendorRating) => _$this._vendorRating = vendorRating;

  num? _driverRating;
  num? get driverRating => _$this._driverRating;
  set driverRating(num? driverRating) => _$this._driverRating = driverRating;

  JsonObject? _comment;
  JsonObject? get comment => _$this._comment;
  set comment(JsonObject? comment) => _$this._comment = comment;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  ReviewCustomerDtoBuilder? _customer;
  ReviewCustomerDtoBuilder get customer =>
      _$this._customer ??= ReviewCustomerDtoBuilder();
  set customer(ReviewCustomerDtoBuilder? customer) =>
      _$this._customer = customer;

  ReviewDtoBuilder() {
    ReviewDto._defaults(this);
  }

  ReviewDtoBuilder get _$this {
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
      _vendorRating = $v.vendorRating;
      _driverRating = $v.driverRating;
      _comment = $v.comment;
      _createdAt = $v.createdAt;
      _customer = $v.customer?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewDto other) {
    _$v = other as _$ReviewDto;
  }

  @override
  void update(void Function(ReviewDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewDto build() => _build();

  _$ReviewDto _build() {
    _$ReviewDto _$result;
    try {
      _$result =
          _$v ??
          _$ReviewDto._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'ReviewDto', 'id'),
            orderId: BuiltValueNullFieldError.checkNotNull(
              orderId,
              r'ReviewDto',
              'orderId',
            ),
            customerId: BuiltValueNullFieldError.checkNotNull(
              customerId,
              r'ReviewDto',
              'customerId',
            ),
            targetType: BuiltValueNullFieldError.checkNotNull(
              targetType,
              r'ReviewDto',
              'targetType',
            ),
            fulfillmentId: fulfillmentId,
            deliveryGroupId: deliveryGroupId,
            vendorId: vendorId,
            driverId: driverId,
            rating: BuiltValueNullFieldError.checkNotNull(
              rating,
              r'ReviewDto',
              'rating',
            ),
            vendorRating: vendorRating,
            driverRating: driverRating,
            comment: comment,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'ReviewDto',
              'createdAt',
            ),
            customer: _customer?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'customer';
        _customer?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ReviewDto',
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
