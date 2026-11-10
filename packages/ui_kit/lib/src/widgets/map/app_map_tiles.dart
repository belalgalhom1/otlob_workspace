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

  /// Optional CARTO API key. When omitted or empty, clean OpenStreetMap tiles
  /// are served to avoid the "API KEY REQUIRED" watermark.
  final String? apiKey;

  /// Global default CARTO API key configured across all applications.
  static String? defaultCartoApiKey = 'cb1_4ypn_1_415291f018422807fa2ba7a8';

  /// High-contrast color matrix applied to CartoDB Dark Matter tiles in dark mode.
  ///
  /// Strongly boosts the luminance of city names, street labels, and district titles
  /// to pure crisp white (#FFFFFF) while keeping the dark background deeply dark.
  static const List<double> darkWhiteTextMatrix = <double>[
    4.8, 0.0, 0.0, 0.0, -78.0, // R
    0.0, 4.8, 0.0, 0.0, -78.0, // G
    0.0, 0.0, 4.8, 0.0, -78.0, // B
    0.0, 0.0, 0.0, 1.0, 0.0,   // A
  ];

  /// High-contrast dark inversion matrix used when falling back to standard OpenStreetMap.
  ///
  /// Inverts dark text labels (city names, countries, towns, streets) into pure
  /// crisp white (#FFFFFF) with smooth anti-aliased readability, while turning
  /// the daytime background into an elegant dark slate, water into deep navy,
  /// and preserving distinct road networks.
  static const List<double> osmDarkInversionMatrix = <double>[
    0.832, -2.074, -0.209, 0.0, 365.0,
    -0.618, -0.624, -0.209, 0.0, 365.0,
    -0.618, -2.074, 1.241, 0.0, 365.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  final TileBuilder? tileBuilder;

  const AppMapTileLayer({
    super.key,
    this.style = AppMapStyle.auto,
    this.userAgentPackageName = 'com.otlob.app',
    this.tileProvider,
    this.maxZoom = 20.0,
    this.minZoom = 2.0,
    this.apiKey,
    this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveStyle = style == AppMapStyle.auto
        ? (isDark ? AppMapStyle.navigationDark : AppMapStyle.navigationLight)
        : style;

    final resolvedKey = apiKey ?? defaultCartoApiKey;
    final hasKey = resolvedKey != null && resolvedKey.trim().isNotEmpty;
    final keyQuery = hasKey ? '?key=${resolvedKey.trim()}' : '';

    final String urlTemplate;
    final List<String> subdomains;

    switch (effectiveStyle) {
      case AppMapStyle.navigationDark:
        // Use CartoDB Dark Matter only if an API key is present; otherwise
        // fallback to standard OpenStreetMap to prevent the watermark.
        if (hasKey) {
          urlTemplate =
              'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png$keyQuery';
          subdomains = const ['a', 'b', 'c', 'd'];
        } else {
          urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
          subdomains = const [];
        }
        break;

      case AppMapStyle.navigationLight:
        if (hasKey) {
          urlTemplate =
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png$keyQuery';
          subdomains = const ['a', 'b', 'c', 'd'];
        } else {
          urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
          subdomains = const [];
        }
        break;

      case AppMapStyle.standard:
      case AppMapStyle.auto:
        urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        subdomains = const [];
        break;
    }

    final isOsmTile = urlTemplate.contains('openstreetmap.org');
    final needsDarkFilter = isDark &&
        (effectiveStyle == AppMapStyle.navigationDark ||
            effectiveStyle == AppMapStyle.standard);

    final TileBuilder? effectiveTileBuilder;
    if (tileBuilder != null) {
      effectiveTileBuilder = tileBuilder;
    } else if (needsDarkFilter) {
      final matrix = isOsmTile ? osmDarkInversionMatrix : darkWhiteTextMatrix;
      effectiveTileBuilder = (context, tileWidget, tile) {
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(matrix),
          child: tileWidget,
        );
      };
    } else {
      effectiveTileBuilder = null;
    }

    return TileLayer(
      urlTemplate: urlTemplate,
      subdomains: subdomains,
      additionalOptions: subdomains.isNotEmpty ? const {'r': '@2x'} : const {},
      userAgentPackageName: userAgentPackageName,
      maxZoom: maxZoom,
      minZoom: minZoom,
      tileProvider: tileProvider,
      tileBuilder: effectiveTileBuilder,
      panBuffer: 1,
    );
  }
}
