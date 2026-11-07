import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import '../../data/driver_models.dart';

class DriverMapDetailsCard extends StatelessWidget {
  final DriverProfile driver;
  final LatLng location;
  final bool isLive;
  final Map<String, dynamic>? activeOrder;
  final bool isLoadingOrder;
  final LatLng? pickupLocation;
  final LatLng? deliveryLocation;
  final VoidCallback onClose;
  final void Function(String phone) onCallPhone;
  final void Function(double lat, double lng, {String? label}) onOpenMaps;
  final VoidCallback? onAssignOrder;
  final void Function(Map<String, dynamic> order)? onViewOrderDetails;
  final VoidCallback? onCenterOnDriver;
  final VoidCallback? onCenterOnPickup;
  final VoidCallback? onCenterOnDelivery;
  final bool isEmbeddedInSheet;

  const DriverMapDetailsCard({
    super.key,
    required this.driver,
    required this.location,
    required this.isLive,
    this.activeOrder,
    this.isLoadingOrder = false,
    this.pickupLocation,
    this.deliveryLocation,
    required this.onClose,
    required this.onCallPhone,
    required this.onOpenMaps,
    this.onAssignOrder,
    this.onViewOrderDetails,
    this.onCenterOnDriver,
    this.onCenterOnPickup,
    this.onCenterOnDelivery,
    this.isEmbeddedInSheet = false,
  });

  String _formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters م';
    }
    return '${km.toStringAsFixed(1)} كم';
  }

  String _formatDistanceEn(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  String _translateStatus(String status, bool isArabic) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case 'ACCEPTED':
        return isArabic ? 'تم القبول' : 'Accepted';
      case 'PREPARING':
        return isArabic ? 'جاري التحضير' : 'Preparing';
      case 'LOOKING_FOR_DRIVER':
        return isArabic ? 'جاري البحث عن سائق' : 'Looking for Driver';
      case 'DRIVER_ASSIGNED':
        return isArabic ? 'تم تعيين سائق' : 'Driver Assigned';
      case 'READY_FOR_PICKUP':
        return isArabic ? 'جاهز للاستلام' : 'Ready for Pickup';
      case 'PARTIALLY_PICKED_UP':
        return isArabic ? 'استلام جزئي' : 'Partially Picked Up';
      case 'PICKED_UP':
        return isArabic ? 'تم الاستلام (في الطريق)' : 'Picked Up (On the way)';
      case 'DELIVERED':
        return isArabic ? 'تم التوصيل' : 'Delivered';
      case 'CANCELLED':
        return isArabic ? 'ملغي' : 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success;
      case 'PICKED_UP':
        return Colors.blue;
      case 'DRIVER_ASSIGNED':
      case 'READY_FOR_PICKUP':
      case 'PREPARING':
        return Colors.amber.shade700;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color _getDriverStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ONLINE':
        return AppColors.success;
      case 'ON_DELIVERY':
        return Colors.blue;
      case 'ON_BREAK':
        return AppColors.warning;
      case 'SUSPENDED':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _translateDriverStatus(String status, bool isArabic) {
    switch (status.toUpperCase()) {
      case 'ONLINE':
        return isArabic ? 'متصل' : 'Online';
      case 'ON_DELIVERY':
        return isArabic ? 'في رحلة توصيل' : 'On Delivery';
      case 'ON_BREAK':
        return isArabic ? 'في استراحة' : 'On Break';
      case 'OFFLINE':
        return isArabic ? 'غير متصل' : 'Offline';
      case 'SUSPENDED':
        return isArabic ? 'موقوف' : 'Suspended';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Calculate distance and stage
    final distance = const Distance();
    double? distanceToNextKm;
    int? etaMinutes;
    double? distancePickupToDeliveryKm;
    bool isHeadingToCustomer = false;

    if (activeOrder != null) {
      final status = (activeOrder!['status']?.toString() ?? '').toUpperCase();
      isHeadingToCustomer = (status == 'PICKED_UP');

      if (isHeadingToCustomer && deliveryLocation != null) {
        distanceToNextKm = distance.as(LengthUnit.Meter, location, deliveryLocation!) / 1000.0;
      } else if (!isHeadingToCustomer && pickupLocation != null) {
        distanceToNextKm = distance.as(LengthUnit.Meter, location, pickupLocation!) / 1000.0;
      }

      if (distanceToNextKm != null) {
        final mins = (distanceToNextKm / 25.0 * 60).round();
        etaMinutes = mins < 1 ? 1 : mins;
      }

      if (pickupLocation != null && deliveryLocation != null) {
        distancePickupToDeliveryKm =
            distance.as(LengthUnit.Meter, pickupLocation!, deliveryLocation!) / 1000.0;
      }
    }

    final avatarPath = driver.avatar;
    final resolvedAvatar = (avatarPath == null || avatarPath.isEmpty)
        ? ''
        : ImageUtils.formatImageUrl(avatarPath);
    final avatarUrl = resolvedAvatar.isEmpty ? null : resolvedAvatar;
    final driverStatusColor = _getDriverStatusColor(driver.status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: isEmbeddedInSheet
            ? double.infinity
            : (MediaQuery.sizeOf(context).height * 0.55).clamp(320.0, 480.0),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isEmbeddedInSheet ? 0 : 20),
        border: isEmbeddedInSheet
            ? null
            : Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
                width: 1.2,
              ),
        boxShadow: isEmbeddedInSheet
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header: Driver Info ───
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: driverStatusColor.withValues(alpha: 0.15),
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(LucideIcons.user, size: 20, color: driverStatusColor)
                          : null,
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isLive ? AppColors.success : AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
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
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: driverStatusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _translateDriverStatus(driver.status, isArabic),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: driverStatusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isLive ? AppColors.success : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isLive
                                ? (isArabic ? 'موقع مباشر الآن' : 'Live location')
                                : (isArabic ? 'آخر موقع مسجل' : 'Last known location'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isLive ? AppColors.success : AppColors.warning,
                            ),
                          ),
                          if ((driver.vehiclePlate != null && driver.vehiclePlate!.isNotEmpty) ||
                              (driver.vehicleType != null && driver.vehicleType!.isNotEmpty)) ...[
                            const SizedBox(width: 6),
                            Icon(
                              _getVehicleIcon(driver.vehicleType),
                              size: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${driver.vehicleType ?? ""} ${driver.vehiclePlate ?? ""}'.trim(),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onCenterOnDriver != null)
                  IconButton(
                    onPressed: onCenterOnDriver,
                    icon: const Icon(LucideIcons.locateFixed, size: 18),
                    tooltip: isArabic ? 'توسيط على السائق' : 'Center on driver',
                  ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(LucideIcons.x, size: 18),
                  tooltip: isArabic ? 'إغلاق' : 'Close',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Active Order Section ───
            if (isLoadingOrder)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isArabic ? 'جاري فحص الطلب النشط للسائق...' : 'Checking driver active order...',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              )
            else if (activeOrder != null)
              _buildActiveOrderBannerAndDetails(
                context: context,
                isDark: isDark,
                isArabic: isArabic,
                order: activeOrder!,
                isHeadingToCustomer: isHeadingToCustomer,
                distanceToNextKm: distanceToNextKm,
                etaMinutes: etaMinutes,
                distancePickupToDeliveryKm: distancePickupToDeliveryKm,
              )
            else
              _buildNoActiveOrderBanner(
                context: context,
                isDark: isDark,
                isArabic: isArabic,
              ),

            const SizedBox(height: 14),

            // ─── Fast Action Buttons Row ───
            _buildActionButtonsRow(
              context: context,
              isArabic: isArabic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderBannerAndDetails({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required Map<String, dynamic> order,
    required bool isHeadingToCustomer,
    double? distanceToNextKm,
    int? etaMinutes,
    double? distancePickupToDeliveryKm,
  }) {
    final theme = Theme.of(context);
    final orderNumber = order['orderNumber']?.toString() ?? order['id']?.toString() ?? '';
    final status = (order['status']?.toString() ?? 'PENDING').toUpperCase();
    final statusColor = _getStatusColor(status);
    final orderType = order['type']?.toString() ?? 'STANDARD';

    // Customer
    final customer = order['customer'] is Map ? order['customer'] as Map : {};
    final customerUser = customer['user'] is Map ? customer['user'] as Map : {};
    final customerName = customerUser['name']?.toString() ?? (isArabic ? 'عميل' : 'Customer');
    final customerPhone = customerUser['phone']?.toString() ?? '';
    final deliveryAddress = order['deliveryAddress']?.toString() ?? '';

    // Vendor
    final vendor = order['vendor'] is Map ? order['vendor'] as Map : {};
    final vendorBranch = order['vendorBranch'] is Map ? order['vendorBranch'] as Map : {};
    final vendorStoreName = isArabic
        ? (vendor['storeNameAr'] ?? vendor['storeName'] ?? vendor['name'])
        : (vendor['storeName'] ?? vendor['storeNameAr'] ?? vendor['name']);
    final branchName = isArabic
        ? (vendorBranch['nameAr'] ?? vendorBranch['name'])
        : (vendorBranch['name'] ?? vendorBranch['nameAr']);
    final vendorName = (vendorStoreName != null && vendorStoreName.toString().trim().isNotEmpty)
        ? (branchName != null && branchName.toString().trim().isNotEmpty
            ? '$vendorStoreName - $branchName'
            : vendorStoreName.toString().trim())
        : (branchName?.toString().trim() ?? (isArabic ? 'المتجر' : 'Vendor'));
    final pickupAddress = order['pickupAddress']?.toString() ??
        vendorBranch['address']?.toString() ??
        vendor['address']?.toString() ??
        '';

    // Financial
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = (order['grandTotal'] as num?)?.toDouble() ??
        (order['total'] as num?)?.toDouble() ??
        (subtotal + deliveryFee);
    final paymentMethod = order['paymentMethod']?.toString() ?? 'CASH';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. High-Visibility Direction & Stage Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHeadingToCustomer
                  ? [
                      isDark ? const Color(0xFF0F2B48) : const Color(0xFFE0F2FE),
                      isDark ? const Color(0xFF133E64) : const Color(0xFFBAE6FD),
                    ]
                  : [
                      isDark ? const Color(0xFF3B270C) : const Color(0xFFFEF3C7),
                      isDark ? const Color(0xFF4C3310) : const Color(0xFFFDE68A),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHeadingToCustomer
                  ? Colors.blue.withValues(alpha: 0.4)
                  : Colors.amber.shade700.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isHeadingToCustomer ? Colors.blue : Colors.amber.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHeadingToCustomer ? LucideIcons.truck : LucideIcons.store,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHeadingToCustomer
                              ? (isArabic
                                  ? 'في الطريق لتسليم الطلب إلى العميل'
                                  : 'On the way to customer delivery')
                              : (isArabic
                                  ? 'في الطريق لاستلام الطلب من المتجر'
                                  : 'Heading to store for order pickup'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isHeadingToCustomer
                                ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900)
                                : (isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHeadingToCustomer
                              ? '${isArabic ? "العميل: " : "Customer: "}$customerName${customerPhone.isNotEmpty ? " ($customerPhone)" : ""} • $deliveryAddress'
                              : '${isArabic ? "المتجر: " : "Store: "}$vendorName • $pickupAddress',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isHeadingToCustomer
                                ? (isDark ? Colors.blue.shade300 : Colors.blue.shade800)
                                : (isDark ? Colors.amber.shade300 : Colors.amber.shade800),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (distanceToNextKm != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.milestone,
                            size: 13,
                            color: isHeadingToCustomer ? Colors.blue : Colors.amber.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isArabic ? "المسافة: " : "Distance: "}${isArabic ? _formatDistance(distanceToNextKm) : _formatDistanceEn(distanceToNextKm)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isHeadingToCustomer
                                  ? (isDark ? Colors.blue.shade200 : Colors.blue.shade900)
                                  : (isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (etaMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.clock, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${isArabic ? "الوقت التقديري: ~" : "ETA: ~"}$etaMinutes ${isArabic ? "دقيقة" : "min"}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Order Metadata & Financial Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '#$orderNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _translateStatus(status, isArabic),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${grandTotal.toStringAsFixed(2)} ${isArabic ? "ج.م" : "EGP"}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${isArabic ? "النوع: " : "Type: "}$orderType • $paymentMethod',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onViewOrderDetails != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onViewOrderDetails!(order),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isArabic ? 'عرض كل التفاصيل' : 'View full details',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(LucideIcons.arrowUpRight, size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveOrderBanner({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle, size: 18, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'لا يوجد طلب نشط حالياً' : 'No active order currently',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  driver.status == 'ONLINE'
                      ? (isArabic
                          ? 'السائق متصل وجاهز لتلقي الطلبات'
                          : 'Driver is online and ready for orders')
                      : (isArabic
                          ? 'السائق غير نشط حالياً (${_translateDriverStatus(driver.status, isArabic)})'
                          : 'Driver is inactive (${_translateDriverStatus(driver.status, isArabic)})'),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onAssignOrder != null && driver.status != 'SUSPENDED') ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAssignOrder,
              icon: const Icon(LucideIcons.truck, size: 14),
              label: Text(
                isArabic ? 'تعيين طلب' : 'Assign',
                style: const TextStyle(fontSize: 12),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow({
    required BuildContext context,
    required bool isArabic,
  }) {
    final theme = Theme.of(context);
    final customer = activeOrder?['customer'] is Map ? activeOrder!['customer'] as Map : null;
    final customerUser = customer?['user'] is Map ? customer!['user'] as Map : null;
    final customerPhone = customerUser?['phone']?.toString();
    final orderStatus = (activeOrder?['status']?.toString() ?? '').toUpperCase();
    final isHeadingToCustomer = (orderStatus == 'PICKED_UP');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 1. Call Driver
          if (driver.phone != null && driver.phone!.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () => onCallPhone(driver.phone!),
              icon: const Icon(LucideIcons.phone, size: 14),
              label: Text(
                isArabic ? 'اتصال بالسائق' : 'Call Driver',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 2. Call Customer
          if (customerPhone != null && customerPhone.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () => onCallPhone(customerPhone),
              icon: const Icon(LucideIcons.phoneCall, size: 14, color: AppColors.success),
              label: Text(
                isArabic ? 'اتصال بالعميل' : 'Call Customer',
                style: const TextStyle(fontSize: 12, color: AppColors.success),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 3. Driver location in Google Maps (exact pin)
          ElevatedButton.icon(
            onPressed: () => onOpenMaps(
              location.latitude,
              location.longitude,
              label: driver.name.isNotEmpty ? driver.name : (isArabic ? 'السائق' : 'Driver'),
            ),
            icon: const Icon(LucideIcons.mapPin, size: 14),
            label: Text(
              isArabic ? 'فتح موقع السائق' : 'Driver in Maps',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Store / Pickup in Google Maps (if order exists & heading to vendor)
          if (pickupLocation != null && !isHeadingToCustomer) ...[
            OutlinedButton.icon(
              onPressed: () => onOpenMaps(
                pickupLocation!.latitude,
                pickupLocation!.longitude,
                label: isArabic ? 'المتجر' : 'Store',
              ),
              icon: const Icon(LucideIcons.store, size: 14, color: Colors.amber),
              label: Text(
                isArabic ? 'موقع المتجر' : 'Store in Maps',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 5. Customer / Delivery in Google Maps (if order exists)
          if (deliveryLocation != null) ...[
            OutlinedButton.icon(
              onPressed: () => onOpenMaps(
                deliveryLocation!.latitude,
                deliveryLocation!.longitude,
                label: isArabic ? 'العميل' : 'Customer',
              ),
              icon: const Icon(LucideIcons.navigation, size: 14),
              label: Text(
                isArabic ? 'موقع العميل' : 'Customer in Maps',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 5. Center Camera on Route
          if (onCenterOnDelivery != null && (pickupLocation != null || deliveryLocation != null)) ...[
            OutlinedButton.icon(
              onPressed: onCenterOnDelivery,
              icon: const Icon(LucideIcons.expand, size: 14),
              label: Text(
                isArabic ? 'عرض كامل المسار' : 'Fit Route',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String? vehicleType) {
    switch ((vehicleType ?? '').toUpperCase().trim()) {
      case 'CAR':
        return LucideIcons.car;
      case 'BICYCLE':
        return LucideIcons.bike;
      case 'VAN':
      case 'TRUCK':
        return LucideIcons.truck;
      case 'MOTOR_TRICYCLE':
      case 'MOTORCYCLE':
      default:
        return LucideIcons.bike;
    }
  }
}
