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
  final String? driverShiftId;
  @override
  final OrderStatus status;
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
  final num? estimatedPrepTime;
  @override
  final num? distanceKm;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? acceptedAt;
  @override
  final DateTime? preparedAt;
  @override
  final DateTime? driverAssignedAt;
  @override
  final DateTime? pickedUpAt;
  @override
  final String? pickupImageUrl;
  @override
  final String? deliveryImageUrl;
  @override
  final String? paymentReceiptUrl;
  @override
  final DateTime? actualDeliveryTime;

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
    this.driverShiftId,
    required this.status,
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
    this.estimatedPrepTime,
    this.distanceKm,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.preparedAt,
    this.driverAssignedAt,
    this.pickedUpAt,
    this.pickupImageUrl,
    this.deliveryImageUrl,
    this.paymentReceiptUrl,
    this.actualDeliveryTime,
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
        driverShiftId == other.driverShiftId &&
        status == other.status &&
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
        estimatedPrepTime == other.estimatedPrepTime &&
        distanceKm == other.distanceKm &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        acceptedAt == other.acceptedAt &&
        preparedAt == other.preparedAt &&
        driverAssignedAt == other.driverAssignedAt &&
        pickedUpAt == other.pickedUpAt &&
        pickupImageUrl == other.pickupImageUrl &&
        deliveryImageUrl == other.deliveryImageUrl &&
        paymentReceiptUrl == other.paymentReceiptUrl &&
        actualDeliveryTime == other.actualDeliveryTime;
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
    _$hash = $jc(_$hash, driverShiftId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
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
    _$hash = $jc(_$hash, estimatedPrepTime.hashCode);
    _$hash = $jc(_$hash, distanceKm.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, acceptedAt.hashCode);
    _$hash = $jc(_$hash, preparedAt.hashCode);
    _$hash = $jc(_$hash, driverAssignedAt.hashCode);
    _$hash = $jc(_$hash, pickedUpAt.hashCode);
    _$hash = $jc(_$hash, pickupImageUrl.hashCode);
    _$hash = $jc(_$hash, deliveryImageUrl.hashCode);
    _$hash = $jc(_$hash, paymentReceiptUrl.hashCode);
    _$hash = $jc(_$hash, actualDeliveryTime.hashCode);
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
          ..add('driverShiftId', driverShiftId)
          ..add('status', status)
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
          ..add('estimatedPrepTime', estimatedPrepTime)
          ..add('distanceKm', distanceKm)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('acceptedAt', acceptedAt)
          ..add('preparedAt', preparedAt)
          ..add('driverAssignedAt', driverAssignedAt)
          ..add('pickedUpAt', pickedUpAt)
          ..add('pickupImageUrl', pickupImageUrl)
          ..add('deliveryImageUrl', deliveryImageUrl)
          ..add('paymentReceiptUrl', paymentReceiptUrl)
          ..add('actualDeliveryTime', actualDeliveryTime))
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

  String? _driverShiftId;
  String? get driverShiftId => _$this._driverShiftId;
  set driverShiftId(String? driverShiftId) =>
      _$this._driverShiftId = driverShiftId;

  OrderStatus? _status;
  OrderStatus? get status => _$this._status;
  set status(OrderStatus? status) => _$this._status = status;

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

  num? _estimatedPrepTime;
  num? get estimatedPrepTime => _$this._estimatedPrepTime;
  set estimatedPrepTime(num? estimatedPrepTime) =>
      _$this._estimatedPrepTime = estimatedPrepTime;

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

  DateTime? _acceptedAt;
  DateTime? get acceptedAt => _$this._acceptedAt;
  set acceptedAt(DateTime? acceptedAt) => _$this._acceptedAt = acceptedAt;

  DateTime? _preparedAt;
  DateTime? get preparedAt => _$this._preparedAt;
  set preparedAt(DateTime? preparedAt) => _$this._preparedAt = preparedAt;

  DateTime? _driverAssignedAt;
  DateTime? get driverAssignedAt => _$this._driverAssignedAt;
  set driverAssignedAt(DateTime? driverAssignedAt) =>
      _$this._driverAssignedAt = driverAssignedAt;

  DateTime? _pickedUpAt;
  DateTime? get pickedUpAt => _$this._pickedUpAt;
  set pickedUpAt(DateTime? pickedUpAt) => _$this._pickedUpAt = pickedUpAt;

  String? _pickupImageUrl;
  String? get pickupImageUrl => _$this._pickupImageUrl;
  set pickupImageUrl(String? pickupImageUrl) =>
      _$this._pickupImageUrl = pickupImageUrl;

  String? _deliveryImageUrl;
  String? get deliveryImageUrl => _$this._deliveryImageUrl;
  set deliveryImageUrl(String? deliveryImageUrl) =>
      _$this._deliveryImageUrl = deliveryImageUrl;

  String? _paymentReceiptUrl;
  String? get paymentReceiptUrl => _$this._paymentReceiptUrl;
  set paymentReceiptUrl(String? paymentReceiptUrl) =>
      _$this._paymentReceiptUrl = paymentReceiptUrl;

  DateTime? _actualDeliveryTime;
  DateTime? get actualDeliveryTime => _$this._actualDeliveryTime;
  set actualDeliveryTime(DateTime? actualDeliveryTime) =>
      _$this._actualDeliveryTime = actualDeliveryTime;

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
      _driverShiftId = $v.driverShiftId;
      _status = $v.status;
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
      _estimatedPrepTime = $v.estimatedPrepTime;
      _distanceKm = $v.distanceKm;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _acceptedAt = $v.acceptedAt;
      _preparedAt = $v.preparedAt;
      _driverAssignedAt = $v.driverAssignedAt;
      _pickedUpAt = $v.pickedUpAt;
      _pickupImageUrl = $v.pickupImageUrl;
      _deliveryImageUrl = $v.deliveryImageUrl;
      _paymentReceiptUrl = $v.paymentReceiptUrl;
      _actualDeliveryTime = $v.actualDeliveryTime;
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
          driverShiftId: driverShiftId,
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'Order',
            'status',
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
          estimatedPrepTime: estimatedPrepTime,
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
          acceptedAt: acceptedAt,
          preparedAt: preparedAt,
          driverAssignedAt: driverAssignedAt,
          pickedUpAt: pickedUpAt,
          pickupImageUrl: pickupImageUrl,
          deliveryImageUrl: deliveryImageUrl,
          paymentReceiptUrl: paymentReceiptUrl,
          actualDeliveryTime: actualDeliveryTime,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
