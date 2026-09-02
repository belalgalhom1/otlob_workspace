import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver/l10n/app_localizations.dart';

class OrderExecutionScreen extends ConsumerStatefulWidget {
  const OrderExecutionScreen({super.key});

  @override
  ConsumerState<OrderExecutionScreen> createState() => _OrderExecutionScreenState();
}

class _OrderExecutionScreenState extends ConsumerState<OrderExecutionScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
        if (_isMapReady) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
        }
      }
    } catch (_) {
      // Handle location error gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderExecutionProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AsyncValue<dynamic>>(orderExecutionProvider, (previous, state) {
      if (state.hasValue && state.value == null) {
        // Order completed or no active order
        if (context.mounted && GoRouterState.of(context).uri.path == '/order-execution') {
          context.go('/dashboard');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeDelivery),
        automaticallyImplyLeading: false,
      ),
      body: orderState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text(l10n.errorGeneric(error.toString()))),
        data: (orderData) {
          if (orderData == null) {
            return Center(child: Text(l10n.noActiveOrder));
          }
          return _buildMapAndControls(orderData, l10n);
        },
      ),
    );
  }

  Widget _buildMapAndControls(Map<String, dynamic> order, AppLocalizations l10n) {
    final vendorLat = order['vendor']?['latitude'] ?? 0.0;
    final vendorLng = order['vendor']?['longitude'] ?? 0.0;
    
    final customerLat = order['deliveryAddress']?['latitude'] ?? 0.0;
    final customerLng = order['deliveryAddress']?['longitude'] ?? 0.0;

    final status = order['status'] ?? '';
    final isCashOnDelivery = order['paymentMethod'] == 'CASH_ON_DELIVERY';
    final isMobileWallet = order['paymentMethod'] == 'MOBILE_WALLET';
    
    LatLng? targetLocation;
    if (status == 'DRIVER_ASSIGNED' || status == 'READY_FOR_PICKUP' || status == 'PENDING_CUSTOMER_APPROVAL' || status == 'PREPARING') {
      final lat = double.tryParse(vendorLat.toString());
      final lng = double.tryParse(vendorLng.toString());
      if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
        targetLocation = LatLng(lat, lng);
      }
    } else if (status == 'PICKED_UP' || status == 'PENDING_PAYMENT') {
      final lat = double.tryParse(customerLat.toString());
      final lng = double.tryParse(customerLng.toString());
      if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
        targetLocation = LatLng(lat, lng);
      }
    }

    final List<Marker> markers = [];
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: const Icon(LucideIcons.navigation, color: Colors.blue, size: 32),
        ),
      );
    }
    if (targetLocation != null && targetLocation.latitude != 0) {
      markers.add(
        Marker(
          point: targetLocation,
          child: Icon(
            (status == 'PICKED_UP' || status == 'PENDING_PAYMENT') ? LucideIcons.mapPin : LucideIcons.store, 
            color: AppColors.primary, 
            size: 32,
          ),
        ),
      );
    }

    // Determine Polyline (just a straight line for now until routing API is integrated)
    final List<LatLng> polylinePoints = [];
    if (_currentPosition != null && targetLocation != null && targetLocation.latitude != 0) {
      polylinePoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
      polylinePoints.add(targetLocation);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(30.0444, 31.2357), // Cairo fallback
            initialZoom: 14.0,
            onMapReady: () {
              _isMapReady = true;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.otlobegy.driver',
            ),
            if (polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 4.0,
                    color: AppColors.primary,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        
        // Floating Center Map Button
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.surface,
            mini: true,
            onPressed: () {
              if (_currentPosition != null && _isMapReady) {
                _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15);
              }
            },
            child: Icon(LucideIcons.locateFixed, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),

        // Action Bottom Sheet Panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (status == 'PICKED_UP' || status == 'PENDING_PAYMENT') ? LucideIcons.user : LucideIcons.store,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status == 'PENDING_CUSTOMER_APPROVAL'
                                ? l10n.waitingForCustomerApproval
                                : status == 'PENDING_PAYMENT'
                                    ? (l10n.localeName == 'ar' ? 'بانتظار الدفع من العميل' : 'Waiting for Customer Payment')
                                    : status == 'PICKED_UP' ? l10n.navigatingToCustomer : l10n.navigatingToVendor,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text(
                            status == 'PENDING_CUSTOMER_APPROVAL'
                                ? l10n.waitingForCustomerApproval
                                : (status == 'PICKED_UP' || status == 'PENDING_PAYMENT')
                                  ? (order['customer']?['name'] ?? l10n.customerFallback)
                                  : (order['vendor']?['name'] ?? l10n.vendorFallback),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          OrderDetailsBottomSheet.show(context, order);
                        },
                        icon: const Icon(LucideIcons.fileText),
                        label: Text(l10n.localeName == 'ar' ? 'تفاصيل الطلب' : 'View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/chat/${order['id']}');
                        },
                        icon: const Icon(LucideIcons.messageCircle),
                        label: Text(l10n.messageButton),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildActionButton(status, isCashOnDelivery, isMobileWallet, targetLocation, l10n, order),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String status, bool isCashOnDelivery, bool isMobileWallet, LatLng? targetLocation, AppLocalizations l10n, Map<String, dynamic> order) {
    bool isWithinGeofence = true;
    if (_currentPosition != null && targetLocation != null && targetLocation.latitude != 0) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude, 
        _currentPosition!.longitude, 
        targetLocation.latitude, 
        targetLocation.longitude,
      );
      if (distanceInMeters > 100) {
        isWithinGeofence = false;
      }
    }

    if (status == 'PREPARING') {
      return PrimaryButton(
        text: l10n.localeName == 'ar' ? 'جاري تجهيز الطلب من المطعم' : 'Waiting for vendor to prepare...',
        onPressed: null, // Disabled because driver cannot confirm pickup yet
      );
    } else if (status == 'PENDING_CUSTOMER_APPROVAL') {
      return PrimaryButton(
        text: l10n.waitingForCustomerApproval,
        onPressed: null, // Disabled because driver must wait for customer
      );
    } else if (status == 'DRIVER_ASSIGNED' || status == 'READY_FOR_PICKUP') {
      return PrimaryButton(
        text: isWithinGeofence ? l10n.confirmPickup : l10n.moveCloserToVendor,
        onPressed: isWithinGeofence ? () {
          ref.read(orderExecutionProvider.notifier).updateOrderStatus('PICKED_UP');
        } : null,
      );
    } else if (status == 'PICKED_UP') {
      if (isCashOnDelivery) {
        final totalStr = order['total']?.toString() ?? order['grandTotal']?.toString() ?? order['totalFee']?.toString() ?? '0.00';
        final total = double.tryParse(totalStr) ?? 0.0;
        final text = isWithinGeofence 
            ? '${l10n.collectCashAndDeliver} (${total.toStringAsFixed(2)} EGP)' 
            : l10n.moveCloserToCustomer;
            
        return PrimaryButton(
          text: text,
          onPressed: isWithinGeofence ? () {
            ref.read(orderExecutionProvider.notifier).confirmPayment(received: true);
          } : null,
        );
      } else if (isMobileWallet) {
        return PrimaryButton(
          text: isWithinGeofence ? (l10n.localeName == 'ar' ? 'طلب الدفع للوصول' : 'Request Payment to Deliver') : l10n.moveCloserToCustomer,
          onPressed: isWithinGeofence ? () {
            ref.read(orderExecutionProvider.notifier).updateOrderStatus('PENDING_PAYMENT');
          } : null,
        );
      } else {
        return PrimaryButton(
          text: isWithinGeofence ? l10n.confirmDelivery : l10n.moveCloserToCustomer,
          onPressed: isWithinGeofence ? () {
            ref.read(orderExecutionProvider.notifier).updateOrderStatus('DELIVERED');
          } : null,
        );
      }
    } else if (status == 'PENDING_PAYMENT') {
      return PrimaryButton(
        text: l10n.localeName == 'ar' ? 'تأكيد استلام الدفع' : 'Confirm Payment Received',
        onPressed: () {
          ref.read(orderExecutionProvider.notifier).confirmPayment(received: true);
        },
      );
    }
    return const SizedBox.shrink();
  }
}
