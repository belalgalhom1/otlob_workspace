import 'dart:async';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'driver_managers_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/driver_providers.dart';
import '../data/driver_models.dart';
import 'widgets/assign_order_dialog.dart';
import 'widgets/driver_shifts_dialog.dart';
import '../../wallet/presentation/widgets/manual_transaction_dialog.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:core/core.dart';
import 'package:vendor/core/providers.dart';
import 'widgets/driver_form_dialog.dart';
import 'widgets/assist_requests_dialog.dart';
import 'driver_statistics_screen.dart';
import 'all_drivers_statistics_screen.dart';
import '../../zones/presentation/zone_provider.dart';
import 'widgets/driver_map_details_card.dart';
import 'widgets/active_order_details_dialog.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedStatus;
  String? _selectedZoneId;
  List<LatLng> _selectedZonePolygon = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DriverProfile? _selectedDriver;
  LatLng? _selectedDriverLocation;
  bool _selectedDriverIsLive = false;
  Map<String, dynamic>? _selectedDriverOrder;
  bool _isLoadingDriverOrder = false;
  LatLng? _orderPickupLocation;
  LatLng? _orderDeliveryLocation;
  int _mobileViewMode = 0; // 0 = List, 1 = Map
  final MapController _mapController = MapController();

  late final AnimationController _driverMoveController;
  LatLng? _driverAnimStart;
  LatLng? _driverAnimTarget;
  double _driverHeading = 0.0;
  double _driverStartHeading = 0.0;
  double _driverTargetHeading = 0.0;
  bool _isDriverMoving = false;
  Timer? _driverRenderTimer;
  LatLng? _pendingDriverLocation;
  double? _pendingDriverHeading;
  Timer? _driverPollTimer;
  StreamSubscription<dynamic>? _driverLocationSub;
  String? _trackedDriverId;

  static double _lerpAngle(double from, double to, double t) {
    double diff = (to - from) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return (from + diff * t) % 360.0;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * (180.0 / math.pi);
    return (brng + 360.0) % 360.0;
  }

  LatLng? get _currentDriverLocation {
    if (_driverAnimStart != null &&
        _driverAnimTarget != null &&
        _driverMoveController.isAnimating) {
      final t = CurvedAnimation(
        parent: _driverMoveController,
        curve: Curves.easeInOut,
      ).value;
      final curLat = _driverAnimStart!.latitude +
          (_driverAnimTarget!.latitude - _driverAnimStart!.latitude) * t;
      final curLng = _driverAnimStart!.longitude +
          (_driverAnimTarget!.longitude - _driverAnimStart!.longitude) * t;
      return LatLng(curLat, curLng);
    }
    return _selectedDriverLocation;
  }

  double get _currentDriverHeading {
    if (_driverMoveController.isAnimating) {
      final t = CurvedAnimation(
        parent: _driverMoveController,
        curve: Curves.easeInOut,
      ).value;
      return _lerpAngle(_driverStartHeading, _driverTargetHeading, t);
    }
    return _driverHeading;
  }

  @override
  void initState() {
    super.initState();
    _driverMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _driverMoveController.addListener(() {
      if (mounted) setState(() {});
    });
    _driverMoveController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isDriverMoving = false;
          _selectedDriverLocation = _driverAnimTarget ?? _selectedDriverLocation;
        });
      }
    });

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
      ref.read(zoneProvider.notifier).fetchZones();
      _initDriverSocket();
    });
  }

  void _initDriverSocket() {
    try {
      final socket = ref.read(socketServiceProvider);
      socket.init();
      _driverLocationSub?.cancel();
      _driverLocationSub = socket
          .onEvent(SocketEvent.driverLocation)
          .listen(_onDriverLocationSocketEvent);
    } catch (e) {
      debugPrint('Error initializing driver tracking socket: $e');
    }
  }

  void _onDriverLocationSocketEvent(dynamic data) {
    if (data == null || !mounted) return;
    final driverId = data['driverId']?.toString();
    if (driverId != null && driverId == _selectedDriver?.id) {
      final lat = (data['latitude'] ?? data['lat']) as num?;
      final lng = (data['longitude'] ?? data['lng']) as num?;
      final heading = (data['heading'] as num?)?.toDouble();
      if (lat != null && lng != null && lat.toDouble().isFinite && lng.toDouble().isFinite) {
        _queueDriverLocation(LatLng(lat.toDouble(), lng.toDouble()), heading);
      }
    }
  }

  void _queueDriverLocation(LatLng point, double? heading) {
    _pendingDriverLocation = point;
    _pendingDriverHeading = heading;
    _driverRenderTimer?.cancel();
    _driverRenderTimer = Timer(const Duration(milliseconds: 250), _applyDriverLocation);
  }

  void _applyDriverLocation() {
    _driverRenderTimer = null;
    final target = _pendingDriverLocation;
    final heading = _pendingDriverHeading;
    _pendingDriverLocation = null;
    _pendingDriverHeading = null;
    if (target == null || !mounted) return;

    if (_selectedDriverLocation == null) {
      setState(() {
        _selectedDriverLocation = target;
        _selectedDriverIsLive = true;
        _driverHeading = heading ?? 0.0;
        _driverStartHeading = _driverHeading;
        _driverTargetHeading = _driverHeading;
      });
      return;
    }

    final dist = const Distance().as(LengthUnit.Meter, _selectedDriverLocation!, target);
    if (dist < 1.0) {
      if (heading != null && (heading - _driverHeading).abs() > 5.0) {
        setState(() {
          _driverHeading = heading;
          _driverStartHeading = heading;
          _driverTargetHeading = heading;
        });
      }
      return;
    }

    final newHeading = heading ?? _calculateBearing(_selectedDriverLocation!, target);
    _driverStartHeading = _currentDriverHeading;
    _driverTargetHeading = newHeading;
    _driverHeading = newHeading;
    _driverAnimStart = _currentDriverLocation ?? _selectedDriverLocation;
    _driverAnimTarget = target;
    _isDriverMoving = true;
    _selectedDriverIsLive = true;
    _driverMoveController.forward(from: 0.0);
  }

  void _clearSelectedDriver() {
    if (_trackedDriverId != null) {
      try {
        ref.read(socketServiceProvider).emit(SocketEvent.driverUntrack, {'driverId': _trackedDriverId});
      } catch (_) {}
      _trackedDriverId = null;
    }
    _driverPollTimer?.cancel();
    _driverRenderTimer?.cancel();
    _driverMoveController.stop();
    setState(() {
      _selectedDriver = null;
      _selectedDriverLocation = null;
      _driverAnimStart = null;
      _driverAnimTarget = null;
      _isDriverMoving = false;
      _selectedDriverOrder = null;
      _orderPickupLocation = null;
      _orderDeliveryLocation = null;
    });
  }

  @override
  void dispose() {
    _driverMoveController.dispose();
    _driverRenderTimer?.cancel();
    _driverPollTimer?.cancel();
    _driverLocationSub?.cancel();
    if (_trackedDriverId != null) {
      try {
        ref.read(socketServiceProvider).emit(SocketEvent.driverUntrack, {'driverId': _trackedDriverId});
      } catch (_) {}
    }
    _scrollController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(driversProvider.notifier).loadMore();
    }
  }

  void _applyFilters() {
    ref
        .read(driversProvider.notifier)
        .filter(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          status: _selectedStatus,
          zoneId: _selectedZoneId,
        );
  }

  List<LatLng> _extractPolygonPoints(dynamic boundary) {
    if (boundary is! Map) return [];
    final coordinates = boundary['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return [];
    final firstRing = coordinates[0];
    if (firstRing is! List) return [];
    final points = <LatLng>[];
    for (final coord in firstRing) {
      if (coord is List && coord.length >= 2) {
        final lng = (coord[0] as num?)?.toDouble();
        final lat = (coord[1] as num?)?.toDouble();
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }
    return points;
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(30.0444, 31.2357);
    double latSum = 0;
    double lngSum = 0;
    for (final p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  LatLng? _extractCoordinates(dynamic loc) {
    if (loc == null) return null;
    if (loc is List && loc.length >= 2) {
      final lng = (loc[0] as num?)?.toDouble();
      final lat = (loc[1] as num?)?.toDouble();
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        return LatLng(lat, lng);
      }
    }
    if (loc is Map) {
      final lat = (loc['latitude'] ?? loc['lat']) as num?;
      final lng = (loc['longitude'] ?? loc['lng']) as num?;
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        final cLng = (coords[0] as num?)?.toDouble();
        final cLat = (coords[1] as num?)?.toDouble();
        if (cLat != null && cLng != null && cLat != 0.0 && cLng != 0.0) {
          return LatLng(cLat, cLng);
        }
      }
    }
    return null;
  }

  void _fitRouteBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      try {
        _mapController.move(points.first, 15.5);
      } catch (_) {}
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
        ),
      );
    } catch (_) {
      try {
        _mapController.move(points.first, 14);
      } catch (_) {}
    }
  }

  void _onZoneSelected(String? zoneId, List<dynamic> zones) {
    _selectedZoneId = zoneId;
    if (zoneId == null) {
      _selectedZonePolygon = [];
    } else {
      final zone = zones.firstWhere(
        (z) => z is Map && z['id']?.toString() == zoneId,
        orElse: () => null,
      );
      if (zone != null) {
        _selectedZonePolygon = _extractPolygonPoints(zone['boundary']);
        if (_selectedZonePolygon.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(
                _calculateCentroid(_selectedZonePolygon),
                13,
              );
            }
          });
        }
      } else {
        _selectedZonePolygon = [];
      }
    }
  }

  Future<void> _callDriver(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _openInMaps(double lat, double lng, {String? label}) async {
    if (lat == 0.0 || lng == 0.0) return;

    final encodedLabel = Uri.encodeComponent(label ?? "Location");

    // 1. Android geo URI with exact pin coordinates and label
    final geoUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng($encodedLabel)");

    // 2. Exact dropped-pin Google Maps universal URL
    final googleMapsUri = Uri.parse("https://www.google.com/maps?q=$lat,$lng&ll=$lat,$lng&z=17");

    try {
      if (await canLaunchUrl(geoUri)) {
        final ok = await launchUrl(geoUri, mode: LaunchMode.externalNonBrowserApplication);
        if (ok) return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        final ok = await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}

    try {
      await launchUrl(googleMapsUri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driversProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Column(
          children: [
            _buildFilters(isMobile),
            if (isMobile) ...[
              const SizedBox(height: 10),
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _mobileViewMode = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: _mobileViewMode == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _mobileViewMode == 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.list,
                                size: 16,
                                color: _mobileViewMode == 0
                                    ? Colors.black
                                    : theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'القائمة' : 'List',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _mobileViewMode == 0
                                      ? Colors.black
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _mobileViewMode = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: _mobileViewMode == 1
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _mobileViewMode == 1
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.map,
                                size: 16,
                                color: _mobileViewMode == 1
                                    ? Colors.black
                                    : theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'الخريطة' : 'Map',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _mobileViewMode == 1
                                      ? Colors.black
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: isMobile
                  ? (_mobileViewMode == 0
                      ? _buildList(state, isMobile)
                      : _buildMap(context, state))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildList(state, isMobile)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildMap(context, state)),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  bool _canManageDrivers = false;
  bool _canViewAllDriversStats = false;

  Future<void> _checkPermissions() async {
    final repo = ref.read(sharedAuthRepositoryProvider);
    final role = await repo.getUserRole();
    if (role == 'SUPER_ADMIN' || role == 'DRIVER_MANAGER') {
      if (mounted) {
        setState(() {
          _canManageDrivers = true;
          _canViewAllDriversStats = true;
        });
      }
      return;
    }
    final permissions = await repo.getUserPermissions();
    if (mounted) {
      setState(() {
        _canManageDrivers = permissions.contains('MANAGE_DRIVERS');
      });
    }
  }

  Future<void> _locateDriver(DriverProfile driver, {bool switchTabIfMobile = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCompactScreen = MediaQuery.of(context).size.width < 900;

    if (switchTabIfMobile && isCompactScreen && _mobileViewMode != 1) {
      setState(() => _mobileViewMode = 1);
    }

    if (_trackedDriverId != null && _trackedDriverId != driver.id) {
      try {
        ref.read(socketServiceProvider).emit(SocketEvent.driverUntrack, {'driverId': _trackedDriverId});
      } catch (_) {}
    }
    _trackedDriverId = driver.id;
    try {
      ref.read(socketServiceProvider).emit(SocketEvent.driverTrack, {'driverId': driver.id});
    } catch (_) {}

    setState(() {
      _selectedDriver = driver;
      _isLoadingDriverOrder = true;
      _selectedDriverOrder = null;
      _orderPickupLocation = null;
      _orderDeliveryLocation = null;
      _driverAnimStart = null;
      _driverAnimTarget = null;
      _isDriverMoving = false;
      _driverHeading = 0.0;
      _driverStartHeading = 0.0;
      _driverTargetHeading = 0.0;
    });

    try {
      final result = await ref
          .read(adminDriversRepositoryProvider)
          .getDriverLocation(driverId: driver.id);
      final data = (result is Map) ? result : null;
      double? lat = (data?['latitude'] as num?)?.toDouble() ??
          (data?['lat'] as num?)?.toDouble();
      double? lng = (data?['longitude'] as num?)?.toDouble() ??
          (data?['lng'] as num?)?.toDouble();

      // Fallback to driver's location from profile if API location is null
      if ((lat == null || lng == null) && driver.location != null && driver.location!.length >= 2) {
        lng = driver.location![0];
        lat = driver.location![1];
      }

      if (lat == null || lng == null || !mounted) {
        setState(() => _isLoadingDriverOrder = false);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(l10n.driverNoLocation)));
        return;
      }
      final isLive = data?['isLive'] == true;
      final driverLocation = LatLng(lat, lng);
      final activeOrderId = data?['activeOrderId']?.toString();

      // Resolve active order
      String? orderIdToFetch = (activeOrderId != null && activeOrderId.isNotEmpty) ? activeOrderId : null;
      if (orderIdToFetch == null) {
        try {
          final res = await ref.read(adminOrdersRepositoryProvider).ordersFindAll(
            driverId: driver.id,
            limit: 6,
          );
          final list = (res is Map)
              ? (res['orders'] ?? res['items'] ?? res['data'])
              : (res is List ? res : null);
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                final st = item['status']?.toString().toUpperCase() ?? '';
                if (const {
                  'DRIVER_ASSIGNED',
                  'PREPARING',
                  'READY_FOR_PICKUP',
                  'PENDING_PAYMENT',
                  'PARTIALLY_PICKED_UP',
                  'PICKED_UP',
                }.contains(st)) {
                  orderIdToFetch = item['id']?.toString();
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }

      Map<String, dynamic>? fullOrder;
      LatLng? pickup;
      LatLng? delivery;

      if (orderIdToFetch != null && orderIdToFetch.isNotEmpty) {
        try {
          final orderRes = await ref.read(adminOrdersRepositoryProvider).getOrderById(orderIdToFetch);
          if (orderRes is Map) {
            final inner = orderRes['data'];
            fullOrder = inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(orderRes);
            pickup = _extractCoordinates(fullOrder['pickupLocation']) ??
                _extractCoordinates(fullOrder['vendorBranch']?['location']) ??
                _extractCoordinates(fullOrder['vendor']?['location']);
            delivery = _extractCoordinates(fullOrder['deliveryLocation']);
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _selectedDriver = driver;
        _selectedDriverLocation = driverLocation;
        _selectedDriverIsLive = isLive;
        _selectedDriverOrder = fullOrder;
        _isLoadingDriverOrder = false;
        _orderPickupLocation = pickup;
        _orderDeliveryLocation = delivery;
      });

      _driverPollTimer?.cancel();
      _driverPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (!mounted || _selectedDriver?.id != driver.id) return;
        try {
          final locRes = await ref
              .read(adminDriversRepositoryProvider)
              .getDriverLocation(driverId: driver.id);
          final locMap = (locRes is Map) ? locRes : null;
          if (locMap != null && mounted && _selectedDriver?.id == driver.id) {
            final lLat = (locMap['latitude'] as num?)?.toDouble() ??
                (locMap['lat'] as num?)?.toDouble();
            final lLng = (locMap['longitude'] as num?)?.toDouble() ??
                (locMap['lng'] as num?)?.toDouble();
            final heading = (locMap['heading'] as num?)?.toDouble();
            if (lLat != null && lLng != null && lLat.isFinite && lLng.isFinite) {
              _queueDriverLocation(LatLng(lLat, lLng), heading);
            }
          }
        } catch (_) {}
      });

      final points = [
        driverLocation,
        ?pickup,
        ?delivery,
      ];

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitRouteBounds(points);
        }
      });

      if (isCompactScreen && _mobileViewMode == 0) {
        _showDriverLocationBottomSheet(
          driver: driver,
          location: driverLocation,
          isLive: isLive,
          activeOrder: fullOrder,
          pickupLocation: pickup,
          deliveryLocation: delivery,
        );
      } else {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isLive ? l10n.driverLiveLocation : l10n.driverLastKnownLocation,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() => _isLoadingDriverOrder = false);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, err)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDriverLocationBottomSheet({
    required DriverProfile driver,
    required LatLng location,
    required bool isLive,
    Map<String, dynamic>? activeOrder,
    LatLng? pickupLocation,
    LatLng? deliveryLocation,
    bool isLoadingOrder = false,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final sheetMapController = MapController();

    // Compute route points
    final routePoints = <LatLng>[
      location,
      ?pickupLocation,
      ?deliveryLocation,
    ];

    // Compute polylines
    final polylines = <Polyline>[];
    if (activeOrder != null) {
      final st = (activeOrder['status']?.toString() ?? '').toUpperCase();
      final isHeadingToCustomer = (st == 'PICKED_UP');
      if (isHeadingToCustomer && deliveryLocation != null) {
        polylines.add(
          Polyline(
            points: [location, deliveryLocation],
            color: AppColors.primary,
            strokeWidth: 4.5,
          ),
        );
      } else if (!isHeadingToCustomer) {
        if (pickupLocation != null) {
          polylines.add(
            Polyline(
              points: [location, pickupLocation],
              color: Colors.amber.shade700,
              strokeWidth: 4.5,
            ),
          );
        }
        if (pickupLocation != null && deliveryLocation != null) {
          polylines.add(
            Polyline(
              points: [pickupLocation, deliveryLocation],
              color: Colors.blue.withValues(alpha: 0.65),
              strokeWidth: 3.5,
            ),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Interactive mini map
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AnimatedBuilder(
                        animation: _driverMoveController,
                        builder: (ctx, _) {
                          final curLoc = _currentDriverLocation ?? location;
                          final sheetPolylines = <Polyline>[];
                          if (activeOrder != null) {
                            final st = (activeOrder['status']?.toString() ?? '').toUpperCase();
                            final isHeadingToCustomer = (st == 'PICKED_UP');
                            if (isHeadingToCustomer && deliveryLocation != null) {
                              sheetPolylines.add(
                                Polyline(
                                  points: [curLoc, deliveryLocation],
                                  color: AppColors.primary,
                                  strokeWidth: 4.5,
                                ),
                              );
                            } else if (!isHeadingToCustomer) {
                              if (pickupLocation != null) {
                                sheetPolylines.add(
                                  Polyline(
                                    points: [curLoc, pickupLocation],
                                    color: Colors.amber.shade700,
                                    strokeWidth: 4.5,
                                  ),
                                );
                              }
                              if (pickupLocation != null && deliveryLocation != null) {
                                sheetPolylines.add(
                                  Polyline(
                                    points: [pickupLocation, deliveryLocation],
                                    color: Colors.blue.withValues(alpha: 0.65),
                                    strokeWidth: 3.5,
                                  ),
                                );
                              }
                            }
                          }

                          return FlutterMap(
                            mapController: sheetMapController,
                            options: MapOptions(
                              initialCenter: curLoc,
                              initialZoom: 15.0,
                              onMapReady: () {
                                if (routePoints.length > 1) {
                                  try {
                                    final b = LatLngBounds.fromPoints(routePoints);
                                    sheetMapController.fitCamera(
                                      CameraFit.bounds(
                                        bounds: b,
                                        padding: const EdgeInsets.all(40),
                                      ),
                                    );
                                  } catch (_) {}
                                }
                              },
                            ),
                            children: [
                              const AppMapTileLayer(userAgentPackageName: 'com.otlob.admin'),
                              if (sheetPolylines.isNotEmpty) PolylineLayer(polylines: sheetPolylines),
                              MarkerLayer(
                                markers: [
                                  // Driver vehicle marker
                                  Marker(
                                    point: curLoc,
                                    width: 72,
                                    height: 72,
                                    child: RepaintBoundary(
                                      child: InDriveVehicleMarker(
                                        size: 48,
                                        heading: _currentDriverHeading,
                                        isMoving: _isDriverMoving,
                                        vehicleType: driver.vehicleType ?? 'MOTORCYCLE',
                                        plateNumber: driver.vehiclePlate,
                                        label: driver.name,
                                        color: isLive ? AppColors.success : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  // Store / Pickup marker
                                  if (pickupLocation != null)
                                    Marker(
                                      point: pickupLocation,
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade700,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(LucideIcons.store, size: 20, color: Colors.white),
                                      ),
                                    ),
                                  // Customer / Delivery marker
                                  if (deliveryLocation != null)
                                    Marker(
                                      point: deliveryLocation,
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(LucideIcons.mapPin, size: 22, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Google Maps direct pin button overlay
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: FilledButton.icon(
                        onPressed: () => _openInMaps(location.latitude, location.longitude, label: driver.name),
                        icon: const Icon(LucideIcons.externalLink, size: 13),
                        label: Text(
                          isArabic ? 'خرائط Google' : 'Google Maps',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    // Switch to Full Map Button overlay
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _mobileViewMode = 1;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _fitRouteBounds(routePoints);
                          });
                        },
                        icon: const Icon(LucideIcons.maximize2, size: 14),
                        label: Text(
                          isArabic ? 'الخريطة الكاملة' : 'Full Map',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Details section
              Expanded(
                child: DriverMapDetailsCard(
                  driver: driver,
                  location: location,
                  isLive: isLive,
                  activeOrder: activeOrder,
                  isLoadingOrder: isLoadingOrder,
                  pickupLocation: pickupLocation,
                  deliveryLocation: deliveryLocation,
                  isEmbeddedInSheet: true,
                  onClose: () => Navigator.pop(ctx),
                  onCallPhone: (phone) => _callDriver(phone),
                  onOpenMaps: (lat, lng, {label}) => _openInMaps(lat, lng, label: label),
                  onAssignOrder: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (context) => AssignOrderDialog(driver: driver),
                    );
                  },
                  onViewOrderDetails: (ord) {
                    showDialog(
                      context: context,
                      builder: (context) => ActiveOrderDetailsDialog(order: ord),
                    );
                  },
                  onCenterOnDriver: () {
                    try {
                      sheetMapController.move(location, 16);
                    } catch (_) {}
                  },
                  onCenterOnDelivery: () {
                    if (routePoints.length > 1) {
                      try {
                        sheetMapController.fitCamera(
                          CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(routePoints),
                            padding: const EdgeInsets.all(40),
                          ),
                        );
                      } catch (_) {}
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(bool isMobile) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final zones = ref.watch(zoneProvider).value?.zones ?? const [];
    final hasActiveFilters = _searchController.text.trim().isNotEmpty ||
        _selectedStatus != null ||
        _selectedZoneId != null;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dashboard Search Bar + Primary 'Add Driver' Button
          Row(
            children: [
              Expanded(
                child: DashboardSearchBar(
                  controller: _searchController,
                  hintText: l10n.searchDrivers,
                  onChanged: (val) => _applyFilters(),
                  onClear: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const DriverFormDialog(),
                  );
                },
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: Text(
                  isMobile
                      ? (isArabic ? 'سائق جديد' : 'New')
                      : l10n.createNewUser,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Status Filter Chips & Zone Selector & Auxiliary Action Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(null, l10n.filterAll),
                _buildStatusChip('ONLINE', l10n.statusOnline, color: AppColors.success),
                _buildStatusChip('ON_DELIVERY', l10n.statusOnDelivery, color: Colors.blue),
                _buildStatusChip('ON_BREAK', l10n.statusOnBreak, color: AppColors.warning),
                _buildStatusChip('OFFLINE', l10n.statusOffline, color: Colors.grey),
                _buildStatusChip('SUSPENDED', l10n.statusSuspended, color: AppColors.error),

                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 8),

                _buildZoneDropdown(zones, isArabic, l10n),

                if (_canManageDrivers) ...[
                  const SizedBox(width: 8),
                  if (_canViewAllDriversStats) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AllDriversStatisticsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.chartNoAxesCombined, size: 14),
                      label: Text(
                        isArabic ? 'إحصائيات كل السائقين' : 'All Drivers Stats',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DriverManagersScreen(isEmbedded: false),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.userCheck, size: 14),
                    label: Text(
                      isArabic ? 'مسؤولو السائقين' : 'Driver Managers',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AssistRequestsDialog(),
                      );
                    },
                    icon: const Icon(LucideIcons.lifeBuoy, size: 14),
                    label: Text(
                      isArabic ? 'طلبات المساعدة' : 'Assist Requests',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],

                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _selectedStatus = null;
                        _selectedZoneId = null;
                        _selectedZonePolygon = [];
                      });
                      _applyFilters();
                    },
                    icon: const Icon(LucideIcons.x, size: 14, color: AppColors.error),
                    label: Text(
                      l10n.resetFilters,
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status, String label, {Color? color}) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: color != null
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
            : const Color(0xFFF1F3F5),
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() => _selectedStatus = status);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildZoneDropdown(
    List<dynamic> zones,
    bool isArabic,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
            : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedZoneId != null
              ? AppColors.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedZoneId,
          icon: const Icon(LucideIcons.chevronDown, size: 14),
          style: TextStyle(
            fontSize: 12,
            fontWeight: _selectedZoneId != null ? FontWeight.bold : FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.mapPin, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                l10n.allZones,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.mapPin, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(l10n.allZones, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            for (final z in zones)
              DropdownMenuItem(
                value: z['id']?.toString(),
                child: Text(
                  (isArabic ? (z['nameAr'] ?? z['name']) : z['name'])?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (val) {
            setState(() {
              _onZoneSelected(val, zones);
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildList(AsyncValue<DriversState> state, bool isMobile) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          ErrorUtils.translate(context, err),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (data) {
        if (data.drivers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.truck,
                  size: 48,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noDriversFound,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: _scrollController,
          itemCount: data.drivers.length + (data.hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == data.drivers.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final driver = data.drivers[index];
            return _buildDriverCard(driver, isArabic, l10n, isMobile);
          },
        );
      },
    );
  }

  Widget _buildDriverCard(
    DriverProfile driver,
    bool isArabic,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedDriver?.id == driver.id;

    final avatarPath = driver.avatar;
    final resolvedAvatar = (avatarPath == null || avatarPath.isEmpty)
        ? ''
        : ImageUtils.formatImageUrl(avatarPath);
    final avatarUrl = resolvedAvatar.isEmpty ? null : resolvedAvatar;
    final statusColor = _getStatusColor(context, driver.status);

    return InkWell(
      onTap: () => _locateDriver(driver),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar with Status Indicator + Name & Phone + Status Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(LucideIcons.user, color: statusColor, size: 24)
                          : null,
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name.isNotEmpty
                            ? driver.name
                            : (isArabic ? 'سائق' : 'Driver'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (driver.phone != null && driver.phone!.isNotEmpty)
                        InkWell(
                          onTap: () => _callDriver(driver.phone),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.phone,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    driver.phone!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          'ID: ${driver.id.substring(0, driver.id.length > 8 ? 8 : driver.id.length)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _translateDriverStatus(context, driver.status),
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Approval Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getDriverBadgeColor(driver).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getDriverBadgeText(context, driver),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDriverBadgeColor(driver),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Contextual tags (Zone, Manager, Vehicle)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (driver.zoneName != null && driver.zoneName!.isNotEmpty)
                  _buildTagPill(
                    icon: LucideIcons.mapPin,
                    label: driver.zoneName!,
                    color: Colors.teal,
                  ),
                if (driver.driverManagerName != null && driver.driverManagerName!.isNotEmpty)
                  _buildTagPill(
                    icon: LucideIcons.userCheck,
                    label: '${isArabic ? "مسؤول السائقين" : "Manager"}: ${driver.driverManagerName}',
                    color: AppColors.primary,
                  ),
                if ((driver.vehiclePlate != null && driver.vehiclePlate!.isNotEmpty) ||
                    (driver.vehicleType != null && driver.vehicleType!.isNotEmpty))
                  _buildTagPill(
                    icon: LucideIcons.bike,
                    label: '${driver.vehicleType ?? ""} ${driver.vehiclePlate ?? ""}'.trim(),
                    color: Colors.blueGrey,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: Financial & Wallet Snapshot Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.03)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.06 : 0.04),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        driver.walletBalance < 0
                            ? LucideIcons.alertTriangle
                            : LucideIcons.wallet,
                        size: 15,
                        color: driver.walletBalance < 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        driver.walletBalance < 0
                            ? (isArabic ? 'المديونية المستحقة: ' : 'Owed Debt: ')
                            : (isArabic ? 'رصيد المحفظة: ' : 'Wallet Balance: '),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_formatBalance(driver.walletBalance.abs())} ${l10n.egp}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: driver.walletBalance < 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Row 4: Elegant Horizontal Action Strip (All actions in 1 smooth scrolling line)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionPill(
                    icon: LucideIcons.wallet,
                    label: l10n.actionWallet,
                    color: AppColors.primary,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => ManualTransactionDialog(
                          entityId: driver.id,
                          isVendor: false,
                        ),
                      ).then((_) => ref.read(driversProvider.notifier).refresh());
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: LucideIcons.barChart3,
                    label: isArabic ? 'إحصائيات' : 'Statistics',
                    color: Colors.indigoAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DriverStatisticsScreen(driverId: driver.id, driverName: driver.name),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: LucideIcons.truck,
                    label: l10n.actionAssign,
                    color: Colors.blue,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AssignOrderDialog(driver: driver),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    icon: LucideIcons.calendarClock,
                    label: l10n.actionShifts,
                    color: Colors.purpleAccent,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => DriverShiftsDialog(driver: driver),
                      );
                    },
                  ),
                  if (_canManageDrivers) ...[
                    const SizedBox(width: 8),
                    _buildActionPill(
                      icon: LucideIcons.mapPin,
                      label: l10n.actionLocation,
                      color: Colors.teal,
                      onTap: () => _locateDriver(driver),
                    ),
                    const SizedBox(width: 8),
                    _buildActionPill(
                      icon: LucideIcons.pencil,
                      label: l10n.actionEdit,
                      color: Colors.grey,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => DriverFormDialog(driver: driver),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    if (!driver.isApproved)
                      _buildActionPill(
                        icon: LucideIcons.checkCircle,
                        label: l10n.actionApprove,
                        color: AppColors.success,
                        bg: AppColors.success.withValues(alpha: 0.12),
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          ref.read(driversProvider.notifier).updateDriver(driver.id, {
                            'isApproved': true,
                          }).then((_) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Driver Approved')),
                            );
                          }).catchError((err) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ErrorUtils.translate(context, err)),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          });
                        },
                      )
                    else
                      _buildActionPill(
                        icon: driver.isSuspended ? LucideIcons.checkCircle : LucideIcons.ban,
                        label: driver.isSuspended
                            ? l10n.actionUnsuspend
                            : l10n.actionSuspend,
                        color: driver.isSuspended ? AppColors.success : AppColors.error,
                        bg: (driver.isSuspended ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.12),
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          final notifier = ref.read(driversProvider.notifier);
                          final action = driver.isSuspended
                              ? notifier.unsuspendDriver(driver.id)
                              : notifier.suspendDriver(driver.id);
                          action.then((_) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  driver.isSuspended
                                      ? 'Driver Unsuspended'
                                      : 'Driver Suspended',
                                ),
                              ),
                            );
                          }).catchError((err) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(ErrorUtils.translate(context, err)),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          });
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? bg,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = color ?? theme.colorScheme.onSurface;
    final effectiveBg = bg ?? (isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
        : const Color(0xFFF1F3F5));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? theme.colorScheme.onSurface).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context, AsyncValue<DriversState> state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: state.maybeWhen(
        data: (data) {
          final List<Marker> markers = [];

          // Route Polylines
          final polylines = <Polyline>[];
          final curDriverPos = _currentDriverLocation ?? _selectedDriverLocation;
          if (_selectedDriver != null &&
              curDriverPos != null &&
              _selectedDriverOrder != null) {
            final st =
                (_selectedDriverOrder!['status']?.toString() ?? '').toUpperCase();
            final isHeadingToCustomer = (st == 'PICKED_UP');

            if (isHeadingToCustomer && _orderDeliveryLocation != null) {
              polylines.add(
                Polyline(
                  points: [curDriverPos, _orderDeliveryLocation!],
                  color: AppColors.primary,
                  strokeWidth: 4.5,
                ),
              );
            } else if (!isHeadingToCustomer) {
              if (_orderPickupLocation != null) {
                polylines.add(
                  Polyline(
                    points: [curDriverPos, _orderPickupLocation!],
                    color: Colors.amber.shade700,
                    strokeWidth: 4.5,
                  ),
                );
              }
              if (_orderPickupLocation != null && _orderDeliveryLocation != null) {
                polylines.add(
                  Polyline(
                    points: [_orderPickupLocation!, _orderDeliveryLocation!],
                    color: Colors.blue.withValues(alpha: 0.65),
                    strokeWidth: 3.5,
                  ),
                );
              }
            }
          }

          // Build Markers for unselected drivers
          for (final d in data.drivers) {
            if (_selectedDriver?.id == d.id) {
              // Selected driver is rendered below as animated InDriveVehicleMarker
              continue;
            }
            if (d.location != null && d.location!.length >= 2) {
              final lat = d.location![1];
              final lng = d.location![0];
              markers.add(
                Marker(
                  point: LatLng(lat, lng),
                  width: 38,
                  height: 38,
                  child: GestureDetector(
                    onTap: () => _locateDriver(d),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getStatusColor(context, d.status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.bike,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          // Selected Driver: Smooth Animated InDrive Vehicle Marker
          if (_selectedDriver != null && curDriverPos != null) {
            markers.add(
              Marker(
                point: curDriverPos,
                width: 80,
                height: 80,
                child: RepaintBoundary(
                  child: InDriveVehicleMarker(
                    size: 54,
                    heading: _currentDriverHeading,
                    isMoving: _isDriverMoving,
                    vehicleType: _selectedDriver?.vehicleType ?? 'MOTORCYCLE',
                    plateNumber: _selectedDriver?.vehiclePlate,
                    label: _selectedDriver?.name,
                    color: _selectedDriverIsLive ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            );
          }

          // Active Order Store / Pickup Marker
          if (_orderPickupLocation != null) {
            final vendorMap = _selectedDriverOrder?['vendor'] is Map ? _selectedDriverOrder!['vendor'] as Map : {};
            final vendorBranchMap = _selectedDriverOrder?['vendorBranch'] is Map ? _selectedDriverOrder!['vendorBranch'] as Map : {};
            final vendorStoreName = isArabic
                ? (vendorMap['storeNameAr'] ?? vendorMap['storeName'] ?? vendorMap['name'])
                : (vendorMap['storeName'] ?? vendorMap['storeNameAr'] ?? vendorMap['name']);
            final branchName = isArabic
                ? (vendorBranchMap['nameAr'] ?? vendorBranchMap['name'])
                : (vendorBranchMap['name'] ?? vendorBranchMap['nameAr']);
            final vendorName = (vendorStoreName != null && vendorStoreName.toString().trim().isNotEmpty)
                ? (branchName != null && branchName.toString().trim().isNotEmpty
                    ? '$vendorStoreName - $branchName'
                    : vendorStoreName.toString().trim())
                : (branchName?.toString().trim() ?? (isArabic ? 'المتجر' : 'Vendor'));
            markers.add(
              Marker(
                point: _orderPickupLocation!,
                width: 90,
                height: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        border: Border.all(color: Colors.amber.shade700, width: 1.2),
                      ),
                      child: Text(
                        vendorName,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.store, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }

          // Active Order Customer / Delivery Marker
          if (_orderDeliveryLocation != null) {
            final customerUser = _selectedDriverOrder?['customer']?['user'];
            final custName = customerUser?['name']?.toString() ??
                (isArabic ? 'العميل' : 'Customer');
            markers.add(
              Marker(
                point: _orderDeliveryLocation!,
                width: 90,
                height: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        border: Border.all(color: AppColors.success, width: 1.2),
                      ),
                      child: Text(
                        custName,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.mapPin, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }

          final routePoints = [
            ?curDriverPos,
            ?_orderPickupLocation,
            ?_orderDeliveryLocation,
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: curDriverPos ?? const LatLng(30.0444, 31.2357),
                  initialZoom: curDriverPos != null ? 15 : 12,
                ),
                children: [
                  const AppMapTileLayer(userAgentPackageName: 'com.otlob.admin'),
                  if (_selectedZonePolygon.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _selectedZonePolygon,
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Map Control Floating Actions (Top Bar)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    if (_selectedDriver == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.mousePointerClick, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              isArabic
                                  ? 'انقر على أي سائق على الخريطة لعرض تفاصيله والطلب النشط'
                                  : 'Tap any driver marker to inspect location & active order',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (routePoints.length > 1)
                      FilledButton.icon(
                        onPressed: () => _fitRouteBounds(routePoints),
                        icon: const Icon(LucideIcons.expand, size: 14),
                        label: Text(
                          isArabic ? 'كامل المسار' : 'Fit Route',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.92),
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    if (curDriverPos != null) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          try {
                            _mapController.move(curDriverPos, 16);
                          } catch (_) {}
                        },
                        icon: const Icon(LucideIcons.locateFixed, size: 16),
                        tooltip: isArabic ? 'توسيط على السائق' : 'Center on driver',
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        onPressed: () => _openInMaps(
                          curDriverPos.latitude,
                          curDriverPos.longitude,
                          label: _selectedDriver?.name,
                        ),
                        icon: const Icon(LucideIcons.externalLink, size: 16),
                        tooltip: isArabic ? 'فتح في خرائط Google' : 'Open in Google Maps',
                      ),
                    ],
                  ],
                ),
              ),

              // Selected Driver Detailed Floating Card (Bottom)
              if (_selectedDriver != null && curDriverPos != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: DriverMapDetailsCard(
                    driver: _selectedDriver!,
                    location: curDriverPos,
                    isLive: _selectedDriverIsLive,
                    activeOrder: _selectedDriverOrder,
                    isLoadingOrder: _isLoadingDriverOrder,
                    pickupLocation: _orderPickupLocation,
                    deliveryLocation: _orderDeliveryLocation,
                    onClose: _clearSelectedDriver,
                    onCallPhone: (phone) => _callDriver(phone),
                    onOpenMaps: (lat, lng, {label}) => _openInMaps(lat, lng, label: label),
                    onAssignOrder: () {
                      showDialog(
                        context: context,
                        builder: (context) => AssignOrderDialog(driver: _selectedDriver!),
                      );
                    },
                    onViewOrderDetails: (ord) {
                      showDialog(
                        context: context,
                        builder: (context) => ActiveOrderDetailsDialog(order: ord),
                      );
                    },
                    onCenterOnDriver: () {
                      try {
                        _mapController.move(_selectedDriverLocation!, 16);
                      } catch (_) {}
                    },
                    onCenterOnDelivery: () => _fitRouteBounds(routePoints),
                  ),
                ),
            ],
          );
        },
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Clean balance text: no trailing ".0" on whole amounts, negative
  /// balances (driver owes) stand out in red via the caller.
  String _formatBalance(double value) {
    final isWhole = value.truncateToDouble() == value;
    return value.toStringAsFixed(isWhole ? 0 : 2);
  }

  /// Theme-aware status color. (AppColors.textSecondary is fixed black and
  /// was invisible on dark backgrounds for OFFLINE/unknown drivers.)
  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'ONLINE':
        return AppColors.success;
      case 'ON_DELIVERY':
        return Colors.blue;
      case 'ON_BREAK':
        return AppColors.warning;
      case 'OFFLINE':
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
      case 'SUSPENDED':
        return AppColors.error;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    }
  }

  Color _getDriverBadgeColor(DriverProfile driver) {
    if (!driver.isApproved) return AppColors.warning;
    if (driver.isSuspended) return AppColors.error;
    return AppColors.success;
  }

  String _getDriverBadgeText(BuildContext context, DriverProfile driver) {
    final l10n = AppLocalizations.of(context)!;
    if (!driver.isApproved) return l10n.driverStatusPending;
    if (driver.isSuspended) return l10n.driverStatusSuspended;
    return l10n.driverStatusApproved;
  }

  String _translateDriverStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'ONLINE':
        return l10n.statusOnline;
      case 'ON_DELIVERY':
        return l10n.statusOnDelivery;
      case 'OFFLINE':
        return l10n.statusOffline;
      case 'ON_BREAK':
        return l10n.statusOnBreak;
      case 'SUSPENDED':
        return l10n.suspended;
      default:
        return status;
    }
  }
}
