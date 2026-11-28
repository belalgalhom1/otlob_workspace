import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ui_kit/ui_kit.dart' show ExternalActionLauncher;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';
import 'home_design_tokens.dart';

/// Auto-advancing promotional banner carousel scoped to a specific business type
/// (VendorVertical) on [AllVendorsScreen].
///
/// Mirrors the visual design and tap navigation of the Home hero carousel while
/// rendering nothing when no banners target the current business type.
class VerticalPromoBanners extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final List<Map<String, dynamic>> vendors;
  final double height;

  const VerticalPromoBanners({
    super.key,
    required this.banners,
    required this.vendors,
    this.height = 152,
  });

  @override
  State<VerticalPromoBanners> createState() => _VerticalPromoBannersState();
}

class _VerticalPromoBannersState extends State<VerticalPromoBanners> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _syncAutoScrollTimer();
  }

  @override
  void didUpdateWidget(covariant VerticalPromoBanners oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _syncAutoScrollTimer();
    }
  }

  void _syncAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (widget.banners.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _nextSlide() {
    if (!_pageController.hasClients || widget.banners.length <= 1) return;
    _currentPage++;
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToSlide(int targetIndex) {
    final total = widget.banners.length;
    if (!_pageController.hasClients || total <= 1) return;
    final currentMod = _currentPage % total;
    final delta = targetIndex - currentMod;
    final nextPage = _currentPage + delta;
    if (nextPage < 0) return;
    _currentPage = nextPage;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final palette = HomePalette.of(context);
    final total = widget.banners.length;
    final activeDot = _currentPage % total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: widget.height,
        child: Container(
          key: const ValueKey('vertical_promo_banners_carousel'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: palette.borderBanner,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.cardShadowColor,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: total > 1 ? null : 1,
                  onPageChanged: (page) {
                    if (mounted) setState(() => _currentPage = page);
                  },
                  itemBuilder: (context, index) {
                    final b = widget.banners[index % total];
                    return _buildBannerSlide(context, s, b);
                  },
                ),
                if (total > 1)
                  PositionedDirectional(
                    top: 10,
                    end: 12,
                    child: GestureDetector(
                      onTap: _nextSlide,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.48),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                if (total > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(total, (i) {
                            final isSelected = i == activeDot;
                            return GestureDetector(
                              onTap: () => _jumpToSlide(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                width: isSelected ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? HomeDesignTokens.gold
                                      : Colors.white.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          }),
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

  Widget _buildBannerSlide(
    BuildContext context,
    AppStrings s,
    Map<String, dynamic> b,
  ) {
    final title = (s.isArabic &&
            b['titleAr'] != null &&
            b['titleAr'].toString().trim().isNotEmpty)
        ? b['titleAr'].toString()
        : (b['title']?.toString() ?? '');
    final description = (s.isArabic &&
            b['descriptionAr'] != null &&
            b['descriptionAr'].toString().trim().isNotEmpty)
        ? b['descriptionAr'].toString()
        : (b['description']?.toString() ?? '');
    final imageUrl = b['imageUrl']?.toString() ?? '';
    final fullUrl = ImageUtils.formatImageUrl(imageUrl);

    final vendorId = b['vendorId']?.toString();
    final linkedVendor = vendorId != null
        ? widget.vendors
            .where((v) => v['id']?.toString() == vendorId)
            .firstOrNull
        : null;

    final linkedVendorName = linkedVendor != null
        ? ((s.isArabic &&
                linkedVendor['nameAr'] != null &&
                linkedVendor['nameAr'].toString().trim().isNotEmpty)
            ? linkedVendor['nameAr'].toString()
            : (linkedVendor['name']?.toString() ?? ''))
        : '';
    final linkedRating = linkedVendor != null
        ? (double.tryParse(linkedVendor['rating']?.toString() ?? '') ?? 0.0)
        : 0.0;

    final hasTextOverlay =
        title.isNotEmpty || description.isNotEmpty || linkedVendorName.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        final type = b['type']?.toString();
        if (type == 'VENDOR' || type == 'PRODUCT') {
          final vId = b['vendorId']?.toString();
          if (vId != null && vId.isNotEmpty) {
            context.push(
              '/vendor',
              extra: {
                'id': vId,
                'name': linkedVendorName.isNotEmpty ? linkedVendorName : title,
                'productId':
                    type == 'PRODUCT' ? b['productId']?.toString() : null,
              },
            );
          }
        } else if (type == 'EXTERNAL_LINK') {
          final url = b['externalUrl']?.toString();
          if (url != null && url.isNotEmpty) {
            await ExternalActionLauncher.openWebUrl(url, context: context);
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HomeDesignTokens.bannerFallbackStart,
                  HomeDesignTokens.bannerFallbackMid,
                  HomeDesignTokens.bannerFallbackEnd,
                ],
              ),
            ),
          ),
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: fullUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          if (hasTextOverlay)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    HomeDesignTokens.bannerOverlayStart,
                    HomeDesignTokens.bannerOverlayMid,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.52, 1.0],
                ),
              ),
            ),
          if (hasTextOverlay)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (linkedVendorName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: HomeDesignTokens.gold.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: HomeDesignTokens.gold.withValues(alpha: 0.55),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                linkedVendorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HomeDesignTokens.text(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (linkedRating > 0) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                color: HomeDesignTokens.goldLight,
                                size: 12.5,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                linkedRating.toStringAsFixed(1),
                                style: HomeDesignTokens.numeric(
                                  size: 11.5,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (title.isNotEmpty)
                      FractionallySizedBox(
                        widthFactor: 0.80,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeDesignTokens.text(
                            size: 17.5,
                            weight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.18,
                            shadows: const [
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        child: FractionallySizedBox(
                          widthFactor: 0.80,
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: HomeDesignTokens.text(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.90),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
