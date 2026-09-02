import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class PolygonPickerMap extends StatefulWidget {
  final List<LatLng>? initialPolygon;

  const PolygonPickerMap({super.key, this.initialPolygon});

  @override
  State<PolygonPickerMap> createState() => _PolygonPickerMapState();
}

class _PolygonPickerMapState extends State<PolygonPickerMap> {
  late MapController _mapController;
  List<LatLng> _polygonPoints = [];
  final LatLng _defaultLocation = const LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialPolygon != null) {
      _polygonPoints = List.from(widget.initialPolygon!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationServicesDisabled,
            ),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionsDenied)),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationPermissionsDeniedPermanent,
            ),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        _mapController.move(latLng, 13.0);
      }
    } catch (e) {
      // Ignore
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _polygonPoints.add(point);
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
      });
    }
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.drawZoneBoundary),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.undo),
            onPressed: _polygonPoints.isNotEmpty ? _undoLastPoint : null,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash),
            onPressed: _polygonPoints.isNotEmpty ? _clearPolygon : null,
          ),
          if (_polygonPoints.length >= 3)
            IconButton(
              icon: const Icon(LucideIcons.check),
              onPressed: () {
                Navigator.pop(context, _polygonPoints);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _polygonPoints.isNotEmpty ? _polygonPoints.first : _defaultLocation,
              initialZoom: 13.0,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.otlob.admin',
              ),
              if (_polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: <Polygon<Object>>[
                    Polygon<Object>(
                      points: _polygonPoints,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      borderColor: Theme.of(context).primaryColor,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              if (_polygonPoints.isNotEmpty)
                MarkerLayer(
                  markers: _polygonPoints.map((p) {
                    return Marker(
                      point: p,
                      width: 12,
                      height: 12,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          PositionedDirectional(
            end: 24,
            bottom: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _polygonPoints.length >= 3
                  ? () => Navigator.pop(context, _polygonPoints)
                  : null,
              child: Text(
                AppLocalizations.of(context)!.confirmBoundary,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          PositionedDirectional(
            start: 24,
            bottom: 24,
            child: FloatingActionButton(
              heroTag: 'locate_fab_zone',
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          PositionedDirectional(
            top: 16,
            start: 16,
            end: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.tapMapToDrawMinimum,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
