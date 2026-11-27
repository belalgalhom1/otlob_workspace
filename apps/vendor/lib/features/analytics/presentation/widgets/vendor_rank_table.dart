import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';

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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(topVendorsProvider);

    return state.when(
      data: (allVendors) {
        // ── Filter ──────────────────────────────────────────────────
        var vendors = allVendors.where((v) {
          if (searchQuery.isEmpty) return true;
          final name = isArabic
              ? (v.storeNameAr ?? v.storeName)
              : v.storeName;
          return name.toLowerCase().contains(searchQuery);
        }).toList();

        // ── Sort ────────────────────────────────────────────────────
        switch (sortBy) {
          case 'orders':
            vendors.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
            break;
          case 'revenue':
            vendors.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
            break;
          case 'commission':
            vendors.sort(
              (a, b) => b.totalCommission.compareTo(a.totalCommission),
            );
            break;
          case 'wallet':
            vendors.sort((a, b) => b.walletBalance.compareTo(a.walletBalance));
            break;
        }

        if (vendors.isEmpty) {
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
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = vendors[index];
                    return _VendorCard(
                      vendor: vendor,
                      rank: index,
                      isDark: isDark,
                      isArabic: isArabic,
                      isPhone: isPhone,
                      l10n: l10n,
                      onTap: onVendorTap != null
                          ? () => onVendorTap!(vendor.id)
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
            LucideIcons.store,
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

class _VendorCard extends StatelessWidget {
  final AnalyticsVendor vendor;
  final int rank;
  final bool isDark;
  final bool isArabic;
  final bool isPhone;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _VendorCard({
    required this.vendor,
    required this.rank,
    required this.isDark,
    required this.isArabic,
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

    final rawName = isArabic
        ? (vendor.storeNameAr ?? vendor.storeName)
        : vendor.storeName;
    final storeName = rawName.isNotEmpty ? rawName : l10n.unknownVendor;

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

    Widget buildLogo() {
      return AppNetworkAvatar(
        imageUrl: ImageUtils.formatImageUrl(vendor.displayImage),
        size: 48,
        borderRadius: 12,
        fallbackIcon: LucideIcons.store,
        fallbackIconSize: 20,
        backgroundColor: rankColor.withValues(alpha: 0.08),
        foregroundColor: rankColor,
        border: Border.all(
          color: isTop3 ? rankColor.withValues(alpha: 0.6) : borderColor,
          width: isTop3 ? 2.0 : 1.0,
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
                '${vendor.totalOrders} ${l10n.ordersCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Revenue pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.trendingUp,
                size: 13,
                color: AppColors.success,
              ),
              const SizedBox(width: 5),
              Text(
                '${vendor.totalRevenue.toStringAsFixed(2)} ${l10n.egp}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Commission pill
        Tooltip(
          message: isArabic ? 'عمولة المنصة' : 'Platform Commission',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.percent,
                  size: 13,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 5),
                Text(
                  '${isArabic ? 'العمولة' : 'Commission'}: ${vendor.totalCommission.toStringAsFixed(2)} ${l10n.egp}',
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Wallet pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (vendor.walletBalance < 0 ? AppColors.error : Colors.teal)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.wallet,
                size: 13,
                color: vendor.walletBalance < 0 ? AppColors.error : Colors.teal,
              ),
              const SizedBox(width: 5),
              Text(
                '${vendor.walletBalance.toStringAsFixed(2)} ${l10n.egp}',
                style: TextStyle(
                  color: vendor.walletBalance < 0
                      ? AppColors.error
                      : Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    Widget? buildTopProductPill() {
      if (vendor.topProduct == null) return null;
      final p = vendor.topProduct!;
      final rawProductName = isArabic ? (p.nameAr ?? p.name) : p.name;
      final productName = rawProductName.isNotEmpty && rawProductName != 'Unknown'
          ? rawProductName
          : (isArabic ? 'منتج غير محدد' : 'Unnamed Product');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: isPhone ? MainAxisSize.max : MainAxisSize.min,
          children: [
            AppNetworkAvatar(
              imageUrl: ImageUtils.formatImageUrl(p.imageUrl),
              size: 22,
              borderRadius: 6,
              fallbackIcon: LucideIcons.packageCheck,
              fallbackIconSize: 12,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              foregroundColor: AppColors.primary,
              border: Border.all(color: borderColor, width: 0.75),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${l10n.topProduct}: $productName (${p.totalOrders} ${l10n.ordersCount})',
                style: TextStyle(
                  fontSize: 11,
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final topProductWidget = buildTopProductPill();

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
                          buildLogo(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              storeName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onTap != null)
                            Icon(
                              isArabic
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
                      if (topProductWidget != null) ...[
                        const SizedBox(height: 8),
                        topProductWidget,
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          buildRankBadge(),
                          const SizedBox(width: 12),
                          buildLogo(),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: Text(
                              storeName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            flex: 4,
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 6,
                              children: buildMetricPills(),
                            ),
                          ),
                          if (onTap != null) ...[
                            const SizedBox(width: 10),
                            Icon(
                              isArabic
                                  ? LucideIcons.chevronLeft
                                  : LucideIcons.chevronRight,
                              size: 16,
                              color: textColor.withValues(alpha: 0.35),
                            ),
                          ],
                        ],
                      ),
                      if (topProductWidget != null) ...[
                        const SizedBox(height: 10),
                        topProductWidget,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
