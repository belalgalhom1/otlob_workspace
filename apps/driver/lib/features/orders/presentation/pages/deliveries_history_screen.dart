import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:intl/intl.dart';

import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/features/orders/presentation/driver_orders_history_provider.dart';
import 'package:driver/features/order_execution/presentation/widgets/order_details_bottom_sheet.dart';

class DeliveriesHistoryScreen extends ConsumerStatefulWidget {
  const DeliveriesHistoryScreen({super.key});

  @override
  ConsumerState<DeliveriesHistoryScreen> createState() => _DeliveriesHistoryScreenState();
}

class _DeliveriesHistoryScreenState extends ConsumerState<DeliveriesHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(driverOrdersHistoryProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(driverOrdersHistoryProvider);
    final currency = ref.watch(configurationProvider.notifier).currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deliveryHistory),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null && state.orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          ErrorUtils.translate(context, state.error),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: l10n.retry,
                          onPressed: () => ref.read(driverOrdersHistoryProvider.notifier).fetchDeliveries(isRefresh: true),
                        ),
                      ],
                    ),
                  ),
                )
              : state.orders.isEmpty
                  ? EmptyStateWidget(
                      icon: LucideIcons.packageCheck,
                      title: l10n.noDeliveriesYet,
                      subtitle: l10n.noDeliveriesSubtitle,
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(driverOrdersHistoryProvider.notifier).fetchDeliveries(isRefresh: true),
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: state.orders.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == state.orders.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );
                          }
                          final order = state.orders[index];
                          return _buildDeliveryCard(context, order, currency, l10n);
                        },
                      ),
                    ),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    Map<String, dynamic> order,
    String currency,
    AppLocalizations l10n,
  ) {
    final orderNumber = order['orderNumber']?.toString() ?? '#${(order['id'] ?? '').toString().substring(0, 8)}';
    final rawEarnings = order['driverEarnings'] ?? order['estimatedEarnings'];
    final rawFee = order['deliveryFee'] ?? order['fee'] ?? 0;
    final double deliveryFee = rawEarnings != null
        ? (rawEarnings is num ? rawEarnings.toDouble() : double.tryParse(rawEarnings.toString()) ?? 0.0)
        : (rawFee is num ? rawFee.toDouble() * 0.8 : (double.tryParse(rawFee.toString()) ?? 0.0) * 0.8);
    final vendor = order['vendor'] as Map<String, dynamic>?;
    final vendorName = l10n.localeName == 'ar'
        ? (vendor?['storeNameAr'] ?? vendor?['storeName'] ?? (order['pickupAddress'] ?? ''))
        : (vendor?['storeName'] ?? (order['pickupAddress'] ?? ''));

    final addressRaw = order['deliveryAddress'];
    final String dropoffAddress = addressRaw is String
        ? addressRaw
        : (addressRaw is Map ? (addressRaw['address'] ?? '') : '');

    DateTime? createdAt;
    if (order['createdAt'] != null) {
      createdAt = DateTime.tryParse(order['createdAt'].toString())?.toLocal();
    }

    final isCustom = order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE';

    return InkWell(
      onTap: () => OrderDetailsBottomSheet.show(context, order),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order #, Type badge, and Delivered status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    orderNumber,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order['type'] == 'RIDE' ? 'Ride' : 'Courier',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCheck, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        l10n.statusApproved,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup Row
            Row(
              children: [
                Icon(
                  isCustom ? LucideIcons.mapPin : LucideIcons.store,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vendorName.isNotEmpty ? vendorName : l10n.unknown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Dropoff Row
            if (dropoffAddress.isNotEmpty)
              Row(
                children: [
                  Icon(
                    LucideIcons.navigation,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dropoffAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            const Divider(height: 1),
            const SizedBox(height: 12),

            // Footer: Fee earned & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deliveryFeeEarned,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deliveryFee.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(
                        DateFormat.yMMMd().format(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
