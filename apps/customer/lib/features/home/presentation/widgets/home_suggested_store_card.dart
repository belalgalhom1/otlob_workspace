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

/// Compact horizontal Suggested Store card for the zero-scroll Home Screen
/// (Section 6). Adapts automatically to Dark & Light Mode via [HomePalette].
class HomeSuggestedStoreCard extends ConsumerWidget {
  final Map<String, dynamic> vendor;

  const HomeSuggestedStoreCard({super.key, required this.vendor});

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

    final coverRaw = (vendor['coverImage'] ?? vendor['image'])?.toString();
    final coverUrl = (coverRaw != null && coverRaw.isNotEmpty)
        ? ImageUtils.thumbnailUrl(coverRaw)
        : '';

    final rating = double.tryParse(vendor['rating']?.toString() ?? '0') ?? 0.0;
    final metaText = _metaLine(vendor, isAr);

    return SizedBox(
      width: 192,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadowColor,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: palette.cardSurface1,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/vendor', extra: vendor),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: palette.borderSubtle,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final coverHeight = constraints.maxHeight.isFinite
                        ? (constraints.maxHeight * 0.52).clamp(46.0, 64.0)
                        : 56.0;
                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Top Cover Strip (~52–60px responsive)
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
                                  memCacheWidth: 400,
                                  placeholder: (_, _) => DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors:
                                            palette.storeFallbackCoverColors,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, _, _) => DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors:
                                            palette.storeFallbackCoverColors,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: palette.storeFallbackCoverColors,
                                    ),
                                  ),
                                ),
                              // Only apply subtle dark scrim over real cover photos so Light Mode fallbacks stay airy and crisp
                              if (coverUrl.isNotEmpty)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(
                                          alpha: palette.isDark ? 0.30 : 0.14,
                                        ),
                                        Colors.black.withValues(
                                          alpha: palette.isDark ? 0.42 : 0.24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Strip controls: Status pill (start) and Favorite (end)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Status pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2.5,
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
                                    // Favorite Button (24x24)
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        final authStatus = ref.read(
                                          authControllerProvider,
                                        );
                                        if (authStatus !=
                                            AuthStatus.authenticated) {
                                          AuthPromptDialog.show(context);
                                          return;
                                        }
                                        ref
                                            .read(favoritesProvider.notifier)
                                            .toggleFavorite(vendorId);
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          isFav
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: 13,
                                          color: isFav
                                              ? const Color(0xFFF87171)
                                              : Colors.white.withValues(
                                                  alpha: 0.90,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Info Bar
                        Expanded(
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.12,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: HomeDesignTokens.text(
                                            size: 13.0,
                                            weight: FontWeight.w900,
                                            color: palette.textPrimary,
                                            height: 1.15,
                                          ),
                                        ),
                                        if (metaText.isNotEmpty) ...[
                                          const SizedBox(height: 1.5),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                size: 11,
                                                color: palette.goldText,
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  metaText,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: HomeDesignTokens.text(
                                                    size: 11.0,
                                                    weight: FontWeight.w600,
                                                    color: palette.textMuted,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: palette.goldText,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: HomeDesignTokens.numeric(
                                          size: 11.0,
                                          weight: FontWeight.w800,
                                          color: palette.textPrimary,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }
}
