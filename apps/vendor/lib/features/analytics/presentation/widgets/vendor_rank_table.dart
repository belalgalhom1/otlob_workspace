import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

import '../../providers/analytics_provider.dart';

class VendorRankTable extends ConsumerWidget {
  final String searchQuery;
  final String sortBy;
  final void Function(String vendorId)? onVendorTap;

  const VendorRankTable({
    super.key,
    this.searchQuery = '',
    this.sortBy = 'orders',
    this.onVendorTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final state = ref.watch(topVendorsProvider);

    return state.when(
      data: (allVendors) {
        var vendors = allVendors.where((v) {
          if (searchQuery.isEmpty) return true;
          final name = isArabic
              ? (v.storeNameAr ?? v.storeName)
              : v.storeName;
          return name.toLowerCase().contains(searchQuery);
        }).toList();

        switch (sortBy) {
          case 'orders':
            vendors.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
            break;
          case 'revenue':
            vendors.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
            break;
          case 'wallet':
            vendors.sort((a, b) => b.walletBalance.compareTo(a.walletBalance));
            break;
        }

        if (vendors.isEmpty) {
          return _emptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return _VendorCard(
              vendor: vendor,
              rank: index,
              isDark: isDark,
              l10n: l10n,
              isArabic: isArabic,
              onTap: onVendorTap != null ? () => onVendorTap!(vendor.id) : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(e.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.store,
              size: 52,
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noDataAvailable,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black38,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final AnalyticsVendor vendor;
  final int rank;
  final bool isDark;
  final bool isArabic;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _VendorCard({
    required this.vendor,
    required this.rank,
    required this.isDark,
    required this.isArabic,
    required this.l10n,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank < 3;
    final rankColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final rankColor = isTop3
        ? rankColors[rank]
        : (isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.25));
    final cardColor = isDark ? const Color(0xFF252525) : Colors.white;
    final borderColor = isTop3
        ? rankColor.withValues(alpha: 0.4)
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06));
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.45);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    final storeName =
        isArabic ? (vendor.storeNameAr ?? vendor.storeName) : vendor.storeName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: rankColor, width: isTop3 ? 2.5 : 1.5),
                            color: rankColor.withValues(alpha: 0.1),
                          ),
                          child: ClipOval(
                            child: vendor.logo != null
                                ? CachedNetworkImage(
                                    imageUrl: vendor.logo!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, url, err) => Center(
                                      child: Text('${rank + 1}',
                                          style: TextStyle(
                                              color: rankColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                    ),
                                  )
                                : Center(
                                    child: Text('${rank + 1}',
                                        style: TextStyle(
                                            color: rankColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                  ),
                          ),
                        ),
                        if (isTop3)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: cardColor, shape: BoxShape.circle),
                              child:
                                  Icon(Icons.star, color: rankColor, size: 14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                           Text(
                            '${vendor.totalOrders} ${l10n.ordersCount}',
                            style: TextStyle(fontSize: 12, color: subColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${vendor.totalRevenue} EGP',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${vendor.walletBalance} EGP',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      Icon(LucideIcons.chevronRight,
                          size: 16,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black26),
                    ],
                  ],
                ),

                // ── Top Product row ──────────────────────────────────
                if (vendor.topProduct != null) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.topProduct}: ${isArabic ? (vendor.topProduct!.nameAr ?? vendor.topProduct!.name) : vendor.topProduct!.name}',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: textColor),
                          ),
                        ),
                        Text(
                          '${vendor.topProduct!.totalOrders} ${l10n.ordersCount}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
