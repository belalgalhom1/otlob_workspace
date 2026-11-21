import 'package:core/core.dart';
import 'package:latlong2/latlong.dart';

/// Parses any backend location representation (`GeoJSON Point`, `{latitude, longitude}`,
/// `{lat, lng}`, or `[lng, lat]` tuple) into a [LatLng].
/// Returns `null` when coordinates are missing, invalid, or `(0, 0)`.
LatLng? extractGeoPoint(dynamic raw) {
  final point = GeoPointUtils.extractPoint(raw);
  if (point == null) return null;
  return LatLng(point.latitude, point.longitude);
}

/// Converts a [LatLng] into a shared [RoadRoutePoint].
RoadRoutePoint toRoadRoutePoint(LatLng point) =>
    RoadRoutePoint(point.latitude, point.longitude);

/// Converts shared [RoadRoutePoint] coordinates into flutter_map [LatLng] points.
List<LatLng> fromRoadRoutePoints(List<RoadRoutePoint> points) => points
    .map((p) => LatLng(p.latitude, p.longitude))
    .toList(growable: false);

/// Converts a list of [LatLng] points into [RoadRoutePoint] coordinates.
List<RoadRoutePoint> toRoadRoutePoints(List<LatLng> points) => points
    .map((p) => RoadRoutePoint(p.latitude, p.longitude))
    .toList(growable: false);

/// Computes great-circle distance in kilometers between two coordinates.
double distanceKmBetween(LatLng a, LatLng b) => GeoPointUtils.distanceKm(
  RoadRoutePoint(a.latitude, a.longitude),
  RoadRoutePoint(b.latitude, b.longitude),
);

/// Computes clockwise bearing in degrees `[0, 360)` from [from] to [to],
/// returning `null` when points are within stationary GPS jitter (< 2m).
double? computeBearingDegrees(LatLng from, LatLng to) =>
    GeoPointUtils.computeBearingDegrees(
      RoadRoutePoint(from.latitude, from.longitude),
      RoadRoutePoint(to.latitude, to.longitude),
    );

/// Fetches a driving road geometry between [from] and [to] via shared OSRM
/// client fallback with LRU caching, returning `null` cleanly on error/timeout.
Future<List<LatLng>?> fetchRoadRoutePoints(
  Dio dio,
  LatLng from,
  LatLng to,
) async {
  final pts = await OsrmClientFallback.fetchMultiWaypointRoute(
    dio,
    [toRoadRoutePoint(from), toRoadRoutePoint(to)],
  );
  if (pts == null || pts.length < 2) return null;
  return fromRoadRoutePoints(pts);
}
