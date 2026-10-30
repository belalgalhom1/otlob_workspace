import 'package:ui_kit/ui_kit.dart' hide AppColors;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:url_launcher/url_launcher.dart';
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
  bool _isDriverWalking = false;
  DateTime? _lastCameraMove;
  LatLng? get _currentDriverLocation {
    if (_driverAnimStart != null && _driverAnimTarget != null && _driverMoveController.isAnimating) {
      final t = _driverMoveController.value;
      final curLat = _driverAnimStart!.latitude +
          (_driverAnimTarget!.latitude - _driverAnimStart!.latitude) * t;
      final curLng = _driverAnimStart!.longitude +
          (_driverAnimTarget!.longitude - _driverAnimStart!.longitude) * t;
      return LatLng(curLat, curLng);
    }
    return _driverLocation;
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
  XFile? _receiptFile;

  String get _driverPhone {
    final driver = _orderDetails?['driver'];
    if (driver is! Map) return '';
    final direct = driver['phone']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final user = driver['user'];
    if (user is Map) return user['phone']?.toString().trim() ?? '';
    return '';
  }

  Future<void> _callDriver(BuildContext context, String phone, AppStrings s) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isArabic ? 'تعذر بدء الاتصال' : 'Could not start the call'),
        ),
      );
    }
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
            _mapController.move(pos, 15.0);
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
          _mapController.move(_driverLocation!, 15.0);
        }
      }
    });
    _initTracking();
  }

  StreamSubscription<void>? _connectSub;

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
      _statusSub?.cancel();
      _statusSub = socket.onEvent('order.status').listen((data) {
        if (data != null && data['orderId'] == widget.orderId) {
          if (mounted) {
            setState(() {
              _orderStatus =
                  data['newStatus'] ?? data['status'] ?? _orderStatus;
            });
            if (_orderStatus == 'DRIVER_ASSIGNED' ||
                _orderStatus == 'PENDING_PAYMENT') {
              _fetchOrderDetails();
            }
          }
        }
      });

      _driverLocSub?.cancel();
      _driverLocSub = socket.onEvent('driver.location').listen((data) {
        if (data != null && data['orderId'] == widget.orderId) {
          final lat = (data['latitude'] ?? data['lat']) as double?;
          final lng = (data['longitude'] ?? data['lng']) as double?;
          if (lat != null &&
              lng != null &&
              lat.isFinite &&
              lng.isFinite &&
              mounted) {
            _queueDriverLocation(LatLng(lat, lng));
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
      });
    }
  }

  String _getDisplayStatus(String rawStatus, bool isAr) {
    switch (rawStatus) {
      case 'PENDING':
        return isAr ? 'بإنتظار المطعم' : 'Pending Vendor';
      case 'LOOKING_FOR_DRIVER':
        return isAr ? 'جاري البحث عن كابتن...' : 'Looking for Driver...';
      case 'ACCEPTED':
        return isAr ? 'تم القبول' : 'Accepted';
      case 'PREPARING':
        return isAr ? 'قيد التحضير' : 'Preparing';
      case 'READY_FOR_PICKUP':
        return isAr ? 'جاهز للاستلام' : 'Ready for Pickup';
      case 'PICKED_UP':
        return isAr ? 'الطلب في الطريق إليك' : 'On the Way';
      case 'DELIVERED':
        return isAr ? 'تم التوصيل' : 'Delivered';
      case 'CANCELLED':
        return isAr ? 'تم الإلغاء' : 'Cancelled';
      case 'DRIVER_ASSIGNED':
        return isAr ? 'تم تعيين كابتن' : 'Driver Assigned';
      case 'PENDING_PAYMENT':
        return isAr ? 'بانتظار الدفع' : 'Pending Payment';
      default:
        return rawStatus
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '',
            )
            .join(' ');
    }
  }

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
  // so the UI rebuilds at most ~3x/second no matter how fast the socket emits.
  void _queueDriverLocation(LatLng point) {
    _pendingDriverLocation = point;
    _driverRenderTimer ??=
        Timer(const Duration(milliseconds: 300), _applyDriverLocation);
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
    _pendingDriverLocation = null;
    if (target == null || !mounted) return;

    if (_driverLocation == null) {
      setState(() {
        _driverLocation = target;
      });
      if (_followDriver) {
        _mapController.move(target, 15.0);
      }
      return;
    }

    final dist = const Distance().as(LengthUnit.Meter, _driverLocation!, target);
    if (dist < 1.0) return;

    _driverHeading = _calculateBearing(_driverLocation!, target);
    _driverAnimStart = _driverLocation;
    _driverAnimTarget = target;
    _isDriverWalking = true;
    _driverMoveController.forward(from: 0.0);
  }

  void _toggleFollow() {
    setState(() => _followDriver = !_followDriver);
    if (_followDriver && _driverLocation != null) {
      _mapController.move(_driverLocation!, 16.0);
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

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          if (_driverLocation == null && _initialMapCenter == null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                if (_driverLocation != null && _initialMapCenter != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_driverLocation!, _initialMapCenter!],
                        color: AppColors.primary,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                if (_initialMapCenter != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _initialMapCenter!,
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
                AnimatedBuilder(
                  animation: _driverMoveController,
                  builder: (context, _) {
                    final pos = _currentDriverLocation;
                    if (pos == null) return const SizedBox.shrink();
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: pos,
                          width: 68,
                          height: 68,
                          child: RepaintBoundary(
                            child: LiveWalkingDriverMarker(
                              heading: _driverHeading,
                              isWalking: _isDriverWalking,
                              color: AppColors.primary,
                              label: s.isArabic ? 'الكابتن' : 'Driver',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton(
              heroTag: 'track_follow_driver',
              onPressed: _toggleFollow,
              backgroundColor: _followDriver ? AppColors.primary : Colors.white,
              foregroundColor:
                  _followDriver ? Colors.white : AppColors.primary,
              child: Icon(
                _followDriver ? Icons.my_location : Icons.location_searching,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  Text(
                    s.isArabic ? 'حالة الطلب' : 'Order Status',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(s.isArabic),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _orderStatus == 'LOOKING_FOR_DRIVER'
                          ? Colors.orange
                          : AppColors.primary,
                    ),
                  ),
                  if (_driverDistanceMeters() != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.route, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _distanceLabel(_driverDistanceMeters()!),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Customer Assist Decision Prompt
                  if (_orderDetails != null) ...[
                    Builder(builder: (context) {
                      final order = _orderDetails!;
                      final deliveryGroups = order['deliveryGroups'] is List ? order['deliveryGroups'] as List : [];
                      
                      Map? pendingGroup;
                      for (final g in deliveryGroups) {
                        if (g is Map && g['assistDriverId'] != null && g['assistCustomerApproved'] == null) {
                          pendingGroup = g;
                          break;
                        }
                      }

                      final isSinglePending = order['assistDriverId'] != null && order['assistCustomerApproved'] == null;
                      if (!isSinglePending && pendingGroup == null) return const SizedBox.shrink();

                      final fee = pendingGroup != null
                          ? (pendingGroup['assistFee']?.toString() ?? '0')
                          : (order['assistFee']?.toString() ?? '0');
                      final deliveryGroupId = pendingGroup?['id']?.toString();
                      final isAr = s.isArabic;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.group_add_rounded, color: AppColors.primary, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isAr ? 'طلب مندوب مساعد إضافي للشحنة' : 'Assistant Driver Assigned',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                                      final ok = await ref.read(ordersProvider.notifier).decideAssistOrder(
                                        widget.orderId,
                                        approve: false,
                                        deliveryGroupId: deliveryGroupId,
                                      );
                                      if (ok && mounted) _fetchOrderDetails();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(isAr ? 'رفض' : 'Decline'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final ok = await ref.read(ordersProvider.notifier).decideAssistOrder(
                                        widget.orderId,
                                        approve: true,
                                        deliveryGroupId: deliveryGroupId,
                                      );
                                      if (ok && mounted) _fetchOrderDetails();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(isAr ? 'موافقة' : 'Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Single-Vendor Store & Branch Card
                  if (_orderDetails != null &&
                      _orderDetails!['vendor'] != null &&
                      (_orderDetails!['vendorFulfillments'] is! List ||
                          (_orderDetails!['vendorFulfillments'] as List).isEmpty))
                    Builder(builder: (context) {
                      final v = _orderDetails!['vendor'] as Map;
                      final b = _orderDetails!['vendorBranch'] as Map?;
                      final storeName = (s.isArabic ? (v['storeNameAr'] ?? v['storeName']) : (v['storeName'] ?? v['name']))?.toString() ?? 'Store';
                      final branchName = b != null ? (s.isArabic ? (b['nameAr'] ?? b['name']) : (b['name'] ?? b['nameAr']))?.toString() : null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    storeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (branchName != null && branchName.isNotEmpty)
                                    Text(
                                      '${s.isArabic ? "الفرع: " : "Branch: "}$branchName',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Multi-Vendor Fulfillments Overview
                  if (_orderDetails != null &&
                      _orderDetails!['vendorFulfillments'] is List &&
                      (_orderDetails!['vendorFulfillments'] as List).isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                s.isArabic ? 'حالة تحضير المتاجر للطلب' : 'Store Fulfillment Status',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...(_orderDetails!['vendorFulfillments'] as List).map((f) {
                            if (f is! Map) return const SizedBox.shrink();
                            final v = f['vendor'] is Map ? f['vendor'] as Map : {};
                            final b = f['vendorBranch'] is Map ? f['vendorBranch'] as Map : null;
                            final storeName = (s.isArabic ? (v['storeNameAr'] ?? v['storeName']) : (v['storeName'] ?? v['name']))?.toString() ?? 'Store';
                            final branchName = b != null ? (s.isArabic ? (b['nameAr'] ?? b['name']) : (b['name'] ?? b['nameAr']))?.toString() : null;
                            final fStatus = f['status']?.toString() ?? 'PENDING';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(storeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        if (branchName != null && branchName.isNotEmpty)
                                          Text(
                                            '${s.isArabic ? "الفرع: " : "Branch: "}$branchName',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: fStatus == 'READY_FOR_PICKUP'
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : (fStatus == 'PREPARING'
                                              ? Colors.orange.withValues(alpha: 0.15)
                                              : Colors.blue.withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getDisplayStatus(fStatus, s.isArabic),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: fStatus == 'READY_FOR_PICKUP'
                                            ? Colors.green
                                            : (fStatus == 'PREPARING' ? Colors.orange : Colors.blue),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  if (_orderDetails != null &&
                      _orderDetails!['driver'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _orderDetails!['driver']['name'] ??
                                      (s.isArabic
                                          ? 'كابتن التوصيل'
                                          : 'Delivery Captain'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_driverPhone.isNotEmpty)
                            IconButton(
                              onPressed: () =>
                                  _callDriver(context, _driverPhone, s),
                              icon: const Icon(Icons.phone_rounded),
                              color: AppColors.primary,
                              tooltip: s.isArabic ? 'اتصال' : 'Call',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: const CircleBorder(),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if ((_orderDetails!['driver']['ratingCount'] ??
                                      0) >
                                  0) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ((_orderDetails!['driver']['rating'] ??
                                                  500) /
                                              100)
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '(${_orderDetails!['driver']['ratingCount']})',
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
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final chatRepo = ref.read(
                            sharedChatRepositoryProvider,
                          );
                          final conversation = await chatRepo
                              .createOrderConversation(widget.orderId);
                          if (!context.mounted) return;
                          if (conversation != null) {
                            final convoId = conversation['id'];
                            context.push(
                              '/chat/order/$convoId',
                              extra: {'title': s.isArabic ? 'طلب' : 'Order'},
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to start chat: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      label: Text(
                        s.isArabic ? 'محادثة الدعم' : 'Contact Support',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_orderStatus == 'PENDING_PAYMENT')
                    Builder(builder: (context) {
                      final upfront = double.tryParse(
                            _orderDetails?['upfrontAmount']?.toString() ?? '0',
                          ) ??
                          0.0;
                      final total = double.tryParse(
                            (_orderDetails?['grandTotal'] ??
                                    _orderDetails?['total'])
                                ?.toString() ??
                                '0',
                          ) ??
                          0.0;
                      // Cash on delivery with an upfront requirement: the
                      // customer pays the upfront first. Mobile wallet /
                      // InstaPay: always the whole amount.
                      final isUpfront =
                          (_orderDetails?['paymentMethod']?.toString() ?? '') ==
                                  'CASH_ON_DELIVERY' &&
                              upfront > 0;
                      final amountDue = isUpfront ? upfront : total;
                      final paidClaimed =
                          (_orderDetails?['paymentStatus']?.toString() ?? '') ==
                              'PAID';
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
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
                                      fontSize: 15,
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
                                    _orderDetails!['driver']
                                            ['mobileWallets'] !=
                                        null &&
                                    (_orderDetails!['driver']
                                            ['mobileWallets'] as List)
                                        .isNotEmpty)
                                  ..._trackingVisibleWallets(
                                          _orderDetails!['driver']
                                              ['mobileWallets'] as List)
                                      .map((wallet) {
                                    final walletMap = wallet is Map
                                        ? Map<dynamic, dynamic>.from(wallet)
                                        : <dynamic, dynamic>{};
                                    final number = (walletMap['number'] ??
                                            walletMap['walletNumber'] ??
                                            '')
                                        .toString();
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${_trackingWalletProviderName(walletMap, s)}: $number',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final file =
                                              await ImagePicker().pickImage(
                                            source: ImageSource.gallery,
                                            maxWidth: 1920,
                                            imageQuality: 80,
                                          );
                                          if (file != null) {
                                            setState(
                                              () =>
                                                  _receiptFile = file,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.receipt_long_rounded),
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
                                        ),
                                      ),
                                      if (_receiptFile != null) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            File(_receiptFile!.path),
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
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
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
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
                                                  receiptPath:
                                                      _receiptFile!.path,
                                                );
                                            if (success) {
                                              setState(
                                                () => _receiptFile = null,
                                              );
                                              await _fetchOrderDetails();
                                            }
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? (s.isArabic
                                                          ? 'تم التأكيد!'
                                                          : 'Confirmed!')
                                                      : (s.isArabic
                                                          ? 'فشل التأكيد. حاول مرة أخرى.'
                                                          : 'Confirmation failed. Try again.'),
                                                ),
                                                backgroundColor: success
                                                    ? null
                                                    : Colors.red,
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  if (_orderStatus == 'DELIVERED' &&
                      _orderDetails?['review'] == null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          RateOrderBottomSheet.show(context, widget.orderId);
                        },
                        icon: const Icon(Icons.star_rate_rounded, size: 20),
                        label: Text(s.isArabic ? 'تقييم الطلب' : 'Rate Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ],
      ),
    );
  }
}
