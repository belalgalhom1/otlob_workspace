import 'dart:collection';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

const Distance _geodesic = Distance();

/// Parses coordinate payloads returned across Otlob APIs and sockets:
/// - `[lng, lat]` GeoJSON coordinate pairs
/// - `{ coordinates: [lng, lat] }`
/// - `{ latitude, longitude }` or `{ lat, lng }`
LatLng? extractGeoPoint(dynamic raw) {
  if (raw == null) return null;

  if (raw is List && raw.length >= 2) {
    final lng = double.tryParse(raw[0].toString());
    final lat = double.tryParse(raw[1].toString());
    return _validLatLng(lat, lng);
  }

  if (raw is Map) {
    if (raw['coordinates'] is List) {
      return extractGeoPoint(raw['coordinates']);
    }
    final lat = double.tryParse((raw['latitude'] ?? raw['lat']).toString());
    final lng = double.tryParse((raw['longitude'] ?? raw['lng']).toString());
    return _validLatLng(lat, lng);
  }

  return null;
}

LatLng? _validLatLng(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  if (!lat.isFinite || !lng.isFinite) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  if (lat == 0.0 && lng == 0.0) return null;
  return LatLng(lat, lng);
}

/// Computes great-circle distance in kilometers between [a] and [b] with
/// meter-level precision (avoiding `latlong2`'s integer kilometer truncation).
double distanceKmBetween(LatLng a, LatLng b) {
  return _geodesic.as(LengthUnit.Meter, a, b) / 1000.0;
}

/// Computes compass bearing in degrees [0, 360) when the segment length is
/// meaningful (> 3 meters); returns `null` for stationary jitter.
double? computeBearingDegrees(LatLng from, LatLng to) {
  if (_geodesic.as(LengthUnit.Meter, from, to) < 3.0) {
    return null;
  }
  final lat1 = from.latitude * math.pi / 180.0;
  final lat2 = to.latitude * math.pi / 180.0;
  final dLon = (to.longitude - from.longitude) * math.pi / 180.0;
  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final deg = math.atan2(y, x) * 180.0 / math.pi;
  return (deg + 360.0) % 360.0;
}

final LinkedHashMap<String, List<LatLng>> _roadRouteCache =
    LinkedHashMap<String, List<LatLng>>();
const int _maxCachedRoutes = 40;

String _routeCacheKey(LatLng from, LatLng to) =>
    '${from.latitude.toStringAsFixed(4)},${from.longitude.toStringAsFixed(4)}->'
    '${to.latitude.toStringAsFixed(4)},${to.longitude.toStringAsFixed(4)}';

/// Best-effort road route geometry lookup using OSRM driving directions.
/// Never fabricates ETAs and gracefully returns `null` on timeout/failure so the
/// UI can render straight-line route segments immediately without blocking.
Future<List<LatLng>?> fetchRoadRoutePoints(
  Dio dio,
  LatLng from,
  LatLng to,
) async {
  final key = _routeCacheKey(from, to);
  final cached = _roadRouteCache[key];
  if (cached != null && cached.isNotEmpty) {
    // Refresh LRU order.
    _roadRouteCache.remove(key);
    _roadRouteCache[key] = cached;
    return cached;
  }

  try {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson';

    final response = await dio.get<dynamic>(
      url,
      options: Options(
        receiveTimeout: const Duration(milliseconds: 2500),
        sendTimeout: const Duration(milliseconds: 2500),
        extra: const {'requiresAuth': false},
      ),
    );

    final data = response.data;
    if (data is! Map) return null;
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final geometry = routes.first is Map
        ? (routes.first as Map)['geometry']
        : null;
    final coords = geometry is Map ? geometry['coordinates'] : null;
    if (coords is! List || coords.length < 2) return null;

    final points = <LatLng>[];
    for (final item in coords) {
      final pt = extractGeoPoint(item);
      if (pt != null) points.add(pt);
    }
    if (points.length < 2) return null;

    if (_roadRouteCache.length >= _maxCachedRoutes) {
      _roadRouteCache.remove(_roadRouteCache.keys.first);
    }
    _roadRouteCache[key] = points;
    return points;
  } catch (_) {
    return null;
  }
}
