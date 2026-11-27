import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/favorites_provider.dart';
import 'home_design_tokens.dart';

/// Compact 3-column store card for the Home Screen Nearby Vendors grid.
/// Adapts automatically to Dark & Light Mode via [HomePalette].
class HomeSuggestedStoreCard extends ConsumerWidget {
  final Map<String, dynamic> vendor;
  final double? width;

  const HomeSuggestedStoreCard({
    super.key,
    required this.vendor,
    this.width,
  });

  bool _isVendorOpen(Map<String, dynamic> v) {
    final status = v['status']?.toString().toUpperCase();
    final vendorOpen = status == null || status == 'OPEN';
    final closestBranch = v['closestBranch'];
    final branchOpen =
        closestBranch is! Map || closestBranch['isOpen'] != false;
    return vendorOpen && branchOpen;
  }

  String _metaLine(Map<String, dynamic> v, bool isAr) {
    final parts = <String>[];

    final distNum = num.tryParse(v['distanceKm']?.toString() ?? '');
    if (distNum != null) {
      parts.add(
        isAr
            ? '${distNum.toStringAsFixed(1)} كم'
            : '${distNum.toStringAsFixed(1)} km',
      );
    }

    final rawTime = isAr
        ? v['deliveryTime']
        : (v['deliveryTimeEn'] ?? v['deliveryTime']);
    if (rawTime != null && rawTime.toString().isNotEmpty) {
      parts.add(rawTime.toString());
    } else if (distNum != null && distNum > 0) {
      final baseMin = (15 + distNum * 2.5).round();
      final maxMin = baseMin + 10;
      parts.add(isAr ? '$baseMin-$maxMin د' : '$baseMin-$maxMin m');
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HomePalette.of(context);
    final s = AppStrings.of(context);
    final isAr = s.isArabic;
    final vendorId = vendor['id']?.toString() ?? '';
    final isFav = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(vendorId)),
    );

    final name =
        isAr &&
            vendor['nameAr'] != null &&
            vendor['nameAr'].toString().isNotEmpty
        ? vendor['nameAr'].toString()
        : (vendor['name'] ?? vendor['storeName'] ?? '').toString();

    final isOpen = _isVendorOpen(vendor);
    final statusLabel = isOpen
        ? (isAr ? 'مفتوح' : 'Open')
        : (isAr ? 'مغلق' : 'Closed');

    final coverRaw = (vendor['coverImage'] ?? vendor['image'] ?? vendor['logo'])
        ?.toString();
    final coverUrl = (coverRaw != null && coverRaw.isNotEmpty)
        ? ImageUtils.thumbnailUrl(coverRaw)
        : '';

    final rating = double.tryParse(vendor['rating']?.toString() ?? '0') ?? 0.0;
    final metaText = _metaLine(vendor, isAr);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: palette.cardSurface1,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/vendor', extra: vendor),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.borderSubtle,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final coverHeight = constraints.maxHeight.isFinite
                      ? (constraints.maxHeight * 0.49).clamp(58.0, 76.0)
                      : 70.0;
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Cover Image
                      SizedBox(
                        height: coverHeight,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (coverUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 320,
                                placeholder: (_, _) =>
                                    _buildFallbackCover(palette),
                                errorWidget: (_, _, _) =>
                                    _buildFallbackCover(palette),
                              )
                            else
                              _buildFallbackCover(palette),
                            if (coverUrl.isNotEmpty)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(
                                        alpha: palette.isDark ? 0.32 : 0.16,
                                      ),
                                      Colors.black.withValues(
                                        alpha: palette.isDark ? 0.40 : 0.22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Top overlay: Status pill (start) + Favorite button (end)
                            Positioned(
                              top: 6,
                              left: 6,
                              right: 6,
                              child: MediaQuery.withClampedTextScaling(
                                maxScaleFactor: 1.05,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOpen
                                              ? HomeDesignTokens.gold
                                              : palette.discountBgRed,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: isOpen
                                              ? null
                                              : Border.all(
                                                  color:
                                                      palette.discountBorderRed,
                                                ),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: HomeDesignTokens.text(
                                            size: 9.5,
                                            weight: FontWeight.w900,
                                            color: isOpen
                                                ? HomeDesignTokens.darkOnGold
                                                : palette.discountTextRed,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {
                                        final authStatus = ref.read(
                                          authControllerProvider,
                                        );
                                        if (authStatus !=
                                            AuthStatus.authenticated) {
                                          AuthPromptDialog.show(context);
                                          return;
                                        }
                                        final result = await ref
                                            .read(favoritesProvider.notifier)
                                            .toggleFavorite(vendorId);
                                        if (context.mounted) {
                                          showVendorFavoriteFeedback(
                                            context,
                                            isFavorite: result,
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(
                                            alpha: 0.48,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          isFav
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: 12,
                                          color: isFav
                                              ? const Color(0xFFF87171)
                                              : Colors.white.withValues(
                                                  alpha: 0.92,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Info Area (Name + Rating + Meta)
                      Expanded(
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.12,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HomeDesignTokens.text(
                                    size: 12.5,
                                    weight: FontWeight.w800,
                                    color: palette.textPrimary,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 12.5,
                                      color: palette.goldText,
                                    ),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: HomeDesignTokens.numeric(
                                        size: 11.5,
                                        weight: FontWeight.w800,
                                        color: palette.textPrimary,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                if (metaText.isNotEmpty) ...[
                                  const SizedBox(height: 2.5),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 10.5,
                                        color: palette.goldText,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: Text(
                                            metaText,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: HomeDesignTokens.text(
                                              size: 10.5,
                                              weight: FontWeight.w600,
                                              color: palette.textMuted,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: card);
    }
    return card;
  }

  Widget _buildFallbackCover(HomePalette palette) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.storeFallbackCoverColors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 24,
          color: palette.goldText.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
