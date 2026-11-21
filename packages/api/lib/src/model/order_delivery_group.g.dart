// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_delivery_group.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderDeliveryGroup extends OrderDeliveryGroup {
  @override
  final String id;
  @override
  final String orderId;
  @override
  final num sequence;
  @override
  final DeliveryGroupStatus status;
  @override
  final String? primaryDriverId;
  @override
  final String? primaryDriverShiftId;
  @override
  final String? assistDriverId;
  @override
  final String? assistDriverShiftId;
  @override
  final num? assistFee;
  @override
  final bool? assistCustomerApproved;
  @override
  final DateTime? assistApprovedAt;
  @override
  final bool isStacked;
  @override
  final bool isPaymentCollector;
  @override
  final String? assignedByUserId;
  @override
  final DateTime? assignedAt;
  @override
  final num? distanceKm;
  @override
  final num deliveryFee;
  @override
  final num goldSurchargeAmount;
  @override
  final DriverTier? primaryDriverTierSnapshot;
  @override
  final num settledGoldBonusAmount;
  @override
  final num settledGoldPlatformRetainedAmount;
  @override
  final num settledBronzeDriverDeduction;
  @override
  final num settledBronzeSupervisorDeduction;
  @override
  final String? settledPrimaryManagerId;
  @override
  final num? estimatedPrepTime;
  @override
  final String? pickupImageUrl;
  @override
  final String? deliveryImageUrl;
  @override
  final DateTime? pickedUpAt;
  @override
  final DateTime? deliveredAt;
  @override
  final Driver? primaryDriver;
  @override
  final Driver? assistDriver;
  @override
  final BuiltList<OrderDeliveryGroupItem>? items;

  factory _$OrderDeliveryGroup([
    void Function(OrderDeliveryGroupBuilder)? updates,
  ]) => (OrderDeliveryGroupBuilder()..update(updates))._build();

  _$OrderDeliveryGroup._({
    required this.id,
    required this.orderId,
    required this.sequence,
    required this.status,
    this.primaryDriverId,
    this.primaryDriverShiftId,
    this.assistDriverId,
    this.assistDriverShiftId,
    this.assistFee,
    this.assistCustomerApproved,
    this.assistApprovedAt,
    required this.isStacked,
    required this.isPaymentCollector,
    this.assignedByUserId,
    this.assignedAt,
    this.distanceKm,
    required this.deliveryFee,
    required this.goldSurchargeAmount,
    this.primaryDriverTierSnapshot,
    required this.settledGoldBonusAmount,
    required this.settledGoldPlatformRetainedAmount,
    required this.settledBronzeDriverDeduction,
    required this.settledBronzeSupervisorDeduction,
    this.settledPrimaryManagerId,
    this.estimatedPrepTime,
    this.pickupImageUrl,
    this.deliveryImageUrl,
    this.pickedUpAt,
    this.deliveredAt,
    this.primaryDriver,
    this.assistDriver,
    this.items,
  }) : super._();
  @override
  OrderDeliveryGroup rebuild(
    void Function(OrderDeliveryGroupBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderDeliveryGroupBuilder toBuilder() =>
      OrderDeliveryGroupBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderDeliveryGroup &&
        id == other.id &&
        orderId == other.orderId &&
        sequence == other.sequence &&
        status == other.status &&
        primaryDriverId == other.primaryDriverId &&
        primaryDriverShiftId == other.primaryDriverShiftId &&
        assistDriverId == other.assistDriverId &&
        assistDriverShiftId == other.assistDriverShiftId &&
        assistFee == other.assistFee &&
        assistCustomerApproved == other.assistCustomerApproved &&
        assistApprovedAt == other.assistApprovedAt &&
        isStacked == other.isStacked &&
        isPaymentCollector == other.isPaymentCollector &&
        assignedByUserId == other.assignedByUserId &&
        assignedAt == other.assignedAt &&
        distanceKm == other.distanceKm &&
        deliveryFee == other.deliveryFee &&
        goldSurchargeAmount == other.goldSurchargeAmount &&
        primaryDriverTierSnapshot == other.primaryDriverTierSnapshot &&
        settledGoldBonusAmount == other.settledGoldBonusAmount &&
        settledGoldPlatformRetainedAmount ==
            other.settledGoldPlatformRetainedAmount &&
        settledBronzeDriverDeduction == other.settledBronzeDriverDeduction &&
        settledBronzeSupervisorDeduction ==
            other.settledBronzeSupervisorDeduction &&
        settledPrimaryManagerId == other.settledPrimaryManagerId &&
        estimatedPrepTime == other.estimatedPrepTime &&
        pickupImageUrl == other.pickupImageUrl &&
        deliveryImageUrl == other.deliveryImageUrl &&
        pickedUpAt == other.pickedUpAt &&
        deliveredAt == other.deliveredAt &&
        primaryDriver == other.primaryDriver &&
        assistDriver == other.assistDriver &&
        items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, sequence.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, primaryDriverId.hashCode);
    _$hash = $jc(_$hash, primaryDriverShiftId.hashCode);
    _$hash = $jc(_$hash, assistDriverId.hashCode);
    _$hash = $jc(_$hash, assistDriverShiftId.hashCode);
    _$hash = $jc(_$hash, assistFee.hashCode);
    _$hash = $jc(_$hash, assistCustomerApproved.hashCode);
    _$hash = $jc(_$hash, assistApprovedAt.hashCode);
    _$hash = $jc(_$hash, isStacked.hashCode);
    _$hash = $jc(_$hash, isPaymentCollector.hashCode);
    _$hash = $jc(_$hash, assignedByUserId.hashCode);
    _$hash = $jc(_$hash, assignedAt.hashCode);
    _$hash = $jc(_$hash, distanceKm.hashCode);
    _$hash = $jc(_$hash, deliveryFee.hashCode);
    _$hash = $jc(_$hash, goldSurchargeAmount.hashCode);
    _$hash = $jc(_$hash, primaryDriverTierSnapshot.hashCode);
    _$hash = $jc(_$hash, settledGoldBonusAmount.hashCode);
    _$hash = $jc(_$hash, settledGoldPlatformRetainedAmount.hashCode);
    _$hash = $jc(_$hash, settledBronzeDriverDeduction.hashCode);
    _$hash = $jc(_$hash, settledBronzeSupervisorDeduction.hashCode);
    _$hash = $jc(_$hash, settledPrimaryManagerId.hashCode);
    _$hash = $jc(_$hash, estimatedPrepTime.hashCode);
    _$hash = $jc(_$hash, pickupImageUrl.hashCode);
    _$hash = $jc(_$hash, deliveryImageUrl.hashCode);
    _$hash = $jc(_$hash, pickedUpAt.hashCode);
    _$hash = $jc(_$hash, deliveredAt.hashCode);
    _$hash = $jc(_$hash, primaryDriver.hashCode);
    _$hash = $jc(_$hash, assistDriver.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderDeliveryGroup')
          ..add('id', id)
          ..add('orderId', orderId)
          ..add('sequence', sequence)
          ..add('status', status)
          ..add('primaryDriverId', primaryDriverId)
          ..add('primaryDriverShiftId', primaryDriverShiftId)
          ..add('assistDriverId', assistDriverId)
          ..add('assistDriverShiftId', assistDriverShiftId)
          ..add('assistFee', assistFee)
          ..add('assistCustomerApproved', assistCustomerApproved)
          ..add('assistApprovedAt', assistApprovedAt)
          ..add('isStacked', isStacked)
          ..add('isPaymentCollector', isPaymentCollector)
          ..add('assignedByUserId', assignedByUserId)
          ..add('assignedAt', assignedAt)
          ..add('distanceKm', distanceKm)
          ..add('deliveryFee', deliveryFee)
          ..add('goldSurchargeAmount', goldSurchargeAmount)
          ..add('primaryDriverTierSnapshot', primaryDriverTierSnapshot)
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
          ..add('settledPrimaryManagerId', settledPrimaryManagerId)
          ..add('estimatedPrepTime', estimatedPrepTime)
          ..add('pickupImageUrl', pickupImageUrl)
          ..add('deliveryImageUrl', deliveryImageUrl)
          ..add('pickedUpAt', pickedUpAt)
          ..add('deliveredAt', deliveredAt)
          ..add('primaryDriver', primaryDriver)
          ..add('assistDriver', assistDriver)
          ..add('items', items))
        .toString();
  }
}

class OrderDeliveryGroupBuilder
    implements Builder<OrderDeliveryGroup, OrderDeliveryGroupBuilder> {
  _$OrderDeliveryGroup? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  num? _sequence;
  num? get sequence => _$this._sequence;
  set sequence(num? sequence) => _$this._sequence = sequence;

  DeliveryGroupStatus? _status;
  DeliveryGroupStatus? get status => _$this._status;
  set status(DeliveryGroupStatus? status) => _$this._status = status;

  String? _primaryDriverId;
  String? get primaryDriverId => _$this._primaryDriverId;
  set primaryDriverId(String? primaryDriverId) =>
      _$this._primaryDriverId = primaryDriverId;

  String? _primaryDriverShiftId;
  String? get primaryDriverShiftId => _$this._primaryDriverShiftId;
  set primaryDriverShiftId(String? primaryDriverShiftId) =>
      _$this._primaryDriverShiftId = primaryDriverShiftId;

  String? _assistDriverId;
  String? get assistDriverId => _$this._assistDriverId;
  set assistDriverId(String? assistDriverId) =>
      _$this._assistDriverId = assistDriverId;

  String? _assistDriverShiftId;
  String? get assistDriverShiftId => _$this._assistDriverShiftId;
  set assistDriverShiftId(String? assistDriverShiftId) =>
      _$this._assistDriverShiftId = assistDriverShiftId;

  num? _assistFee;
  num? get assistFee => _$this._assistFee;
  set assistFee(num? assistFee) => _$this._assistFee = assistFee;

  bool? _assistCustomerApproved;
  bool? get assistCustomerApproved => _$this._assistCustomerApproved;
  set assistCustomerApproved(bool? assistCustomerApproved) =>
      _$this._assistCustomerApproved = assistCustomerApproved;

  DateTime? _assistApprovedAt;
  DateTime? get assistApprovedAt => _$this._assistApprovedAt;
  set assistApprovedAt(DateTime? assistApprovedAt) =>
      _$this._assistApprovedAt = assistApprovedAt;

  bool? _isStacked;
  bool? get isStacked => _$this._isStacked;
  set isStacked(bool? isStacked) => _$this._isStacked = isStacked;

  bool? _isPaymentCollector;
  bool? get isPaymentCollector => _$this._isPaymentCollector;
  set isPaymentCollector(bool? isPaymentCollector) =>
      _$this._isPaymentCollector = isPaymentCollector;

  String? _assignedByUserId;
  String? get assignedByUserId => _$this._assignedByUserId;
  set assignedByUserId(String? assignedByUserId) =>
      _$this._assignedByUserId = assignedByUserId;

  DateTime? _assignedAt;
  DateTime? get assignedAt => _$this._assignedAt;
  set assignedAt(DateTime? assignedAt) => _$this._assignedAt = assignedAt;

  num? _distanceKm;
  num? get distanceKm => _$this._distanceKm;
  set distanceKm(num? distanceKm) => _$this._distanceKm = distanceKm;

  num? _deliveryFee;
  num? get deliveryFee => _$this._deliveryFee;
  set deliveryFee(num? deliveryFee) => _$this._deliveryFee = deliveryFee;

  num? _goldSurchargeAmount;
  num? get goldSurchargeAmount => _$this._goldSurchargeAmount;
  set goldSurchargeAmount(num? goldSurchargeAmount) =>
      _$this._goldSurchargeAmount = goldSurchargeAmount;

  DriverTier? _primaryDriverTierSnapshot;
  DriverTier? get primaryDriverTierSnapshot =>
      _$this._primaryDriverTierSnapshot;
  set primaryDriverTierSnapshot(DriverTier? primaryDriverTierSnapshot) =>
      _$this._primaryDriverTierSnapshot = primaryDriverTierSnapshot;

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

  String? _settledPrimaryManagerId;
  String? get settledPrimaryManagerId => _$this._settledPrimaryManagerId;
  set settledPrimaryManagerId(String? settledPrimaryManagerId) =>
      _$this._settledPrimaryManagerId = settledPrimaryManagerId;

  num? _estimatedPrepTime;
  num? get estimatedPrepTime => _$this._estimatedPrepTime;
  set estimatedPrepTime(num? estimatedPrepTime) =>
      _$this._estimatedPrepTime = estimatedPrepTime;

  String? _pickupImageUrl;
  String? get pickupImageUrl => _$this._pickupImageUrl;
  set pickupImageUrl(String? pickupImageUrl) =>
      _$this._pickupImageUrl = pickupImageUrl;

  String? _deliveryImageUrl;
  String? get deliveryImageUrl => _$this._deliveryImageUrl;
  set deliveryImageUrl(String? deliveryImageUrl) =>
      _$this._deliveryImageUrl = deliveryImageUrl;

  DateTime? _pickedUpAt;
  DateTime? get pickedUpAt => _$this._pickedUpAt;
  set pickedUpAt(DateTime? pickedUpAt) => _$this._pickedUpAt = pickedUpAt;

  DateTime? _deliveredAt;
  DateTime? get deliveredAt => _$this._deliveredAt;
  set deliveredAt(DateTime? deliveredAt) => _$this._deliveredAt = deliveredAt;

  DriverBuilder? _primaryDriver;
  DriverBuilder get primaryDriver => _$this._primaryDriver ??= DriverBuilder();
  set primaryDriver(DriverBuilder? primaryDriver) =>
      _$this._primaryDriver = primaryDriver;

  DriverBuilder? _assistDriver;
  DriverBuilder get assistDriver => _$this._assistDriver ??= DriverBuilder();
  set assistDriver(DriverBuilder? assistDriver) =>
      _$this._assistDriver = assistDriver;

  ListBuilder<OrderDeliveryGroupItem>? _items;
  ListBuilder<OrderDeliveryGroupItem> get items =>
      _$this._items ??= ListBuilder<OrderDeliveryGroupItem>();
  set items(ListBuilder<OrderDeliveryGroupItem>? items) =>
      _$this._items = items;

  OrderDeliveryGroupBuilder() {
    OrderDeliveryGroup._defaults(this);
  }

  OrderDeliveryGroupBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _orderId = $v.orderId;
      _sequence = $v.sequence;
      _status = $v.status;
      _primaryDriverId = $v.primaryDriverId;
      _primaryDriverShiftId = $v.primaryDriverShiftId;
      _assistDriverId = $v.assistDriverId;
      _assistDriverShiftId = $v.assistDriverShiftId;
      _assistFee = $v.assistFee;
      _assistCustomerApproved = $v.assistCustomerApproved;
      _assistApprovedAt = $v.assistApprovedAt;
      _isStacked = $v.isStacked;
      _isPaymentCollector = $v.isPaymentCollector;
      _assignedByUserId = $v.assignedByUserId;
      _assignedAt = $v.assignedAt;
      _distanceKm = $v.distanceKm;
      _deliveryFee = $v.deliveryFee;
      _goldSurchargeAmount = $v.goldSurchargeAmount;
      _primaryDriverTierSnapshot = $v.primaryDriverTierSnapshot;
      _settledGoldBonusAmount = $v.settledGoldBonusAmount;
      _settledGoldPlatformRetainedAmount = $v.settledGoldPlatformRetainedAmount;
      _settledBronzeDriverDeduction = $v.settledBronzeDriverDeduction;
      _settledBronzeSupervisorDeduction = $v.settledBronzeSupervisorDeduction;
      _settledPrimaryManagerId = $v.settledPrimaryManagerId;
      _estimatedPrepTime = $v.estimatedPrepTime;
      _pickupImageUrl = $v.pickupImageUrl;
      _deliveryImageUrl = $v.deliveryImageUrl;
      _pickedUpAt = $v.pickedUpAt;
      _deliveredAt = $v.deliveredAt;
      _primaryDriver = $v.primaryDriver?.toBuilder();
      _assistDriver = $v.assistDriver?.toBuilder();
      _items = $v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderDeliveryGroup other) {
    _$v = other as _$OrderDeliveryGroup;
  }

  @override
  void update(void Function(OrderDeliveryGroupBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderDeliveryGroup build() => _build();

  _$OrderDeliveryGroup _build() {
    _$OrderDeliveryGroup _$result;
    try {
      _$result =
          _$v ??
          _$OrderDeliveryGroup._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'OrderDeliveryGroup',
              'id',
            ),
            orderId: BuiltValueNullFieldError.checkNotNull(
              orderId,
              r'OrderDeliveryGroup',
              'orderId',
            ),
            sequence: BuiltValueNullFieldError.checkNotNull(
              sequence,
              r'OrderDeliveryGroup',
              'sequence',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'OrderDeliveryGroup',
              'status',
            ),
            primaryDriverId: primaryDriverId,
            primaryDriverShiftId: primaryDriverShiftId,
            assistDriverId: assistDriverId,
            assistDriverShiftId: assistDriverShiftId,
            assistFee: assistFee,
            assistCustomerApproved: assistCustomerApproved,
            assistApprovedAt: assistApprovedAt,
            isStacked: BuiltValueNullFieldError.checkNotNull(
              isStacked,
              r'OrderDeliveryGroup',
              'isStacked',
            ),
            isPaymentCollector: BuiltValueNullFieldError.checkNotNull(
              isPaymentCollector,
              r'OrderDeliveryGroup',
              'isPaymentCollector',
            ),
            assignedByUserId: assignedByUserId,
            assignedAt: assignedAt,
            distanceKm: distanceKm,
            deliveryFee: BuiltValueNullFieldError.checkNotNull(
              deliveryFee,
              r'OrderDeliveryGroup',
              'deliveryFee',
            ),
            goldSurchargeAmount: BuiltValueNullFieldError.checkNotNull(
              goldSurchargeAmount,
              r'OrderDeliveryGroup',
              'goldSurchargeAmount',
            ),
            primaryDriverTierSnapshot: primaryDriverTierSnapshot,
            settledGoldBonusAmount: BuiltValueNullFieldError.checkNotNull(
              settledGoldBonusAmount,
              r'OrderDeliveryGroup',
              'settledGoldBonusAmount',
            ),
            settledGoldPlatformRetainedAmount:
                BuiltValueNullFieldError.checkNotNull(
                  settledGoldPlatformRetainedAmount,
                  r'OrderDeliveryGroup',
                  'settledGoldPlatformRetainedAmount',
                ),
            settledBronzeDriverDeduction: BuiltValueNullFieldError.checkNotNull(
              settledBronzeDriverDeduction,
              r'OrderDeliveryGroup',
              'settledBronzeDriverDeduction',
            ),
            settledBronzeSupervisorDeduction:
                BuiltValueNullFieldError.checkNotNull(
                  settledBronzeSupervisorDeduction,
                  r'OrderDeliveryGroup',
                  'settledBronzeSupervisorDeduction',
                ),
            settledPrimaryManagerId: settledPrimaryManagerId,
            estimatedPrepTime: estimatedPrepTime,
            pickupImageUrl: pickupImageUrl,
            deliveryImageUrl: deliveryImageUrl,
            pickedUpAt: pickedUpAt,
            deliveredAt: deliveredAt,
            primaryDriver: _primaryDriver?.build(),
            assistDriver: _assistDriver?.build(),
            items: _items?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'primaryDriver';
        _primaryDriver?.build();
        _$failedField = 'assistDriver';
        _assistDriver?.build();
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderDeliveryGroup',
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
