import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ActiveOrderDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> order;

  const ActiveOrderDetailsDialog({super.key, required this.order});

  Future<void> _callPhone(String? phone) async {
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

    final encodedLabel = Uri.encodeComponent(label ?? 'Location');

    // 1. Android geo URI with exact pin coordinates and label
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedLabel)');

    // 2. Exact dropped-pin Google Maps universal URL
    final googleMapsUri = Uri.parse('https://www.google.com/maps?q=$lat,$lng&ll=$lat,$lng&z=17');

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

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = DateTime.tryParse(dateVal.toString())?.toLocal();
      if (dt != null) {
        return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
      }
    } catch (_) {}
    return dateVal.toString();
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
        return isArabic ? 'تم الاستلام الجزئي' : 'Partially Picked Up';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final orderNumber = order['orderNumber']?.toString() ?? order['id']?.toString() ?? '';
    final status = (order['status']?.toString() ?? 'PENDING').toUpperCase();
    final statusColor = _getStatusColor(status);
    final orderType = order['type']?.toString() ?? 'STANDARD';

    // Customer
    final customer = order['customer'] is Map ? order['customer'] as Map : {};
    final customerUser = customer['user'] is Map ? customer['user'] as Map : {};
    final customerName = customerUser['name']?.toString() ?? (isArabic ? 'عميل' : 'Customer');
    final customerPhone = customerUser['phone']?.toString() ?? '';
    final deliveryAddress = order['deliveryAddress']?.toString() ?? (isArabic ? 'غير محدد' : 'Not specified');

    // Vendor / Pickup
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

    // Items
    final rawItems = order['items'];
    final items = (rawItems is List) ? rawItems : [];

    // Financials
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = (order['grandTotal'] as num?)?.toDouble() ??
        (order['total'] as num?)?.toDouble() ??
        (subtotal + deliveryFee);
    final paymentMethod = order['paymentMethod']?.toString() ?? 'CASH';
    final paymentStatus = order['paymentStatus']?.toString() ?? 'PENDING';
    final specialRequest = order['specialRequest']?.toString();

    // Coordinates
    final deliveryLoc = order['deliveryLocation'];
    double? deliveryLat;
    double? deliveryLng;
    if (deliveryLoc is List && deliveryLoc.length >= 2) {
      deliveryLng = (deliveryLoc[0] as num?)?.toDouble();
      deliveryLat = (deliveryLoc[1] as num?)?.toDouble();
    }

    final pickupLoc = order['pickupLocation'] ?? vendorBranch['location'] ?? vendor['location'];
    double? pickupLat;
    double? pickupLng;
    if (pickupLoc is List && pickupLoc.length >= 2) {
      pickupLng = (pickupLoc[0] as num?)?.toDouble();
      pickupLat = (pickupLoc[1] as num?)?.toDouble();
    }

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.packageCheck, size: 20, color: AppColors.primary),
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
                                '#$orderNumber',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _translateStatus(status, isArabic),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isArabic ? "نوع الطلب: " : "Type: "}$orderType',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 20),
                    tooltip: isArabic ? 'إغلاق' : 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stage summary card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                status == 'PICKED_UP'
                                    ? LucideIcons.truck
                                    : LucideIcons.store,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  status == 'PICKED_UP'
                                      ? (isArabic
                                          ? 'السائق في الطريق إلى العميل'
                                          : 'Driver is on the way to customer')
                                      : (isArabic
                                          ? 'السائق في طريقه للمتجر للاستلام'
                                          : 'Driver is heading to store for pickup'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pickup & Delivery route box
                    _buildRouteCard(
                      context: context,
                      isDark: isDark,
                      isArabic: isArabic,
                      vendorName: vendorName,
                      branchName: branchName,
                      pickupAddress: pickupAddress,
                      pickupLat: pickupLat,
                      pickupLng: pickupLng,
                      customerName: customerName,
                      customerPhone: customerPhone,
                      deliveryAddress: deliveryAddress,
                      deliveryLat: deliveryLat,
                      deliveryLng: deliveryLng,
                    ),
                    const SizedBox(height: 16),

                    // Items list (if available)
                    if (items.isNotEmpty) ...[
                      Text(
                        isArabic ? 'عناصر الطلب' : 'Order Items',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                          ),
                          itemBuilder: (ctx, idx) {
                            final it = items[idx];
                            final name = it['name']?.toString() ??
                                it['product']?['name']?.toString() ??
                                (isArabic ? 'عنصر' : 'Item');
                            final qty = it['quantity']?.toString() ?? '1';
                            final price = (it['price'] as num?)?.toDouble() ?? 0.0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      qty,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${price.toStringAsFixed(2)} ${isArabic ? "ج.م" : "EGP"}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Financial summary
                    _buildFinancialCard(
                      context: context,
                      isDark: isDark,
                      isArabic: isArabic,
                      subtotal: subtotal,
                      deliveryFee: deliveryFee,
                      grandTotal: grandTotal,
                      paymentMethod: paymentMethod,
                      paymentStatus: paymentStatus,
                    ),

                    if (specialRequest != null && specialRequest.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.messageSquare, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'ملاحظات العميل:' : 'Customer Notes:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    specialRequest,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Timestamps
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (order['createdAt'] != null)
                          _buildTimestampChip(
                            icon: LucideIcons.clock,
                            label: '${isArabic ? "تاريخ الطلب: " : "Created: "}${_formatDate(order['createdAt'])}',
                            theme: theme,
                          ),
                        if (order['pickedUpAt'] != null)
                          _buildTimestampChip(
                            icon: LucideIcons.checkCheck,
                            label: '${isArabic ? "الاستلام: " : "Picked up: "}${_formatDate(order['pickedUpAt'])}',
                            theme: theme,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isArabic ? 'إغلاق' : 'Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required String vendorName,
    required String branchName,
    required String pickupAddress,
    double? pickupLat,
    double? pickupLng,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Store / Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.store, size: 14, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'موقع الاستلام (المتجر)' : 'Pickup Location (Store)',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      branchName.isNotEmpty ? '$vendorName ($branchName)' : vendorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (pickupAddress.isNotEmpty)
                      Text(
                        pickupAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (pickupLat != null && pickupLng != null)
                IconButton(
                  onPressed: () => _openInMaps(pickupLat, pickupLng, label: vendorName),
                  icon: const Icon(LucideIcons.store, size: 16, color: Colors.amber),
                  tooltip: isArabic ? 'فتح موقع المتجر في خرائط Google' : 'Open Store in Google Maps',
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          // Customer / Delivery
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.mapPin, size: 14, color: AppColors.success),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'موقع التسليم (العميل)' : 'Delivery Location (Customer)',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customerPhone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _callPhone(customerPhone),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.phone, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  Text(
                                    isArabic ? 'اتصال' : 'Call',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      deliveryAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (deliveryLat != null && deliveryLng != null)
                IconButton(
                  onPressed: () => _openInMaps(deliveryLat, deliveryLng, label: customerName),
                  icon: const Icon(LucideIcons.navigation, size: 16),
                  tooltip: isArabic ? 'فتح في خرائط Google' : 'Open in Google Maps',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required double subtotal,
    required double deliveryFee,
    required double grandTotal,
    required String paymentMethod,
    required String paymentStatus,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'المجموع الفرعي:' : 'Subtotal:',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '${subtotal.toStringAsFixed(2)} ${isArabic ? "ج.م" : "EGP"}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'رسوم التوصيل:' : 'Delivery Fee:',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '${deliveryFee.toStringAsFixed(2)} ${isArabic ? "ج.م" : "EGP"}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'المبلغ الإجمالي:' : 'Grand Total:',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${grandTotal.toStringAsFixed(2)} ${isArabic ? "ج.م" : "EGP"}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isArabic ? "طريقة الدفع: " : "Payment: "}$paymentMethod',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (paymentStatus.toUpperCase() == 'PAID'
                          ? AppColors.success
                          : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paymentStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: paymentStatus.toUpperCase() == 'PAID'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
