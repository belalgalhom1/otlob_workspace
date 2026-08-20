// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReviewDto extends ReviewDto {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final String customerId;
  @override
  final String? vendorId;
  @override
  final String? driverId;
  @override
  final num? vendorRating;
  @override
  final num? driverRating;
  @override
  final String? comment;
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
    this.vendorId,
    this.driverId,
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
        vendorId == other.vendorId &&
        driverId == other.driverId &&
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
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
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
          ..add('vendorId', vendorId)
          ..add('driverId', driverId)
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

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  num? _vendorRating;
  num? get vendorRating => _$this._vendorRating;
  set vendorRating(num? vendorRating) => _$this._vendorRating = vendorRating;

  num? _driverRating;
  num? get driverRating => _$this._driverRating;
  set driverRating(num? driverRating) => _$this._driverRating = driverRating;

  String? _comment;
  String? get comment => _$this._comment;
  set comment(String? comment) => _$this._comment = comment;

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
      _vendorId = $v.vendorId;
      _driverId = $v.driverId;
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
            vendorId: vendorId,
            driverId: driverId,
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
