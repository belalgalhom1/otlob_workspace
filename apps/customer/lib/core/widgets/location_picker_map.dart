import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerMap({super.key, this.initialLocation});

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  // Default to Cairo, Egypt
  final LatLng _defaultLocation = const LatLng(30.0444, 31.2357);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _hasSearched = false;
  Timer? _searchDebounce;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  /// Live place search (OpenStreetMap Nominatim, Egypt-biased): results
  /// refresh automatically for anything typed (3+ chars), no submit needed.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _searching = false;
        _hasSearched = false;
      });
      return;
    }
    // Instant UI feedback (spinner + clear button) while debouncing.
    setState(() {
      _searching = true;
      _hasSearched = false;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _searching = true);
    try {
      final res = await Dio()
          .get(
            'https://nominatim.openstreetmap.org/search',
            queryParameters: {
              'q': query,
              'format': 'jsonv2',
              'limit': 6,
              'countrycodes': 'eg',
              'accept-language': _isAr ? 'ar' : 'en',
              'addressdetails': 1,
            },
            options: Options(
              headers: {'User-Agent': 'otlob-customer-app/1.0'},
            ),
          )
          .timeout(const Duration(seconds: 10));
      final list = ((res.data as List?) ?? [])
          .whereType<Map>()
          .map((e) => {
                'name': e['display_name']?.toString() ?? query,
                'lat': double.tryParse(e['lat']?.toString() ?? ''),
                'lng': double.tryParse(e['lon']?.toString() ?? ''),
              })
          .where((e) => e['lat'] != null && e['lng'] != null)
          .toList();
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(list);
          _searching = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searching = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _pickSearchResult(Map<String, dynamic> place) {
    final point = LatLng(
      (place['lat'] as num).toDouble(),
      (place['lng'] as num).toDouble(),
    );
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = point;
      _searchResults = [];
      _hasSearched = false;
      _searchController.clear();
    });
    _mapController.move(point, 15.0);
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    final isAr = _isAr;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr
                ? 'خدمات الموقع متوقفة. يرجى تفعيلها من الإعدادات.'
                : 'Location services are disabled. Please enable them in settings.'),
          ),
        );
      }
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr
                  ? 'تم رفض إذن الموقع.'
                  : 'Location permissions are denied.'),
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr
                ? 'إذن الموقع مرفوض نهائياً، يرجى تفعيله من إعدادات التطبيق.'
                : 'Location permissions are permanently denied, please enable them in app settings.'),
          ),
        );
      }
      await Geolocator.openAppSettings();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown == null) throw TimeoutException('location');
          return lastKnown;
        },
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
        });
        _mapController.move(latLng, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAr
                ? 'تعذر تحديد الموقع. حرك الخريطة واختر يدوياً.'
                : 'Could not fetch location: $e'),
          ),
        );
      }
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAr ? 'اختر الموقع' : 'Pick Location'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(LucideIcons.check),
              tooltip: _isAr ? 'تأكيد' : 'Confirm',
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _defaultLocation,
              initialZoom: 13.0,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.otlob.customer',
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
          // Place search overlay.
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      _searchDebounce?.cancel();
                      final query = value.trim();
                      if (query.length >= 3) {
                        setState(() {
                          _searching = true;
                          _hasSearched = false;
                        });
                        _searchPlaces(query);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _isAr
                          ? 'ابحث عن مكان... (٣ أحرف على الأقل)'
                          : 'Search for a place... (min 3 chars)',
                      prefixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _hasSearched = false;
                                });
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty ||
                    (_hasSearched &&
                        !_searching &&
                        _searchController.text.trim().length >= 3))
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _searchResults.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Text(
                              _isAr
                                  ? 'لا توجد أماكن مطابقة'
                                  : 'No places found',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final place = _searchResults[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                          ),
                          title: Text(
                            place['name'].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => _pickSearchResult(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 24 + bottomInset,
            left: 24,
            right: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedLocation == null
                  ? null
                  : () => Navigator.pop(context, _selectedLocation),
              child: Text(
                _isAr ? 'تأكيد الموقع' : 'Confirm Location',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 96 + bottomInset,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'locate_fab',
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
