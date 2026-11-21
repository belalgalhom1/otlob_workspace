// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_route_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OrderRouteResponseDtoSource_Enum _$orderRouteResponseDtoSourceEnum_osrm =
    const OrderRouteResponseDtoSource_Enum._('osrm');
const OrderRouteResponseDtoSource_Enum
_$orderRouteResponseDtoSourceEnum_fallback =
    const OrderRouteResponseDtoSource_Enum._('fallback');

OrderRouteResponseDtoSource_Enum _$orderRouteResponseDtoSourceEnumValueOf(
  String name,
) {
  switch (name) {
    case 'osrm':
      return _$orderRouteResponseDtoSourceEnum_osrm;
    case 'fallback':
      return _$orderRouteResponseDtoSourceEnum_fallback;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OrderRouteResponseDtoSource_Enum>
_$orderRouteResponseDtoSourceEnumValues =
    BuiltSet<OrderRouteResponseDtoSource_Enum>(
      const <OrderRouteResponseDtoSource_Enum>[
        _$orderRouteResponseDtoSourceEnum_osrm,
        _$orderRouteResponseDtoSourceEnum_fallback,
      ],
    );

Serializer<OrderRouteResponseDtoSource_Enum>
_$orderRouteResponseDtoSourceEnumSerializer =
    _$OrderRouteResponseDtoSource_EnumSerializer();

class _$OrderRouteResponseDtoSource_EnumSerializer
    implements PrimitiveSerializer<OrderRouteResponseDtoSource_Enum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'osrm': 'osrm',
    'fallback': 'fallback',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'osrm': 'osrm',
    'fallback': 'fallback',
  };

  @override
  final Iterable<Type> types = const <Type>[OrderRouteResponseDtoSource_Enum];
  @override
  final String wireName = 'OrderRouteResponseDtoSource_Enum';

  @override
  Object serialize(
    Serializers serializers,
    OrderRouteResponseDtoSource_Enum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  OrderRouteResponseDtoSource_Enum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => OrderRouteResponseDtoSource_Enum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$OrderRouteResponseDto extends OrderRouteResponseDto {
  @override
  final JsonObject? orderId;
  @override
  final JsonObject? orderStatus;
  @override
  final String encodedPolyline;
  @override
  final BuiltList<RouteCoordinateDto> coordinates;
  @override
  final BuiltList<RouteCoordinateDto> waypoints;
  @override
  final num distanceMeters;
  @override
  final num durationSeconds;
  @override
  final bool isRoadRoute;
  @override
  final OrderRouteResponseDtoSource_Enum source_;
  @override
  final RouteCoordinateDto? driverLocation;
  @override
  final RouteCoordinateDto? destination;

  factory _$OrderRouteResponseDto([
    void Function(OrderRouteResponseDtoBuilder)? updates,
  ]) => (OrderRouteResponseDtoBuilder()..update(updates))._build();

  _$OrderRouteResponseDto._({
    this.orderId,
    this.orderStatus,
    required this.encodedPolyline,
    required this.coordinates,
    required this.waypoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isRoadRoute,
    required this.source_,
    this.driverLocation,
    this.destination,
  }) : super._();
  @override
  OrderRouteResponseDto rebuild(
    void Function(OrderRouteResponseDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OrderRouteResponseDtoBuilder toBuilder() =>
      OrderRouteResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OrderRouteResponseDto &&
        orderId == other.orderId &&
        orderStatus == other.orderStatus &&
        encodedPolyline == other.encodedPolyline &&
        coordinates == other.coordinates &&
        waypoints == other.waypoints &&
        distanceMeters == other.distanceMeters &&
        durationSeconds == other.durationSeconds &&
        isRoadRoute == other.isRoadRoute &&
        source_ == other.source_ &&
        driverLocation == other.driverLocation &&
        destination == other.destination;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, orderStatus.hashCode);
    _$hash = $jc(_$hash, encodedPolyline.hashCode);
    _$hash = $jc(_$hash, coordinates.hashCode);
    _$hash = $jc(_$hash, waypoints.hashCode);
    _$hash = $jc(_$hash, distanceMeters.hashCode);
    _$hash = $jc(_$hash, durationSeconds.hashCode);
    _$hash = $jc(_$hash, isRoadRoute.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, driverLocation.hashCode);
    _$hash = $jc(_$hash, destination.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OrderRouteResponseDto')
          ..add('orderId', orderId)
          ..add('orderStatus', orderStatus)
          ..add('encodedPolyline', encodedPolyline)
          ..add('coordinates', coordinates)
          ..add('waypoints', waypoints)
          ..add('distanceMeters', distanceMeters)
          ..add('durationSeconds', durationSeconds)
          ..add('isRoadRoute', isRoadRoute)
          ..add('source_', source_)
          ..add('driverLocation', driverLocation)
          ..add('destination', destination))
        .toString();
  }
}

class OrderRouteResponseDtoBuilder
    implements Builder<OrderRouteResponseDto, OrderRouteResponseDtoBuilder> {
  _$OrderRouteResponseDto? _$v;

  JsonObject? _orderId;
  JsonObject? get orderId => _$this._orderId;
  set orderId(JsonObject? orderId) => _$this._orderId = orderId;

  JsonObject? _orderStatus;
  JsonObject? get orderStatus => _$this._orderStatus;
  set orderStatus(JsonObject? orderStatus) => _$this._orderStatus = orderStatus;

  String? _encodedPolyline;
  String? get encodedPolyline => _$this._encodedPolyline;
  set encodedPolyline(String? encodedPolyline) =>
      _$this._encodedPolyline = encodedPolyline;

  ListBuilder<RouteCoordinateDto>? _coordinates;
  ListBuilder<RouteCoordinateDto> get coordinates =>
      _$this._coordinates ??= ListBuilder<RouteCoordinateDto>();
  set coordinates(ListBuilder<RouteCoordinateDto>? coordinates) =>
      _$this._coordinates = coordinates;

  ListBuilder<RouteCoordinateDto>? _waypoints;
  ListBuilder<RouteCoordinateDto> get waypoints =>
      _$this._waypoints ??= ListBuilder<RouteCoordinateDto>();
  set waypoints(ListBuilder<RouteCoordinateDto>? waypoints) =>
      _$this._waypoints = waypoints;

  num? _distanceMeters;
  num? get distanceMeters => _$this._distanceMeters;
  set distanceMeters(num? distanceMeters) =>
      _$this._distanceMeters = distanceMeters;

  num? _durationSeconds;
  num? get durationSeconds => _$this._durationSeconds;
  set durationSeconds(num? durationSeconds) =>
      _$this._durationSeconds = durationSeconds;

  bool? _isRoadRoute;
  bool? get isRoadRoute => _$this._isRoadRoute;
  set isRoadRoute(bool? isRoadRoute) => _$this._isRoadRoute = isRoadRoute;

  OrderRouteResponseDtoSource_Enum? _source_;
  OrderRouteResponseDtoSource_Enum? get source_ => _$this._source_;
  set source_(OrderRouteResponseDtoSource_Enum? source_) =>
      _$this._source_ = source_;

  RouteCoordinateDtoBuilder? _driverLocation;
  RouteCoordinateDtoBuilder get driverLocation =>
      _$this._driverLocation ??= RouteCoordinateDtoBuilder();
  set driverLocation(RouteCoordinateDtoBuilder? driverLocation) =>
      _$this._driverLocation = driverLocation;

  RouteCoordinateDtoBuilder? _destination;
  RouteCoordinateDtoBuilder get destination =>
      _$this._destination ??= RouteCoordinateDtoBuilder();
  set destination(RouteCoordinateDtoBuilder? destination) =>
      _$this._destination = destination;

  OrderRouteResponseDtoBuilder() {
    OrderRouteResponseDto._defaults(this);
  }

  OrderRouteResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _orderId = $v.orderId;
      _orderStatus = $v.orderStatus;
      _encodedPolyline = $v.encodedPolyline;
      _coordinates = $v.coordinates.toBuilder();
      _waypoints = $v.waypoints.toBuilder();
      _distanceMeters = $v.distanceMeters;
      _durationSeconds = $v.durationSeconds;
      _isRoadRoute = $v.isRoadRoute;
      _source_ = $v.source_;
      _driverLocation = $v.driverLocation?.toBuilder();
      _destination = $v.destination?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OrderRouteResponseDto other) {
    _$v = other as _$OrderRouteResponseDto;
  }

  @override
  void update(void Function(OrderRouteResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OrderRouteResponseDto build() => _build();

  _$OrderRouteResponseDto _build() {
    _$OrderRouteResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$OrderRouteResponseDto._(
            orderId: orderId,
            orderStatus: orderStatus,
            encodedPolyline: BuiltValueNullFieldError.checkNotNull(
              encodedPolyline,
              r'OrderRouteResponseDto',
              'encodedPolyline',
            ),
            coordinates: coordinates.build(),
            waypoints: waypoints.build(),
            distanceMeters: BuiltValueNullFieldError.checkNotNull(
              distanceMeters,
              r'OrderRouteResponseDto',
              'distanceMeters',
            ),
            durationSeconds: BuiltValueNullFieldError.checkNotNull(
              durationSeconds,
              r'OrderRouteResponseDto',
              'durationSeconds',
            ),
            isRoadRoute: BuiltValueNullFieldError.checkNotNull(
              isRoadRoute,
              r'OrderRouteResponseDto',
              'isRoadRoute',
            ),
            source_: BuiltValueNullFieldError.checkNotNull(
              source_,
              r'OrderRouteResponseDto',
              'source_',
            ),
            driverLocation: _driverLocation?.build(),
            destination: _destination?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'coordinates';
        coordinates.build();
        _$failedField = 'waypoints';
        waypoints.build();

        _$failedField = 'driverLocation';
        _driverLocation?.build();
        _$failedField = 'destination';
        _destination?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'OrderRouteResponseDto',
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
