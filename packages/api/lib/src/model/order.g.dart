// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Order extends Order {
  @override
  final String id;
  @override
  final String orderNumber;
  @override
  final String? clientOrderKey;
  @override
  final OrderType type;
  @override
  final String customerId;
  @override
  final String? vendorId;
  @override
  final String? vendorBranchId;
  @override
  final String? driverId;
  @override
  final String? zoneId;
  @override
  final OrderStatus status;
  @override
  final num revision;
  @override
  final PaymentMethod paymentMethod;
  @override
  final PaymentStatus paymentStatus;
  @override
  final String deliveryAddress;
  @override
  final String? pickupAddress;
  @override
  final String? itemDetails;
  @override
  final VehicleType? requestedVehicleType;
  @override
  final num subtotal;
  @override
  final num deliveryFee;
  @override
  final num driverBonusFee;
  @override
  final num serviceFee;
  @override
  final num tax;
  @override
  final num discount;
  @override
  final num coinsUsed;
  @override
  final num coinsEarned;
  @override
  final num grandTotal;
  @override
  final num upfrontAmount;
  @override
  final String? specialRequest;
  @override
  final num? distanceKm;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? paymentReceiptUrl;
  @override
  final DateTime? actualDeliveryTime;
  @override
  final DateTime? settledAt;
  @override
  final String? cancelledByUserId;
  @override
  final Role? cancelledByRole;
  @override
  final String? cancelledByName;
  @override
  final String? cancelledByNameAr;
  @override
  final String? cancelledByAvatar;
  @override
  final String? cancelReason;
  @override
  final DateTime? cancelledAt;

  factory _$Order([void Function(OrderBuilder)? updates]) =>
      (OrderBuilder()..update(updates))._build();

  _$Order._({
    required this.id,
    required this.orderNumber,
    this.clientOrderKey,
    required this.type,
    required this.customerId,
    this.vendorId,
    this.vendorBranchId,
    this.driverId,
    this.zoneId,
    required this.status,
    required this.revision,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.pickupAddress,
    this.itemDetails,
    this.requestedVehicleType,
    required this.subtotal,
    required this.deliveryFee,
    required this.driverBonusFee,
    required this.serviceFee,
    required this.tax,
    required this.discount,
    required this.coinsUsed,
    required this.coinsEarned,
    required this.grandTotal,
    required this.upfrontAmount,
    this.specialRequest,
    this.distanceKm,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.paymentReceiptUrl,
    this.actualDeliveryTime,
    this.settledAt,
    this.cancelledByUserId,
    this.cancelledByRole,
    this.cancelledByName,
    this.cancelledByNameAr,
    this.cancelledByAvatar,
    this.cancelReason,
    this.cancelledAt,
  }) : super._();
  @override
  Order rebuild(void Function(OrderBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrderBuilder toBuilder() => OrderBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Order &&
        id == other.id &&
        orderNumber == other.orderNumber &&
        clientOrderKey == other.clientOrderKey &&
        type == other.type &&
        customerId == other.customerId &&
        vendorId == other.vendorId &&
        vendorBranchId == other.vendorBranchId &&
        driverId == other.driverId &&
        zoneId == other.zoneId &&
        status == other.status &&
        revision == other.revision &&
        paymentMethod == other.paymentMethod &&
        paymentStatus == other.paymentStatus &&
        deliveryAddress == other.deliveryAddress &&
        pickupAddress == other.pickupAddress &&
        itemDetails == other.itemDetails &&
        requestedVehicleType == other.requestedVehicleType &&
        subtotal == other.subtotal &&
        deliveryFee == other.deliveryFee &&
        driverBonusFee == other.driverBonusFee &&
        serviceFee == other.serviceFee &&
        tax == other.tax &&
        discount == other.discount &&
        coinsUsed == other.coinsUsed &&
        coinsEarned == other.coinsEarned &&
        grandTotal == other.grandTotal &&
        upfrontAmount == other.upfrontAmount &&
        specialRequest == other.specialRequest &&
        distanceKm == other.distanceKm &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        paymentReceiptUrl == other.paymentReceiptUrl &&
        actualDeliveryTime == other.actualDeliveryTime &&
        settledAt == other.settledAt &&
        cancelledByUserId == other.cancelledByUserId &&
        cancelledByRole == other.cancelledByRole &&
        cancelledByName == other.cancelledByName &&
        cancelledByNameAr == other.cancelledByNameAr &&
        cancelledByAvatar == other.cancelledByAvatar &&
        cancelReason == other.cancelReason &&
        cancelledAt == other.cancelledAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderNumber.hashCode);
    _$hash = $jc(_$hash, clientOrderKey.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, customerId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, vendorBranchId.hashCode);
    _$hash = $jc(_$hash, driverId.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, revision.hashCode);
    _$hash = $jc(_$hash, paymentMethod.hashCode);
    _$hash = $jc(_$hash, paymentStatus.hashCode);
    _$hash = $jc(_$hash, deliveryAddress.hashCode);
    _$hash = $jc(_$hash, pickupAddress.hashCode);
    _$hash = $jc(_$hash, itemDetails.hashCode);
    _$hash = $jc(_$hash, requestedVehicleType.hashCode);
    _$hash = $jc(_$hash, subtotal.hashCode);
    _$hash = $jc(_$hash, deliveryFee.hashCode);
    _$hash = $jc(_$hash, driverBonusFee.hashCode);
    _$hash = $jc(_$hash, serviceFee.hashCode);
    _$hash = $jc(_$hash, tax.hashCode);
    _$hash = $jc(_$hash, discount.hashCode);
    _$hash = $jc(_$hash, coinsUsed.hashCode);
    _$hash = $jc(_$hash, coinsEarned.hashCode);
    _$hash = $jc(_$hash, grandTotal.hashCode);
    _$hash = $jc(_$hash, upfrontAmount.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jc(_$hash, distanceKm.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, paymentReceiptUrl.hashCode);
    _$hash = $jc(_$hash, actualDeliveryTime.hashCode);
    _$hash = $jc(_$hash, settledAt.hashCode);
    _$hash = $jc(_$hash, cancelledByUserId.hashCode);
    _$hash = $jc(_$hash, cancelledByRole.hashCode);
    _$hash = $jc(_$hash, cancelledByName.hashCode);
    _$hash = $jc(_$hash, cancelledByNameAr.hashCode);
    _$hash = $jc(_$hash, cancelledByAvatar.hashCode);
    _$hash = $jc(_$hash, cancelReason.hashCode);
    _$hash = $jc(_$hash, cancelledAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Order')
          ..add('id', id)
          ..add('orderNumber', orderNumber)
          ..add('clientOrderKey', clientOrderKey)
          ..add('type', type)
          ..add('customerId', customerId)
          ..add('vendorId', vendorId)
          ..add('vendorBranchId', vendorBranchId)
          ..add('driverId', driverId)
          ..add('zoneId', zoneId)
          ..add('status', status)
          ..add('revision', revision)
          ..add('paymentMethod', paymentMethod)
          ..add('paymentStatus', paymentStatus)
          ..add('deliveryAddress', deliveryAddress)
          ..add('pickupAddress', pickupAddress)
          ..add('itemDetails', itemDetails)
          ..add('requestedVehicleType', requestedVehicleType)
          ..add('subtotal', subtotal)
          ..add('deliveryFee', deliveryFee)
          ..add('driverBonusFee', driverBonusFee)
          ..add('serviceFee', serviceFee)
          ..add('tax', tax)
          ..add('discount', discount)
          ..add('coinsUsed', coinsUsed)
          ..add('coinsEarned', coinsEarned)
          ..add('grandTotal', grandTotal)
          ..add('upfrontAmount', upfrontAmount)
          ..add('specialRequest', specialRequest)
          ..add('distanceKm', distanceKm)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('paymentReceiptUrl', paymentReceiptUrl)
          ..add('actualDeliveryTime', actualDeliveryTime)
          ..add('settledAt', settledAt)
          ..add('cancelledByUserId', cancelledByUserId)
          ..add('cancelledByRole', cancelledByRole)
          ..add('cancelledByName', cancelledByName)
          ..add('cancelledByNameAr', cancelledByNameAr)
          ..add('cancelledByAvatar', cancelledByAvatar)
          ..add('cancelReason', cancelReason)
          ..add('cancelledAt', cancelledAt))
        .toString();
  }
}

class OrderBuilder implements Builder<Order, OrderBuilder> {
  _$Order? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderNumber;
  String? get orderNumber => _$this._orderNumber;
  set orderNumber(String? orderNumber) => _$this._orderNumber = orderNumber;

  String? _clientOrderKey;
  String? get clientOrderKey => _$this._clientOrderKey;
  set clientOrderKey(String? clientOrderKey) =>
      _$this._clientOrderKey = clientOrderKey;

  OrderType? _type;
  OrderType? get type => _$this._type;
  set type(OrderType? type) => _$this._type = type;

  String? _customerId;
  String? get customerId => _$this._customerId;
  set customerId(String? customerId) => _$this._customerId = customerId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _vendorBranchId;
  String? get vendorBranchId => _$this._vendorBranchId;
  set vendorBranchId(String? vendorBranchId) =>
      _$this._vendorBranchId = vendorBranchId;

  String? _driverId;
  String? get driverId => _$this._driverId;
  set driverId(String? driverId) => _$this._driverId = driverId;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  OrderStatus? _status;
  OrderStatus? get status => _$this._status;
  set status(OrderStatus? status) => _$this._status = status;

  num? _revision;
  num? get revision => _$this._revision;
  set revision(num? revision) => _$this._revision = revision;

  PaymentMethod? _paymentMethod;
  PaymentMethod? get paymentMethod => _$this._paymentMethod;
  set paymentMethod(PaymentMethod? paymentMethod) =>
      _$this._paymentMethod = paymentMethod;

  PaymentStatus? _paymentStatus;
  PaymentStatus? get paymentStatus => _$this._paymentStatus;
  set paymentStatus(PaymentStatus? paymentStatus) =>
      _$this._paymentStatus = paymentStatus;

  String? _deliveryAddress;
  String? get deliveryAddress => _$this._deliveryAddress;
  set deliveryAddress(String? deliveryAddress) =>
      _$this._deliveryAddress = deliveryAddress;

  String? _pickupAddress;
  String? get pickupAddress => _$this._pickupAddress;
  set pickupAddress(String? pickupAddress) =>
      _$this._pickupAddress = pickupAddress;

  String? _itemDetails;
  String? get itemDetails => _$this._itemDetails;
  set itemDetails(String? itemDetails) => _$this._itemDetails = itemDetails;

  VehicleType? _requestedVehicleType;
  VehicleType? get requestedVehicleType => _$this._requestedVehicleType;
  set requestedVehicleType(VehicleType? requestedVehicleType) =>
      _$this._requestedVehicleType = requestedVehicleType;

  num? _subtotal;
  num? get subtotal => _$this._subtotal;
  set subtotal(num? subtotal) => _$this._subtotal = subtotal;

  num? _deliveryFee;
  num? get deliveryFee => _$this._deliveryFee;
  set deliveryFee(num? deliveryFee) => _$this._deliveryFee = deliveryFee;

  num? _driverBonusFee;
  num? get driverBonusFee => _$this._driverBonusFee;
  set driverBonusFee(num? driverBonusFee) =>
      _$this._driverBonusFee = driverBonusFee;

  num? _serviceFee;
  num? get serviceFee => _$this._serviceFee;
  set serviceFee(num? serviceFee) => _$this._serviceFee = serviceFee;

  num? _tax;
  num? get tax => _$this._tax;
  set tax(num? tax) => _$this._tax = tax;

  num? _discount;
  num? get discount => _$this._discount;
  set discount(num? discount) => _$this._discount = discount;

  num? _coinsUsed;
  num? get coinsUsed => _$this._coinsUsed;
  set coinsUsed(num? coinsUsed) => _$this._coinsUsed = coinsUsed;

  num? _coinsEarned;
  num? get coinsEarned => _$this._coinsEarned;
  set coinsEarned(num? coinsEarned) => _$this._coinsEarned = coinsEarned;

  num? _grandTotal;
  num? get grandTotal => _$this._grandTotal;
  set grandTotal(num? grandTotal) => _$this._grandTotal = grandTotal;

  num? _upfrontAmount;
  num? get upfrontAmount => _$this._upfrontAmount;
  set upfrontAmount(num? upfrontAmount) =>
      _$this._upfrontAmount = upfrontAmount;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  num? _distanceKm;
  num? get distanceKm => _$this._distanceKm;
  set distanceKm(num? distanceKm) => _$this._distanceKm = distanceKm;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  String? _paymentReceiptUrl;
  String? get paymentReceiptUrl => _$this._paymentReceiptUrl;
  set paymentReceiptUrl(String? paymentReceiptUrl) =>
      _$this._paymentReceiptUrl = paymentReceiptUrl;

  DateTime? _actualDeliveryTime;
  DateTime? get actualDeliveryTime => _$this._actualDeliveryTime;
  set actualDeliveryTime(DateTime? actualDeliveryTime) =>
      _$this._actualDeliveryTime = actualDeliveryTime;

  DateTime? _settledAt;
  DateTime? get settledAt => _$this._settledAt;
  set settledAt(DateTime? settledAt) => _$this._settledAt = settledAt;

  String? _cancelledByUserId;
  String? get cancelledByUserId => _$this._cancelledByUserId;
  set cancelledByUserId(String? cancelledByUserId) =>
      _$this._cancelledByUserId = cancelledByUserId;

  Role? _cancelledByRole;
  Role? get cancelledByRole => _$this._cancelledByRole;
  set cancelledByRole(Role? cancelledByRole) =>
      _$this._cancelledByRole = cancelledByRole;

  String? _cancelledByName;
  String? get cancelledByName => _$this._cancelledByName;
  set cancelledByName(String? cancelledByName) =>
      _$this._cancelledByName = cancelledByName;

  String? _cancelledByNameAr;
  String? get cancelledByNameAr => _$this._cancelledByNameAr;
  set cancelledByNameAr(String? cancelledByNameAr) =>
      _$this._cancelledByNameAr = cancelledByNameAr;

  String? _cancelledByAvatar;
  String? get cancelledByAvatar => _$this._cancelledByAvatar;
  set cancelledByAvatar(String? cancelledByAvatar) =>
      _$this._cancelledByAvatar = cancelledByAvatar;

  String? _cancelReason;
  String? get cancelReason => _$this._cancelReason;
  set cancelReason(String? cancelReason) => _$this._cancelReason = cancelReason;

  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _$this._cancelledAt;
  set cancelledAt(DateTime? cancelledAt) => _$this._cancelledAt = cancelledAt;

  OrderBuilder() {
    Order._defaults(this);
  }

  OrderBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderNumber = $v.orderNumber;
      _clientOrderKey = $v.clientOrderKey;
      _type = $v.type;
      _customerId = $v.customerId;
      _vendorId = $v.vendorId;
      _vendorBranchId = $v.vendorBranchId;
      _driverId = $v.driverId;
      _zoneId = $v.zoneId;
      _status = $v.status;
      _revision = $v.revision;
      _paymentMethod = $v.paymentMethod;
      _paymentStatus = $v.paymentStatus;
      _deliveryAddress = $v.deliveryAddress;
      _pickupAddress = $v.pickupAddress;
      _itemDetails = $v.itemDetails;
      _requestedVehicleType = $v.requestedVehicleType;
      _subtotal = $v.subtotal;
      _deliveryFee = $v.deliveryFee;
      _driverBonusFee = $v.driverBonusFee;
      _serviceFee = $v.serviceFee;
      _tax = $v.tax;
      _discount = $v.discount;
      _coinsUsed = $v.coinsUsed;
      _coinsEarned = $v.coinsEarned;
      _grandTotal = $v.grandTotal;
      _upfrontAmount = $v.upfrontAmount;
      _specialRequest = $v.specialRequest;
      _distanceKm = $v.distanceKm;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _paymentReceiptUrl = $v.paymentReceiptUrl;
      _actualDeliveryTime = $v.actualDeliveryTime;
      _settledAt = $v.settledAt;
      _cancelledByUserId = $v.cancelledByUserId;
      _cancelledByRole = $v.cancelledByRole;
      _cancelledByName = $v.cancelledByName;
      _cancelledByNameAr = $v.cancelledByNameAr;
      _cancelledByAvatar = $v.cancelledByAvatar;
      _cancelReason = $v.cancelReason;
      _cancelledAt = $v.cancelledAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Order other) {
    _$v = other as _$Order;
  }

  @override
  void update(void Function(OrderBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Order build() => _build();

  _$Order _build() {
    final _$result =
        _$v ??
        _$Order._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Order', 'id'),
          orderNumber: BuiltValueNullFieldError.checkNotNull(
            orderNumber,
            r'Order',
            'orderNumber',
          ),
          clientOrderKey: clientOrderKey,
          type: BuiltValueNullFieldError.checkNotNull(type, r'Order', 'type'),
          customerId: BuiltValueNullFieldError.checkNotNull(
            customerId,
            r'Order',
            'customerId',
          ),
          vendorId: vendorId,
          vendorBranchId: vendorBranchId,
          driverId: driverId,
          zoneId: zoneId,
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'Order',
            'status',
          ),
          revision: BuiltValueNullFieldError.checkNotNull(
            revision,
            r'Order',
            'revision',
          ),
          paymentMethod: BuiltValueNullFieldError.checkNotNull(
            paymentMethod,
            r'Order',
            'paymentMethod',
          ),
          paymentStatus: BuiltValueNullFieldError.checkNotNull(
            paymentStatus,
            r'Order',
            'paymentStatus',
          ),
          deliveryAddress: BuiltValueNullFieldError.checkNotNull(
            deliveryAddress,
            r'Order',
            'deliveryAddress',
          ),
          pickupAddress: pickupAddress,
          itemDetails: itemDetails,
          requestedVehicleType: requestedVehicleType,
          subtotal: BuiltValueNullFieldError.checkNotNull(
            subtotal,
            r'Order',
            'subtotal',
          ),
          deliveryFee: BuiltValueNullFieldError.checkNotNull(
            deliveryFee,
            r'Order',
            'deliveryFee',
          ),
          driverBonusFee: BuiltValueNullFieldError.checkNotNull(
            driverBonusFee,
            r'Order',
            'driverBonusFee',
          ),
          serviceFee: BuiltValueNullFieldError.checkNotNull(
            serviceFee,
            r'Order',
            'serviceFee',
          ),
          tax: BuiltValueNullFieldError.checkNotNull(tax, r'Order', 'tax'),
          discount: BuiltValueNullFieldError.checkNotNull(
            discount,
            r'Order',
            'discount',
          ),
          coinsUsed: BuiltValueNullFieldError.checkNotNull(
            coinsUsed,
            r'Order',
            'coinsUsed',
          ),
          coinsEarned: BuiltValueNullFieldError.checkNotNull(
            coinsEarned,
            r'Order',
            'coinsEarned',
          ),
          grandTotal: BuiltValueNullFieldError.checkNotNull(
            grandTotal,
            r'Order',
            'grandTotal',
          ),
          upfrontAmount: BuiltValueNullFieldError.checkNotNull(
            upfrontAmount,
            r'Order',
            'upfrontAmount',
          ),
          specialRequest: specialRequest,
          distanceKm: distanceKm,
          deletedAt: deletedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Order',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Order',
            'updatedAt',
          ),
          paymentReceiptUrl: paymentReceiptUrl,
          actualDeliveryTime: actualDeliveryTime,
          settledAt: settledAt,
          cancelledByUserId: cancelledByUserId,
          cancelledByRole: cancelledByRole,
          cancelledByName: cancelledByName,
          cancelledByNameAr: cancelledByNameAr,
          cancelledByAvatar: cancelledByAvatar,
          cancelReason: cancelReason,
          cancelledAt: cancelledAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
