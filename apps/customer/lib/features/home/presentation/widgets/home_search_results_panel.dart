import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';
import '../providers/discovery_search_controller.dart';
import 'category_icon_image.dart';
import 'home_design_tokens.dart';

/// Backend-driven product & vendor discovery search results panel rendered
/// directly inside the Home Screen whenever the customer searches for a
/// product or store.
class HomeSearchResultsPanel extends ConsumerWidget {
  const HomeSearchResultsPanel({
    super.key,
    required this.query,
    required this.palette,
    required this.fallbackVendors,
  });

  final String query;
  final HomePalette palette;
  final List<Map<String, dynamic>> fallbackVendors;

  bool _isVendorOpen(Map<String, dynamic> v) {
    final status = v['status']?.toString().toUpperCase();
    final vendorOpen = status == null || status == 'OPEN';
    final closestBranch = v['closestBranch'];
    final branchOpen =
        closestBranch is! Map || closestBranch['isOpen'] != false;
    return vendorOpen && branchOpen;
  }

  String _formatPrice(dynamic rawPrice, String currency) {
    final numVal = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '');
    if (numVal == null) return '';
    final rounded = numVal.roundToDouble();
    final formatted = (numVal - rounded).abs() < 0.005
        ? rounded.toStringAsFixed(0)
        : numVal.toStringAsFixed(2);
    return '$formatted ${currency.trim()}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final isAr = s.isArabic;

    Widget buildSearchingIndicator() {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: HomeDesignTokens.gold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAr
                  ? 'جاري البحث عن المنتجات والمتاجر...'
                  : 'Searching products & stores...',
              style: HomeDesignTokens.text(
                size: 13.0,
                weight: FontWeight.w700,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (query.trim().isEmpty) {
      return buildSearchingIndicator();
    }

    final searchAsync = ref.watch(
      discoverySearchControllerProvider((query: query, verticalId: null)),
    );

    return searchAsync.when(
      loading: buildSearchingIndicator,
      error: (_, _) => _buildResultsBody(
        context,
        s,
        isAr,
        fallbackVendors,
      ),
      data: (results) {
        final effectiveResults = results.isNotEmpty ? results : fallbackVendors;
        return _buildResultsBody(context, s, isAr, effectiveResults);
      },
    );
  }

  Widget _buildResultsBody(
    BuildContext context,
    AppStrings s,
    bool isAr,
    List<Map<String, dynamic>> results,
  ) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.cardSurface1,
                  border: Border.all(color: palette.borderSubtle),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.search_off_rounded,
                  size: 26,
                  color: palette.goldText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.noResults,
                textAlign: TextAlign.center,
                style: HomeDesignTokens.text(
                  size: 15.0,
                  weight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'جرّب البحث باسم منتج أو متجر آخر'
                    : 'Try searching for another product or store',
                textAlign: TextAlign.center,
                style: HomeDesignTokens.text(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalProducts = results.fold<int>(
      0,
      (sum, v) => sum + ((v['matchingProducts'] as List?)?.length ?? 0),
    );

    final summaryBadge = totalProducts > 0
        ? (isAr
              ? '${results.length} متجر • $totalProducts منتج'
              : '${results.length} stores • $totalProducts products')
        : (isAr ? '${results.length} متجر' : '${results.length} stores');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.searchResults,
                style: HomeDesignTokens.text(
                  size: 14.5,
                  weight: FontWeight.w900,
                  color: palette.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.cardSurface1,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.borderSubtle),
                ),
                child: Text(
                  summaryBadge,
                  style: HomeDesignTokens.text(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: 12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildVendorResultCard(
              context,
              s,
              isAr,
              results[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorResultCard(
    BuildContext context,
    AppStrings s,
    bool isAr,
    Map<String, dynamic> vendor,
  ) {
    final matchingProducts = (vendor['matchingProducts'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    final vendorName =
        (isAr &&
            vendor['nameAr'] != null &&
            vendor['nameAr'].toString().trim().isNotEmpty)
        ? vendor['nameAr'].toString().trim()
        : (vendor['name'] ?? vendor['storeName'] ?? '').toString().trim();

    final logoRaw = (vendor['logo'] ?? vendor['image'])?.toString();
    final logoUrl = (logoRaw != null && logoRaw.isNotEmpty)
        ? ImageUtils.thumbnailUrl(logoRaw)
        : '';

    final isOpen = _isVendorOpen(vendor);
    final rating = double.tryParse(vendor['rating']?.toString() ?? '0') ?? 0.0;
    final distanceNum = num.tryParse(vendor['distanceKm']?.toString() ?? '');
    final deliveryTime = isAr
        ? vendor['deliveryTime']?.toString()
        : (vendor['deliveryTimeEn'] ?? vendor['deliveryTime'])?.toString();

    final metaParts = <String>[];
    if (distanceNum != null) {
      metaParts.add(
        isAr
            ? '${distanceNum.toStringAsFixed(1)} كم'
            : '${distanceNum.toStringAsFixed(1)} km',
      );
    }
    if (deliveryTime != null && deliveryTime.isNotEmpty) {
      metaParts.add(deliveryTime);
    }

    return Container(
      key: ValueKey('home_search_vendor_${vendor['id']}'),
      decoration: BoxDecoration(
        color: palette.cardSurface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vendor Header (tappable -> opens vendor screen)
          InkWell(
            onTap: () => context.push('/vendor', extra: vendor),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: Radius.circular(matchingProducts.isEmpty ? 16 : 0),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: palette.cardSurface2,
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            memCacheWidth: 120,
                            errorWidget: (_, _, _) => Icon(
                              Icons.storefront_rounded,
                              size: 20,
                              color: palette.goldText,
                            ),
                          )
                        : Icon(
                            Icons.storefront_rounded,
                            size: 20,
                            color: palette.goldText,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                vendorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HomeDesignTokens.text(
                                  size: 14.5,
                                  weight: FontWeight.w900,
                                  color: palette.textPrimary,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? HomeDesignTokens.gold
                                    : palette.discountBgRed,
                                borderRadius: BorderRadius.circular(999),
                                border: isOpen
                                    ? null
                                    : Border.all(
                                        color: palette.discountBorderRed,
                                        width: 0.8,
                                      ),
                              ),
                              child: Text(
                                isOpen
                                    ? (isAr ? 'مفتوح' : 'Open')
                                    : (isAr ? 'مغلق' : 'Closed'),
                                style: HomeDesignTokens.text(
                                  size: 10.0,
                                  weight: FontWeight.w900,
                                  color: isOpen
                                      ? HomeDesignTokens.darkOnGold
                                      : palette.discountTextRed,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (rating > 0) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: HomeDesignTokens.gold,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: HomeDesignTokens.numeric(
                                  size: 12.0,
                                  weight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              if (metaParts.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: HomeDesignTokens.text(
                                    size: 11.5,
                                    color: palette.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ],
                            if (metaParts.isNotEmpty)
                              Expanded(
                                child: Text(
                                  metaParts.join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HomeDesignTokens.text(
                                    size: 11.5,
                                    weight: FontWeight.w600,
                                    color: palette.textMuted,
                                  ),
                                ),
                              )
                            else if (rating <= 0)
                              Expanded(
                                child: Text(
                                  s.clickToViewMenu,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HomeDesignTokens.text(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Matching Products from this Vendor
          if (matchingProducts.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: palette.borderSubtle.withValues(alpha: 0.6),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                children: [
                  for (var i = 0; i < matchingProducts.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 10,
                        thickness: 0.7,
                        color: palette.borderSubtle.withValues(alpha: 0.45),
                      ),
                    _buildMatchingProductRow(
                      context,
                      s,
                      isAr,
                      vendor,
                      matchingProducts[i],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchingProductRow(
    BuildContext context,
    AppStrings s,
    bool isAr,
    Map<String, dynamic> vendor,
    Map<String, dynamic> product,
  ) {
    final productId = product['id']?.toString();
    final productName =
        (isAr &&
            product['nameAr'] != null &&
            product['nameAr'].toString().trim().isNotEmpty)
        ? product['nameAr'].toString().trim()
        : (product['name'] ?? '').toString().trim();
    final description = (product['description'] ?? '').toString().trim();
    final rawImg = (product['image'] ?? product['imageUrl'])?.toString();
    final imgUrl = (rawImg != null && rawImg.isNotEmpty)
        ? ImageUtils.formatImageUrl(rawImg)
        : '';
    final priceText = _formatPrice(product['price'], s.egp);

    return InkWell(
      key: ValueKey('home_search_product_${productId ?? productName}'),
      onTap: () => context.push(
        '/vendor',
        extra: {
          ...vendor,
          if (productId != null && productId.isNotEmpty) 'productId': productId,
        },
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product thumbnail (background removed transparently)
            SizedBox(
              width: 52,
              height: 52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imgUrl.isNotEmpty
                    ? TransparentBgNetworkImage(
                        imageUrl: imgUrl,
                        mode: BackgroundRemovalMode.autoUniform,
                        fit: BoxFit.contain,
                        width: 52,
                        height: 52,
                        maxCacheDimension: 180,
                        fallbackBuilder: (_) => Center(
                          child: Icon(
                            Icons.fastfood_rounded,
                            size: 22,
                            color: palette.textMuted,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.fastfood_rounded,
                          size: 22,
                          color: palette.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeDesignTokens.text(
                      size: 14.0,
                      weight: FontWeight.w800,
                      color: palette.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeDesignTokens.text(
                        size: 11.5,
                        weight: FontWeight.w500,
                        color: palette.textMuted,
                        height: 1.15,
                      ),
                    ),
                  ],
                  if (priceText.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      priceText,
                      style: HomeDesignTokens.numeric(
                        size: 13.0,
                        weight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: HomeDesignTokens.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isAr ? 'اطلب' : 'Order',
                style: HomeDesignTokens.text(
                  size: 12.0,
                  weight: FontWeight.w900,
                  color: HomeDesignTokens.darkOnGold,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
