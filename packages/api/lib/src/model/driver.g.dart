// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Driver extends Driver {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String? avatar;
  @override
  final String? nationalId;
  @override
  final String? licenseNumber;
  @override
  final VehicleType vehicleType;
  @override
  final String? vehiclePlate;
  @override
  final DriverTier tier;
  @override
  final DriverStatus status;
  @override
  final DateTime? lastLocationUpdate;
  @override
  final num rating;
  @override
  final num ratingCount;
  @override
  final num totalOrders;
  @override
  final num ordersSinceSettlement;
  @override
  final num walletBalance;
  @override
  final bool hasUnpaidCommission;
  @override
  final num version;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final bool isApproved;
  @override
  final DateTime? approvedAt;
  @override
  final String? approvedById;

  factory _$Driver([void Function(DriverBuilder)? updates]) =>
      (DriverBuilder()..update(updates))._build();

  _$Driver._({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.nationalId,
    this.licenseNumber,
    required this.vehicleType,
    this.vehiclePlate,
    required this.tier,
    required this.status,
    this.lastLocationUpdate,
    required this.rating,
    required this.ratingCount,
    required this.totalOrders,
    required this.ordersSinceSettlement,
    required this.walletBalance,
    required this.hasUnpaidCommission,
    required this.version,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isApproved,
    this.approvedAt,
    this.approvedById,
  }) : super._();
  @override
  Driver rebuild(void Function(DriverBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DriverBuilder toBuilder() => DriverBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Driver &&
        id == other.id &&
        userId == other.userId &&
        name == other.name &&
        avatar == other.avatar &&
        nationalId == other.nationalId &&
        licenseNumber == other.licenseNumber &&
        vehicleType == other.vehicleType &&
        vehiclePlate == other.vehiclePlate &&
        tier == other.tier &&
        status == other.status &&
        lastLocationUpdate == other.lastLocationUpdate &&
        rating == other.rating &&
        ratingCount == other.ratingCount &&
        totalOrders == other.totalOrders &&
        ordersSinceSettlement == other.ordersSinceSettlement &&
        walletBalance == other.walletBalance &&
        hasUnpaidCommission == other.hasUnpaidCommission &&
        version == other.version &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        isApproved == other.isApproved &&
        approvedAt == other.approvedAt &&
        approvedById == other.approvedById;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, avatar.hashCode);
    _$hash = $jc(_$hash, nationalId.hashCode);
    _$hash = $jc(_$hash, licenseNumber.hashCode);
    _$hash = $jc(_$hash, vehicleType.hashCode);
    _$hash = $jc(_$hash, vehiclePlate.hashCode);
    _$hash = $jc(_$hash, tier.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, lastLocationUpdate.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, ratingCount.hashCode);
    _$hash = $jc(_$hash, totalOrders.hashCode);
    _$hash = $jc(_$hash, ordersSinceSettlement.hashCode);
    _$hash = $jc(_$hash, walletBalance.hashCode);
    _$hash = $jc(_$hash, hasUnpaidCommission.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, isApproved.hashCode);
    _$hash = $jc(_$hash, approvedAt.hashCode);
    _$hash = $jc(_$hash, approvedById.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Driver')
          ..add('id', id)
          ..add('userId', userId)
          ..add('name', name)
          ..add('avatar', avatar)
          ..add('nationalId', nationalId)
          ..add('licenseNumber', licenseNumber)
          ..add('vehicleType', vehicleType)
          ..add('vehiclePlate', vehiclePlate)
          ..add('tier', tier)
          ..add('status', status)
          ..add('lastLocationUpdate', lastLocationUpdate)
          ..add('rating', rating)
          ..add('ratingCount', ratingCount)
          ..add('totalOrders', totalOrders)
          ..add('ordersSinceSettlement', ordersSinceSettlement)
          ..add('walletBalance', walletBalance)
          ..add('hasUnpaidCommission', hasUnpaidCommission)
          ..add('version', version)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('isApproved', isApproved)
          ..add('approvedAt', approvedAt)
          ..add('approvedById', approvedById))
        .toString();
  }
}

class DriverBuilder implements Builder<Driver, DriverBuilder> {
  _$Driver? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _avatar;
  String? get avatar => _$this._avatar;
  set avatar(String? avatar) => _$this._avatar = avatar;

  String? _nationalId;
  String? get nationalId => _$this._nationalId;
  set nationalId(String? nationalId) => _$this._nationalId = nationalId;

  String? _licenseNumber;
  String? get licenseNumber => _$this._licenseNumber;
  set licenseNumber(String? licenseNumber) =>
      _$this._licenseNumber = licenseNumber;

  VehicleType? _vehicleType;
  VehicleType? get vehicleType => _$this._vehicleType;
  set vehicleType(VehicleType? vehicleType) =>
      _$this._vehicleType = vehicleType;

  String? _vehiclePlate;
  String? get vehiclePlate => _$this._vehiclePlate;
  set vehiclePlate(String? vehiclePlate) => _$this._vehiclePlate = vehiclePlate;

  DriverTier? _tier;
  DriverTier? get tier => _$this._tier;
  set tier(DriverTier? tier) => _$this._tier = tier;

  DriverStatus? _status;
  DriverStatus? get status => _$this._status;
  set status(DriverStatus? status) => _$this._status = status;

  DateTime? _lastLocationUpdate;
  DateTime? get lastLocationUpdate => _$this._lastLocationUpdate;
  set lastLocationUpdate(DateTime? lastLocationUpdate) =>
      _$this._lastLocationUpdate = lastLocationUpdate;

  num? _rating;
  num? get rating => _$this._rating;
  set rating(num? rating) => _$this._rating = rating;

  num? _ratingCount;
  num? get ratingCount => _$this._ratingCount;
  set ratingCount(num? ratingCount) => _$this._ratingCount = ratingCount;

  num? _totalOrders;
  num? get totalOrders => _$this._totalOrders;
  set totalOrders(num? totalOrders) => _$this._totalOrders = totalOrders;

  num? _ordersSinceSettlement;
  num? get ordersSinceSettlement => _$this._ordersSinceSettlement;
  set ordersSinceSettlement(num? ordersSinceSettlement) =>
      _$this._ordersSinceSettlement = ordersSinceSettlement;

  num? _walletBalance;
  num? get walletBalance => _$this._walletBalance;
  set walletBalance(num? walletBalance) =>
      _$this._walletBalance = walletBalance;

  bool? _hasUnpaidCommission;
  bool? get hasUnpaidCommission => _$this._hasUnpaidCommission;
  set hasUnpaidCommission(bool? hasUnpaidCommission) =>
      _$this._hasUnpaidCommission = hasUnpaidCommission;

  num? _version;
  num? get version => _$this._version;
  set version(num? version) => _$this._version = version;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  bool? _isApproved;
  bool? get isApproved => _$this._isApproved;
  set isApproved(bool? isApproved) => _$this._isApproved = isApproved;

  DateTime? _approvedAt;
  DateTime? get approvedAt => _$this._approvedAt;
  set approvedAt(DateTime? approvedAt) => _$this._approvedAt = approvedAt;

  String? _approvedById;
  String? get approvedById => _$this._approvedById;
  set approvedById(String? approvedById) => _$this._approvedById = approvedById;

  DriverBuilder() {
    Driver._defaults(this);
  }

  DriverBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _name = $v.name;
      _avatar = $v.avatar;
      _nationalId = $v.nationalId;
      _licenseNumber = $v.licenseNumber;
      _vehicleType = $v.vehicleType;
      _vehiclePlate = $v.vehiclePlate;
      _tier = $v.tier;
      _status = $v.status;
      _lastLocationUpdate = $v.lastLocationUpdate;
      _rating = $v.rating;
      _ratingCount = $v.ratingCount;
      _totalOrders = $v.totalOrders;
      _ordersSinceSettlement = $v.ordersSinceSettlement;
      _walletBalance = $v.walletBalance;
      _hasUnpaidCommission = $v.hasUnpaidCommission;
      _version = $v.version;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _isApproved = $v.isApproved;
      _approvedAt = $v.approvedAt;
      _approvedById = $v.approvedById;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Driver other) {
    _$v = other as _$Driver;
  }

  @override
  void update(void Function(DriverBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Driver build() => _build();

  _$Driver _build() {
    final _$result =
        _$v ??
        _$Driver._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Driver', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'Driver',
            'userId',
          ),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Driver', 'name'),
          avatar: avatar,
          nationalId: nationalId,
          licenseNumber: licenseNumber,
          vehicleType: BuiltValueNullFieldError.checkNotNull(
            vehicleType,
            r'Driver',
            'vehicleType',
          ),
          vehiclePlate: vehiclePlate,
          tier: BuiltValueNullFieldError.checkNotNull(tier, r'Driver', 'tier'),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'Driver',
            'status',
          ),
          lastLocationUpdate: lastLocationUpdate,
          rating: BuiltValueNullFieldError.checkNotNull(
            rating,
            r'Driver',
            'rating',
          ),
          ratingCount: BuiltValueNullFieldError.checkNotNull(
            ratingCount,
            r'Driver',
            'ratingCount',
          ),
          totalOrders: BuiltValueNullFieldError.checkNotNull(
            totalOrders,
            r'Driver',
            'totalOrders',
          ),
          ordersSinceSettlement: BuiltValueNullFieldError.checkNotNull(
            ordersSinceSettlement,
            r'Driver',
            'ordersSinceSettlement',
          ),
          walletBalance: BuiltValueNullFieldError.checkNotNull(
            walletBalance,
            r'Driver',
            'walletBalance',
          ),
          hasUnpaidCommission: BuiltValueNullFieldError.checkNotNull(
            hasUnpaidCommission,
            r'Driver',
            'hasUnpaidCommission',
          ),
          version: BuiltValueNullFieldError.checkNotNull(
            version,
            r'Driver',
            'version',
          ),
          deletedAt: deletedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Driver',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Driver',
            'updatedAt',
          ),
          isApproved: BuiltValueNullFieldError.checkNotNull(
            isApproved,
            r'Driver',
            'isApproved',
          ),
          approvedAt: approvedAt,
          approvedById: approvedById,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
