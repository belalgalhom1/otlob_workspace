import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/core/router/app_router.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';

class OrderExecutionScreen extends ConsumerStatefulWidget {
  const OrderExecutionScreen({super.key});

  @override
  ConsumerState<OrderExecutionScreen> createState() => _OrderExecutionScreenState();
}

class _OrderExecutionScreenState extends ConsumerState<OrderExecutionScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isMapReady = false;
  XFile? _pickupPhoto;
  XFile? _deliveryPhoto;

  String _resolveMediaUrl(String path) {
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$cleanBaseUrl$path';
  }

  Future<XFile?> _capturePickupPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _pickupPhoto = file);
      }
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<XFile?> _captureDeliveryPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _deliveryPhoto = file);
      }
      return file;
    } catch (_) {
      return null;
    }
  }

  void _viewPhoto({String? remoteUrl, XFile? localFile}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: localFile != null
                      ? Image.file(
                          File(localFile.path),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          _resolveMediaUrl(remoteUrl!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                          LucideIcons.imageOff,
                          color: Colors.white70,
                          size: 48,
                        ),
                        ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(LucideIcons.x, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// When the active order finishes (backend no longer returns it, or its
  /// status flips to DELIVERED/CANCELLED via socket), leave this page for
  /// the dashboard instead of stranding the driver on a dead order screen.
  void _maybeLeaveForDashboard(AsyncValue<dynamic> state) {
    if (!mounted || !state.hasValue) return;
    final value = state.value;
    var finished = value == null;
    if (!finished && value is Map) {
      final status = (value['status'] ?? '').toString().toUpperCase();
      finished = status == 'DELIVERED' || status == 'CANCELLED';
    }
    if (!finished) return;
    try {
      final router = ref.read(appRouterProvider);
      if (router.state.uri.path == '/order-execution') {
        router.go('/dashboard');
      }
    } catch (_) {
      // Navigation best-effort only; the empty state below is the fallback.
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // NOTE: ref.listen must stay here (not in build) — listening during
    // build re-subscribes on every rebuild and throws in debug builds.
    ref.listen<AsyncValue<dynamic>>(
      orderExecutionProvider,
      (previous, state) => _maybeLeaveForDashboard(state),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeDelivery),
        automaticallyImplyLeading: false,
      ),
      body: orderState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text(ErrorUtils.translate(context, error))),
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
    final isCustomOrRide = order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE';
    final vendorData = order['vendor'];
    final pickupLoc = order['pickupLocation'];
    
    double vendorLat = 0.0;
    double vendorLng = 0.0;
    
    if (pickupLoc is List && pickupLoc.length > 1) {
      vendorLng = double.tryParse(pickupLoc[0].toString()) ?? 0.0;
      vendorLat = double.tryParse(pickupLoc[1].toString()) ?? 0.0;
    } else if (pickupLoc is Map && pickupLoc['coordinates'] is List && (pickupLoc['coordinates'] as List).length > 1) {
      vendorLng = double.tryParse(pickupLoc['coordinates'][0].toString()) ?? 0.0;
      vendorLat = double.tryParse(pickupLoc['coordinates'][1].toString()) ?? 0.0;
    } else if (order['pickupCoordinates'] is List && (order['pickupCoordinates'] as List).length > 1) {
      vendorLng = double.tryParse(order['pickupCoordinates'][0].toString()) ?? 0.0;
      vendorLat = double.tryParse(order['pickupCoordinates'][1].toString()) ?? 0.0;
    } else if (vendorData is Map) {
      vendorLat = double.tryParse((vendorData['latitude'] ?? 0.0).toString()) ?? 0.0;
      vendorLng = double.tryParse((vendorData['longitude'] ?? 0.0).toString()) ?? 0.0;
    }
    
    final dl = order['deliveryLocation'];
    double customerLat = 0.0;
    double customerLng = 0.0;
    if (dl is List && dl.length > 1) {
      customerLng = double.tryParse(dl[0].toString()) ?? 0.0;
      customerLat = double.tryParse(dl[1].toString()) ?? 0.0;
    } else if (dl is Map && dl['coordinates'] is List && (dl['coordinates'] as List).length > 1) {
      customerLng = double.tryParse(dl['coordinates'][0].toString()) ?? 0.0;
      customerLat = double.tryParse(dl['coordinates'][1].toString()) ?? 0.0;
    } else if (order['deliveryAddress'] is Map) {
      customerLat = double.tryParse(order['deliveryAddress']['latitude']?.toString() ?? '') ?? 0.0;
      customerLng = double.tryParse(order['deliveryAddress']['longitude']?.toString() ?? '') ?? 0.0;
    }

    final status = order['status'] ?? '';
    final isCashOnDelivery = order['paymentMethod'] == 'CASH_ON_DELIVERY';
    final isMobileWallet = order['paymentMethod'] == 'MOBILE_WALLET';
    
    LatLng? targetLocation;
    if (status == 'DRIVER_ASSIGNED' || status == 'READY_FOR_PICKUP' || status == 'PREPARING') {
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
            padding: EdgeInsets.fromLTRB(
              24.0,
              24.0,
              24.0,
              24.0 + MediaQuery.of(context).padding.bottom,
            ),
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
                            status == 'PENDING_PAYMENT'
                                ? (l10n.localeName == 'ar' ? 'بانتظار الدفع من العميل' : 'Waiting for Customer Payment')
                                    : (status == 'PICKED_UP')
                                        ? l10n.navigatingToCustomer
                                        : (isCustomOrRide
                                            ? (l10n.localeName == 'ar' ? 'التوجه إلى موقع الاستلام' : 'Navigating to Pickup')
                                            : l10n.navigatingToVendor),
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text(
                            (status == 'PICKED_UP' || status == 'PENDING_PAYMENT')
                                  ? ((order['customer'] is Map ? order['customer']['name'] : null) ?? l10n.customerFallback)
                                  : (isCustomOrRide
                                      ? (order['pickupAddress']?.toString() ?? (l10n.localeName == 'ar' ? 'موقع الاستلام' : 'Pickup Location'))
                                      : ((order['vendor'] is Map ? order['vendor']['name'] ?? order['vendor']['storeName'] : null) ?? l10n.vendorFallback)),
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
                _buildPickupPhotoWidget(context, status, l10n, order),
                _buildDeliveryPhotoWidget(context, status, l10n, order),
                _buildActionButton(context, status, isCashOnDelivery, isMobileWallet, targetLocation, l10n, order),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPhotoWidget(
    BuildContext context,
    String status,
    AppLocalizations l10n,
    Map<String, dynamic> order,
  ) {
    final isCustomOrRide =
        order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE';
    final showCapture = (status == 'DRIVER_ASSIGNED' || status == 'READY_FOR_PICKUP') &&
        (isCustomOrRide || status == 'READY_FOR_PICKUP');
    final remoteUrl = order['pickupImageUrl']?.toString();

    // After pickup show the proof photo, tappable to view full screen.
    if (!showCapture && remoteUrl != null && remoteUrl.isNotEmpty) {
      return _buildPhotoRow(
        l10n: l10n,
        label: l10n.pickupPhoto,
        thumbnail: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _resolveMediaUrl(remoteUrl),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 56,
              height: 56,
              color: Theme.of(context).dividerColor,
              child: const Icon(LucideIcons.imageOff, size: 20),
            ),
          ),
        ),
        onTap: () => _viewPhoto(remoteUrl: remoteUrl),
      );
    }

    // Before pickup require a captured photo as proof.
    if (showCapture) {
      final preview = _pickupPhoto;
      if (preview != null) {
        return _buildPhotoRow(
          l10n: l10n,
          label: l10n.retakePickupPhoto,
          thumbnail: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(preview.path),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          onTap: () => _capturePickupPhoto(),
          leading: IconButton(
            onPressed: () => _capturePickupPhoto(),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: l10n.retakePickupPhoto,
          ),
        );
      }
      return _buildPhotoRow(
        l10n: l10n,
        label: l10n.capturePickupPhoto,
        thumbnail: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.camera, color: AppColors.primary),
        ),
        onTap: () => _capturePickupPhoto(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDeliveryPhotoWidget(
    BuildContext context,
    String status,
    AppLocalizations l10n,
    Map<String, dynamic> order,
  ) {
    final showCapture = status == 'PICKED_UP';
    final remoteUrl = order['deliveryImageUrl']?.toString();

    // After delivery show the proof photo, tappable to view full screen.
    if (!showCapture && remoteUrl != null && remoteUrl.isNotEmpty) {
      return _buildPhotoRow(
        l10n: l10n,
        label: l10n.deliveryPhoto,
        thumbnail: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _resolveMediaUrl(remoteUrl),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 56,
              height: 56,
              color: Theme.of(context).dividerColor,
              child: const Icon(LucideIcons.imageOff, size: 20),
            ),
          ),
        ),
        onTap: () => _viewPhoto(remoteUrl: remoteUrl),
      );
    }

    // Before delivery require a captured photo as proof.
    if (showCapture) {
      final preview = _deliveryPhoto;
      if (preview != null) {
        return _buildPhotoRow(
          l10n: l10n,
          label: l10n.retakeDeliveryPhoto,
          thumbnail: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(preview.path),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          onTap: () => _captureDeliveryPhoto(),
          leading: IconButton(
            onPressed: () => _captureDeliveryPhoto(),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: l10n.retakeDeliveryPhoto,
          ),
        );
      }
      return _buildPhotoRow(
        l10n: l10n,
        label: l10n.captureDeliveryPhoto,
        thumbnail: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.camera, color: AppColors.primary),
        ),
        onTap: () => _captureDeliveryPhoto(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPhotoRow({
    required AppLocalizations l10n,
    required String label,
    required Widget thumbnail,
    required VoidCallback onTap,
    Widget? leading,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          GestureDetector(onTap: onTap, child: thumbnail),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
          if (leading != null) ...[
            const SizedBox(width: 4),
            leading,
          ],
          IconButton(
            onPressed: onTap,
            icon: const Icon(LucideIcons.chevronRight, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String status, bool isCashOnDelivery, bool isMobileWallet, LatLng? targetLocation, AppLocalizations l10n, Map<String, dynamic> order) {
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

    void showErr(Object e) {
      if (context.mounted) {
        final message = ErrorUtils.translate(context, e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    Future<void> handleAction(Future<void> Function() action) async {
      if (!isWithinGeofence) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.localeName == 'ar' ? 'تأكيد المسافة' : 'Distance Override'),
            content: Text(l10n.localeName == 'ar' ? 'أنت بعيد جدا عن الموقع. هل تريد المتابعة؟' : 'You are far from the location. Continue anyway?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.localeName == 'ar' ? 'إلغاء' : 'Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.localeName == 'ar' ? 'متابعة' : 'Continue')),
            ],
          ),
        );
        if (confirm != true) return;
      }
      try {
        await action();
      } catch (e) {
        showErr(e);
      }
    }

    if (status == 'PREPARING') {
      return PrimaryButton(
        text: l10n.localeName == 'ar' ? 'جاري تجهيز الطلب من المطعم' : 'Waiting for vendor to prepare...',
        onPressed: null,
      );
    } else if (status == 'DRIVER_ASSIGNED' || status == 'READY_FOR_PICKUP') {
      final isCustomOrRide =
          order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE';
      if (!isCustomOrRide && status == 'DRIVER_ASSIGNED') {
        return PrimaryButton(
          text: l10n.localeName == 'ar' ? 'بانتظار تجهيز الطلب من المطعم' : 'Waiting for vendor to prepare...',
          onPressed: null,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            text: l10n.confirmPickup,
            onPressed: () => handleAction(() async {
              var photo = _pickupPhoto;
              if (photo == null) {
                photo = await _capturePickupPhoto();
                if (photo == null) return;
              }
              await ref
                  .read(orderExecutionProvider.notifier)
                  .confirmPickupWithPhoto(photo);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pickupPhotoRequired,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else if (status == 'PICKED_UP') {
      String? label;
      if (isCashOnDelivery) {
        final totalStr = order['total']?.toString() ?? order['grandTotal']?.toString() ?? order['totalFee']?.toString() ?? '0.00';
        final total = double.tryParse(totalStr) ?? 0.0;
        final upfrontStr = order['upfrontAmount']?.toString() ?? '0.00';
        final upfront = double.tryParse(upfrontStr) ?? 0.0;
        final collectAmount = (total - upfront) > 0 ? (total - upfront) : 0.0;
        label = '${l10n.collectCashAndDeliver} (${collectAmount.toStringAsFixed(2)} EGP)';
      } else {
        label = l10n.confirmDelivery;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            text: label,
            onPressed: () => handleAction(() async {
              var photo = _deliveryPhoto;
              if (photo == null) {
                photo = await _captureDeliveryPhoto();
                if (photo == null) return;
              }
              await ref
                  .read(orderExecutionProvider.notifier)
                  .confirmDeliveryWithPhoto(photo);
              // Order is finished — leave this page at once instead of
              // waiting on the provider refetch (which shows "No active
              // order" if we stay).
              if (context.mounted) context.go('/dashboard');
            }),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deliveryPhotoRequired,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    } else if (status == 'PENDING_PAYMENT') {
      final isAr = l10n.localeName == 'ar';
      final upfront =
          double.tryParse(order['upfrontAmount']?.toString() ?? '0') ?? 0.0;
      final total =
          double.tryParse((order['grandTotal'] ?? order['total'])?.toString() ?? '0') ?? 0.0;
      // Cash on delivery with an upfront requirement: the customer pays the
      // upfront first. Mobile wallet / InstaPay: always the whole amount.
      final isUpfront = isCashOnDelivery && upfront > 0;
      final amountDue = isUpfront ? upfront : total;
      final paidClaimed =
          (order['paymentStatus']?.toString() ?? '') == 'PAID';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpfront
                      ? (isAr
                          ? 'المبلغ المطلوب مقدماً: ${amountDue.toStringAsFixed(0)} ج.م'
                          : 'Upfront amount due: ${amountDue.toStringAsFixed(0)} EGP')
                      : (isAr
                          ? 'المبلغ المطلوب تحويله: ${amountDue.toStringAsFixed(0)} ج.م'
                          : 'Amount to transfer: ${amountDue.toStringAsFixed(0)} EGP'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  paidClaimed
                      ? (isAr
                          ? (isUpfront
                              ? 'العميل يقول إنه دفع المبلغ المقدم. تحقق من محفظتك ثم أكد.'
                              : 'العميل يقول إنه حوّل المبلغ إلى محفظتك. تحقق من محفظتك ثم أكد.')
                          : (isUpfront
                              ? 'The customer says they paid the upfront amount. Check your wallet, then confirm.'
                              : 'The customer says they transferred the payment. Check your wallet, then confirm.'))
                      : (isAr
                          ? (isUpfront
                              ? 'في انتظار أن يدفع العميل المبلغ المقدم.'
                              : 'في انتظار أن يحول العميل المبلغ إلى محفظتك الإلكترونية.')
                          : (isUpfront
                              ? 'Waiting for the customer to pay the upfront amount.'
                              : 'Waiting for the customer to transfer the payment to your mobile wallet.')),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if ((order['paymentReceiptUrl']?.toString().isNotEmpty ??
              false)) ...[
            GestureDetector(
              onTap: () => _viewPhoto(
                remoteUrl: order['paymentReceiptUrl'].toString(),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _resolveMediaUrl(
                          order['paymentReceiptUrl'].toString(),
                        ),
                        height: 64,
                        width: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          LucideIcons.imageOff,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'إيصال التحويل من العميل — اضغط للتكبير'
                            : 'Customer transfer receipt — tap to enlarge',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.zoomIn,
                      size: 18,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            text: isAr ? 'تأكيد: استلمت المبلغ' : 'Confirm: I Have Received It',
            onPressed: !paidClaimed
                ? null
                : () async {
                    try {
                      await ref
                          .read(orderExecutionProvider.notifier)
                          .confirmPayment(received: true);
                      // NOTE: do NOT leave this page here — confirming
                      // payment sends the order back to PICKED_UP so the
                      // driver can deliver it. Dashboard redirect happens
                      // only after actual delivery (see confirmDelivery
                      // handler + _maybeLeaveForDashboard listener).
                    } catch (e) {
                      showErr(e);
                    }
                  },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: !paidClaimed
                ? null
                : () async {
                    try {
                      await ref
                          .read(orderExecutionProvider.notifier)
                          .confirmPayment(received: false);
                    } catch (e) {
                      showErr(e);
                    }
                  },
            child: Text(
              isAr ? 'لم أستلم المبلغ' : 'I Did Not Receive It',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
