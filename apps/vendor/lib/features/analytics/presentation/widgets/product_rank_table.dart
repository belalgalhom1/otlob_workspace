import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:core/core.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(topProductsProvider);

    return state.when(
      data: (allProducts) {
        // ── Filter ──────────────────────────────────────────────────
        var products = allProducts.where((p) {
          if (searchQuery.isEmpty) return true;
          final name = isArabic ? (p.nameAr ?? p.name) : p.name;
          return name.toLowerCase().contains(searchQuery);
        }).toList();

        // ── Sort ────────────────────────────────────────────────────
        products.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));

        if (products.isEmpty) {
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
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final rawName =
                        isArabic ? (product.nameAr ?? product.name) : product.name;
                    final displayName = (rawName.isNotEmpty && rawName != 'Unknown')
                        ? rawName
                        : (isArabic ? 'منتج غير محدد' : 'Unnamed Product');

                    return _ProductCard(
                      product: product,
                      productName: displayName,
                      rank: index,
                      isDark: isDark,
                      isPhone: isPhone,
                      l10n: l10n,
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
            LucideIcons.package,
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

class _ProductCard extends StatelessWidget {
  final AnalyticsTopProduct product;
  final String productName;
  final int rank;
  final bool isDark;
  final bool isPhone;
  final AppLocalizations l10n;

  const _ProductCard({
    required this.product,
    required this.productName,
    required this.rank,
    required this.isDark,
    required this.isPhone,
    required this.l10n,
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

    Widget buildProductImage() {
      return AppNetworkAvatar(
        imageUrl: ImageUtils.formatImageUrl(product.imageUrl),
        size: 48,
        borderRadius: 12,
        fallbackIcon: LucideIcons.package,
        fallbackIconSize: 20,
        backgroundColor: rankColor.withValues(alpha: 0.08),
        foregroundColor: rankColor,
        border: Border.all(
          color: isTop3 ? rankColor.withValues(alpha: 0.6) : borderColor,
          width: isTop3 ? 2.0 : 1.0,
        ),
      );
    }

    Widget buildOrdersPill() {
      return Container(
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
              '${product.totalOrders} ${l10n.ordersCount}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 12 : 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              buildRankBadge(),
              const SizedBox(width: 12),
              buildProductImage(),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  productName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 14),
              buildOrdersPill(),
            ],
          ),
        ),
      ),
    );
  }
}
