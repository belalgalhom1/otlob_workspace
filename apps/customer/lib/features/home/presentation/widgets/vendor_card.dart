import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/favorites_provider.dart';
import 'home_design_tokens.dart';

/// Compact horizontal store row card for business-type browsing screens.
///
/// Gives each store its own clean, scannable horizontal strip (logo + details +
/// favorite action) so many stores are visible on screen at once without losing
/// visual hierarchy or touch-target comfort.
class VendorCard extends ConsumerWidget {
  final Map<String, dynamic> vendor;

  const VendorCard({super.key, required this.vendor});

  Color _tagColor(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('أعلى') || t.contains('highest') || t.contains('top rated')) {
      return Colors.amber.shade700;
    }
    if (t.contains('بريميوم') || t.contains('premium')) {
      return const Color(0xFF7B1FA2);
    }
    if (t.contains('رائج') || t.contains('trending')) {
      return Colors.blue.shade600;
    }
    if (t.contains('جديد') || t.contains('new')) return Colors.teal;
    if (t.contains('عرض') || t.contains('deal') || t.contains('offer')) {
      return Colors.red;
    }
    if (t.contains('صحي') || t.contains('healthy')) {
      return Colors.green.shade600;
    }
    if (t.contains('محلي') || t.contains('local') || t.contains('مفضل')) {
      return AppColors.primary;
    }
    if (t.contains('موثوق') || t.contains('trusted')) return Colors.indigo;
    if (t.contains('طازج') || t.contains('fresh')) return Colors.green.shade700;
    return HomeDesignTokens.gold;
  }

  String? _deliveryLabel(Map<String, dynamic> vendor, bool isAr) {
    final raw = isAr
        ? vendor['deliveryTime']
        : (vendor['deliveryTimeEn'] ?? vendor['deliveryTime']);
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }

    final dist = num.tryParse(vendor['distanceKm']?.toString() ?? '');
    if (dist != null && dist > 0) {
      final baseMin = (15 + dist * 2.5).round();
      final maxMin = baseMin + 10;
      return isAr ? '$baseMin-$maxMin دقيقة' : '$baseMin-$maxMin mins';
    }
    return null;
  }

  String _resolveLogoUrl(Map<String, dynamic> vendor) {
    final logo = vendor['logo']?.toString().trim() ?? '';
    if (logo.isNotEmpty) return logo;
    final image = vendor['image']?.toString().trim() ?? '';
    if (image.isNotEmpty) return image;
    return vendor['coverImage']?.toString().trim() ?? '';
  }

  bool _isClosedVendor(Map<String, dynamic> vendor, String rawTag) {
    final status = vendor['status']?.toString().toUpperCase() ?? '';
    if (status == 'CLOSED' || status == 'BUSY' || status == 'INACTIVE') {
      return true;
    }
    final t = rawTag.trim().toLowerCase();
    return t == 'closed' || t == 'مغلق';
  }

  bool _isStatusTag(String rawTag) {
    final t = rawTag.trim().toLowerCase();
    return t == 'open' || t == 'closed' || t == 'مفتوح' || t == 'مغلق';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HomePalette.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final vendorId = vendor['id']?.toString() ?? '';
    final isFav = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(vendorId)),
    );

    final name = isAr &&
            vendor['nameAr'] != null &&
            vendor['nameAr'].toString().trim().isNotEmpty
        ? vendor['nameAr'].toString().trim()
        : (vendor['name'] ?? vendor['storeName'] ?? '').toString().trim();

    final description = isAr
        ? (vendor['vendorAr'] ??
                vendor['descriptionAr'] ??
                vendor['vendor'] ??
                vendor['description'] ??
                '')
            .toString()
            .trim()
        : (vendor['vendor'] ?? vendor['description'] ?? '').toString().trim();

    final rawTag = (vendor['tag'] as String? ?? '').trim();
    final isClosed = _isClosedVendor(vendor, rawTag);
    final hasExplicitStatus = (vendor['status']?.toString().trim().isNotEmpty ?? false) ||
        _isStatusTag(rawTag);
    final promoTag = _isStatusTag(rawTag) ? '' : rawTag;

    final rating = double.tryParse(vendor['rating']?.toString() ?? '0') ?? 0;
    final ratingCount = int.tryParse(vendor['ratingCount']?.toString() ?? '0') ?? 0;
    final timeLabel = _deliveryLabel(vendor, isAr);
    final distanceNum = num.tryParse(vendor['distanceKm']?.toString() ?? '');
    final logoUrl = _resolveLogoUrl(vendor);

    final statusColor = isClosed ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
    final statusLabel = isClosed
        ? (isAr ? 'مغلق' : 'Closed')
        : (isAr ? 'مفتوح' : 'Open');

    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: palette.borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadowColor,
            blurRadius: palette.isDark ? 10 : 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/vendor', extra: vendor),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Brand logo / thumbnail tile
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: palette.cardSurface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: palette.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: logoUrl.isEmpty
                            ? Icon(
                                Icons.storefront_rounded,
                                size: 28,
                                color: palette.textMuted,
                              )
                            : CachedNetworkImage(
                                imageUrl: ImageUtils.thumbnailUrl(logoUrl),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Center(
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 24,
                                    color: palette.textMuted.withValues(alpha: 0.5),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 26,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (isClosed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Store name, status, rating, time, distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Line 1: Store name + status pill
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HomeDesignTokens.text(
                                size: 15,
                                weight: FontWeight.w800,
                                color: palette.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (hasExplicitStatus) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(
                                  alpha: palette.isDark ? 0.18 : 0.11,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: HomeDesignTokens.text(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: statusColor,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Line 2: Rating + Delivery time + Distance
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (rating > 0 || ratingCount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: HomeDesignTokens.ratingAmber,
                                  size: 14,
                                ),
                                const SizedBox(width: 2.5),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: HomeDesignTokens.numeric(
                                    size: 12,
                                    weight: FontWeight.w800,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                if (ratingCount > 0) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    '($ratingCount)',
                                    style: HomeDesignTokens.numeric(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          if (timeLabel != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12.5,
                                  color: palette.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  timeLabel,
                                  style: HomeDesignTokens.text(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          if (distanceNum != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_outlined,
                                  size: 12,
                                  color: palette.textMuted,
                                ),
                                const SizedBox(width: 2.5),
                                Text(
                                  isAr
                                      ? '${distanceNum.toStringAsFixed(1)} كم'
                                      : '${distanceNum.toStringAsFixed(1)} km',
                                  style: HomeDesignTokens.text(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Line 3 (optional): Promo tag pill or single-line description
                      if (promoTag.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _tagColor(promoTag).withValues(
                              alpha: palette.isDark ? 0.22 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            promoTag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HomeDesignTokens.text(
                              size: 10.5,
                              weight: FontWeight.w800,
                              color: _tagColor(promoTag),
                              height: 1.15,
                            ),
                          ),
                        ),
                      ] else if (description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeDesignTokens.text(
                            size: 11.5,
                            weight: FontWeight.w500,
                            color: palette.textMuted,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Trailing favorite button
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Material(
                    color: palette.cardSurface2,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        final authStatus = ref.read(authControllerProvider);
                        if (authStatus != AuthStatus.authenticated) {
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
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? Colors.red : palette.textMuted,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
