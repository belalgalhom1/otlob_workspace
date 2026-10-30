import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Style variants for the redesigned Otlob navigation map.
enum AppMapStyle {
  /// Automatic style switching based on [ThemeData.brightness].
  auto,

  /// Clean, premium light navigation map with soft off-white background,
  /// differentiated road hierarchy, highway coloring, subtle buildings,
  /// pastel parks, and modern typography.
  navigationLight,

  /// Deep, high-contrast dark navigation map with visible road networks,
  /// elegant dark building details, and glowing route lines.
  navigationDark,

  /// Clean OpenStreetMap standard fallback.
  standard,
}

/// A high-performance, beautiful navigation map tile layer for FlutterMap.
///
/// Automatically provides high-DPI (@2x retina) custom-styled vector-raster
/// navigation tiles with subdomains and theme-aware styling.
class AppMapTileLayer extends StatelessWidget {
  final AppMapStyle style;
  final String userAgentPackageName;
  final TileProvider? tileProvider;
  final double maxZoom;
  final double minZoom;

  const AppMapTileLayer({
    super.key,
    this.style = AppMapStyle.auto,
    this.userAgentPackageName = 'com.otlob.app',
    this.tileProvider,
    this.maxZoom = 20.0,
    this.minZoom = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveStyle = style == AppMapStyle.auto
        ? (isDark ? AppMapStyle.navigationDark : AppMapStyle.navigationLight)
        : style;

    final String urlTemplate;
    final List<String> subdomains;

    switch (effectiveStyle) {
      case AppMapStyle.navigationDark:
        // CartoDB Dark Matter Navigation (Premium Dark Vector-Raster Style)
        urlTemplate =
            'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png';
        subdomains = const ['a', 'b', 'c', 'd'];
        break;

      case AppMapStyle.navigationLight:
        // CartoDB Voyager Navigation (Modern Vector-Raster Navigation Style)
        urlTemplate =
            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
        subdomains = const ['a', 'b', 'c', 'd'];
        break;

      case AppMapStyle.standard:
      case AppMapStyle.auto:
        urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        subdomains = const [];
        break;
    }

    return TileLayer(
      urlTemplate: urlTemplate,
      subdomains: subdomains,
      additionalOptions: subdomains.isNotEmpty ? const {'r': '@2x'} : const {},
      userAgentPackageName: userAgentPackageName,
      maxZoom: maxZoom,
      minZoom: minZoom,
      tileProvider: tileProvider,
      panBuffer: 1,
    );
  }
}
