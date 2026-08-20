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
import '../../../../core/providers/platform_settings_provider.dart';
import 'package:data/providers.dart';
import '../widgets/rate_order_bottom_sheet.dart';
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  LatLng? _initialMapCenter;
  String _orderStatus = 'LOOKING_FOR_DRIVER';
  Map<String, dynamic>? _orderDetails;
  DateTime? _orderUpdatedAt;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

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

    final order = await ref.read(ordersProvider.notifier).fetchOrderDetails(widget.orderId);
    if (mounted && order != null) {
      setState(() {
        _orderDetails = order;
        _orderStatus = order['status'] ?? 'LOOKING_FOR_DRIVER';
        
        // If we failed to get user location, use the delivery location as map center
        if (_initialMapCenter == null && order['deliveryLat'] != null && order['deliveryLng'] != null) {
          final lat = double.tryParse(order['deliveryLat'].toString());
          final lng = double.tryParse(order['deliveryLng'].toString());
          if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
            _initialMapCenter = LatLng(lat, lng);
            if (_driverLocation == null) {
              _mapController.move(_initialMapCenter!, 14.0);
            }
          }
        }
      });
      if (_orderStatus == 'PENDING_CUSTOMER_APPROVAL' || _orderStatus == 'DRIVER_ASSIGNED' || _orderStatus == 'PENDING_PAYMENT') {
        _fetchOrderDetails();
      }
    }

    final token = await tokenService.getAccessToken();
    if (token != null) {
      await socket.initSocket(token);
      
      socket.on('order.status', (data) {
        if (data != null && data['orderId'] == widget.orderId) {
          if (mounted) {
            setState(() {
              _orderStatus = data['newStatus'] ?? data['status'] ?? _orderStatus;
            });
            if (_orderStatus == 'PENDING_CUSTOMER_APPROVAL' || _orderStatus == 'DRIVER_ASSIGNED' || _orderStatus == 'PENDING_PAYMENT') {
              _fetchOrderDetails();
            }
          }
        }
      });

      socket.on('driver.location', (data) {
        if (data != null && data['orderId'] == widget.orderId) {
          final lat = (data['latitude'] ?? data['lat']) as double?;
          final lng = (data['longitude'] ?? data['lng']) as double?;
          if (lat != null && lng != null && lat.isFinite && lng.isFinite && mounted) {
            setState(() {
              _driverLocation = LatLng(lat, lng);
            });
            _mapController.move(_driverLocation!, 15.0);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    final socket = ref.read(socketServiceProvider);
    socket.off('order.status');
    socket.off('driver.location');
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    final order = await ref.read(ordersProvider.notifier).fetchOrderDetails(widget.orderId);
    if (mounted && order != null) {
      setState(() {
        _orderDetails = order;
        _orderUpdatedAt = DateTime.tryParse(order['updatedAt']?.toString() ?? '');
      });
      if (_orderStatus == 'PENDING_CUSTOMER_APPROVAL' || _orderStatus == 'DRIVER_ASSIGNED') {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (_orderUpdatedAt == null) return;
    
    final settings = ref.read(platformSettingsProvider).value;
    final timeoutMins = settings?.customerApprovalTimeoutMins ?? 10;
    
    final expiryTime = _orderUpdatedAt!.add(Duration(minutes: timeoutMins));
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      if (now.isAfter(expiryTime)) {
        timer.cancel();
        setState(() {
          _timeRemaining = Duration.zero;
        });
      } else {
        setState(() {
          _timeRemaining = expiryTime.difference(now);
        });
      }
    });
  }

  String _getDisplayStatus(String rawStatus, bool isAr) {
    switch (rawStatus) {
      case 'PENDING': return isAr ? 'بإنتظار المطعم' : 'Pending Vendor';
      case 'CHANGES_REQUESTED': return isAr ? 'تعديلات مطلوبة' : 'Changes Requested';
      case 'LOOKING_FOR_DRIVER': return isAr ? 'جاري البحث عن كابتن...' : 'Looking for Driver...';
      case 'ACCEPTED': return isAr ? 'تم القبول' : 'Accepted';
      case 'PREPARING': return isAr ? 'قيد التحضير' : 'Preparing';
      case 'READY_FOR_PICKUP': return isAr ? 'جاهز للاستلام' : 'Ready for Pickup';
      case 'PICKED_UP': return isAr ? 'تم الاستلام من المتجر' : 'Picked Up';
      case 'ARRIVING': return isAr ? 'الكابتن في الطريق' : 'Driver Arriving';
      case 'IN_TRANSIT': return isAr ? 'الطلب في الطريق' : 'In Transit';
      case 'DELIVERED': return isAr ? 'تم التوصيل' : 'Delivered';
      case 'CANCELLED': return isAr ? 'تم الإلغاء' : 'Cancelled';
      case 'PENDING_CUSTOMER_APPROVAL': return isAr ? 'بانتظار موافقتك' : 'Pending Your Approval';
      case 'DRIVER_ASSIGNED': return isAr ? 'بانتظار موافقتك' : 'Pending Your Approval';
      case 'PENDING_PAYMENT': return isAr ? 'بانتظار الدفع' : 'Pending Payment';
      default: return rawStatus.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _driverLocation ?? _initialMapCenter!,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
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
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
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
                    _getDisplayStatus(_orderStatus, s.isArabic),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _orderStatus == 'LOOKING_FOR_DRIVER' ? Colors.orange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_orderDetails != null && _orderDetails!['driver'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                                  _orderDetails!['driver']['name'] ?? (s.isArabic ? 'كابتن التوصيل' : 'Delivery Captain'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(_orderDetails!['driver']['rating'] ?? 500) / 100}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              if (_orderDetails!['driver']['ratingCount'] != null && _orderDetails!['driver']['ratingCount'] > 0)
                                Text(
                                  '(${_orderDetails!['driver']['ratingCount']})',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                ),
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
                          final chatRepo = ref.read(sharedChatRepositoryProvider);
                          final conversation = await chatRepo.createOrderConversation(widget.orderId);
                          if (!context.mounted) return;
                          if (conversation != null) {
                            final convoId = conversation['id'];
                            context.push('/chat/order/$convoId', extra: {'title': s.isArabic ? 'طلب' : 'Order'});
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
                          }
                        }
                      },
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      label: Text(s.isArabic ? 'محادثة الدعم' : 'Contact Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            s.isArabic ? 'يرجى تحويل المبلغ للكابتن على المحفظة الإلكترونية ثم تأكيد التحويل. يمكنك استخدام المحادثة لإرسال الإيصال.' : "Please transfer the amount to the driver's mobile wallet, then confirm. You can use chat to send the receipt.",
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          if (_orderDetails != null && _orderDetails!['driver'] != null && _orderDetails!['driver']['mobileWallets'] != null && (_orderDetails!['driver']['mobileWallets'] as List).isNotEmpty)
                            Text(
                              '${s.isArabic ? 'رقم المحفظة' : 'Wallet Number'}: ${(_orderDetails!['driver']['mobileWallets'] as List).first['number'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final success = await ref.read(ordersProvider.notifier).markPaymentPaid(widget.orderId);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isArabic ? 'تم التأكيد!' : 'Confirmed!')));
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              child: Text(s.isArabic ? 'لقد قمت بالتحويل' : 'I have transferred the amount', style: const TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                  if (_orderStatus == 'DELIVERED' && _orderDetails?['review'] == null) ...[
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
