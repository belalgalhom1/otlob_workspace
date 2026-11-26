import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';
import 'category_icon_image.dart';
import 'home_design_tokens.dart';

class OffersAutoScroller extends StatefulWidget {
  final List<Map<String, dynamic>> offers;
  final bool isDark;
  final AppStrings s;
  final List<Map<String, dynamic>> allVendors;

  const OffersAutoScroller({
    super.key,
    required this.offers,
    required this.isDark,
    required this.s,
    required this.allVendors,
  });

  @override
  State<OffersAutoScroller> createState() => _OffersAutoScrollerState();
}

class _OffersAutoScrollerState extends State<OffersAutoScroller> {
  late PageController _controller;
  Timer? _timer;
  late int _page;

  @override
  void initState() {
    super.initState();
    _initPageAndController();
    _startTimer();
  }

  void _initPageAndController() {
    _page = widget.offers.length > 1 ? widget.offers.length * 100 : 0;
    // 0.87 viewportFraction with 10px trailing margin yields ~84% visible card
    // width with the next offer peeking in cleanly from the end edge.
    _controller = PageController(
      viewportFraction: widget.offers.length > 1 ? 0.87 : 1.0,
      initialPage: _page,
    );
  }

  @override
  void didUpdateWidget(OffersAutoScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers.length != widget.offers.length) {
      _controller.dispose();
      _initPageAndController();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.offers.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_controller.hasClients && _controller.page != null) {
        _page = _controller.page!.round() + 1;
        _controller.animateToPage(
          _page,
          duration: const Duration(milliseconds: 700),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();

    final palette = HomePalette.fromBrightness(widget.isDark);
    final isMultiple = widget.offers.length > 1;

    return PageView.builder(
      controller: _controller,
      padEnds: false,
      itemCount: isMultiple ? null : 1,
      onPageChanged: (index) {
        _page = index;
      },
      itemBuilder: (context, index) {
        final offer = widget.offers[index % widget.offers.length];
        return Padding(
          padding: EdgeInsetsDirectional.only(end: isMultiple ? 10 : 0),
          child: _buildOfferCard(context, offer, palette),
        );
      },
    );
  }

  void _openOfferVendor(
    BuildContext context,
    Map<String, dynamic> offer,
    String? vendorId,
    String vendorName,
  ) {
    if (vendorId == null) return;
    context.push(
      '/vendor',
      extra: {
        'id': vendorId,
        'name': vendorName,
        'productId': offer['productId']?.toString(),
        'variantId': offer['variantId']?.toString(),
      },
    );
  }

  Widget _buildOfferCard(
    BuildContext context,
    Map<String, dynamic> offer,
    HomePalette palette,
  ) {
    final isAr = widget.s.isArabic;

    final productName =
        (isAr &&
            offer['productNameAr'] != null &&
            offer['productNameAr'].toString().isNotEmpty)
        ? offer['productNameAr'].toString()
        : (offer['productName']?.toString() ??
              (isAr ? offer['titleAr'] ?? offer['title'] : offer['title']) ??
              '');

    final variantName =
        (isAr &&
            offer['variantNameAr'] != null &&
            offer['variantNameAr'].toString().isNotEmpty)
        ? offer['variantNameAr'].toString()
        : (offer['variantName']?.toString() ?? '');

    final displayTitle = variantName.isNotEmpty
        ? '$productName ($variantName)'
        : productName;

    final vendorName =
        (isAr &&
            offer['vendorStoreNameAr'] != null &&
            offer['vendorStoreNameAr'].toString().isNotEmpty)
        ? offer['vendorStoreNameAr'].toString()
        : (offer['vendorStoreName']?.toString() ?? '');

    final String? rawImageUrl =
        offer['productImageUrl']?.toString().isNotEmpty == true
        ? offer['productImageUrl'].toString()
        : offer['imageUrl']?.toString();
    final String imageUrl =
        rawImageUrl != null ? ImageUtils.formatImageUrl(rawImageUrl) : '';

    final double? offerPrice =
        _toDouble(offer['offerPrice']) ?? _toDouble(offer['productBasePrice']);
    final double? originalPrice =
        _toDouble(offer['originalPrice']) ??
        _toDouble(offer['productComparePrice']);

    final vendorId = offer['vendorId']?.toString();
    final vendorObj = widget.allVendors
        .where((v) => v['id']?.toString() == vendorId)
        .firstOrNull;
    final double? vendorRating = vendorObj != null
        ? double.tryParse(vendorObj['rating']?.toString() ?? '')
        : null;

    final hasDiscount =
        offerPrice != null &&
        originalPrice != null &&
        originalPrice > offerPrice;

    return GestureDetector(
      onTap: () => _openOfferVendor(context, offer, vendorId, vendorName),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.hotDealGradientColors,
          ),
          border: Border.all(
            color: palette.borderHotDeal,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image Container (Start / Right in RTL): 106px wide, fills card height
              SizedBox(
                width: 106,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        TransparentBgNetworkImage(
                          imageUrl: imageUrl,
                          mode: BackgroundRemovalMode.autoUniform,
                          fit: BoxFit.contain,
                          maxCacheDimension: 300,
                          placeholderBuilder: (_) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: HomeDesignTokens.gold,
                              ),
                            ),
                          ),
                          fallbackBuilder: (_) => Center(
                            child: Icon(
                              Icons.local_offer_rounded,
                              color: palette.goldText,
                              size: 30,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: palette.goldText,
                            size: 30,
                          ),
                        ),
                      // Red Offer Badge at Top-Start (Top-Right in RTL)
                      PositionedDirectional(
                        top: 5,
                        start: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: HomeDesignTokens.offerBadgeRed,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.30),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 10.5,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.s.offerBadge,
                                style: HomeDesignTokens.text(
                                  size: 9.0,
                                  weight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Details Column (End / Left in RTL): fills card height cleanly, space-between
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Store name + Star rating, followed by 1-line Product title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                vendorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HomeDesignTokens.text(
                                  size: 11.0,
                                  weight: FontWeight.w800,
                                  color: palette.textMuted,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (vendorRating != null && vendorRating > 0) ...[
                              const SizedBox(width: 4),
                              _buildRatingRow(vendorRating, palette),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeDesignTokens.text(
                            size: 13.5,
                            weight: FontWeight.w900,
                            color: palette.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Prices + Discount pill + Gold Order button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (offerPrice != null)
                                  Text(
                                    '${offerPrice.toStringAsFixed(0)} ${widget.s.egp}',
                                    style: HomeDesignTokens.numeric(
                                      size: 14.0,
                                      weight: FontWeight.w900,
                                      color: palette.textPrimary,
                                      height: 1.0,
                                    ),
                                  ),
                                if (hasDiscount) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    originalPrice.toStringAsFixed(0),
                                    style: HomeDesignTokens.numeric(
                                      size: 11.0,
                                      weight: FontWeight.w600,
                                      color: palette.textMuted,
                                      height: 1.0,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: palette.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  _buildDiscountBadge(
                                    offerPrice,
                                    originalPrice,
                                    palette,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: HomeDesignTokens.gold,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _openOfferVendor(
                              context,
                              offer,
                              vendorId,
                              vendorName,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              child: Text(
                                isAr ? 'اطلب' : 'Order',
                                style: HomeDesignTokens.text(
                                  size: 12.0,
                                  weight: FontWeight.w900,
                                  color: HomeDesignTokens.darkOnGold,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(double rating, HomePalette palette) {
    final fullStars = rating.floor().clamp(0, 5);
    final hasHalf = (rating - fullStars) >= 0.5 && fullStars < 5;
    final emptyStarColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.14);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < fullStars) {
            return const Icon(
              Icons.star_rounded,
              color: HomeDesignTokens.ratingAmber,
              size: 11.0,
            );
          }
          if (i == fullStars && hasHalf) {
            return const Icon(
              Icons.star_half_rounded,
              color: HomeDesignTokens.ratingAmber,
              size: 11.0,
            );
          }
          return Icon(
            Icons.star_rounded,
            color: emptyStarColor,
            size: 11.0,
          );
        }),
      ],
    );
  }

  Widget _buildDiscountBadge(
    double offer,
    double original,
    HomePalette palette,
  ) {
    final pct = (((original - offer) / original) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: palette.discountBgRed,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: palette.discountBorderRed,
          width: 0.8,
        ),
      ),
      child: Text(
        '-$pct%',
        style: HomeDesignTokens.numeric(
          size: 10.0,
          weight: FontWeight.w800,
          color: palette.discountTextRed,
          height: 1.0,
        ),
      ),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
