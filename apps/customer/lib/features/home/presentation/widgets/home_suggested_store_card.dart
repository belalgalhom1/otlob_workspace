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
/// (Section 6). Preserves all existing vendor navigation & favorite logic.
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

    final logoRaw = (vendor['logo'] ?? vendor['image'])?.toString();
    final logoUrl = (logoRaw != null && logoRaw.isNotEmpty)
        ? ImageUtils.thumbnailUrl(logoRaw)
        : '';

    final rating = double.tryParse(vendor['rating']?.toString() ?? '0') ?? 0.0;
    final metaText = _metaLine(vendor, isAr);

    return SizedBox(
      width: 172,
      child: Material(
        color: HomeDesignTokens.cardSurface1,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/vendor', extra: vendor),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: HomeDesignTokens.borderSubtle,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Top Cover Strip (48px)
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover background
                        if (coverUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 360,
                            placeholder: (_, _) => const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    HomeDesignTokens.cardSurface2,
                                    HomeDesignTokens.cardSurface1,
                                  ],
                                ),
                              ),
                            ),
                            errorWidget: (_, _, _) => const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    HomeDesignTokens.cardSurface2,
                                    HomeDesignTokens.cardSurface1,
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  HomeDesignTokens.cardSurface2,
                                  HomeDesignTokens.cardSurface1,
                                ],
                              ),
                            ),
                          ),
                        // Subtle scrim so pill, centered logo, and fav icon stay crisp
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.32),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                        // Strip controls: Status pill (start), Logo (center), Favorite (end)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Status pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? HomeDesignTokens.gold
                                      : Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(999),
                                  border: isOpen
                                      ? null
                                      : Border.all(
                                          color: HomeDesignTokens.borderSubtle,
                                        ),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: HomeDesignTokens.text(
                                    size: 8.5,
                                    weight: FontWeight.w900,
                                    color: isOpen
                                        ? HomeDesignTokens.darkOnGold
                                        : HomeDesignTokens.discountTextRed,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              // Centered Store Logo (36x36)
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HomeDesignTokens.logoBg,
                                  border: Border.all(
                                    color: HomeDesignTokens.gold.withValues(
                                      alpha: 0.55,
                                    ),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: logoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: logoUrl,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 120,
                                        placeholder: (_, _) => const Icon(
                                          Icons.storefront_rounded,
                                          size: 16,
                                          color: HomeDesignTokens.gold,
                                        ),
                                        errorWidget: (_, _, _) => const Icon(
                                          Icons.storefront_rounded,
                                          size: 16,
                                          color: HomeDesignTokens.gold,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.storefront_rounded,
                                        size: 16,
                                        color: HomeDesignTokens.gold,
                                      ),
                              ),
                              // Favorite Button (20x20)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  final authStatus = ref.read(
                                    authControllerProvider,
                                  );
                                  if (authStatus != AuthStatus.authenticated) {
                                    AuthPromptDialog.show(context);
                                    return;
                                  }
                                  ref
                                      .read(favoritesProvider.notifier)
                                      .toggleFavorite(vendorId);
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 11,
                                    color: isFav
                                        ? HomeDesignTokens.discountTextRed
                                        : Colors.white.withValues(alpha: 0.85),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: HomeDesignTokens.text(
                                      size: 10.5,
                                      weight: FontWeight.w900,
                                      color: HomeDesignTokens.textPrimary,
                                      height: 1.15,
                                    ),
                                  ),
                                  if (metaText.isNotEmpty) ...[
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 9,
                                          color: HomeDesignTokens.gold,
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            metaText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: HomeDesignTokens.text(
                                              size: 8.5,
                                              weight: FontWeight.w600,
                                              color: HomeDesignTokens.textMuted,
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
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: HomeDesignTokens.gold,
                              ),
                              const SizedBox(width: 1),
                              Text(
                                rating.toStringAsFixed(1),
                                style: HomeDesignTokens.numeric(
                                  size: 9.5,
                                  weight: FontWeight.w800,
                                  color: HomeDesignTokens.gold,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
