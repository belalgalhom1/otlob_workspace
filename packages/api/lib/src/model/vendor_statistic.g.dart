// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_statistic.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VendorStatistic extends VendorStatistic {
  @override
  final String id;
  @override
  final String vendorId;
  @override
  final JsonObject? period;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final num totalOrders;
  @override
  final num totalRevenue;
  @override
  final num totalCommission;
  @override
  final num totalTax;
  @override
  final num completedOrders;
  @override
  final num cancelledOrders;
  @override
  final num? avgPrepTimeMins;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final JsonObject? vendor;

  factory _$VendorStatistic([void Function(VendorStatisticBuilder)? updates]) =>
      (VendorStatisticBuilder()..update(updates))._build();

  _$VendorStatistic._({
    required this.id,
    required this.vendorId,
    this.period,
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalTax,
    required this.completedOrders,
    required this.cancelledOrders,
    this.avgPrepTimeMins,
    required this.createdAt,
    required this.updatedAt,
    this.vendor,
  }) : super._();
  @override
  VendorStatistic rebuild(void Function(VendorStatisticBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VendorStatisticBuilder toBuilder() => VendorStatisticBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VendorStatistic &&
        id == other.id &&
        vendorId == other.vendorId &&
        period == other.period &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        totalOrders == other.totalOrders &&
        totalRevenue == other.totalRevenue &&
        totalCommission == other.totalCommission &&
        totalTax == other.totalTax &&
        completedOrders == other.completedOrders &&
        cancelledOrders == other.cancelledOrders &&
        avgPrepTimeMins == other.avgPrepTimeMins &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        vendor == other.vendor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jc(_$hash, totalOrders.hashCode);
    _$hash = $jc(_$hash, totalRevenue.hashCode);
    _$hash = $jc(_$hash, totalCommission.hashCode);
    _$hash = $jc(_$hash, totalTax.hashCode);
    _$hash = $jc(_$hash, completedOrders.hashCode);
    _$hash = $jc(_$hash, cancelledOrders.hashCode);
    _$hash = $jc(_$hash, avgPrepTimeMins.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VendorStatistic')
          ..add('id', id)
          ..add('vendorId', vendorId)
          ..add('period', period)
          ..add('startDate', startDate)
          ..add('endDate', endDate)
          ..add('totalOrders', totalOrders)
          ..add('totalRevenue', totalRevenue)
          ..add('totalCommission', totalCommission)
          ..add('totalTax', totalTax)
          ..add('completedOrders', completedOrders)
          ..add('cancelledOrders', cancelledOrders)
          ..add('avgPrepTimeMins', avgPrepTimeMins)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('vendor', vendor))
        .toString();
  }
}

class VendorStatisticBuilder
    implements Builder<VendorStatistic, VendorStatisticBuilder> {
  _$VendorStatistic? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  JsonObject? _period;
  JsonObject? get period => _$this._period;
  set period(JsonObject? period) => _$this._period = period;

  DateTime? _startDate;
  DateTime? get startDate => _$this._startDate;
  set startDate(DateTime? startDate) => _$this._startDate = startDate;

  DateTime? _endDate;
  DateTime? get endDate => _$this._endDate;
  set endDate(DateTime? endDate) => _$this._endDate = endDate;

  num? _totalOrders;
  num? get totalOrders => _$this._totalOrders;
  set totalOrders(num? totalOrders) => _$this._totalOrders = totalOrders;

  num? _totalRevenue;
  num? get totalRevenue => _$this._totalRevenue;
  set totalRevenue(num? totalRevenue) => _$this._totalRevenue = totalRevenue;

  num? _totalCommission;
  num? get totalCommission => _$this._totalCommission;
  set totalCommission(num? totalCommission) =>
      _$this._totalCommission = totalCommission;

  num? _totalTax;
  num? get totalTax => _$this._totalTax;
  set totalTax(num? totalTax) => _$this._totalTax = totalTax;

  num? _completedOrders;
  num? get completedOrders => _$this._completedOrders;
  set completedOrders(num? completedOrders) =>
      _$this._completedOrders = completedOrders;

  num? _cancelledOrders;
  num? get cancelledOrders => _$this._cancelledOrders;
  set cancelledOrders(num? cancelledOrders) =>
      _$this._cancelledOrders = cancelledOrders;

  num? _avgPrepTimeMins;
  num? get avgPrepTimeMins => _$this._avgPrepTimeMins;
  set avgPrepTimeMins(num? avgPrepTimeMins) =>
      _$this._avgPrepTimeMins = avgPrepTimeMins;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  JsonObject? _vendor;
  JsonObject? get vendor => _$this._vendor;
  set vendor(JsonObject? vendor) => _$this._vendor = vendor;

  VendorStatisticBuilder() {
    VendorStatistic._defaults(this);
  }

  VendorStatisticBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _vendorId = $v.vendorId;
      _period = $v.period;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _totalOrders = $v.totalOrders;
      _totalRevenue = $v.totalRevenue;
      _totalCommission = $v.totalCommission;
      _totalTax = $v.totalTax;
      _completedOrders = $v.completedOrders;
      _cancelledOrders = $v.cancelledOrders;
      _avgPrepTimeMins = $v.avgPrepTimeMins;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _vendor = $v.vendor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VendorStatistic other) {
    _$v = other as _$VendorStatistic;
  }

  @override
  void update(void Function(VendorStatisticBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VendorStatistic build() => _build();

  _$VendorStatistic _build() {
    final _$result =
        _$v ??
        _$VendorStatistic._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'VendorStatistic',
            'id',
          ),
          vendorId: BuiltValueNullFieldError.checkNotNull(
            vendorId,
            r'VendorStatistic',
            'vendorId',
          ),
          period: period,
          startDate: BuiltValueNullFieldError.checkNotNull(
            startDate,
            r'VendorStatistic',
            'startDate',
          ),
          endDate: BuiltValueNullFieldError.checkNotNull(
            endDate,
            r'VendorStatistic',
            'endDate',
          ),
          totalOrders: BuiltValueNullFieldError.checkNotNull(
            totalOrders,
            r'VendorStatistic',
            'totalOrders',
          ),
          totalRevenue: BuiltValueNullFieldError.checkNotNull(
            totalRevenue,
            r'VendorStatistic',
            'totalRevenue',
          ),
          totalCommission: BuiltValueNullFieldError.checkNotNull(
            totalCommission,
            r'VendorStatistic',
            'totalCommission',
          ),
          totalTax: BuiltValueNullFieldError.checkNotNull(
            totalTax,
            r'VendorStatistic',
            'totalTax',
          ),
          completedOrders: BuiltValueNullFieldError.checkNotNull(
            completedOrders,
            r'VendorStatistic',
            'completedOrders',
          ),
          cancelledOrders: BuiltValueNullFieldError.checkNotNull(
            cancelledOrders,
            r'VendorStatistic',
            'cancelledOrders',
          ),
          avgPrepTimeMins: avgPrepTimeMins,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'VendorStatistic',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'VendorStatistic',
            'updatedAt',
          ),
          vendor: vendor,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
