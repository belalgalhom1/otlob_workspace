import 'dart:convert';
import 'dart:io';

/// Result holding the real road speed limit and its unit.
class RoadSpeedLimit {
  final int speed;
  final String unit; // 'km/h' or 'mph'

  const RoadSpeedLimit({
    required this.speed,
    this.unit = 'km/h',
  });
}

/// Service that queries actual road maxspeed data from OpenStreetMap Overpass.
///
/// Adheres strictly to the requirement:
/// "Use actual available road speed-limit data... Never invent missing speed-limit information."
class SpeedLimitService {
  SpeedLimitService._();
  static final SpeedLimitService instance = SpeedLimitService._();

  final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  // In-memory cache keyed by rounded lat/lng (~110m precision)
  final Map<String, RoadSpeedLimit?> _cache = {};

  String _cacheKey(double lat, double lng) {
    return '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
  }

  /// Fetches real OSM maxspeed around the given coordinate.
  /// Returns null if no maxspeed data is tagged on the road segment.
  Future<RoadSpeedLimit?> getSpeedLimit(double lat, double lng) async {
    if (lat == 0.0 || lng == 0.0) return null;

    final key = _cacheKey(lat, lng);
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final query =
          '[out:json][timeout:3];way(around:35,$lat,$lng)["maxspeed"];out tags;';
      final uri = Uri.parse(
          'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');

      final request = await _client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data is Map && data['elements'] is List) {
          final elements = data['elements'] as List;
          for (final el in elements) {
            final tags = el['tags'];
            if (tags is Map && tags['maxspeed'] != null) {
              final rawSpeed = tags['maxspeed'].toString().trim().toLowerCase();
              final parsed = _parseOsmMaxspeed(rawSpeed);
              if (parsed != null) {
                _cache[key] = parsed;
                return parsed;
              }
            }
          }
        }
      }
    } catch (_) {
      // Graceful fallback on network timeout or offline
    }

    // Do NOT invent fake data if missing
    _cache[key] = null;
    return null;
  }

  RoadSpeedLimit? _parseOsmMaxspeed(String raw) {
    if (raw == 'none' || raw == 'signals' || raw == 'walk' || raw == 'variable') {
      return null;
    }

    final isMph = raw.contains('mph');
    final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
    if (digits == null) return null;

    final speedVal = int.tryParse(digits);
    if (speedVal == null || speedVal <= 0) return null;

    return RoadSpeedLimit(
      speed: speedVal,
      unit: isMph ? 'mph' : 'km/h',
    );
  }
}
