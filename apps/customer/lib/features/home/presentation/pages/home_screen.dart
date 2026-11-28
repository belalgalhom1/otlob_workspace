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
import '../widgets/category_icon_image.dart';
import '../widgets/home_design_tokens.dart';
import '../widgets/home_search_results_panel.dart';
import '../widgets/home_suggested_store_card.dart';
import '../widgets/offers_auto_scroller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _searchFieldKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _debouncedSearchQuery = '';

  static const double _refreshTriggerDistance = 54.0;
  static const double _maxPullDistance = 82.0;
  double _pullRefreshOffset = 0.0;
  bool _isRefreshing = false;

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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    final wasFocused = _searchFocusNode.hasFocus;
    if (trimmed.isEmpty) {
      if (_debouncedSearchQuery.isNotEmpty) {
        setState(() => _debouncedSearchQuery = '');
      } else {
        setState(() {});
      }
      if (wasFocused) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_searchFocusNode.hasFocus) {
            _searchFocusNode.requestFocus();
          }
        });
      }
      return;
    }
    setState(() {});
    if (wasFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_searchFocusNode.hasFocus) {
          _searchFocusNode.requestFocus();
        }
      });
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _debouncedSearchQuery = trimmed);
    });
  }

  void _onPullDragUpdate(DragUpdateDetails details) {
    if (_isRefreshing) return;
    final delta = details.delta.dy;
    if (delta > 0 || _pullRefreshOffset > 0) {
      final next = (_pullRefreshOffset + delta * 0.48).clamp(
        0.0,
        _maxPullDistance,
      );
      if (next != _pullRefreshOffset) {
        setState(() => _pullRefreshOffset = next);
      }
    }
  }

  void _onPullDragEnd(DragEndDetails _) {
    if (_isRefreshing) return;
    if (_pullRefreshOffset >= _refreshTriggerDistance) {
      _handleHomeRefresh();
    } else if (_pullRefreshOffset > 0) {
      setState(() => _pullRefreshOffset = 0.0);
    }
  }

  void _onPullDragCancel() {
    if (_isRefreshing) return;
    if (_pullRefreshOffset > 0) {
      setState(() => _pullRefreshOffset = 0.0);
    }
  }

  Future<void> _handleHomeRefresh({bool showHeaderIndicator = true}) async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      if (showHeaderIndicator) {
        _pullRefreshOffset = _refreshTriggerDistance;
      }
    });
    try {
      final authStatus = ref.read(authControllerProvider);
      ref.invalidate(homeControllerProvider);
      await ref.read(homeControllerProvider.future);
      if (authStatus == AuthStatus.authenticated) {
        ref.invalidate(coinHistoryProvider);
        ref.read(inboxCountsProvider.notifier).refresh();
        ref.invalidate(profileProvider);
      }
    } catch (_) {
      // Handled gracefully by provider state if fatal.
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _pullRefreshOffset = 0.0;
        });
      }
    }
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
    _searchDebounce?.cancel();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _promoTimer?.cancel();
    _promoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final homeState = ref.watch(homeControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: palette.bgMain,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              bottom: false,
              child: homeState.when(
                data: (data) => _buildZeroScrollLayout(context, data, palette),
                loading: () => _buildShimmer(),
                error: (error, _) =>
                    _buildError(ErrorUtils.translate(context, error), palette),
              ),
            ),
            homeState.maybeWhen(
              data: (data) => Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(context, data, palette),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroScrollLayout(
    BuildContext context,
    HomeData data,
    HomePalette palette,
  ) {
    final rawQuery = _searchController.text.trim();
    final isSearching = rawQuery.isNotEmpty;
    final searchQuery = rawQuery.toLowerCase();

    final searchFallbackVendors = isSearching
        ? data.products.where((v) {
            return (v['name']?.toString() ?? '').toLowerCase().contains(
                  searchQuery,
                ) ||
                (v['nameAr']?.toString() ?? '').toLowerCase().contains(
                  searchQuery,
                ) ||
                (v['vendor']?.toString() ?? '').toLowerCase().contains(
                  searchQuery,
                );
          }).toList()
        : const <Map<String, dynamic>>[];

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const double bottomNavHeight = 62.0;

    final pullProgress = (_pullRefreshOffset / _refreshTriggerDistance).clamp(
      0.0,
      1.0,
    );

    return Column(
      children: [
        // 0. Fixed Top App Bar (54px) — drag down on header to refresh Home
        GestureDetector(
          key: const ValueKey('home_header_pull_refresh_area'),
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: _onPullDragUpdate,
          onVerticalDragEnd: _onPullDragEnd,
          onVerticalDragCancel: _onPullDragCancel,
          child: _buildHeader(context, palette),
        ),

        // Main Body Container (fills all remaining viewport space, ZERO vertical scroll in browse mode)
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: _pullRefreshOffset == 0
                    ? const Duration(milliseconds: 220)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(
                  0,
                  _pullRefreshOffset * 0.35,
                  0,
                ),
                child: isSearching
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(
                          14,
                          6,
                          14,
                          bottomNavHeight + 4 + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 44.0,
                              child: _buildSearch(palette),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: HomeSearchResultsPanel(
                                query: _debouncedSearchQuery,
                                palette: palette,
                                fallbackVendors: searchFallbackVendors,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportHeight = (constraints.maxHeight -
                                  bottomNavHeight -
                                  4 -
                                  bottomInset -
                                  6)
                              .clamp(420.0, 1200.0);
                          final hasOffers = data.offers.isNotEmpty;
                          final double sectionGap =
                              (viewportHeight * 0.015).clamp(8.0, 12.0);
                          final double searchHeight =
                              viewportHeight >= 540.0 ? 44.0 : 40.0;
                          final double categoriesHeight = hasOffers
                              ? (viewportHeight * 0.132).clamp(70.0, 84.0)
                              : (viewportHeight * 0.144).clamp(74.0, 88.0);
                          final double hotDealsHeight = hasOffers
                              ? (viewportHeight * 0.212).clamp(114.0, 136.0)
                              : 0.0;
                          final double bannerHeight = hasOffers
                              ? (viewportHeight * 0.195).clamp(108.0, 144.0)
                              : (viewportHeight * 0.225).clamp(124.0, 162.0);
                          final double courierHeight = hasOffers
                              ? (viewportHeight * 0.158).clamp(88.0, 114.0)
                              : (viewportHeight * 0.180).clamp(98.0, 128.0);

                          return RefreshIndicator(
                            color: HomeDesignTokens.gold,
                            backgroundColor: palette.cardSurface1,
                            onRefresh: () =>
                                _handleHomeRefresh(showHeaderIndicator: false),
                            child: CustomScrollView(
                              key: const ValueKey('home_body_scroll_view'),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    6,
                                    14,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Section 1: Hero Promotional Carousel
                                        SizedBox(
                                          height: bannerHeight,
                                          child: _buildTopBanners(
                                            context,
                                            data,
                                            palette,
                                          ),
                                        ),
                                        SizedBox(height: sectionGap),

                                        // Section 2: Search Bar
                                        SizedBox(
                                          height: searchHeight,
                                          child: _buildSearch(palette),
                                        ),
                                        SizedBox(height: sectionGap),

                                        // Section 3: Business Types / Categories Row
                                        SizedBox(
                                          height: categoriesHeight,
                                          child: _buildMainCategoryTabs(
                                            data,
                                            palette,
                                          ),
                                        ),
                                        SizedBox(height: sectionGap),

                                        // Section 4: Custom Courier Card
                                        SizedBox(
                                          height: courierHeight,
                                          child: _buildCustomCourierBanner(
                                            courierHeight,
                                            palette,
                                          ),
                                        ),

                                        // Section 5: Hot Deals Carousel
                                        if (hasOffers) ...[
                                          SizedBox(height: sectionGap),
                                          SizedBox(
                                            height: hotDealsHeight,
                                            child: _buildOffersStrip(
                                              data,
                                              palette,
                                            ),
                                          ),
                                        ],

                                        SizedBox(height: sectionGap + 2),
                                        // Section 6 Header: Nearby Vendors
                                        _buildSuggestedStoresHeader(
                                          context,
                                          data,
                                          palette,
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),

                                // Section 6 Grid: 3 Vendor Cards per Row, stacked vertically
                                if (data.products.isEmpty)
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      bottomNavHeight + 18 + bottomInset,
                                    ),
                                    sliver: SliverToBoxAdapter(
                                      child: _buildEmptyStoresCard(
                                        context,
                                        palette,
                                      ),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      bottomNavHeight + 18 + bottomInset,
                                    ),
                                    sliver: SliverGrid(
                                      key: const ValueKey('home_vendors_grid'),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 10,
                                        mainAxisExtent: 144,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final vendor = data.products[index];
                                          return HomeSuggestedStoreCard(
                                            key: ValueKey(
                                              '${_selectedType}_${vendor['id']}',
                                            ),
                                            vendor: vendor,
                                          );
                                        },
                                        childCount: data.products.length,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (_pullRefreshOffset > 2 || _isRefreshing)
                Positioned(
                  top: (_pullRefreshOffset * 0.55 - 12).clamp(4.0, 34.0),
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: _isRefreshing
                            ? 1.0
                            : pullProgress.clamp(0.25, 1.0),
                        child: Container(
                          key: const ValueKey('home_pull_refresh_indicator'),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.cardSurface1,
                            border: Border.all(
                              color: HomeDesignTokens.gold,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: palette.isDark ? 0.45 : 0.14,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isRefreshing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: HomeDesignTokens.gold,
                                  ),
                                )
                              : Transform.rotate(
                                  angle: pullProgress * 6.283185,
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: palette.goldText,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 0. Top Header — ~48px fixed, theme-aware
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, HomePalette palette) {
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

    final authStatus = ref.watch(authControllerProvider);
    final rawAvatar = authStatus == AuthStatus.authenticated
        ? ref.watch(profileProvider.select((p) => p.avatar)).trim()
        : '';
    final avatarUrl = rawAvatar.isNotEmpty
        ? ImageUtils.formatImageUrl(rawAvatar)
        : '';

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: palette.headerBg,
        border: Border(
          bottom: BorderSide(
            color: palette.borderHeader,
            width: 1,
          ),
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Start Side (Right in RTL): User Profile Avatar (if uploaded) else Main App Logo inside circular gold ring (40x40)
            Container(
              key: const ValueKey('home_header_logo'),
              width: 40,
              height: 40,
              padding: avatarUrl.isNotEmpty
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: HomeDesignTokens.gold,
                  width: 1.8,
                ),
              ),
              alignment: Alignment.center,
              child: avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        key: ValueKey('home_header_avatar_$avatarUrl'),
                        imageUrl: avatarUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        placeholder: (_, _) => Padding(
                          padding: const EdgeInsets.all(3),
                          child: Image.asset(
                            'assets/home_logo.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                          ),
                        ),
                        errorWidget: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(3),
                          child: Image.asset(
                            'assets/home_logo.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                  : ClipOval(
                      child: Image.asset(
                        'assets/home_logo.png',
                        key: const ValueKey('home_header_main_logo'),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            const SizedBox(width: 9),

            Expanded(
              child: GestureDetector(
                onTap: () {
                  final authStatus = ref.read(authControllerProvider);
                  if (authStatus == AuthStatus.unauthenticated) {
                    AuthPromptDialog.show(context);
                    return;
                  }
                  _showAddressSelectionBottomSheet(
                    context,
                    ref,
                    activeAddress,
                    palette,
                  );
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
                              size: 12.0,
                              weight: FontWeight.w600,
                              color: palette.textMuted,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.location_on_rounded,
                          color: palette.goldText,
                          size: 12.5,
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
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: palette.textPrimary,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: palette.goldText,
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
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.cardSurface1,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: palette.borderHighlight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$coinBalance',
                          style: HomeDesignTokens.numeric(
                            size: 13.5,
                            weight: FontWeight.w800,
                            color: palette.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: HomeDesignTokens.gold,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.star_rounded,
                            size: 11.5,
                            color: HomeDesignTokens.darkOnGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Chat Icon Button (36x36)
                _buildHeaderIconButton(
                  palette: palette,
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

                // Notification Icon Button (36x36 + 7x7 gold unread dot)
                _buildHeaderIconButton(
                  palette: palette,
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
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required HomePalette palette,
    required IconData icon,
    required bool hasUnread,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: palette.cardSurface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: palette.borderSubtle,
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                size: 18,
                color: palette.textPrimary,
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 7,
                  height: 7,
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
  // 1. Hero Promotional Carousel (flex: 1.35, 118px–148px, radius: 16px)
  // ---------------------------------------------------------------------------
  Widget _buildTopBanners(
    BuildContext context,
    HomeData data,
    HomePalette palette,
  ) {
    final s = AppStrings.of(context);
    final banners = data.promotions
        .where((p) => (p['verticalId']?.toString().trim() ?? '').isEmpty)
        .toList();
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
                                    linkedVendor['nameAr']
                                        .toString()
                                        .isNotEmpty)
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
                                errorWidget: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            // Subtle dark gradient scrim for white text readability in both modes
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
                                8,
                                14,
                                24,
                              ),
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
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: HomeDesignTokens.gold
                                              .withValues(alpha: 0.22),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: HomeDesignTokens.gold
                                                .withValues(alpha: 0.55),
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
                                                  size: 12.0,
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
                                                color:
                                                    HomeDesignTokens.goldLight,
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
                                      const SizedBox(height: 3),
                                    ],
                                    if (title.isNotEmpty)
                                      FractionallySizedBox(
                                        widthFactor: 0.80,
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: HomeDesignTokens.text(
                                            size: 18.5,
                                            weight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1.18,
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
                                      Flexible(
                                        child: FractionallySizedBox(
                                          widthFactor: 0.80,
                                          child: Text(
                                            description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: HomeDesignTokens.text(
                                              size: 13.0,
                                              weight: FontWeight.w600,
                                              color: Colors.white.withValues(
                                                alpha: 0.90,
                                              ),
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
                    },
                  ),

                // 28x28 circular next-slide chevron button at top-end (left in RTL)
                if (totalItems > 1)
                  PositionedDirectional(
                    top: 10,
                    end: 14,
                    child: GestureDetector(
                      onTap: _nextPromoSlide,
                      child: Container(
                        width: 28,
                        height: 28,
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
                          size: 18,
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
                          horizontal: 11,
                          vertical: 5,
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
                                height: 7,
                                width: isSelected ? 18 : 7,
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
  // 2. Search Bar (~44px, radius: 12px, theme-aware)
  // ---------------------------------------------------------------------------
  Widget _buildSearch(HomePalette palette) {
    final s = AppStrings.of(context);
    final isFocused = _searchFocusNode.hasFocus;

    return Container(
      key: _searchFieldKey,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.inputSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? HomeDesignTokens.gold : palette.borderSubtle,
          width: 1,
        ),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: palette.cardShadowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _searchDebounce?.cancel();
                setState(() => _debouncedSearchQuery = value.trim());
              },
              textInputAction: TextInputAction.search,
              textAlign: TextAlign.start,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: HomeDesignTokens.gold,
              style: HomeDesignTokens.text(
                size: 14.5,
                weight: FontWeight.w600,
                color: palette.textPrimary,
                height: 1.2,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: s.searchRestaurant,
                hintStyle: HomeDesignTokens.text(
                  size: 14.5,
                  weight: FontWeight.w600,
                  color: palette.textMuted,
                  height: 1.2,
                ),
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsetsDirectional.only(
                  start: 40,
                  end: _searchController.text.isNotEmpty ? 34 : 12,
                  top: 8,
                  bottom: 8,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
            PositionedDirectional(
              start: 13,
              child: IgnorePointer(
                child: Icon(
                  LucideIcons.search,
                  color: palette.goldText,
                  size: 19,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              PositionedDirectional(
                end: 10,
                child: GestureDetector(
                  onTap: () {
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() => _debouncedSearchQuery = '');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: palette.textMuted,
                    size: 17,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Business Types / Categories Grid (5-col row, gap: 8px, ~48–52px icons)
  // ---------------------------------------------------------------------------
  Widget _buildMainCategoryTabs(HomeData data, HomePalette palette) {
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
              end: i < categories.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.push('/all-vendors', extra: cat['type'] as String);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Square 1:1 Image Card (~48–54px, 100% edge-to-edge image)
                  Expanded(
                    child: Center(
                      child: Transform.scale(
                        scale: isSelected ? 1.03 : 1.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 54,
                            maxHeight: 54,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _buildCategoryImageCard(
                              cat,
                              isSelected,
                              palette,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Category Label below image (13px w900 active / 12.5px w700 inactive)
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.12,
                    child: SizedBox(
                      height: 20,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          name,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: HomeDesignTokens.text(
                            size: isSelected ? 13.0 : 12.5,
                            weight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: palette.textPrimary,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryImageCard(
    Map<String, dynamic> cat,
    bool isSelected,
    HomePalette palette,
  ) {
    final isAll = cat['type'] == 'all';
    final iconUrl = cat['iconUrl']?.toString();
    final hasImage = iconUrl != null && iconUrl.isNotEmpty;

    if (isAll) {
      return Container(
        key: const ValueKey('home_all_category_tile'),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: HomeDesignTokens.gold,
            width: isSelected ? 2.0 : 1.8,
          ),
        ),
        alignment: Alignment.center,
        child: ClipOval(
          child: Image.asset(
            'assets/home_logo.png',
            key: const ValueKey('home_all_main_logo'),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Container(
      key: ValueKey('home_category_tile_${cat['type']}'),
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.zero,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: hasImage
          ? TransparentBgNetworkImage(
              imageUrl: ImageUtils.formatImageUrl(iconUrl),
              mode: BackgroundRemovalMode.black,
              fit: BoxFit.contain,
              maxCacheDimension: 240,
              fallbackBuilder: (_) => Center(
                child: Icon(
                  _getFallbackIconData(cat['type']?.toString() ?? ''),
                  color: palette.goldText,
                  size: 30,
                ),
              ),
            )
          : Center(
              child: Icon(
                _getFallbackIconData(cat['type']?.toString() ?? ''),
                color: palette.goldText,
                size: 30,
              ),
            ),
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
  // 4. Custom Courier Card (flex: 1, ~96px–118px, Dark & Light adaptive)
  // ---------------------------------------------------------------------------
  Widget _buildCustomCourierBanner(double cardHeight, HomePalette palette) {
    final s = AppStrings.of(context);
    final verticalPad = cardHeight >= 108
        ? 9.0
        : (cardHeight >= 96 ? 7.0 : 5.0);
    final imageBoxHeight = (cardHeight - verticalPad * 2).clamp(68.0, 102.0);
    final imageBoxWidth = cardHeight >= 100 ? 140.0 : 124.0;

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
                color: palette.courierShadowColor,
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
                  color: palette.borderCourier,
                  width: 1,
                ),
                gradient: palette.courierGradient,
              ),
              child: InkWell(
                onTap: openCustomDelivery,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    15,
                    verticalPad,
                    9,
                    verticalPad,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Start Column (Right in RTL): Title + 24/7 pill, 2-line Description, CTA button
                      Expanded(
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.12,
                          child: LayoutBuilder(
                            builder: (context, colConstraints) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: Text(
                                            s.customDeliveryBannerTitle,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: HomeDesignTokens.text(
                                              size: 17.5,
                                              weight: FontWeight.w900,
                                              color: palette.courierTitleColor,
                                              height: 1.12,
                                            ),
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
                                          color: palette.courierBadgeBg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: palette.borderCourier,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          '24/7',
                                          style: HomeDesignTokens.numeric(
                                            size: 10.5,
                                            weight: FontWeight.w900,
                                            color: palette.courierBadgeText,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: SizedBox(
                                        width: colConstraints.maxWidth,
                                        child: Text(
                                          s.customDeliveryBannerSub,
                                          maxLines: 2,
                                          softWrap: true,
                                          style: HomeDesignTokens.text(
                                            size: 13.0,
                                            weight: FontWeight.w600,
                                            color: palette.courierSubtitleColor,
                                            height: 1.2,
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
                                          vertical: 4.5,
                                        ),
                                        child: Text(
                                          s.orderNow,
                                          style: HomeDesignTokens.text(
                                            size: 13.0,
                                            weight: FontWeight.w900,
                                            color: HomeDesignTokens.darkOnGold,
                                            height: 1.15,
                                          ),
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

                      const SizedBox(width: 8),

                      // End Column (Left in RTL): Larger bright Image Box inside unchanged outer card
                      Container(
                        width: imageBoxWidth,
                        height: imageBoxHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: palette.borderCourierImage,
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: palette.courierImageFallbackColors,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: fullUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: fullUrl,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                memCacheWidth: 420,
                                placeholder: (_, _) => Center(
                                  child: Icon(
                                    Icons.delivery_dining_rounded,
                                    color: palette.goldText,
                                    size: 32,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.delivery_dining_rounded,
                                    color: palette.goldText,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  color: palette.goldText,
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
  // 5. Hot Deals Section (Horizontal Snap Carousel, ~124px–134px)
  // ---------------------------------------------------------------------------
  Widget _buildOffersStrip(HomeData data, HomePalette palette) {
    final s = AppStrings.of(context);
    if (data.offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  s.hotDeals,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeDesignTokens.text(
                    size: 16.0,
                    weight: FontWeight.w900,
                    color: palette.textPrimary,
                    height: 1.15,
                  ),
                ),
              ),
              if (data.offers.length > 1) ...[
                const SizedBox(width: 8),
                Text(
                  s.isArabic ? 'اسحب للمزيد ←' : 'Swipe for more →',
                  style: HomeDesignTokens.text(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: palette.textMuted,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: OffersAutoScroller(
            offers: data.offers,
            isDark: palette.isDark,
            s: s,
            allVendors: data.products,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Nearby Vendors Section Header & Empty State (paired with 3-col SliverGrid)
  // ---------------------------------------------------------------------------
  Widget _buildSuggestedStoresHeader(
    BuildContext context,
    HomeData data,
    HomePalette palette,
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

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeDesignTokens.text(
                size: 16.0,
                weight: FontWeight.w900,
                color: palette.textPrimary,
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
                size: 13.0,
                weight: FontWeight.w800,
                color: palette.textPrimary,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStoresCard(
    BuildContext context,
    HomePalette palette,
  ) {
    final s = AppStrings.of(context);
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: palette.cardSurface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 22,
            color: palette.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            s.noResults,
            style: HomeDesignTokens.text(
              size: 14.5,
              weight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Fixed Bottom Navigation Bar (62px + blur + theme-aware + real cart badge)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav(
    BuildContext context,
    HomeData data,
    HomePalette palette,
  ) {
    final s = AppStrings.of(context);
    final cartCount = ref.watch(cartProvider.select((c) => c.totalItems));
    final chatUnread = ref.watch(
      inboxCountsProvider.select((c) => c.chatUnread),
    );

    return ClipRect(
      key: const ValueKey('home_bottom_nav'),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: palette.navBg,
            border: Border(
              top: BorderSide(
                color: palette.borderNav,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: SizedBox(
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          palette: palette,
                          index: 0,
                          icon: Icons.home_rounded,
                          label: s.navHome,
                          isSelected: true,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          palette: palette,
                          index: 1,
                          icon: LucideIcons.messageSquare,
                          label: s.navChat,
                          isSelected: false,
                          badgeCount: chatUnread,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          palette: palette,
                          index: 2,
                          icon: LucideIcons.shoppingCart,
                          label: s.cart,
                          isSelected: false,
                          badgeCount: cartCount,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          palette: palette,
                          index: 3,
                          icon: LucideIcons.shoppingBag,
                          label: s.navOrders,
                          isSelected: false,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          palette: palette,
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
      ),
    );
  }

  Widget _buildNavItem({
    required HomePalette palette,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    final iconColor = isSelected ? palette.goldText : palette.textMuted;
    final labelColor = isSelected ? palette.textPrimary : palette.textMuted;

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
              Icon(icon, color: iconColor, size: 22),
              if (badgeCount > 0)
                PositionedDirectional(
                  top: -5,
                  end: -9,
                  child: Container(
                    width: 18,
                    height: 18,
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
                            size: 11,
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
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: HomeDesignTokens.text(
                size: 12.5,
                weight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: labelColor,
                height: 1.12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading, Error, and Address Selection Bottom Sheet (Theme-aware)
  // ---------------------------------------------------------------------------
  Widget _buildError(String message, HomePalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: palette.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: HomeDesignTokens.text(
                size: 14.5,
                weight: FontWeight.w600,
                color: palette.textPrimary,
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
                  size: 14.5,
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
    HomePalette palette,
  ) {
    final s = AppStrings.of(context);
    final profileState = ref.read(profileProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.cardSurface1,
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
                      size: 18,
                      weight: FontWeight.w900,
                      color: palette.textPrimary,
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
                        size: 14.5,
                        color: palette.textMuted,
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
                            ? palette.goldText
                            : palette.textMuted,
                      ),
                      title: Text(
                        addr['label'] ?? s.address,
                        style: HomeDesignTokens.text(
                          size: 15,
                          weight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        addr['address'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HomeDesignTokens.text(
                          size: 13,
                          color: palette.textMuted,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: palette.goldText,
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
                Divider(
                  height: 32,
                  color: palette.borderHeader,
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
                      icon: Icon(
                        Icons.settings_outlined,
                        color: palette.goldText,
                      ),
                      label: Text(
                        s.isArabic ? 'إدارة العناوين' : 'Manage Addresses',
                        style: HomeDesignTokens.text(
                          size: 14.5,
                          weight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: palette.borderSubtle,
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
