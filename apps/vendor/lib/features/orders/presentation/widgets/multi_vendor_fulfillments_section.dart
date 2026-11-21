import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';

/// Displays per-store fulfillment portions inside an expanded vendor/admin
/// order card, keeping headers, badges, items, and subtotals responsive on
/// narrow mobile viewports and at elevated text scaling.
class MultiVendorFulfillmentsSection extends StatelessWidget {
  final Map<dynamic, dynamic> order;
  final List<dynamic> fulfillments;
  final List<dynamic> allItems;
  final bool isArabic;
  final String userRole;
  final bool canManageVendors;
  final bool canManageOrders;
  final Widget Function(String status, bool isArabic) statusBadgeBuilder;
  final void Function(String phone) onCallStore;
  final void Function(String photoUrl) onViewPhoto;
  final void Function(String fulfillmentId) onAcceptFulfillment;
  final void Function(String fulfillmentId, String storeName)
      onRejectFulfillment;
  final void Function(String fulfillmentId) onStartPreparing;
  final void Function(String fulfillmentId) onMarkReady;

  const MultiVendorFulfillmentsSection({
    super.key,
    required this.order,
    required this.fulfillments,
    required this.allItems,
    required this.isArabic,
    required this.userRole,
    required this.canManageVendors,
    required this.canManageOrders,
    required this.statusBadgeBuilder,
    required this.onCallStore,
    required this.onViewPhoto,
    required this.onAcceptFulfillment,
    required this.onRejectFulfillment,
    required this.onStartPreparing,
    required this.onMarkReady,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 430;
    final canManagePortions = userRole == 'SUPER_ADMIN' ||
        userRole == 'ADMIN' ||
        userRole == 'VENDOR_MEMBER' ||
        canManageVendors ||
        canManageOrders;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme),
          SizedBox(height: isCompact ? 10 : 14),
          for (var i = 0; i < fulfillments.length; i++)
            _buildFulfillmentCard(
              context: context,
              theme: theme,
              index: i,
              rawFulfillment: fulfillments[i],
              isCompact: isCompact,
              canManagePortions: canManagePortions,
              isLast: i == fulfillments.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.store,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fulfillments.length == 1
                    ? (isArabic
                          ? 'تفاصيل المتجر والفرع والأصناف'
                          : 'Store, Branch & Items Details')
                    : (isArabic
                          ? 'محطات وأصناف المتاجر (${fulfillments.length} متاجر)'
                          : 'Store Stops & Items (${fulfillments.length} Stores)'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                isArabic ? 'متعدد المتاجر' : 'Multi-Vendor',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isArabic
              ? 'تفاصيل كل متجر والفرع والأصناف المستقلة وحالة التحضير'
              : 'Each store has a distinct branch stop, status, items, and settlement',
          style: TextStyle(
            fontSize: 11.5,
            height: 1.35,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildFulfillmentCard({
    required BuildContext context,
    required ThemeData theme,
    required int index,
    required dynamic rawFulfillment,
    required bool isCompact,
    required bool canManagePortions,
    required bool isLast,
  }) {
    final f = rawFulfillment is Map ? rawFulfillment : const {};
    final fId = f['id']?.toString() ?? '';
    final fStatus = f['status']?.toString() ?? 'PENDING';
    final fVendor = f['vendor'] is Map ? f['vendor'] as Map : const {};
    final fBranch =
        f['vendorBranch'] is Map ? f['vendorBranch'] as Map : const {};

    final storeName = (isArabic
            ? (fVendor['storeNameAr'] ??
                  fVendor['storeName'] ??
                  fVendor['name'] ??
                  'متجر')
            : (fVendor['storeName'] ??
                  fVendor['storeNameAr'] ??
                  fVendor['name'] ??
                  'Store'))
        .toString();

    final branchName = (isArabic
            ? (fBranch['nameAr'] ?? fBranch['name'] ?? '')
            : (fBranch['name'] ?? fBranch['nameAr'] ?? ''))
        .toString();

    final branchAddress = fBranch['address']?.toString() ?? '';
    final branchSummary = branchName.isNotEmpty && branchAddress.isNotEmpty
        ? '$branchName - $branchAddress'
        : (branchName.isNotEmpty ? branchName : branchAddress);

    final storePhone =
        fBranch['phone']?.toString() ?? fVendor['phone']?.toString() ?? '';
    final isContracted =
        (fBranch['isContracted'] ?? fVendor['isContracted'] ?? false) == true;
    final storeLogo =
        (fVendor['logo'] ?? fVendor['logoUrl'])?.toString().trim() ?? '';

    final fSubtotal =
        double.tryParse(f['subtotal']?.toString() ?? '0') ?? 0.0;
    final commRate =
        double.tryParse(f['commissionRate']?.toString() ?? '10') ?? 10.0;
    final commAmount =
        isContracted ? (fSubtotal * commRate / 100).roundToDouble() : 0.0;
    final netPayout = isContracted ? (fSubtotal - commAmount) : fSubtotal;

    final rawFItems = f['items'];
    List<dynamic> portionItems = (rawFItems is List && rawFItems.isNotEmpty)
        ? rawFItems
        : allItems
              .where((it) => it is Map && it['fulfillmentId'] == fId)
              .toList();

    if (portionItems.isEmpty && fulfillments.length == 1) {
      portionItems = allItems;
    }

    final isRejected = fStatus == 'REJECTED' || fStatus == 'CANCELLED';
    final rejectionReason = isArabic
        ? (f['rejectionReasonAr'] ?? f['rejectionReason'])
        : (f['rejectionReason'] ?? f['rejectionReasonAr']);
    final rejectionCode = f['rejectionCode']?.toString();
    final pickupPhoto = f['pickupImageUrl']?.toString();
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: isRejected
            ? AppColors.error.withValues(alpha: 0.04)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRejected
              ? AppColors.error.withValues(alpha: 0.25)
              : theme.colorScheme.onSurface.withValues(alpha: 0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top meta tier: Stop index + contract tag on start; status badge + call button on end.
          // Wrap keeps status/contract badges on clean horizontal lines at narrow widths.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isContracted
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isContracted
                            ? (isArabic ? 'شريك معتمد' : 'Contracted')
                            : (isArabic ? 'دفع بالاستلام' : 'Cash at pickup'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isContracted
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                      ),
                    ),
                    statusBadgeBuilder(fStatus, isArabic),
                  ],
                ),
              ),
              if (storePhone.isNotEmpty) ...[
                const SizedBox(width: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onCallStore(storePhone),
                    child: Tooltip(
                      message: isArabic ? 'اتصال بالمتجر' : 'Call store',
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.phoneCall,
                          color: AppColors.primary,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Second tier: full-width store identity (logo, store name, branch/address)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkAvatar(
                imageUrl: ImageUtils.formatImageUrl(storeLogo),
                size: 40,
                borderRadius: 10,
                fallbackIcon: LucideIcons.store,
                fallbackIconSize: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                foregroundColor: AppColors.primary,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.25,
                        decoration: isRejected
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (branchSummary.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.mapPin,
                              size: 12.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              branchSummary,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Stage timestamps / progress pills
          if (f['preparingAt'] != null ||
              f['readyAt'] != null ||
              f['pickedUpAt'] != null ||
              (pickupPhoto != null && pickupPhoto.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (f['preparingAt'] != null)
                  _buildTimestampChip(
                    label:
                        '${isArabic ? "بدء التحضير: " : "Preparing: "}${DateFormat("hh:mm a").format(DateTime.parse(f["preparingAt"].toString()).toLocal())}',
                    color: Colors.purple,
                  ),
                if (f['readyAt'] != null)
                  _buildTimestampChip(
                    label:
                        '${isArabic ? "جاهز للاستلام: " : "Ready: "}${DateFormat("hh:mm a").format(DateTime.parse(f["readyAt"].toString()).toLocal())}',
                    color: AppColors.success,
                  ),
                if (f['pickedUpAt'] != null)
                  _buildTimestampChip(
                    label:
                        '${isArabic ? "استلم السائق: " : "Picked up: "}${DateFormat("hh:mm a").format(DateTime.parse(f["pickedUpAt"].toString()).toLocal())}',
                    color: Colors.teal,
                  ),
                if (pickupPhoto != null && pickupPhoto.isNotEmpty)
                  InkWell(
                    onTap: () => onViewPhoto(pickupPhoto),
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.camera,
                            size: 11,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isArabic
                                ? 'صورة استلام السائق'
                                : 'Driver pickup photo',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Rejection alert
          if (isRejected &&
              rejectionReason != null &&
              rejectionReason.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      LucideIcons.alertTriangle,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${isArabic ? "سبب الرفض: " : "Rejection Reason: "}$rejectionReason${rejectionCode != null ? " ($rejectionCode)" : ""}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // Items in this store portion
          if (portionItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                isArabic
                    ? 'لا توجد أصناف مسجلة لهذا المتجر'
                    : 'No items listed for this store',
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            for (final item in portionItems)
              _buildPortionItemRow(
                theme: theme,
                item: item,
                isDark: isDark,
              ),

          // Portion footer: Subtotal & net payout
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinancialRow(
                  label: isArabic ? 'إجمالي أصناف المتجر' : 'Store Subtotal',
                  value: '${fSubtotal.toStringAsFixed(2)} ${isArabic ? 'ج.م' : 'EGP'}',
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                  valueStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (isContracted) ...[
                  const SizedBox(height: 4),
                  _buildFinancialRow(
                    label: isArabic
                        ? 'الصافي (${(100 - commRate).toInt()}٪)'
                        : 'Net (${(100 - commRate).toInt()}%)',
                    value: '${netPayout.toStringAsFixed(2)} ${isArabic ? 'ج.م' : 'EGP'}',
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success.withValues(alpha: 0.9),
                    ),
                    valueStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quick portion actions for Super Admin / Admin / multi-branch Vendor
          if (canManagePortions &&
              (userRole != 'VENDOR_MEMBER' || fulfillments.length > 1) &&
              !isRejected &&
              fStatus != 'DELIVERED') ...[
            const SizedBox(height: 10),
            if (fStatus == 'PENDING')
              _buildPendingDecisionActions(
                fId: fId,
                storeName: storeName,
              )
            else if ((fStatus == 'ACCEPTED' ||
                    fStatus == 'LOOKING_FOR_DRIVER') &&
                !(((order['status'] == 'PENDING_PAYMENT' ||
                        order['paymentMethod'] == 'MOBILE_WALLET' ||
                        (double.tryParse(
                                  order['upfrontAmount']?.toString() ?? '0',
                                ) ??
                                0.0) >
                            0) &&
                    order['paymentStatus'] != 'COMPLETED')))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onStartPreparing(fId),
                  icon: const Icon(LucideIcons.chefHat, size: 15),
                  label: Text(
                    isArabic
                        ? 'بدء تحضير أصناف هذا المتجر'
                        : 'Start Preparing This Store Items',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else if (fStatus == 'PREPARING')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onMarkReady(fId),
                  icon: const Icon(LucideIcons.packageCheck, size: 15),
                  label: Text(
                    isArabic
                        ? 'تأكيد جاهزية أصناف المتجر للاستلام'
                        : 'Mark Store Ready for Pickup',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimestampChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPortionItemRow({
    required ThemeData theme,
    required dynamic item,
    required bool isDark,
  }) {
    final pName = item['productName']?.toString() ??
        item['name']?.toString() ??
        (isArabic ? 'صنف' : 'Item');
    final variant = item['variantName']?.toString();
    final unit = item['selectedUnit']?.toString();
    final pQty = item['quantity'] ?? 1;
    final pPrice = double.tryParse(
          item['unitPrice']?.toString() ?? item['price']?.toString() ?? '0',
        ) ??
        0.0;
    final pTotalPrice = double.tryParse(item['totalPrice']?.toString() ?? '0') ??
        (pPrice * (pQty as num));
    final product = item['product'] is Map ? item['product'] as Map : null;
    final rawImg = [
      product?['imageUrl'],
      product?['image'],
      item['imageUrl'],
      item['image'],
    ]
        .map((e) => e?.toString().trim() ?? '')
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final pNotes = item['specialRequest']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppNetworkAvatar(
            imageUrl: ImageUtils.formatImageUrl(rawImg),
            size: 38,
            borderRadius: 8,
            fallbackIcon: LucideIcons.package,
            fallbackIconSize: 16,
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            foregroundColor: Colors.grey,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${pQty}x',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((variant != null && variant.isNotEmpty) ||
                    (unit != null && unit.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      [
                        if (variant != null && variant.isNotEmpty) variant,
                        if (unit != null && unit.isNotEmpty) unit,
                      ].join(' • '),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                if (pNotes != null && pNotes.trim().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.messageSquare,
                          size: 10,
                          color: isDark ? Colors.amber : Colors.amber.shade900,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            pNotes,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.amber
                                  : Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final opt in ((item['selectedOptions'] as List?) ?? []))
                  if (opt is Map &&
                      (opt['optionName']?.toString().isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        '+ ${opt['optionName']}${(double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0) > 0 ? ' (+${opt['priceAdded']} ${isArabic ? 'ج.م' : 'EGP'})' : ''}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${pTotalPrice.toStringAsFixed(2)} ${isArabic ? 'ج.م' : 'EGP'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow({
    required String label,
    required String value,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 8),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildPendingDecisionActions({
    required String fId,
    required String storeName,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final acceptBtn = ElevatedButton.icon(
          onPressed: () => onAcceptFulfillment(fId),
          icon: const Icon(LucideIcons.checkCheck, size: 15),
          label: Text(
            isArabic ? 'قبول هذا المتجر' : 'Accept Store',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        final rejectBtn = OutlinedButton.icon(
          onPressed: () => onRejectFulfillment(fId, storeName),
          icon: const Icon(LucideIcons.xCircle, size: 15),
          label: Text(
            isArabic ? 'رفض' : 'Reject',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        final scale = MediaQuery.textScalerOf(context).scale(1.0);
        // Stack buttons only when narrow width and larger text scaling would
        // truncate labels.
        if (constraints.maxWidth < 235 ||
            (constraints.maxWidth < 275 && scale > 1.15)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              acceptBtn,
              const SizedBox(height: 8),
              rejectBtn,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: acceptBtn),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: rejectBtn),
          ],
        );
      },
    );
  }
}
