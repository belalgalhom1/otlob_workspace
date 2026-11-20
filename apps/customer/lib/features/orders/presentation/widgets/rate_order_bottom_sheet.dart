import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart' show AppNetworkAvatar;
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/l10n/app_strings.dart';
import '../../../../../../core/utils/image_utils.dart';
import '../providers/orders_provider.dart';

class RateOrderBottomSheet extends ConsumerStatefulWidget {
  final String orderId;
  final Map<String, dynamic>? order;

  const RateOrderBottomSheet({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  ConsumerState<RateOrderBottomSheet> createState() =>
      _RateOrderBottomSheetState();

  static Future<bool?> show(
    BuildContext context,
    String orderId, {
    Map<String, dynamic>? order,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: RateOrderBottomSheet(orderId: orderId, order: order),
        ),
      ),
    );
  }
}

class _RateOrderBottomSheetState extends ConsumerState<RateOrderBottomSheet> {
  Map<String, dynamic>? _orderDetails;
  bool _loadingDetails = false;
  int _fallbackRating = 5;
  final Map<String, int> _fulfillmentRatings = {};
  final Map<String, int> _groupRatings = {};
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _orderDetails = widget.order;
    if (_orderDetails == null) {
      _loadOrder();
    } else {
      _initTargetRatings(_orderDetails!);
    }
  }

  Future<void> _loadOrder() async {
    setState(() => _loadingDetails = true);
    final fetched = await ref
        .read(ordersProvider.notifier)
        .fetchOrderDetails(widget.orderId);
    if (!mounted) return;
    setState(() {
      _orderDetails = fetched;
      _loadingDetails = false;
      if (fetched != null) {
        _initTargetRatings(fetched);
      }
    });
  }

  void _initTargetRatings(Map<String, dynamic> order) {
    final reviews = (order['reviews'] as List?)?.whereType<Map>().toList() ?? [];
    final ratedFulfillmentIds = reviews
        .map((r) => r['fulfillmentId']?.toString())
        .whereType<String>()
        .toSet();
    final ratedGroupIds = reviews
        .map((r) => r['deliveryGroupId']?.toString())
        .whereType<String>()
        .toSet();

    final fulfillments = _unratedFulfillments(order, ratedFulfillmentIds);
    for (final f in fulfillments) {
      final fid = f['id'].toString();
      _fulfillmentRatings.putIfAbsent(fid, () => 5);
    }

    final groups = _unratedGroups(order, ratedGroupIds);
    for (final g in groups) {
      final gid = g['id'].toString();
      _groupRatings.putIfAbsent(gid, () => 5);
    }
  }

  List<Map<String, dynamic>> _unratedFulfillments(
    Map<String, dynamic> order,
    Set<String> ratedIds,
  ) {
    final raw = order['vendorFulfillments'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .where((f) {
          final id = f['id']?.toString();
          final status = f['status']?.toString() ?? '';
          return id != null &&
              status != 'REJECTED' &&
              status != 'CANCELLED' &&
              !ratedIds.contains(id);
        })
        .map((f) => Map<String, dynamic>.from(f))
        .toList();
  }

  List<Map<String, dynamic>> _unratedGroups(
    Map<String, dynamic> order,
    Set<String> ratedIds,
  ) {
    final raw = order['deliveryGroups'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .where((g) {
          final id = g['id']?.toString();
          final status = g['status']?.toString() ?? '';
          final driver = g['primaryDriver'] ?? g['driver'];
          final hasDriver = g['primaryDriverId'] != null ||
              (driver is Map && driver['id'] != null);
          return id != null &&
              status == 'DELIVERED' &&
              hasDriver &&
              !ratedIds.contains(id);
        })
        .map((g) => Map<String, dynamic>.from(g))
        .toList();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    final s = AppStrings.of(context);
    setState(() => _isSubmitting = true);

    try {
      final comment = _commentController.text.trim();
      final order = _orderDetails;
      final fulfillmentsRaw = order?['vendorFulfillments'];
      final hasFulfillmentTargets = _fulfillmentRatings.isNotEmpty;
      final hasGroupTargets = _groupRatings.isNotEmpty;

      // Custom orders have no vendorFulfillments; avoid sending vendorRating
      // which backend rejects with INVALID_TRANSITION when deliveredFulfillments is empty.
      final hasAnyVendorFulfillment =
          fulfillmentsRaw is List && fulfillmentsRaw.isNotEmpty;

      final success = await ref.read(ordersProvider.notifier).rateOrder(
            widget.orderId,
            _fallbackRating,
            comment,
            includeVendorRating: !hasFulfillmentTargets && hasAnyVendorFulfillment,
            includeDriverRating: !hasGroupTargets,
            fulfillmentRatings: hasFulfillmentTargets
                ? _fulfillmentRatings.entries
                    .map((e) => (
                          fulfillmentId: e.key,
                          rating: e.value,
                          comment: comment.isEmpty ? null : comment,
                        ))
                    .toList()
                : null,
            deliveryGroupRatings: hasGroupTargets
                ? _groupRatings.entries
                    .map((e) => (
                          deliveryGroupId: e.key,
                          rating: e.value,
                          comment: comment.isEmpty ? null : comment,
                        ))
                    .toList()
                : null,
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s.isArabic
                    ? 'تم إرسال التقييم بنجاح'
                    : 'Rating submitted successfully',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                s.isArabic
                    ? 'حدث خطأ أثناء التقييم'
                    : 'Failed to submit rating',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _starRow({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < value ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 36,
          ),
          onPressed: () => onChanged(index + 1),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = _orderDetails;
    final reviews = (order?['reviews'] as List?)?.whereType<Map>().toList() ?? [];
    final ratedFulfillmentIds = reviews
        .map((r) => r['fulfillmentId']?.toString())
        .whereType<String>()
        .toSet();
    final ratedGroupIds = reviews
        .map((r) => r['deliveryGroupId']?.toString())
        .whereType<String>()
        .toSet();
    final fulfillments = order != null
        ? _unratedFulfillments(order, ratedFulfillmentIds)
        : const <Map<String, dynamic>>[];
    final groups = order != null
        ? _unratedGroups(order, ratedGroupIds)
        : const <Map<String, dynamic>>[];
    final hasTargets = fulfillments.isNotEmpty || groups.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.isArabic ? 'تقييم الطلب' : 'Rate Order',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_loadingDetails)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (hasTargets) ...[
              ...fulfillments.map((f) {
                final fid = f['id'].toString();
                final v = f['vendor'] is Map ? f['vendor'] as Map : const {};
                final b =
                    f['vendorBranch'] is Map ? f['vendorBranch'] as Map : null;
                final storeName = (s.isArabic
                        ? (v['storeNameAr'] ?? v['storeName'])
                        : (v['storeName'] ?? v['storeNameAr']))
                    ?.toString();
                final branchName = b == null
                    ? null
                    : (s.isArabic
                            ? (b['nameAr'] ?? b['name'])
                            : (b['name'] ?? b['nameAr']))
                        ?.toString();
                final title = [
                  if (storeName != null && storeName.isNotEmpty) storeName,
                  if (branchName != null && branchName.isNotEmpty) branchName,
                ].join(' • ');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
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
                          AppNetworkAvatar(
                            imageUrl: ImageUtils.formatImageUrl(
                              (v['logo'] ?? v['logoUrl'])?.toString(),
                            ),
                            size: 28,
                            borderRadius: 7,
                            fallbackIcon: Icons.storefront_rounded,
                            fallbackIconSize: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title.isNotEmpty ? title : s.vendor,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _starRow(
                        value: _fulfillmentRatings[fid] ?? 5,
                        onChanged: (val) =>
                            setState(() => _fulfillmentRatings[fid] = val),
                      ),
                    ],
                  ),
                );
              }),
              ...groups.map((g) {
                final gid = g['id'].toString();
                final seq = g['sequence'] ?? 1;
                final driver = g['primaryDriver'] ?? g['driver'];
                final driverName = driver is Map
                    ? driver['name']?.toString()
                    : null;
                final tripPrefix = groups.length > 1
                    ? (s.isArabic ? 'التوصيل $seq' : 'Delivery #$seq')
                    : (s.isArabic ? 'كابتن التوصيل' : 'Delivery Captain');
                final title = (driverName != null && driverName.isNotEmpty)
                    ? '$tripPrefix • $driverName'
                    : tripPrefix;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
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
                          AppNetworkAvatar(
                            imageUrl: ImageUtils.formatImageUrl(
                              (driver is Map
                                      ? (driver['avatar'] ??
                                          (driver['user'] is Map
                                              ? driver['user']['avatar']
                                              : null))
                                      : null)
                                  ?.toString(),
                            ),
                            size: 28,
                            fallbackIcon: Icons.delivery_dining_rounded,
                            fallbackIconSize: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _starRow(
                        value: _groupRatings[gid] ?? 5,
                        onChanged: (val) =>
                            setState(() => _groupRatings[gid] = val),
                      ),
                    ],
                  ),
                );
              }),
            ] else
              _starRow(
                value: _fallbackRating,
                onChanged: (val) => setState(() => _fallbackRating = val),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: s.isArabic
                    ? 'أضف تعليقاً (اختياري)'
                    : 'Add a comment (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _loadingDetails ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        s.isArabic ? 'إرسال التقييم' : 'Submit Rating',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
