import 'dart:math' as math;

import 'package:core/core.dart'
    show AppOrderType, OrderActivityHelper, OrderTypeHelper;
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart' show AppNetworkAvatar;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';

/// Maps a raw backend order or fulfillment status code to a localized label,
/// respecting request type (`RIDE` vs `CUSTOM_DELIVERY` vs `STANDARD`).
String formatTrackingDisplayStatus(
  String rawStatus,
  bool isAr, {
  AppOrderType orderType = AppOrderType.standard,
}) {
  return OrderTypeHelper.customerStatusLabel(
    orderType,
    rawStatus,
    isArabic: isAr,
  );
}

/// Floating map controls paired with a collapsible bottom sheet so the live map
/// stays unobstructed by default while keeping status, store fulfillments,
/// order updates, and Order Chat readily accessible.
class OrderTrackingSheetOverlay extends StatefulWidget {
  final String orderStatus;
  final String statusLabel;
  final String? distanceLabel;
  final Map<String, dynamic>? orderDetails;
  final int tripPathLength;
  final bool followDriver;
  final VoidCallback? onFitRoute;
  final VoidCallback onRecenterDriver;
  final VoidCallback onOpenChat;
  final VoidCallback? onRateOrder;
  final Widget? assistPromptWidget;
  final Widget? pendingPaymentWidget;
  final List<Widget> assignedDriversWidgets;
  final ValueChanged<double>? onSheetHeightChanged;

  const OrderTrackingSheetOverlay({
    super.key,
    required this.orderStatus,
    required this.statusLabel,
    this.distanceLabel,
    required this.orderDetails,
    required this.tripPathLength,
    required this.followDriver,
    this.onFitRoute,
    required this.onRecenterDriver,
    required this.onOpenChat,
    this.onRateOrder,
    this.assistPromptWidget,
    this.pendingPaymentWidget,
    this.assignedDriversWidgets = const [],
    this.onSheetHeightChanged,
  });

  @override
  State<OrderTrackingSheetOverlay> createState() =>
      _OrderTrackingSheetOverlayState();
}

class _OrderTrackingSheetOverlayState extends State<OrderTrackingSheetOverlay> {
  static const double _minExtent = 0.20;
  static const double _compactExtent = 0.34;
  static const double _urgentExtent = 0.45;
  static const double _expandedExtent = 0.74;
  static const double _maxExtent = 0.78;

  late final DraggableScrollableController _sheetController;
  late final ValueNotifier<double> _extentNotifier;
  double? _lastReportedBodyHeight;

  bool get _hasUrgentAction =>
      widget.assistPromptWidget != null || widget.pendingPaymentWidget != null;

  double get _preferredInitialExtent =>
      _hasUrgentAction ? _urgentExtent : _compactExtent;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _extentNotifier = ValueNotifier<double>(_preferredInitialExtent);
  }

  @override
  void didUpdateWidget(covariant OrderTrackingSheetOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasUrgent =
        oldWidget.assistPromptWidget != null ||
        oldWidget.pendingPaymentWidget != null;
    if (!wasUrgent && _hasUrgentAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_sheetController.isAttached) return;
        if (_extentNotifier.value < _urgentExtent) {
          _sheetController.animateTo(
            _urgentExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _extentNotifier.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (!_sheetController.isAttached) return;
    final current = _extentNotifier.value;
    final target = current >= 0.55 ? _preferredInitialExtent : _expandedExtent;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Color _statusAccentColor() {
    if (widget.orderStatus == 'CANCELLED' || widget.orderStatus == 'REJECTED') {
      return Colors.redAccent;
    }
    if (widget.orderStatus == 'DELIVERED') {
      return Colors.green;
    }
    if (widget.orderStatus == 'LOOKING_FOR_DRIVER' ||
        widget.orderStatus == 'PENDING' ||
        widget.orderStatus == 'PENDING_PAYMENT') {
      return Colors.orange;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final statusColor = _statusAccentColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight = constraints.maxHeight;
        if (_lastReportedBodyHeight != bodyHeight) {
          _lastReportedBodyHeight = bodyHeight;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.onSheetHeightChanged?.call(
              _extentNotifier.value * bodyHeight,
            );
          });
        }

        return Stack(
          children: [
            // Keep route/driver controls directly above the sheet without
            // rebuilding the whole screen when the user drags the panel.
            ValueListenableBuilder<double>(
              valueListenable: _extentNotifier,
              builder: (context, extent, _) {
                final sheetPx = extent * bodyHeight;
                const fabGroupHeight = 112.0;
                final maxBottom = math.max(16.0, bodyHeight - fabGroupHeight);
                final controlsBottom = (sheetPx + 14.0).clamp(16.0, maxBottom);

                return PositionedDirectional(
                  end: 16,
                  bottom: controlsBottom,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.tripPathLength >= 2 &&
                          widget.onFitRoute != null) ...[
                        Material(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          shadowColor: Colors.black26,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onFitRoute,
                            child: Tooltip(
                              message: s.isArabic
                                  ? 'عرض كامل مسار الرحلة'
                                  : 'Fit Entire Route',
                              child: const Padding(
                                padding: EdgeInsets.all(11.0),
                                child: Icon(
                                  Icons.alt_route_rounded,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Material(
                        color: widget.followDriver
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        shape: const CircleBorder(),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: widget.onRecenterDriver,
                          child: Tooltip(
                            message: s.isArabic
                                ? 'إعادة التمركز على الكابتن'
                                : 'Recenter on Driver',
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(
                                widget.followDriver
                                    ? Icons.my_location
                                    : Icons.location_searching,
                                size: 24,
                                color: widget.followDriver
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if (_extentNotifier.value != notification.extent) {
                  _extentNotifier.value = notification.extent;
                }
                widget.onSheetHeightChanged?.call(
                  notification.extent * bodyHeight,
                );
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: _preferredInitialExtent,
                minChildSize: _minExtent,
                maxChildSize: _maxExtent,
                snap: true,
                snapSizes: [_preferredInitialExtent],
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          16 + bottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSheetHeader(s, isDark, statusColor),
                            Divider(
                              height: 20,
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                            ),
                            if (widget.assistPromptWidget != null) ...[
                              widget.assistPromptWidget!,
                            ],
                            if (widget.pendingPaymentWidget != null) ...[
                              widget.pendingPaymentWidget!,
                              const SizedBox(height: 12),
                            ],
                            _buildCancellationBanner(s, isDark),
                            _buildRequestSummaryCard(s, isDark),
                            ..._buildStoreFulfillmentSections(s, isDark),
                            if (widget.assignedDriversWidgets.isNotEmpty)
                              ...widget.assignedDriversWidgets,
                            _buildOrderUpdatesCard(s, isDark),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: widget.onOpenChat,
                                icon: const Icon(Icons.chat_rounded, size: 20),
                                label: Text(
                                  () {
                                    final t = OrderTypeHelper.resolve(
                                      widget.orderDetails,
                                    );
                                    if (t.isRide) {
                                      return s.isArabic
                                          ? 'محادثة الكابتن'
                                          : 'Chat with Driver';
                                    }
                                    return OrderTypeHelper.chatTitle(
                                      t,
                                      isArabic: s.isArabic,
                                    );
                                  }(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.onRateOrder != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: widget.onRateOrder,
                                  icon: const Icon(
                                    Icons.star_rate_rounded,
                                    size: 20,
                                  ),
                                  label: Text(
                                    OrderTypeHelper.rateActionLabel(
                                      OrderTypeHelper.resolve(
                                        widget.orderDetails,
                                      ),
                                      isArabic: s.isArabic,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheetHeader(AppStrings s, bool isDark, Color statusColor) {
    final orderType = OrderTypeHelper.resolve(widget.orderDetails);
    final fulfillmentsRaw = widget.orderDetails?['vendorFulfillments'];
    final storeCount = orderType.hasStoreFulfillment && fulfillmentsRaw is List
        ? fulfillmentsRaw.length
        : 0;
    final muted = isDark ? Colors.white60 : Colors.grey.shade600;
    final statusHeaderTitle = orderType.isRide
        ? (s.isArabic ? 'حالة الرحلة' : 'Ride Status')
        : (orderType.isCustomDelivery
            ? (s.isArabic ? 'حالة التوصيل' : 'Delivery Status')
            : (s.isArabic ? 'حالة الطلب' : 'Order Status'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleExpand,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleExpand,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            statusHeaderTitle,
                            style: TextStyle(fontSize: 12, color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (orderType.isNonStandard)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          OrderTypeHelper.requestTypeLabel(
                            orderType,
                            isArabic: s.isArabic,
                          ),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (storeCount > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.isArabic
                              ? '$storeCount متاجر'
                              : '$storeCount stores',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (widget.distanceLabel != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.route, size: 13, color: muted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.distanceLabel!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: widget.onOpenChat,
                child: Tooltip(
                  message: OrderTypeHelper.chatTitle(
                    orderType,
                    isArabic: s.isArabic,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.isArabic ? 'محادثة' : 'Chat',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<double>(
              valueListenable: _extentNotifier,
              builder: (context, extent, _) {
                final isExpanded = extent >= 0.55;
                return Material(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _toggleExpand,
                    child: Tooltip(
                      message: isExpanded
                          ? (s.isArabic ? 'تصغير التفاصيل' : 'Collapse details')
                          : (s.isArabic ? 'عرض التفاصيل' : 'Show details'),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          size: 22,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleExpand,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              widget.statusLabel,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: statusColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestSummaryCard(AppStrings s, bool isDark) {
    final details = widget.orderDetails;
    if (details == null) return const SizedBox.shrink();
    final orderType = OrderTypeHelper.resolve(details);
    if (!orderType.isNonStandard) return const SizedBox.shrink();

    final pickup = (details['pickupAddress'] ?? details['pickup'] ?? '').toString().trim();
    final dropoff = (details['deliveryAddress'] ?? details['dropoff'] ?? '').toString().trim();
    final itemDetails = (details['itemDetails'] ?? '').toString().trim();
    final rawTotal = details['grandTotal'] ?? details['total'] ?? details['deliveryFee'];
    final total = rawTotal is num
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal?.toString() ?? '');
    final muted = isDark ? Colors.white60 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                orderType.isRide
                    ? Icons.directions_car_filled_rounded
                    : Icons.local_shipping_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  orderType.isRide
                      ? (s.isArabic ? 'تفاصيل الرحلة' : 'Ride Details')
                      : (s.isArabic ? 'تفاصيل التوصيل' : 'Delivery Details'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (total != null && total > 0)
                Text(
                  '${total.toStringAsFixed(0)} ${s.egp}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          if (pickup.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.circle, size: 9, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${orderType.isRide ? (s.isArabic ? 'نقطة الركوب' : 'Pickup') : s.pickupLocation}: $pickup',
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
          if (dropoff.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 13, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${orderType.isRide ? (s.isArabic ? 'الوجهة' : 'Destination') : s.dropoffLocation}: $dropoff',
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
          if (orderType.isCustomDelivery && itemDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              itemDetails,
              style: TextStyle(fontSize: 12, color: muted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStoreFulfillmentSections(AppStrings s, bool isDark) {
    final details = widget.orderDetails;
    if (details == null ||
        !OrderTypeHelper.shouldShowStoreFulfillmentSections(details)) {
      return const [];
    }

    final fulfillmentsRaw = details['vendorFulfillments'];
    final fulfillments = fulfillmentsRaw is List ? fulfillmentsRaw : const [];

    if (fulfillments.isEmpty && details['vendor'] is Map) {
      final v = details['vendor'] as Map;
      final b = details['vendorBranch'] is Map
          ? details['vendorBranch'] as Map
          : null;
      final storeName =
          (s.isArabic
                  ? (v['storeNameAr'] ?? v['storeName'])
                  : (v['storeName'] ?? v['name']))
              ?.toString() ??
          'Store';
      final branchName = b != null
          ? (s.isArabic ? (b['nameAr'] ?? b['name']) : (b['name'] ?? b['nameAr']))
                ?.toString()
          : null;

      return [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              AppNetworkAvatar(
                imageUrl: ImageUtils.formatImageUrl(
                  (v['logo'] ?? v['logoUrl'])?.toString(),
                ),
                size: 36,
                borderRadius: 9,
                fallbackIcon: Icons.storefront_rounded,
                fallbackIconSize: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      maxLines: 2,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (fulfillments.isEmpty) return const [];

    return [
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.isArabic
                        ? 'حالة تحضير المتاجر للطلب'
                        : 'Store Fulfillment Status',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...fulfillments.map((f) {
              if (f is! Map) return const SizedBox.shrink();
              final v = f['vendor'] is Map ? f['vendor'] as Map : const {};
              final b = f['vendorBranch'] is Map
                  ? f['vendorBranch'] as Map
                  : null;
              final storeName =
                  (s.isArabic
                          ? (v['storeNameAr'] ?? v['storeName'])
                          : (v['storeName'] ?? v['name']))
                      ?.toString() ??
                  'Store';
              final branchName = b != null
                  ? (s.isArabic
                            ? (b['nameAr'] ?? b['name'])
                            : (b['name'] ?? b['nameAr']))
                        ?.toString()
                  : null;
              final fStatus = f['status']?.toString() ?? 'PENDING';
              final isRejected =
                  fStatus == 'REJECTED' || fStatus == 'CANCELLED';
              final isReadyOrDone =
                  fStatus == 'READY_FOR_PICKUP' ||
                  fStatus == 'PICKED_UP' ||
                  fStatus == 'DELIVERED';
              final rejectionReason =
                  (s.isArabic
                          ? (f['rejectionReasonAr'] ?? f['rejectionReason'])
                          : (f['rejectionReason'] ?? f['rejectionReasonAr']))
                      ?.toString();
              final badgeColor = isRejected
                  ? Colors.red
                  : (isReadyOrDone
                        ? Colors.green
                        : (fStatus == 'PREPARING'
                              ? Colors.orange
                              : Colors.blue));

              final rawLogo =
                  (v['logo'] ??
                          v['logoUrl'] ??
                          (fulfillments.length == 1 && details['vendor'] is Map
                              ? (details['vendor']['logo'] ??
                                  details['vendor']['logoUrl'])
                              : null))
                      ?.toString();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppNetworkAvatar(
                      imageUrl: ImageUtils.formatImageUrl(rawLogo),
                      size: 32,
                      borderRadius: 8,
                      fallbackIcon: Icons.storefront_rounded,
                      fallbackIconSize: 17,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: isRejected
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (branchName != null && branchName.isNotEmpty)
                            Text(
                              '${s.isArabic ? "الفرع: " : "Branch: "}$branchName',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (isRejected &&
                              rejectionReason != null &&
                              rejectionReason.isNotEmpty)
                            Text(
                              rejectionReason,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatTrackingDisplayStatus(fStatus, s.isArabic),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
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
    ];
  }

  Widget _buildCancellationBanner(AppStrings s, bool isDark) {
    final details = widget.orderDetails;
    if (details == null) return const SizedBox.shrink();
    final actor = OrderActivityHelper.resolveCancelledBy(details);
    if (actor == null) return const SizedBox.shrink();

    final headline = OrderActivityHelper.formatCanceledByHeadline(
      actor,
      isArabic: s.isArabic,
    );
    final roleText = OrderActivityHelper.roleLabel(
      actor.role,
      isArabic: s.isArabic,
      isSystem: actor.isSystem,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppNetworkAvatar(
            imageUrl: actor.resolvedAvatarUrl,
            size: 36,
            borderRadius: actor.role?.toUpperCase() == 'VENDOR_MEMBER' ? 9 : null,
            fallbackIcon: Icons.cancel_rounded,
            fallbackIconSize: 18,
            backgroundColor: Colors.red.withValues(alpha: 0.15),
            foregroundColor: Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                if (actor.reason != null && actor.reason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${s.isArabic ? 'السبب:' : 'Reason:'} ${actor.reason!.trim()}',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderUpdatesCard(AppStrings s, bool isDark) {
    final details = widget.orderDetails;
    if (!OrderTypeHelper.shouldShowActivityLogOnTracking(details)) {
      return const SizedBox.shrink();
    }
    final orderType = OrderTypeHelper.resolve(details);
    final rawEvents = details?['statusEvents'];
    if (rawEvents is! List || rawEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final events = OrderActivityHelper.normalizeTimelineEvents(
      rawEvents,
      newestFirst: true,
    );
    if (events.isEmpty) return const SizedBox.shrink();

    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.isArabic ? 'تحديثات الطلب' : 'Order Updates',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(events.length, (index) {
            final ev = events[index];
            final evStatus = ev['status']?.toString() ?? '';
            final actor = OrderActivityHelper.resolveEventActor(ev);
            final evNote = OrderActivityHelper.formatEventNote(
              ev['note']?.toString(),
              status: evStatus,
              actor: actor,
              isArabic: s.isArabic,
            );
            final dt = DateTime.tryParse(
              ev['createdAt']?.toString() ?? '',
            )?.toLocal();
            final timeStr = dt != null
                ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                : '';
            final isLatest = index == 0;
            final isLast = index == events.length - 1;
            final dotColor = evStatus == 'CANCELLED' || evStatus == 'REJECTED'
                ? Colors.redAccent
                : (isLatest
                      ? AppColors.primary
                      : (isDark ? Colors.white38 : Colors.black38));

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                formatTrackingDisplayStatus(
                                  evStatus,
                                  s.isArabic,
                                  orderType: orderType,
                                ),
                                style: TextStyle(
                                  fontWeight: isLatest
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (actor != null) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              AppNetworkAvatar(
                                imageUrl: actor.resolvedAvatarUrl,
                                size: 18,
                                borderRadius:
                                    actor.role?.toUpperCase() == 'VENDOR_MEMBER'
                                        ? 5
                                        : null,
                                fallbackIcon: actor.isSystem
                                    ? Icons.settings_rounded
                                    : Icons.person_rounded,
                                fallbackIconSize: 11,
                              ),
                              Text(
                                actor.displayName(isArabic: s.isArabic),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  OrderActivityHelper.roleLabel(
                                    actor.role,
                                    isArabic: s.isArabic,
                                    isSystem: actor.isSystem,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (evNote.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            evNote,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
