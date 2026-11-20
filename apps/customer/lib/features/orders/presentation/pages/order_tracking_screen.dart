import 'package:ui_kit/ui_kit.dart' hide AppColors;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart'
    show SocketEvent, orderRevisionOf, orderRevisionTrackerProvider;
import '../../../../core/utils/image_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/token_service.dart';

import 'dart:async';
import 'dart:math' as math;
import '../../../../core/services/location_service.dart';
import '../providers/orders_provider.dart';
import 'package:data/providers.dart';
import '../widgets/order_tracking_sheet.dart';
import '../widgets/rate_order_bottom_sheet.dart';

class _TrackingLifecycleObserver with WidgetsBindingObserver {
  final Future<void> Function() onResume;

  _TrackingLifecycleObserver({required this.onResume}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Wallet label using existing translations only: InstaPay wallets show
/// InstaPay, everything else shows Mobile Wallet. No custom names added.
String _trackingWalletProviderName(Map<dynamic, dynamic> wallet, AppStrings s) {
  if (_trackingIsInstaPay(wallet)) return s.instapay;
  return s.mobileWallet;
}

bool _trackingIsInstaPay(Map<dynamic, dynamic> wallet) {
  return (wallet['type'] ?? wallet['provider'] ?? '')
      .toString()
      .toUpperCase()
      .contains('INSTAPAY');
}

/// Mobile-wallet payments show the mobile-money wallets (Vodafone etc.),
/// not InstaPay — unless InstaPay is all the driver has (fallback).
List<dynamic> _trackingVisibleWallets(List<dynamic> wallets) {
  final mobile = wallets.where((w) {
    final m = w is Map ? Map<dynamic, dynamic>.from(w) : <dynamic, dynamic>{};
    return !_trackingIsInstaPay(m);
  }).toList();
  return mobile.isNotEmpty ? mobile : wallets;
}

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _driverMoveController;
  LatLng? _driverAnimStart;
  LatLng? _driverAnimTarget;
  double _driverHeading = 0.0;
  double _driverStartHeading = 0.0;
  double _driverTargetHeading = 0.0;
  bool _isDriverWalking = false;
  DateTime? _lastCameraMove;

  double get _currentDriverHeading {
    if (_driverMoveController.isAnimating) {
      final t = CurvedAnimation(
        parent: _driverMoveController,
        curve: Curves.easeInOutCubic,
      ).value;
      return _lerpAngle(_driverStartHeading, _driverTargetHeading, t);
    }
    return _driverHeading;
  }

  static double _lerpAngle(double from, double to, double t) {
    double diff = (to - from) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return (from + diff * t) % 360.0;
  }

  LatLng? get _currentDriverLocation {
    if (_driverAnimStart != null && _driverAnimTarget != null && _driverMoveController.isAnimating) {
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
    return _driverLocation;
  }

  String get _driverVehicleType {
    final driver = _orderDetails?['driver'];
    if (driver is Map && driver['vehicleType'] != null) {
      final t = driver['vehicleType'].toString().trim();
      if (t.isNotEmpty) return t;
    }
    final deliveryGroups = _orderDetails?['deliveryGroups'];
    if (deliveryGroups is List && deliveryGroups.isNotEmpty) {
      for (final g in deliveryGroups) {
        if (g is! Map || g['status']?.toString() == 'CANCELLED') continue;
        final d = g['primaryDriver'] ?? g['driver'];
        if (d is Map && d['vehicleType'] != null) {
          final t = d['vehicleType'].toString().trim();
          if (t.isNotEmpty) return t;
        }
      }
    }
    if (_orderDetails?['requestedVehicleType'] != null) {
      final t = _orderDetails!['requestedVehicleType'].toString().trim();
      if (t.isNotEmpty) return t;
    }
    return 'MOTORCYCLE';
  }

  String? get _driverVehiclePlate {
    final driver = _orderDetails?['driver'];
    if (driver is Map && driver['vehiclePlate'] != null) {
      final p = driver['vehiclePlate'].toString().trim();
      if (p.isNotEmpty) return p;
    }
    final deliveryGroups = _orderDetails?['deliveryGroups'];
    if (deliveryGroups is List && deliveryGroups.isNotEmpty) {
      for (final g in deliveryGroups) {
        if (g is! Map || g['status']?.toString() == 'CANCELLED') continue;
        final d = g['primaryDriver'] ?? g['driver'];
        if (d is Map && d['vehiclePlate'] != null) {
          final p = d['vehiclePlate'].toString().trim();
          if (p.isNotEmpty) return p;
        }
      }
    }
    return null;
  }

  String get _driverDisplayName {
    final driver = _orderDetails?['driver'];
    if (driver is Map && driver['name'] != null) {
      final n = driver['name'].toString().trim();
      if (n.isNotEmpty) return n;
    }
    final deliveryGroups = _orderDetails?['deliveryGroups'];
    if (deliveryGroups is List && deliveryGroups.isNotEmpty) {
      for (final g in deliveryGroups) {
        if (g is! Map || g['status']?.toString() == 'CANCELLED') continue;
        final d = g['primaryDriver'] ?? g['driver'];
        if (d is Map && d['name'] != null) {
          final n = d['name'].toString().trim();
          if (n.isNotEmpty) return n;
        }
      }
    }
    return '';
  }

  String? get _driverId {
    final driver = _orderDetails?['driver'];
    if (driver is Map && driver['id'] != null) {
      final id = driver['id'].toString().trim();
      if (id.isNotEmpty) return id;
    }
    final deliveryGroups = _orderDetails?['deliveryGroups'];
    if (deliveryGroups is List && deliveryGroups.isNotEmpty) {
      for (final g in deliveryGroups) {
        if (g is! Map || g['status']?.toString() == 'CANCELLED') continue;
        final d = g['primaryDriver'] ?? g['driver'];
        if (d is Map && d['id'] != null) {
          final id = d['id'].toString().trim();
          if (id.isNotEmpty) return id;
        }
      }
    }
    return null;
  }

  IconData _vehicleIconData(String type) {
    switch (type.toUpperCase()) {
      case 'CAR':
        return Icons.directions_car_rounded;
      case 'BICYCLE':
        return Icons.pedal_bike_rounded;
      case 'VAN':
      case 'TRUCK':
        return Icons.local_shipping_rounded;
      case 'MOTOR_TRICYCLE':
      case 'MOTORCYCLE':
      default:
        return Icons.two_wheeler_rounded;
    }
  }

  String _vehicleTypeLabel(String type, bool isArabic) {
    switch (type.toUpperCase()) {
      case 'CAR':
        return isArabic ? 'سيارة' : 'Car';
      case 'BICYCLE':
        return isArabic ? 'دراجة هوائية' : 'Bicycle';
      case 'VAN':
        return isArabic ? 'فان بضائع' : 'Van';
      case 'TRUCK':
        return isArabic ? 'شاحنة' : 'Truck';
      case 'MOTOR_TRICYCLE':
        return isArabic ? 'تروسيكل' : 'Motor Tricycle';
      case 'MOTORCYCLE':
      default:
        return isArabic ? 'دراجة نارية' : 'Motorcycle';
    }
  }

  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  LatLng? _initialMapCenter;
  LatLng? _deliveryLocation;
  String _orderStatus = 'LOOKING_FOR_DRIVER';
  Map<String, dynamic>? _orderDetails;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _driverLocSub;
  _TrackingLifecycleObserver? _lifecycleObserver;

  bool _followDriver = true;
  Timer? _driverRenderTimer;
  LatLng? _pendingDriverLocation;
  double? _pendingDriverHeading;
  XFile? _receiptFile;
  double _sheetHeightPx = 0.0;

  Future<void> _callDriver(BuildContext context, String phone, AppStrings s) async {
    await ExternalActionLauncher.callPhone(phone, context: context);
  }

  @override
  void initState() {
    super.initState();
    _driverMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _driverMoveController.addListener(() {
      // Throttle camera movement to prevent excessive map redraws on budget devices
      if (_followDriver && _driverAnimTarget != null) {
        final now = DateTime.now();
        if (_lastCameraMove == null || now.difference(_lastCameraMove!).inMilliseconds > 350) {
          _lastCameraMove = now;
          final pos = _currentDriverLocation;
          if (pos != null) {
            final zoom = _mapController.camera.zoom;
            _mapController.move(pos, zoom);
          }
        }
      }
    });
    _driverMoveController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isDriverWalking = false;
          _driverLocation = _driverAnimTarget ?? _driverLocation;
        });
        if (_followDriver && _driverLocation != null) {
          final zoom = _mapController.camera.zoom;
          _mapController.move(_driverLocation!, zoom);
        }
      }
    });
    _initTracking();
  }

  StreamSubscription<void>? _connectSub;
  StreamSubscription<dynamic>? _fulfillmentSub;
  StreamSubscription<dynamic>? _assistSub;
  StreamSubscription<dynamic>? _assignedSub;

  Future<void> _initTracking() async {
    final socket = ref.read(socketServiceProvider);
    final tokenService = ref.read(tokenServiceProvider);
    final locationSvc = ref.read(locationServiceProvider);

    // GPS must never gate order/socket setup: center the map
    // opportunistically with a short timeout, falling back to the order's
    // delivery location below when it fails or is slow.
    locationSvc
        .getCurrentLocation()
        .timeout(const Duration(seconds: 4))
        .then((pos) {
      if (!mounted) return;
      setState(() {
        _initialMapCenter = LatLng(pos.latitude, pos.longitude);
      });
      // We do not move the map here if driverLocation is already set
      if (_driverLocation == null && _initialMapCenter != null) {
        try {
          _mapController.move(_initialMapCenter!, 14.0);
        } catch (_) {}
      }
    }).catchError((e) {
      debugPrint('Failed to get location: $e');
      return null;
    });

    final order = await ref
        .read(ordersProvider.notifier)
        .fetchOrderDetails(widget.orderId);
    if (mounted && order != null) {
      setState(() {
        _orderDetails = order;
        _orderStatus = order['status'] ?? 'LOOKING_FOR_DRIVER';

        // If we failed to get user location, use the delivery location as map center
        if (_initialMapCenter == null &&
            order['deliveryLat'] != null &&
            order['deliveryLng'] != null) {
          final lat = double.tryParse(order['deliveryLat'].toString());
          final lng = double.tryParse(order['deliveryLng'].toString());
          if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
            _deliveryLocation = LatLng(lat, lng);
            if (_initialMapCenter == null) {
              _initialMapCenter = LatLng(lat, lng);
              if (_driverLocation == null) {
                _mapController.move(_initialMapCenter!, 14.0);
              }
            }
          }
        }
      });
      if (_orderStatus == 'DRIVER_ASSIGNED' ||
          _orderStatus == 'PENDING_PAYMENT') {
        _fetchOrderDetails();
      }
      _extractDriverLocationFromOrder();
    }

    final token = await tokenService.getAccessToken();
    if (token != null) {
      await socket.initSocket(token);

      // Seed the driver marker immediately: request the last known location
      // (live Redis, or last persisted) for drivers that are stationary and
      // therefore not emitting position updates.
      _requestDriverLocation(socket);
      _connectSub?.cancel();
      _connectSub = socket.onConnect.listen((_) {
        _requestDriverLocation(socket);
      });

      // onEvent uses broadcast streams that survive socket reconnects/re-auth.
      _fulfillmentSub?.cancel();
      _fulfillmentSub = socket
          .onEvent(SocketEvent.orderFulfillmentUpdated.eventName)
          .listen((data) {
        if (data != null && data['orderId'] == widget.orderId && mounted) {
          setState(() {
            if (_orderDetails != null) {
              final fulfillments = _orderDetails!['vendorFulfillments'];
              if (fulfillments is List) {
                for (var f in fulfillments) {
                  if (f is Map && f['id'] == data['fulfillmentId']) {
                    f['status'] = data['status'];
                    if (data['pickedUpAt'] != null) {
                      f['pickedUpAt'] = data['pickedUpAt'];
                    }
                  }
                }
              }
              if (data['fulfillmentSummary'] != null) {
                _orderDetails!['fulfillmentSummary'] = data['fulfillmentSummary'];
              }
            }
            final incomingOrderStatus = data['orderStatus'] ?? data['parentStatus'] ?? data['newStatus'];
            if (incomingOrderStatus != null) {
              _orderStatus = incomingOrderStatus.toString();
            }
          });
          _fetchOrderDetails();
        }
      });

      _assistSub?.cancel();
      _assistSub = socket
          .onEvent(SocketEvent.orderAssistProposed.eventName)
          .listen((data) {
        if (data != null && data['orderId'] == widget.orderId && mounted) {
          _fetchOrderDetails();
        }
      });

      _assignedSub?.cancel();
      _assignedSub = socket
          .onEvent(SocketEvent.orderAssigned.eventName)
          .listen((data) {
        if (data != null && data['orderId'] == widget.orderId && mounted) {
          _fetchOrderDetails();
          _requestDriverLocation(socket);
        }
      });

      _statusSub?.cancel();
      _statusSub = socket.onEvent(SocketEvent.orderStatus.eventName).listen((data) {
        if (data != null && data['orderId'] == widget.orderId) {
          // The latest transition wins: a stale socket event must not move the
          // tracking status back to an earlier revision.
          final revisions = ref.read(orderRevisionTrackerProvider);
          if (!revisions.accept(widget.orderId, orderRevisionOf(data))) {
            return;
          }
          if (mounted) {
            final newStatus = data['newStatus'] ?? data['status'] ?? _orderStatus;
            setState(() {
              _orderStatus = newStatus.toString();
            });
            _fetchOrderDetails();
            _requestDriverLocation(socket);
          }
        }
      });

      _driverLocSub?.cancel();
      _driverLocSub = socket.onEvent('driver.location').listen((data) {
        if (data != null && (data['orderId'] == widget.orderId || (data['driverId'] != null && data['driverId'] == _driverId))) {
          final lat = (data['latitude'] ?? data['lat'] ?? (data['location'] is List && data['location'].length >= 2 ? data['location'][1] : null)) as num?;
          final lng = (data['longitude'] ?? data['lng'] ?? (data['location'] is List && data['location'].length >= 2 ? data['location'][0] : null)) as num?;
          final heading = (data['heading'] ?? data['bearing']) as num?;
          if (lat != null &&
              lng != null &&
              lat.toDouble().isFinite &&
              lng.toDouble().isFinite &&
              mounted) {
            _queueDriverLocation(
              LatLng(lat.toDouble(), lng.toDouble()),
              heading: heading?.toDouble(),
            );
          }
        }
      });
    }

    // Refetch on resume so any status/driver change that happened while the
    // app was backgrounded (and missed by the socket) is picked up instantly.
    _lifecycleObserver?.dispose();
    _lifecycleObserver = _TrackingLifecycleObserver(onResume: _fetchOrderDetails);

    // Safety net while tracking is open: periodic refresh catches anything
    // the socket missed (drops, background gaps). Stops itself on dispose
    // and once the order reaches a terminal state.
    _detailsRefreshTimer?.cancel();
    _detailsRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      if (_orderStatus == 'DELIVERED' || _orderStatus == 'CANCELLED') {
        _detailsRefreshTimer?.cancel();
        _detailsRefreshTimer = null;
        return;
      }
      _fetchOrderDetails();
    });
  }

  Timer? _detailsRefreshTimer;

  @override
  void dispose() {
    _driverMoveController.dispose();
    _statusSub?.cancel();
    _fulfillmentSub?.cancel();
    _assistSub?.cancel();
    _assignedSub?.cancel();
    _driverLocSub?.cancel();
    _connectSub?.cancel();
    _driverRenderTimer?.cancel();
    _detailsRefreshTimer?.cancel();
    _lifecycleObserver?.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    final order = await ref
        .read(ordersProvider.notifier)
        .fetchOrderDetails(widget.orderId);
    if (mounted && order != null) {
      setState(() {
        _orderDetails = order;
        _orderStatus = order['status']?.toString() ?? _orderStatus;
      });
      _extractDriverLocationFromOrder();
    }
  }

  bool _trackingCanRateOrder(Map<String, dynamic>? order) {
    if (order == null) return false;
    final reviewsRaw = order['reviews'];
    if (reviewsRaw is! List) return order['review'] == null;
    final reviews = reviewsRaw.whereType<Map>().toList();
    final ratedFulfillments = reviews
        .map((r) => r['fulfillmentId']?.toString())
        .whereType<String>()
        .toSet();
    final ratedGroups = reviews
        .map((r) => r['deliveryGroupId']?.toString())
        .whereType<String>()
        .toSet();

    final fulfillments = order['vendorFulfillments'];
    if (fulfillments is List && fulfillments.isNotEmpty) {
      final hasUnratedFulfillment = fulfillments.whereType<Map>().any((f) {
        final fid = f['id']?.toString();
        final fStatus = f['status']?.toString() ?? '';
        return fid != null &&
            fStatus != 'REJECTED' &&
            fStatus != 'CANCELLED' &&
            !ratedFulfillments.contains(fid);
      });
      if (hasUnratedFulfillment) return true;
    }

    final groups = order['deliveryGroups'];
    if (groups is List && groups.isNotEmpty) {
      return groups.whereType<Map>().any((g) {
        final gid = g['id']?.toString();
        final gStatus = g['status']?.toString() ?? '';
        final drv = g['primaryDriver'] ?? g['driver'];
        final hasDriver = g['primaryDriverId'] != null ||
            (drv is Map && drv['id'] != null);
        return gid != null &&
            gStatus == 'DELIVERED' &&
            hasDriver &&
            !ratedGroups.contains(gid);
      });
    }
    return reviews.isEmpty && order['review'] == null;
  }

  List<Widget> _buildAssignedDriversSection(AppStrings s, bool isDark) {
    final details = _orderDetails;
    if (details == null) return const [];

    final groupsRaw = details['deliveryGroups'];
    final activeGroups = (groupsRaw is List ? groupsRaw : const [])
        .whereType<Map>()
        .where((g) => g['status']?.toString() != 'CANCELLED')
        .where((g) => (g['primaryDriver'] ?? g['driver']) is Map)
        .toList();

    if (activeGroups.length > 1) {
      final seenKeys = <String>{};
      final widgets = <Widget>[];
      for (final g in activeGroups) {
        final drv = Map<String, dynamic>.from(
          (g['primaryDriver'] ?? g['driver']) as Map,
        );
        final seq = g['sequence'] ?? 1;
        final key = '${drv['id'] ?? seq}|$seq';
        if (!seenKeys.add(key)) continue;
        widgets.add(
          _buildSingleDriverCard(
            drv,
            s,
            isDark,
            groupLabel: s.isArabic ? 'التوصيل #$seq' : 'Trip #$seq',
          ),
        );
        widgets.add(const SizedBox(height: 10));
      }
      if (widgets.isNotEmpty) return widgets;
    }

    final fallbackDriver = details['driver'] is Map
        ? Map<String, dynamic>.from(details['driver'] as Map)
        : (activeGroups.isNotEmpty
            ? Map<String, dynamic>.from(
                (activeGroups.first['primaryDriver'] ??
                    activeGroups.first['driver']) as Map,
              )
            : null);
    if (fallbackDriver == null) return const [];

    return [
      _buildSingleDriverCard(fallbackDriver, s, isDark),
      const SizedBox(height: 12),
    ];
  }

  Widget _buildSingleDriverCard(
    Map<String, dynamic> driver,
    AppStrings s,
    bool isDark, {
    String? groupLabel,
  }) {
    final vehicleType =
        (driver['vehicleType']?.toString().trim().isNotEmpty ?? false)
            ? driver['vehicleType'].toString().trim()
            : _driverVehicleType;
    final vehiclePlate = driver['vehiclePlate']?.toString().trim();
    final phone =
        (driver['phone'] ?? driver['user']?['phone'])?.toString().trim() ?? '';
    final avatar =
        (driver['avatar'] ?? driver['user']?['avatar'])?.toString().trim() ??
            '';
    final ratingCount = (driver['ratingCount'] as num?)?.toInt() ?? 0;
    final ratingRaw = (driver['rating'] as num?)?.toDouble() ?? 500.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppNetworkAvatar(
                imageUrl: ImageUtils.formatImageUrl(avatar),
                size: 42,
                fallbackIcon: Icons.person,
                fallbackIconSize: 22,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    _vehicleIconData(vehicleType),
                    size: 11,
                    color: AppColors.primary,
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
                if (groupLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      groupLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Text(
                  driver['name']?.toString() ??
                      (s.isArabic ? 'كابتن التوصيل' : 'Delivery Captain'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _vehicleTypeLabel(vehicleType, s.isArabic),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    if (vehiclePlate != null && vehiclePlate.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          vehiclePlate,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              onPressed: () => _callDriver(context, phone, s),
              icon: const Icon(Icons.phone_rounded),
              color: AppColors.primary,
              tooltip: s.isArabic ? 'اتصال' : 'Call',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                shape: const CircleBorder(),
              ),
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (ratingCount > 0) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (ratingRaw / 100).toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  '($ratingCount)',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _extractDriverLocationFromOrder() {
    if (_driverLocation != null) return;
    final driver = _orderDetails?['driver'];
    if (driver is Map) {
      final loc = driver['location'];
      if (loc is List && loc.length >= 2) {
        final lng = (loc[0] as num?)?.toDouble();
        final lat = (loc[1] as num?)?.toDouble();
        if (lat != null && lng != null && lat.isFinite && lng.isFinite && (lat != 0 || lng != 0)) {
          _applyInitialDriverLocation(LatLng(lat, lng));
          return;
        }
      }
      final lat = (driver['latitude'] ?? driver['lat']) as num?;
      final lng = (driver['longitude'] ?? driver['lng']) as num?;
      if (lat != null && lng != null && lat.toDouble().isFinite && lng.toDouble().isFinite && (lat != 0 || lng != 0)) {
        _applyInitialDriverLocation(LatLng(lat.toDouble(), lng.toDouble()));
        return;
      }
    }
    final deliveryGroups = _orderDetails?['deliveryGroups'];
    if (deliveryGroups is List && deliveryGroups.isNotEmpty) {
      for (final g in deliveryGroups) {
        if (g is! Map || g['status']?.toString() == 'CANCELLED') continue;
        final d = g['primaryDriver'] ?? g['driver'];
        if (d is Map) {
          final loc = d['location'];
          if (loc is List && loc.length >= 2) {
            final lng = (loc[0] as num?)?.toDouble();
            final lat = (loc[1] as num?)?.toDouble();
            if (lat != null && lng != null && lat.isFinite && lng.isFinite && (lat != 0 || lng != 0)) {
              _applyInitialDriverLocation(LatLng(lat, lng));
              return;
            }
          }
          final lat = (d['latitude'] ?? d['lat']) as num?;
          final lng = (d['longitude'] ?? d['lng']) as num?;
          if (lat != null && lng != null && lat.toDouble().isFinite && lng.toDouble().isFinite && (lat != 0 || lng != 0)) {
            _applyInitialDriverLocation(LatLng(lat.toDouble(), lng.toDouble()));
            return;
          }
        }
      }
    }
  }

  void _applyInitialDriverLocation(LatLng pos) {
    if (_driverLocation != null || !mounted) return;
    setState(() {
      _driverLocation = pos;
    });
    if (_followDriver) {
      try {
        _mapController.move(pos, 15.0);
      } catch (_) {}
    }
  }

  String _getDisplayStatus(String rawStatus, bool isAr) =>
      formatTrackingDisplayStatus(rawStatus, isAr);

  // Status label shown in the header. During the PICKED_UP leg (which covers the
  // whole drive to the customer, since the backend has no ARRIVING/IN_TRANSIT),
  // the wording depends on how close the driver actually is: "On the Way" until
  // ~1km, then "Arriving".
  String _statusLabel(bool isAr) {
    if (_orderStatus == 'PICKED_UP') {
      final distance = _driverDistanceMeters();
      if (distance != null && distance < 1000) {
        return isAr ? 'الكابتن على وشك الوصول' : 'Driver is almost there';
      }
      return isAr ? 'الكابتن في الطريق إليك' : 'Driver is on the way';
    }
    return _getDisplayStatus(_orderStatus, isAr);
  }

  void _requestDriverLocation(SocketService socket) {
    try {
      socket.emit('driver.location.request', {'orderId': widget.orderId});
    } catch (e) {
      debugPrint('Failed to request driver location: $e');
    }
  }

  // Coalesce bursts of location events into a single map update (latest wins)
  // so the UI rebuilds at most ~5x/second no matter how fast the socket emits.
  void _queueDriverLocation(LatLng point, {double? heading}) {
    _pendingDriverLocation = point;
    _pendingDriverHeading = heading;
    _driverRenderTimer ??=
        Timer(const Duration(milliseconds: 180), _applyDriverLocation);
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

  void _applyDriverLocation() {
    _driverRenderTimer = null;
    final target = _pendingDriverLocation;
    final explicitHeading = _pendingDriverHeading;
    _pendingDriverLocation = null;
    _pendingDriverHeading = null;
    if (target == null || !mounted) return;

    if (_driverLocation == null) {
      setState(() {
        _driverLocation = target;
        if (explicitHeading != null) {
          _driverHeading = explicitHeading;
          _driverStartHeading = explicitHeading;
          _driverTargetHeading = explicitHeading;
        }
      });
      if (_followDriver) {
        try {
          _mapController.move(target, 15.0);
        } catch (_) {}
      }
      return;
    }

    final currentPos = _currentDriverLocation ?? _driverLocation!;
    final dist = const Distance().as(LengthUnit.Meter, currentPos, target);
    if (dist < 0.5) return;

    final newHeading = explicitHeading ?? _calculateBearing(currentPos, target);
    _driverStartHeading = _currentDriverHeading;
    _driverTargetHeading = newHeading;
    _driverHeading = newHeading;
    _driverAnimStart = currentPos;
    _driverAnimTarget = target;
    _driverLocation = currentPos;
    _isDriverWalking = true;
    _driverMoveController.forward(from: 0.0);
  }

  void _recenterOnDriver() {
    final driverPos = _currentDriverLocation ?? _driverLocation;
    final destPos = _deliveryLocation ?? _initialMapCenter;
    final s = AppStrings.of(context);

    if (driverPos != null) {
      setState(() => _followDriver = true);
      final currentZoom = _mapController.camera.zoom;
      final targetZoom = currentZoom < 14.5 ? 16.0 : currentZoom;
      _mapController.move(driverPos, targetZoom);
      return;
    }

    if (destPos != null) {
      setState(() => _followDriver = false);
      _mapController.move(destPos, 15.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            s.isArabic
                ? 'في انتظار تحديد موقع الكابتن، تم التمركز على موقع التوصيل'
                : 'Waiting for captain location, centered on delivery address',
          ),
        ),
      );
      return;
    }

    final storeStops = _extractStoreStops(s.isArabic);
    if (storeStops.isNotEmpty) {
      final stop = storeStops.first;
      final lat = stop['lat'] as double?;
      final lng = stop['lng'] as double?;
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        setState(() => _followDriver = false);
        _mapController.move(LatLng(lat, lng), 15.0);
      }
    }
  }

  void _fitEntireRoute(List<LatLng> tripPath) {
    if (tripPath.isEmpty) return;
    setState(() => _followDriver = false);

    if (tripPath.length == 1) {
      _mapController.move(tripPath.first, 15.0);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints(tripPath);
      final bottomPad = math.max(70.0, _sheetHeightPx + 36.0);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.fromLTRB(50, 50, 50, bottomPad),
        ),
      );
    } catch (e) {
      debugPrint('Failed to fit route bounds: $e');
    }
  }

  double? _driverDistanceMeters() {
    final from = _initialMapCenter ?? _deliveryLocation;
    if (_driverLocation == null || from == null) return null;
    return const Distance().as(LengthUnit.Meter, from, _driverLocation!);
  }

  String _distanceLabel(double meters) {
    final s = AppStrings.of(context);
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} ${s.isArabic ? 'م' : 'm'}';
    }
    return '${(meters / 1000).toStringAsFixed(1)} ${s.isArabic ? 'كم' : 'km'}';
  }

  List<Map<String, dynamic>> _extractStoreStops(bool isArabic) {
    final List<Map<String, dynamic>> stops = [];
    if (_orderDetails == null) return stops;

    final fulfillments = _orderDetails!['vendorFulfillments'];
    if (fulfillments is List && fulfillments.isNotEmpty) {
      for (int i = 0; i < fulfillments.length; i++) {
        final f = fulfillments[i];
        if (f is! Map) continue;
        final v = f['vendor'] is Map ? f['vendor'] as Map : {};
        final b = f['vendorBranch'] is Map ? f['vendorBranch'] as Map : {};

        double sLat = 0.0;
        double sLng = 0.0;
        if (b['location'] is List && (b['location'] as List).length > 1) {
          sLng = double.tryParse(b['location'][0].toString()) ?? 0.0;
          sLat = double.tryParse(b['location'][1].toString()) ?? 0.0;
        } else if (b['lat'] != null && b['lng'] != null) {
          sLat = double.tryParse(b['lat'].toString()) ?? 0.0;
          sLng = double.tryParse(b['lng'].toString()) ?? 0.0;
        } else if (v['latitude'] != null && v['longitude'] != null) {
          sLat = double.tryParse(v['latitude'].toString()) ?? 0.0;
          sLng = double.tryParse(v['longitude'].toString()) ?? 0.0;
        }

        if (sLat == 0.0 || sLng == 0.0) continue;

        final storeName = (isArabic
                ? (v['storeNameAr'] ?? v['storeName'] ?? v['name'] ?? 'متجر')
                : (v['storeName'] ?? v['storeNameAr'] ?? v['name'] ?? 'Store'))
            .toString();
        final branchName = (isArabic
                ? (b['nameAr'] ?? b['name'] ?? '')
                : (b['name'] ?? b['nameAr'] ?? ''))
            .toString();
        final fStatus = f['status']?.toString() ?? 'PENDING';
        if (fStatus == 'REJECTED' || fStatus == 'CANCELLED') continue;
        final isPickedUp = fStatus == 'PICKED_UP' || f['pickedUpAt'] != null || _orderStatus == 'PICKED_UP' || _orderStatus == 'DELIVERED';

        stops.add({
          'index': i + 1,
          'name': branchName.isNotEmpty ? '$storeName ($branchName)' : storeName,
          'storeName': storeName,
          'lat': sLat,
          'lng': sLng,
          'status': fStatus,
          'isPickedUp': isPickedUp,
        });
      }
    } else {
      final v = _orderDetails!['vendor'] is Map ? _orderDetails!['vendor'] as Map : {};
      final b = _orderDetails!['vendorBranch'] is Map ? _orderDetails!['vendorBranch'] as Map : {};
      final pickupLoc = _orderDetails!['pickupLocation'];

      double sLat = 0.0;
      double sLng = 0.0;
      if (pickupLoc is List && pickupLoc.length > 1) {
        sLng = double.tryParse(pickupLoc[0].toString()) ?? 0.0;
        sLat = double.tryParse(pickupLoc[1].toString()) ?? 0.0;
      } else if (b['lat'] != null && b['lng'] != null) {
        sLat = double.tryParse(b['lat'].toString()) ?? 0.0;
        sLng = double.tryParse(b['lng'].toString()) ?? 0.0;
      } else if (v['latitude'] != null && v['longitude'] != null) {
        sLat = double.tryParse(v['latitude'].toString()) ?? 0.0;
        sLng = double.tryParse(v['longitude'].toString()) ?? 0.0;
      }

      if (sLat != 0.0 && sLng != 0.0) {
        final storeName = (isArabic
                ? (v['storeNameAr'] ?? v['storeName'] ?? v['name'] ?? 'متجر')
                : (v['storeName'] ?? v['storeNameAr'] ?? v['name'] ?? 'Store'))
            .toString();
        final isPickedUp = _orderStatus == 'PICKED_UP' || _orderStatus == 'DELIVERED';
        stops.add({
          'index': 1,
          'name': storeName,
          'storeName': storeName,
          'lat': sLat,
          'lng': sLng,
          'status': _orderStatus,
          'isPickedUp': isPickedUp,
        });
      }
    }
    return stops;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeStops = _extractStoreStops(s.isArabic);
    final isMultipleStores = storeStops.length > 1;
    final destPos = _deliveryLocation ?? _initialMapCenter;

    // Build the dynamic sequential trip polyline
    final List<LatLng> tripPath = [];
    if (_driverLocation != null) {
      tripPath.add(_driverLocation!);
    }
    for (final stop in storeStops) {
      if (stop['isPickedUp'] != true) {
        tripPath.add(LatLng(stop['lat'] as double, stop['lng'] as double));
      }
    }
    if (destPos != null) {
      tripPath.add(destPos);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.isArabic ? 'تتبع الطلب' : 'Track Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Stack(
        children: [
          if (_orderDetails == null && _driverLocation == null && _initialMapCenter == null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_driverLocation == null && _initialMapCenter == null)
            ColoredBox(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _driverLocation ?? _initialMapCenter!,
                initialZoom: 14.0,
                // Stop following the driver as soon as the user pans the map;
                // the follow button re-centers and resumes.
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && _followDriver && mounted) {
                    setState(() => _followDriver = false);
                  }
                },
              ),
              children: [
                const AppMapTileLayer(userAgentPackageName: 'com.otlob.customer'),
                AnimatedBuilder(
                  animation: _driverMoveController,
                  builder: (context, _) {
                    final currentDriverPos = _currentDriverLocation ?? _driverLocation;
                    final List<LatLng> liveTripPath = [];
                    if (currentDriverPos != null) {
                      liveTripPath.add(currentDriverPos);
                    }
                    for (final stop in storeStops) {
                      if (stop['isPickedUp'] != true) {
                        liveTripPath.add(LatLng(stop['lat'] as double, stop['lng'] as double));
                      }
                    }
                    if (destPos != null) {
                      liveTripPath.add(destPos);
                    }

                    if (liveTripPath.length < 2) return const SizedBox.shrink();
                    return PolylineLayer(
                      polylines: [
                        Polyline(
                          points: liveTripPath,
                          color: AppColors.primary,
                          strokeWidth: 4.0,
                        ),
                      ],
                    );
                  },
                ),

                // 1. Store Pickup Stops Markers
                if (storeStops.isNotEmpty)
                  MarkerLayer(
                    markers: storeStops.map((stop) {
                      final point = LatLng(stop['lat'] as double, stop['lng'] as double);
                      final bool isPickedUp = stop['isPickedUp'] == true;
                      final int stopIndex = stop['index'] as int;
                      final String storeName = stop['name'] as String;

                      return Marker(
                        point: point,
                        width: 112,
                        height: 66,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.15,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: isPickedUp ? AppColors.success : const Color(0xFFF59E0B),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                isMultipleStores
                                    ? '${s.isArabic ? "محطة" : "Stop"} $stopIndex: $storeName'
                                    : storeName,
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
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isPickedUp ? AppColors.success : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPickedUp ? Icons.check_rounded : Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                if (isMultipleStores)
                                  PositionedDirectional(
                                    top: -2,
                                    end: -2,
                                    child: CircleAvatar(
                                      radius: 7,
                                      backgroundColor: isPickedUp ? Colors.green.shade900 : Colors.black87,
                                      child: Text(
                                        '$stopIndex',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // 2. Customer Delivery Destination Marker
                if (destPos != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: destPos,
                        width: 100,
                        height: 64,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.15,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
                                ),
                                child: Text(
                                  s.isArabic ? 'موقع التوصيل' : 'Delivery Address',
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                AnimatedBuilder(
                  animation: _driverMoveController,
                  builder: (context, _) {
                    final pos = _currentDriverLocation;
                    if (pos == null) return const SizedBox.shrink();
                    final heading = _currentDriverHeading;
                    final vehicleType = _driverVehicleType;
                    final plate = _driverVehiclePlate;
                    final driverName = _driverDisplayName;
                    final labelText = plate ?? (driverName.isNotEmpty ? driverName : (s.isArabic ? 'الكابتن' : 'Driver'));

                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: pos,
                          width: 80,
                          height: 80,
                          child: RepaintBoundary(
                            child: InDriveVehicleMarker(
                              size: 54,
                              heading: heading,
                              isMoving: _isDriverWalking,
                              vehicleType: vehicleType,
                              plateNumber: plate,
                              label: labelText,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          OrderTrackingSheetOverlay(
            orderStatus: _orderStatus,
            statusLabel: _statusLabel(s.isArabic),
            distanceLabel: _driverDistanceMeters() != null
                ? _distanceLabel(_driverDistanceMeters()!)
                : null,
            orderDetails: _orderDetails,
            tripPathLength: tripPath.length,
            followDriver: _followDriver,
            onFitRoute: tripPath.length >= 2
                ? () => _fitEntireRoute(tripPath)
                : null,
            onRecenterDriver: _recenterOnDriver,
            onOpenChat: () => _openOrderChat(context, s),
            onRateOrder: _orderStatus == 'DELIVERED' &&
                    _trackingCanRateOrder(_orderDetails)
                ? () async {
                    final rated = await RateOrderBottomSheet.show(
                      context,
                      widget.orderId,
                      order: _orderDetails,
                    );
                    if (rated == true && mounted) {
                      _fetchOrderDetails();
                    }
                  }
                : null,
            assistPromptWidget: _buildAssistPromptWidget(context, s),
            pendingPaymentWidget: _buildPendingPaymentWidget(context, s),
            assignedDriversWidgets: _orderDetails != null
                ? _buildAssignedDriversSection(s, isDark)
                : const [],
            onSheetHeightChanged: (heightPx) => _sheetHeightPx = heightPx,
          ),
        ],
      ),
    );
  }

  Future<void> _openOrderChat(BuildContext context, AppStrings s) async {
    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      final conversation = await chatRepo.createOrderConversation(
        widget.orderId,
      );
      if (!context.mounted) return;
      if (conversation != null) {
        final convoData = conversation is Map && conversation.containsKey('data')
            ? conversation['data']
            : conversation;
        final convoId = convoData['id'] ?? widget.orderId;
        final orderNum = _orderDetails?['orderNumber'] ??
            convoData['order']?['orderNumber'] ??
            (widget.orderId.length >= 8
                ? widget.orderId.substring(0, 8)
                : widget.orderId);
        final title = s.isArabic ? 'طلب #$orderNum' : 'Order #$orderNum';
        ref.read(sharedInboxProvider.notifier).refresh();
        await context.push(
          '/chat/order/$convoId',
          extra: {
            'title': title,
            'orderId': widget.orderId,
          },
        );
        if (mounted) {
          ref.read(sharedInboxProvider.notifier).refresh();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  Widget? _buildAssistPromptWidget(BuildContext context, AppStrings s) {
    final order = _orderDetails;
    if (order == null) return null;
    final deliveryGroups = order['deliveryGroups'] is List
        ? order['deliveryGroups'] as List
        : const [];

    Map? pendingGroup;
    for (final g in deliveryGroups) {
      if (g is Map &&
          g['assistDriverId'] != null &&
          g['assistCustomerApproved'] == null) {
        pendingGroup = g;
        break;
      }
    }

    final isSinglePending =
        order['assistDriverId'] != null &&
        order['assistCustomerApproved'] == null;
    if (!isSinglePending && pendingGroup == null) return null;

    final fee = pendingGroup != null
        ? (pendingGroup['assistFee']?.toString() ?? '0')
        : (order['assistFee']?.toString() ?? '0');
    final deliveryGroupId = pendingGroup?['id']?.toString();
    final groupSeq = pendingGroup?['sequence'];
    final hasMultipleGroups = deliveryGroups.length > 1;
    final isAr = s.isArabic;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_add_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? (hasMultipleGroups && groupSeq != null
                            ? 'طلب مندوب مساعد إضافي للشحنة #$groupSeq'
                            : 'طلب مندوب مساعد إضافي للشحنة')
                      : (hasMultipleGroups && groupSeq != null
                            ? 'Assistant Driver Assigned (Trip #$groupSeq)'
                            : 'Assistant Driver Assigned'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'تم تعيين كابتن مساعد إضافي لدعم توصيل الطلب. الرسوم الإضافية: $fee ج.م. يرجى تأكيد موافقتك للمتابعة.'
                : 'An assistant driver has been assigned to support delivery (Fee: $fee EGP). Please confirm your decision to continue.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(ordersProvider.notifier)
                        .decideAssistOrder(
                          widget.orderId,
                          approve: false,
                          deliveryGroupId: deliveryGroupId,
                        );
                    if (!context.mounted) return;
                    if (ok) {
                      _fetchOrderDetails();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'تعذر إرسال القرار. حاول مرة أخرى.'
                                : 'Failed to submit decision. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isAr ? 'رفض' : 'Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(ordersProvider.notifier)
                        .decideAssistOrder(
                          widget.orderId,
                          approve: true,
                          deliveryGroupId: deliveryGroupId,
                        );
                    if (!context.mounted) return;
                    if (ok) {
                      _fetchOrderDetails();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr
                                ? 'تعذر إرسال القرار. حاول مرة أخرى.'
                                : 'Failed to submit decision. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(isAr ? 'موافقة' : 'Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildPendingPaymentWidget(BuildContext context, AppStrings s) {
    if (_orderStatus != 'PENDING_PAYMENT') return null;

    final upfront = double.tryParse(
          _orderDetails?['upfrontAmount']?.toString() ?? '0',
        ) ??
        0.0;
    final total = double.tryParse(
          (_orderDetails?['grandTotal'] ?? _orderDetails?['total'])
                  ?.toString() ??
              '0',
        ) ??
        0.0;
    // Cash on delivery with an upfront requirement: the customer pays the
    // upfront first. Mobile wallet / InstaPay: always the whole amount.
    final isUpfront =
        (_orderDetails?['paymentMethod']?.toString() ?? '') ==
            'CASH_ON_DELIVERY' &&
        upfront > 0;
    final amountDue = isUpfront ? upfront : total;
    final paidClaimed =
        (_orderDetails?['paymentStatus']?.toString() ?? '') == 'PAID';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isUpfront
                  ? (s.isArabic
                        ? 'المبلغ المقدم المطلوب دفعه أولاً: ${amountDue.toStringAsFixed(0)} ${s.egp}'
                        : 'Upfront amount to pay first: ${amountDue.toStringAsFixed(0)} ${s.egp}')
                  : (s.isArabic
                        ? 'المبلغ المطلوب تحويله: ${amountDue.toStringAsFixed(0)} ${s.egp}'
                        : 'Amount to transfer: ${amountDue.toStringAsFixed(0)} ${s.egp}'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
          ),
          Text(
            s.isArabic
                ? 'يرجى تحويل المبلغ للكابتن على المحفظة الإلكترونية ثم تأكيد التحويل. يمكنك استخدام المحادثة لإرسال الإيصال.'
                : "Please transfer the amount to the driver's mobile wallet, then confirm. You can use chat to send the receipt.",
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (_orderDetails != null &&
              _orderDetails!['driver'] != null &&
              _orderDetails!['driver']['mobileWallets'] != null &&
              (_orderDetails!['driver']['mobileWallets'] as List).isNotEmpty)
            ..._trackingVisibleWallets(
              _orderDetails!['driver']['mobileWallets'] as List,
            ).map((wallet) {
              final walletMap = wallet is Map
                  ? Map<dynamic, dynamic>.from(wallet)
                  : <dynamic, dynamic>{};
              final number =
                  (walletMap['number'] ?? walletMap['walletNumber'] ?? '')
                      .toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_trackingWalletProviderName(walletMap, s)}: $number',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          const SizedBox(height: 12),
          if (paidClaimed)
            Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.isArabic
                        ? 'تم إرسال تأكيدك. بانتظار أن يؤكد الكابتن استلام المبلغ.'
                        : 'Your confirmation was sent. Waiting for the driver to confirm receipt.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1920,
                        imageQuality: 80,
                      );
                      if (file != null && mounted) {
                        setState(() => _receiptFile = file);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        MediaPermissionHelper.handlePickerError(
                          e,
                          context: context,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: Text(
                    _receiptFile != null
                        ? (_receiptFile!.name.isNotEmpty
                              ? _receiptFile!.name
                              : (s.isArabic
                                    ? 'تم إرفاق الإيصال'
                                    : 'Receipt attached'))
                        : (s.isArabic
                              ? 'إرفاق لقطة شاشة من التحويل (إجباري)'
                              : 'Attach transfer screenshot (required)'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_receiptFile != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_receiptFile!.path),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_receiptFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              s.isArabic
                                  ? 'يرجى إرفاق لقطة الشاشة أولاً'
                                  : 'Please attach the screenshot first',
                            ),
                          ),
                        );
                        return;
                      }
                      final success = await ref
                          .read(ordersProvider.notifier)
                          .markPaymentPaid(
                            widget.orderId,
                            receiptPath: _receiptFile!.path,
                          );
                      if (success) {
                        setState(() => _receiptFile = null);
                        await _fetchOrderDetails();
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? (s.isArabic ? 'تم التأكيد!' : 'Confirmed!')
                                : (s.isArabic
                                      ? 'فشل التأكيد. حاول مرة أخرى.'
                                      : 'Confirmation failed. Try again.'),
                          ),
                          backgroundColor: success ? null : Colors.red,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(
                      isUpfront
                          ? (s.isArabic
                                ? 'لقد دفعت المبلغ المقدم'
                                : 'I Have Paid the Upfront')
                          : (s.isArabic
                                ? 'لقد قمت بالتحويل'
                                : 'I Have Transferred the Payment'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
