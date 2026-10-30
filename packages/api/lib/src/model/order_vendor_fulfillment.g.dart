// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_vendor_fulfillment.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderVendorFulfillment extends OrderVendorFulfillment {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final String vendorId;
  @override
  final String? vendorBranchId;
  @override
  final OrderVendorFulfillmentStatus status;
  @override
  final String? stage;
  @override
  final num subtotal;
  @override
  final num commissionRate;
  @override
  final String? rejectionCode;
  @override
  final String? rejectionReason;
  @override
  final String? rejectionReasonAr;
  @override
  final DateTime? preparingAt;
  @override
  final DateTime? readyAt;
  @override
  final String? pickupImageUrl;
  @override
  final DateTime? pickedUpAt;
  @override
  final DateTime? deliveredAt;
  @override
  final Vendor? vendor;
  @override
  final VendorBranch? vendorBranch;
  @override
  final BuiltList<OrderItem>? items;

  factory _$OrderVendorFulfillment([
    void Function(OrderVendorFulfillmentBuilder)? updates,
  ]) => (OrderVendorFulfillmentBuilder()..update(updates))._build();

  _$OrderVendorFulfillment._({
    required this.id,
    required this.orderId,
    required this.vendorId,
    this.vendorBranchId,
    required this.status,
    this.stage,
    required this.subtotal,
    required this.commissionRate,
    this.rejectionCode,
    this.rejectionReason,
    this.rejectionReasonAr,
    this.preparingAt,
    this.readyAt,
    this.pickupImageUrl,
    this.pickedUpAt,
    this.deliveredAt,
    this.vendor,
    this.vendorBranch,
    this.items,
  }) : super._();
  @override
  OrderVendorFulfillment rebuild(
    void Function(OrderVendorFulfillmentBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderVendorFulfillmentBuilder toBuilder() =>
      OrderVendorFulfillmentBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderVendorFulfillment &&
        id == other.id &&
        orderId == other.orderId &&
        vendorId == other.vendorId &&
        vendorBranchId == other.vendorBranchId &&
        status == other.status &&
        stage == other.stage &&
        subtotal == other.subtotal &&
        commissionRate == other.commissionRate &&
        rejectionCode == other.rejectionCode &&
        rejectionReason == other.rejectionReason &&
        rejectionReasonAr == other.rejectionReasonAr &&
        preparingAt == other.preparingAt &&
        readyAt == other.readyAt &&
        pickupImageUrl == other.pickupImageUrl &&
        pickedUpAt == other.pickedUpAt &&
        deliveredAt == other.deliveredAt &&
        vendor == other.vendor &&
        vendorBranch == other.vendorBranch &&
        items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, vendorBranchId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, stage.hashCode);
    _$hash = $jc(_$hash, subtotal.hashCode);
    _$hash = $jc(_$hash, commissionRate.hashCode);
    _$hash = $jc(_$hash, rejectionCode.hashCode);
    _$hash = $jc(_$hash, rejectionReason.hashCode);
    _$hash = $jc(_$hash, rejectionReasonAr.hashCode);
    _$hash = $jc(_$hash, preparingAt.hashCode);
    _$hash = $jc(_$hash, readyAt.hashCode);
    _$hash = $jc(_$hash, pickupImageUrl.hashCode);
    _$hash = $jc(_$hash, pickedUpAt.hashCode);
    _$hash = $jc(_$hash, deliveredAt.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jc(_$hash, vendorBranch.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderVendorFulfillment')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('vendorId', vendorId)
          ..add('vendorBranchId', vendorBranchId)
          ..add('status', status)
          ..add('stage', stage)
          ..add('subtotal', subtotal)
          ..add('commissionRate', commissionRate)
          ..add('rejectionCode', rejectionCode)
          ..add('rejectionReason', rejectionReason)
          ..add('rejectionReasonAr', rejectionReasonAr)
          ..add('preparingAt', preparingAt)
          ..add('readyAt', readyAt)
          ..add('pickupImageUrl', pickupImageUrl)
          ..add('pickedUpAt', pickedUpAt)
          ..add('deliveredAt', deliveredAt)
          ..add('vendor', vendor)
          ..add('vendorBranch', vendorBranch)
          ..add('items', items))
        .toString();
  }
}

class OrderVendorFulfillmentBuilder
    implements Builder<OrderVendorFulfillment, OrderVendorFulfillmentBuilder> {
  _$OrderVendorFulfillment? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _vendorBranchId;
  String? get vendorBranchId => _$this._vendorBranchId;
  set vendorBranchId(String? vendorBranchId) =>
      _$this._vendorBranchId = vendorBranchId;

  OrderVendorFulfillmentStatus? _status;
  OrderVendorFulfillmentStatus? get status => _$this._status;
  set status(OrderVendorFulfillmentStatus? status) => _$this._status = status;

  String? _stage;
  String? get stage => _$this._stage;
  set stage(String? stage) => _$this._stage = stage;

  num? _subtotal;
  num? get subtotal => _$this._subtotal;
  set subtotal(num? subtotal) => _$this._subtotal = subtotal;

  num? _commissionRate;
  num? get commissionRate => _$this._commissionRate;
  set commissionRate(num? commissionRate) =>
      _$this._commissionRate = commissionRate;

  String? _rejectionCode;
  String? get rejectionCode => _$this._rejectionCode;
  set rejectionCode(String? rejectionCode) =>
      _$this._rejectionCode = rejectionCode;

  String? _rejectionReason;
  String? get rejectionReason => _$this._rejectionReason;
  set rejectionReason(String? rejectionReason) =>
      _$this._rejectionReason = rejectionReason;

  String? _rejectionReasonAr;
  String? get rejectionReasonAr => _$this._rejectionReasonAr;
  set rejectionReasonAr(String? rejectionReasonAr) =>
      _$this._rejectionReasonAr = rejectionReasonAr;

  DateTime? _preparingAt;
  DateTime? get preparingAt => _$this._preparingAt;
  set preparingAt(DateTime? preparingAt) => _$this._preparingAt = preparingAt;

  DateTime? _readyAt;
  DateTime? get readyAt => _$this._readyAt;
  set readyAt(DateTime? readyAt) => _$this._readyAt = readyAt;

  String? _pickupImageUrl;
  String? get pickupImageUrl => _$this._pickupImageUrl;
  set pickupImageUrl(String? pickupImageUrl) =>
      _$this._pickupImageUrl = pickupImageUrl;

  DateTime? _pickedUpAt;
  DateTime? get pickedUpAt => _$this._pickedUpAt;
  set pickedUpAt(DateTime? pickedUpAt) => _$this._pickedUpAt = pickedUpAt;

  DateTime? _deliveredAt;
  DateTime? get deliveredAt => _$this._deliveredAt;
  set deliveredAt(DateTime? deliveredAt) => _$this._deliveredAt = deliveredAt;

  VendorBuilder? _vendor;
  VendorBuilder get vendor => _$this._vendor ??= VendorBuilder();
  set vendor(VendorBuilder? vendor) => _$this._vendor = vendor;

  VendorBranchBuilder? _vendorBranch;
  VendorBranchBuilder get vendorBranch =>
      _$this._vendorBranch ??= VendorBranchBuilder();
  set vendorBranch(VendorBranchBuilder? vendorBranch) =>
      _$this._vendorBranch = vendorBranch;

  ListBuilder<OrderItem>? _items;
  ListBuilder<OrderItem> get items =>
      _$this._items ??= ListBuilder<OrderItem>();
  set items(ListBuilder<OrderItem>? items) => _$this._items = items;

  OrderVendorFulfillmentBuilder() {
    OrderVendorFulfillment._defaults(this);
  }

  OrderVendorFulfillmentBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _vendorId = $v.vendorId;
      _vendorBranchId = $v.vendorBranchId;
      _status = $v.status;
      _stage = $v.stage;
      _subtotal = $v.subtotal;
      _commissionRate = $v.commissionRate;
      _rejectionCode = $v.rejectionCode;
      _rejectionReason = $v.rejectionReason;
      _rejectionReasonAr = $v.rejectionReasonAr;
      _preparingAt = $v.preparingAt;
      _readyAt = $v.readyAt;
      _pickupImageUrl = $v.pickupImageUrl;
      _pickedUpAt = $v.pickedUpAt;
      _deliveredAt = $v.deliveredAt;
      _vendor = $v.vendor?.toBuilder();
      _vendorBranch = $v.vendorBranch?.toBuilder();
      _items = $v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderVendorFulfillment other) {
    _$v = other as _$OrderVendorFulfillment;
  }

  @override
  void update(void Function(OrderVendorFulfillmentBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderVendorFulfillment build() => _build();

  _$OrderVendorFulfillment _build() {
    _$OrderVendorFulfillment _$result;
    try {
      _$result =
          _$v ??
          _$OrderVendorFulfillment._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'OrderVendorFulfillment',
              'id',
            ),
            orderId: BuiltValueNullFieldError.checkNotNull(
              orderId,
              r'OrderVendorFulfillment',
              'orderId',
            ),
            vendorId: BuiltValueNullFieldError.checkNotNull(
              vendorId,
              r'OrderVendorFulfillment',
              'vendorId',
            ),
            vendorBranchId: vendorBranchId,
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'OrderVendorFulfillment',
              'status',
            ),
            stage: stage,
            subtotal: BuiltValueNullFieldError.checkNotNull(
              subtotal,
              r'OrderVendorFulfillment',
              'subtotal',
            ),
            commissionRate: BuiltValueNullFieldError.checkNotNull(
              commissionRate,
              r'OrderVendorFulfillment',
              'commissionRate',
            ),
            rejectionCode: rejectionCode,
            rejectionReason: rejectionReason,
            rejectionReasonAr: rejectionReasonAr,
            preparingAt: preparingAt,
            readyAt: readyAt,
            pickupImageUrl: pickupImageUrl,
            pickedUpAt: pickedUpAt,
            deliveredAt: deliveredAt,
            vendor: _vendor?.build(),
            vendorBranch: _vendorBranch?.build(),
            items: _items?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vendor';
        _vendor?.build();
        _$failedField = 'vendorBranch';
        _vendorBranch?.build();
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderVendorFulfillment',
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
