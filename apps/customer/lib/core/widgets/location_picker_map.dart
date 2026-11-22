import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart' hide AppColors;

import '../../features/home/presentation/widgets/special_delivery_tokens.dart';
import '../../features/profile/presentation/providers/profile_controller.dart';

class LocationPickerMap extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  final String? title;
  final ValueChanged<String>? onAddressResolved;

  const LocationPickerMap({
    super.key,
    this.initialLocation,
    this.title,
    this.onAddressResolved,
  });

  @override
  ConsumerState<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends ConsumerState<LocationPickerMap>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _pulseController;
  LatLng? _selectedLocation;
  String? _resolvedAddress;
  bool _isResolvingAddress = false;

  // Default map center (Cairo, Egypt) when no initial coordinate is provided yet
  final LatLng _defaultLocation = const LatLng(30.0444, 31.2357);

  final TextEditingController _searchController = TextEditingController();
  final Dio _nominatimDio = Dio();
  CancelToken? _searchCancelToken;
  CancelToken? _reverseCancelToken;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _hasSearched = false;
  Timer? _searchDebounce;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  void _showToast(String message) {
    if (!mounted) return;
    final palette = SpecialDeliveryPalette.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(
              color: SpecialDeliveryTokens.gold,
              width: 1,
            ),
          ),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: SpecialDeliveryTokens.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: SpecialDeliveryTokens.text(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// Live place search (OpenStreetMap Nominatim, Egypt-biased): results
  /// refresh automatically for anything typed (3+ chars), no submit needed.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('new_query');
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _searching = false;
        _hasSearched = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _hasSearched = false;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    _searchCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;
    setState(() => _searching = true);
    try {
      final res = await _nominatimDio
          .get(
            'https://nominatim.openstreetmap.org/search',
            cancelToken: cancelToken,
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
      if (cancelToken.isCancelled) return;
      final list = ((res.data as List?) ?? [])
          .whereType<Map>()
          .map(
            (e) => {
              'name': e['display_name']?.toString() ?? query,
              'lat': double.tryParse(e['lat']?.toString() ?? ''),
              'lng': double.tryParse(e['lon']?.toString() ?? ''),
            },
          )
          .where((e) => e['lat'] != null && e['lng'] != null)
          .toList();
      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(list);
          _searching = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searching = false;
          _hasSearched = true;
        });
      }
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    _reverseCancelToken?.cancel('new_point');
    final cancelToken = CancelToken();
    _reverseCancelToken = cancelToken;
    if (mounted) {
      setState(() => _isResolvingAddress = true);
    }
    try {
      final res = await _nominatimDio
          .get(
            'https://nominatim.openstreetmap.org/reverse',
            cancelToken: cancelToken,
            queryParameters: {
              'lat': point.latitude,
              'lon': point.longitude,
              'format': 'jsonv2',
              'accept-language': _isAr ? 'ar' : 'en',
            },
            options: Options(
              headers: {'User-Agent': 'otlob-customer-app/1.0'},
            ),
          )
          .timeout(const Duration(seconds: 6));
      if (cancelToken.isCancelled || !mounted) return;
      final data = res.data;
      String? resolved;
      if (data is Map) {
        final addr = data['address'];
        if (addr is Map) {
          final parts = <String>[
            for (final k in const [
              'road',
              'neighbourhood',
              'suburb',
              'city',
              'town',
              'state',
            ])
              if (addr[k] != null && addr[k].toString().trim().isNotEmpty)
                addr[k].toString().trim(),
          ];
          if (parts.isNotEmpty) {
            resolved = parts.take(2).join('، ');
          }
        }
        resolved ??= data['display_name']?.toString();
      }
      if (mounted) {
        setState(() {
          _resolvedAddress = resolved;
          _isResolvingAddress = false;
        });
      }
    } catch (_) {
      if (mounted && !cancelToken.isCancelled) {
        setState(() => _isResolvingAddress = false);
      }
    }
  }

  void _pickSearchResult(Map<String, dynamic> place) {
    final point = LatLng(
      (place['lat'] as num).toDouble(),
      (place['lng'] as num).toDouble(),
    );
    final name = place['name']?.toString();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = point;
      _resolvedAddress = name;
      _isResolvingAddress = false;
      _searchResults = [];
      _hasSearched = false;
      _searchController.clear();
    });
    _mapController.move(point, 15.0);
  }

  LatLng? _extractAddressCoords(Map<String, dynamic> addr) {
    final loc = addr['location'];
    if (loc is List && loc.length == 2) {
      final lng = (loc[0] as num?)?.toDouble();
      final lat = (loc[1] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(lat, lng);
    } else if (loc is Map && loc['coordinates'] is List) {
      final coords = loc['coordinates'] as List;
      if (coords.length == 2) {
        final lng = (coords[0] as num?)?.toDouble();
        final lat = (coords[1] as num?)?.toDouble();
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    }
    final lat = (addr['lat'] as num?)?.toDouble();
    final lng = (addr['lng'] as num?)?.toDouble();
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  void _pickSavedAddress(Map<String, dynamic> addr, LatLng point) {
    FocusScope.of(context).unfocus();
    final display = (addr['address']?.toString().trim().isNotEmpty == true)
        ? addr['address'].toString().trim()
        : (addr['label']?.toString().trim() ?? '');
    setState(() {
      _selectedLocation = point;
      _resolvedAddress = display.isNotEmpty ? display : null;
      _isResolvingAddress = false;
      _searchResults = [];
      _hasSearched = false;
    });
    _mapController.move(point, 15.5);
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _selectedLocation = widget.initialLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedLocation == null) {
        _getCurrentLocation();
      } else {
        _reverseGeocode(_selectedLocation!);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    final isAr = _isAr;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showToast(
        isAr
            ? 'خدمات الموقع متوقفة. يرجى تفعيلها من الإعدادات.'
            : 'Location services are disabled. Please enable them in settings.',
      );
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showToast(
          isAr ? 'تم رفض إذن الموقع.' : 'Location permissions are denied.',
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showToast(
        isAr
            ? 'إذن الموقع مرفوض نهائياً، يرجى تفعيله من إعدادات التطبيق.'
            : 'Location permissions are permanently denied, please enable them in app settings.',
      );
      await Geolocator.openAppSettings();
      return;
    }

    try {
      final position =
          await Geolocator.getCurrentPosition(
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
          _resolvedAddress = null;
        });
        _mapController.move(latLng, 15.0);
        _reverseGeocode(latLng);
      }
    } catch (e) {
      _showToast(
        _isAr
            ? 'تعذر تحديد الموقع. حرك الخريطة واختر يدوياً.'
            : 'Could not fetch location: $e',
      );
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = point;
      _resolvedAddress = null;
      _searchResults = [];
      _hasSearched = false;
    });
    _reverseGeocode(point);
  }

  void _confirmSelection() {
    if (_selectedLocation == null) return;
    if (_resolvedAddress != null && _resolvedAddress!.trim().isNotEmpty) {
      widget.onAddressResolved?.call(_resolvedAddress!.trim());
    }
    Navigator.pop(context, _selectedLocation);
  }

  String _formatCoordinateLabel(LatLng loc) {
    return '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}';
  }

  @override
  void dispose() {
    _searchCancelToken?.cancel('disposed');
    _reverseCancelToken?.cancel('disposed');
    _nominatimDio.close(force: true);
    _mapController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SpecialDeliveryPalette.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final savedAddresses = ref.watch(
      profileProvider.select((p) => p.addresses),
    );
    final usableSaved = savedAddresses
        .map((a) => (addr: a, coords: _extractAddressCoords(a)))
        .where((e) => e.coords != null)
        .toList(growable: false);

    final selectedLabel = _resolvedAddress?.trim().isNotEmpty == true
        ? _resolvedAddress!.trim()
        : (_selectedLocation != null
              ? _formatCoordinateLabel(_selectedLocation!)
              : (_isAr ? 'اضغط على الخريطة لتحديد الموقع' : 'Tap map to pick a location'));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: palette.bgMain,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 52px Themed Header
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: palette.headerBg,
                  border: Border(
                    bottom: BorderSide(color: palette.headerBorder, width: 1),
                  ),
                  boxShadow: [palette.headerShadow],
                ),
                child: Row(
                  children: [
                    TactileScaleTap(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.surfaceBorder),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.title ?? (_isAr ? 'اختر الموقع' : 'Pick Location'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SpecialDeliveryTokens.text(
                          size: 15,
                          weight: FontWeight.w900,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    TactileScaleTap(
                      onTap: _selectedLocation == null ? null : _confirmSelection,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _selectedLocation != null
                              ? palette.selectedTint
                              : palette.disabledBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedLocation != null
                                ? SpecialDeliveryTokens.gold
                                : palette.surfaceBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.check,
                          size: 17,
                          color: _selectedLocation != null
                              ? palette.goldText
                              : palette.disabledText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Map & Floating Controls
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ?? _defaultLocation,
                        initialZoom: 14.0,
                        onTap: _onTap,
                      ),
                      children: [
                        const AppMapTileLayer(
                          userAgentPackageName: 'com.otlob.customer',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 190,
                                height: 92,
                                alignment: Alignment.bottomCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Floating address tooltip
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 184,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: SpecialDeliveryTokens.gold,
                                          width: 1,
                                        ),
                                        boxShadow: [palette.surfaceShadow],
                                      ),
                                      child: Text(
                                        _isResolvingAddress
                                            ? (_isAr ? 'جاري تحديد العنوان...' : 'Resolving...')
                                            : selectedLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: SpecialDeliveryTokens.text(
                                          size: 9.5,
                                          weight: FontWeight.w800,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Pulsing Gold-Bordered Pin
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AnimatedBuilder(
                                            animation: _pulseController,
                                            builder: (context, _) {
                                              final t = _pulseController.value;
                                              return Transform.scale(
                                                scale: 0.7 + (t * 0.75),
                                                child: Opacity(
                                                  opacity: (1.0 - t).clamp(0.0, 1.0),
                                                  child: Container(
                                                    width: 34,
                                                    height: 34,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: palette.pinHaloColor,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: SpecialDeliveryTokens.gold,
                                              border: Border.all(
                                                color: palette.surface,
                                                width: 2.5,
                                              ),
                                              boxShadow: [palette.surfaceShadow],
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              size: 16,
                                              color: SpecialDeliveryTokens.darkOnGold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Floating Top Overlay: Search Input + Real Saved Address Pills
                    Positioned(
                      top: 12,
                      left: 14,
                      right: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.surfaceBorder),
                              boxShadow: [palette.surfaceShadow],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              cursorColor: SpecialDeliveryTokens.gold,
                              style: SpecialDeliveryTokens.text(
                                size: 12,
                                weight: FontWeight.w600,
                                color: palette.textPrimary,
                              ),
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
                                isDense: true,
                                hintText: _isAr
                                    ? 'ابحث عن مكان... (٣ أحرف على الأقل)'
                                    : 'Search for a place... (min 3 chars)',
                                hintStyle: SpecialDeliveryTokens.text(
                                  size: 11.5,
                                  weight: FontWeight.w500,
                                  color: palette.textMuted,
                                ),
                                prefixIcon: _searching
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: SpecialDeliveryTokens.gold,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        LucideIcons.search,
                                        size: 16,
                                        color: palette.goldText,
                                      ),
                                suffixIcon: _searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: palette.textMuted,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults = [];
                                            _hasSearched = false;
                                          });
                                        },
                                      ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),

                          // Saved Addresses Row (strictly only when backend returns saved addresses)
                          if (usableSaved.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 30,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: usableSaved.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, i) {
                                  final entry = usableSaved[i];
                                  final label =
                                      entry.addr['label']?.toString().trim();
                                  final address =
                                      entry.addr['address']?.toString().trim();
                                  final pillText =
                                      (label != null && label.isNotEmpty)
                                      ? label
                                      : (address ?? '');
                                  return TactileScaleTap(
                                    onTap: () => _pickSavedAddress(
                                      entry.addr,
                                      entry.coords!,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.surface,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: palette.surfaceBorder,
                                        ),
                                        boxShadow: [palette.surfaceShadow],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bookmark_rounded,
                                            size: 12,
                                            color: palette.goldText,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            pillText,
                                            style: SpecialDeliveryTokens.text(
                                              size: 10.5,
                                              weight: FontWeight.w800,
                                              color: palette.textPrimary,
                                              height: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          // Autocomplete Dropdown
                          if (_searchResults.isNotEmpty ||
                              (_hasSearched &&
                                  !_searching &&
                                  _searchController.text.trim().length >= 3))
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              constraints: const BoxConstraints(maxHeight: 210),
                              decoration: BoxDecoration(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: palette.surfaceBorder,
                                ),
                                boxShadow: [palette.surfaceShadow],
                              ),
                              child: _searchResults.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        _isAr
                                            ? 'لا توجد أماكن مطابقة'
                                            : 'No places found',
                                        style: SpecialDeliveryTokens.text(
                                          size: 12,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: _searchResults.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: palette.headerBorder,
                                      ),
                                      itemBuilder: (context, i) {
                                        final place = _searchResults[i];
                                        return ListTile(
                                          dense: true,
                                          leading: Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                            color: palette.goldText,
                                          ),
                                          title: Text(
                                            place['name'].toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: SpecialDeliveryTokens.text(
                                              size: 11.5,
                                              weight: FontWeight.w600,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          onTap: () => _pickSearchResult(place),
                                        );
                                      },
                                    ),
                            ),
                        ],
                      ),
                    ),

                    // Bottom-End (Left in RTL) Gold GPS Locate Button (44x44)
                    PositionedDirectional(
                      bottom: 116 + bottomInset,
                      end: 14,
                      child: TactileScaleTap(
                        onTap: _getCurrentLocation,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SpecialDeliveryTokens.gold,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: SpecialDeliveryTokens.gold.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.my_location_rounded,
                            size: 20,
                            color: SpecialDeliveryTokens.darkOnGold,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Floating Confirmation Card
                    Positioned(
                      bottom: 14 + bottomInset,
                      left: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: palette.surfaceBorder),
                          boxShadow: [palette.surfaceShadow],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: palette.goldText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _isResolvingAddress
                                        ? (_isAr
                                              ? 'جاري تحديد العنوان...'
                                              : 'Resolving address...')
                                        : selectedLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SpecialDeliveryTokens.text(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TactileScaleTap(
                              pressedScale: 0.98,
                              onTap: _selectedLocation == null
                                  ? null
                                  : _confirmSelection,
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _selectedLocation != null
                                      ? SpecialDeliveryTokens.gold
                                      : palette.disabledBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _isAr ? 'تأكيد الموقع' : 'Confirm Location',
                                  style: SpecialDeliveryTokens.text(
                                    size: 13.5,
                                    weight: FontWeight.w900,
                                    color: _selectedLocation != null
                                        ? SpecialDeliveryTokens.darkOnGold
                                        : palette.disabledText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
