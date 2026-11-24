import 'dart:ui' show ImageFilter, lerpDouble;

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
import '../widgets/fly_to_cart_overlay.dart';
import '../widgets/product_bottom_sheet.dart';
import '../widgets/store_details_tokens.dart';

class _HiddenScrollbarBehavior extends ScrollBehavior {
  const _HiddenScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _CategoryTileModel {
  final String id;
  final String label;
  final int itemCount;
  final String? imageUrl;

  const _CategoryTileModel({
    required this.id,
    required this.label,
    required this.itemCount,
    required this.imageUrl,
  });
}

class VendorDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;
  const VendorDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _initialProductShown = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _catScrollController = ScrollController();
  final ScrollController _menuScrollController = ScrollController();

  final GlobalKey _floatingCartHostKey = GlobalKey();
  final Map<String, GlobalKey> _categoryTileKeys = {};
  final Map<String, GlobalKey> _productThumbKeys = {};
  final Set<OverlayEntry> _activeFlyEntries = {};

  bool _showCatLeftFade = false;
  bool _showCatRightFade = false;
  bool _isSearchFocused = false;

  late final AnimationController _cartPopController;
  Alignment _cartPopAlignment = Alignment.bottomRight;

  @override
  void initState() {
    super.initState();
    _cartPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _catScrollController.addListener(_updateCategoryFades);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final closestBranch = widget.restaurant['_proximity']?['closestBranch'];
      final closestBranchId =
          closestBranch?['id']?.toString() ??
          widget.restaurant['branchId']?.toString();
      final vendorId = widget.restaurant['id']?.toString() ?? '';
      if (closestBranchId != null && vendorId.isNotEmpty) {
        ref
            .read(selectedBranchProvider.notifier)
            .selectBranchById(
              vendorId,
              closestBranchId,
              name: closestBranch?['name']?.toString(),
              nameAr: closestBranch?['nameAr']?.toString(),
              address: closestBranch?['address']?.toString(),
            );
      }
      _updateCategoryFades();
    });
  }

  @override
  void dispose() {
    for (final entry in _activeFlyEntries) {
      if (entry.mounted) {
        entry.remove();
      }
    }
    _activeFlyEntries.clear();
    _cartPopController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _searchController.dispose();
    _catScrollController
      ..removeListener(_updateCategoryFades)
      ..dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    if (_isSearchFocused != _searchFocusNode.hasFocus) {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    }
  }

  void _updateCategoryFades() {
    if (!mounted || !_catScrollController.hasClients) return;
    final pos = _catScrollController.position;
    final maxScroll = pos.maxScrollExtent;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final bool leftFade;
    final bool rightFade;
    if (maxScroll <= 4) {
      leftFade = false;
      rightFade = false;
    } else if (isRtl) {
      // In RTL horizontal scroll, pixels == 0 is the right edge and
      // pixels == maxScrollExtent is the left edge.
      rightFade = pos.pixels > 6;
      leftFade = pos.pixels < maxScroll - 6;
    } else {
      leftFade = pos.pixels > 6;
      rightFade = pos.pixels < maxScroll - 6;
    }

    if (leftFade != _showCatLeftFade || rightFade != _showCatRightFade) {
      setState(() {
        _showCatLeftFade = leftFade;
        _showCatRightFade = rightFade;
      });
    }
  }

  GlobalKey _keyForCategory(String catId) =>
      _categoryTileKeys.putIfAbsent(catId, GlobalKey.new);

  GlobalKey _keyForProductThumb(String productId) =>
      _productThumbKeys.putIfAbsent(productId, GlobalKey.new);

  Rect? _rectFromKey(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    return topLeft & renderBox.size;
  }

  /// Measures the live bounding rect of our untouched [FloatingCartOverlay]
  /// pill when mounted, or computes its exact initial mounted coordinates when
  /// the cart currently has 0 items so the first added item lands accurately.
  Rect? _resolveExistingCartTargetRect() {
    final hostContext = _floatingCartHostKey.currentContext;
    final hostBox = hostContext?.findRenderObject() as RenderBox?;
    if (hostContext == null || hostBox == null || !hostBox.hasSize) {
      return null;
    }

    Rect? livePillRect;
    void visit(Element element) {
      if (livePillRect != null) return;
      if (element.widget is InkWell) {
        final rb = element.renderObject;
        if (rb is RenderBox && rb.hasSize && rb.size.width > 0) {
          final origin = rb.localToGlobal(Offset.zero);
          livePillRect = origin & rb.size;
          return;
        }
      }
      element.visitChildren(visit);
    }

    hostContext.visitChildElements(visit);
    if (livePillRect != null && !livePillRect!.isEmpty) {
      return livePillRect;
    }

    // Cart currently has 0 items: compute exact initial FloatingCartOverlay position
    final hostOrigin = hostBox.localToGlobal(Offset.zero);
    final hostSize = hostBox.size;
    final mediaPadding = MediaQuery.paddingOf(context);
    final minY = 16.0 + mediaPadding.top;
    final maxX = (hostSize.width - 200.0 - 16.0).clamp(16.0, double.infinity);
    final maxY = (hostSize.height - 60.0 - 16.0 - mediaPadding.bottom - 28.0)
        .clamp(minY, double.infinity);
    return (hostOrigin + Offset(maxX, maxY)) & const Size(200.0, 60.0);
  }

  void _triggerExistingCartSpringPop() {
    if (!mounted) return;
    final hostBox =
        _floatingCartHostKey.currentContext?.findRenderObject() as RenderBox?;
    final pillRect = _resolveExistingCartTargetRect();
    if (hostBox != null &&
        hostBox.hasSize &&
        hostBox.size.width > 0 &&
        hostBox.size.height > 0 &&
        pillRect != null) {
      final hostOrigin = hostBox.localToGlobal(Offset.zero);
      final localCenter = pillRect.center - hostOrigin;
      final ax = ((localCenter.dx / hostBox.size.width) * 2.0 - 1.0).clamp(
        -1.0,
        1.0,
      );
      final ay = ((localCenter.dy / hostBox.size.height) * 2.0 - 1.0).clamp(
        -1.0,
        1.0,
      );
      _cartPopAlignment = Alignment(ax, ay);
    }
    _cartPopController.forward(from: 0.0);
  }

  void _runFlyToCartAndCommit({
    required BuildContext context,
    required Rect? sourceRect,
    required String? imageUrl,
    required Future<void> Function() commitAdd,
  }) {
    final targetRect = _resolveExistingCartTargetRect();
    late final OverlayEntry? createdEntry;
    createdEntry = FlyToCartOverlay.launch(
      context: context,
      sourceRect: sourceRect,
      targetRect: targetRect,
      imageUrl: imageUrl,
      onLanded: () async {
        if (createdEntry != null) {
          _activeFlyEntries.remove(createdEntry);
        }
        try {
          await commitAdd();
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerExistingCartSpringPop();
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(this.context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(ErrorUtils.translate(this.context, e)),
                backgroundColor: StoreDetailsTokens.errorRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
    );
    if (createdEntry != null) {
      _activeFlyEntries.add(createdEntry);
    }
  }

  void _selectCategory(String catId) {
    setState(() => _selectedCategory = catId);

    // Auto-center tapped category tile horizontally in the bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tileCtx = _categoryTileKeys[catId]?.currentContext;
      if (tileCtx != null) {
        Scrollable.ensureVisible(
          tileCtx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      _updateCategoryFades();
    });

    // Reset product list scroll to top (no scroll-spy auto-switching)
    if (_menuScrollController.hasClients) {
      _menuScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _handleFavoriteToggle(
    BuildContext context,
    String vendorId,
  ) async {
    if (vendorId.isEmpty) return;
    final authStatus = ref.read(authControllerProvider);
    if (authStatus == AuthStatus.unauthenticated) {
      AuthPromptDialog.show(context);
      return;
    }
    await ref.read(favoritesProvider.notifier).toggleFavorite(vendorId);
  }

  void _showBranchSelector({
    required BuildContext context,
    required List<dynamic> branches,
    required String vendorId,
    required String? currentBranchId,
    required StoreDetailsPalette palette,
    required bool isAr,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (sheetCtx) {
        final bottomSafe = MediaQuery.paddingOf(sheetCtx).bottom;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(sheetCtx).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafe),
                    decoration: BoxDecoration(
                      color: palette.bgCard,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: palette.sheetTopBorder,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 16,
                              color: StoreDetailsTokens.gold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr ? 'اختر الفرع المناسب' : 'Select Branch',
                                style: StoreDetailsTokens.text(
                                  size: 15,
                                  weight: FontWeight.w900,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: branches
                                  .whereType<Map>()
                                  .map((b) {
                                    final bId = b['id']?.toString() ?? '';
                                    final bName =
                                        (isAr &&
                                            b['nameAr'] != null &&
                                            b['nameAr']
                                                .toString()
                                                .trim()
                                                .isNotEmpty)
                                        ? b['nameAr'].toString().trim()
                                        : (b['name']?.toString().trim() ?? '');
                                    final bAddress =
                                        b['address']?.toString().trim() ?? '';
                                    final bOpen = b['isOpen'] != false;
                                    final isSelected = bId == currentBranchId;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Material(
                                        color: isSelected
                                            ? const Color.fromRGBO(
                                                229,
                                                169,
                                                60,
                                                0.15,
                                              )
                                            : palette.bgCard2,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          onTap: () {
                                            ref
                                                .read(
                                                  selectedBranchProvider
                                                      .notifier,
                                                )
                                                .selectBranchById(
                                                  vendorId,
                                                  bId,
                                                  name: b['name']?.toString(),
                                                  nameAr: b['nameAr']
                                                      ?.toString(),
                                                  address: b['address']
                                                      ?.toString(),
                                                );
                                            Navigator.of(sheetCtx).pop();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? StoreDetailsTokens.gold
                                                    : palette.borderGold,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  LucideIcons.mapPin,
                                                  size: 15,
                                                  color: isSelected
                                                      ? StoreDetailsTokens.gold
                                                      : palette.textMuted,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              bName,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: StoreDetailsTokens.text(
                                                                size: 12.5,
                                                                weight:
                                                                    FontWeight
                                                                        .w800,
                                                                color: palette
                                                                    .textPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                          if (!bOpen) ...[
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              isAr
                                                                  ? '(مغلق)'
                                                                  : '(Closed)',
                                                              style: StoreDetailsTokens.text(
                                                                size: 10.5,
                                                                weight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    StoreDetailsTokens
                                                                        .errorRed,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      if (bAddress
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          bAddress,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              StoreDetailsTokens.text(
                                                                size: 10.5,
                                                                weight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: palette
                                                                    .textMuted,
                                                              ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected
                                                        ? StoreDetailsTokens
                                                              .gold
                                                        : Colors.transparent,
                                                    border: isSelected
                                                        ? null
                                                        : Border.all(
                                                            color: palette
                                                                .borderGold,
                                                            width: 1.5,
                                                          ),
                                                  ),
                                                  child: isSelected
                                                      ? const Center(
                                                          child: Icon(
                                                            Icons.check_rounded,
                                                            size: 10,
                                                            color:
                                                                StoreDetailsTokens
                                                                    .darkOnGold,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
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
      },
    );
  }

  void _showProductBottomSheet({
    required BuildContext context,
    required Map<String, dynamic> item,
    required Map<String, dynamic> fullVendor,
    required AppStrings s,
    required bool isDark,
    required bool isPharmacy,
    String? initialVariantId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (sheetCtx) {
        return Stack(
          children: [
            // Backdrop blur + tap outside to close
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(sheetCtx).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            ProductBottomSheet(
              item: item,
              restaurant: fullVendor,
              initialUnit: 'package',
              initialVariantId: initialVariantId,
              s: s,
              isDark: isDark,
              isPharmacy: isPharmacy,
              onRequestFlyAdd: (previewRect, flyImageUrl, commitAdd, _) {
                if (!mounted) return;
                _runFlyToCartAndCommit(
                  context: this.context,
                  sourceRect: previewRect,
                  imageUrl: flyImageUrl,
                  commitAdd: commitAdd,
                );
              },
            ),
          ],
        );
      },
    );
  }

  bool _detectPharmacy(Map<String, dynamic> fullVendor) {
    final typeStr = fullVendor['type']?.toString().toLowerCase() ?? '';
    final vendorSlug = fullVendor['slug']?.toString().toLowerCase() ?? '';
    final vendorName = fullVendor['name']?.toString().toLowerCase() ?? '';
    final verticalSlug =
        fullVendor['vertical']?['slug']?.toString().toLowerCase() ?? '';
    final combined = '$typeStr $vendorSlug $vendorName $verticalSlug';
    return combined.contains('pharmacy') ||
        combined.contains('pharmacies') ||
        combined.contains('pharma') ||
        combined.contains('medical') ||
        combined.contains('medicine') ||
        combined.contains('صيدلي');
  }

  List<_CategoryTileModel> _buildCategoryTiles({
    required List<dynamic> rawCategories,
    required List<Map<String, dynamic>> allMenu,
    required Map<String, dynamic> fullVendor,
    required AppStrings s,
    required bool isAr,
  }) {
    String? firstProductImgInCategory(String? catId) {
      for (final prod in allMenu) {
        if (catId != null) {
          final prodCat =
              (prod['category'] ?? prod['categoryId'])?.toString() ?? '';
          if (prodCat != catId) continue;
        }
        final img = StoreDetailsTokens.cleanBackendImageUrl(
          prod['imageUrl'] ?? prod['image'],
        );
        if (img != null) return img;
      }
      return null;
    }

    String? firstCategoryIcon() {
      for (final raw in rawCategories) {
        if (raw is! Map) continue;
        final img = StoreDetailsTokens.cleanBackendImageUrl(
          raw['imageUrl'] ?? raw['image'] ?? raw['iconUrl'],
        );
        if (img != null) return img;
      }
      return null;
    }

    final allTileImage =
        StoreDetailsTokens.cleanBackendImageUrl(fullVendor['logo']) ??
        firstProductImgInCategory(null) ??
        firstCategoryIcon() ??
        StoreDetailsTokens.cleanBackendImageUrl(fullVendor['coverImage']);

    final tiles = <_CategoryTileModel>[
      _CategoryTileModel(
        id: 'all',
        label: s.catAll,
        itemCount: allMenu.length,
        imageUrl: allTileImage,
      ),
    ];

    for (final raw in rawCategories) {
      if (raw is! Map) continue;
      final catId = raw['id']?.toString() ?? '';
      if (catId.isEmpty) continue;
      final label =
          (isAr &&
              raw['nameAr'] != null &&
              raw['nameAr'].toString().trim().isNotEmpty)
          ? raw['nameAr'].toString().trim()
          : (raw['name']?.toString().trim() ?? '');
      if (label.isEmpty) continue;

      final count = allMenu.where((prod) {
        final prodCat =
            (prod['category'] ?? prod['categoryId'])?.toString() ?? '';
        return prodCat == catId;
      }).length;

      final catImage =
          StoreDetailsTokens.cleanBackendImageUrl(
            raw['imageUrl'] ?? raw['image'] ?? raw['iconUrl'],
          ) ??
          firstProductImgInCategory(catId);

      tiles.add(
        _CategoryTileModel(
          id: catId,
          label: label,
          itemCount: count,
          imageUrl: catImage,
        ),
      );
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = StoreDetailsPalette.fromBrightness(isDark);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final cartState = ref.watch(cartProvider);
    final vendorId = widget.restaurant['id']?.toString() ?? '';
    final detailAsync = ref.watch(vendorDetailControllerProvider(vendorId));

    return Scaffold(
      backgroundColor: palette.bgMain,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: palette.systemOverlayStyle,
        child: detailAsync.when(
          data: (fullVendor) => _buildLoadedViewport(
            context: context,
            fullVendor: fullVendor,
            cartState: cartState,
            palette: palette,
            s: s,
            isDark: isDark,
            isAr: isAr,
            isRtl: isRtl,
          ),
          loading: () => _buildLoadingSkeleton(
            context: context,
            palette: palette,
            isRtl: isRtl,
          ),
          error: (err, _) => _buildErrorState(
            context: context,
            vendorId: vendorId,
            error: err,
            palette: palette,
            s: s,
            isRtl: isRtl,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedViewport({
    required BuildContext context,
    required Map<String, dynamic> fullVendor,
    required CartState cartState,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isDark,
    required bool isAr,
    required bool isRtl,
  }) {
    final resolvedVendorId =
        (fullVendor['id'] ?? widget.restaurant['id'])?.toString() ?? '';
    final isFavorite = ref.watch(
      favoritesProvider.select((favs) => favs.contains(resolvedVendorId)),
    );

    final isPharmacy = _detectPharmacy(fullVendor);

    // Enrich menu items with product-level metadata (e.g. imageUrl, isFeatured)
    final rawProductsById = <String, Map<String, dynamic>>{};
    final rawProducts = fullVendor['products'];
    if (rawProducts is List) {
      for (final rp in rawProducts) {
        if (rp is Map && rp['id'] != null) {
          rawProductsById[rp['id'].toString()] = Map<String, dynamic>.from(rp);
        }
      }
    }

    final rawMenuList = (fullVendor['menu'] as List<dynamic>?) ?? const [];
    final allMenu = rawMenuList
        .whereType<Map>()
        .map((rawItem) {
          final map = Map<String, dynamic>.from(rawItem);
          final pid = map['id']?.toString() ?? '';
          final extra = rawProductsById[pid];
          if (extra != null) {
            map['isFeatured'] ??= extra['isFeatured'];
            if ((map['imageUrl'] == null ||
                    map['imageUrl'].toString().trim().isEmpty) &&
                extra['imageUrl'] != null) {
              map['imageUrl'] = extra['imageUrl'];
            }
          }
          return map;
        })
        .toList(growable: false);

    final branches = (fullVendor['branches'] as List<dynamic>?) ?? const [];
    final activeBranchId = ref
        .watch(selectedBranchProvider)[resolvedVendorId]
        ?.id;
    final currentBranch =
        branches
            .whereType<Map>()
            .where((b) => b['id']?.toString() == activeBranchId)
            .firstOrNull ??
        (fullVendor['closestBranch'] is Map
            ? fullVendor['closestBranch'] as Map
            : null) ??
        (branches.isNotEmpty && branches.first is Map
            ? branches.first as Map
            : null);

    final vendorStatusOpen =
        fullVendor['status'] == null ||
        fullVendor['status'].toString().toUpperCase() == 'OPEN';
    final branchOpen =
        currentBranch == null || currentBranch['isOpen'] != false;
    final isOpen = vendorStatusOpen && branchOpen;

    // Deep-link initial product/variant bottom sheet support
    final initialProductId = widget.restaurant['productId'];
    final initialVariantId = widget.restaurant['variantId']?.toString();
    if (!_initialProductShown &&
        initialProductId != null &&
        allMenu.isNotEmpty) {
      final targetItem = allMenu
          .where((i) => i['id']?.toString() == initialProductId.toString())
          .firstOrNull;
      if (targetItem != null) {
        _initialProductShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && isOpen) {
            _showProductBottomSheet(
              context: context,
              item: targetItem,
              fullVendor: fullVendor,
              s: s,
              isDark: isDark,
              isPharmacy: isPharmacy,
              initialVariantId: initialVariantId,
            );
          }
        });
      }
    }

    final storeName =
        (isAr &&
            fullVendor['storeNameAr'] != null &&
            fullVendor['storeNameAr'].toString().trim().isNotEmpty)
        ? fullVendor['storeNameAr'].toString().trim()
        : ((isAr &&
                  fullVendor['nameAr'] != null &&
                  fullVendor['nameAr'].toString().trim().isNotEmpty)
              ? fullVendor['nameAr'].toString().trim()
              : (fullVendor['storeName'] ?? fullVendor['name'] ?? '')
                    .toString()
                    .trim());

    final storeDescription =
        (isAr &&
            fullVendor['descriptionAr'] != null &&
            fullVendor['descriptionAr'].toString().trim().isNotEmpty)
        ? fullVendor['descriptionAr'].toString().trim()
        : (fullVendor['description']?.toString().trim() ?? '');

    final verticalMap = fullVendor['vertical'] is Map
        ? fullVendor['vertical'] as Map
        : null;
    final verticalLabel = verticalMap != null
        ? ((isAr &&
                  verticalMap['nameAr'] != null &&
                  verticalMap['nameAr'].toString().trim().isNotEmpty)
              ? verticalMap['nameAr'].toString().trim()
              : (verticalMap['name']?.toString().trim() ?? ''))
        : '';
    final statusText = isOpen
        ? (isAr ? 'مفتوح الآن' : 'Open now')
        : (isAr ? 'مغلق حالياً' : 'Closed');
    final distNum = num.tryParse(fullVendor['distanceKm']?.toString() ?? '');
    final distLabel = distNum != null
        ? (isAr
              ? '${distNum.toStringAsFixed(1)} كم'
              : '${distNum.toStringAsFixed(1)} km')
        : '';
    final subtitleParts = <String>[
      if (verticalLabel.isNotEmpty) verticalLabel,
      statusText,
      if (distLabel.isNotEmpty) distLabel,
    ];
    final subtitleText = subtitleParts.join(' • ');

    final rating =
        (fullVendor['rating'] as num?)?.toDouble() ??
        double.tryParse(fullVendor['rating']?.toString() ?? '0') ??
        0.0;
    final ratingCount =
        (fullVendor['ratingCount'] as num?)?.toInt() ??
        int.tryParse(fullVendor['ratingCount']?.toString() ?? '0') ??
        0;

    final rawCategories =
        (fullVendor['categories'] as List<dynamic>?) ?? const [];
    final categoryTiles = _buildCategoryTiles(
      rawCategories: rawCategories,
      allMenu: allMenu,
      fullVendor: fullVendor,
      s: s,
      isAr: isAr,
    );

    final validCategoryIds = categoryTiles.map((t) => t.id).toSet();
    final effectiveCategory = validCategoryIds.contains(_selectedCategory)
        ? _selectedCategory
        : 'all';

    final categoryFiltered = effectiveCategory == 'all'
        ? allMenu
        : allMenu
              .where((item) {
                final itemCat =
                    (item['category'] ?? item['categoryId'])?.toString() ?? '';
                return itemCat == effectiveCategory;
              })
              .toList(growable: false);

    final filteredMenu = StoreDetailsTokens.filterProductsByStrictName(
      categoryFiltered,
      _searchQuery,
    );

    final coverUrl = StoreDetailsTokens.cleanBackendImageUrl(
      fullVendor['coverImage'] ?? fullVendor['logo'],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCategoryFades());

    return Stack(
      children: [
        // A. Outer Viewport-Locked Container (Zero Outer Scroll)
        Positioned.fill(
          child: SafeArea(
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // B. Top Store Banner & Controls (106px fixed, shrink: 0)
                  _buildTopBanner(
                    context: context,
                    coverImageUrl: coverUrl,
                    isFavorite: isFavorite,
                    isRtl: isRtl,
                    onBack: () => _handleBack(context),
                    onToggleFavorite: () =>
                        _handleFavoriteToggle(context, resolvedVendorId),
                  ),

                  // C. Main Content Wrapper (flex: 1, padding: 8px 14px 10px 14px, 8px gaps)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, contentConstraints) {
                        final maxDescExpandedHeight =
                            (contentConstraints.maxHeight * 0.28).clamp(
                              52.0,
                              220.0,
                            );

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // D. Store Header, Expandable Description & Branch Row
                              _buildStoreHeaderSection(
                                context: context,
                                palette: palette,
                                s: s,
                                isAr: isAr,
                                storeName: storeName,
                                subtitleText: subtitleText,
                                isOpen: isOpen,
                                rating: rating,
                                ratingCount: ratingCount,
                                description: storeDescription,
                                maxDescExpandedHeight: maxDescExpandedHeight,
                                currentBranch: currentBranch,
                                branches: branches,
                                vendorId: resolvedVendorId,
                              ),

                              const SizedBox(height: 8),

                              // E. Direct Order CTA Section
                              _buildDirectOrderSection(
                                context: context,
                                palette: palette,
                                s: s,
                                vendorId: resolvedVendorId,
                                storeName: storeName,
                              ),

                              if (categoryTiles.length > 1 ||
                                  allMenu.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                // F. Horizontal Visual Category Bar
                                _buildVisualCategoryBar(
                                  tiles: categoryTiles,
                                  activeCategoryId: effectiveCategory,
                                  palette: palette,
                                ),
                              ],

                              const SizedBox(height: 8),

                              // G. Menu Header, Strict Product-Name Search & Product Cards
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildMenuHeaderAndSearch(
                                      palette: palette,
                                      s: s,
                                      isAr: isAr,
                                      isPharmacy: isPharmacy,
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: _buildScrollableProductList(
                                        context: context,
                                        items: filteredMenu,
                                        fullVendor: fullVendor,
                                        cartState: cartState,
                                        palette: palette,
                                        s: s,
                                        isDark: isDark,
                                        isAr: isAr,
                                        isOpen: isOpen,
                                        isPharmacy: isPharmacy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // I. Existing Cart UI (100% Untouched Design + Fly-to-Cart Anchor & 320ms Spring Pop)
        Positioned.fill(
          key: _floatingCartHostKey,
          child: _buildExistingCartWithSpringPop(),
        ),
      ],
    );
  }

  Widget _buildExistingCartWithSpringPop() {
    const existingCartStack = Stack(children: [FloatingCartOverlay()]);
    return AnimatedBuilder(
      animation: _cartPopController,
      builder: (context, child) {
        if (!_cartPopController.isAnimating) {
          return child!;
        }
        final t = _cartPopController.value;
        // 320ms spring pop: scale 1 → 1.04 → 1 with translateY 0 → -2px → 0,
        // cubic-bezier(0.34, 1.56, 0.64, 1)
        const springCurve = Cubic(0.34, 1.56, 0.64, 1.0);
        final double progress;
        if (t <= 0.55) {
          progress = springCurve.transform((t / 0.55).clamp(0.0, 1.0));
        } else {
          final settle = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
          progress = 1.0 - Curves.easeOutCubic.transform(settle);
        }
        final scale = lerpDouble(1.0, 1.04, progress)!;
        final dy = lerpDouble(0.0, -2.0, progress)!;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            alignment: _cartPopAlignment,
            child: child,
          ),
        );
      },
      child: existingCartStack,
    );
  }

  // ─── B. Top Store Banner & Controls (106px fixed) ──────────────────────────

  Widget _buildTopBanner({
    required BuildContext context,
    required String? coverImageUrl,
    required bool isFavorite,
    required bool isRtl,
    required VoidCallback onBack,
    required VoidCallback onToggleFavorite,
  }) {
    final hasImage = coverImageUrl != null && coverImageUrl.isNotEmpty;

    return SizedBox(
      key: const Key('store_top_banner'),
      height: 106,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: ImageUtils.formatImageUrl(coverImageUrl),
                fit: BoxFit.cover,
                placeholder: (_, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: StoreDetailsTokens.bannerFallbackGradient,
                  ),
                ),
                errorWidget: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: StoreDetailsTokens.bannerFallbackGradient,
                  ),
                ),
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: StoreDetailsTokens.bannerFallbackGradient,
                ),
              ),

            // Subtle scrim for crisp button legibility over bright photos
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top-Right Back Button (RTL start): top 12, start 12, 36×36 #FFFFFF circle
            PositionedDirectional(
              top: 12,
              start: 12,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.28),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: const Color(0xFFFFFFFF),
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: const Key('store_back_button'),
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(16, 16),
                          painter: _StrokeBackArrowPainter(
                            isRtl: isRtl,
                            color: const Color(0xFF181613),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top-Left Action Buttons (RTL end): top 12, end 12, horizontal flex gap 6px
            PositionedDirectional(
              top: 12,
              end: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Material(
                        color: const Color.fromRGBO(0, 0, 0, 0.55),
                        shape: const CircleBorder(
                          side: BorderSide(
                            color: Color.fromRGBO(255, 255, 255, 0.25),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          key: const Key('store_favorite_button'),
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorite,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color: isFavorite
                                    ? StoreDetailsTokens.errorRed
                                    : Colors.white,
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
        ),
      ),
    );
  }

  // ─── D. Store Header, Expandable Description & Branch Row ─────────────────

  Widget _buildStoreHeaderSection({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isAr,
    required String storeName,
    required String subtitleText,
    required bool isOpen,
    required double rating,
    required int ratingCount,
    required String description,
    required double maxDescExpandedHeight,
    required Map<dynamic, dynamic>? currentBranch,
    required List<dynamic> branches,
    required String vendorId,
  }) {
    final branchName = currentBranch != null
        ? ((isAr &&
                  currentBranch['nameAr'] != null &&
                  currentBranch['nameAr'].toString().trim().isNotEmpty)
              ? currentBranch['nameAr'].toString().trim()
              : (currentBranch['name']?.toString().trim() ?? ''))
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    style: StoreDetailsTokens.text(
                      size: 17,
                      weight: FontWeight.w900,
                      color: palette.textPrimary,
                      height: 1.18,
                    ),
                  ),
                  if (subtitleText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOpen
                                ? StoreDetailsTokens.openGreen
                                : StoreDetailsTokens.errorRed,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            subtitleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StoreDetailsTokens.text(
                              size: 11,
                              weight: FontWeight.w700,
                              color: palette.textMuted,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Rating Block (aligned top-end, gap 4px): (N) 11px Inter 700, rating 13px Inter 900, Star 14px #E5A93C
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '($ratingCount)',
                    style: StoreDetailsTokens.numeric(
                      size: 11,
                      weight: FontWeight.w700,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: StoreDetailsTokens.numeric(
                      size: 13,
                      weight: FontWeight.w900,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: StoreDetailsTokens.gold,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Expandable Description (11px --text-muted, 1-line clamp by default, toggle 10.5px w800 --gold-text)
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDescExpandedHeight),
            child: ScrollConfiguration(
              behavior: const _HiddenScrollbarBehavior(),
              child: SingleChildScrollView(
                child: AppExpandableText(
                  text: description,
                  trimLines: 1,
                  readMoreLabel: s.readMoreAction,
                  readLessLabel: s.readLessAction,
                  toggleColor: palette.goldText,
                  style: StoreDetailsTokens.text(
                    size: 11,
                    weight: FontWeight.w500,
                    color: palette.textMuted,
                    height: 1.28,
                  ),
                  toggleStyle: StoreDetailsTokens.text(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: palette.goldText,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),
        ],

        // Branch Row (padding-top: 2px)
        if (branchName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 12,
                  color: StoreDetailsTokens.gold,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${isAr ? "الفرع" : "Branch"}: $branchName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StoreDetailsTokens.text(
                      size: 11,
                      weight: FontWeight.w700,
                      color: palette.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                if (branches.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    key: const Key('store_change_branch_button'),
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _showBranchSelector(
                      context: context,
                      branches: branches,
                      vendorId: vendorId,
                      currentBranchId: currentBranch?['id']?.toString(),
                      palette: palette,
                      isAr: isAr,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      child: Text(
                        isAr ? 'تغيير' : 'Change',
                        style: StoreDetailsTokens.text(
                          size: 11,
                          weight: FontWeight.w800,
                          color: palette.goldText,
                          height: 1.2,
                        ),
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

  // ─── E. Direct Order CTA Section ───────────────────────────────────────────

  Widget _buildDirectOrderSection({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required String vendorId,
    required String storeName,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color.fromRGBO(229, 169, 60, 0.12),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: const Key('store_direct_order_button'),
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final authState = ref.read(authControllerProvider);
              if (authState != AuthStatus.authenticated) {
                AuthPromptDialog.show(context);
                return;
              }
              context.push(
                '/chat/vendor/$vendorId',
                extra: {'title': storeName},
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: StoreDetailsTokens.gold, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomChatIcon(size: 14, color: palette.goldText),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      s.chatWithVendor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StoreDetailsTokens.text(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: palette.goldText,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 11,
              color: StoreDetailsTokens.gold,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                s.chatWithVendorSubtext,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: StoreDetailsTokens.text(
                  size: 10,
                  weight: FontWeight.w600,
                  color: palette.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── F. Horizontal Visual Category Bar ─────────────────────────────────────

  Widget _buildVisualCategoryBar({
    required List<_CategoryTileModel> tiles,
    required String activeCategoryId,
    required StoreDetailsPalette palette,
  }) {
    return Stack(
      children: [
        ScrollConfiguration(
          behavior: const _HiddenScrollbarBehavior(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _updateCategoryFades();
              return false;
            },
            child: SingleChildScrollView(
              key: const Key('store_visual_category_scroll'),
              controller: _catScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                children: [
                  for (int i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _buildVisualCategoryTile(
                      tile: tiles[i],
                      isActive: tiles[i].id == activeCategoryId,
                      palette: palette,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Dynamic Left Edge Fade (28px)
        if (_showCatLeftFade)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      palette.bgMain,
                      palette.bgMain.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Dynamic Right Edge Fade (28px)
        if (_showCatRightFade)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
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

  Widget _buildVisualCategoryTile({
    required _CategoryTileModel tile,
    required bool isActive,
    required StoreDetailsPalette palette,
  }) {
    final tileKey = _keyForCategory(tile.id);
    final hasImage = tile.imageUrl != null && tile.imageUrl!.isNotEmpty;

    return GestureDetector(
      key: tileKey,
      onTap: () => _selectCategory(tile.id),
      child: AnimatedContainer(
        key: Key('store_category_tile_${tile.id}'),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color.fromRGBO(229, 169, 60, 0.15)
              : palette.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? StoreDetailsTokens.gold : palette.borderGold,
            width: 1,
          ),
          boxShadow: isActive ? null : [palette.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 48px × 48px Category Image with ring & corner item-count badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.bgCard2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? StoreDetailsTokens.gold
                      : palette.borderGold,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color.fromRGBO(229, 169, 60, 0.28),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isActive ? 10 : 11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      CachedNetworkImage(
                        imageUrl: ImageUtils.thumbnailUrl(tile.imageUrl),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _buildCategoryFallbackIcon(
                          tileId: tile.id,
                          palette: palette,
                          isActive: isActive,
                        ),
                        errorWidget: (_, _, _) => _buildCategoryFallbackIcon(
                          tileId: tile.id,
                          palette: palette,
                          isActive: isActive,
                        ),
                      )
                    else
                      _buildCategoryFallbackIcon(
                        tileId: tile.id,
                        palette: palette,
                        isActive: isActive,
                      ),

                    // Item Count Corner Badge (bottom: 2px; left: 2px)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 1,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? StoreDetailsTokens.gold
                              : const Color.fromRGBO(0, 0, 0, 0.70),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tile.itemCount}',
                          style: StoreDetailsTokens.numeric(
                            size: 8.5,
                            weight: FontWeight.w900,
                            color: isActive
                                ? StoreDetailsTokens.darkOnGold
                                : Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Category Label (10.5px, single-line nowrap, tight line-height)
            Text(
              tile.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: StoreDetailsTokens.text(
                size: 10.5,
                weight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive ? palette.goldText : palette.textPrimary,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFallbackIcon({
    required String tileId,
    required StoreDetailsPalette palette,
    required bool isActive,
  }) {
    return ColoredBox(
      color: palette.bgCard2,
      child: Center(
        child: Icon(
          tileId == 'all'
              ? Icons.grid_view_rounded
              : Icons.restaurant_menu_rounded,
          size: 20,
          color: isActive ? StoreDetailsTokens.gold : palette.textMuted,
        ),
      ),
    );
  }

  // ─── G. Menu Header, Strict Product-Name Search & Product Cards ────────────

  Widget _buildMenuHeaderAndSearch({
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isAr,
    required bool isPharmacy,
  }) {
    final headingText = isAr ? 'القائمة' : (isPharmacy ? s.products : s.menu);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          headingText,
          style: StoreDetailsTokens.text(
            size: 13.5,
            weight: FontWeight.w900,
            color: palette.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 8),

        // Search Input Wrapper: flex 1, max-width 235px, height 32px, radius 12px
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 235),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: palette.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSearchFocused
                      ? StoreDetailsTokens.gold
                      : palette.borderGold,
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    key: const Key('store_menu_search_input'),
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: StoreDetailsTokens.text(
                      size: 11,
                      weight: FontWeight.w600,
                      color: palette.textPrimary,
                      height: 1.2,
                    ),
                    cursorColor: StoreDetailsTokens.gold,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      hintText: isAr ? 'ابحث باسم المنتج...' : s.search,
                      hintStyle: StoreDetailsTokens.text(
                        size: 11,
                        weight: FontWeight.w500,
                        color: palette.textMuted,
                        height: 1.2,
                      ),
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 32,
                        end: 28,
                        top: 6,
                        bottom: 6,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),

                  // Search Icon: 14×14, #E5A93C, right 10px in RTL (start: 10)
                  const PositionedDirectional(
                    start: 10,
                    child: IgnorePointer(
                      child: Icon(
                        LucideIcons.search,
                        size: 14,
                        color: StoreDetailsTokens.gold,
                      ),
                    ),
                  ),

                  // Clear (✕) Button: 16×16 circular, 9px icon, left 8px in RTL (end: 8)
                  if (_searchQuery.isNotEmpty)
                    PositionedDirectional(
                      end: 8,
                      child: GestureDetector(
                        key: const Key('store_menu_search_clear'),
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.bgCard2,
                            border: Border.all(
                              color: palette.borderGold,
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close_rounded,
                              size: 9,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableProductList({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> fullVendor,
    required CartState cartState,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isDark,
    required bool isAr,
    required bool isOpen,
    required bool isPharmacy,
  }) {
    if (items.isEmpty) {
      final hasSearch = _searchQuery.trim().isNotEmpty;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSearch ? LucideIcons.searchX : Icons.inventory_2_outlined,
                size: 36,
                color: palette.textMuted.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch ? s.noResults : s.noItemsInCategory,
                textAlign: TextAlign.center,
                style: StoreDetailsTokens.text(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
              if (hasSearch) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Text(
                    isAr ? 'مسح البحث' : 'Clear search',
                    style: StoreDetailsTokens.text(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: palette.goldText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Reserve scroll padding at the very end when the untouched FloatingCartOverlay
    // pill is visible so the bottom-most product card can always scroll clear of it.
    final bottomListPadding = cartState.totalItems > 0 ? 88.0 : 4.0;

    return ScrollConfiguration(
      behavior: const _HiddenScrollbarBehavior(),
      child: ListView.separated(
        key: const Key('store_menu_product_list'),
        controller: _menuScrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(bottom: bottomListPadding),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildProductCard(
          context: context,
          item: items[index],
          fullVendor: fullVendor,
          cartState: cartState,
          palette: palette,
          s: s,
          isDark: isDark,
          isAr: isAr,
          isOpen: isOpen,
          isPharmacy: isPharmacy,
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required Map<String, dynamic> item,
    required Map<String, dynamic> fullVendor,
    required CartState cartState,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isDark,
    required bool isAr,
    required bool isOpen,
    required bool isPharmacy,
  }) {
    final productId = item['id']?.toString() ?? '';
    final thumbKey = _keyForProductThumb(
      productId.isNotEmpty ? productId : item.hashCode.toString(),
    );

    final bool tracksStock = item['tracksStock'] == null
        ? true
        : (item['tracksStock'] == true);
    final int? itemStock = item['stock'] == null
        ? null
        : int.tryParse(item['stock'].toString());
    final bool sellByStrip = item['sellByStrip'] == true;
    final int stripsPerPackage =
        int.tryParse(item['stripsPerPackage']?.toString() ?? '') ?? 1;
    final bool isStripProduct = sellByStrip && stripsPerPackage >= 2;

    final cartProductLines = cartState.allItems.where(
      (ci) => ci.product.id == productId,
    );
    final int totalCartQty = cartProductLines.fold<int>(
      0,
      (sum, ci) => sum + ci.quantity,
    );
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
    final int? effectiveItemStock = itemStock == null
        ? null
        : (isStripProduct ? itemStock * stripsPerPackage : itemStock);
    final int remainingSimpleStock = (tracksStock && effectiveItemStock != null)
        ? effectiveItemStock - totalCartUnits
        : 1;
    final bool isItemOutOfStock = hasMenuVariants
        ? menuVariants.whereType<Map>().every((v) {
            final vTracks = v['tracksStock'] == null
                ? true
                : (v['tracksStock'] == true);
            final int? vStock = v['stock'] == null
                ? null
                : int.tryParse(v['stock'].toString());
            return vTracks && vStock != null && vStock <= 0;
          })
        : (tracksStock && itemStock != null && remainingSimpleStock <= 0);

    final prodName =
        (isAr &&
            item['nameAr'] != null &&
            item['nameAr'].toString().trim().isNotEmpty)
        ? item['nameAr'].toString().trim()
        : (item['name']?.toString().trim() ?? '');
    final prodDesc =
        (isAr &&
            item['descriptionAr'] != null &&
            item['descriptionAr'].toString().trim().isNotEmpty)
        ? item['descriptionAr'].toString().trim()
        : (item['description']?.toString().trim() ?? '');

    final price =
        double.tryParse(
          (item['price'] ?? item['basePrice'])?.toString() ?? '0',
        ) ??
        0.0;
    final comparePrice = item['comparePrice'] == null
        ? null
        : double.tryParse(item['comparePrice'].toString());
    final hasDiscount = comparePrice != null && comparePrice > price;
    final discountPct = hasDiscount
        ? (((comparePrice - price) / comparePrice) * 100).round()
        : 0;

    final optionGroups = item['optionGroups'] as List? ?? const [];
    final hasVariantsWithOptions = menuVariants.whereType<Map>().any(
      (v) => (v['optionGroups'] as List?)?.isNotEmpty == true,
    );
    final isPharmacyWithStrips =
        isPharmacy && sellByStrip && item['stripsPerPackage'] != null;
    final requiresCustomization =
        hasMenuVariants ||
        optionGroups.isNotEmpty ||
        hasVariantsWithOptions ||
        isPharmacyWithStrips;

    final hasPaidOptions = optionGroups.whereType<Map>().any((g) {
      final opts = g['options'] as List? ?? const [];
      return opts.whereType<Map>().any(
        (o) => (double.tryParse(o['priceAdded']?.toString() ?? '0') ?? 0) > 0,
      );
    });
    final showStartingPrefix = hasMenuVariants || hasPaidOptions;
    final currency = s.egp.trim();

    final thumbUrl = StoreDetailsTokens.cleanBackendImageUrl(
      item['imageUrl'] ?? item['image'],
    );

    // Optional real backend badge (discount % or featured)
    String? badgeLabel;
    bool forceBadgeLtr = false;
    if (hasDiscount && discountPct > 0) {
      badgeLabel = '-$discountPct%';
      forceBadgeLtr = true;
    } else if (item['isFeatured'] == true) {
      badgeLabel = isAr ? 'مميز' : 'Featured';
    }

    void handleOpenCard() {
      final authStatus = ref.read(authControllerProvider);
      if (authStatus == AuthStatus.unauthenticated) {
        AuthPromptDialog.show(context);
        return;
      }
      if (!isOpen) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'هذا المتجر مغلق حالياً ولا يستقبل طلبات!'
                    : 'This store is currently closed and is not accepting orders!',
              ),
              backgroundColor: StoreDetailsTokens.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }
      _showProductBottomSheet(
        context: context,
        item: item,
        fullVendor: fullVendor,
        s: s,
        isDark: isDark,
        isPharmacy: isPharmacy,
      );
    }

    void handleQuickAdd() {
      if (!isOpen) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'هذا المتجر مغلق حالياً ولا يستقبل طلبات!'
                    : 'This store is currently closed and is not accepting orders!',
              ),
              backgroundColor: StoreDetailsTokens.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }
      if (isItemOutOfStock) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(s.outOfStock),
              backgroundColor: StoreDetailsTokens.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }

      final authStatus = ref.read(authControllerProvider);
      if (authStatus == AuthStatus.unauthenticated) {
        AuthPromptDialog.show(context);
        return;
      }

      if (requiresCustomization) {
        _showProductBottomSheet(
          context: context,
          item: item,
          fullVendor: fullVendor,
          s: s,
          isDark: isDark,
          isPharmacy: isPharmacy,
        );
        return;
      }

      final payload = <String, dynamic>{
        ...item,
        'vendorId': fullVendor['id'] ?? widget.restaurant['id'],
        'vendorName': fullVendor['name'] ?? fullVendor['storeName'],
      };
      final sourceRect = _rectFromKey(thumbKey);
      final cartNotifier = ref.read(cartProvider.notifier);

      _runFlyToCartAndCommit(
        context: context,
        sourceRect: sourceRect,
        imageUrl: thumbUrl,
        commitAdd: () => cartNotifier.addItem(payload, unit: 'package'),
      );
    }

    final canQuickOrder = isOpen && !isItemOutOfStock;

    return Container(
      key: Key('store_product_card_$productId'),
      decoration: BoxDecoration(
        color: palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderGold, width: 1),
        boxShadow: [palette.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: handleOpenCard,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 56px × 56px Thumbnail + Optional Backend Badge (top: -6px; right: -4px)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      key: thumbKey,
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: palette.bgCard2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.borderGold, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: (thumbUrl != null && thumbUrl.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: ImageUtils.thumbnailUrl(thumbUrl),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Center(
                                  child: Icon(
                                    Icons.fastfood_rounded,
                                    size: 22,
                                    color: palette.textMuted.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.fastfood_rounded,
                                    size: 22,
                                    color: palette.textMuted.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.fastfood_rounded,
                                  size: 22,
                                  color: palette.textMuted.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (badgeLabel != null)
                      Positioned(
                        top: -6,
                        right: -4,
                        child: Directionality(
                          textDirection: forceBadgeLtr
                              ? TextDirection.ltr
                              : Directionality.of(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: StoreDetailsTokens.gold,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              badgeLabel,
                              style: forceBadgeLtr
                                  ? StoreDetailsTokens.numeric(
                                      size: 8.5,
                                      weight: FontWeight.w900,
                                      color: StoreDetailsTokens.darkOnGold,
                                      height: 1.1,
                                    )
                                  : StoreDetailsTokens.text(
                                      size: 8.5,
                                      weight: FontWeight.w900,
                                      color: StoreDetailsTokens.darkOnGold,
                                      height: 1.1,
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),

                // Text Stack: Name (12px w900), Desc (10px muted 1-line, mt 2px), Starting Price (11px Inter w900 gold, mt 4px)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        prodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StoreDetailsTokens.text(
                          size: 12,
                          weight: FontWeight.w900,
                          color: palette.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      if (prodDesc.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          prodDesc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StoreDetailsTokens.text(
                            size: 10,
                            weight: FontWeight.w500,
                            color: palette.textMuted,
                            height: 1.25,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            if (showStartingPrefix)
                              TextSpan(
                                text: isAr ? 'يبدأ من ' : 'From ',
                                style: StoreDetailsTokens.text(
                                  size: 10.5,
                                  weight: FontWeight.w800,
                                  color: palette.goldText,
                                ),
                              ),
                            TextSpan(
                              text: StoreDetailsTokens.formatPrice(price),
                              style: StoreDetailsTokens.numeric(
                                size: 11,
                                weight: FontWeight.w900,
                                color: palette.goldText,
                              ),
                            ),
                            TextSpan(
                              text: ' $currency',
                              style: StoreDetailsTokens.text(
                                size: 10.5,
                                weight: FontWeight.w900,
                                color: palette.goldText,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const TextSpan(text: '  '),
                              TextSpan(
                                text:
                                    '${StoreDetailsTokens.formatPrice(comparePrice)} $currency',
                                style: StoreDetailsTokens.numeric(
                                  size: 9.5,
                                  weight: FontWeight.w600,
                                  color: palette.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: palette.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Quick Add Button (+ أضف): padding 6px 10px, radius 12px, #E5A93C (hover #F6C667), text #14120E, 10.5px w900
                Material(
                  color: canQuickOrder
                      ? StoreDetailsTokens.gold
                      : palette.bgCard2,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: Key('store_quick_add_$productId'),
                    borderRadius: BorderRadius.circular(12),
                    hoverColor: StoreDetailsTokens.goldHover,
                    splashColor: StoreDetailsTokens.goldHover.withValues(
                      alpha: 0.45,
                    ),
                    highlightColor: StoreDetailsTokens.goldHover.withValues(
                      alpha: 0.35,
                    ),
                    onTap: handleQuickAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: canQuickOrder
                            ? null
                            : Border.all(color: palette.borderGold, width: 0.8),
                      ),
                      child: Text(
                        isItemOutOfStock
                            ? s.outOfStock
                            : (isAr ? '+ أضف' : '+ Add'),
                        maxLines: 1,
                        softWrap: false,
                        style: StoreDetailsTokens.text(
                          size: 10.5,
                          weight: FontWeight.w900,
                          color: canQuickOrder
                              ? StoreDetailsTokens.darkOnGold
                              : palette.textMuted,
                          height: 1.2,
                        ),
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

  // ─── Graceful Loading Skeleton & Error State ───────────────────────────────

  Widget _buildLoadingSkeleton({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required bool isRtl,
  }) {
    return SafeArea(
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 106,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: palette.bgCard2),
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: Material(
                      color: const Color(0xFFFFFFFF),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _handleBack(context),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: CustomPaint(
                              size: const Size(16, 16),
                              painter: _StrokeBackArrowPainter(
                                isRtl: isRtl,
                                color: const Color(0xFF181613),
                                strokeWidth: 2.5,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBlock(palette, width: 160, height: 17, radius: 6),
                    const SizedBox(height: 6),
                    _skeletonBlock(palette, width: 220, height: 11, radius: 6),
                    const SizedBox(height: 8),
                    _skeletonBlock(
                      palette,
                      width: double.infinity,
                      height: 34,
                      radius: 12,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 76,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: List.generate(
                            4,
                            (idx) => Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: idx < 3 ? 8 : 0,
                              ),
                              child: _skeletonBlock(
                                palette,
                                width: 62,
                                height: 74,
                                radius: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, _) => _skeletonBlock(
                          palette,
                          width: double.infinity,
                          height: 76,
                          radius: 16,
                        ),
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

  Widget _skeletonBlock(
    StoreDetailsPalette palette, {
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.bgCard2,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: palette.borderGold.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required BuildContext context,
    required String vendorId,
    required Object error,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isRtl,
  }) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                color: palette.bgCard,
                shape: CircleBorder(
                  side: BorderSide(color: palette.borderGold),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _handleBack(context),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(16, 16),
                        painter: _StrokeBackArrowPainter(
                          isRtl: isRtl,
                          color: palette.textPrimary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: StoreDetailsTokens.errorRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${s.errorPrefix}${ErrorUtils.translate(context, error)}',
                      textAlign: TextAlign.center,
                      style: StoreDetailsTokens.text(
                        size: 13,
                        weight: FontWeight.w700,
                        color: palette.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key('store_error_retry_button'),
                      onPressed: () => ref.invalidate(
                        vendorDetailControllerProvider(vendorId),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StoreDetailsTokens.gold,
                        foregroundColor: StoreDetailsTokens.darkOnGold,
                        minimumSize: const Size(140, 42),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        s.retry,
                        style: StoreDetailsTokens.text(
                          size: 13,
                          weight: FontWeight.w900,
                          color: StoreDetailsTokens.darkOnGold,
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
    );
  }
}

/// Draws a crisp 16×16 directional back arrow with an exact 2.5px stroke width.
class _StrokeBackArrowPainter extends CustomPainter {
  final bool isRtl;
  final Color color;
  final double strokeWidth;

  const _StrokeBackArrowPainter({
    required this.isRtl,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final h = size.height / 2;
    final w = size.width;

    if (isRtl) {
      // Points right (→) in RTL when anchored at top-right
      canvas.drawLine(Offset(2.5, h), Offset(w - 2.5, h), paint);
      final head = Path()
        ..moveTo(w - 6.8, h - 4.5)
        ..lineTo(w - 2.2, h)
        ..lineTo(w - 6.8, h + 4.5);
      canvas.drawPath(head, paint);
    } else {
      // Points left (←) in LTR when anchored at top-left
      canvas.drawLine(Offset(w - 2.5, h), Offset(2.5, h), paint);
      final head = Path()
        ..moveTo(6.8, h - 4.5)
        ..lineTo(2.2, h)
        ..lineTo(6.8, h + 4.5);
      canvas.drawPath(head, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokeBackArrowPainter oldDelegate) {
    return oldDelegate.isRtl != isRtl ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
