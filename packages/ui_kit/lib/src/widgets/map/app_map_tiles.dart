import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Style variants for the redesigned Otlob navigation map.
enum AppMapStyle {
  /// Default style that always resolves to the crisp white/light navigation map
  /// across all apps regardless of app light/dark theme.
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

class _SharedNetworkTileProvider extends NetworkTileProvider {
  _SharedNetworkTileProvider() : super(silenceExceptions: true);

  // Shared across map rebuilds and screen transitions so HTTP/TLS keep-alive
  // sockets remain warm; TileLayer.dispose() must not close the shared pool.
  @override
  Future<void> dispose() async {}
}

/// A high-performance, beautiful navigation map tile layer for FlutterMap.
///
/// Automatically provides high-DPI (@2x on dense displays, 1x on 1x displays)
/// vector-raster navigation tiles with subdomains, throttled pan updates,
/// shared keep-alive connections, and repaint-isolated light canvas rendering.
class AppMapTileLayer extends StatefulWidget {
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
  State<AppMapTileLayer> createState() => _AppMapTileLayerState();
}

class _AppMapTileLayerState extends State<AppMapTileLayer> {
  static final Map<String, _SharedNetworkTileProvider> _sharedProviders = {};

  static _SharedNetworkTileProvider _getSharedProvider(String packageName) {
    return _sharedProviders.putIfAbsent(
      packageName,
      _SharedNetworkTileProvider.new,
    );
  }

  // Owned per mounted tile layer instance to throttle continuous pan/fling
  // tile-range & prune work (~12Hz) with zero leaked timers while letting
  // gesture-end and programmatic camera events settle immediately.
  late final TileUpdateTransformer _tileUpdateTransformer =
      _createSmoothTileUpdateTransformer();

  static TileUpdateTransformer _createSmoothTileUpdateTransformer() {
    DateTime? lastContinuousEmit;
    return TileUpdateTransformer.fromHandlers(
      handleData: (event, sink) {
        if (event.wasTriggeredByTap()) return;

        final mapEvent = event.mapEvent;
        final source = mapEvent.source;
        final isContinuousGesture =
            mapEvent is MapEventWithMove &&
            (source == MapEventSource.onDrag ||
                source == MapEventSource.onMultiFinger ||
                source == MapEventSource.flingAnimationController ||
                source == MapEventSource.doubleTapZoomAnimationController ||
                source == MapEventSource.scrollWheel);

        if (!isContinuousGesture) {
          lastContinuousEmit = DateTime.now();
          sink.add(event);
          return;
        }

        final now = DateTime.now();
        if (lastContinuousEmit == null ||
            now.difference(lastContinuousEmit!) >=
                const Duration(milliseconds: 80)) {
          lastContinuousEmit = now;
          sink.add(event);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style == AppMapStyle.auto
        ? AppMapStyle.navigationLight
        : widget.style;

    final resolvedKey = widget.apiKey ?? AppMapTileLayer.defaultCartoApiKey;
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
    final needsDarkFilter = effectiveStyle == AppMapStyle.navigationDark;

    final TileBuilder? effectiveTileBuilder;
    if (widget.tileBuilder != null) {
      effectiveTileBuilder = widget.tileBuilder;
    } else if (needsDarkFilter) {
      final matrix = isOsmTile
          ? AppMapTileLayer.osmDarkInversionMatrix
          : AppMapTileLayer.darkWhiteTextMatrix;
      effectiveTileBuilder = (context, tileWidget, tile) {
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(matrix),
          child: tileWidget,
        );
      };
    } else {
      effectiveTileBuilder = null;
    }

    // Only request server @2x tiles on high-DPI displays and only when `{r}`
    // exists in the URL template (so OSM never triggers 4x simulated zoom requests).
    final isHighDensity = MediaQuery.devicePixelRatioOf(context) > 1.0;
    final useServerRetina = urlTemplate.contains('{r}') && isHighDensity;

    final tileLayer = TileLayer(
      urlTemplate: urlTemplate,
      subdomains: subdomains,
      retinaMode: useServerRetina,
      userAgentPackageName: widget.userAgentPackageName,
      maxZoom: widget.maxZoom,
      minZoom: widget.minZoom,
      tileProvider: widget.tileProvider ?? _getSharedProvider(widget.userAgentPackageName),
      tileBuilder: effectiveTileBuilder,
      tileUpdateTransformer: _tileUpdateTransformer,
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
      panBuffer: 1,
      keepBuffer: 2,
    );

    if (effectiveStyle == AppMapStyle.navigationDark) {
      return RepaintBoundary(child: tileLayer);
    }
    return RepaintBoundary(
      child: ColoredBox(color: Colors.white, child: tileLayer),
    );
  }
}
