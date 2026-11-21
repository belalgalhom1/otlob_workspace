import 'dart:collection';

import 'package:api/api.dart';
import 'package:built_collection/built_collection.dart';
import 'package:core/core.dart';

import 'response_parser.dart';

/// Canonical domain model for a resolved driving route returned by
/// [SharedRoutingRepository].
class ResolvedRoadRoute {
  final List<RoadRoutePoint> points;
  final List<RoadRoutePoint> waypoints;
  final String encodedPolyline;
  final int distanceMeters;
  final int durationSeconds;
  final bool isRoadRoute;
  final RoadRoutePoint? driverLocation;
  final RoadRoutePoint? destination;
  final String source;

  const ResolvedRoadRoute({
    required this.points,
    required this.waypoints,
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isRoadRoute,
    this.driverLocation,
    this.destination,
    required this.source,
  });

  bool get hasRenderablePath => points.length >= 2;
}

/// Shared repository consuming backend `/orders/:orderId/route` and
/// `/orders/route` endpoints with LRU caching, in-flight request deduplication,
/// and resilient OSRM / straight-chord fallbacks.
class SharedRoutingRepository {
  final OrdersApi _ordersApi;
  final Dio? _externalDio;

  static const int _maxCacheEntries = 120;
  final LinkedHashMap<String, ResolvedRoadRoute> _routeCache =
      LinkedHashMap<String, ResolvedRoadRoute>();
  final Map<String, Future<ResolvedRoadRoute>> _inFlightWaypointRequests = {};

  SharedRoutingRepository(this._ordersApi, {Dio? externalDio})
    : _externalDio = externalDio;

  /// Fetches the backend-authorized road route for [orderId].
  ///
  /// When the backend returns a fallback (`isRoadRoute: false`) or is
  /// temporarily unreachable, falls back to client multi-waypoint OSRM using
  /// backend-resolved waypoints (or [fallbackWaypoints]), and finally a
  /// straight waypoint chord (`isRoadRoute: false`) only if offline.
  Future<ResolvedRoadRoute> getOrderRoute({
    required String orderId,
    bool includeDriver = true,
    List<RoadRoutePoint> fallbackWaypoints = const [],
    CancelToken? cancelToken,
  }) async {
    OrderRouteResponseDto? dto;
    try {
      final response = await _ordersApi.ordersControllerGetOrderRoute(
        orderId: orderId,
        includeDriver: includeDriver,
        cancelToken: cancelToken,
      );
      dto = ResponseParser.parseTyped(
        response,
        OrderRouteResponseDto.serializer,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel || (cancelToken?.isCancelled ?? false)) {
        rethrow;
      }
    } catch (_) {
      // Fall through cleanly to client OSRM / straight fallback.
    }

    if (dto != null) {
      final resolved = await _resolveDtoOrFallback(
        dto,
        fallbackWaypoints: fallbackWaypoints,
        cancelToken: cancelToken,
      );
      if (resolved.isRoadRoute && resolved.waypoints.length >= 2) {
        final key = _cacheKey(resolved.waypoints);
        _writeCache(key, resolved);
        OsrmClientFallback.primeCache(resolved.waypoints, resolved.points);
      }
      return resolved;
    }

    return _fallbackFromWaypoints(fallbackWaypoints, cancelToken: cancelToken);
  }

  /// Computes a driving road route across ordered [rawWaypoints] via
  /// `POST /orders/route`, backed by LRU caching & client OSRM fallback.
  Future<ResolvedRoadRoute> computeWaypointsRoute(
    List<RoadRoutePoint> rawWaypoints, {
    CancelToken? cancelToken,
  }) async {
    final waypoints = GeoPointUtils.deduplicateAdjacentWaypoints(rawWaypoints);
    if (waypoints.length < 2 ||
        GeoPointUtils.computeTotalPathMeters(waypoints) < 15.0) {
      return _buildChordResult(waypoints);
    }

    final key = _cacheKey(waypoints);
    final cached = _readCache(key);
    if (cached != null) return cached;

    final existing = _inFlightWaypointRequests[key];
    if (existing != null) return existing;

    final pending = _fetchWaypointsRoute(
      key,
      waypoints,
      cancelToken: cancelToken,
    );
    _inFlightWaypointRequests[key] = pending;
    try {
      return await pending;
    } finally {
      _inFlightWaypointRequests.remove(key);
    }
  }

  Future<ResolvedRoadRoute> _fetchWaypointsRoute(
    String cacheKey,
    List<RoadRoutePoint> waypoints, {
    CancelToken? cancelToken,
  }) async {
    OrderRouteResponseDto? dto;
    try {
      final dtoPayload = ComputeRouteDto((b) {
        b.waypoints = ListBuilder<RouteCoordinateDto>(
          waypoints.map(
            (w) => RouteCoordinateDto(
              (c) => c
                ..latitude = w.latitude
                ..longitude = w.longitude,
            ),
          ),
        );
      });
      final response = await _ordersApi.ordersControllerComputeRoute(
        computeRouteDto: dtoPayload,
        cancelToken: cancelToken,
      );
      dto = ResponseParser.parseTyped(
        response,
        OrderRouteResponseDto.serializer,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel || (cancelToken?.isCancelled ?? false)) {
        rethrow;
      }
    } catch (_) {
      // Fall through to client OSRM fallback.
    }

    final ResolvedRoadRoute result;
    if (dto != null) {
      result = await _resolveDtoOrFallback(
        dto,
        fallbackWaypoints: waypoints,
        cancelToken: cancelToken,
      );
    } else {
      result = await _fallbackFromWaypoints(
        waypoints,
        cancelToken: cancelToken,
      );
    }

    if (result.isRoadRoute && result.points.length >= 2) {
      _writeCache(cacheKey, result);
      OsrmClientFallback.primeCache(waypoints, result.points);
    }
    return result;
  }

  Future<ResolvedRoadRoute> _resolveDtoOrFallback(
    OrderRouteResponseDto dto, {
    required List<RoadRoutePoint> fallbackWaypoints,
    CancelToken? cancelToken,
  }) async {
    List<RoadRoutePoint> points = dto.coordinates
        .map(
          (c) => RoadRoutePoint(c.latitude.toDouble(), c.longitude.toDouble()),
        )
        .where((p) => p.isValid)
        .toList();

    if (points.length < 2 && dto.encodedPolyline.isNotEmpty) {
      points = PolylineCodec.decode(dto.encodedPolyline);
    }

    final dtoWaypoints = dto.waypoints
        .map(
          (c) => RoadRoutePoint(c.latitude.toDouble(), c.longitude.toDouble()),
        )
        .where((p) => p.isValid && p.isNonZero)
        .toList();

    final effectiveWaypoints = dtoWaypoints.length >= 2
        ? dtoWaypoints
        : GeoPointUtils.deduplicateAdjacentWaypoints(fallbackWaypoints);

    final driverPt = dto.driverLocation == null
        ? null
        : GeoPointUtils.extractPoint({
            'latitude': dto.driverLocation!.latitude,
            'longitude': dto.driverLocation!.longitude,
          });
    final destPt = dto.destination == null
        ? null
        : GeoPointUtils.extractPoint({
            'latitude': dto.destination!.latitude,
            'longitude': dto.destination!.longitude,
          });

    if (dto.isRoadRoute && points.length >= 2) {
      return ResolvedRoadRoute(
        points: points,
        waypoints: effectiveWaypoints,
        encodedPolyline: dto.encodedPolyline.isNotEmpty
            ? dto.encodedPolyline
            : PolylineCodec.encode(points),
        distanceMeters: dto.distanceMeters.toInt(),
        durationSeconds: dto.durationSeconds.toInt(),
        isRoadRoute: true,
        driverLocation: driverPt,
        destination: destPt,
        source: dto.source_.name,
      );
    }

    final fallbackResolved = await _fallbackFromWaypoints(
      effectiveWaypoints,
      cancelToken: cancelToken,
      driverLocation: driverPt,
      destination: destPt,
    );
    return fallbackResolved;
  }

  Future<ResolvedRoadRoute> _fallbackFromWaypoints(
    List<RoadRoutePoint> rawWaypoints, {
    CancelToken? cancelToken,
    RoadRoutePoint? driverLocation,
    RoadRoutePoint? destination,
  }) async {
    final waypoints = GeoPointUtils.deduplicateAdjacentWaypoints(rawWaypoints);
    if (_externalDio != null && waypoints.length >= 2) {
      final osrmPoints = await OsrmClientFallback.fetchMultiWaypointRoute(
        _externalDio,
        waypoints,
        cancelToken: cancelToken,
      );
      if (osrmPoints != null && osrmPoints.length >= 2) {
        return ResolvedRoadRoute(
          points: osrmPoints,
          waypoints: waypoints,
          encodedPolyline: PolylineCodec.encode(osrmPoints),
          distanceMeters: GeoPointUtils.computeTotalPathMeters(osrmPoints).round(),
          durationSeconds: 0,
          isRoadRoute: true,
          driverLocation: driverLocation,
          destination: destination ?? waypoints.last,
          source: 'client_osrm',
        );
      }
    }
    return _buildChordResult(
      waypoints,
      driverLocation: driverLocation,
      destination: destination,
    );
  }

  ResolvedRoadRoute _buildChordResult(
    List<RoadRoutePoint> waypoints, {
    RoadRoutePoint? driverLocation,
    RoadRoutePoint? destination,
  }) {
    return ResolvedRoadRoute(
      points: waypoints,
      waypoints: waypoints,
      encodedPolyline: PolylineCodec.encode(waypoints),
      distanceMeters: GeoPointUtils.computeTotalPathMeters(waypoints).round(),
      durationSeconds: 0,
      isRoadRoute: false,
      driverLocation: driverLocation,
      destination: destination ?? (waypoints.isNotEmpty ? waypoints.last : null),
      source: 'fallback',
    );
  }

  String _cacheKey(List<RoadRoutePoint> waypoints) =>
      waypoints.map((p) => p.toCacheSegment(decimals: 5)).join('|');

  ResolvedRoadRoute? _readCache(String key) {
    final hit = _routeCache.remove(key);
    if (hit == null) return null;
    _routeCache[key] = hit;
    return hit;
  }

  void _writeCache(String key, ResolvedRoadRoute value) {
    _routeCache.remove(key);
    if (_routeCache.length >= _maxCacheEntries) {
      _routeCache.remove(_routeCache.keys.first);
    }
    _routeCache[key] = value;
  }
}
