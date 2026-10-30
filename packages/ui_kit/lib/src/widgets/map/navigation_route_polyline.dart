import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Helper to generate dual-stroke navigation routes (casing + vibrant foreground)
/// similar to commercial navigation applications (Google Maps / Waze).
class NavigationRoutePolylines {
  /// Builds a list of [Polyline]s that render a professional double-casing route.
  static List<Polyline> build({
    required List<LatLng> points,
    Color foregroundColor = const Color(0xFFF59E0B), // Otlob Primary
    Color? casingColor,
    double strokeWidth = 5.0,
    double casingWidth = 8.5,
  }) {
    if (points.isEmpty) return const [];

    final resolvedCasing = casingColor ?? const Color(0xFF0F172A).withValues(alpha: 0.75);

    return [
      // 1. Outer Casing (Drop Shadow / Border)
      Polyline(
        points: points,
        strokeWidth: casingWidth,
        color: resolvedCasing,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
      // 2. Vibrant Foreground Navigation Line
      Polyline(
        points: points,
        strokeWidth: strokeWidth,
        color: foregroundColor,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    ];
  }
}
