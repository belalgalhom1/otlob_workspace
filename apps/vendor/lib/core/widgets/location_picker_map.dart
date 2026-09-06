import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final List<dynamic>? zones;

  const LocationPickerMap({
    super.key,
    this.initialLocation,
    this.zones,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class ZonePolygonData {
  final String id;
  final String name;
  final List<LatLng> points;

  ZonePolygonData({
    required this.id,
    required this.name,
    required this.points,
  });
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  final List<ZonePolygonData> _parsedZones = [];
  ZonePolygonData? _currentZone;

  // Default to Cairo, Egypt
  final LatLng _defaultLocation = const LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _parseZones();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _currentZone = _findZoneForPoint(_selectedLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  void _parseZones() {
    if (widget.zones == null || widget.zones!.isEmpty) return;

    for (final z in widget.zones!) {
      final id = z['id']?.toString() ?? '';
      final name = z['name']?.toString() ?? '';
      var boundaryData = z['boundary'] ?? z['coordinates'];

      if (boundaryData is Map && boundaryData['coordinates'] != null) {
        boundaryData = boundaryData['coordinates'];
      }

      if (boundaryData is List && boundaryData.isNotEmpty) {
        final ring = boundaryData.first;
        if (ring is List) {
          final points = <LatLng>[];
          for (final pt in ring) {
            if (pt is List && pt.length >= 2) {
              final lng = double.tryParse(pt[0].toString());
              final lat = double.tryParse(pt[1].toString());
              if (lat != null && lng != null) {
                points.add(LatLng(lat, lng));
              }
            }
          }
          if (points.length >= 3) {
            _parsedZones.add(ZonePolygonData(id: id, name: name, points: points));
          }
        }
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].latitude, yi = polygon[i].longitude;
      final xj = polygon[j].latitude, yj = polygon[j].longitude;
      final intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  ZonePolygonData? _findZoneForPoint(LatLng point) {
    for (final z in _parsedZones) {
      if (_isPointInPolygon(point, z.points)) {
        return z;
      }
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
          _currentZone = _findZoneForPoint(latLng);
        });
        _mapController.move(latLng, 15.0);
      }
    } catch (_) {}
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _currentZone = _findZoneForPoint(point);
    });
  }

  LatLng _getInitialCenter() {
    if (_selectedLocation != null) return _selectedLocation!;
    if (_parsedZones.isNotEmpty && _parsedZones.first.points.isNotEmpty) {
      return _parsedZones.first.points.first;
    }
    return _defaultLocation;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pickLocation),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(LucideIcons.check),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _getInitialCenter(),
              initialZoom: 13.0,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.otlob.admin',
              ),
              if (_parsedZones.isNotEmpty)
                PolygonLayer(
                  polygons: _parsedZones.map((z) {
                    final isCurrent = _currentZone?.id == z.id;
                    return Polygon(
                      points: z.points,
                      color: isCurrent
                          ? primaryColor.withValues(alpha: 0.25)
                          : Colors.blue.withValues(alpha: 0.12),
                      borderColor: isCurrent
                          ? primaryColor
                          : Colors.blue.withValues(alpha: 0.6),
                      borderStrokeWidth: isCurrent ? 2.5 : 1.5,
                    );
                  }).toList(),
                ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_selectedLocation != null && _parsedZones.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _currentZone != null
                        ? Colors.black.withValues(alpha: 0.8)
                        : Colors.amber.shade900.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentZone != null
                            ? LucideIcons.mapPin
                            : LucideIcons.alertTriangle,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _currentZone != null
                              ? l10n.insideZone(_currentZone!.name)
                              : l10n.outsideDeliveryZones,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            end: 24,
            bottom: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedLocation == null
                  ? null
                  : () => Navigator.pop(context, _selectedLocation),
              child: Text(
                l10n.done,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          PositionedDirectional(
            start: 24,
            bottom: 90,
            child: FloatingActionButton(
              heroTag: 'locate_fab_admin',
              backgroundColor: primaryColor,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

