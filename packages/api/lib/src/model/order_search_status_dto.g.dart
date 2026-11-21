// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_search_status_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OrderSearchStatusDto extends OrderSearchStatusDto {
  @override
  final String orderId;
  @override
  final String orderNumber;
  @override
  final OrderType orderType;
  @override
  final OrderStatus orderStatus;
  @override
  final num revision;
  @override
  final DriverSearchPhase phase;
  @override
  final num attempt;
  @override
  final num maxAttempts;
  @override
  final num radiusKm;
  @override
  final num maxRadiusKm;
  @override
  final num contactedCount;
  @override
  final num totalContactedCount;
  @override
  final num rejectedCount;
  @override
  final num nearbyAvailableCount;
  @override
  final BuiltList<NearbyDriverPreviewDto> nearbyDrivers;
  @override
  final String? waveExpiresAt;
  @override
  final num searchTimeoutSecs;
  @override
  final String searchStartedAt;
  @override
  final String updatedAt;
  @override
  final SearchTerminalReason terminalReason;
  @override
  final bool canRetry;
  @override
  final GeoPointDto? driverLocation;
  @override
  final num? driverDistanceKm;
  @override
  final num? driverEtaMinutes;

  factory _$OrderSearchStatusDto([
    void Function(OrderSearchStatusDtoBuilder)? updates,
  ]) => (OrderSearchStatusDtoBuilder()..update(updates))._build();

  _$OrderSearchStatusDto._({
    required this.orderId,
    required this.orderNumber,
    required this.orderType,
    required this.orderStatus,
    required this.revision,
    required this.phase,
    required this.attempt,
    required this.maxAttempts,
    required this.radiusKm,
    required this.maxRadiusKm,
    required this.contactedCount,
    required this.totalContactedCount,
    required this.rejectedCount,
    required this.nearbyAvailableCount,
    required this.nearbyDrivers,
    this.waveExpiresAt,
    required this.searchTimeoutSecs,
    required this.searchStartedAt,
    required this.updatedAt,
    required this.terminalReason,
    required this.canRetry,
    this.driverLocation,
    this.driverDistanceKm,
    this.driverEtaMinutes,
  }) : super._();
  @override
  OrderSearchStatusDto rebuild(
    void Function(OrderSearchStatusDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderSearchStatusDtoBuilder toBuilder() =>
      OrderSearchStatusDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderSearchStatusDto &&
        orderId == other.orderId &&
        orderNumber == other.orderNumber &&
        orderType == other.orderType &&
        orderStatus == other.orderStatus &&
        revision == other.revision &&
        phase == other.phase &&
        attempt == other.attempt &&
        maxAttempts == other.maxAttempts &&
        radiusKm == other.radiusKm &&
        maxRadiusKm == other.maxRadiusKm &&
        contactedCount == other.contactedCount &&
        totalContactedCount == other.totalContactedCount &&
        rejectedCount == other.rejectedCount &&
        nearbyAvailableCount == other.nearbyAvailableCount &&
        nearbyDrivers == other.nearbyDrivers &&
        waveExpiresAt == other.waveExpiresAt &&
        searchTimeoutSecs == other.searchTimeoutSecs &&
        searchStartedAt == other.searchStartedAt &&
        updatedAt == other.updatedAt &&
        terminalReason == other.terminalReason &&
        canRetry == other.canRetry &&
        driverLocation == other.driverLocation &&
        driverDistanceKm == other.driverDistanceKm &&
        driverEtaMinutes == other.driverEtaMinutes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, orderNumber.hashCode);
    _$hash = $jc(_$hash, orderType.hashCode);
    _$hash = $jc(_$hash, orderStatus.hashCode);
    _$hash = $jc(_$hash, revision.hashCode);
    _$hash = $jc(_$hash, phase.hashCode);
    _$hash = $jc(_$hash, attempt.hashCode);
    _$hash = $jc(_$hash, maxAttempts.hashCode);
    _$hash = $jc(_$hash, radiusKm.hashCode);
    _$hash = $jc(_$hash, maxRadiusKm.hashCode);
    _$hash = $jc(_$hash, contactedCount.hashCode);
    _$hash = $jc(_$hash, totalContactedCount.hashCode);
    _$hash = $jc(_$hash, rejectedCount.hashCode);
    _$hash = $jc(_$hash, nearbyAvailableCount.hashCode);
    _$hash = $jc(_$hash, nearbyDrivers.hashCode);
    _$hash = $jc(_$hash, waveExpiresAt.hashCode);
    _$hash = $jc(_$hash, searchTimeoutSecs.hashCode);
    _$hash = $jc(_$hash, searchStartedAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, terminalReason.hashCode);
    _$hash = $jc(_$hash, canRetry.hashCode);
    _$hash = $jc(_$hash, driverLocation.hashCode);
    _$hash = $jc(_$hash, driverDistanceKm.hashCode);
    _$hash = $jc(_$hash, driverEtaMinutes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderSearchStatusDto')
          ..add('orderId', orderId)
          ..add('orderNumber', orderNumber)
          ..add('orderType', orderType)
          ..add('orderStatus', orderStatus)
          ..add('revision', revision)
          ..add('phase', phase)
          ..add('attempt', attempt)
          ..add('maxAttempts', maxAttempts)
          ..add('radiusKm', radiusKm)
          ..add('maxRadiusKm', maxRadiusKm)
          ..add('contactedCount', contactedCount)
          ..add('totalContactedCount', totalContactedCount)
          ..add('rejectedCount', rejectedCount)
          ..add('nearbyAvailableCount', nearbyAvailableCount)
          ..add('nearbyDrivers', nearbyDrivers)
          ..add('waveExpiresAt', waveExpiresAt)
          ..add('searchTimeoutSecs', searchTimeoutSecs)
          ..add('searchStartedAt', searchStartedAt)
          ..add('updatedAt', updatedAt)
          ..add('terminalReason', terminalReason)
          ..add('canRetry', canRetry)
          ..add('driverLocation', driverLocation)
          ..add('driverDistanceKm', driverDistanceKm)
          ..add('driverEtaMinutes', driverEtaMinutes))
        .toString();
  }
}

class OrderSearchStatusDtoBuilder
    implements Builder<OrderSearchStatusDto, OrderSearchStatusDtoBuilder> {
  _$OrderSearchStatusDto? _$v;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _orderNumber;
  String? get orderNumber => _$this._orderNumber;
  set orderNumber(String? orderNumber) => _$this._orderNumber = orderNumber;

  OrderType? _orderType;
  OrderType? get orderType => _$this._orderType;
  set orderType(OrderType? orderType) => _$this._orderType = orderType;

  OrderStatus? _orderStatus;
  OrderStatus? get orderStatus => _$this._orderStatus;
  set orderStatus(OrderStatus? orderStatus) =>
      _$this._orderStatus = orderStatus;

  num? _revision;
  num? get revision => _$this._revision;
  set revision(num? revision) => _$this._revision = revision;

  DriverSearchPhase? _phase;
  DriverSearchPhase? get phase => _$this._phase;
  set phase(DriverSearchPhase? phase) => _$this._phase = phase;

  num? _attempt;
  num? get attempt => _$this._attempt;
  set attempt(num? attempt) => _$this._attempt = attempt;

  num? _maxAttempts;
  num? get maxAttempts => _$this._maxAttempts;
  set maxAttempts(num? maxAttempts) => _$this._maxAttempts = maxAttempts;

  num? _radiusKm;
  num? get radiusKm => _$this._radiusKm;
  set radiusKm(num? radiusKm) => _$this._radiusKm = radiusKm;

  num? _maxRadiusKm;
  num? get maxRadiusKm => _$this._maxRadiusKm;
  set maxRadiusKm(num? maxRadiusKm) => _$this._maxRadiusKm = maxRadiusKm;

  num? _contactedCount;
  num? get contactedCount => _$this._contactedCount;
  set contactedCount(num? contactedCount) =>
      _$this._contactedCount = contactedCount;

  num? _totalContactedCount;
  num? get totalContactedCount => _$this._totalContactedCount;
  set totalContactedCount(num? totalContactedCount) =>
      _$this._totalContactedCount = totalContactedCount;

  num? _rejectedCount;
  num? get rejectedCount => _$this._rejectedCount;
  set rejectedCount(num? rejectedCount) =>
      _$this._rejectedCount = rejectedCount;

  num? _nearbyAvailableCount;
  num? get nearbyAvailableCount => _$this._nearbyAvailableCount;
  set nearbyAvailableCount(num? nearbyAvailableCount) =>
      _$this._nearbyAvailableCount = nearbyAvailableCount;

  ListBuilder<NearbyDriverPreviewDto>? _nearbyDrivers;
  ListBuilder<NearbyDriverPreviewDto> get nearbyDrivers =>
      _$this._nearbyDrivers ??= ListBuilder<NearbyDriverPreviewDto>();
  set nearbyDrivers(ListBuilder<NearbyDriverPreviewDto>? nearbyDrivers) =>
      _$this._nearbyDrivers = nearbyDrivers;

  String? _waveExpiresAt;
  String? get waveExpiresAt => _$this._waveExpiresAt;
  set waveExpiresAt(String? waveExpiresAt) =>
      _$this._waveExpiresAt = waveExpiresAt;

  num? _searchTimeoutSecs;
  num? get searchTimeoutSecs => _$this._searchTimeoutSecs;
  set searchTimeoutSecs(num? searchTimeoutSecs) =>
      _$this._searchTimeoutSecs = searchTimeoutSecs;

  String? _searchStartedAt;
  String? get searchStartedAt => _$this._searchStartedAt;
  set searchStartedAt(String? searchStartedAt) =>
      _$this._searchStartedAt = searchStartedAt;

  String? _updatedAt;
  String? get updatedAt => _$this._updatedAt;
  set updatedAt(String? updatedAt) => _$this._updatedAt = updatedAt;

  SearchTerminalReason? _terminalReason;
  SearchTerminalReason? get terminalReason => _$this._terminalReason;
  set terminalReason(SearchTerminalReason? terminalReason) =>
      _$this._terminalReason = terminalReason;

  bool? _canRetry;
  bool? get canRetry => _$this._canRetry;
  set canRetry(bool? canRetry) => _$this._canRetry = canRetry;

  GeoPointDtoBuilder? _driverLocation;
  GeoPointDtoBuilder get driverLocation =>
      _$this._driverLocation ??= GeoPointDtoBuilder();
  set driverLocation(GeoPointDtoBuilder? driverLocation) =>
      _$this._driverLocation = driverLocation;

  num? _driverDistanceKm;
  num? get driverDistanceKm => _$this._driverDistanceKm;
  set driverDistanceKm(num? driverDistanceKm) =>
      _$this._driverDistanceKm = driverDistanceKm;

  num? _driverEtaMinutes;
  num? get driverEtaMinutes => _$this._driverEtaMinutes;
  set driverEtaMinutes(num? driverEtaMinutes) =>
      _$this._driverEtaMinutes = driverEtaMinutes;

  OrderSearchStatusDtoBuilder() {
    OrderSearchStatusDto._defaults(this);
  }

  OrderSearchStatusDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _orderId = $v.orderId;
      _orderNumber = $v.orderNumber;
      _orderType = $v.orderType;
      _orderStatus = $v.orderStatus;
      _revision = $v.revision;
      _phase = $v.phase;
      _attempt = $v.attempt;
      _maxAttempts = $v.maxAttempts;
      _radiusKm = $v.radiusKm;
      _maxRadiusKm = $v.maxRadiusKm;
      _contactedCount = $v.contactedCount;
      _totalContactedCount = $v.totalContactedCount;
      _rejectedCount = $v.rejectedCount;
      _nearbyAvailableCount = $v.nearbyAvailableCount;
      _nearbyDrivers = $v.nearbyDrivers.toBuilder();
      _waveExpiresAt = $v.waveExpiresAt;
      _searchTimeoutSecs = $v.searchTimeoutSecs;
      _searchStartedAt = $v.searchStartedAt;
      _updatedAt = $v.updatedAt;
      _terminalReason = $v.terminalReason;
      _canRetry = $v.canRetry;
      _driverLocation = $v.driverLocation?.toBuilder();
      _driverDistanceKm = $v.driverDistanceKm;
      _driverEtaMinutes = $v.driverEtaMinutes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderSearchStatusDto other) {
    _$v = other as _$OrderSearchStatusDto;
  }

  @override
  void update(void Function(OrderSearchStatusDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderSearchStatusDto build() => _build();

  _$OrderSearchStatusDto _build() {
    _$OrderSearchStatusDto _$result;
    try {
      _$result =
          _$v ??
          _$OrderSearchStatusDto._(
            orderId: BuiltValueNullFieldError.checkNotNull(
              orderId,
              r'OrderSearchStatusDto',
              'orderId',
            ),
            orderNumber: BuiltValueNullFieldError.checkNotNull(
              orderNumber,
              r'OrderSearchStatusDto',
              'orderNumber',
            ),
            orderType: BuiltValueNullFieldError.checkNotNull(
              orderType,
              r'OrderSearchStatusDto',
              'orderType',
            ),
            orderStatus: BuiltValueNullFieldError.checkNotNull(
              orderStatus,
              r'OrderSearchStatusDto',
              'orderStatus',
            ),
            revision: BuiltValueNullFieldError.checkNotNull(
              revision,
              r'OrderSearchStatusDto',
              'revision',
            ),
            phase: BuiltValueNullFieldError.checkNotNull(
              phase,
              r'OrderSearchStatusDto',
              'phase',
            ),
            attempt: BuiltValueNullFieldError.checkNotNull(
              attempt,
              r'OrderSearchStatusDto',
              'attempt',
            ),
            maxAttempts: BuiltValueNullFieldError.checkNotNull(
              maxAttempts,
              r'OrderSearchStatusDto',
              'maxAttempts',
            ),
            radiusKm: BuiltValueNullFieldError.checkNotNull(
              radiusKm,
              r'OrderSearchStatusDto',
              'radiusKm',
            ),
            maxRadiusKm: BuiltValueNullFieldError.checkNotNull(
              maxRadiusKm,
              r'OrderSearchStatusDto',
              'maxRadiusKm',
            ),
            contactedCount: BuiltValueNullFieldError.checkNotNull(
              contactedCount,
              r'OrderSearchStatusDto',
              'contactedCount',
            ),
            totalContactedCount: BuiltValueNullFieldError.checkNotNull(
              totalContactedCount,
              r'OrderSearchStatusDto',
              'totalContactedCount',
            ),
            rejectedCount: BuiltValueNullFieldError.checkNotNull(
              rejectedCount,
              r'OrderSearchStatusDto',
              'rejectedCount',
            ),
            nearbyAvailableCount: BuiltValueNullFieldError.checkNotNull(
              nearbyAvailableCount,
              r'OrderSearchStatusDto',
              'nearbyAvailableCount',
            ),
            nearbyDrivers: nearbyDrivers.build(),
            waveExpiresAt: waveExpiresAt,
            searchTimeoutSecs: BuiltValueNullFieldError.checkNotNull(
              searchTimeoutSecs,
              r'OrderSearchStatusDto',
              'searchTimeoutSecs',
            ),
            searchStartedAt: BuiltValueNullFieldError.checkNotNull(
              searchStartedAt,
              r'OrderSearchStatusDto',
              'searchStartedAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'OrderSearchStatusDto',
              'updatedAt',
            ),
            terminalReason: BuiltValueNullFieldError.checkNotNull(
              terminalReason,
              r'OrderSearchStatusDto',
              'terminalReason',
            ),
            canRetry: BuiltValueNullFieldError.checkNotNull(
              canRetry,
              r'OrderSearchStatusDto',
              'canRetry',
            ),
            driverLocation: _driverLocation?.build(),
            driverDistanceKm: driverDistanceKm,
            driverEtaMinutes: driverEtaMinutes,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'nearbyDrivers';
        nearbyDrivers.build();

        _$failedField = 'driverLocation';
        _driverLocation?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderSearchStatusDto',
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
