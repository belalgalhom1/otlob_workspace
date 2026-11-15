import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

import '../nearby_vendors_provider.dart';

/// Shows the vendors around the driver on a live map.
///
/// Vendors are colour-coded by how many orders they received recently:
/// red = busiest, orange = steady, primary = quiet. Busy vendors also get a
/// translucent circle whose size grows with their order count, so the driver
/// can see at a glance where the demand is concentrated.
class NearbyVendorsMapScreen extends ConsumerStatefulWidget {
  const NearbyVendorsMapScreen({super.key});

  @override
  ConsumerState<NearbyVendorsMapScreen> createState() =>
      _NearbyVendorsMapScreenState();
}

class _NearbyVendorsMapScreenState
    extends ConsumerState<NearbyVendorsMapScreen> {
  static const double _radiusKm = 5;

  final MapController _mapController = MapController();
  Position? _position;
  bool _locating = true;
  String? _locationError;
  bool _mapReady = false;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationError = _isArabic
              ? 'خدمة الموقع مغلقة. يرجى تشغيلها للمتابعة.'
              : 'Location services are disabled. Please enable them to continue.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationError = _isArabic
              ? 'تم رفض إذن الموقع. يرجى السماح بالوصول إلى الموقع.'
              : 'Location permission denied. Please allow location access.';
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (!mounted) return;
      if (position == null) {
        setState(() {
          _locating = false;
          _locationError = _isArabic
              ? 'تعذر تحديد موقعك الحالي. حاول مرة أخرى.'
              : 'Could not determine your current location. Please try again.';
        });
        return;
      }

      setState(() {
        _position = position;
        _locating = false;
      });

      if (_mapReady) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = _isArabic
            ? 'تعذر تحديد موقعك: $e'
            : 'Could not determine your location: $e';
      });
    }
  }

  void _recenter() {
    final position = _position;
    if (position == null || !_mapReady) return;
    _mapController.move(LatLng(position.latitude, position.longitude), 14);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isArabic ? 'خريطة المتاجر القريبة' : 'Nearby Vendors Map',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _isArabic ? 'تحديث' : 'Refresh',
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _locate,
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_locating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locationError != null || _position == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.mapPinOff,
                  size: 54, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                _isArabic ? 'الموقع غير متاح' : 'Location unavailable',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _locationError ??
                    (_isArabic
                        ? 'يرجى السماح بالوصول إلى الموقع.'
                        : 'Please allow location access.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _locate,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final position = _position!;
    final async = ref.watch(
      nearbyVendorsProvider((
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: _radiusKm,
        hours: null,
        days: null,
      )),
    );

    return async.when(
      loading: () => Stack(
        children: [
          _buildMap(position, const []),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (error, _) => Stack(
        children: [
          _buildMap(position, const []),
          _ErrorOverlay(
            isArabic: _isArabic,
            message: '$error',
            onRetry: () => ref.invalidate(
              nearbyVendorsProvider((
                lat: position.latitude,
                lng: position.longitude,
                radiusKm: _radiusKm,
                hours: null,
                days: null,
              )),
            ),
          ),
        ],
      ),
      data: (raw) {
        final vendors = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((v) {
              final lat = _asDouble(v['lat']);
              final lng = _asDouble(v['lng']);
              return lat != 0 && lng != 0;
            })
            .toList();

        final demand = _DemandThresholds.from(vendors);

        return Stack(
          children: [
            _buildMap(position, vendors, demand),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _HeaderCard(
                isArabic: _isArabic,
                isDark: isDark,
                vendorCount: vendors.length,
                radiusKm: _radiusKm.toInt(),
                demand: demand,
              ),
            ),
            if (vendors.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252525) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.store,
                              size: 34, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            _isArabic
                                ? 'لا توجد متاجر قريبة'
                                : 'No nearby vendors',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isArabic
                                ? 'لم نجد متاجر داخل $_radiusKm كم من موقعك.'
                                : 'No vendors were found within $_radiusKm km.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 20,
              child: Column(
                children: [
                  if (vendors.isNotEmpty)
                    FloatingActionButton.small(
                      heroTag: 'nearby_list',
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      onPressed: () =>
                          _showVendorList(vendors, demand, isDark),
                      child: Icon(
                        LucideIcons.list,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'nearby_recenter',
                    backgroundColor:
                        isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    onPressed: _recenter,
                    child: Icon(
                      LucideIcons.locateFixed,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMap(
    Position position,
    List<Map<String, dynamic>> vendors, [
    _DemandThresholds? demand,
  ]) {
    final center = LatLng(position.latitude, position.longitude);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        minZoom: 8,
        maxZoom: 19,
        onMapReady: () {
          _mapReady = true;
        },
      ),
      children: [
        const AppMapTileLayer(userAgentPackageName: 'com.otlobegy.driver'),
        if (demand != null)
          CircleLayer(
            circles: [
              for (final vendor in vendors)
                if (demand.levelOf(vendor) != _DemandLevel.normal)
                  CircleMarker(
                    point: LatLng(
                      _asDouble(vendor['lat']),
                      _asDouble(vendor['lng']),
                    ),
                    radius: demand.circleRadiusMeters(vendor),
                    useRadiusInMeter: true,
                    color: (demand.levelOf(vendor) == _DemandLevel.high
                            ? Colors.red
                            : Colors.orange)
                        .withValues(alpha: 0.16),
                    borderColor:
                        (demand.levelOf(vendor) == _DemandLevel.high
                                ? Colors.red
                                : Colors.orange)
                            .withValues(alpha: 0.55),
                    borderStrokeWidth: 1.5,
                  ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 42,
              height: 42,
              child: const _DriverDot(),
            ),
            for (final vendor in vendors)
              Marker(
                point: LatLng(
                  _asDouble(vendor['lat']),
                  _asDouble(vendor['lng']),
                ),
                width: 96,
                height: 72,
                child: _VendorMarker(
                  vendor: vendor,
                  level: demand?.levelOf(vendor) ?? _DemandLevel.normal,
                  isArabic: _isArabic,
                  onTap: () => _showVendorSheet(vendor, demand),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showVendorSheet(
    Map<String, dynamic> vendor,
    _DemandThresholds? demand,
  ) {
    final isArabic = _isArabic;
    final name = _vendorName(vendor, isArabic);
    final orders = _asInt(vendor['orderCount']);
    final activeOrders = _asInt(vendor['activeOrderCount']);
    final distance = _asDouble(vendor['distanceKm']);
    final level = demand?.levelOf(vendor) ?? _DemandLevel.normal;
    final color = _colorFor(level);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.14),
                    child: Icon(LucideIcons.store, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeOrders > 0
                              ? (isArabic
                                  ? '$activeOrders طلب نشط في الوقت الحالي'
                                  : '$activeOrders active orders right now')
                              : (orders > 0
                                  ? (isArabic
                                      ? '$orders طلب في الوقت الحالي'
                                      : '$orders orders in current time')
                                  : (isArabic
                                      ? 'لا توجد طلبات جارية حالياً'
                                      : 'No active orders currently')),
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: LucideIcons.mapPin,
                text: '${distance.toStringAsFixed(1)} km',
              ),
              if ((vendor['branchAddress']?.toString() ?? '').isNotEmpty)
                _InfoRow(
                  icon: LucideIcons.navigation,
                  text: vendor['branchAddress'].toString(),
                ),
              if ((vendor['branchName']?.toString() ?? '').isNotEmpty ||
                  (vendor['branchNameAr']?.toString() ?? '').isNotEmpty)
                _InfoRow(
                  icon: LucideIcons.building2,
                  text: (vendor['branchNameAr']?.toString().isNotEmpty ?? false)
                      ? vendor['branchNameAr'].toString()
                      : vendor['branchName'].toString(),
                ),
              _InfoRow(
                icon: LucideIcons.circleDot,
                text: _statusLabel(vendor, isArabic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVendorList(
    List<Map<String, dynamic>> vendors,
    _DemandThresholds demand,
    bool isDark,
  ) {
    final sorted = [...vendors]..sort(
        (a, b) {
          final aActive = _asInt(a['activeOrderCount']);
          final bActive = _asInt(b['activeOrderCount']);
          if (bActive != aActive) return bActive.compareTo(aActive);
          final aCount = _asInt(a['orderCount']);
          final bCount = _asInt(b['orderCount']);
          if (bCount != aCount) return bCount.compareTo(aCount);
          return _asDouble(a['distanceKm']).compareTo(_asDouble(b['distanceKm']));
        },
      );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, controller) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Text(
                      _isArabic ? 'المتاجر القريبة' : 'Nearby Vendors',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${sorted.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final vendor = sorted[index];
                    final level = demand.levelOf(vendor);
                    final color = _colorFor(level);
                    final orders = _asInt(vendor['orderCount']);
                    final active = _asInt(vendor['activeOrderCount']);
                    final distance = _asDouble(vendor['distanceKm']);
                    return Material(
                      color: isDark ? const Color(0xFF252525) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showVendorSheet(vendor, demand);
                        },
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.14),
                          child: Icon(
                            level == _DemandLevel.high
                                ? LucideIcons.flame
                                : LucideIcons.store,
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _vendorName(vendor, _isArabic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          _isArabic
                              ? (active > 0
                                  ? '$active طلب نشط الآن · ${distance.toStringAsFixed(1)} كم'
                                  : '$orders طلب حالياً · ${distance.toStringAsFixed(1)} كم')
                              : (active > 0
                                  ? '$active active now · ${distance.toStringAsFixed(1)} km'
                                  : '$orders orders now · ${distance.toStringAsFixed(1)} km'),
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            _isArabic
                                ? _levelLabelAr(level)
                                : _levelLabelEn(level),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Demand classification ──────────────────────────────────────────────────

enum _DemandLevel { high, medium, normal }

class _DemandThresholds {
  final int high;
  final int medium;
  final int maxCount;

  const _DemandThresholds({
    required this.high,
    required this.medium,
    required this.maxCount,
  });

  factory _DemandThresholds.from(List<Map<String, dynamic>> vendors) {
    if (vendors.isEmpty) {
      return const _DemandThresholds(high: 0, medium: 0, maxCount: 0);
    }
    var maxCount = 0;
    for (final vendor in vendors) {
      final active = _asInt(vendor['activeOrderCount']);
      final total = _asInt(vendor['orderCount']);
      maxCount = math.max(maxCount, math.max(active, total));
    }
    // Real-time demand bands for current time orders
    final high = maxCount >= 3 ? math.max(3, (maxCount * 0.6).ceil()) : (maxCount >= 2 ? 2 : 0);
    final medium = maxCount >= 1 ? 1 : 0;
    return _DemandThresholds(high: high, medium: medium, maxCount: maxCount);
  }

  _DemandLevel levelOf(Map<String, dynamic> vendor) {
    final active = _asInt(vendor['activeOrderCount']);
    final count = _asInt(vendor['orderCount']);
    final effective = math.max(active, count);
    if (active >= 2 || (high > 0 && effective >= high)) return _DemandLevel.high;
    if (active >= 1 || (medium > 0 && effective >= medium)) return _DemandLevel.medium;
    return _DemandLevel.normal;
  }

  double circleRadiusMeters(Map<String, dynamic> vendor) {
    final count = _asInt(vendor['orderCount']);
    final ratio = maxCount > 0 ? count / maxCount : 0;
    return 160 + ratio * 440;
  }
}

Color _colorFor(_DemandLevel level) {
  switch (level) {
    case _DemandLevel.high:
      return const Color(0xFFE53935);
    case _DemandLevel.medium:
      return const Color(0xFFF59E0B);
    case _DemandLevel.normal:
      return AppColors.primary;
  }
}

String _levelLabelAr(_DemandLevel level) {
  switch (level) {
    case _DemandLevel.high:
      return 'ضغط طلبات الآن';
    case _DemandLevel.medium:
      return 'نشاط حالي';
    case _DemandLevel.normal:
      return 'عادي';
  }
}

String _levelLabelEn(_DemandLevel level) {
  switch (level) {
    case _DemandLevel.high:
      return 'High demand now';
    case _DemandLevel.medium:
      return 'Active now';
    case _DemandLevel.normal:
      return 'Normal';
  }
}

String _vendorName(Map<String, dynamic> vendor, bool isArabic) {
  final ar = vendor['storeNameAr']?.toString().trim() ?? '';
  final en = vendor['storeName']?.toString().trim() ?? '';
  if (isArabic && ar.isNotEmpty) return ar;
  if (en.isNotEmpty) return en;
  if (ar.isNotEmpty) return ar;
  return isArabic ? 'متجر' : 'Vendor';
}

String _statusLabel(Map<String, dynamic> vendor, bool isArabic) {
  final open = vendor['branchIsOpen'] == true &&
      vendor['vendorStatus']?.toString() == 'OPEN';
  if (open) return isArabic ? 'مفتوح الآن' : 'Open now';
  return isArabic ? 'مغلق حالياً' : 'Currently closed';
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// ─── Map widgets ────────────────────────────────────────────────────────────

class _DriverDot extends StatelessWidget {
  const _DriverDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(7),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 16),
      ),
    );
  }
}

class _VendorMarker extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final _DemandLevel level;
  final bool isArabic;
  final VoidCallback onTap;

  const _VendorMarker({
    required this.vendor,
    required this.level,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(level);
    final activeOrders = _asInt(vendor['activeOrderCount']);
    final orders = _asInt(vendor['orderCount']);
    final displayCount = activeOrders > 0 ? activeOrders : orders;
    final name = _vendorName(vendor, isArabic);
    final isHigh = level == _DemandLevel.high;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: color,
                    width: isHigh ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: isHigh ? 12 : 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isHigh ? LucideIcons.flame : LucideIcons.store,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
              if (displayCount > 0)
                Positioned(
                  top: -7,
                  right: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$displayCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            constraints: const BoxConstraints(maxWidth: 92),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isArabic;
  final bool isDark;
  final int vendorCount;
  final int radiusKm;
  final _DemandThresholds demand;

  const _HeaderCard({
    required this.isArabic,
    required this.isDark,
    required this.vendorCount,
    required this.radiusKm,
    required this.demand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.store,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? '$vendorCount متجر داخل $radiusKm كم'
                          : '$vendorCount vendors within $radiusKm km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'حسب الطلبات الجارية في الوقت الحالي'
                          : 'By real-time orders in current time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: const Color(0xFFE53935),
                label: isArabic ? 'طلبات كثيرة الآن' : 'High demand now',
                isDark: isDark,
              ),
              _LegendDot(
                color: const Color(0xFFF59E0B),
                label: isArabic ? 'نشاط حالي' : 'Active now',
                isDark: isDark,
              ),
              _LegendDot(
                color: AppColors.primary,
                label: isArabic ? 'عادي' : 'Normal',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final bool isArabic;
  final String message;
  final VoidCallback onRetry;

  const _ErrorOverlay({
    required this.isArabic,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.triangleAlert,
                size: 34, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              isArabic ? 'تعذر تحميل المتاجر' : 'Could not load vendors',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 15),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
