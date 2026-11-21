import 'dart:collection';
import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Immutable WGS84 coordinate pair shared across routing & map helpers without
/// coupling `core` to Flutter map widget libraries.
class RoadRoutePoint {
  final double latitude;
  final double longitude;

  const RoadRoutePoint(this.latitude, this.longitude);

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;

  bool get isNonZero => latitude.abs() > 0.0001 || longitude.abs() > 0.0001;

  String toCacheSegment({int decimals = 5}) =>
      '${latitude.toStringAsFixed(decimals)},${longitude.toStringAsFixed(decimals)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoadRoutePoint &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'RoadRoutePoint($latitude, $longitude)';
}

/// Google Encoded Polyline (precision 5) encoder and decoder matching the
/// backend `polyline.utils.ts` implementation.
class PolylineCodec {
  const PolylineCodec._();

  static String encode(List<RoadRoutePoint> points) {
    if (points.isEmpty) return '';
    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final point in points) {
      if (!point.isValid) continue;
      final latE5 = (point.latitude * 1e5).round();
      final lngE5 = (point.longitude * 1e5).round();
      _encodeSignedValue(latE5 - prevLat, buffer);
      _encodeSignedValue(lngE5 - prevLng, buffer);
      prevLat = latE5;
      prevLng = lngE5;
    }
    return buffer.toString();
  }

  static void _encodeSignedValue(int value, StringBuffer buffer) {
    int encoded = value < 0 ? ~(value << 1) : (value << 1);
    while (encoded >= 0x20) {
      buffer.writeCharCode((0x20 | (encoded & 0x1f)) + 63);
      encoded >>= 5;
    }
    buffer.writeCharCode(encoded + 63);
  }

  static List<RoadRoutePoint> decode(String encoded) {
    if (encoded.isEmpty) return const [];
    final points = <RoadRoutePoint>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        if (index >= encoded.length) return points;
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      do {
        if (index >= encoded.length) return points;
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      final point = RoadRoutePoint(lat / 1e5, lng / 1e5);
      if (point.isValid) {
        points.add(point);
      }
    }
    return points;
  }
}

/// Shared coordinate parsing, geodesic distance, bearing, and route-trimming
/// utilities across Customer, Driver, and Vendor apps.
class GeoPointUtils {
  const GeoPointUtils._();

  static const double earthRadiusKm = 6371.0;

  /// Parses GeoJSON Point maps, `[lng, lat]` tuples, `{latitude, longitude}`,
  /// `{lat, lng}`, or any Iterable pair. Rejects malformed coordinates & `(0, 0)`.
  static RoadRoutePoint? extractPoint(dynamic raw) {
    if (raw == null) return null;

    double? lat;
    double? lng;

    if (raw is RoadRoutePoint) {
      return (raw.isValid && raw.isNonZero) ? raw : null;
    }

    if (raw is Map) {
      final coords = raw['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = _toDouble(coords[0]);
        lat = _toDouble(coords[1]);
      } else if (coords is Iterable && coords.length >= 2) {
        final items = coords.toList(growable: false);
        lng = _toDouble(items[0]);
        lat = _toDouble(items[1]);
      } else {
        lat = _toDouble(raw['latitude'] ?? raw['lat']);
        lng = _toDouble(raw['longitude'] ?? raw['lng']);
      }
    } else if (raw is List && raw.length >= 2) {
      lng = _toDouble(raw[0]);
      lat = _toDouble(raw[1]);
    } else if (raw is Iterable && raw.length >= 2) {
      final items = raw.toList(growable: false);
      lng = _toDouble(items[0]);
      lat = _toDouble(items[1]);
    }

    if (lat == null || lng == null) return null;
    final point = RoadRoutePoint(lat, lng);
    if (!point.isValid || !point.isNonZero) return null;
    return point;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// Great-circle Haversine distance in kilometers.
  static double distanceKm(RoadRoutePoint a, RoadRoutePoint b) {
    const rad = math.pi / 180.0;
    final dLat = (b.latitude - a.latitude) * rad;
    final dLng = (b.longitude - a.longitude) * rad;
    final sLat = math.sin(dLat / 2);
    final sLng = math.sin(dLng / 2);
    final h =
        sLat * sLat +
        math.cos(a.latitude * rad) * math.cos(b.latitude * rad) * sLng * sLng;
    final clamped = h < 0 ? 0.0 : (h > 1 ? 1.0 : h);
    return 2 * earthRadiusKm * math.atan2(math.sqrt(clamped), math.sqrt(1 - clamped));
  }

  static double distanceMeters(RoadRoutePoint a, RoadRoutePoint b) =>
      distanceKm(a, b) * 1000.0;

  static double computeTotalPathMeters(List<RoadRoutePoint> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += distanceMeters(points[i - 1], points[i]);
    }
    return total;
  }

  /// Bearing in clockwise degrees `[0, 360)` from [from] toward [to], or `null`
  /// when movement is under [minDistanceMeters] (stationary GPS jitter).
  static double? computeBearingDegrees(
    RoadRoutePoint from,
    RoadRoutePoint to, {
    double minDistanceMeters = 2.0,
  }) {
    if (distanceMeters(from, to) < minDistanceMeters) return null;
    const rad = math.pi / 180.0;
    final lat1 = from.latitude * rad;
    final lat2 = to.latitude * rad;
    final dLng = (to.longitude - from.longitude) * rad;
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final deg = math.atan2(y, x) * (180.0 / math.pi);
    return (deg + 360.0) % 360.0;
  }

  /// Collapses adjacent waypoints separated by less than [minDistanceKm] (15m default).
  static List<RoadRoutePoint> deduplicateAdjacentWaypoints(
    List<RoadRoutePoint> waypoints, {
    double minDistanceKm = 0.015,
  }) {
    final valid = waypoints.where((p) => p.isValid && p.isNonZero).toList();
    if (valid.length <= 1) return valid;

    final kept = <RoadRoutePoint>[valid.first];
    for (int i = 1; i < valid.length; i++) {
      if (distanceKm(kept.last, valid[i]) >= minDistanceKm) {
        kept.add(valid[i]);
      }
    }

    final lastInput = valid.last;
    if (kept.length == 1 && distanceKm(kept.last, lastInput) > 0.0005) {
      kept.add(lastInput);
    } else if (kept.length >= 2 &&
        distanceKm(kept.last, lastInput) >= minDistanceKm) {
      kept.add(lastInput);
    }
    return kept;
  }
}

/// Result of snapping & trimming a cached road route to the driver's live
/// position so completed road segments disappear cleanly behind the marker.
class RoadRouteTrimResult {
  final List<RoadRoutePoint> points;
  final bool isOffRoute;

  const RoadRouteTrimResult({
    required this.points,
    required this.isOffRoute,
  });
}

/// Trims completed vertices along [route] up to the segment closest to
/// [driverPos]. Flags [isOffRoute] when the driver deviates farther than
/// [offRouteThresholdKm] (default 250m) so callers know to re-query the route.
RoadRouteTrimResult trimRouteToDriverPosition(
  List<RoadRoutePoint> route,
  RoadRoutePoint driverPos, {
  double offRouteThresholdKm = 0.25,
}) {
  if (route.isEmpty) {
    return const RoadRouteTrimResult(points: [], isOffRoute: false);
  }
  if (route.length == 1) {
    final distKm = GeoPointUtils.distanceKm(driverPos, route.first);
    if (distKm < 0.003) {
      return RoadRouteTrimResult(points: [driverPos], isOffRoute: false);
    }
    return RoadRouteTrimResult(
      points: [driverPos, route.first],
      isOffRoute: distKm > offRouteThresholdKm,
    );
  }

  final cosLat = math
      .cos(driverPos.latitude * math.pi / 180.0)
      .clamp(0.1, 1.0);

  int bestSegmentIndex = 0;
  double bestDistKm = double.infinity;
  RoadRoutePoint bestProjection = route.first;

  for (int i = 0; i < route.length - 1; i++) {
    final a = route[i];
    final b = route[i + 1];
    final abLat = b.latitude - a.latitude;
    final abLng = (b.longitude - a.longitude) * cosLat;
    final apLat = driverPos.latitude - a.latitude;
    final apLng = (driverPos.longitude - a.longitude) * cosLat;
    final abLenSq = abLat * abLat + abLng * abLng;

    final double t = abLenSq <= 1e-14
        ? 0.0
        : ((apLat * abLat + apLng * abLng) / abLenSq).clamp(0.0, 1.0);

    final proj = RoadRoutePoint(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
    final dKm = GeoPointUtils.distanceKm(driverPos, proj);
    if (dKm < bestDistKm) {
      bestDistKm = dKm;
      bestSegmentIndex = i;
      bestProjection = proj;
    }
  }

  final isOffRoute = bestDistKm > offRouteThresholdKm;
  final trimmed = <RoadRoutePoint>[driverPos];
  if (!isOffRoute && GeoPointUtils.distanceKm(driverPos, bestProjection) > 0.003) {
    final nextVertex = route[bestSegmentIndex + 1];
    if (GeoPointUtils.distanceKm(bestProjection, nextVertex) > 0.003) {
      trimmed.add(bestProjection);
    }
  }
  trimmed.addAll(
    isOffRoute ? route : route.sublist(bestSegmentIndex + 1),
  );

  return RoadRouteTrimResult(points: trimmed, isOffRoute: isOffRoute);
}

/// Multi-waypoint client OSRM fallback used strictly when the backend route
/// endpoint is temporarily unreachable or returns `isRoadRoute: false`.
class OsrmClientFallback {
  const OsrmClientFallback._();

  static const int _maxCacheEntries = 100;
  static final LinkedHashMap<String, List<RoadRoutePoint>> _lruCache =
      LinkedHashMap<String, List<RoadRoutePoint>>();

  static Future<List<RoadRoutePoint>?> fetchMultiWaypointRoute(
    Dio dio,
    List<RoadRoutePoint> rawWaypoints, {
    CancelToken? cancelToken,
  }) async {
    final waypoints = GeoPointUtils.deduplicateAdjacentWaypoints(rawWaypoints);
    if (waypoints.length < 2) return null;
    if (GeoPointUtils.computeTotalPathMeters(waypoints) < 15.0) return null;

    final key = waypoints.map((p) => p.toCacheSegment(decimals: 5)).join('|');
    final cached = _lruCache.remove(key);
    if (cached != null) {
      _lruCache[key] = cached;
      return cached;
    }

    try {
      final coordStr = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final url =
          'https://router.project-osrm.org/route/v1/driving/$coordStr'
          '?overview=full&geometries=geojson&steps=false&continue_straight=default';
      final response = await dio.get<dynamic>(
        url,
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: const Duration(milliseconds: 2800),
          sendTimeout: const Duration(milliseconds: 2500),
          extra: const {'requiresAuth': false},
        ),
      );
      final data = response.data;
      if (data is! Map || (data['code'] != null && data['code'] != 'Ok')) {
        return null;
      }
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final firstRoute = routes.first;
      if (firstRoute is! Map) return null;
      final geometry = firstRoute['geometry'];
      if (geometry is! Map) return null;
      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) return null;

      final pts = <RoadRoutePoint>[];
      for (final item in coords) {
        if (item is List && item.length >= 2) {
          final lng = (item[0] as num?)?.toDouble();
          final lat = (item[1] as num?)?.toDouble();
          if (lat != null && lng != null) {
            final pt = RoadRoutePoint(lat, lng);
            if (pt.isValid) pts.add(pt);
          }
        }
      }
      if (pts.length < 2) return null;

      if (_lruCache.length >= _maxCacheEntries) {
        _lruCache.remove(_lruCache.keys.first);
      }
      _lruCache[key] = pts;
      return pts;
    } catch (_) {
      return null;
    }
  }

  /// Stores a backend-resolved road route in the shared client cache so any
  /// direct fallback caller benefits too.
  static void primeCache(
    List<RoadRoutePoint> rawWaypoints,
    List<RoadRoutePoint> points,
  ) {
    if (points.length < 2) return;
    final waypoints = GeoPointUtils.deduplicateAdjacentWaypoints(rawWaypoints);
    if (waypoints.length < 2) return;
    final key = waypoints.map((p) => p.toCacheSegment(decimals: 5)).join('|');
    _lruCache.remove(key);
    if (_lruCache.length >= _maxCacheEntries) {
      _lruCache.remove(_lruCache.keys.first);
    }
    _lruCache[key] = List<RoadRoutePoint>.unmodifiable(points);
  }
}
