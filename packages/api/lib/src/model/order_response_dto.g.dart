// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderResponseDto extends OrderResponseDto {
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
  final num goldSurchargeAmount;
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
  final num settledGoldBonusAmount;
  @override
  final num settledGoldPlatformRetainedAmount;
  @override
  final num settledBronzeDriverDeduction;
  @override
  final num settledBronzeSupervisorDeduction;
  @override
  final num? settledBronzeDriverDeductionRate;
  @override
  final num? settledBronzeSupervisorDeductionRate;
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
  @override
  final BuiltList<DriverWalletTransaction>? driverTransactions;
  @override
  final BuiltList<OrderDispatch>? dispatches;
  @override
  final BuiltList<OrderItem>? items;
  @override
  final BuiltList<OrderStatusEvent>? statusEvents;
  @override
  final Customer? customer;
  @override
  final Driver? driver;
  @override
  final Vendor? vendor;
  @override
  final VendorBranch? vendorBranch;
  @override
  final Zone? zone;
  @override
  final BuiltList<SupportTicket>? supportTickets;
  @override
  final BuiltList<VendorWalletTransaction>? vendorTransactions;
  @override
  final BuiltList<OrderReview>? reviews;
  @override
  final BuiltList<OrderVendorFulfillment>? vendorFulfillments;
  @override
  final BuiltList<OrderDeliveryGroup>? deliveryGroups;
  @override
  final JsonObject? fulfillmentSummary;
  @override
  final OrderCancelledByDto? cancelledBy;

  factory _$OrderResponseDto([
    void Function(OrderResponseDtoBuilder)? updates,
  ]) => (OrderResponseDtoBuilder()..update(updates))._build();

  _$OrderResponseDto._({
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
    required this.goldSurchargeAmount,
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
    required this.settledGoldBonusAmount,
    required this.settledGoldPlatformRetainedAmount,
    required this.settledBronzeDriverDeduction,
    required this.settledBronzeSupervisorDeduction,
    this.settledBronzeDriverDeductionRate,
    this.settledBronzeSupervisorDeductionRate,
    this.cancelledByUserId,
    this.cancelledByRole,
    this.cancelledByName,
    this.cancelledByNameAr,
    this.cancelledByAvatar,
    this.cancelReason,
    this.cancelledAt,
    this.driverTransactions,
    this.dispatches,
    this.items,
    this.statusEvents,
    this.customer,
    this.driver,
    this.vendor,
    this.vendorBranch,
    this.zone,
    this.supportTickets,
    this.vendorTransactions,
    this.reviews,
    this.vendorFulfillments,
    this.deliveryGroups,
    this.fulfillmentSummary,
    this.cancelledBy,
  }) : super._();
  @override
  OrderResponseDto rebuild(void Function(OrderResponseDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OrderResponseDtoBuilder toBuilder() =>
      OrderResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderResponseDto &&
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
        goldSurchargeAmount == other.goldSurchargeAmount &&
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
        settledGoldBonusAmount == other.settledGoldBonusAmount &&
        settledGoldPlatformRetainedAmount ==
            other.settledGoldPlatformRetainedAmount &&
        settledBronzeDriverDeduction == other.settledBronzeDriverDeduction &&
        settledBronzeSupervisorDeduction ==
            other.settledBronzeSupervisorDeduction &&
        settledBronzeDriverDeductionRate ==
            other.settledBronzeDriverDeductionRate &&
        settledBronzeSupervisorDeductionRate ==
            other.settledBronzeSupervisorDeductionRate &&
        cancelledByUserId == other.cancelledByUserId &&
        cancelledByRole == other.cancelledByRole &&
        cancelledByName == other.cancelledByName &&
        cancelledByNameAr == other.cancelledByNameAr &&
        cancelledByAvatar == other.cancelledByAvatar &&
        cancelReason == other.cancelReason &&
        cancelledAt == other.cancelledAt &&
        driverTransactions == other.driverTransactions &&
        dispatches == other.dispatches &&
        items == other.items &&
        statusEvents == other.statusEvents &&
        customer == other.customer &&
        driver == other.driver &&
        vendor == other.vendor &&
        vendorBranch == other.vendorBranch &&
        zone == other.zone &&
        supportTickets == other.supportTickets &&
        vendorTransactions == other.vendorTransactions &&
        reviews == other.reviews &&
        vendorFulfillments == other.vendorFulfillments &&
        deliveryGroups == other.deliveryGroups &&
        fulfillmentSummary == other.fulfillmentSummary &&
        cancelledBy == other.cancelledBy;
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
    _$hash = $jc(_$hash, goldSurchargeAmount.hashCode);
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
    _$hash = $jc(_$hash, settledGoldBonusAmount.hashCode);
    _$hash = $jc(_$hash, settledGoldPlatformRetainedAmount.hashCode);
    _$hash = $jc(_$hash, settledBronzeDriverDeduction.hashCode);
    _$hash = $jc(_$hash, settledBronzeSupervisorDeduction.hashCode);
    _$hash = $jc(_$hash, settledBronzeDriverDeductionRate.hashCode);
    _$hash = $jc(_$hash, settledBronzeSupervisorDeductionRate.hashCode);
    _$hash = $jc(_$hash, cancelledByUserId.hashCode);
    _$hash = $jc(_$hash, cancelledByRole.hashCode);
    _$hash = $jc(_$hash, cancelledByName.hashCode);
    _$hash = $jc(_$hash, cancelledByNameAr.hashCode);
    _$hash = $jc(_$hash, cancelledByAvatar.hashCode);
    _$hash = $jc(_$hash, cancelReason.hashCode);
    _$hash = $jc(_$hash, cancelledAt.hashCode);
    _$hash = $jc(_$hash, driverTransactions.hashCode);
    _$hash = $jc(_$hash, dispatches.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, statusEvents.hashCode);
    _$hash = $jc(_$hash, customer.hashCode);
    _$hash = $jc(_$hash, driver.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jc(_$hash, vendorBranch.hashCode);
    _$hash = $jc(_$hash, zone.hashCode);
    _$hash = $jc(_$hash, supportTickets.hashCode);
    _$hash = $jc(_$hash, vendorTransactions.hashCode);
    _$hash = $jc(_$hash, reviews.hashCode);
    _$hash = $jc(_$hash, vendorFulfillments.hashCode);
    _$hash = $jc(_$hash, deliveryGroups.hashCode);
    _$hash = $jc(_$hash, fulfillmentSummary.hashCode);
    _$hash = $jc(_$hash, cancelledBy.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderResponseDto')
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
          ..add('goldSurchargeAmount', goldSurchargeAmount)
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
          ..add('settledGoldBonusAmount', settledGoldBonusAmount)
          ..add(
            'settledGoldPlatformRetainedAmount',
            settledGoldPlatformRetainedAmount,
          )
          ..add('settledBronzeDriverDeduction', settledBronzeDriverDeduction)
          ..add(
            'settledBronzeSupervisorDeduction',
            settledBronzeSupervisorDeduction,
          )
          ..add(
            'settledBronzeDriverDeductionRate',
            settledBronzeDriverDeductionRate,
          )
          ..add(
            'settledBronzeSupervisorDeductionRate',
            settledBronzeSupervisorDeductionRate,
          )
          ..add('cancelledByUserId', cancelledByUserId)
          ..add('cancelledByRole', cancelledByRole)
          ..add('cancelledByName', cancelledByName)
          ..add('cancelledByNameAr', cancelledByNameAr)
          ..add('cancelledByAvatar', cancelledByAvatar)
          ..add('cancelReason', cancelReason)
          ..add('cancelledAt', cancelledAt)
          ..add('driverTransactions', driverTransactions)
          ..add('dispatches', dispatches)
          ..add('items', items)
          ..add('statusEvents', statusEvents)
          ..add('customer', customer)
          ..add('driver', driver)
          ..add('vendor', vendor)
          ..add('vendorBranch', vendorBranch)
          ..add('zone', zone)
          ..add('supportTickets', supportTickets)
          ..add('vendorTransactions', vendorTransactions)
          ..add('reviews', reviews)
          ..add('vendorFulfillments', vendorFulfillments)
          ..add('deliveryGroups', deliveryGroups)
          ..add('fulfillmentSummary', fulfillmentSummary)
          ..add('cancelledBy', cancelledBy))
        .toString();
  }
}

class OrderResponseDtoBuilder
    implements Builder<OrderResponseDto, OrderResponseDtoBuilder> {
  _$OrderResponseDto? _$v;

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

  num? _goldSurchargeAmount;
  num? get goldSurchargeAmount => _$this._goldSurchargeAmount;
  set goldSurchargeAmount(num? goldSurchargeAmount) =>
      _$this._goldSurchargeAmount = goldSurchargeAmount;

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

  num? _settledGoldBonusAmount;
  num? get settledGoldBonusAmount => _$this._settledGoldBonusAmount;
  set settledGoldBonusAmount(num? settledGoldBonusAmount) =>
      _$this._settledGoldBonusAmount = settledGoldBonusAmount;

  num? _settledGoldPlatformRetainedAmount;
  num? get settledGoldPlatformRetainedAmount =>
      _$this._settledGoldPlatformRetainedAmount;
  set settledGoldPlatformRetainedAmount(
    num? settledGoldPlatformRetainedAmount,
  ) => _$this._settledGoldPlatformRetainedAmount =
      settledGoldPlatformRetainedAmount;

  num? _settledBronzeDriverDeduction;
  num? get settledBronzeDriverDeduction => _$this._settledBronzeDriverDeduction;
  set settledBronzeDriverDeduction(num? settledBronzeDriverDeduction) =>
      _$this._settledBronzeDriverDeduction = settledBronzeDriverDeduction;

  num? _settledBronzeSupervisorDeduction;
  num? get settledBronzeSupervisorDeduction =>
      _$this._settledBronzeSupervisorDeduction;
  set settledBronzeSupervisorDeduction(num? settledBronzeSupervisorDeduction) =>
      _$this._settledBronzeSupervisorDeduction =
          settledBronzeSupervisorDeduction;

  num? _settledBronzeDriverDeductionRate;
  num? get settledBronzeDriverDeductionRate =>
      _$this._settledBronzeDriverDeductionRate;
  set settledBronzeDriverDeductionRate(num? settledBronzeDriverDeductionRate) =>
      _$this._settledBronzeDriverDeductionRate =
          settledBronzeDriverDeductionRate;

  num? _settledBronzeSupervisorDeductionRate;
  num? get settledBronzeSupervisorDeductionRate =>
      _$this._settledBronzeSupervisorDeductionRate;
  set settledBronzeSupervisorDeductionRate(
    num? settledBronzeSupervisorDeductionRate,
  ) => _$this._settledBronzeSupervisorDeductionRate =
      settledBronzeSupervisorDeductionRate;

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

  ListBuilder<DriverWalletTransaction>? _driverTransactions;
  ListBuilder<DriverWalletTransaction> get driverTransactions =>
      _$this._driverTransactions ??= ListBuilder<DriverWalletTransaction>();
  set driverTransactions(
    ListBuilder<DriverWalletTransaction>? driverTransactions,
  ) => _$this._driverTransactions = driverTransactions;

  ListBuilder<OrderDispatch>? _dispatches;
  ListBuilder<OrderDispatch> get dispatches =>
      _$this._dispatches ??= ListBuilder<OrderDispatch>();
  set dispatches(ListBuilder<OrderDispatch>? dispatches) =>
      _$this._dispatches = dispatches;

  ListBuilder<OrderItem>? _items;
  ListBuilder<OrderItem> get items =>
      _$this._items ??= ListBuilder<OrderItem>();
  set items(ListBuilder<OrderItem>? items) => _$this._items = items;

  ListBuilder<OrderStatusEvent>? _statusEvents;
  ListBuilder<OrderStatusEvent> get statusEvents =>
      _$this._statusEvents ??= ListBuilder<OrderStatusEvent>();
  set statusEvents(ListBuilder<OrderStatusEvent>? statusEvents) =>
      _$this._statusEvents = statusEvents;

  CustomerBuilder? _customer;
  CustomerBuilder get customer => _$this._customer ??= CustomerBuilder();
  set customer(CustomerBuilder? customer) => _$this._customer = customer;

  DriverBuilder? _driver;
  DriverBuilder get driver => _$this._driver ??= DriverBuilder();
  set driver(DriverBuilder? driver) => _$this._driver = driver;

  VendorBuilder? _vendor;
  VendorBuilder get vendor => _$this._vendor ??= VendorBuilder();
  set vendor(VendorBuilder? vendor) => _$this._vendor = vendor;

  VendorBranchBuilder? _vendorBranch;
  VendorBranchBuilder get vendorBranch =>
      _$this._vendorBranch ??= VendorBranchBuilder();
  set vendorBranch(VendorBranchBuilder? vendorBranch) =>
      _$this._vendorBranch = vendorBranch;

  ZoneBuilder? _zone;
  ZoneBuilder get zone => _$this._zone ??= ZoneBuilder();
  set zone(ZoneBuilder? zone) => _$this._zone = zone;

  ListBuilder<SupportTicket>? _supportTickets;
  ListBuilder<SupportTicket> get supportTickets =>
      _$this._supportTickets ??= ListBuilder<SupportTicket>();
  set supportTickets(ListBuilder<SupportTicket>? supportTickets) =>
      _$this._supportTickets = supportTickets;

  ListBuilder<VendorWalletTransaction>? _vendorTransactions;
  ListBuilder<VendorWalletTransaction> get vendorTransactions =>
      _$this._vendorTransactions ??= ListBuilder<VendorWalletTransaction>();
  set vendorTransactions(
    ListBuilder<VendorWalletTransaction>? vendorTransactions,
  ) => _$this._vendorTransactions = vendorTransactions;

  ListBuilder<OrderReview>? _reviews;
  ListBuilder<OrderReview> get reviews =>
      _$this._reviews ??= ListBuilder<OrderReview>();
  set reviews(ListBuilder<OrderReview>? reviews) => _$this._reviews = reviews;

  ListBuilder<OrderVendorFulfillment>? _vendorFulfillments;
  ListBuilder<OrderVendorFulfillment> get vendorFulfillments =>
      _$this._vendorFulfillments ??= ListBuilder<OrderVendorFulfillment>();
  set vendorFulfillments(
    ListBuilder<OrderVendorFulfillment>? vendorFulfillments,
  ) => _$this._vendorFulfillments = vendorFulfillments;

  ListBuilder<OrderDeliveryGroup>? _deliveryGroups;
  ListBuilder<OrderDeliveryGroup> get deliveryGroups =>
      _$this._deliveryGroups ??= ListBuilder<OrderDeliveryGroup>();
  set deliveryGroups(ListBuilder<OrderDeliveryGroup>? deliveryGroups) =>
      _$this._deliveryGroups = deliveryGroups;

  JsonObject? _fulfillmentSummary;
  JsonObject? get fulfillmentSummary => _$this._fulfillmentSummary;
  set fulfillmentSummary(JsonObject? fulfillmentSummary) =>
      _$this._fulfillmentSummary = fulfillmentSummary;

  OrderCancelledByDtoBuilder? _cancelledBy;
  OrderCancelledByDtoBuilder get cancelledBy =>
      _$this._cancelledBy ??= OrderCancelledByDtoBuilder();
  set cancelledBy(OrderCancelledByDtoBuilder? cancelledBy) =>
      _$this._cancelledBy = cancelledBy;

  OrderResponseDtoBuilder() {
    OrderResponseDto._defaults(this);
  }

  OrderResponseDtoBuilder get _$this {
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
      _goldSurchargeAmount = $v.goldSurchargeAmount;
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
      _settledGoldBonusAmount = $v.settledGoldBonusAmount;
      _settledGoldPlatformRetainedAmount = $v.settledGoldPlatformRetainedAmount;
      _settledBronzeDriverDeduction = $v.settledBronzeDriverDeduction;
      _settledBronzeSupervisorDeduction = $v.settledBronzeSupervisorDeduction;
      _settledBronzeDriverDeductionRate = $v.settledBronzeDriverDeductionRate;
      _settledBronzeSupervisorDeductionRate =
          $v.settledBronzeSupervisorDeductionRate;
      _cancelledByUserId = $v.cancelledByUserId;
      _cancelledByRole = $v.cancelledByRole;
      _cancelledByName = $v.cancelledByName;
      _cancelledByNameAr = $v.cancelledByNameAr;
      _cancelledByAvatar = $v.cancelledByAvatar;
      _cancelReason = $v.cancelReason;
      _cancelledAt = $v.cancelledAt;
      _driverTransactions = $v.driverTransactions?.toBuilder();
      _dispatches = $v.dispatches?.toBuilder();
      _items = $v.items?.toBuilder();
      _statusEvents = $v.statusEvents?.toBuilder();
      _customer = $v.customer?.toBuilder();
      _driver = $v.driver?.toBuilder();
      _vendor = $v.vendor?.toBuilder();
      _vendorBranch = $v.vendorBranch?.toBuilder();
      _zone = $v.zone?.toBuilder();
      _supportTickets = $v.supportTickets?.toBuilder();
      _vendorTransactions = $v.vendorTransactions?.toBuilder();
      _reviews = $v.reviews?.toBuilder();
      _vendorFulfillments = $v.vendorFulfillments?.toBuilder();
      _deliveryGroups = $v.deliveryGroups?.toBuilder();
      _fulfillmentSummary = $v.fulfillmentSummary;
      _cancelledBy = $v.cancelledBy?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderResponseDto other) {
    _$v = other as _$OrderResponseDto;
  }

  @override
  void update(void Function(OrderResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderResponseDto build() => _build();

  _$OrderResponseDto _build() {
    _$OrderResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$OrderResponseDto._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'OrderResponseDto',
              'id',
            ),
            orderNumber: BuiltValueNullFieldError.checkNotNull(
              orderNumber,
              r'OrderResponseDto',
              'orderNumber',
            ),
            clientOrderKey: clientOrderKey,
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'OrderResponseDto',
              'type',
            ),
            customerId: BuiltValueNullFieldError.checkNotNull(
              customerId,
              r'OrderResponseDto',
              'customerId',
            ),
            vendorId: vendorId,
            vendorBranchId: vendorBranchId,
            driverId: driverId,
            zoneId: zoneId,
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'OrderResponseDto',
              'status',
            ),
            revision: BuiltValueNullFieldError.checkNotNull(
              revision,
              r'OrderResponseDto',
              'revision',
            ),
            paymentMethod: BuiltValueNullFieldError.checkNotNull(
              paymentMethod,
              r'OrderResponseDto',
              'paymentMethod',
            ),
            paymentStatus: BuiltValueNullFieldError.checkNotNull(
              paymentStatus,
              r'OrderResponseDto',
              'paymentStatus',
            ),
            deliveryAddress: BuiltValueNullFieldError.checkNotNull(
              deliveryAddress,
              r'OrderResponseDto',
              'deliveryAddress',
            ),
            pickupAddress: pickupAddress,
            itemDetails: itemDetails,
            requestedVehicleType: requestedVehicleType,
            subtotal: BuiltValueNullFieldError.checkNotNull(
              subtotal,
              r'OrderResponseDto',
              'subtotal',
            ),
            deliveryFee: BuiltValueNullFieldError.checkNotNull(
              deliveryFee,
              r'OrderResponseDto',
              'deliveryFee',
            ),
            goldSurchargeAmount: BuiltValueNullFieldError.checkNotNull(
              goldSurchargeAmount,
              r'OrderResponseDto',
              'goldSurchargeAmount',
            ),
            driverBonusFee: BuiltValueNullFieldError.checkNotNull(
              driverBonusFee,
              r'OrderResponseDto',
              'driverBonusFee',
            ),
            serviceFee: BuiltValueNullFieldError.checkNotNull(
              serviceFee,
              r'OrderResponseDto',
              'serviceFee',
            ),
            tax: BuiltValueNullFieldError.checkNotNull(
              tax,
              r'OrderResponseDto',
              'tax',
            ),
            discount: BuiltValueNullFieldError.checkNotNull(
              discount,
              r'OrderResponseDto',
              'discount',
            ),
            coinsUsed: BuiltValueNullFieldError.checkNotNull(
              coinsUsed,
              r'OrderResponseDto',
              'coinsUsed',
            ),
            coinsEarned: BuiltValueNullFieldError.checkNotNull(
              coinsEarned,
              r'OrderResponseDto',
              'coinsEarned',
            ),
            grandTotal: BuiltValueNullFieldError.checkNotNull(
              grandTotal,
              r'OrderResponseDto',
              'grandTotal',
            ),
            upfrontAmount: BuiltValueNullFieldError.checkNotNull(
              upfrontAmount,
              r'OrderResponseDto',
              'upfrontAmount',
            ),
            specialRequest: specialRequest,
            distanceKm: distanceKm,
            deletedAt: deletedAt,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'OrderResponseDto',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'OrderResponseDto',
              'updatedAt',
            ),
            paymentReceiptUrl: paymentReceiptUrl,
            actualDeliveryTime: actualDeliveryTime,
            settledAt: settledAt,
            settledGoldBonusAmount: BuiltValueNullFieldError.checkNotNull(
              settledGoldBonusAmount,
              r'OrderResponseDto',
              'settledGoldBonusAmount',
            ),
            settledGoldPlatformRetainedAmount:
                BuiltValueNullFieldError.checkNotNull(
                  settledGoldPlatformRetainedAmount,
                  r'OrderResponseDto',
                  'settledGoldPlatformRetainedAmount',
                ),
            settledBronzeDriverDeduction: BuiltValueNullFieldError.checkNotNull(
              settledBronzeDriverDeduction,
              r'OrderResponseDto',
              'settledBronzeDriverDeduction',
            ),
            settledBronzeSupervisorDeduction:
                BuiltValueNullFieldError.checkNotNull(
                  settledBronzeSupervisorDeduction,
                  r'OrderResponseDto',
                  'settledBronzeSupervisorDeduction',
                ),
            settledBronzeDriverDeductionRate: settledBronzeDriverDeductionRate,
            settledBronzeSupervisorDeductionRate:
                settledBronzeSupervisorDeductionRate,
            cancelledByUserId: cancelledByUserId,
            cancelledByRole: cancelledByRole,
            cancelledByName: cancelledByName,
            cancelledByNameAr: cancelledByNameAr,
            cancelledByAvatar: cancelledByAvatar,
            cancelReason: cancelReason,
            cancelledAt: cancelledAt,
            driverTransactions: _driverTransactions?.build(),
            dispatches: _dispatches?.build(),
            items: _items?.build(),
            statusEvents: _statusEvents?.build(),
            customer: _customer?.build(),
            driver: _driver?.build(),
            vendor: _vendor?.build(),
            vendorBranch: _vendorBranch?.build(),
            zone: _zone?.build(),
            supportTickets: _supportTickets?.build(),
            vendorTransactions: _vendorTransactions?.build(),
            reviews: _reviews?.build(),
            vendorFulfillments: _vendorFulfillments?.build(),
            deliveryGroups: _deliveryGroups?.build(),
            fulfillmentSummary: fulfillmentSummary,
            cancelledBy: _cancelledBy?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'driverTransactions';
        _driverTransactions?.build();
        _$failedField = 'dispatches';
        _dispatches?.build();
        _$failedField = 'items';
        _items?.build();
        _$failedField = 'statusEvents';
        _statusEvents?.build();
        _$failedField = 'customer';
        _customer?.build();
        _$failedField = 'driver';
        _driver?.build();
        _$failedField = 'vendor';
        _vendor?.build();
        _$failedField = 'vendorBranch';
        _vendorBranch?.build();
        _$failedField = 'zone';
        _zone?.build();
        _$failedField = 'supportTickets';
        _supportTickets?.build();
        _$failedField = 'vendorTransactions';
        _vendorTransactions?.build();
        _$failedField = 'reviews';
        _reviews?.build();
        _$failedField = 'vendorFulfillments';
        _vendorFulfillments?.build();
        _$failedField = 'deliveryGroups';
        _deliveryGroups?.build();

        _$failedField = 'cancelledBy';
        _cancelledBy?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderResponseDto',
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
