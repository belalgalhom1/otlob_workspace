import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

import '../../providers/analytics_provider.dart';

class DriverRankTable extends ConsumerWidget {
  final String searchQuery;
  final String sortBy;
  final void Function(String driverId)? onDriverTap;

  const DriverRankTable({
    super.key,
    this.searchQuery = '',
    this.sortBy = 'orders',
    this.onDriverTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(topDriversProvider);

    return state.when(
      data: (allDrivers) {
        // ── Filter ──────────────────────────────────────────────────
        var drivers = allDrivers.where((d) {
          if (searchQuery.isEmpty) return true;
          return d.name.toLowerCase().contains(searchQuery) ||
              (d.phone ?? '').contains(searchQuery);
        }).toList();

        // ── Sort ────────────────────────────────────────────────────
        switch (sortBy) {
          case 'trips':
          case 'orders':
            drivers.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
            break;
          case 'wallet':
            drivers.sort((a, b) => b.walletBalance.compareTo(a.walletBalance));
            break;
        }

        if (drivers.isEmpty) {
          return _emptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return _DriverCard(
              driver: driver,
              rank: index,
              isDark: isDark,
              l10n: l10n,
              onTap: onDriverTap != null ? () => onDriverTap!(driver.id) : null,
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
          Icon(LucideIcons.truck,
              size: 52,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)),
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

class _DriverCard extends StatelessWidget {
  final AnalyticsDriver driver;
  final int rank;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _DriverCard({
    required this.driver,
    required this.rank,
    required this.isDark,
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

    final isOnline = driver.status.toUpperCase() == 'ONLINE';

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Rank + Avatar ──────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rankColor,
                          width: isTop3 ? 2.5 : 1.5,
                        ),
                        color: rankColor.withValues(alpha: 0.1),
                      ),
                      child: ClipOval(
                        child: driver.avatar != null
                            ? CachedNetworkImage(
                                imageUrl: driver.avatar!,
                                fit: BoxFit.cover,
                                errorWidget: (_, url, err) => Center(
                                  child: Text(
                                    '${rank + 1}',
                                    style: TextStyle(
                                        color: rankColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  '${rank + 1}',
                                  style: TextStyle(
                                      color: rankColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
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
                            color: cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.star, color: rankColor, size: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // ── Info ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Tier chip
                      _Chip(
                        label: _tierLabel(context, driver.tier),
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 4),
                      // Online / Offline — full line, never truncated
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? l10n.statusOnline : l10n.statusOffline,
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Stats ─────────────────────────────────────────
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.shoppingBag,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${driver.totalOrders} ${l10n.ordersCount}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.wallet,
                              size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${driver.walletBalance.toStringAsFixed(2)} ${l10n.egp}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _Chip({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Localised tier name (GOLD/SILVER/BRONZE) for the on-screen chip.
String _tierLabel(BuildContext context, String tier) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  switch (tier.toUpperCase()) {
    case 'GOLD':
      return ar ? 'ذهبي' : 'Gold';
    case 'SILVER':
      return ar ? 'فضي' : 'Silver';
    case 'BRONZE':
      return ar ? 'برونزي' : 'Bronze';
    default:
      return tier;
  }
}
