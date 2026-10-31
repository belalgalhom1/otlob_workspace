import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';

class OffersAutoScroller extends StatefulWidget {
  final List<Map<String, dynamic>> offers;
  final bool isDark;
  final AppStrings s;
  final List<Map<String, dynamic>> allVendors;

  const OffersAutoScroller({super.key, 
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
    _page = widget.offers.isNotEmpty ? widget.offers.length * 100 : 0;
    _controller = PageController(viewportFraction: 0.85, initialPage: _page);
  }

  @override
  void didUpdateWidget(OffersAutoScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers.length != widget.offers.length) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.offers.length <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_controller.hasClients && _controller.page != null) {
        setState(() {
          _page = _controller.page!.round() + 1;
        });
        _controller.animateToPage(
          _page,
          duration: const Duration(milliseconds: 800),
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
    
    return PageView.builder(
      controller: _controller,
      onPageChanged: (index) {
        setState(() => _page = index);
      },
      itemBuilder: (context, index) {
        final offer = widget.offers[index % widget.offers.length];
        return _buildOfferCard(context, offer);
      },
    );
  }

  Widget _buildOfferCard(BuildContext context, Map<String, dynamic> offer) {
    final isAr = widget.s.isArabic;

    final productName = (isAr && offer['productNameAr'] != null && offer['productNameAr'].toString().isNotEmpty)
        ? offer['productNameAr'].toString()
        : (offer['productName']?.toString() ?? (isAr ? offer['titleAr'] ?? offer['title'] : offer['title']) ?? '');

    final variantName = (isAr && offer['variantNameAr'] != null && offer['variantNameAr'].toString().isNotEmpty)
        ? offer['variantNameAr'].toString()
        : (offer['variantName']?.toString() ?? '');

    final displayTitle = variantName.isNotEmpty
        ? '$productName ($variantName)'
        : productName;

    final vendorName = (isAr && offer['vendorStoreNameAr'] != null && offer['vendorStoreNameAr'].toString().isNotEmpty)
        ? offer['vendorStoreNameAr'].toString()
        : (offer['vendorStoreName']?.toString() ?? '');

    final String? rawImageUrl = offer['productImageUrl']?.toString().isNotEmpty == true
        ? offer['productImageUrl'].toString()
        : offer['imageUrl']?.toString();
    final String imageUrl = rawImageUrl != null ? ImageUtils.formatImageUrl(rawImageUrl) : '';

    // Price resolution: use explicit offer/original if set, else use product prices
    final double? offerPrice = _toDouble(offer['offerPrice']) ?? _toDouble(offer['productBasePrice']);
    final double? originalPrice = _toDouble(offer['originalPrice']) ?? _toDouble(offer['productComparePrice']);

    final vendorId = offer['vendorId']?.toString();
    final vendorList = widget.allVendors.where((v) => v['id']?.toString() == vendorId).toList();
    final Map<String, dynamic>? vendorObj = vendorList.isNotEmpty ? vendorList.first : null;

    return GestureDetector(
      onTap: () {
        if (vendorId != null) {
          context.push('/vendor', extra: {
            'id': vendorId,
            'name': vendorName,
            'productId': offer['productId']?.toString(),
            'variantId': offer['variantId']?.toString(),
          });
        }
      },
      child: Container(
        margin: const EdgeInsetsDirectional.only(start: 16, end: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: widget.isDark ? const Color(0xFF18181B) : Colors.white,
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image — full top section with ambient glow
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: widget.isDark ? const Color(0xFF101012) : const Color(0xFFF4F4F5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ambient blurred backdrop: eliminates harsh cutoffs/letterboxing
                      if (imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: ClipRect(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                              child: Transform.scale(
                                scale: 1.35,
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 200,
                                  color: (widget.isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                                  colorBlendMode: widget.isDark ? BlendMode.darken : BlendMode.lighten,
                                  errorWidget: (_, _, _) => const SizedBox(),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Gradient overlay for smooth transition into card
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
                                Colors.transparent,
                                (widget.isDark ? const Color(0xFF18181B) : Colors.white).withValues(alpha: 0.85),
                                widget.isDark ? const Color(0xFF18181B) : Colors.white,
                              ],
                              stops: const [0.0, 0.4, 0.88, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Hero crisp foreground image
                      if (imageUrl.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              memCacheWidth: 600,
                              placeholder: (_, _) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (_, _, _) => const Icon(
                                Icons.image_not_supported_rounded, 
                                color: Colors.grey, 
                                size: 40,
                              ),
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 48),
                        ),

                      // OFFER badge
                      PositionedDirectional(
                        top: 12,
                        start: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                widget.s.offerBadge.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
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
              // Bottom info section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vendorName.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded, color: AppColors.primary, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vendorName,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (vendorObj != null) ...[
                            const SizedBox(width: 8),
                            Builder(builder: (context) {
                              double rating = double.tryParse(vendorObj['rating']?.toString() ?? '0') ?? 0;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (index) {
                                  if (index < rating.floor()) {
                                    return const Icon(Icons.star_rounded, color: Colors.amber, size: 14);
                                  } else if (index < rating) {
                                    return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 14);
                                  } else {
                                    return Icon(Icons.star_rounded, color: widget.isDark ? Colors.white12 : Colors.grey.shade300, size: 14);
                                  }
                                }),
                              );
                            }),
                          ],
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      displayTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: widget.isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (offerPrice != null)
                                Text(
                                  '${offerPrice.toStringAsFixed(0)}${widget.s.egp}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              if (offerPrice != null && originalPrice != null && originalPrice > offerPrice) ...[
                                Text(
                                  '${originalPrice.toStringAsFixed(0)}${widget.s.egp}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDark ? Colors.white : Colors.black54,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                    decorationColor: Colors.red.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                _buildDiscountBadge(offerPrice, originalPrice),
                              ],
                            ],
                          ),
                        ),
                        // Order Button
                        ElevatedButton(
                          onPressed: () {
                            if (vendorId != null) {
                              context.push('/vendor', extra: {
                                'id': vendorId,
                                'name': vendorName,
                                'productId': offer['productId']?.toString(),
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(60, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          child: Text(
                            widget.s.isArabic ? 'اطلب' : 'Order',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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

  Widget _buildDiscountBadge(double offer, double original) {
    final pct = (((original - offer) / original) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: widget.isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: widget.isDark ? 0.45 : 0.25),
        ),
      ),
      child: Text(
        '-$pct%',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFFEF4444),
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
