import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';

import '../../providers/analytics_provider.dart';

class ProductRankTable extends ConsumerWidget {
  final String searchQuery;
  final String sortBy;

  const ProductRankTable({
    super.key,
    this.searchQuery = '',
    this.sortBy = 'orders',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final state = ref.watch(topProductsProvider);

    return state.when(
      data: (allProducts) {
        var products = allProducts.where((p) {
          if (searchQuery.isEmpty) return true;
          final name = isArabic ? (p.nameAr ?? p.name) : p.name;
          return name.toLowerCase().contains(searchQuery);
        }).toList();

        // Products only have one sort — totalOrders
        products.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));

        if (products.isEmpty) {
          return _emptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final productName =
                isArabic ? (product.nameAr ?? product.name) : product.name;
            return _ProductCard(
              product: product,
              productName: productName,
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
          Icon(LucideIcons.packageOpen,
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

class _ProductCard extends StatelessWidget {
  final AnalyticsTopProduct product;
  final String productName;
  final int rank;
  final bool isDark;
  final AppLocalizations l10n;

  const _ProductCard({
    required this.product,
    required this.productName,
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
            // ── Image / Rank ───────────────────────────────────────
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
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!,
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
                      decoration: BoxDecoration(
                          color: cardColor, shape: BoxShape.circle),
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
                    productName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.ordersCount}: ${product.totalOrders}',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Icon ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.shoppingBag,
                  color: AppColors.primary, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
