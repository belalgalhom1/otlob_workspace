import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/token_service.dart';

import 'dart:async';
import '../../../../core/services/location_service.dart';
import '../providers/orders_provider.dart';
import 'package:data/providers.dart';
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

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  LatLng? _initialMapCenter;
  LatLng? _deliveryLocation;
  String _orderStatus = 'LOOKING_FOR_DRIVER';
  Map<String, dynamic>? _orderDetails;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _driverLocSub;
  _TrackingLifecycleObserver? _lifecycleObserver;
  void Function(dynamic)? _onConnectHandler;
  bool _followDriver = true;
  Timer? _driverRenderTimer;
  LatLng? _pendingDriverLocation;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    final socket = ref.read(socketServiceProvider);
    final tokenService = ref.read(tokenServiceProvider);
    final locationSvc = ref.read(locationServiceProvider);

    try {
      final pos = await locationSvc.getCurrentLocation();
      if (mounted) {
        setState(() {
          _initialMapCenter = LatLng(pos.latitude, pos.longitude);
        });
        // We do not move the map here if driverLocation is already set
        if (_driverLocation == null) {
          _mapController.move(_initialMapCenter!, 14.0);
        }
      }
    } catch (e) {
      debugPrint('Failed to get location: $e');
      // Silently ignore and fallback to order's delivery location later if needed
    }

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
      _onConnectHandler = (_) => _requestDriverLocation(socket);
      socket.on('connect', _onConnectHandler!);

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
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _driverLocSub?.cancel();
    _driverRenderTimer?.cancel();
    if (_onConnectHandler != null) {
      ref.read(socketServiceProvider).off('connect', _onConnectHandler!);
    }
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
      case 'CHANGES_REQUESTED':
        return isAr ? 'تعديلات مطلوبة' : 'Changes Requested';
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

  void _applyDriverLocation() {
    _driverRenderTimer = null;
    final target = _pendingDriverLocation;
    _pendingDriverLocation = null;
    if (target == null || !mounted) return;

    setState(() {
      _driverLocation = target;
    });
    if (_followDriver) {
      _mapController.move(target, 15.0);
    }
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
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.otlob.customer',
                ),
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
                if (_driverLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _driverLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.directions_car,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
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
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  if (_orderStatus == 'PENDING_PAYMENT') ...[
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
                          Text(
                            s.isArabic
                                ? 'يرجى تحويل المبلغ للكابتن على المحفظة الإلكترونية ثم تأكيد التحويل. يمكنك استخدام المحادثة لإرسال الإيصال.'
                                : "Please transfer the amount to the driver's mobile wallet, then confirm. You can use chat to send the receipt.",
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          if (_orderDetails != null &&
                              _orderDetails!['driver'] != null &&
                              _orderDetails!['driver']['mobileWallets'] !=
                                  null &&
                              (_orderDetails!['driver']['mobileWallets']
                                      as List)
                                  .isNotEmpty)
                            Text(
                              '${s.isArabic ? 'رقم المحفظة' : 'Wallet Number'}: ${(_orderDetails!['driver']['mobileWallets'] as List).first['number'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final success = await ref
                                    .read(ordersProvider.notifier)
                                    .markPaymentPaid(widget.orderId);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        s.isArabic
                                            ? 'تم التأكيد!'
                                            : 'Confirmed!',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: Text(
                                s.isArabic
                                    ? 'لقد قمت بالتحويل'
                                    : 'I have transferred the amount',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        ],
      ),
    );
  }
}
