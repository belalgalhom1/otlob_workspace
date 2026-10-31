import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';

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

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isPhone = availableWidth < 650;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 12 : 20,
                    12,
                    isPhone ? 12 : 20,
                    24,
                  ),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return _DriverCard(
                      driver: driver,
                      rank: index,
                      isDark: isDark,
                      isPhone: isPhone,
                      l10n: l10n,
                      onTap: onDriverTap != null
                          ? () => onDriverTap!(driver.id)
                          : null,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(
          ErrorUtils.translate(context, e),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.truck,
            size: 52,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
          ),
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
  final bool isPhone;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _DriverCard({
    required this.driver,
    required this.rank,
    required this.isDark,
    required this.isPhone,
    required this.l10n,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank < 3;
    final isFirst = rank == 0;
    final isSecond = rank == 1;
    final isThird = rank == 2;

    final rankColor = isFirst
        ? const Color(0xFFFFD700)
        : (isSecond
            ? const Color(0xFFC0C0C0)
            : (isThird
                ? const Color(0xFFCD7F32)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.25))));

    final cardColor = Theme.of(context).colorScheme.surface;
    final borderColor = isTop3
        ? rankColor.withValues(alpha: 0.45)
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06));
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? const Color(0xFFF1F5F9) : textColor.withValues(alpha: 0.75);
    final isOnline = driver.status.toUpperCase() == 'ONLINE';
    final isNegative = driver.walletBalance < 0;

    Widget buildRankBadge() {
      if (isTop3) {
        final gradient = isFirst
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : (isSecond
                ? const LinearGradient(
                    colors: [Color(0xFFECEFF1), Color(0xFF90A4AE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFB74D), Color(0xFF8D6E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ));

        return Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: rankColor.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '#${rank + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
      }

      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          '#${rank + 1}',
          style: TextStyle(
            color: subColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }

    Widget buildAvatar() {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isTop3 ? rankColor.withValues(alpha: 0.6) : borderColor,
            width: isTop3 ? 2.0 : 1.0,
          ),
          color: rankColor.withValues(alpha: 0.08),
        ),
        child: ClipOval(
          child: driver.avatar != null && driver.avatar!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: driver.avatar!,
                  fit: BoxFit.cover,
                  errorWidget: (_, url, err) => Center(
                    child: Icon(
                      LucideIcons.user,
                      size: 20,
                      color: rankColor,
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    LucideIcons.user,
                    size: 20,
                    color: rankColor,
                  ),
                ),
        ),
      );
    }

    List<Widget> buildMetricPills() {
      return [
        // Orders pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.shoppingBag,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                '${driver.totalOrders} ${l10n.ordersCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Wallet balance pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (isNegative ? AppColors.error : AppColors.success)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNegative ? LucideIcons.circleAlert : LucideIcons.wallet,
                size: 13,
                color: isNegative ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 5),
              Text(
                '${driver.walletBalance.toStringAsFixed(2)} ${l10n.egp}',
                style: TextStyle(
                  color: isNegative ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isTop3 ? 1.5 : 1.0),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isPhone ? 12 : 16,
              vertical: 12,
            ),
            child: isPhone
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          buildRankBadge(),
                          const SizedBox(width: 10),
                          buildAvatar(),
                          const SizedBox(width: 12),
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
                                Row(
                                  children: [
                                    _Chip(
                                      label: _tierLabel(context, driver.tier),
                                      color: AppColors.primary,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOnline
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOnline
                                          ? l10n.statusOnline
                                          : l10n.statusOffline,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (onTap != null)
                            Icon(
                              Localizations.localeOf(context).languageCode == 'ar'
                                  ? LucideIcons.chevronLeft
                                  : LucideIcons.chevronRight,
                              size: 16,
                              color: textColor.withValues(alpha: 0.35),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: buildMetricPills(),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      buildRankBadge(),
                      const SizedBox(width: 12),
                      buildAvatar(),
                      const SizedBox(width: 14),
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
                            Row(
                              children: [
                                _Chip(
                                  label: _tierLabel(context, driver.tier),
                                  color: AppColors.primary,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline
                                      ? l10n.statusOnline
                                      : l10n.statusOffline,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                ),
                                if (driver.phone != null &&
                                    driver.phone!.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: subColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    driver.phone!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Wrap(
                        spacing: 8,
                        children: buildMetricPills(),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? LucideIcons.chevronLeft
                              : LucideIcons.chevronRight,
                          size: 16,
                          color: textColor.withValues(alpha: 0.35),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _Chip({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
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
