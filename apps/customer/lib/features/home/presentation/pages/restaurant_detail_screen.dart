import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';
import 'package:ui_kit/ui_kit.dart' show AppExpandableText;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../../core/widgets/custom_chat_icon.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../providers/favorites_provider.dart';
import '../providers/vendor_detail_controller.dart';
import '../widgets/category_icon_image.dart';
import '../widgets/fly_to_cart_animation.dart';
import '../widgets/product_bottom_sheet.dart';
import '../widgets/store_detail_tokens.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;
  const VendorDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _selectedUnit = 'package';
  bool _initialProductShown = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _menuScrollController = ScrollController();

  final GlobalKey _cartAnchorKey = GlobalKey();
  final ValueNotifier<int> _cartLandPulse = ValueNotifier<int>(0);
  final Map<String, GlobalKey> _categoryTileKeys = {};
  final Map<String, GlobalKey> _productThumbKeys = {};

  bool _showCatStartFade = false;
  bool _showCatEndFade = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _categoryScrollController.addListener(_updateCategoryEdgeFades);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCategoryEdgeFades();
      final closestBranch = widget.restaurant['_proximity']?['closestBranch'];
      final closestBranchId =
          closestBranch?['id']?.toString() ??
          widget.restaurant['branchId']?.toString();
      final vendorId = widget.restaurant['id']?.toString() ?? '';
      if (closestBranchId != null && vendorId.isNotEmpty && mounted) {
        ref.read(selectedBranchProvider.notifier).selectBranchById(
          vendorId,
          closestBranchId,
          name: closestBranch?['name']?.toString(),
          nameAr: closestBranch?['nameAr']?.toString(),
          address: closestBranch?['address']?.toString(),
        );
      }
    });
  }

  void _onSearchFocusChange() {
    if (mounted) setState(() {});
  }

  void _updateCategoryEdgeFades() {
    if (!_categoryScrollController.hasClients || !mounted) return;
    final pos = _categoryScrollController.position;
    if (!pos.hasContentDimensions) return;
    final showStart = pos.pixels > 4.0;
    final showEnd = pos.maxScrollExtent - pos.pixels > 4.0;
    if (showStart != _showCatStartFade || showEnd != _showCatEndFade) {
      setState(() {
        _showCatStartFade = showStart;
        _showCatEndFade = showEnd;
      });
    }
  }

  GlobalKey _keyForCategory(String catId) =>
      _categoryTileKeys.putIfAbsent(catId, () => GlobalKey());

  GlobalKey _keyForProductThumb(String productId) =>
      _productThumbKeys.putIfAbsent(productId, () => GlobalKey());

  Rect? _measureRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final renderBox = ctx.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return null;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    return topLeft & renderBox.size;
  }

  Rect _resolveCartDestinationRect() {
    final liveRect = _measureRect(_cartAnchorKey);
    if (liveRect != null && !liveRect.isEmpty) {
      return liveRect;
    }
    return FloatingCartOverlay.defaultParkedRect(
      MediaQuery.sizeOf(context),
      MediaQuery.paddingOf(context),
    );
  }

  void _launchFlyToCart({
    required Rect? srcRect,
    required String? imageUrl,
  }) {
    if (!mounted) return;
    final dstRect = _resolveCartDestinationRect();
    if (srcRect == null || srcRect.isEmpty) {
      _cartLandPulse.value++;
      return;
    }
    launchFlyToCartAnimation(
      context: context,
      srcRect: srcRect,
      dstRect: dstRect,
      imageUrl: imageUrl,
      onLanded: () {
        if (mounted) {
          _cartLandPulse.value++;
        }
      },
    );
  }

  void _selectCategory(String catId) {
    setState(() => _selectedCategory = catId);

    // Smoothly auto-center the tapped category tile horizontally.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tileCtx = _categoryTileKeys[catId]?.currentContext;
      if (tileCtx != null) {
        Scrollable.ensureVisible(
          tileCtx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
      _updateCategoryEdgeFades();
    });
  }

  List<Map<String, dynamic>> _filterMenuItems(
    List<dynamic> allMenu,
    bool isAr,
  ) {
    final categoryFiltered = allMenu
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(
          (map) =>
              _selectedCategory == 'all' ||
              map['category']?.toString() == _selectedCategory ||
              map['categoryId']?.toString() == _selectedCategory,
        )
        .toList();

    final normalizedQuery = normalizeMenuSearchText(_searchQuery);
    if (normalizedQuery.isEmpty) return categoryFiltered;

    // Strict name-only search (never matches descriptions) with Arabic normalization.
    final exactMatches = <Map<String, dynamic>>[];
    final partialMatches = <Map<String, dynamic>>[];

    for (final item in categoryFiltered) {
      final rawPrimary = (isAr
              ? (item['nameAr'] ?? item['name'] ?? '')
              : (item['name'] ?? item['nameAr'] ?? ''))
          .toString();
      final rawSecondary = (isAr
              ? (item['name'] ?? '')
              : (item['nameAr'] ?? ''))
          .toString();

      final normPrimary = normalizeMenuSearchText(rawPrimary);
      final normSecondary = normalizeMenuSearchText(rawSecondary);

      if (normPrimary == normalizedQuery ||
          (normSecondary.isNotEmpty && normSecondary == normalizedQuery)) {
        exactMatches.add(item);
      } else if (normPrimary.contains(normalizedQuery) ||
          (normSecondary.isNotEmpty &&
              normSecondary.contains(normalizedQuery))) {
        partialMatches.add(item);
      }
    }

    // If an exact product name match exists, show only the exact match(es).
    return exactMatches.isNotEmpty ? exactMatches : partialMatches;
  }

  void _showBranchSelector(
    BuildContext context,
    List<dynamic> branches,
    String vendorId,
    bool isAr,
    StoreDetailPalette palette,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentSelected = ref.read(selectedBranchProvider)[vendorId]?.id;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textMuted.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isAr ? 'اختر الفرع المناسب' : 'Select Branch',
                  style: StoreDetailPalette.text(
                    size: 16,
                    weight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...branches.map((b) {
                  if (b is! Map) return const SizedBox.shrink();
                  final bId = b['id']?.toString() ?? '';
                  final bName = (isAr
                          ? (b['nameAr'] ?? b['name'])
                          : (b['name'] ?? b['nameAr']))
                      ?.toString() ??
                      (isAr ? 'الفرع' : 'Branch');
                  final bAddress = b['address']?.toString() ?? '';
                  final isSelected = bId == currentSelected;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.gold.withValues(alpha: 0.15)
                          : palette.bgCard2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? palette.gold : palette.borderGold,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: isSelected ? palette.gold : palette.textMuted,
                      ),
                      title: Text(
                        bName,
                        style: StoreDetailPalette.text(
                          size: 13,
                          weight:
                              isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      subtitle: bAddress.isNotEmpty
                          ? Text(
                              bAddress,
                              style: StoreDetailPalette.text(
                                size: 11,
                                weight: FontWeight.w600,
                                color: palette.textMuted,
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(
                              LucideIcons.check,
                              size: 16,
                              color: palette.gold,
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(selectedBranchProvider.notifier)
                            .selectBranchById(
                              vendorId,
                              bId,
                              name: b['name']?.toString(),
                              nameAr: b['nameAr']?.toString(),
                              address: b['address']?.toString(),
                            );
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWorkingHoursSheet(
    BuildContext context,
    List<dynamic> workingHours,
    bool isAr,
    bool isOpen,
    StoreDetailPalette palette,
  ) {
    if (workingHours.isEmpty) return;

    final now = DateTime.now();
    final todayDay = now.weekday % 7;

    String getDayName(int day) {
      switch (day) {
        case 0:
          return isAr ? 'الأحد' : 'Sunday';
        case 1:
          return isAr ? 'الإثنين' : 'Monday';
        case 2:
          return isAr ? 'الثلاثاء' : 'Tuesday';
        case 3:
          return isAr ? 'الأربعاء' : 'Wednesday';
        case 4:
          return isAr ? 'الخميس' : 'Thursday';
        case 5:
          return isAr ? 'الجمعة' : 'Friday';
        case 6:
          return isAr ? 'السبت' : 'Saturday';
        default:
          return '';
      }
    }

    String formatTimeTo12Hour(String timeStr) {
      try {
        final parts = timeStr.split(':');
        if (parts.length < 2) return timeStr;
        final hour = int.tryParse(parts[0]) ?? 0;
        final min = int.tryParse(parts[1]) ?? 0;
        final period =
            hour >= 12 ? (isAr ? 'م' : 'PM') : (isAr ? 'ص' : 'AM');
        var displayHour = hour % 12;
        if (displayHour == 0) displayHour = 12;
        return '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
      } catch (_) {
        return timeStr;
      }
    }

    final sortedHours = List<dynamic>.from(workingHours);
    sortedHours.sort((a, b) {
      final dayA = int.tryParse(a['day'].toString()) ?? 0;
      final dayB = int.tryParse(b['day'].toString()) ?? 0;
      const order = [6, 0, 1, 2, 3, 4, 5];
      return order.indexOf(dayA).compareTo(order.indexOf(dayB));
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textMuted.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendarClock,
                      size: 18,
                      color: isOpen ? palette.gold : const Color(0xFFF87171),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'ساعات العمل الأسبوعية' : 'Weekly Working Hours',
                      style: StoreDetailPalette.text(
                        size: 15,
                        weight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sortedHours.map((item) {
                  final day = int.tryParse(item['day'].toString()) ?? 0;
                  final isClosed = item['isClosed'] as bool? ?? false;
                  final openTime = item['openTime'] as String? ?? '09:00';
                  final closeTime = item['closeTime'] as String? ?? '22:00';
                  final isToday = day == todayDay;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getDayName(day),
                          style: StoreDetailPalette.text(
                            size: 12.5,
                            weight: isToday ? FontWeight.w900 : FontWeight.w600,
                            color: isToday
                                ? palette.goldText
                                : palette.textPrimary,
                          ),
                        ),
                        if (isClosed)
                          Text(
                            isAr ? 'إجازة' : 'Closed',
                            style: StoreDetailPalette.text(
                              size: 11.5,
                              weight: FontWeight.w800,
                              color: const Color(0xFFF87171),
                            ),
                          )
                        else
                          Text(
                            '${formatTimeTo12Hour(openTime)} - ${formatTimeTo12Hour(closeTime)}',
                            style: StoreDetailPalette.numeric(
                              size: 12,
                              weight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday
                                  ? palette.goldText
                                  : palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _categoryScrollController.removeListener(_updateCategoryEdgeFades);
    _categoryScrollController.dispose();
    _menuScrollController.dispose();
    _cartLandPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final palette = StoreDetailPalette.of(context);
    final isDark = palette.isDark;
    final cartState = ref.watch(cartProvider);

    final vendorId = widget.restaurant['id']?.toString() ?? '';
    final detailAsync = ref.watch(vendorDetailControllerProvider(vendorId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.systemOverlayStyle,
      child: detailAsync.when(
        data: (fullVendor) {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          final typeStr = fullVendor['type']?.toString().toLowerCase() ?? '';
          final vendorSlug = fullVendor['slug']?.toString().toLowerCase() ?? '';
          final vendorNameLower =
              fullVendor['name']?.toString().toLowerCase() ?? '';
          final isPharmacy = typeStr.contains('pharmacy') ||
              typeStr.contains('pharmacies-') ||
              typeStr.contains('صيدلي') ||
              typeStr.contains('صيدليات') ||
              typeStr.contains('medical') ||
              typeStr.contains('medicine') ||
              typeStr.contains('pharma') ||
              vendorSlug.contains('pharmacy') ||
              vendorSlug.contains('صيدلي') ||
              vendorSlug.contains('صيدليات') ||
              vendorNameLower.contains('pharmacy') ||
              vendorNameLower.contains('صيدلي') ||
              vendorNameLower.contains('صيدليات');

          final allMenu = (fullVendor['menu'] as List<dynamic>?) ?? const [];
          final categories =
              (fullVendor['categories'] as List<dynamic>?) ?? const [];
          final workingHours =
              (fullVendor['workingHours'] as List<dynamic>?) ?? const [];
          final branches =
              (fullVendor['branches'] as List<dynamic>?) ?? const [];

          final resolvedVendorId =
              fullVendor['id']?.toString() ?? vendorId;
          final activeBranchId =
              ref.watch(selectedBranchProvider)[resolvedVendorId]?.id;
          final currentBranch = branches
                  .where((b) => b is Map && b['id']?.toString() == activeBranchId)
                  .firstOrNull as Map? ??
              (fullVendor['closestBranch'] is Map
                  ? fullVendor['closestBranch'] as Map
                  : null) ??
              (branches.isNotEmpty && branches.first is Map
                  ? branches.first as Map
                  : null);

          final vendorStatusOpen = fullVendor['status'] == null ||
              fullVendor['status'].toString().toUpperCase() == 'OPEN';
          final branchOpen =
              currentBranch == null || currentBranch['isOpen'] != false;
          // Backend is the single source of truth for store open/closed status.
          final isOpen = vendorStatusOpen && branchOpen;

          // Schedule edge fade check once categories layout settles.
          if (categories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateCategoryEdgeFades(),
            );
          }

          final initialProductId = widget.restaurant['productId'];
          final initialVariantId = widget.restaurant['variantId']?.toString();
          if (!_initialProductShown &&
              initialProductId != null &&
              allMenu.isNotEmpty) {
            final item = allMenu
                .where(
                  (i) => i['id']?.toString() == initialProductId.toString(),
                )
                .firstOrNull;
            if (item != null) {
              _initialProductShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && isOpen) {
                  _showProductBottomSheet(
                    context,
                    ref,
                    Map<String, dynamic>.from(item as Map),
                    ref.read(cartProvider),
                    s,
                    isDark,
                    isPharmacy,
                    initialVariantId: initialVariantId,
                  );
                }
              });
            }
          }

          final filteredMenu = _filterMenuItems(allMenu, isAr);

          final storeName = (isAr &&
                      fullVendor['nameAr'] != null &&
                      fullVendor['nameAr'].toString().isNotEmpty
                  ? fullVendor['nameAr']
                  : (fullVendor['name'] ?? fullVendor['storeName'] ?? ''))
              .toString();
          final description = (isAr &&
                      fullVendor['vendorAr'] != null &&
                      fullVendor['vendorAr'].toString().isNotEmpty
                  ? fullVendor['vendorAr']
                  : (fullVendor['vendor'] ?? fullVendor['description'] ?? ''))
              .toString();

          final bottomInset = MediaQuery.paddingOf(context).bottom;

          // A. Unified Full-Page Scrollable Store View (Banner + Info + Categories + 3-Col Product Grid)
          return Scaffold(
            backgroundColor: palette.bgMain,
            resizeToAvoidBottomInset: false,
            body: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  bottom: false,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(scrollbars: false),
                        child: CustomScrollView(
                          key: const ValueKey('store_menu_vertical_list'),
                          controller: _menuScrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // B. Top Store Banner (168px full-bleed, scrolls naturally with the page)
                            SliverToBoxAdapter(
                              child: _buildTopBanner(
                                context: context,
                                fullVendor: fullVendor,
                                vendorId: resolvedVendorId,
                                palette: palette,
                              ),
                            ),

                            // D, E, F, G1. Store Header, CTA, Categories & Menu Search
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  14,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildStoreHeaderSection(
                                      context: context,
                                      fullVendor: fullVendor,
                                      storeName: storeName,
                                      description: description,
                                      branches: branches,
                                      currentBranch: currentBranch,
                                      workingHours: workingHours,
                                      isOpen: isOpen,
                                      isAr: isAr,
                                      s: s,
                                      palette: palette,
                                      vendorId: resolvedVendorId,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDirectOrderCta(
                                      context: context,
                                      vendorId: resolvedVendorId,
                                      storeName: storeName,
                                      s: s,
                                      palette: palette,
                                    ),
                                    if (categories.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      _buildVisualCategoryBar(
                                        categories: categories,
                                        allMenu: allMenu,
                                        fullVendor: fullVendor,
                                        s: s,
                                        isAr: isAr,
                                        palette: palette,
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    _buildMenuHeaderAndSearch(
                                      s: s,
                                      isPharmacy: isPharmacy,
                                      palette: palette,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // G2. 3-Column Product Grid (or Empty State)
                            if (filteredMenu.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    14,
                                    16,
                                    14,
                                    24 + bottomInset,
                                  ),
                                  child: _buildEmptyMenuState(
                                    s: s,
                                    isAr: isAr,
                                    palette: palette,
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  14,
                                  2,
                                  14,
                                  (cartState.totalItems > 0 ? 92 : 20) +
                                      bottomInset,
                                ),
                                sliver: SliverLayoutBuilder(
                                  builder: (context, sliverConstraints) {
                                    final double maxWidth =
                                        sliverConstraints.crossAxisExtent;
                                    final int crossAxisCount = maxWidth >= 840
                                        ? 5
                                        : (maxWidth >= 560 ? 4 : 3);
                                    const double crossAxisSpacing = 10.0;
                                    const double mainAxisSpacing = 10.0;
                                    final double cardWidth =
                                        ((maxWidth -
                                                    (crossAxisCount - 1) *
                                                        crossAxisSpacing) /
                                                crossAxisCount)
                                            .clamp(80.0, 240.0);
                                    final double textScale =
                                        MediaQuery.textScalerOf(context)
                                            .scale(1.0)
                                            .clamp(1.0, 1.15);
                                    final double mainAxisExtent =
                                        (cardWidth - 5.0) +
                                        (78.0 * textScale).ceilToDouble();

                                    return SliverGrid(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => _buildProductCard(
                                          context: context,
                                          item: filteredMenu[index],
                                          cartState: cartState,
                                          s: s,
                                          isAr: isAr,
                                          isOpen: isOpen,
                                          isPharmacy: isPharmacy,
                                          palette: palette,
                                        ),
                                        childCount: filteredMenu.length,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: crossAxisSpacing,
                                            mainAxisSpacing: mainAxisSpacing,
                                            mainAxisExtent: mainAxisExtent,
                                          ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Persistent floating Back & Favorite controls over top corners
                      PositionedDirectional(
                        top: 12,
                        start: 12,
                        child: _buildBackButton(context),
                      ),
                      PositionedDirectional(
                        top: 12,
                        end: 12,
                        child: _buildFavoriteBannerButton(
                          context: context,
                          vendorId: resolvedVendorId,
                        ),
                      ),
                    ],
                  ),
                ),

                // I. Existing Cart UI (100% Untouched Design — only anchorKey & landPulse attached)
                FloatingCartOverlay(
                  cartAnchorKey: _cartAnchorKey,
                  landPulse: _cartLandPulse,
                ),
              ],
            ),
          );
        },
        loading: () => _buildLoadingSkeleton(palette),
        error: (err, stack) => Scaffold(
          backgroundColor: palette.bgMain,
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildBackButton(context),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 46,
                            color: palette.goldText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${s.errorPrefix}${ErrorUtils.translate(context, err)}',
                            textAlign: TextAlign.center,
                            style: StoreDetailPalette.text(
                              size: 13,
                              weight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(
                              vendorDetailControllerProvider(vendorId),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.gold,
                              foregroundColor: palette.darkOnGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              s.retry,
                              style: StoreDetailPalette.text(
                                size: 12.5,
                                weight: FontWeight.w900,
                                color: palette.darkOnGold,
                              ),
                            ),
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
    );
  }

  // ---------------------------------------------------------------------------
  // B. Top Store Banner & Controls (106px fixed)
  // ---------------------------------------------------------------------------
  Widget _buildTopBanner({
    required BuildContext context,
    required Map<String, dynamic> fullVendor,
    required String vendorId,
    required StoreDetailPalette palette,
  }) {
    final coverRaw = (fullVendor['coverImage'] ?? fullVendor['image'])
        ?.toString()
        .trim();
    final hasCover = coverRaw != null && coverRaw.isNotEmpty;

    const fallbackGradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StoreDetailPalette.bannerFallbackStart,
            StoreDetailPalette.bannerFallbackMid,
            StoreDetailPalette.bannerFallbackEnd,
          ],
        ),
      ),
    );

    return SizedBox(
      key: const ValueKey('store_detail_banner'),
      height: 168,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            fallbackGradient,
            if (hasCover)
              CachedNetworkImage(
                key: const ValueKey('store_detail_cover_image'),
                imageUrl: ImageUtils.formatImageUrl(coverRaw),
                fit: BoxFit.cover,
                placeholder: (_, _) => fallbackGradient,
                errorWidget: (_, _, _) => fallbackGradient,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteBannerButton({
    required BuildContext context,
    required String vendorId,
  }) {
    final isFav = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(vendorId)),
    );
    return GestureDetector(
      key: const ValueKey('store_detail_favorite_btn'),
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
          showVendorFavoriteFeedback(context, isFavorite: result);
        }
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.55),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 17,
              color: isFav ? const Color(0xFFF87171) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('store_detail_back_btn'),
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: Color(0xFF181613),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. Store Header, Expandable Description & Branch Row (moderately scaled up)
  // ---------------------------------------------------------------------------
  Widget _buildStoreHeaderSection({
    required BuildContext context,
    required Map<String, dynamic> fullVendor,
    required String storeName,
    required String description,
    required List<dynamic> branches,
    required Map? currentBranch,
    required List<dynamic> workingHours,
    required bool isOpen,
    required bool isAr,
    required AppStrings s,
    required StoreDetailPalette palette,
    required String vendorId,
  }) {
    final rating = (fullVendor['rating'] as num? ?? 0).toDouble();
    final ratingCount = (fullVendor['ratingCount'] as num?)?.toInt() ?? 0;

    final vertical = fullVendor['vertical'];
    final verticalLabel = vertical is Map
        ? ((isAr
                ? (vertical['nameAr'] ?? vertical['name'])
                : (vertical['name'] ?? vertical['nameAr']))
            ?.toString()
            .trim() ??
            '')
        : '';
    final openText = isOpen
        ? (isAr ? 'مفتوح الآن' : 'Open now')
        : (isAr ? 'مغلق الآن' : 'Closed now');
    final statusColor = isOpen
        ? (palette.isDark
            ? const Color(0xFF4ADE80)
            : const Color(0xFF16A34A))
        : (palette.isDark
            ? const Color(0xFFF87171)
            : const Color(0xFFDC2626));

    final branchName = currentBranch != null
        ? ((isAr
                ? (currentBranch['nameAr'] ?? currentBranch['name'])
                : (currentBranch['name'] ?? currentBranch['nameAr']))
            ?.toString()
            .trim() ??
            '')
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title & Rating Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StoreDetailPalette.text(
                      size: 19.5,
                      weight: FontWeight.w900,
                      color: palette.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: workingHours.isNotEmpty
                        ? () => _showWorkingHoursSheet(
                              context,
                              workingHours,
                              isAr,
                              isOpen,
                              palette,
                            )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (verticalLabel.isNotEmpty) ...[
                                  TextSpan(
                                    text: verticalLabel,
                                    style: StoreDetailPalette.text(
                                      size: 12.5,
                                      weight: FontWeight.w700,
                                      color: palette.textPrimary,
                                      height: 1.15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' • ',
                                    style: StoreDetailPalette.text(
                                      size: 12.5,
                                      weight: FontWeight.w700,
                                      color: palette.textMuted,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 4,
                                    ),
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: openText,
                                  style: StoreDetailPalette.text(
                                    size: 12.5,
                                    weight: FontWeight.w800,
                                    color: statusColor,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (workingHours.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.clock,
                            size: 13,
                            color: palette.goldText,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Rating Block (top-end, gap: 4px): (N), 4.7, Star 16px #E5A93C
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (ratingCount > 0) ...[
                    Text(
                      '($ratingCount)',
                      style: StoreDetailPalette.numeric(
                        size: 12,
                        weight: FontWeight.w700,
                        color: palette.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    rating.toStringAsFixed(1),
                    style: StoreDetailPalette.numeric(
                      size: 15,
                      weight: FontWeight.w900,
                      color: palette.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFE5A93C),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Expandable Description (1-line clamp by default, toggle 12px w800 gold)
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          AppExpandableText(
            text: description.trim(),
            trimLines: 1,
            readMoreLabel: s.readMoreAction,
            readLessLabel: s.readLessAction,
            toggleColor: palette.goldText,
            toggleStyle: StoreDetailPalette.text(
              size: 12,
              weight: FontWeight.w800,
              color: palette.goldText,
              height: 1.15,
            ),
            style: StoreDetailPalette.text(
              size: 12.5,
              weight: FontWeight.w500,
              color: palette.textPrimary,
              height: 1.35,
            ),
          ),
        ],

        // Branch Row (padding-top: 2px)
        if (currentBranch != null && branchName.isNotEmpty) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color: palette.goldText,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${isAr ? 'الفرع' : 'Branch'}: $branchName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StoreDetailPalette.text(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: palette.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ),
                if (branches.length > 1) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showBranchSelector(
                      context,
                      branches,
                      vendorId,
                      isAr,
                      palette,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      isAr ? 'تغيير' : 'Change',
                      style: StoreDetailPalette.text(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: palette.goldText,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // E. Direct Order CTA Section (moderately scaled up)
  // ---------------------------------------------------------------------------
  Widget _buildDirectOrderCta({
    required BuildContext context,
    required String vendorId,
    required String storeName,
    required AppStrings s,
    required StoreDetailPalette palette,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color.fromRGBO(229, 169, 60, 0.12),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              final authState = ref.read(authControllerProvider);
              if (authState != AuthStatus.authenticated) {
                AuthPromptDialog.show(context);
                return;
              }
              context.push('/chat/vendor/$vendorId', extra: {'title': storeName});
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.gold,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomChatIcon(size: 17, color: palette.goldText),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        s.chatWithVendor,
                        maxLines: 1,
                        softWrap: false,
                        style: StoreDetailPalette.text(
                          size: 13.5,
                          weight: FontWeight.w800,
                          color: palette.goldText,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: palette.goldText,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  s.chatWithVendorSubtext,
                  maxLines: 1,
                  softWrap: false,
                  style: StoreDetailPalette.text(
                    size: 12.0,
                    weight: FontWeight.w600,
                    color: palette.textPrimary,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // F. Horizontal Visual Category Bar (56x56 Category Images + Count Badge + Auto-Center)
  // ---------------------------------------------------------------------------
  /// Resolves ONLY the category's own backend image (`iconUrl`/`imageUrl`),
  /// never substituting a product photo so category icons remain distinct from products.
  String? _resolveCategoryOwnImageUrl(Map<String, dynamic> cat) {
    final directUrl =
        (cat['iconUrl'] ?? cat['imageUrl'] ?? cat['image'])?.toString().trim();
    return (directUrl != null && directUrl.isNotEmpty) ? directUrl : null;
  }

  Widget _buildAllCategoryTileVisual(
    List<dynamic> categories,
    StoreDetailPalette palette,
  ) {
    final previewUrls = categories
        .whereType<Map>()
        .map((c) => _resolveCategoryOwnImageUrl(Map<String, dynamic>.from(c)))
        .whereType<String>()
        .take(4)
        .toList();

    if (previewUrls.isEmpty) {
      return _buildCategoryFallbackIcon('all', palette);
    }

    return ColoredBox(
      color: palette.bgCard2,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: List.generate(previewUrls.length, (i) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: TransparentBgNetworkImage(
                imageUrl: ImageUtils.formatImageUrl(previewUrls[i]),
                mode: BackgroundRemovalMode.autoUniform,
                fit: BoxFit.contain,
                maxCacheDimension: 120,
                fallbackBuilder: (_) => Icon(
                  Icons.category_rounded,
                  size: 12,
                  color: palette.goldText,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  int _categoryItemCount(String catId, List<dynamic> allMenu) {
    if (catId == 'all') return allMenu.length;
    return allMenu.where((p) {
      if (p is! Map) return false;
      return p['category']?.toString() == catId ||
          p['categoryId']?.toString() == catId;
    }).length;
  }

  Widget _buildVisualCategoryBar({
    required List<dynamic> categories,
    required List<dynamic> allMenu,
    required Map<String, dynamic> fullVendor,
    required AppStrings s,
    required bool isAr,
    required StoreDetailPalette palette,
  }) {
    final allTiles = <Map<String, dynamic>>[
      {'id': 'all', 'name': s.catAll, 'nameAr': 'الكل'},
      ...categories
          .whereType<Map>()
          .map((c) => Map<String, dynamic>.from(c)),
    ];

    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            key: const ValueKey('store_category_bar'),
            controller: _categoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(allTiles.length, (i) {
                  final cat = allTiles[i];
                  final catId = cat['id']?.toString() ?? '';
                  final isSelected = _selectedCategory == catId;
                  final label = (isAr
                          ? (cat['nameAr'] ?? cat['name'] ?? '')
                          : (cat['name'] ?? cat['nameAr'] ?? ''))
                      .toString();
                  final count = _categoryItemCount(catId, allMenu);
                  final imgRaw = catId == 'all'
                      ? null
                      : _resolveCategoryOwnImageUrl(cat);

                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: i < allTiles.length - 1 ? 8 : 0,
                    ),
                    child: GestureDetector(
                      key: _keyForCategory(catId),
                      onTap: () => _selectCategory(catId),
                      child: AnimatedContainer(
                        key: ValueKey('store_category_tile_$catId'),
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color.fromRGBO(229, 169, 60, 0.15)
                              : palette.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected ? palette.gold : palette.borderGold,
                            width: 1,
                          ),
                          boxShadow: isSelected ? const [] : [palette.cardShadow],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 56x56 Category Image (full zoomed-out BoxFit.contain) + Corner Count Badge
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: palette.bgCard2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? palette.gold
                                      : palette.borderGold,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: palette.gold.withValues(
                                            alpha: 0.28,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isSelected ? 12 : 13,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (catId == 'all')
                                      _buildAllCategoryTileVisual(
                                        categories,
                                        palette,
                                      )
                                    else if (imgRaw != null &&
                                        imgRaw.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: TransparentBgNetworkImage(
                                          imageUrl: ImageUtils.formatImageUrl(
                                            imgRaw,
                                          ),
                                          mode:
                                              BackgroundRemovalMode.autoUniform,
                                          fit: BoxFit.contain,
                                          maxCacheDimension: 180,
                                          placeholderBuilder: (_) => ColoredBox(
                                            color: palette.bgCard2,
                                          ),
                                          fallbackBuilder: (_) =>
                                              _buildCategoryFallbackIcon(
                                                catId,
                                                palette,
                                              ),
                                        ),
                                      )
                                    else
                                      _buildCategoryFallbackIcon(
                                        catId,
                                        palette,
                                      ),

                                    // Item Count Corner Badge (bottom: 2, left: 2)
                                    Positioned(
                                      bottom: 2,
                                      left: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? palette.gold
                                              : Colors.black.withValues(
                                                  alpha: 0.70,
                                                ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: StoreDetailPalette.numeric(
                                            size: 9.5,
                                            weight: FontWeight.w900,
                                            color: isSelected
                                                ? palette.darkOnGold
                                                : Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Category Label (12px, single-line nowrap)
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: StoreDetailPalette.text(
                                size: 12,
                                weight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: isSelected
                                    ? palette.goldText
                                    : palette.textPrimary,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        // Dynamic Edge Fade (Start edge — Right in RTL, Left in LTR)
        if (_showCatStartFade)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            width: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      palette.bgMain,
                      palette.bgMain.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Dynamic Edge Fade (End edge — Left in RTL, Right in LTR)
        if (_showCatEndFade)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerEnd,
                    end: AlignmentDirectional.centerStart,
                    colors: [
                      palette.bgMain,
                      palette.bgMain.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFallbackIcon(String catId, StoreDetailPalette palette) {
    return ColoredBox(
      color: palette.bgCard2,
      child: Center(
        child: Icon(
          catId == 'all'
              ? Icons.grid_view_rounded
              : Icons.category_rounded,
          size: 24,
          color: palette.goldText,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // G1. Menu Header & Strict Product-Name Search Row (scaled up to match Home)
  // ---------------------------------------------------------------------------
  Widget _buildMenuHeaderAndSearch({
    required AppStrings s,
    required bool isPharmacy,
    required StoreDetailPalette palette,
  }) {
    final isFocused = _searchFocusNode.hasFocus;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          isPharmacy ? s.products : s.menu,
          style: StoreDetailPalette.text(
            size: 15.5,
            weight: FontWeight.w900,
            color: palette.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Container(
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: palette.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused ? palette.gold : palette.borderGold,
                    width: 1,
                  ),
                ),
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    TextField(
                      key: const ValueKey('store_menu_search_field'),
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      textInputAction: TextInputAction.search,
                      textAlignVertical: TextAlignVertical.center,
                      cursorColor: palette.gold,
                      style: StoreDetailPalette.text(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: palette.textPrimary,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: s.search,
                        hintStyle: StoreDetailPalette.text(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: palette.textMuted.withValues(alpha: 0.78),
                          height: 1.2,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 36,
                          end: 32,
                          top: 9,
                          bottom: 9,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 12,
                      child: IgnorePointer(
                        child: Icon(
                          LucideIcons.search,
                          size: 16,
                          color: palette.gold,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      PositionedDirectional(
                        end: 8,
                        child: GestureDetector(
                          key: const ValueKey('store_menu_search_clear'),
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.textMuted.withValues(alpha: 0.22),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: palette.textPrimary,
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // G2. Product Grid Card (3-Col Square Image + Floating '+' + Name + Price)
  // ---------------------------------------------------------------------------
  Widget _buildProductCard({
    required BuildContext context,
    required Map<String, dynamic> item,
    required CartState cartState,
    required AppStrings s,
    required bool isAr,
    required bool isOpen,
    required bool isPharmacy,
    required StoreDetailPalette palette,
  }) {
    final productId = item['id']?.toString() ?? '';
    final thumbKey = _keyForProductThumb(productId);

    final bool tracksStock =
        item['tracksStock'] == null ? true : (item['tracksStock'] == true);
    final int? itemStock =
        item['stock'] == null ? null : int.tryParse(item['stock'].toString());
    final bool sellByStrip = item['sellByStrip'] == true;
    final int stripsPerPackage =
        int.tryParse(item['stripsPerPackage']?.toString() ?? '') ?? 1;
    final bool isStripProduct = sellByStrip && stripsPerPackage >= 2;

    final cartProductLines = cartState.allItems
        .where((ci) => ci.product.id == productId)
        .toList();
    final int totalCartQty =
        cartProductLines.fold<int>(0, (sum, ci) => sum + ci.quantity);
    final int totalCartUnits = isStripProduct
        ? cartProductLines.fold<int>(
            0,
            (sum, ci) =>
                sum +
                (ci.selectedUnit == 'strip'
                    ? ci.quantity
                    : ci.quantity * stripsPerPackage),
          )
        : totalCartQty;

    final List<dynamic> menuVariants = item['variants'] as List? ?? const [];
    final bool hasMenuVariants =
        (item['hasVariants'] == true || menuVariants.isNotEmpty) &&
            menuVariants.isNotEmpty;
    final bool hasOptionGroups =
        (item['optionGroups'] as List?)?.isNotEmpty == true;
    final bool hasVariantsWithOptions =
        (item['variants'] as List?)?.any(
              (v) => (v['optionGroups'] as List?)?.isNotEmpty == true,
            ) ??
            false;
    final bool isPharmacyWithStrips =
        isPharmacy && sellByStrip && item['stripsPerPackage'] != null;
    final bool hasCustomizations = hasMenuVariants ||
        hasOptionGroups ||
        hasVariantsWithOptions ||
        isPharmacyWithStrips;

    final CartItem? simpleCartLine =
        (!hasCustomizations && cartProductLines.length == 1)
            ? cartProductLines.first
            : null;
    final bool canInlineDecrement =
        simpleCartLine != null && simpleCartLine.backendId != null;

    final int? effectiveItemStock = itemStock == null
        ? null
        : (isStripProduct ? itemStock * stripsPerPackage : itemStock);
    final int remainingSimpleStock = (tracksStock && effectiveItemStock != null)
        ? effectiveItemStock - totalCartUnits
        : 1;
    final bool isItemOutOfStock = hasMenuVariants
        ? menuVariants.every((v) {
            final vTracks =
                v['tracksStock'] == null ? true : (v['tracksStock'] == true);
            final int? vStock = v['stock'] == null
                ? null
                : int.tryParse(v['stock'].toString());
            return vTracks && vStock != null && vStock <= 0;
          })
        : (tracksStock && itemStock != null && remainingSimpleStock <= 0);

    final name = (isAr &&
                item['nameAr'] != null &&
                item['nameAr'].toString().isNotEmpty
            ? item['nameAr']
            : (item['name'] ?? ''))
        .toString();
    final description = (isAr &&
                item['descriptionAr'] != null &&
                item['descriptionAr'].toString().isNotEmpty
            ? item['descriptionAr']
            : (item['description'] ?? ''))
        .toString();

    final price =
        double.tryParse((item['price'] ?? item['basePrice'])?.toString() ?? '0') ??
            0.0;
    final comparePrice = double.tryParse(item['comparePrice']?.toString() ?? '');
    final hasDiscount = comparePrice != null && comparePrice > price && price > 0;
    final discountPct = hasDiscount
        ? (((comparePrice - price) / comparePrice) * 100).round()
        : 0;
    final isFeatured = item['isFeatured'] == true;
    final badgeText = hasDiscount
        ? '-$discountPct%'
        : (isFeatured ? (isAr ? 'مميز' : 'Featured') : null);

    final priceStr = price.toStringAsFixed(price % 1 == 0 ? 0 : 2);
    final compareStr = hasDiscount
        ? comparePrice.toStringAsFixed(comparePrice % 1 == 0 ? 0 : 2)
        : '';
    final pricePrefix =
        hasMenuVariants ? (isAr ? 'من ' : 'From ') : '';

    final resolvedImg = (item['imageUrl'] ?? item['image'])?.toString().trim();
    final formattedThumbUrl = (resolvedImg != null && resolvedImg.isNotEmpty)
        ? ImageUtils.thumbnailUrl(resolvedImg)
        : '';

    void openSheet() {
      final authStatus = ref.read(authControllerProvider);
      if (authStatus == AuthStatus.unauthenticated) {
        AuthPromptDialog.show(context);
        return;
      }
      if (!isOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'هذا المتجر مغلق حالياً ولا يستقبل طلبات!'
                  : 'This store is currently closed and is not accepting orders!',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _selectedUnit = 'package');
      _showProductBottomSheet(
        context,
        ref,
        item,
        cartState,
        s,
        palette.isDark,
        isPharmacy,
      );
    }

    Future<void> onQuickAdd() async {
      if (isItemOutOfStock) return;

      final authStatus = ref.read(authControllerProvider);
      if (authStatus == AuthStatus.unauthenticated) {
        AuthPromptDialog.show(context);
        return;
      }
      if (!isOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'هذا المتجر مغلق حالياً ولا يستقبل طلبات!'
                  : 'This store is currently closed and is not accepting orders!',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (hasCustomizations) {
        setState(() => _selectedUnit = 'package');
        _showProductBottomSheet(
          context,
          ref,
          item,
          cartState,
          s,
          palette.isDark,
          isPharmacy,
        );
        return;
      }

      // Entry Point 1 — Product Grid Quick Add (+):
      // Capture square product image global rect and fly to FloatingCartOverlay.
      final srcRect = _measureRect(thumbKey);
      _launchFlyToCart(
        srcRect: srcRect,
        imageUrl: formattedThumbUrl,
      );

      try {
        await ref.read(cartProvider.notifier).addItem(
          {
            ...item,
            'vendorId': widget.restaurant['id'],
            'vendorName': widget.restaurant['name'],
          },
          unit: 'package',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorUtils.translate(context, e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> onQuickDecrement() async {
      if (!canInlineDecrement) {
        openSheet();
        return;
      }
      try {
        await ref
            .read(cartProvider.notifier)
            .updateQuantity(simpleCartLine, simpleCartLine.quantity - 1);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorUtils.translate(context, e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Container(
      key: ValueKey('store_product_card_$productId'),
      decoration: BoxDecoration(
        color: palette.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.borderGold,
          width: 1,
        ),
        boxShadow: [palette.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openSheet,
          borderRadius: BorderRadius.circular(14),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Square Image Box with Discount Badge & Floating '+' Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      key: thumbKey,
                      decoration: BoxDecoration(
                        color: palette.bgCard2,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: formattedThumbUrl.isNotEmpty
                                ? TransparentBgNetworkImage(
                                    imageUrl: formattedThumbUrl,
                                    mode: BackgroundRemovalMode.autoUniform,
                                    fit: BoxFit.contain,
                                    maxCacheDimension: 260,
                                    placeholderBuilder: (_) =>
                                        ColoredBox(color: palette.bgCard2),
                                    fallbackBuilder: (_) => Center(
                                      child: Icon(
                                        Icons.fastfood_rounded,
                                        size: 28,
                                        color: palette.textMuted.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.fastfood_rounded,
                                      size: 28,
                                      color: palette.textMuted.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                          ),
                          if (badgeText != null)
                            PositionedDirectional(
                              top: 4,
                              start: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.gold,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  badgeText,
                                  style: StoreDetailPalette.text(
                                    size: 9.5,
                                    weight: FontWeight.w900,
                                    color: palette.darkOnGold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          if (isItemOutOfStock)
                            PositionedDirectional(
                              bottom: 4,
                              start: 4,
                              end: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    s.outOfStock,
                                    maxLines: 1,
                                    style: StoreDetailPalette.text(
                                      size: 9.5,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (isOpen)
                            PositionedDirectional(
                              bottom: 5,
                              end: 5,
                              child: _buildGridAddControl(
                                productId: productId,
                                totalCartQty: totalCartQty,
                                canInlineDecrement: canInlineDecrement,
                                palette: palette,
                                onAdd: onQuickAdd,
                                onDecrement: onQuickDecrement,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Text Stack: 2-line Name, optional 1-line Description, Price
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StoreDetailPalette.text(
                            size: 12.0,
                            weight: FontWeight.w800,
                            color: palette.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        if (description.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StoreDetailPalette.text(
                              size: 10.5,
                              weight: FontWeight.w500,
                              color: palette.textPrimary,
                              height: 1.15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (pricePrefix.isNotEmpty)
                                Text(
                                  pricePrefix,
                                  style: StoreDetailPalette.text(
                                    size: 10.5,
                                    weight: FontWeight.w700,
                                    color: palette.goldText,
                                    height: 1.05,
                                  ),
                                ),
                              Text(
                                '$priceStr ${s.egp}',
                                style: StoreDetailPalette.numeric(
                                  size: 12.5,
                                  weight: FontWeight.w900,
                                  color: palette.goldText,
                                  height: 1.05,
                                ),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 4),
                                Text(
                                  compareStr,
                                  style: StoreDetailPalette.numeric(
                                    size: 10.0,
                                    weight: FontWeight.w600,
                                    color: palette.textMuted,
                                    height: 1.05,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: palette.textMuted,
                                  ),
                                ),
                              ],
                            ],
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
      ),
    );
  }

  Widget _buildGridAddControl({
    required String productId,
    required int totalCartQty,
    required bool canInlineDecrement,
    required StoreDetailPalette palette,
    required VoidCallback onAdd,
    required VoidCallback onDecrement,
  }) {
    if (totalCartQty <= 0) {
      return Material(
        color: palette.gold,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        child: InkWell(
          key: ValueKey('store_quick_add_$productId'),
          onTap: onAdd,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              Icons.add_rounded,
              size: 19,
              color: palette.darkOnGold,
            ),
          ),
        ),
      );
    }

    if (canInlineDecrement) {
      return Material(
        color: palette.gold,
        borderRadius: BorderRadius.circular(999),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        child: SizedBox(
          height: 28,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                key: ValueKey('store_quick_dec_$productId'),
                onTap: onDecrement,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(999),
                  right: Radius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    totalCartQty == 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    size: 15,
                    color: palette.darkOnGold,
                  ),
                ),
              ),
              Text(
                '$totalCartQty',
                style: StoreDetailPalette.numeric(
                  size: 11.5,
                  weight: FontWeight.w900,
                  color: palette.darkOnGold,
                  height: 1.0,
                ),
              ),
              InkWell(
                key: ValueKey('store_quick_add_$productId'),
                onTap: onAdd,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(999),
                  right: Radius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: palette.darkOnGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: palette.gold,
      borderRadius: BorderRadius.circular(999),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      child: InkWell(
        key: ValueKey('store_quick_add_$productId'),
        onTap: onAdd,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalCartQty',
                style: StoreDetailPalette.numeric(
                  size: 11.5,
                  weight: FontWeight.w900,
                  color: palette.darkOnGold,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.add_rounded,
                size: 15,
                color: palette.darkOnGold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMenuState({
    required AppStrings s,
    required bool isAr,
    required StoreDetailPalette palette,
  }) {
    final isSearchEmpty = _searchQuery.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearchEmpty
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 42,
              color: palette.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              isSearchEmpty
                  ? (isAr
                      ? 'لا توجد منتجات مطابقة لبحثك'
                      : 'No products match your search')
                  : s.noItemsInCategory,
              textAlign: TextAlign.center,
              style: StoreDetailPalette.text(
                size: 12.5,
                weight: FontWeight.w700,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(StoreDetailPalette palette) {
    Widget box({double? width, required double height, double radius = 12}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: palette.bgCard2,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.bgMain,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 168,
              color: palette.bgCard2,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        box(width: 165, height: 20, radius: 6),
                        box(width: 68, height: 18, radius: 6),
                      ],
                    ),
                    const SizedBox(height: 6),
                    box(width: 230, height: 13, radius: 6),
                    const SizedBox(height: 10),
                    box(height: 42, radius: 12),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: box(width: 70, height: 84, radius: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        box(width: 78, height: 18, radius: 6),
                        box(width: 200, height: 40, radius: 12),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.62,
                            ),
                        itemCount: 6,
                        itemBuilder: (_, _) => box(height: 180, radius: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
    CartState cartState,
    AppStrings s,
    bool isDark,
    bool isPharmacy, {
    String? initialVariantId,
  }) {
    final parentMessenger = ScaffoldMessenger.maybeOf(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (sheetCtx) {
        return ProductBottomSheet(
          item: item,
          restaurant: widget.restaurant,
          initialUnit: _selectedUnit,
          initialVariantId: initialVariantId,
          s: s,
          isDark: isDark,
          isPharmacy: isPharmacy,
          onFlyToCart: (srcRect, imageUrl) {
            _launchFlyToCart(srcRect: srcRect, imageUrl: imageUrl);
          },
          onAddError: (error) {
            if (mounted && parentMessenger != null) {
              parentMessenger.showSnackBar(
                SnackBar(
                  content: Text(ErrorUtils.translate(context, error)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }
}
