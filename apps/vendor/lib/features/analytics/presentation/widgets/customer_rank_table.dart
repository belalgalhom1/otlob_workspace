import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';

import '../../providers/analytics_provider.dart';

class CustomerRankTable extends ConsumerWidget {
  final String searchQuery;
  final String sortBy;

  const CustomerRankTable({
    super.key,
    this.searchQuery = '',
    this.sortBy = 'orders',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(topCustomersProvider);

    return state.when(
      data: (allCustomers) {
        var customers = allCustomers.where((c) {
          if (searchQuery.isEmpty) return true;
          return c.name.toLowerCase().contains(searchQuery) ||
              (c.phone ?? '').contains(searchQuery);
        }).toList();

        switch (sortBy) {
          case 'orders':
            customers.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
            break;
          case 'spent':
            customers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
            break;
          case 'coins':
            customers.sort((a, b) => b.coinBalance.compareTo(a.coinBalance));
            break;
        }

        if (customers.isEmpty) {
          return _emptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _CustomerCard(
              customer: customer,
              rank: index,
              isDark: isDark,
              l10n: l10n,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(ErrorUtils.translate(context, e),
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users,
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

class _CustomerCard extends StatelessWidget {
  final AnalyticsCustomer customer;
  final int rank;
  final bool isDark;
  final AppLocalizations l10n;

  const _CustomerCard({
    required this.customer,
    required this.rank,
    required this.isDark,
    required this.l10n,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Avatar / Rank ──────────────────────────────────────
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
                    child: customer.avatar != null
                        ? CachedNetworkImage(
                            imageUrl: customer.avatar!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Center(
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
                      decoration:
                          BoxDecoration(color: cardColor, shape: BoxShape.circle),
                      child: Icon(Icons.star, color: rankColor, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Name ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customer.totalOrders} ${l10n.ordersCount}',
                    style: TextStyle(fontSize: 12, color: subColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Stats ─────────────────────────────────────────────
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${customer.totalSpent.toStringAsFixed(2)} ${l10n.egp}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${customer.coinBalance} ${l10n.analyticsCoins}',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
