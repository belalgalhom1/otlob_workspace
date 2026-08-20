import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:dio/dio.dart';

class ZoneEditScreen extends ConsumerStatefulWidget {
  final dynamic zone;

  const ZoneEditScreen({super.key, this.zone});

  @override
  ConsumerState<ZoneEditScreen> createState() => _ZoneEditScreenState();
}

class _ZoneEditScreenState extends ConsumerState<ZoneEditScreen> {
  final MapController _mapController = MapController();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _baseDeliveryFeeController;
  late TextEditingController _minOrderAmountController;
  bool _isActive = true;
  
  final List<LatLng> _polygonPoints = [];
  bool _isLoading = false;
  bool _isMapStep = true;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone?['name'] ?? '');
    _nameArController = TextEditingController(text: widget.zone?['nameAr'] ?? '');
    _baseDeliveryFeeController = TextEditingController(
        text: widget.zone?['baseDeliveryFeeOverride']?.toString() ?? '');
    _minOrderAmountController = TextEditingController(
        text: widget.zone?['minOrderAmountOverride']?.toString() ?? '');
    _isActive = widget.zone?['isActive'] ?? true;

    if (widget.zone != null) {
      try {
        var boundaryData = widget.zone['boundary'] ?? widget.zone['coordinates'];
        
        // Handle GeoJSON Map format
        if (boundaryData is Map && boundaryData['coordinates'] != null) {
          boundaryData = boundaryData['coordinates'];
        }

        if (boundaryData is List && boundaryData.isNotEmpty) {
          final linearRing = boundaryData.first;
          if (linearRing is List) {
            for (var point in linearRing) {
              if (point is List && point.length >= 2) {
                // GeoJSON is [lng, lat]
                _polygonPoints.add(LatLng(
                  (point[1] as num).toDouble(),
                  (point[0] as num).toDouble(),
                ));
              }
            }

            // Remove the last point if it closes the polygon (same as first),
            // so we don't double up when drawing/editing.
            if (_polygonPoints.length > 3 &&
                _polygonPoints.first.latitude == _polygonPoints.last.latitude &&
                _polygonPoints.first.longitude == _polygonPoints.last.longitude) {
              _polygonPoints.removeLast();
            }
          }
        }
      } catch (e) {
        // Handle parsing errors safely
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _nameArController.dispose();
    _baseDeliveryFeeController.dispose();
    _minOrderAmountController.dispose();
    super.dispose();
  }

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _polygonPoints.add(latlng);
    });
  }

  void _undoPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
      });
    }
  }

  void _resetPolygon() {
    setState(() {
      _polygonPoints.clear();
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
        },
        options: Options(headers: {
          'User-Agent': 'OtlobVendorApp/1.0',
        }),
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _searchResults = response.data as List<dynamic>;
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchLocation(query);
    });
    // Trigger rebuild to show/hide the clear icon
    setState(() {});
  }

  Future<void> _saveZone() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tapMapToDrawMinimum),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Close the polygon for backend (first point == last point)
      List<List<double>> ring = _polygonPoints.map((p) => [p.longitude, p.latitude]).toList();
      ring.add([_polygonPoints.first.longitude, _polygonPoints.first.latitude]);
      
      final polygon = [ring];

      final zoneData = {
        'name': _nameController.text,
        'nameAr': _nameArController.text.isNotEmpty ? _nameArController.text : _nameController.text,
        'isActive': _isActive,
        'boundary': polygon,
      };

      if (_baseDeliveryFeeController.text.isNotEmpty) {
        zoneData['baseDeliveryFeeOverride'] = double.parse(_baseDeliveryFeeController.text);
      }
      if (_minOrderAmountController.text.isNotEmpty) {
        zoneData['minOrderAmountOverride'] = double.parse(_minOrderAmountController.text);
      }

      final notifier = ref.read(zoneProvider.notifier);
      
      if (widget.zone == null) {
        await notifier.createZone(zoneData);
      } else {
        await notifier.updateZone(widget.zone['id'], zoneData);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorSavingZone(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildMapStep() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _polygonPoints.isNotEmpty ? _polygonPoints.first : const LatLng(30.0444, 31.2357), // Default Cairo
            initialZoom: _polygonPoints.isNotEmpty ? 14 : 12,
            onTap: _handleTap,
            onMapReady: () {
              if (_polygonPoints.isNotEmpty) {
                final bounds = LatLngBounds.fromPoints(_polygonPoints);
                _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.otlob.vendor',
            ),
            if (_polygonPoints.isNotEmpty)
              PolygonLayer(
                polygons: <Polygon<Object>>[
                  Polygon<Object>(
                    points: _polygonPoints,
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            if (_polygonPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polygonPoints,
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), blurRadius: 10),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    prefixIcon: const Icon(LucideIcons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _searchLocation,
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), blurRadius: 10),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(LucideIcons.mapPin, size: 20),
                          title: Text(
                            result['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () {
                            final lat = double.tryParse(result['lat'].toString()) ?? 0;
                            final lon = double.tryParse(result['lon'].toString()) ?? 0;
                            if (lat != 0 && lon != 0) {
                              _mapController.move(LatLng(lat, lon), 14);
                            }
                            setState(() {
                              _searchResults.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 100, // Moved up to make room for Done button
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _undoPoint,
                  icon: const Icon(LucideIcons.undo),
                  tooltip: 'Undo',
                ),
                IconButton(
                  onPressed: _resetPolygon,
                  icon: const Icon(LucideIcons.rotateCcw),
                  tooltip: 'Reset',
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _polygonPoints.length >= 3
                  ? () {
                      setState(() {
                        _isMapStep = false;
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.done,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 600, // Limits width on desktop/tablet, takes full width on mobile
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.generalInformation,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: AppLocalizations.of(context)!.nameEn,
                  controller: _nameController,
                  validator: (val) => val == null || val.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: AppLocalizations.of(context)!.nameAr,
                  controller: _nameArController,
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.active),
                    value: _isActive,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const Divider(height: 48),
                Text(
                  AppLocalizations.of(context)!.overridesOptional,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: AppLocalizations.of(context)!.baseFeeOverride,
                  controller: _baseDeliveryFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: AppLocalizations.of(context)!.minOrderOverride,
                  controller: _minOrderAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveZone,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Text(
                          AppLocalizations.of(context)!.save,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.zone != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.editZone : AppLocalizations.of(context)!.createZone),
        leading: _isMapStep
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isMapStep = true;
                  });
                },
              ),
      ),
      body: _isMapStep ? _buildMapStep() : _buildFormStep(),
    );
  }
}
