import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:data/data.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
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
  int _currentStopIndex = 0;
  final Set<int> _collectedStopIndices = <int>{};

  String? _resolveActiveDriverGroupId(Map<String, dynamic> order) {
    final direct = order['activeDeliveryGroupId']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final groups = order['deliveryGroups'];
    final driverId = order['driverId']?.toString();
    if (groups is List && groups.isNotEmpty) {
      for (final grp in groups) {
        if (grp is Map &&
            grp['status'] != 'DELIVERED' &&
            grp['status'] != 'CANCELLED' &&
            (driverId == null ||
                grp['primaryDriverId']?.toString() == driverId ||
                grp['assistDriverId']?.toString() == driverId)) {
          return grp['id']?.toString();
        }
      }
    }
    return null;
  }

  Future<void> _callPhone(BuildContext context, String? phone) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localizations.localeOf(context).languageCode == 'ar'
                ? 'رقم الهاتف غير متاح'
                : 'Phone number not available'),
          ),
        );
      }
      return;
    }
    await ExternalActionLauncher.callPhone(digits, context: context);
  }

  Future<void> _launchMapsNavigation(double lat, double lng) async {
    await MapNavigationLauncher.launchNavigation(
      latitude: lat,
      longitude: lng,
      context: context,
    );
  }
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<dynamic>? _fulfillmentSub;
  ProviderSubscription<AsyncValue<dynamic>>? _orderExecSub;
  RoadSpeedLimit? _roadSpeedLimit;
  bool _isMapReady = false;
  XFile? _pickupPhoto;
  XFile? _deliveryPhoto;

  String _resolveMediaUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$cleanBaseUrl$cleanPath';
  }

  Future<XFile?> _capturePickupPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _pickupPhoto = file);
      }
      return file;
    } catch (e) {
      if (mounted) {
        MediaPermissionHelper.handlePickerError(e, context: context);
      }
      return null;
    }
  }

  Future<XFile?> _captureDeliveryPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _deliveryPhoto = file);
      }
      return file;
    } catch (e) {
      if (mounted) {
        MediaPermissionHelper.handlePickerError(e, context: context);
      }
      return null;
    }
  }

  void _viewPhoto({String? remoteUrl, XFile? localFile}) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        maxWidth: 680,
        scrollableBody: false,
        bodyPadding: const EdgeInsets.all(16),
        header: AppDialogHeader(
          icon: LucideIcons.image,
          title: isAr ? 'عرض الصورة' : 'Photo Preview',
          onClose: () => Navigator.pop(ctx),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: localFile != null
                  ? Image.file(
                      File(localFile.path),
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      _resolveMediaUrl(remoteUrl!),
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 180,
                        child: Center(
                          child: Icon(
                            LucideIcons.imageOff,
                            color: AppColors.textMuted,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        footer: AppDialogFooter(
          cancelLabel: isAr ? 'إغلاق' : 'Close',
          onCancel: () => Navigator.pop(ctx),
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
    _initLocationTracking();
    // Use listenManual in initState so Riverpod's debugDoingBuild assertion
    // passes and subscription cleanup is explicit in dispose().
    _orderExecSub = ref.listenManual<AsyncValue<dynamic>>(
      orderExecutionProvider,
      (previous, state) {
        final prevId = previous?.value is Map ? previous!.value['id']?.toString() : null;
        final nextId = state.value is Map ? state.value['id']?.toString() : null;
        if (prevId != null && nextId != null && prevId != nextId && mounted) {
          setState(() {
            _currentStopIndex = 0;
            _collectedStopIndices.clear();
            _pickupPhoto = null;
            _deliveryPhoto = null;
          });
        }
        _maybeLeaveForDashboard(state);
      },
    );
    final socket = ref.read(coreSocketServiceProvider);
    _fulfillmentSub = socket
        .onEvent(SocketEvent.orderFulfillmentUpdated)
        .listen((data) {
      if (!mounted) return;
      final currentOrder = ref.read(orderExecutionProvider).value;
      final activeOrderId =
          currentOrder is Map ? currentOrder['id']?.toString() : null;
      final incomingOrderId =
          data is Map ? (data['orderId'] ?? data['id'])?.toString() : null;
      if (activeOrderId == null ||
          incomingOrderId == null ||
          incomingOrderId == activeOrderId) {
        ref.read(orderExecutionProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _orderExecSub?.close();
    _fulfillmentSub?.cancel();
    _positionStreamSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    await _getCurrentLocation();
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _positionStreamSub?.cancel();
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() {
          _currentPosition = pos;
        });
        SpeedLimitService.instance.getSpeedLimit(pos.latitude, pos.longitude).then((limit) {
          if (mounted && limit != null) {
            setState(() => _roadSpeedLimit = limit);
          }
        });
      });
    } catch (_) {}
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
        SpeedLimitService.instance.getSpeedLimit(pos.latitude, pos.longitude).then((limit) {
          if (mounted && limit != null) {
            setState(() => _roadSpeedLimit = limit);
          }
        });
        if (_isMapReady) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
        }
      }
    } catch (_) {
      // Handle location error gracefully
    }
  }

  void _showActiveOrdersBottomSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final repo = ref.read(driverOrdersRepositoryProvider);
    final activeOrders = await repo.getActiveDriverOrders();
    if (!mounted) return;

    if (activeOrders.isEmpty) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.noActiveOrder)),
      );
      return;
    }

    final currentOrder = ref.read(orderExecutionProvider).value;
    final currentId = currentOrder is Map ? currentOrder['id']?.toString() : null;

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.listOrdered, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.localeName == 'ar'
                            ? 'الطلبات النشطة (${activeOrders.length})'
                            : 'Active Orders (${activeOrders.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeOrders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = activeOrders[index] as Map<String, dynamic>;
                      final id = item['id']?.toString() ?? '';
                      final isSelected = id == currentId;
                      final itemType = OrderTypeHelper.resolve(item);
                      final isItemAr = l10n.localeName == 'ar';
                      final orderNumber = item['orderNumber']?.toString() ?? (id.length >= 6 ? id.substring(0, 6) : id);
                      final itemCustomer = item['customer'] is Map ? item['customer'] as Map : const {};
                      final itemCustomerName = (itemCustomer['name'] ?? itemCustomer['user']?['name'])?.toString().trim();
                      final displayLabel = itemType.isRide
                          ? (itemCustomerName != null && itemCustomerName.isNotEmpty
                              ? '${isItemAr ? 'رحلة' : 'Ride'} • $itemCustomerName'
                              : (isItemAr ? 'رحلة' : 'Ride'))
                          : (itemType.isCustomDelivery
                              ? (isItemAr ? 'توصيل خاص' : 'Custom Delivery')
                              : (item['vendor']?['storeName'] ?? l10n.vendorFallback).toString());
                      final itemAvatar = itemType.isRide
                          ? (itemCustomer['avatar'] ?? itemCustomer['user']?['avatar'])?.toString()
                          : (item['vendor']?['logo'] ?? item['vendor']?['logoUrl'])?.toString();
                      final status = item['status']?.toString() ?? '';

                      return ListTile(
                        leading: AppNetworkAvatar(
                          imageUrl: ImageUtils.formatImageUrl(itemAvatar),
                          size: 40,
                          borderRadius: itemType.isRide ? null : 10,
                          fallbackText: '${index + 1}',
                          preferInitialFallback: !itemType.isRide,
                          fallbackIcon: itemType.isRide
                              ? LucideIcons.car
                              : (itemType.isCustomDelivery
                                  ? LucideIcons.package
                                  : LucideIcons.store),
                          backgroundColor: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          foregroundColor:
                              isSelected ? Colors.black : Colors.grey.shade700,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#$orderNumber - $displayLabel',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (item['isStacked'] == true) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  l10n.localeName == 'ar' ? 'مجمع في المسار' : 'Batch',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(status),
                        trailing: isSelected
                            ? const Icon(LucideIcons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (!isSelected) {
                            ref.read(orderExecutionProvider.notifier).selectOrder(id);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderExecutionProvider);
    final l10n = AppLocalizations.of(context)!;
    final activeOrder = orderState.asData?.value;
    final activeType = OrderTypeHelper.resolve(activeOrder is Map ? activeOrder : null);
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          OrderTypeHelper.driverExecutionScreenTitle(
            activeType,
            isArabic: isAr,
            standardFallback: l10n.activeDelivery,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.listOrdered),
            tooltip: isAr ? 'الطلبات النشطة' : 'Active Orders',
            onPressed: () => _showActiveOrdersBottomSheet(context),
          ),
        ],
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
    final orderType = OrderTypeHelper.resolve(order);
    final isCustomOrRide = orderType.isNonStandard;
    final vendorData = order['vendor'];
    final customerMap =
        order['customer'] is Map ? (order['customer'] as Map) : const {};
    final customerName =
        (customerMap['name'] ?? customerMap['user']?['name'])?.toString().trim();
    final customerPhone =
        (customerMap['phone'] ?? customerMap['user']?['phone'])?.toString().trim() ?? '';
    final customerAvatar =
        (customerMap['avatar'] ?? customerMap['user']?['avatar'])?.toString();
    final pickupLoc = order['pickupLocation'];
    final isAr = l10n.localeName == 'ar';
    final currency = 'EGP';
    
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

    final allItems = (order['items'] as List?) ?? [];
    final String? activeGroupId = _resolveActiveDriverGroupId(order);
    final Map<String, int> stopSequenceByFulfillmentId = {};
    if (order['deliveryGroups'] is List) {
      int baseSeq = 0;
      for (final grp in (order['deliveryGroups'] as List)) {
        if (grp is Map &&
            (activeGroupId == null ||
                activeGroupId.isEmpty ||
                grp['id']?.toString() == activeGroupId) &&
            grp['items'] is List) {
          for (final gi in (grp['items'] as List)) {
            if (gi is Map && gi['fulfillmentId'] != null) {
              final seq = (gi['sequence'] as num?)?.toInt() ?? 0;
              stopSequenceByFulfillmentId[gi['fulfillmentId'].toString()] =
                  baseSeq + seq;
            }
          }
          baseSeq += 1000;
        }
      }
    }
    final List<Map<String, dynamic>> pickupStops = [];
    if (order['vendorFulfillments'] is List && (order['vendorFulfillments'] as List).isNotEmpty) {
      final rawFulfillments = List<dynamic>.from(order['vendorFulfillments'] as List);
      rawFulfillments.sort((a, b) {
        final aId = (a is Map ? a['id'] : null)?.toString() ?? '';
        final bId = (b is Map ? b['id'] : null)?.toString() ?? '';
        final aSeq = stopSequenceByFulfillmentId[aId] ?? 999999;
        final bSeq = stopSequenceByFulfillmentId[bId] ?? 999999;
        return aSeq.compareTo(bSeq);
      });
      for (final f in rawFulfillments) {
        if (f is Map && f['status'] != 'REJECTED' && f['status'] != 'CANCELLED') {
          final branch = f['vendorBranch'] is Map ? (f['vendorBranch'] as Map) : {};
          final v = f['vendor'] is Map ? (f['vendor'] as Map) : {};
          
          double bLng = 0.0;
          double bLat = 0.0;
          if (branch['location'] is List && (branch['location'] as List).length > 1) {
            bLng = double.tryParse(branch['location'][0].toString()) ?? 0.0;
            bLat = double.tryParse(branch['location'][1].toString()) ?? 0.0;
          } else if (branch['lng'] != null && branch['lat'] != null) {
            bLng = double.tryParse(branch['lng'].toString()) ?? 0.0;
            bLat = double.tryParse(branch['lat'].toString()) ?? 0.0;
          } else if (v['latitude'] != null && v['longitude'] != null) {
            bLat = double.tryParse(v['latitude'].toString()) ?? 0.0;
            bLng = double.tryParse(v['longitude'].toString()) ?? 0.0;
          }

          final storeName = (v['storeNameAr'] ?? v['storeName'] ?? v['name'] ?? 'Store').toString();
          final branchName = (branch['nameAr'] ?? branch['name'] ?? '').toString();
          final phone = (branch['phone'] ?? v['phone'] ?? v['user']?['phone'] ?? '').toString();
          final address = (branch['address'] ?? v['address'] ?? '').toString();
          final subtotal = double.tryParse(f['subtotal']?.toString() ?? '0') ?? 0.0;
          final isContracted = (f['isContracted'] as bool?) ??
              (branch['isContracted'] as bool?) ??
              (v['isContracted'] as bool?) ??
              false;
          final commRate = double.tryParse(f['commissionRate']?.toString() ?? '10') ?? 10.0;
          final netContracted = subtotal - (subtotal * (commRate / 100)).roundToDouble();
          final double cashToPay = f['cashToPay'] != null
              ? (double.tryParse(f['cashToPay'].toString()) ?? 0.0)
              : (isContracted
                  ? (netContracted < 0 ? 0.0 : netContracted)
                  : subtotal);

          final fId = f['id']?.toString() ?? '';
          final rawFItems = f['items'];
          final stopItems = (rawFItems is List && rawFItems.isNotEmpty)
              ? rawFItems
              : allItems
                  .where((it) => it is Map && it['fulfillmentId'] == fId)
                  .toList();

          pickupStops.add({
            'fulfillmentId': fId,
            'vendorId': f['vendorId']?.toString() ?? '',
            'storeName': storeName,
            'branchName': branchName,
            'vendorLogo': (v['logo'] ?? v['logoUrl'])?.toString(),
            'name': branchName.isNotEmpty ? '$storeName ($branchName)' : storeName,
            'phone': phone,
            'address': address,
            'lat': bLat,
            'lng': bLng,
            'subtotal': subtotal,
            'isContracted': isContracted,
            'cashToPay': cashToPay,
            'items': stopItems,
            'status': f['status']?.toString() ?? 'PENDING',
            'pickedUpAt': f['pickedUpAt'],
            'pickupImageUrl': f['pickupImageUrl']?.toString(),
          });
          if (vendorLat == 0.0 && vendorLng == 0.0 && bLat != 0.0 && bLng != 0.0) {
            vendorLat = bLat;
            vendorLng = bLng;
          }
        }
      }
    }

    if (pickupStops.isEmpty && (vendorLat != 0.0 || vendorData is Map || isCustomOrRide)) {
      final storeName = orderType.isRide
          ? (isAr ? 'العميل' : 'Customer')
          : (vendorData is Map
                  ? (vendorData['storeNameAr'] ?? vendorData['storeName'] ?? vendorData['name'])
                  : (orderType.isCustomDelivery
                      ? (isAr ? 'موقع الاستلام' : 'Pickup Location')
                      : 'Store'))
              .toString();
      final branch = order['vendorBranch'] is Map ? (order['vendorBranch'] as Map) : {};
      final branchName = (branch['nameAr'] ?? branch['name'] ?? '').toString();
      final phone = isCustomOrRide
          ? (order['pickupPhone']?.toString().trim().isNotEmpty == true
              ? order['pickupPhone'].toString().trim()
              : customerPhone)
          : (branch['phone'] ?? (vendorData is Map ? vendorData['phone'] : '') ?? '').toString();
      final address = (branch['address'] ?? order['pickupAddress'] ?? '').toString();
      final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
      final isContracted = (branch['isContracted'] ?? (vendorData is Map ? vendorData['isContracted'] : false)) ?? false;
      final double cashToPay = order['financials'] is Map && order['financials']['cashToPayStore'] != null
          ? (double.tryParse(order['financials']['cashToPayStore'].toString()) ?? 0.0)
          : (order['cashToPay'] != null
              ? (double.tryParse(order['cashToPay'].toString()) ?? 0.0)
              : subtotal);

      pickupStops.add({
        'fulfillmentId': '',
        'vendorId': order['vendorId']?.toString() ?? '',
        'storeName': storeName,
        'branchName': branchName,
        'vendorLogo': orderType.isRide
            ? customerAvatar
            : (vendorData is Map ? (vendorData['logo'] ?? vendorData['logoUrl']) : null)
                ?.toString(),
        'name': branchName.isNotEmpty ? '$storeName ($branchName)' : storeName,
        'phone': phone,
        'address': address,
        'lat': vendorLat,
        'lng': vendorLng,
        'subtotal': subtotal,
        'isContracted': isContracted,
        'cashToPay': cashToPay,
        'items': allItems,
        'status': order['status'] ?? 'PENDING',
      });
    }
    
    final dl = order['deliveryLocation'] ?? order['customer']?['location'] ?? order['destinationLocation'];
    double customerLat = 0.0;
    double customerLng = 0.0;
    if (dl is List && dl.length > 1) {
      customerLng = double.tryParse(dl[0].toString()) ?? 0.0;
      customerLat = double.tryParse(dl[1].toString()) ?? 0.0;
    } else if (dl is Map && dl['coordinates'] is List && (dl['coordinates'] as List).length > 1) {
      customerLng = double.tryParse(dl['coordinates'][0].toString()) ?? 0.0;
      customerLat = double.tryParse(dl['coordinates'][1].toString()) ?? 0.0;
    } else if (order['deliveryAddress'] is Map) {
      final addr = order['deliveryAddress'] as Map;
      customerLat = double.tryParse((addr['latitude'] ?? addr['lat'])?.toString() ?? '') ?? 0.0;
      customerLng = double.tryParse((addr['longitude'] ?? addr['lng'] ?? addr['long'])?.toString() ?? '') ?? 0.0;
    }

    final status = order['status'] ?? '';
    final isCashOnDelivery = order['paymentMethod'] == 'CASH_ON_DELIVERY';
    final isMobileWallet = order['paymentMethod'] == 'MOBILE_WALLET';
    final isDelivering = status == 'PICKED_UP' || status == 'PENDING_PAYMENT';

    // Clamp current stop index and auto-advance past stops already marked PICKED_UP
    if (pickupStops.isNotEmpty) {
      if (_currentStopIndex >= pickupStops.length) {
        _currentStopIndex = pickupStops.length - 1;
      }
      _collectedStopIndices.clear();
      int firstPendingIndex = -1;
      for (int i = 0; i < pickupStops.length; i++) {
        final sStatus = pickupStops[i]['status']?.toString();
        final isPickedUp = sStatus == 'PICKED_UP' || pickupStops[i]['pickedUpAt'] != null;
        if (isPickedUp) {
          _collectedStopIndices.add(i);
        } else if (firstPendingIndex == -1) {
          firstPendingIndex = i;
        }
      }
      if (pickupStops.length > 1 &&
          firstPendingIndex != -1 &&
          _collectedStopIndices.contains(_currentStopIndex)) {
        _currentStopIndex = firstPendingIndex;
      }
    }
    final currentStop = pickupStops.isNotEmpty ? pickupStops[_currentStopIndex] : null;
    
    LatLng? targetLocation;
    if (!isDelivering &&
        currentStop != null &&
        (currentStop['lat'] as num?)?.toDouble() != 0.0 &&
        (currentStop['lng'] as num?)?.toDouble() != 0.0) {
      targetLocation = LatLng(
        (currentStop['lat'] as num).toDouble(),
        (currentStop['lng'] as num).toDouble(),
      );
    } else if (isDelivering && customerLat != 0.0 && customerLng != 0.0) {
      targetLocation = LatLng(customerLat, customerLng);
    }

    final profileAsync = ref.watch(driverProfileProvider);
    final profile = profileAsync.asData?.value;
    final vehicleType = (profile is Map ? (profile['vehicleType'] ?? profile['vehicle_type']) : null)?.toString().toUpperCase().trim() ?? 'MOTORCYCLE';
    final vehiclePlate = profile is Map ? profile['vehiclePlate']?.toString().trim() : null;
    final driverName = profile is Map ? (profile['name']?.toString().trim() ?? '') : '';

    final List<Marker> markers = [];
    if (_currentPosition != null) {
      final heading = (_currentPosition!.heading.isFinite && _currentPosition!.heading >= 0)
          ? _currentPosition!.heading
          : 0.0;
      final speedKmh = (_currentPosition!.speed.isFinite && _currentPosition!.speed > 0)
          ? _currentPosition!.speed * 3.6
          : 0.0;
      final isMoving = speedKmh > 1.5;

      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 76,
          height: 76,
          child: RepaintBoundary(
            child: InDriveVehicleMarker(
              size: 52,
              heading: heading,
              isMoving: isMoving,
              vehicleType: vehicleType,
              plateNumber: vehiclePlate,
              label: (vehiclePlate != null && vehiclePlate.isNotEmpty)
                  ? vehiclePlate
                  : (driverName.isNotEmpty ? driverName : null),
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (isDelivering) {
      if (customerLat != 0.0 && customerLng != 0.0) {
        markers.add(
          Marker(
            point: LatLng(customerLat, customerLng),
            width: 42,
            height: 42,
            child: const NavigationPinMarker(
              icon: LucideIcons.mapPin,
              pinColor: Color(0xFFEF4444),
            ),
          ),
        );
      }
    } else {
      for (int i = 0; i < pickupStops.length; i++) {
        final stop = pickupStops[i];
        final stopLat = stop['lat'] as double;
        final stopLng = stop['lng'] as double;
        final stopName = stop['name'] as String;
        final isMultiple = pickupStops.length > 1;
        final isSelected = i == _currentStopIndex;
        final isCollected = _collectedStopIndices.contains(i);

        if (stopLat == 0.0 || stopLng == 0.0) continue;

        markers.add(
          Marker(
            point: LatLng(stopLat, stopLng),
            width: isMultiple ? 116 : 44,
            height: isMultiple ? 66 : 44,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: GestureDetector(
                onTap: () {
                  setState(() => _currentStopIndex = i);
                  if (_isMapReady) {
                    _mapController.move(LatLng(stopLat, stopLng), 15);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isCollected
                                ? AppColors.success
                                : (isSelected ? AppColors.primary : const Color(0xFF1E293B)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isCollected
                                ? LucideIcons.check
                                : (orderType.isRide
                                    ? LucideIcons.user
                                    : (orderType.isCustomDelivery
                                        ? LucideIcons.package
                                        : LucideIcons.store)),
                            color: isCollected || !isSelected ? Colors.white : Colors.black,
                            size: 16,
                          ),
                        ),
                        if (isMultiple)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: CircleAvatar(
                              radius: 7,
                              backgroundColor: isCollected ? Colors.green.shade800 : Colors.black,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isMultiple)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 8.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    // Determine Polyline
    final List<LatLng> polylinePoints = [];
    if (_currentPosition != null) {
      polylinePoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
      if (isDelivering) {
        if (customerLat != 0.0 && customerLng != 0.0) {
          polylinePoints.add(LatLng(customerLat, customerLng));
        }
      } else {
        for (int i = 0; i < pickupStops.length; i++) {
          if (_collectedStopIndices.contains(i) && i < _currentStopIndex) continue;
          final stop = pickupStops[i];
          final sLat = stop['lat'] as double;
          final sLng = stop['lng'] as double;
          if (sLat != 0.0 && sLng != 0.0) {
            polylinePoints.add(LatLng(sLat, sLng));
          }
        }
        if (customerLat != 0.0 && customerLng != 0.0) {
          polylinePoints.add(LatLng(customerLat, customerLng));
        }
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : (targetLocation ?? const LatLng(30.0444, 31.2357)),
            initialZoom: 14.0,
            onMapReady: () {
              _isMapReady = true;
            },
          ),
          children: [
            const AppMapTileLayer(
              userAgentPackageName: 'com.otlobegy.driver',
            ),
            if (polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: NavigationRoutePolylines.build(
                  points: polylinePoints,
                  foregroundColor: AppColors.primary,
                ),
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        
        // Speed Limit Sign (Overpass OSM Maxspeed)
        if (_roadSpeedLimit != null)
          Positioned(
            top: 16,
            left: 16 + MediaQuery.paddingOf(context).left,
            child: SpeedLimitSign(
              speedLimit: _roadSpeedLimit!.speed,
              unit: _roadSpeedLimit!.unit,
              currentSpeed: _currentPosition != null && _currentPosition!.speed > 0
                  ? _currentPosition!.speed * 3.6
                  : null,
            ),
          ),

        // Floating Center Map Button
        Positioned(
          top: 16,
          right: 16 + MediaQuery.paddingOf(context).right,
          child: FloatingActionButton(
            heroTag: 'driver_center_map_fab',
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.58,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, -5)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20.0,
                18.0,
                20.0,
                18.0 + MediaQuery.paddingOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Multi-Stop Waypoint Bar (when multiple pickup stops exist)
                    if (pickupStops.length > 1 && !isDelivering) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < pickupStops.length; i++) ...[
                              _buildStopChip(
                                index: i,
                                totalStops: pickupStops.length,
                                stop: pickupStops[i],
                                isActive: _currentStopIndex == i,
                                isCollected: _collectedStopIndices.contains(i),
                                isAr: isAr,
                                onTap: () {
                                  setState(() => _currentStopIndex = i);
                                  final sLat = pickupStops[i]['lat'] as double;
                                  final sLng = pickupStops[i]['lng'] as double;
                                  if (sLat != 0 && sLng != 0 && _isMapReady) {
                                    _mapController.move(LatLng(sLat, sLng), 15);
                                  }
                                },
                              ),
                              if (i < pickupStops.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    isAr ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                                    size: 14,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 2. Active Header
                    Row(
                      children: [
                        AppNetworkAvatar(
                          imageUrl: ImageUtils.formatImageUrl(
                            (orderType.isRide ||
                                    status == 'PICKED_UP' ||
                                    status == 'PENDING_PAYMENT')
                                ? customerAvatar
                                : (currentStop?['vendorLogo'] ??
                                        (order['vendor'] is Map
                                            ? (order['vendor']['logo'] ??
                                                order['vendor']['logoUrl'])
                                            : null))
                                    ?.toString(),
                          ),
                          size: 46,
                          borderRadius: (orderType.isRide ||
                                  status == 'PICKED_UP' ||
                                  status == 'PENDING_PAYMENT')
                              ? null
                              : 12,
                          fallbackIcon: (orderType.isRide ||
                                  status == 'PICKED_UP' ||
                                  status == 'PENDING_PAYMENT')
                              ? LucideIcons.user
                              : (orderType.isCustomDelivery
                                  ? LucideIcons.package
                                  : LucideIcons.store),
                          fallbackIconSize: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      status == 'PENDING_PAYMENT'
                                          ? (isAr ? 'بانتظار الدفع من العميل' : 'Waiting for Customer Payment')
                                          : (status == 'PICKED_UP')
                                              ? (orderType.isRide
                                                  ? (isAr ? 'التوجه إلى الوجهة' : 'Navigate to Dropoff')
                                                  : l10n.navigatingToCustomer)
                                              : (pickupStops.length > 1
                                                  ? (isAr ? 'المحطة ${_currentStopIndex + 1} من ${pickupStops.length} (استلام)' : 'Stop ${_currentStopIndex + 1} of ${pickupStops.length} (Pickup)')
                                                  : (orderType.isRide
                                                      ? (isAr ? 'التوجه إلى نقطة الاستلام' : 'Navigate to Pickup')
                                                      : (orderType.isCustomDelivery
                                                          ? (isAr ? 'التوجه إلى موقع الاستلام' : 'Navigating to Pickup')
                                                          : l10n.navigatingToVendor))),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (order['isStacked'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isAr ? 'مجمع في المسار' : 'Batch',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (status == 'PICKED_UP' || status == 'PENDING_PAYMENT')
                                    ? (customerName?.isNotEmpty == true ? customerName! : l10n.customerFallback)
                                    : (orderType.isRide
                                        ? (isAr ? 'العميل' : 'Customer')
                                        : (currentStop != null
                                            ? currentStop['name']
                                            : (isCustomOrRide
                                                ? (order['pickupAddress']?.toString() ?? (isAr ? 'موقع الاستلام' : 'Pickup Location'))
                                                : ((order['vendor'] is Map ? order['vendor']['name'] ?? order['vendor']['storeName'] : null) ?? l10n.vendorFallback)))),
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (orderType.isRide) ...[
                                Builder(builder: (_) {
                                  final addrText = isDelivering
                                      ? (order['deliveryAddress'] is String
                                          ? order['deliveryAddress'].toString()
                                          : (order['deliveryAddress'] is Map
                                              ? (order['deliveryAddress']['address'] ?? '').toString()
                                              : ''))
                                      : ((currentStop?['address'] ?? order['pickupAddress'] ?? '').toString());
                                  final infoLine = !isDelivering &&
                                          customerName != null &&
                                          customerName.isNotEmpty
                                      ? (addrText.isNotEmpty
                                          ? '$customerName • $addrText'
                                          : customerName)
                                      : addrText;
                                  if (infoLine.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      infoLine,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ] else if (!isDelivering && currentStop != null && (currentStop['address'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  currentStop['address'],
                                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Store Payment Instruction Banner (STANDARD store orders only)
                    if (!isDelivering && currentStop != null && orderType.hasStoreFulfillment) ...[
                      Builder(builder: (context) {
                        final bool isContracted = currentStop['isContracted'] == true;
                        final double cashToPay =
                            (currentStop['cashToPay'] as num?)?.toDouble() ?? 0.0;
                        final bool noCashAtStore = cashToPay <= 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: noCashAtStore
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: noCashAtStore
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : AppColors.warning.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                noCashAtStore ? LucideIcons.badgeCheck : LucideIcons.banknote,
                                size: 16,
                                color: noCashAtStore ? AppColors.success : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  noCashAtStore
                                      ? (isAr
                                          ? 'لا تدفع كاش في هذا المتجر (0 $currency)'
                                          : 'Do not pay cash at this store (0 $currency)')
                                      : isContracted
                                          ? (isAr
                                              ? 'متجر شريك: ادفع صافي الفاتورة كاش: ${cashToPay.toStringAsFixed(2)} $currency'
                                              : 'Partner Store: Pay net cash at pickup: ${cashToPay.toStringAsFixed(2)} $currency')
                                          : (isAr
                                              ? 'متجر غير متعاقد: ادفع للمتجر كاش: ${cashToPay.toStringAsFixed(2)} $currency'
                                              : 'Uncontracted: Pay store in cash: ${cashToPay.toStringAsFixed(2)} $currency'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: noCashAtStore ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // 4. Action Row (Maps Navigation, Call, Details, Chat)
                    Row(
                      children: [
                        // Navigation with Google Maps
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              LatLng? destination;
                              if (isDelivering) {
                                if (customerLat != 0.0 && customerLng != 0.0) {
                                  destination = LatLng(customerLat, customerLng);
                                }
                              } else if (currentStop != null) {
                                final sLat =
                                    (currentStop['lat'] as num?)?.toDouble() ?? 0.0;
                                final sLng =
                                    (currentStop['lng'] as num?)?.toDouble() ?? 0.0;
                                if (sLat != 0.0 && sLng != 0.0) {
                                  destination = LatLng(sLat, sLng);
                                }
                              }
                              destination ??= targetLocation;

                              if (destination == null ||
                                  destination.latitude == 0.0 ||
                                  destination.longitude == 0.0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAr
                                          ? 'إحداثيات الموقع غير متوفرة'
                                          : 'Location coordinates are not available',
                                    ),
                                  ),
                                );
                                return;
                              }
                              _launchMapsNavigation(
                                destination.latitude,
                                destination.longitude,
                              );
                            },
                            icon: const Icon(LucideIcons.navigation, size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(isAr ? 'خرائط' : 'Maps', maxLines: 1),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Phone Call
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (isDelivering || orderType.isRide) {
                                _callPhone(context, customerPhone);
                              } else if (currentStop != null) {
                                _callPhone(context, currentStop['phone'] as String?);
                              }
                            },
                            icon: const Icon(LucideIcons.phone, size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(isAr ? 'اتصال' : 'Call', maxLines: 1),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // View Details
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              OrderDetailsBottomSheet.show(context, order);
                            },
                            icon: const Icon(LucideIcons.fileText, size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(isAr ? 'التفاصيل' : 'Details', maxLines: 1),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              side: BorderSide(color: Theme.of(context).dividerColor),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chat
                        IconButton(
                          onPressed: () => context.push('/chat/${order['id']}'),
                          icon: const Icon(LucideIcons.messageCircle, color: AppColors.primary),
                          tooltip: l10n.messageButton,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isDelivering && !orderType.isRide && currentStop != null && (currentStop['items'] as List).isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'أصناف هذه المحطة (${(currentStop['items'] as List).length}):' : 'Items at this stop (${(currentStop['items'] as List).length}):',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final item in (currentStop['items'] as List))
                                  () {
                                    final prod = item is Map &&
                                            item['product'] is Map
                                        ? item['product'] as Map
                                        : null;
                                    final rawImg = item is Map
                                        ? ([
                                              prod?['imageUrl'],
                                              prod?['image'],
                                              item['imageUrl'],
                                              item['image'],
                                            ]
                                                .map((e) =>
                                                    e?.toString().trim() ?? '')
                                                .firstWhere(
                                                    (e) => e.isNotEmpty,
                                                    orElse: () => ''))
                                        : '';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppNetworkAvatar(
                                            imageUrl: rawImg.isNotEmpty
                                                ? ImageUtils.formatImageUrl(
                                                    rawImg)
                                                : null,
                                            size: 20,
                                            borderRadius: 5,
                                            fallbackIcon: LucideIcons.package,
                                            fallbackIconSize: 11,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.08),
                                            foregroundColor: Colors.grey,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              '${item['quantity'] ?? 1}x ${item['productName'] ?? item['name'] ?? 'Item'}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildPickupPhotoWidget(context, status, l10n, order, pickupStops),
                    _buildDeliveryPhotoWidget(context, status, l10n, order),
                    _buildActionButton(context, status, isCashOnDelivery, isMobileWallet, targetLocation, l10n, order, pickupStops),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopChip({
    required int index,
    required int totalStops,
    required Map<String, dynamic> stop,
    required bool isActive,
    required bool isCollected,
    required bool isAr,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCollected
              ? AppColors.success.withValues(alpha: 0.12)
              : (isActive ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCollected
                ? AppColors.success
                : (isActive ? AppColors.primary : Colors.grey.shade400),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCollected ? LucideIcons.checkCircle : (isActive ? LucideIcons.mapPin : LucideIcons.store),
              size: 13,
              color: isCollected ? AppColors.success : (isActive ? AppColors.primary : Colors.grey),
            ),
            const SizedBox(width: 5),
            Text(
              isAr ? 'محطة ${index + 1}: ${stop['name'] ?? stop['storeName']}' : 'Stop ${index + 1}: ${stop['name'] ?? stop['storeName']}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isCollected ? AppColors.success : (isActive ? AppColors.primary : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupPhotoWidget(
    BuildContext context,
    String status,
    AppLocalizations l10n,
    Map<String, dynamic> order, [
    List<Map<String, dynamic>> pickupStops = const [],
  ]) {
    if (!OrderTypeHelper.requiresOrderPhotos(order)) {
      return const SizedBox.shrink();
    }
    final isCustomOrRide =
        order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE';
    final currentStopStatus = (pickupStops.isNotEmpty && !isCustomOrRide)
        ? (pickupStops[_currentStopIndex]['status']?.toString() ?? status)
        : status;
    final currentStopPickedUp = (pickupStops.isNotEmpty && !isCustomOrRide) &&
        (currentStopStatus == 'PICKED_UP' || pickupStops[_currentStopIndex]['pickedUpAt'] != null);
    final showCapture = (status == 'DRIVER_ASSIGNED' ||
            status == 'PREPARING' ||
            status == 'READY_FOR_PICKUP' ||
            status == 'PARTIALLY_PICKED_UP') &&
        (isCustomOrRide || (!currentStopPickedUp && currentStopStatus == 'READY_FOR_PICKUP'));
    String? remoteUrl = (pickupStops.isNotEmpty && !isCustomOrRide)
        ? pickupStops[_currentStopIndex]['pickupImageUrl']?.toString()
        : order['pickupImageUrl']?.toString();
    if ((remoteUrl == null || remoteUrl.isEmpty) && pickupStops.isNotEmpty) {
      remoteUrl = pickupStops[_currentStopIndex]['pickupImageUrl']?.toString();
    }
    final activeGroupId = _resolveActiveDriverGroupId(order);
    if ((remoteUrl == null || remoteUrl.isEmpty) &&
        activeGroupId != null &&
        activeGroupId.isNotEmpty &&
        order['deliveryGroups'] is List) {
      for (final grp in (order['deliveryGroups'] as List)) {
        if (grp is Map &&
            grp['id']?.toString() == activeGroupId &&
            grp['pickupImageUrl'] != null &&
            grp['pickupImageUrl'].toString().isNotEmpty) {
          remoteUrl = grp['pickupImageUrl'].toString();
          break;
        }
      }
    }

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
    if (!OrderTypeHelper.requiresOrderPhotos(order)) {
      return const SizedBox.shrink();
    }
    final showCapture = status == 'PICKED_UP';
    final activeGroupId = _resolveActiveDriverGroupId(order);
    String? remoteUrl = order['deliveryImageUrl']?.toString();
    if ((remoteUrl == null || remoteUrl.isEmpty) &&
        activeGroupId != null &&
        activeGroupId.isNotEmpty &&
        order['deliveryGroups'] is List) {
      for (final grp in (order['deliveryGroups'] as List)) {
        if (grp is Map &&
            grp['id']?.toString() == activeGroupId &&
            grp['deliveryImageUrl'] != null &&
            grp['deliveryImageUrl'].toString().isNotEmpty) {
          remoteUrl = grp['deliveryImageUrl'].toString();
          break;
        }
      }
    }

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
            icon: const AppAdaptiveChevron(size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String status, bool isCashOnDelivery, bool isMobileWallet, LatLng? targetLocation, AppLocalizations l10n, Map<String, dynamic> order, [List<Map<String, dynamic>> pickupStops = const []]) {
    void showErr(Object e) {
      if (context.mounted) {
        final message = ErrorUtils.translate(context, e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    Future<void> handleAction(Future<void> Function() action) async {
      // 1. Fetch fresh GPS fix at the exact moment of button press
      Position? freshPos = _currentPosition;
      try {
        freshPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
        if (mounted) {
          setState(() => _currentPosition = freshPos);
        }
      } catch (_) {
        try {
          freshPos ??= await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      bool withinFence = true;
      double? calculatedDistance;
      if (freshPos != null &&
          targetLocation != null &&
          targetLocation.latitude != 0.0 &&
          targetLocation.longitude != 0.0) {
        calculatedDistance = Geolocator.distanceBetween(
          freshPos.latitude,
          freshPos.longitude,
          targetLocation.latitude,
          targetLocation.longitude,
        );
        final accuracy = (freshPos.accuracy.isFinite && freshPos.accuracy > 0)
            ? freshPos.accuracy
            : 30.0;
        // Indoor/GPS fixes can be wildly inaccurate. Only warn when the fix is
        // reasonably trustworthy and the driver is clearly outside the fence,
        // otherwise drivers get a false "you are far away" prompt at the door.
        final allowedRadius = math.max(2500.0, 800.0 + accuracy * 2);
        if (accuracy <= 1500 && calculatedDistance > allowedRadius) {
          withinFence = false;
        }
      }

      if (!withinFence && context.mounted) {
        final isAr = l10n.localeName == 'ar';
        final distKm = calculatedDistance != null ? (calculatedDistance / 1000).toStringAsFixed(1) : '';
        final distMsg = distKm.isNotEmpty
            ? (isAr ? 'أنت على بعد تقريبي $distKm كم من الموقع المحدد. هل تريد المتابعة وتأكيد العملية؟' : 'You appear to be approximately $distKm km from the target location. Do you wish to continue anyway?')
            : (isAr ? 'أنت بعيد جدا عن الموقع. هل تريد المتابعة؟' : 'You are far from the location. Continue anyway?');

        final confirm = await AppConfirmDialog.show(
          context,
          title: isAr ? 'تأكيد المسافة' : 'Distance Override',
          message: distMsg,
          confirmLabel: isAr ? 'متابعة' : 'Continue',
          cancelLabel: isAr ? 'إلغاء' : 'Cancel',
          icon: LucideIcons.mapPin,
          confirmIcon: LucideIcons.navigation,
        );
        if (confirm != true) return;
      }
      try {
        await action();
      } catch (e) {
        showErr(e);
      }
    }

    if (status == 'PREPARING' ||
        status == 'DRIVER_ASSIGNED' ||
        status == 'READY_FOR_PICKUP' ||
        status == 'PARTIALLY_PICKED_UP') {
      final isCustomOrRide =
          order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE';
      final currentStopStatus = (pickupStops.isNotEmpty && !isCustomOrRide)
          ? (pickupStops[_currentStopIndex]['status']?.toString() ?? status)
          : status;
      final currentStopPickedUp = (pickupStops.isNotEmpty && !isCustomOrRide) &&
          (currentStopStatus == 'PICKED_UP' ||
              pickupStops[_currentStopIndex]['pickedUpAt'] != null ||
              _collectedStopIndices.contains(_currentStopIndex));

      int firstPendingIndex = -1;
      int remainingPendingCount = 0;
      for (int i = 0; i < pickupStops.length; i++) {
        final sStatus = pickupStops[i]['status']?.toString();
        final collected = sStatus == 'PICKED_UP' ||
            pickupStops[i]['pickedUpAt'] != null ||
            _collectedStopIndices.contains(i);
        if (!collected) {
          remainingPendingCount++;
          if (firstPendingIndex == -1) {
            firstPendingIndex = i;
          }
        }
      }

      if (!isCustomOrRide && currentStopPickedUp) {
        return PrimaryButton(
          text: firstPendingIndex != -1
              ? (l10n.localeName == 'ar'
                  ? 'تم استلام هذه المحطة ✓ (الانتقال للمحطة ${firstPendingIndex + 1})'
                  : 'Stop Collected ✓ (Go to Stop ${firstPendingIndex + 1})')
              : (l10n.localeName == 'ar'
                  ? 'تم استلام هذه المحطة ✓'
                  : 'Stop Collected ✓'),
          onPressed: firstPendingIndex != -1
              ? () {
                  setState(() => _currentStopIndex = firstPendingIndex);
                  final next = pickupStops[firstPendingIndex];
                  final sLat = next['lat'] as double;
                  final sLng = next['lng'] as double;
                  if (sLat != 0 && sLng != 0 && _isMapReady) {
                    _mapController.move(LatLng(sLat, sLng), 15);
                  }
                }
              : null,
        );
      }

      if (!isCustomOrRide &&
          firstPendingIndex != -1 &&
          firstPendingIndex < _currentStopIndex) {
        return PrimaryButton(
          text: l10n.localeName == 'ar'
              ? 'يجب استلام المحطة ${firstPendingIndex + 1} أولاً'
              : 'Collect Stop ${firstPendingIndex + 1} First',
          onPressed: () {
            setState(() => _currentStopIndex = firstPendingIndex);
            final next = pickupStops[firstPendingIndex];
            final sLat = next['lat'] as double;
            final sLng = next['lng'] as double;
            if (sLat != 0 && sLng != 0 && _isMapReady) {
              _mapController.move(LatLng(sLat, sLng), 15);
            }
          },
        );
      }

      if (!isCustomOrRide && currentStopStatus != 'READY_FOR_PICKUP') {
        return PrimaryButton(
          text: l10n.localeName == 'ar'
              ? 'بانتظار تجهيز الطلب من المطعم'
              : 'Waiting for vendor to prepare...',
          onPressed: null,
        );
      }
      final bool hasMultiple = pickupStops.length > 1;
      final bool isFinalRemainingStop = remainingPendingCount <= 1;

      if (hasMultiple && !isFinalRemainingStop) {
        return PrimaryButton(
          text: l10n.localeName == 'ar'
              ? 'تأكيد استلام المحطة ${_currentStopIndex + 1} مع الصورة'
              : 'Confirm Stop ${_currentStopIndex + 1} Pickup (Photo)',
          onPressed: () => handleAction(() async {
            var photo = _pickupPhoto;
            if (photo == null) {
              photo = await _capturePickupPhoto();
              if (photo == null) return;
            }
            final curFulfillmentId = pickupStops[_currentStopIndex]['fulfillmentId']?.toString();
            await ref
                .read(orderExecutionProvider.notifier)
                .confirmPickupWithPhoto(photo, fulfillmentId: curFulfillmentId);
            int nextPending = -1;
            setState(() {
              _collectedStopIndices.add(_currentStopIndex);
              _pickupPhoto = null;
              for (int i = 0; i < pickupStops.length; i++) {
                if (!_collectedStopIndices.contains(i) &&
                    pickupStops[i]['status']?.toString() != 'PICKED_UP' &&
                    pickupStops[i]['pickedUpAt'] == null) {
                  nextPending = i;
                  break;
                }
              }
              if (nextPending != -1) {
                _currentStopIndex = nextPending;
              }
            });
            if (nextPending != -1) {
              final next = pickupStops[nextPending];
              final sLat = next['lat'] as double;
              final sLng = next['lng'] as double;
              if (sLat != 0 && sLng != 0 && _isMapReady) {
                _mapController.move(LatLng(sLat, sLng), 15);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.localeName == 'ar'
                      ? 'تم تأكيد استلام المحطة! توجه الآن إلى ${next['name'] ?? next['storeName']}'
                      : 'Stop confirmed! Proceed to ${next['name'] ?? next['storeName']}'),
                  backgroundColor: AppColors.success,
                ),
              );
              }
            }
          }),
        );
      }

      final requiresPhotos = OrderTypeHelper.requiresOrderPhotos(order);
      final isAr = l10n.localeName == 'ar';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            text: hasMultiple
                ? (isAr ? 'تأكيد استلام المحطة الأخيرة مع الصورة' : 'Confirm Final Stop Pickup (Photo)')
                : l10n.confirmPickup,
            onPressed: () => handleAction(() async {
              if (!requiresPhotos) {
                await ref
                    .read(orderExecutionProvider.notifier)
                    .confirmPickupWithoutPhoto();
                if (!mounted) return;
                setState(() {
                  _collectedStopIndices.add(_currentStopIndex);
                  _pickupPhoto = null;
                });
                return;
              }
              var photo = _pickupPhoto;
              if (photo == null) {
                photo = await _capturePickupPhoto();
                if (photo == null) return;
              }
              final rawFulfillmentId = pickupStops.isNotEmpty
                  ? pickupStops[_currentStopIndex]['fulfillmentId']?.toString()
                  : null;
              final curFulfillmentId = (rawFulfillmentId != null && rawFulfillmentId.isNotEmpty)
                  ? rawFulfillmentId
                  : null;
              await ref
                  .read(orderExecutionProvider.notifier)
                  .confirmPickupWithPhoto(photo, fulfillmentId: curFulfillmentId);
              if (!mounted) return;
              setState(() {
                _collectedStopIndices.add(_currentStopIndex);
                _pickupPhoto = null;
              });
            }),
          ),
          if (requiresPhotos) ...[
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
        ],
      );
    } else if (status == 'PICKED_UP') {
      final orderType = OrderTypeHelper.resolve(order);
      final requiresPhotos = orderType.requiresOrderPhotos;
      final isAr = l10n.localeName == 'ar';
      String label;
      if (isCashOnDelivery) {
        final totalStr = order['total']?.toString() ?? order['grandTotal']?.toString() ?? order['totalFee']?.toString() ?? '0.00';
        final total = double.tryParse(totalStr) ?? 0.0;
        final upfrontStr = order['upfrontAmount']?.toString() ?? '0.00';
        final upfront = double.tryParse(upfrontStr) ?? 0.0;
        final rawCashToCollect = (order['financials'] is Map
                ? order['financials']['cashToCollect']
                : null) ??
            order['cashToCollect'];
        final double toCollect = (rawCashToCollect != null &&
                double.tryParse(rawCashToCollect.toString()) != null)
            ? double.parse(rawCashToCollect.toString())
            : (total - upfront);
        final collectAmount = toCollect > 0 ? toCollect : 0.0;
        if (orderType.isRide) {
          label = isAr
              ? 'تحصيل الكاش وإنهاء الرحلة (${collectAmount.toStringAsFixed(2)} ج.م)'
              : 'Collect Cash & Complete Ride (${collectAmount.toStringAsFixed(2)} EGP)';
        } else {
          label = '${l10n.collectCashAndDeliver} (${collectAmount.toStringAsFixed(2)} EGP)';
        }
      } else {
        label = orderType.isRide
            ? (isAr ? 'إنهاء الرحلة' : 'Complete Ride')
            : l10n.confirmDelivery;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            text: label,
            onPressed: () => handleAction(() async {
              if (!requiresPhotos) {
                await ref
                    .read(orderExecutionProvider.notifier)
                    .confirmDeliveryWithoutPhoto();
              } else {
                var photo = _deliveryPhoto;
                if (photo == null) {
                  photo = await _captureDeliveryPhoto();
                  if (photo == null) return;
                }
                final activeGroupId = _resolveActiveDriverGroupId(order);
                await ref
                    .read(orderExecutionProvider.notifier)
                    .confirmDeliveryWithPhoto(
                      photo,
                      deliveryGroupId: activeGroupId,
                    );
              }
              if (!mounted || !context.mounted) return;
              await _navigateAfterOrderCompleted(context, order, l10n);
            }),
          ),
          if (requiresPhotos) ...[
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
      final isPrimaryCollector = order['isPrimaryCollector'] != false &&
          (order['financials'] is Map
              ? (order['financials']['isPrimaryCollector'] != false)
              : true);

      if (!isPrimaryCollector) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                LucideIcons.hourglass,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? 'في انتظار تأكيد استلام الدفع من السائق الأساسي للطلب.'
                    : 'Waiting for the primary collector to confirm payment reception.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'سيتم تحديث حالة طلبك ومحطات الاستلام تلقائياً فور تأكيد استلام المبلغ.'
                    : 'Your delivery stops and status will update automatically once payment is confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }

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

  Future<void> _navigateAfterOrderCompleted(
    BuildContext context,
    Map<String, dynamic> order,
    AppLocalizations l10n,
  ) async {
    final repo = ref.read(driverOrdersRepositoryProvider);
    final activeOrders = await repo.getActiveDriverOrders();

    if (activeOrders.isNotEmpty) {
      final currentId = order['id']?.toString();
      final stillHasCurrent = currentId != null &&
          activeOrders.any((o) => o['id']?.toString() == currentId);
      if (stillHasCurrent) {
        if (mounted) {
          setState(() {
            _pickupPhoto = null;
            _deliveryPhoto = null;
            _collectedStopIndices.clear();
            _currentStopIndex = 0;
          });
        }
        ref.read(orderExecutionProvider.notifier).selectOrder(currentId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.localeName == 'ar'
                  ? 'تم التسليم بنجاح! لديك محطة أخرى ضمن نفس الطلب'
                  : 'Trip delivered! Moving to your next trip for this order',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        return;
      }
      final remaining =
          activeOrders.where((o) => o['id']?.toString() != currentId).toList();
      if (remaining.isNotEmpty) {
        final nextOrder = remaining.first;
        final nextId = nextOrder['id']?.toString();
        if (nextId != null) {
          if (mounted) {
            setState(() {
              _pickupPhoto = null;
              _deliveryPhoto = null;
              _collectedStopIndices.clear();
              _currentStopIndex = 0;
            });
          }
          ref.read(orderExecutionProvider.notifier).selectOrder(nextId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.localeName == 'ar'
                    ? 'تم الإنهاء بنجاح! جاري التوجه للمحطة التالية (${remaining.length} متبقي)'
                    : 'Completed! Moving to next stop (${remaining.length} remaining)',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          return;
        }
      }
    }

    if (context.mounted) context.go('/dashboard');
  }
}
