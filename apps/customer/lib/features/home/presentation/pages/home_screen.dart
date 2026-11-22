import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';
import 'package:ui_kit/ui_kit.dart' show ExternalActionLauncher;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../chat/presentation/providers/inbox_counts_provider.dart';
import '../../../profile/presentation/providers/coin_history_provider.dart';
import '../../../profile/presentation/providers/delivery_address_provider.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../providers/customer_location_provider.dart';
import '../providers/home_controller.dart';
import '../providers/home_state.dart';
import '../widgets/home_design_tokens.dart';
import '../widgets/home_suggested_store_card.dart';
import '../widgets/offers_auto_scroller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final String _selectedType = 'all';
  bool _isFirstPromoSlide = true;

  late PageController _promoPageController;
  Timer? _promoTimer;
  int _currentPromoPage = 0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _promoPageController = PageController(
      initialPage: _currentPromoPage,
      viewportFraction: 1.0,
    );
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_isFirstPromoSlide) {
        _isFirstPromoSlide = false;
        return;
      }
      if (_promoPageController.hasClients) {
        _currentPromoPage++;
        _promoPageController.animateToPage(
          _currentPromoPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _nextPromoSlide() {
    if (!_promoPageController.hasClients) return;
    _currentPromoPage++;
    _promoPageController.animateToPage(
      _currentPromoPage,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToPromoSlide(int targetIndex, int totalItems) {
    if (!_promoPageController.hasClients || totalItems <= 1) return;
    final currentMod = _currentPromoPage % totalItems;
    final delta = targetIndex - currentMod;
    final nextPage = _currentPromoPage + delta;
    if (nextPage < 0) return;
    _currentPromoPage = nextPage;
    _promoPageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _promoTimer?.cancel();
    _promoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: HomeDesignTokens.bgMain,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              bottom: false,
              child: homeState.when(
                data: (data) => _buildZeroScrollLayout(context, data),
                loading: () => _buildShimmer(),
                error: (error, _) =>
                    _buildError(ErrorUtils.translate(context, error)),
              ),
            ),
            homeState.maybeWhen(
              data: (data) => Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(context, data),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroScrollLayout(BuildContext context, HomeData data) {
    final searchQuery = _searchController.text.toLowerCase();

    final filtered = data.products.where((v) {
      final matchSearch =
          searchQuery.isEmpty ||
          (v['name']?.toString() ?? '').toLowerCase().contains(searchQuery) ||
          (v['nameAr']?.toString() ?? '').toLowerCase().contains(searchQuery) ||
          (v['vendor']?.toString() ?? '').toLowerCase().contains(searchQuery);
      return matchSearch;
    }).toList();

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final responsiveGap = (viewportHeight * 0.01).clamp(6.0, 10.0);

    return Column(
      children: [
        // 1. Fixed Top App Bar (48px)
        _buildHeader(context),

        // 2. Main Body Container (fills all remaining viewport space, ZERO vertical scroll)
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 8, 14, 58 + bottomInset),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final hasOffers = data.offers.isNotEmpty;

                  const double searchHeight = 36.0;
                  const double categoriesHeight = 64.0;
                  final double hotDealsHeight = hasOffers ? 114.0 : 0.0;
                  const double storesHeight = 106.0;

                  final int gapCount = hasOffers ? 5 : 4;
                  final double fixedTotal =
                      searchHeight +
                      categoriesHeight +
                      hotDealsHeight +
                      storesHeight;

                  double remainingForFlex =
                      availableHeight - fixedTotal - (gapCount * responsiveGap);

                  double bannerHeight;
                  double courierHeight;

                  if (remainingForFlex >= 210.0) {
                    // Standard mobile screens (360x800, 390x844, 412x915)
                    bannerHeight = (remainingForFlex * (1.35 / 2.35)).clamp(
                      118.0,
                      148.0,
                    );
                    courierHeight = (remainingForFlex * (1.0 / 2.35)).clamp(
                      92.0,
                      112.0,
                    );
                  } else {
                    // Graceful scale-down on unusually short/split-screen viewports
                    final double safeBudget =
                        (availableHeight - fixedTotal - (gapCount * 4.0)).clamp(
                          120.0,
                          260.0,
                        );
                    bannerHeight = (safeBudget * (1.35 / 2.35)).clamp(
                      72.0,
                      148.0,
                    );
                    courierHeight = (safeBudget * (1.0 / 2.35)).clamp(
                      56.0,
                      112.0,
                    );
                  }

                  // Guarantee zero RenderFlex overflow under any constraint
                  final double totalNeeded =
                      fixedTotal + bannerHeight + courierHeight;
                  if (totalNeeded > availableHeight && availableHeight > 0) {
                    final double excess = totalNeeded - availableHeight;
                    final double bannerShrink = excess * (1.35 / 2.35);
                    final double courierShrink = excess * (1.0 / 2.35);
                    bannerHeight = (bannerHeight - bannerShrink).clamp(
                      64.0,
                      148.0,
                    );
                    courierHeight = (courierHeight - courierShrink).clamp(
                      52.0,
                      112.0,
                    );
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Top Promotional Banner (Carousel)
                      SizedBox(
                        height: bannerHeight,
                        child: _buildTopBanners(context, data),
                      ),

                      // Section 2: Search Bar (36px)
                      SizedBox(
                        height: searchHeight,
                        child: _buildSearch(),
                      ),

                      // Section 3: Services / Categories Grid (~64px, all visible at once)
                      SizedBox(
                        height: categoriesHeight,
                        child: _buildMainCategoryTabs(data),
                      ),

                      // Section 4: Custom Courier Card
                      SizedBox(
                        height: courierHeight,
                        child: _buildCustomCourierBanner(courierHeight),
                      ),

                      // Section 5: Hot Deals (Horizontal Snap Carousel, ~114px)
                      if (hasOffers)
                        SizedBox(
                          height: hotDealsHeight,
                          child: _buildOffersStrip(data),
                        ),

                      // Section 6: Suggested Stores (Horizontal Scroll Row, ~106px)
                      SizedBox(
                        height: storesHeight,
                        child: _buildSuggestedStoresSection(
                          context,
                          data,
                          filtered,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Top App Bar (Header) — 48px fixed
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    final s = AppStrings.of(context);
    final activeAddress = ref.watch(activeDeliveryAddressProvider);
    final effectiveLocation = ref.watch(effectiveCustomerLocationProvider).value;
    final coinBalance = ref.watch(coinHistoryProvider).currentBalance;
    final inboxCounts = ref.watch(inboxCountsProvider);

    String displayAddress;
    if (activeAddress != null &&
        (activeAddress['address'] as String?)?.isNotEmpty == true) {
      displayAddress = activeAddress['address'] as String;
    } else if (effectiveLocation?.isGps == true) {
      displayAddress = s.isArabic ? 'الموقع الحالي' : 'Current Location';
    } else {
      displayAddress = s.addAddress;
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: HomeDesignTokens.bgMain.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(
            color: HomeDesignTokens.borderHeader,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Start Side (Right in RTL): Circular App Logo (36x36) + Address Picker
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeDesignTokens.logoBg,
              border: Border.all(
                color: HomeDesignTokens.gold,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: GestureDetector(
              onTap: () {
                final authStatus = ref.read(authControllerProvider);
                if (authStatus == AuthStatus.unauthenticated) {
                  AuthPromptDialog.show(context);
                  return;
                }
                _showAddressSelectionBottomSheet(context, ref, activeAddress);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          s.deliverTo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeDesignTokens.text(
                            size: 9.5,
                            weight: FontWeight.w600,
                            color: HomeDesignTokens.textMuted,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.location_on_rounded,
                        color: HomeDesignTokens.gold,
                        size: 10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          displayAddress.isEmpty
                              ? s.locationName
                              : displayAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeDesignTokens.text(
                            size: 11.5,
                            weight: FontWeight.w800,
                            color: HomeDesignTokens.textPrimary,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 12,
                        color: HomeDesignTokens.gold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // End Side (Left in RTL, gap: 6px): Coins Pill + Chat + Notifications
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coins Pill
              GestureDetector(
                onTap: () {
                  final authStatus = ref.read(authControllerProvider);
                  if (authStatus == AuthStatus.unauthenticated) {
                    AuthPromptDialog.show(context);
                    return;
                  }
                  context.push('/coin-history');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: HomeDesignTokens.cardSurface1,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: HomeDesignTokens.borderHighlight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$coinBalance',
                        style: HomeDesignTokens.numeric(
                          size: 11,
                          weight: FontWeight.w800,
                          color: HomeDesignTokens.gold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: HomeDesignTokens.gold,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.star_rounded,
                          size: 10,
                          color: HomeDesignTokens.darkOnGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Chat Icon Button (28x28)
              _buildHeaderIconButton(
                icon: LucideIcons.messageSquare,
                hasUnread: inboxCounts.chatUnread > 0,
                onTap: () {
                  final authStatus = ref.read(authControllerProvider);
                  if (authStatus == AuthStatus.unauthenticated) {
                    AuthPromptDialog.show(context);
                    return;
                  }
                  context.push('/inbox');
                },
              ),

              const SizedBox(width: 6),

              // Notification Icon Button (28x28 + 6x6 gold unread dot)
              _buildHeaderIconButton(
                icon: LucideIcons.bell,
                hasUnread: inboxCounts.notificationsUnread > 0,
                onTap: () {
                  final authStatus = ref.read(authControllerProvider);
                  if (authStatus == AuthStatus.unauthenticated) {
                    AuthPromptDialog.show(context);
                    return;
                  }
                  context.push('/notifications');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required bool hasUnread,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: HomeDesignTokens.cardSurface1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: HomeDesignTokens.borderSubtle,
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                size: 14,
                color: HomeDesignTokens.textPrimary,
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: HomeDesignTokens.gold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Section 1 — Top Promotional Banner (Carousel)
  // ---------------------------------------------------------------------------
  Widget _buildTopBanners(BuildContext context, HomeData data) {
    final s = AppStrings.of(context);
    final banners = data.promotions;
    final totalItems = banners.isEmpty ? 1 : (banners.length + 1);

    return Consumer(
      builder: (context, ref, child) {
        final platformSettings = ref.watch(platformSettingsProvider).value;
        final coverUrl = platformSettings?.homeCoverUrl;

        Widget buildCoverSlide() {
          return Stack(
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
              if (coverUrl != null && coverUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: ImageUtils.formatImageUrl(coverUrl),
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Image.asset(
                    'assets/home_cover.jpg',
                    fit: BoxFit.cover,
                  ),
                )
              else
                Image.asset(
                  'assets/home_cover.jpg',
                  fit: BoxFit.cover,
                ),
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: HomeDesignTokens.borderBanner,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
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
                if (banners.isEmpty)
                  buildCoverSlide()
                else
                  PageView.builder(
                    controller: _promoPageController,
                    onPageChanged: (int page) {
                      setState(() => _currentPromoPage = page);
                    },
                    itemBuilder: (context, index) {
                      final actualIndex = index % totalItems;
                      if (actualIndex == 0) {
                        return buildCoverSlide();
                      }

                      final b = banners[actualIndex - 1];
                      final title =
                          (s.isArabic &&
                              b['titleAr'] != null &&
                              b['titleAr'].toString().isNotEmpty)
                          ? b['titleAr'].toString()
                          : (b['title']?.toString() ?? '');
                      final description =
                          (s.isArabic &&
                              b['descriptionAr'] != null &&
                              b['descriptionAr'].toString().isNotEmpty)
                          ? b['descriptionAr'].toString()
                          : (b['description']?.toString() ?? '');

                      final String imageUrl = b['imageUrl']?.toString() ?? '';
                      final String fullUrl = ImageUtils.formatImageUrl(imageUrl);

                      final vendorId = b['vendorId']?.toString();
                      final linkedVendor = vendorId != null
                          ? data.products
                                .where((v) => v['id']?.toString() == vendorId)
                                .firstOrNull
                          : null;

                      final linkedVendorName = linkedVendor != null
                          ? ((s.isArabic &&
                                    linkedVendor['nameAr'] != null &&
                                    linkedVendor['nameAr'].toString().isNotEmpty)
                                ? linkedVendor['nameAr'].toString()
                                : (linkedVendor['name']?.toString() ?? ''))
                          : '';
                      final linkedRating = linkedVendor != null
                          ? (double.tryParse(
                                  linkedVendor['rating']?.toString() ?? '',
                                ) ??
                                0.0)
                          : 0.0;

                      final hasTextOverlay =
                          title.isNotEmpty ||
                          description.isNotEmpty ||
                          linkedVendorName.isNotEmpty;

                      return GestureDetector(
                        onTap: () async {
                          if (b['type'] == 'VENDOR' || b['type'] == 'PRODUCT') {
                            final vId = b['vendorId']?.toString();
                            if (vId != null) {
                              context.push(
                                '/vendor',
                                extra: {
                                  'id': vId,
                                  'name': title,
                                  'productId': b['type'] == 'PRODUCT'
                                      ? b['productId']?.toString()
                                      : null,
                                },
                              );
                            }
                          } else if (b['type'] == 'EXTERNAL_LINK') {
                            final url = b['externalUrl']?.toString();
                            if (url != null && url.isNotEmpty) {
                              await ExternalActionLauncher.openWebUrl(
                                url,
                                context: context,
                              );
                            }
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Fallback dark royal gradient
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
                            // Full-bleed crisp banner image (cover)
                            if (imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: fullUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const SizedBox.shrink(),
                              ),
                            // Subtle RTL dark gradient overlay (start 95% -> center 75% -> end transparent)
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
                            // Inner Content Layout (NO CTA BUTTONS)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                10,
                                14,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (linkedVendorName.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: HomeDesignTokens.gold.withValues(
                                          alpha: 0.20,
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: HomeDesignTokens.borderHighlight,
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
                                                size: 9.5,
                                                weight: FontWeight.w800,
                                                color:
                                                    HomeDesignTokens.goldLight,
                                                height: 1.15,
                                              ),
                                            ),
                                          ),
                                          if (linkedRating > 0) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.star_rounded,
                                              color: HomeDesignTokens.goldLight,
                                              size: 10,
                                            ),
                                            const SizedBox(width: 1),
                                            Text(
                                              linkedRating.toStringAsFixed(1),
                                              style: HomeDesignTokens.numeric(
                                                size: 9,
                                                weight: FontWeight.w800,
                                                color:
                                                    HomeDesignTokens.goldLight,
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
                                      widthFactor: 0.78,
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: HomeDesignTokens.text(
                                          size: 15.5,
                                          weight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.25,
                                          shadows: const [
                                            Shadow(
                                              blurRadius: 8,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    FractionallySizedBox(
                                      widthFactor: 0.78,
                                      child: Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: HomeDesignTokens.text(
                                          size: 10.5,
                                          weight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.90,
                                          ),
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Optional 24x24 circular next-slide button at top-end (left in RTL)
                if (totalItems > 1)
                  PositionedDirectional(
                    top: 10,
                    end: 14,
                    child: GestureDetector(
                      onTap: _nextPromoSlide,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.50),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),

                // Bottom-centered Pagination Dots inside compact dark pill
                if (totalItems > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(totalItems, (index) {
                            final isSelected =
                                (_currentPromoPage % totalItems) == index;
                            return GestureDetector(
                              onTap: () => _jumpToPromoSlide(index, totalItems),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                height: 6,
                                width: isSelected ? 16 : 6,
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
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Section 2 — Search Bar (36px fixed)
  // ---------------------------------------------------------------------------
  Widget _buildSearch() {
    final s = AppStrings.of(context);
    final isFocused = _searchFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 36,
      decoration: BoxDecoration(
        color: HomeDesignTokens.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? HomeDesignTokens.gold
              : HomeDesignTokens.borderSubtle,
          width: 1,
        ),
      ),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          PositionedDirectional(
            start: 12,
            child: IgnorePointer(
              child: const Icon(
                LucideIcons.search,
                color: HomeDesignTokens.gold,
                size: 16,
              ),
            ),
          ),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (_) => setState(() {}),
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: HomeDesignTokens.gold,
            style: HomeDesignTokens.text(
              size: 11.5,
              weight: FontWeight.w600,
              color: HomeDesignTokens.textPrimary,
              height: 1.2,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: s.searchRestaurant,
              hintStyle: HomeDesignTokens.text(
                size: 11.5,
                weight: FontWeight.w600,
                color: HomeDesignTokens.textMuted,
                height: 1.2,
              ),
              filled: false,
              contentPadding: EdgeInsetsDirectional.only(
                start: 36,
                end: _searchController.text.isNotEmpty ? 30 : 12,
                top: 8,
                bottom: 8,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            PositionedDirectional(
              end: 8,
              child: GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {});
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: HomeDesignTokens.textMuted,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Section 3 — Services / Categories Grid (All visible at once, ~64px)
  // ---------------------------------------------------------------------------
  Widget _buildMainCategoryTabs(HomeData data) {
    final s = AppStrings.of(context);
    final categories = data.categories;
    if (categories.isEmpty) return const SizedBox.shrink();

    return Row(
      children: List.generate(categories.length, (i) {
        final cat = categories[i];
        final isSelected = _selectedType == cat['type'];
        final String name =
            (s.isArabic &&
                cat['nameAr'] != null &&
                cat['nameAr'].toString().isNotEmpty)
            ? cat['nameAr'].toString()
            : (cat['name']?.toString() ?? '');

        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: i < categories.length - 1 ? 6 : 0,
            ),
            child: Material(
              color: isSelected
                  ? HomeDesignTokens.gold
                  : HomeDesignTokens.cardSurface1,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  context.push('/all-vendors', extra: cat['type'] as String);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? HomeDesignTokens.goldLight
                          : HomeDesignTokens.borderSubtle,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: HomeDesignTokens.gold.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular 36x36 Icon Badge
                      _buildCategoryIcon(cat, isSelected, categories),
                      const SizedBox(height: 3),
                      // Label
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            name,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: HomeDesignTokens.text(
                              size: isSelected ? 9.5 : 8.8,
                              weight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: isSelected
                                  ? HomeDesignTokens.darkOnGold
                                  : HomeDesignTokens.textPrimary,
                              height: 1.05,
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
      }),
    );
  }

  Widget _buildCategoryIcon(
    Map<String, dynamic> cat,
    bool isSelected,
    List<dynamic> allCategories,
  ) {
    if (isSelected && cat['type'] == 'all') {
      final realCategories = allCategories
          .where((c) => c['type'] != 'all')
          .take(4)
          .toList();

      return Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: HomeDesignTokens.selectedCategoryIconBg.withValues(
            alpha: 0.92,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: realCategories.isEmpty
            ? const Icon(
                Icons.grid_view_rounded,
                color: HomeDesignTokens.gold,
                size: 16,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniCategoryIcon(
                        realCategories[0]['type']?.toString() ?? '',
                        realCategories[0]['iconUrl'],
                      ),
                      if (realCategories.length > 1) ...[
                        const SizedBox(width: 1.5),
                        _buildMiniCategoryIcon(
                          realCategories[1]['type']?.toString() ?? '',
                          realCategories[1]['iconUrl'],
                        ),
                      ],
                    ],
                  ),
                  if (realCategories.length > 2) ...[
                    const SizedBox(height: 1.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniCategoryIcon(
                          realCategories[2]['type']?.toString() ?? '',
                          realCategories[2]['iconUrl'],
                        ),
                        if (realCategories.length > 3) ...[
                          const SizedBox(width: 1.5),
                          _buildMiniCategoryIcon(
                            realCategories[3]['type']?.toString() ?? '',
                            realCategories[3]['iconUrl'],
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
      );
    }

    // 3D-style radial dark circular badge (36x36) with full-bleed circular icon image
    final iconUrl = cat['iconUrl']?.toString();
    final hasImage = iconUrl != null && iconUrl.isNotEmpty;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? null
            : const RadialGradient(
                center: Alignment(-0.4, -0.5),
                radius: 0.85,
                colors: [
                  Color(0xFF34302A),
                  Color(0xFF1A1815),
                  Color(0xFF110F0D),
                ],
                stops: [0.0, 0.70, 1.0],
              ),
        color: isSelected ? HomeDesignTokens.selectedCategoryIconBg : null,
        border: Border.all(
          color: HomeDesignTokens.gold.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: ImageUtils.formatImageUrl(iconUrl),
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                memCacheWidth: 144,
                placeholder: (_, _) => Icon(
                  _getFallbackIconData(cat['type']?.toString() ?? ''),
                  color: HomeDesignTokens.gold,
                  size: 18,
                ),
                errorWidget: (_, _, _) => Icon(
                  _getFallbackIconData(cat['type']?.toString() ?? ''),
                  color: HomeDesignTokens.gold,
                  size: 18,
                ),
              ),
            )
          : Icon(
              _getFallbackIconData(cat['type']?.toString() ?? ''),
              color: HomeDesignTokens.gold,
              size: 18,
            ),
    );
  }

  Widget _buildMiniCategoryIcon(String type, dynamic iconUrl) {
    if (iconUrl != null && iconUrl.toString().isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: ImageUtils.formatImageUrl(iconUrl as String?),
          width: 13.5,
          height: 13.5,
          fit: BoxFit.cover,
          memCacheWidth: 64,
          errorWidget: (_, _, _) => Icon(
            _getFallbackIconData(type),
            color: HomeDesignTokens.gold,
            size: 11,
          ),
        ),
      );
    }
    return Icon(
      _getFallbackIconData(type),
      color: HomeDesignTokens.gold,
      size: 11,
    );
  }

  IconData _getFallbackIconData(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('restaurant')) return Icons.restaurant_rounded;
    if (normalized.contains('pharmacy')) return Icons.healing_rounded;
    if (normalized.contains('supermarket') ||
        normalized.contains('market') ||
        normalized.contains('grocery')) {
      return Icons.shopping_cart_rounded;
    }
    if (normalized.contains('produce') ||
        normalized.contains('fruit') ||
        normalized.contains('veg')) {
      return Icons.eco_rounded;
    }
    return Icons.category_rounded;
  }

  // ---------------------------------------------------------------------------
  // 6. Section 4 — Custom Courier Card (flex: 1, 92px–112px)
  // ---------------------------------------------------------------------------
  Widget _buildCustomCourierBanner(double cardHeight) {
    final s = AppStrings.of(context);
    final verticalPad = cardHeight >= 104 ? 10.0 : 6.0;
    final imageBoxHeight = (cardHeight - verticalPad * 2).clamp(60.0, 78.0);

    return Consumer(
      builder: (context, ref, child) {
        final platformSettings = ref.watch(platformSettingsProvider).value;
        final iconUrl =
            platformSettings?.deliveryBannerIconUrl ??
            platformSettings?.motorcycleIconUrl;
        final String fullUrl =
            (iconUrl != null && iconUrl.isNotEmpty)
                ? ImageUtils.formatImageUrl(iconUrl)
                : '';

        void openCustomDelivery() {
          final authStatus = ref.read(authControllerProvider);
          if (authStatus == AuthStatus.unauthenticated) {
            AuthPromptDialog.show(context);
            return;
          }
          context.push('/custom-delivery');
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: HomeDesignTokens.gold.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: HomeDesignTokens.borderCourier,
                  width: 1,
                ),
                gradient: const RadialGradient(
                  center: Alignment(-0.6, -0.6),
                  radius: 1.35,
                  colors: [
                    HomeDesignTokens.courierGoldGlow,
                    HomeDesignTokens.courierBgMid,
                    HomeDesignTokens.courierBgDark,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: InkWell(
                onTap: openCustomDelivery,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: verticalPad,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Start Column (Right in RTL): Title + 24/7 pill, Description (2 lines, no ellipsis), CTA button
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    s.customDeliveryBannerTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: HomeDesignTokens.text(
                                      size: 14.5,
                                      weight: FontWeight.w900,
                                      color: HomeDesignTokens.gold,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: HomeDesignTokens.gold.withValues(
                                      alpha: 0.20,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: HomeDesignTokens.borderCourier,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '24/7',
                                    style: HomeDesignTokens.numeric(
                                      size: 8.5,
                                      weight: FontWeight.w900,
                                      color: HomeDesignTokens.goldLight,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: SizedBox(
                                  width: MediaQuery.sizeOf(context).width - 178,
                                  child: Text(
                                    s.customDeliveryBannerSub,
                                    maxLines: 2,
                                    softWrap: true,
                                    style: HomeDesignTokens.text(
                                      size: 10.5,
                                      weight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Material(
                              color: HomeDesignTokens.gold,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: openCustomDelivery,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    s.orderNow,
                                    style: HomeDesignTokens.text(
                                      size: 10.5,
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
                      ),

                      const SizedBox(width: 10),

                      // End Column (Left in RTL): Dedicated bright 114x78 Image Box (NO dark dimming overlay)
                      Container(
                        width: 114,
                        height: imageBoxHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: HomeDesignTokens.borderCourierImage,
                            width: 1,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF132945),
                              Color(0xFF0A1424),
                            ],
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: fullUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: fullUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 300,
                                placeholder: (_, _) => const Center(
                                  child: Icon(
                                    Icons.delivery_dining_rounded,
                                    color: HomeDesignTokens.gold,
                                    size: 32,
                                  ),
                                ),
                                errorWidget: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.delivery_dining_rounded,
                                    color: HomeDesignTokens.gold,
                                    size: 32,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  color: HomeDesignTokens.gold,
                                  size: 36,
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
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Section 5 — Hot Deals (Horizontal Snap Carousel, ~114px)
  // ---------------------------------------------------------------------------
  Widget _buildOffersStrip(HomeData data) {
    final s = AppStrings.of(context);
    if (data.offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (margin-bottom: 4px)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                s.hotDeals,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeDesignTokens.text(
                  size: 11.5,
                  weight: FontWeight.w900,
                  color: HomeDesignTokens.textPrimary,
                  height: 1.15,
                ),
              ),
            ),
            if (data.offers.length > 1) ...[
              const SizedBox(width: 8),
              Text(
                s.isArabic ? 'اسحب للمزيد ←' : 'Swipe for more →',
                style: HomeDesignTokens.text(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: HomeDesignTokens.gold,
                  height: 1.15,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        // Snap Carousel
        Expanded(
          child: OffersAutoScroller(
            offers: data.offers,
            isDark: true,
            s: s,
            allVendors: data.products,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Section 6 — Suggested Stores (Horizontal Scroll Row, ~106px)
  // ---------------------------------------------------------------------------
  Widget _buildSuggestedStoresSection(
    BuildContext context,
    HomeData data,
    List<Map<String, dynamic>> filtered,
  ) {
    final s = AppStrings.of(context);

    String label = s.allStores;
    if (_selectedType != 'all') {
      try {
        final selectedCat = data.categories.firstWhere(
          (c) => c['type'] == _selectedType,
        );
        final String catName =
            (s.isArabic && selectedCat['nameAr'] != null)
                ? selectedCat['nameAr'].toString()
                : selectedCat['name'].toString();
        label = '${s.nearbyPrefix}$catName${s.nearbySuffix}';
      } catch (_) {
        label = s.nearbyStores;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (margin-bottom: 4px)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeDesignTokens.text(
                  size: 11.5,
                  weight: FontWeight.w900,
                  color: HomeDesignTokens.textPrimary,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/all-vendors', extra: _selectedType),
              child: Text(
                s.seeAll,
                style: HomeDesignTokens.text(
                  size: 10,
                  weight: FontWeight.w700,
                  color: HomeDesignTokens.gold,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Horizontal Scroll Row
        Expanded(
          child: filtered.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    color: HomeDesignTokens.cardSurface1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HomeDesignTokens.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 20,
                        color: HomeDesignTokens.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.noResults,
                        style: HomeDesignTokens.text(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: HomeDesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final vendor = filtered[index];
                    return HomeSuggestedStoreCard(
                      key: ValueKey('${_selectedType}_${vendor['id']}'),
                      vendor: vendor,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 9. Fixed Bottom Navigation Bar (54px + blur + real cart badge)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav(BuildContext context, HomeData data) {
    final s = AppStrings.of(context);
    final cartCount = ref.watch(cartProvider.select((c) => c.totalItems));
    final chatUnread = ref.watch(
      inboxCountsProvider.select((c) => c.chatUnread),
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            color: HomeDesignTokens.navBg,
            border: Border(
              top: BorderSide(
                color: HomeDesignTokens.borderNav,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        label: s.navHome,
                        isSelected: true,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 1,
                        icon: LucideIcons.messageSquare,
                        label: s.navChat,
                        isSelected: false,
                        badgeCount: chatUnread,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 2,
                        icon: LucideIcons.shoppingCart,
                        label: s.cart,
                        isSelected: false,
                        badgeCount: cartCount,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 3,
                        icon: LucideIcons.shoppingBag,
                        label: s.navOrders,
                        isSelected: false,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 4,
                        icon: LucideIcons.user,
                        label: s.navProfile,
                        isSelected: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    final color = isSelected
        ? HomeDesignTokens.gold
        : HomeDesignTokens.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final authStatus = ref.read(authControllerProvider);
        if (index == 1 || index == 2 || index == 3 || index == 4) {
          if (authStatus == AuthStatus.unauthenticated) {
            AuthPromptDialog.show(context);
            return;
          }
        }

        if (index == 1) context.push('/inbox');
        if (index == 2) context.push('/cart');
        if (index == 3) context.push('/orders');
        if (index == 4) context.push('/profile');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 20),
              if (badgeCount > 0)
                PositionedDirectional(
                  top: -5,
                  end: -8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: HomeDesignTokens.gold,
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: HomeDesignTokens.numeric(
                            size: 9,
                            weight: FontWeight.w900,
                            color: HomeDesignTokens.darkOnGold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: HomeDesignTokens.text(
              size: 10,
              weight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: color,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading, Error, and Address Selection Bottom Sheet (Existing logic intact)
  // ---------------------------------------------------------------------------
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: HomeDesignTokens.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: HomeDesignTokens.text(
                size: 13,
                weight: FontWeight.w600,
                color: HomeDesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(homeControllerProvider);
                ref.invalidate(platformSettingsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeDesignTokens.gold,
                foregroundColor: HomeDesignTokens.darkOnGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppStrings.of(context).retry,
                style: HomeDesignTokens.text(
                  size: 13,
                  weight: FontWeight.w900,
                  color: HomeDesignTokens.darkOnGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return const Center(
      child: CircularProgressIndicator(color: HomeDesignTokens.gold),
    );
  }

  void _showAddressSelectionBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? activeAddress,
  ) {
    final s = AppStrings.of(context);
    final profileState = ref.read(profileProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: HomeDesignTokens.cardSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    s.deliveryAddress,
                    style: HomeDesignTokens.text(
                      size: 16,
                      weight: FontWeight.w900,
                      color: HomeDesignTokens.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (profileState.addresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Text(
                      s.isArabic
                          ? 'لا توجد عناوين محفوظة.'
                          : 'No saved addresses.',
                      style: HomeDesignTokens.text(
                        size: 13,
                        color: HomeDesignTokens.textMuted,
                      ),
                    ),
                  )
                else
                  ...profileState.addresses.map((addr) {
                    final isSelected =
                        activeAddress != null &&
                        addr['id'] == activeAddress['id'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      leading: Icon(
                        addr['label']?.toString().toLowerCase() == 'home'
                            ? Icons.home_rounded
                            : Icons.work_rounded,
                        color: isSelected
                            ? HomeDesignTokens.gold
                            : HomeDesignTokens.textMuted,
                      ),
                      title: Text(
                        addr['label'] ?? s.address,
                        style: HomeDesignTokens.text(
                          size: 13.5,
                          weight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: HomeDesignTokens.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        addr['address'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HomeDesignTokens.text(
                          size: 11.5,
                          color: HomeDesignTokens.textMuted,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: HomeDesignTokens.gold,
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(manualSelectedAddressIdProvider.notifier)
                            .setAddressId(addr['id']);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                const Divider(
                  height: 32,
                  color: HomeDesignTokens.borderHeader,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/addresses');
                      },
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: HomeDesignTokens.gold,
                      ),
                      label: Text(
                        s.isArabic ? 'إدارة العناوين' : 'Manage Addresses',
                        style: HomeDesignTokens.text(
                          size: 13,
                          weight: FontWeight.w800,
                          color: HomeDesignTokens.gold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: HomeDesignTokens.borderSubtle,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
