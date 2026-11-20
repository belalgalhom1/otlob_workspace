import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';

class ActiveOrderDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> order;

  const ActiveOrderDetailsDialog({super.key, required this.order});

  Future<void> _callPhone(String? phone) async {
    await ExternalActionLauncher.callPhone(phone);
  }

  Future<void> _openInMaps(double lat, double lng, {String? label}) async {
    await MapNavigationLauncher.launchLocation(
      latitude: lat,
      longitude: lng,
      label: label,
    );
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
    final readableAmber =
        isDark ? Colors.amber.shade300 : const Color(0xFFB45309);
    final readablePrimaryText =
        isDark ? AppColors.primary : const Color(0xFFB45309);
    final orderType = order['type']?.toString() ?? 'STANDARD';

    // Customer
    final customer = order['customer'] is Map ? order['customer'] as Map : {};
    final customerUser = customer['user'] is Map ? customer['user'] as Map : {};
    final customerName = customerUser['name']?.toString() ?? (isArabic ? 'عميل' : 'Customer');
    final customerPhone = customerUser['phone']?.toString() ?? '';
    final customerAvatar =
        (customerUser['avatar'] ?? customer['avatar'])?.toString();
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
    final vendorLogo = (vendor['logo'] ?? vendor['logoUrl'])?.toString();
    final pickupAddress = order['pickupAddress']?.toString() ??
        vendorBranch['address']?.toString() ??
        vendor['address']?.toString() ??
        '';

    final fulfillments = (order['vendorFulfillments'] as List<dynamic>?) ?? [];
    final bool isMultiVendor = order['isMultiVendor'] == true ||
        fulfillments.length > 1 ||
        (order['vendor'] == null && fulfillments.isNotEmpty);

    // Items
    final rawItems = order['items'];
    final items = (rawItems is List) ? rawItems : [];

    // Financials
    double numVal(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    final subtotal = numVal(order['subtotal']);
    final deliveryFee = numVal(order['deliveryFee']);
    final grandTotal = order['grandTotal'] != null
        ? numVal(order['grandTotal'])
        : (order['total'] != null ? numVal(order['total']) : (subtotal + deliveryFee));
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

    return AppDialog(
      maxWidth: 640,
      maxHeight: 760,
      header: AppDialogHeader(
        icon: LucideIcons.packageCheck,
        title: '#$orderNumber',
        subtitleWidget: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppBadgePill(
              text: _translateStatus(status, isArabic),
              accentColor: statusColor,
            ),
            Text(
              '${isArabic ? "نوع الطلب: " : "Type: "}$orderType',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stage summary card
          AppDialogSectionCard(
            padding: const EdgeInsets.all(12),
            child: Row(
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
          ),
          const SizedBox(height: 16),

          // Pickup & Delivery route box
          _buildRouteCard(
            context: context,
            isDark: isDark,
            isArabic: isArabic,
            vendorName: vendorName,
            vendorLogo: vendorLogo,
            branchName: branchName,
            pickupAddress: pickupAddress,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            customerName: customerName,
            customerAvatar: customerAvatar,
            customerPhone: customerPhone,
            deliveryAddress: deliveryAddress,
            deliveryLat: deliveryLat,
            deliveryLng: deliveryLng,
            fulfillments: fulfillments,
            isMultiVendor: isMultiVendor,
          ),
          const SizedBox(height: 16),

          // Items list (Multi-Vendor breakdown or Single Store)
          if (isMultiVendor && fulfillments.isNotEmpty) ...[
            Text(
              isArabic
                  ? 'أصناف الطلب حسب الجهات (${fulfillments.length})'
                  : 'Order Portions (${fulfillments.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < fulfillments.length; i++) ...[
              () {
                final f = fulfillments[i] is Map ? fulfillments[i] as Map : {};
                final fId = f['id']?.toString() ?? '';
                final fVendor = f['vendor'] is Map ? f['vendor'] as Map : {};
                final fVendorLogo =
                    (fVendor['logo'] ?? fVendor['logoUrl'])?.toString();
                final fBranch = f['vendorBranch'] is Map ? f['vendorBranch'] as Map : {};
                final sName = isArabic
                    ? (fVendor['storeNameAr'] ?? fVendor['storeName'] ?? 'متجر')
                    : (fVendor['storeName'] ?? fVendor['storeNameAr'] ?? 'Store');
                final bName = isArabic ? (fBranch['nameAr'] ?? fBranch['name'] ?? '') : (fBranch['name'] ?? fBranch['nameAr'] ?? '');
                final fStatus = f['status']?.toString() ?? 'PENDING';
                final rawFItems = f['items'];
                final portionItems = (rawFItems is List && rawFItems.isNotEmpty)
                    ? rawFItems
                    : items.where((it) => it is Map && it['fulfillmentId'] == fId).toList();

                return AppDialogSectionCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            AppNetworkAvatar(
                              imageUrl: ImageUtils.formatImageUrl(fVendorLogo),
                              size: 26,
                              borderRadius: 7,
                              fallbackIcon: LucideIcons.store,
                              fallbackIconSize: 13,
                              backgroundColor: readableAmber.withValues(alpha: 0.15),
                              foregroundColor: readableAmber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bName.toString().isNotEmpty ? '$sName ($bName)' : sName.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildMiniPortionStatus(fStatus, isArabic),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppDialogStyles.borderColor(context)),
                      if (portionItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            isArabic ? 'لا توجد عناصر مسجلة لهذا المتجر' : 'No items listed for this store',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: portionItems.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: AppDialogStyles.borderColor(context)),
                          itemBuilder: (ctx, idx) {
                            final it = portionItems[idx];
                            final name = it['productName']?.toString() ?? it['name']?.toString() ?? it['product']?['name']?.toString() ?? (isArabic ? 'عنصر' : 'Item');
                            final variant = it['variantName']?.toString();
                            final unit = it['selectedUnit']?.toString();
                            final qty = it['quantity']?.toString() ?? '1';
                            final price = (it['unitPrice'] as num?)?.toDouble() ?? (it['price'] as num?)?.toDouble() ?? 0.0;
                            final totalPrice = (it['totalPrice'] as num?)?.toDouble() ?? (price * (int.tryParse(qty) ?? 1));

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      qty,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: readablePrimaryText),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if ((variant != null && variant.isNotEmpty) || (unit != null && unit.isNotEmpty))
                                          Text(
                                            [if (variant != null && variant.isNotEmpty) variant, if (unit != null && unit.isNotEmpty) unit].join(' • '),
                                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${totalPrice.toStringAsFixed(2)} ${isArabic ? "ج.م" : "EGP"}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              }(),
            ],
            const SizedBox(height: 16),
          ] else if (items.isNotEmpty) ...[
            Text(
              isArabic ? 'عناصر الطلب' : 'Order Items',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            AppDialogSectionCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppDialogStyles.borderColor(context),
                ),
                itemBuilder: (ctx, idx) {
                  final it = items[idx];
                  final name = it['productName']?.toString() ??
                      it['name']?.toString() ??
                      it['product']?['name']?.toString() ??
                      (isArabic ? 'عنصر' : 'Item');
                  final variant = it['variantName']?.toString();
                  final unit = it['selectedUnit']?.toString();
                  final qty = it['quantity']?.toString() ?? '1';
                  final price = (it['unitPrice'] as num?)?.toDouble() ??
                      (it['price'] as num?)?.toDouble() ?? 0.0;
                  final totalPrice = (it['totalPrice'] as num?)?.toDouble() ?? (price * (int.tryParse(qty) ?? 1));

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            qty,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: readablePrimaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((variant != null && variant.isNotEmpty) || (unit != null && unit.isNotEmpty))
                                Text(
                                  [if (variant != null && variant.isNotEmpty) variant, if (unit != null && unit.isNotEmpty) unit].join(' • '),
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${totalPrice.toStringAsFixed(2)} ${isArabic ? "ج.م" : "EGP"}',
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
            AppDialogSectionCard(
              padding: const EdgeInsets.all(12),
              backgroundColor: readableAmber.withValues(alpha: 0.08),
              borderColor: readableAmber.withValues(alpha: 0.25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.messageSquare, size: 16, color: readableAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'ملاحظات العميل:' : 'Customer Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: readableAmber,
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
      footer: AppDialogFooter(
        cancelLabel: isArabic ? 'إغلاق' : 'Close',
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildMiniPortionStatus(String status, bool isArabic) {
    Color fg;
    String label;
    switch (status) {
      case 'PENDING':
        fg = AppColors.warning;
        label = isArabic ? 'بانتظار القرار' : 'Pending';
        break;
      case 'ACCEPTED':
        fg = AppColors.info;
        label = isArabic ? 'مقبول' : 'Accepted';
        break;
      case 'PREPARING':
        fg = Colors.purple;
        label = isArabic ? 'قيد التحضير' : 'Preparing';
        break;
      case 'READY_FOR_PICKUP':
        fg = AppColors.success;
        label = isArabic ? 'جاهز للاستلام' : 'Ready';
        break;
      case 'PICKED_UP':
        fg = Colors.teal;
        label = isArabic ? 'تم الاستلام' : 'Picked Up';
        break;
      case 'DELIVERED':
        fg = AppColors.success;
        label = isArabic ? 'تم التوصيل' : 'Delivered';
        break;
      case 'REJECTED':
        fg = AppColors.error;
        label = isArabic ? 'مرفوض' : 'Rejected';
        break;
      default:
        fg = Colors.grey;
        label = status;
    }
    return AppBadgePill(text: label, accentColor: fg);
  }

  Widget _buildRouteCard({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required String vendorName,
    String? vendorLogo,
    required String branchName,
    required String pickupAddress,
    double? pickupLat,
    double? pickupLng,
    required String customerName,
    String? customerAvatar,
    required String customerPhone,
    required String deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    List<dynamic> fulfillments = const [],
    bool isMultiVendor = false,
  }) {
    final theme = Theme.of(context);
    final readableAmber =
        isDark ? Colors.amber.shade300 : const Color(0xFFB45309);
    final readablePrimaryText =
        isDark ? AppColors.primary : const Color(0xFFB45309);

    return AppDialogSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Store / Pickup
          if (isMultiVendor && fulfillments.length > 1) ...[
            for (var i = 0; i < fulfillments.length; i++) ...[
              () {
                final f = fulfillments[i] is Map ? fulfillments[i] as Map : {};
                final fVendor = f['vendor'] is Map ? f['vendor'] as Map : {};
                final fVendorLogo =
                    (fVendor['logo'] ?? fVendor['logoUrl'])?.toString();
                final fBranch = f['vendorBranch'] is Map ? f['vendorBranch'] as Map : {};
                final sName = isArabic
                    ? (fVendor['storeNameAr'] ?? fVendor['storeName'] ?? 'متجر')
                    : (fVendor['storeName'] ?? fVendor['storeNameAr'] ?? 'Store');
                final bName = isArabic ? (fBranch['nameAr'] ?? fBranch['name'] ?? '') : (fBranch['name'] ?? fBranch['nameAr'] ?? '');
                final fAddr = fBranch['address']?.toString() ?? '';
                final fStatus = f['status']?.toString() ?? 'PENDING';
                final isContracted = fBranch['isContracted'] ?? fVendor['isContracted'] ?? false;

                return Padding(
                  padding: EdgeInsets.only(bottom: i < fulfillments.length - 1 ? 10 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppNetworkAvatar(
                        imageUrl: ImageUtils.formatImageUrl(fVendorLogo),
                        size: 24,
                        borderRadius: 6,
                        fallbackIcon: LucideIcons.store,
                        fallbackIconSize: 12,
                        backgroundColor: readableAmber.withValues(alpha: 0.15),
                        foregroundColor: readableAmber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'محطة استلام ${i + 1}' : 'Pickup Stop ${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    bName.toString().isNotEmpty ? '$sName ($bName)' : sName.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AppBadgePill(
                                  text: isContracted
                                      ? (isArabic ? 'شريك' : 'Contracted')
                                      : (isArabic ? 'دفع بالاستلام' : 'Cash'),
                                  accentColor:
                                      isContracted ? readablePrimaryText : AppColors.warning,
                                ),
                              ],
                            ),
                            if (fAddr.isNotEmpty)
                              Text(
                                fAddr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildMiniPortionStatus(fStatus, isArabic),
                    ],
                  ),
                );
              }(),
            ],
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkAvatar(
                  imageUrl: ImageUtils.formatImageUrl(vendorLogo),
                  size: 32,
                  borderRadius: 8,
                  fallbackIcon: LucideIcons.store,
                  fallbackIconSize: 15,
                  backgroundColor: readableAmber.withValues(alpha: 0.15),
                  foregroundColor: readableAmber,
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
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        vendorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (pickupAddress.isNotEmpty)
                        Text(
                          pickupAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (pickupLat != null && pickupLng != null)
                  IconButton(
                    onPressed: () => _openInMaps(pickupLat, pickupLng, label: vendorName),
                    icon: Icon(LucideIcons.store, size: 16, color: readableAmber),
                    tooltip: isArabic ? 'فتح موقع المتجر في خرائط Google' : 'Open Store in Google Maps',
                  ),
              ],
            ),
          ],
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
              AppNetworkAvatar(
                imageUrl: ImageUtils.formatImageUrl(customerAvatar),
                size: 32,
                fallbackIcon: LucideIcons.user,
                fallbackIconSize: 15,
                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                foregroundColor: AppColors.success,
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
                        color: theme.colorScheme.onSurfaceVariant,
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
                                  Icon(LucideIcons.phone, size: 12, color: readablePrimaryText),
                                  const SizedBox(width: 3),
                                  Text(
                                    isArabic ? 'اتصال' : 'Call',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: readablePrimaryText,
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
                        color: theme.colorScheme.onSurfaceVariant,
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
    final readablePrimaryText =
        isDark ? AppColors.primary : const Color(0xFFB45309);

    return AppDialogSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'المجموع الفرعي:' : 'Subtotal:',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
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
                  color: theme.colorScheme.onSurfaceVariant,
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: readablePrimaryText,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppBadgePill(
                text: paymentStatus,
                accentColor: paymentStatus.toUpperCase() == 'PAID'
                    ? AppColors.success
                    : AppColors.warning,
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
