import 'dart:ui';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import 'category_icon_image.dart';
import 'store_detail_tokens.dart';

class ProductBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> restaurant;
  final String initialUnit;
  final String? initialVariantId;
  final AppStrings s;
  final bool isDark;
  final bool isPharmacy;

  /// Invoked with the captured global [Rect] of the 160px preview image
  /// BEFORE the sheet is dismissed so the parabolic Fly-to-Cart animation
  /// starts from the exact preview image bounds.
  final void Function(Rect? srcRect, String? imageUrl)? onFlyToCart;

  /// Optional error callback when the cart API fails after optimistic sheet dismissal.
  final void Function(Object error)? onAddError;

  const ProductBottomSheet({
    super.key,
    required this.item,
    required this.restaurant,
    required this.initialUnit,
    this.initialVariantId,
    required this.s,
    required this.isDark,
    required this.isPharmacy,
    this.onFlyToCart,
    this.onAddError,
  });

  @override
  ConsumerState<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends ConsumerState<ProductBottomSheet> {
  final GlobalKey _previewImageKey = GlobalKey();

  late String _selectedUnit;
  Map<String, dynamic>? _selectedVariant;
  bool _hasUserSelectedVariant = false;
  final Map<String, List<Map<String, dynamic>>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;

    final variants = widget.item['variants'] as List<dynamic>? ?? const [];
    final bool hasVariants =
        (widget.item['hasVariants'] == true || variants.isNotEmpty) &&
            variants.isNotEmpty;
    if (hasVariants) {
      Map<String, dynamic>? initialSelected;
      if (widget.initialVariantId != null &&
          widget.initialVariantId!.isNotEmpty) {
        initialSelected = variants
            .whereType<Map>()
            .map((v) => Map<String, dynamic>.from(v))
            .where((v) => v['id']?.toString() == widget.initialVariantId)
            .firstOrNull;
      }
      initialSelected ??= variants
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .where((v) {
            final vTracks =
                v['tracksStock'] == null ? true : (v['tracksStock'] == true);
            final vStock = _parseStock(v['stock']);
            return !(vTracks && vStock != null && vStock <= 0);
          })
          .firstOrNull;
      _selectedVariant =
          initialSelected ?? Map<String, dynamic>.from(variants.first as Map);
    }

    final productOptionGroups =
        widget.item['optionGroups'] as List<dynamic>? ?? const [];
    for (final group in productOptionGroups) {
      _initGroupSelection(group as Map);
    }

    if (_selectedVariant != null) {
      final variantOptionGroups =
          _selectedVariant!['optionGroups'] as List<dynamic>? ?? const [];
      for (final group in variantOptionGroups) {
        _initGroupSelection(group as Map);
      }
    }
  }

  void _initGroupSelection(Map group) {
    final gId = group['id']?.toString() ?? '';
    final isRequired = group['isRequired'] == true;
    final maxSelect = (group['maxSelect'] as num?)?.toInt() ??
        int.tryParse(group['maxSelect']?.toString() ?? '1') ??
        1;
    final options = group['options'] as List<dynamic>? ?? const [];
    if (isRequired && maxSelect == 1 && options.isNotEmpty) {
      _selectedOptions[gId] = [Map<String, dynamic>.from(options.first as Map)];
    } else {
      _selectedOptions[gId] = [];
    }
  }

  bool _areOptionsEqual(List<CartOptionRef> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((o) => o.id).toSet();
    final bIds = b.map((o) => o['id']?.toString() ?? '').toSet();
    return aIds.containsAll(bIds);
  }

  Rect? _capturePreviewRect() {
    final ctx = _previewImageKey.currentContext;
    if (ctx == null) return null;
    final renderBox = ctx.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return null;
    return renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  void _toggleOption(Map<String, dynamic> group, Map<String, dynamic> option) {
    final groupId = group['id']?.toString() ?? '';
    final isRequired = group['isRequired'] == true;
    final maxSelect = (group['maxSelect'] as num?)?.toInt() ??
        int.tryParse(group['maxSelect']?.toString() ?? '1') ??
        1;
    final safeMax = maxSelect <= 0 ? 1 : maxSelect;
    final list =
        List<Map<String, dynamic>>.from(_selectedOptions[groupId] ?? const []);
    final optId = option['id']?.toString() ?? '';

    final isSelected = list.any((o) => o['id']?.toString() == optId);

    setState(() {
      if (isSelected) {
        if (safeMax == 1 && isRequired) {
          return;
        }
        list.removeWhere((o) => o['id']?.toString() == optId);
      } else {
        if (safeMax == 1) {
          list.clear();
          list.add(option);
        } else {
          if (list.length < safeMax) {
            list.add(option);
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAr
                      ? 'الحد الأقصى للاختيار هو $safeMax'
                      : 'Maximum selection is $safeMax',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
      _selectedOptions[groupId] = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final s = widget.s;
    final palette = StoreDetailPalette.fromBrightness(widget.isDark);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final flatOptions =
        _selectedOptions.values.expand((list) => list).toList();

    final cartAllItems = ref.watch(cartProvider).allItems;
    final currentCartItem = cartAllItems.where((ci) {
      return ci.product.id == item['id'] &&
          ci.selectedUnit == _selectedUnit &&
          ci.selectedVariant?.id == _selectedVariant?['id'] &&
          _areOptionsEqual(ci.selectedOptions, flatOptions);
    }).firstOrNull;

    final currentQty = currentCartItem?.quantity ?? 0;

    final bool productTracksStock =
        item['tracksStock'] == null ? true : (item['tracksStock'] == true);
    final int? productStock = _parseStock(item['stock']);
    final int? variantStock = _parseStock(_selectedVariant?['stock']);
    final bool variantTracksStock = _selectedVariant == null
        ? true
        : (_selectedVariant!['tracksStock'] == null
            ? productTracksStock
            : (_selectedVariant!['tracksStock'] == true));

    final bool sellByStrip = item['sellByStrip'] == true;
    final int stripsPerPackage =
        int.tryParse(item['stripsPerPackage']?.toString() ?? '') ?? 1;
    final int divider =
        (_selectedUnit == 'strip' && sellByStrip && stripsPerPackage > 1)
            ? stripsPerPackage
            : 1;

    int convertedLineQty(CartItem ci) {
      int lineQty = ci.quantity;
      if (sellByStrip && stripsPerPackage > 1) {
        if (_selectedUnit == 'strip' && ci.selectedUnit == 'package') {
          lineQty = ci.quantity * stripsPerPackage;
        } else if (_selectedUnit == 'package' && ci.selectedUnit == 'strip') {
          lineQty = (ci.quantity / stripsPerPackage).ceil();
        }
      }
      return lineQty;
    }

    int stockPoolQty = 0;
    int? stockLimit;
    if (_selectedVariant != null) {
      if (variantTracksStock && variantStock != null) {
        stockLimit = variantStock * divider;
        stockPoolQty = cartAllItems
            .where((ci) => ci.selectedVariant?.id == _selectedVariant!['id'])
            .fold<int>(0, (sum, ci) => sum + convertedLineQty(ci));
      }
    } else if (productTracksStock && productStock != null) {
      stockLimit = productStock * divider;
      stockPoolQty = cartAllItems
          .where(
            (ci) => ci.product.id == item['id'] && ci.selectedVariant == null,
          )
          .fold<int>(0, (sum, ci) => sum + convertedLineQty(ci));
    }

    final bool isOutOfStock = stockLimit != null
        ? stockPoolQty >= stockLimit
        : (_selectedVariant != null
            ? variantTracksStock && variantStock != null && variantStock <= 0
            : productTracksStock && productStock != null && productStock <= 0);
    final bool atStockLimit = stockLimit != null && stockPoolQty >= stockLimit;

    final bool supportsStrips =
        item['sellByStrip'] == true && item['stripsPerPackage'] != null;
    final int rawStrips = (item['stripsPerPackage'] as num?)?.toInt() ??
        int.tryParse(item['stripsPerPackage']?.toString() ?? '') ??
        1;
    final int stripsCount = rawStrips > 0 ? rawStrips : 1;

    double effectiveBasePrice = 0.0;
    double originalBasePrice = 0.0;

    if (_selectedVariant != null) {
      final effectiveP =
          _selectedVariant!['price'] ?? _selectedVariant!['basePrice'];
      effectiveBasePrice = double.tryParse(effectiveP?.toString() ?? '0') ?? 0;

      final compareP =
          _selectedVariant!['comparePrice'] ?? _selectedVariant!['basePrice'];
      originalBasePrice =
          double.tryParse(compareP?.toString() ?? '0') ?? effectiveBasePrice;
    } else {
      final effectiveP = item['price'] ?? item['basePrice'];
      effectiveBasePrice = double.tryParse(effectiveP?.toString() ?? '0') ?? 0;

      final compareP = item['comparePrice'] ?? effectiveBasePrice;
      originalBasePrice =
          double.tryParse(compareP?.toString() ?? '0') ?? effectiveBasePrice;
    }

    double optionsTotal = 0.0;
    for (final opt in flatOptions) {
      optionsTotal += double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0;
    }

    final double currentUnitPrice =
        (_selectedUnit == 'strip'
            ? (effectiveBasePrice / stripsCount)
            : effectiveBasePrice) +
        optionsTotal;
    final double originalUnitPrice =
        (_selectedUnit == 'strip'
            ? (originalBasePrice / stripsCount)
            : originalBasePrice) +
        optionsTotal;
    final bool hasDiscount = originalUnitPrice > currentUnitPrice;
    final int discountPercentage = hasDiscount
        ? (((originalUnitPrice - currentUnitPrice) / originalUnitPrice) * 100)
            .round()
        : 0;

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

    final variants = item['variants'] as List<dynamic>? ?? const [];
    final bool hasVariants =
        (item['hasVariants'] == true || variants.isNotEmpty) &&
            variants.isNotEmpty;

    final productMainImage =
        (item['imageUrl'] ?? item['image'])?.toString().trim();
    final selectedVariantImage =
        (_selectedVariant?['imageUrl'] ?? _selectedVariant?['image'])
            ?.toString()
            .trim();

    // Start with the product's own image on open; immediately swap to the
    // selected variant's image once the customer selects a variant (falling
    // back to the product image when a variant has no image).
    final heroImageUrl = (_hasUserSelectedVariant &&
            selectedVariantImage != null &&
            selectedVariantImage.isNotEmpty)
        ? selectedVariantImage
        : productMainImage;

    // For Fly-to-Cart: fly the selected variant's image URL if a variant is
    // selected and defines one; otherwise the product's main image URL.
    final flyRawImageUrl =
        (selectedVariantImage != null && selectedVariantImage.isNotEmpty)
            ? selectedVariantImage
            : productMainImage;
    final formattedFlyUrl = (flyRawImageUrl != null && flyRawImageUrl.isNotEmpty)
        ? ImageUtils.formatImageUrl(flyRawImageUrl)
        : '';

    final productOptionGroups =
        item['optionGroups'] as List<dynamic>? ?? const [];
    final variantOptionGroups =
        _selectedVariant?['optionGroups'] as List<dynamic>? ?? const [];
    final optionGroups = [...productOptionGroups, ...variantOptionGroups];

    bool requiredMet = true;
    if (hasVariants && _selectedVariant == null) {
      requiredMet = false;
    }
    for (final group in optionGroups) {
      final minSelect = (group['minSelect'] as num?)?.toInt() ??
          int.tryParse(group['minSelect']?.toString() ?? '0') ??
          0;
      final effectiveMin = group['isRequired'] == true
          ? (minSelect > 0 ? minSelect : 1)
          : minSelect;
      if (effectiveMin > 0) {
        final gId = group['id']?.toString() ?? '';
        final count = _selectedOptions[gId]?.length ?? 0;
        if (count < effectiveMin) {
          requiredMet = false;
          break;
        }
      }
    }

    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Stack(
      children: [
        // Clicking anywhere outside the product sheet closes it automatically
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('product_bottom_sheet_backdrop'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 430,
              maxHeight: maxSheetHeight,
            ),
            child: Container(
              key: const ValueKey('product_bottom_sheet_container'),
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.bgCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: const Border(
                  top: BorderSide(
                    color: Color.fromRGBO(229, 169, 60, 0.40),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle (44x4, muted 40%, centered)
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.textMuted.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Scrollable inner body when options/variants are tall
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Large Preview Image (full width, 190px, zoomed-out BoxFit.contain so full product is visible)
                              Stack(
                                children: [
                                  Container(
                                    key: _previewImageKey,
                                    width: double.infinity,
                                    height: 190,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: palette.bgCard2,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: palette.borderGold,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: (heroImageUrl == null ||
                                                heroImageUrl.isEmpty)
                                            ? Container(
                                                key: const ValueKey(
                                                  'empty_hero_image',
                                                ),
                                                width: double.infinity,
                                                height: 174,
                                                color: palette.bgCard2,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.fastfood_rounded,
                                                  size: 52,
                                                  color: palette.textMuted,
                                                ),
                                              )
                                            : SizedBox(
                                                key: ValueKey(heroImageUrl),
                                                width: double.infinity,
                                                height: 174,
                                                child:
                                                    TransparentBgNetworkImage(
                                                  imageUrl:
                                                      ImageUtils.formatImageUrl(
                                                        heroImageUrl,
                                                      ),
                                                  mode: BackgroundRemovalMode
                                                      .autoUniform,
                                                  fit: BoxFit.contain,
                                                  maxCacheDimension: 480,
                                                  placeholderBuilder: (_) =>
                                                      ColoredBox(
                                                        color: palette.bgCard2,
                                                      ),
                                                  fallbackBuilder: (_) =>
                                                      Center(
                                                        child: Icon(
                                                          Icons
                                                              .fastfood_rounded,
                                                          size: 44,
                                                          color:
                                                              palette.textMuted,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (isOutOfStock && currentQty == 0)
                                    PositionedDirectional(
                                      end: 10,
                                      bottom: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.75,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          s.outOfStock,
                                          style: StoreDetailPalette.text(
                                            size: 12,
                                            weight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Title & Dynamic Price Row (both 18px w900; price in Inter goldText)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: StoreDetailPalette.text(
                                        size: 18,
                                        weight: FontWeight.w900,
                                        color: palette.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${currentUnitPrice.toStringAsFixed(currentUnitPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                                        style: StoreDetailPalette.numeric(
                                          size: 18,
                                          weight: FontWeight.w900,
                                          color: palette.goldText,
                                          height: 1.2,
                                        ),
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${originalUnitPrice.toStringAsFixed(originalUnitPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                                              style: StoreDetailPalette.numeric(
                                                size: 12,
                                                weight: FontWeight.w600,
                                                color: palette.textMuted,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                decorationColor:
                                                    palette.textMuted,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: palette.gold,
                                                borderRadius:
                                                    BorderRadius.circular(9999),
                                              ),
                                              child: Text(
                                                '-$discountPercentage%',
                                                style:
                                                    StoreDetailPalette.numeric(
                                                      size: 10,
                                                      weight: FontWeight.w900,
                                                      color: palette.darkOnGold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),

                              if (description.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  description.trim(),
                                  style: StoreDetailPalette.text(
                                    size: 13,
                                    weight: FontWeight.w400,
                                    color: palette.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],

                              // Pharmacy Selling Unit (Package vs Strip)
                              if (supportsStrips) ...[
                                const SizedBox(height: 14),
                                Text(
                                  s.sellingUnit,
                                  style: StoreDetailPalette.text(
                                    size: 13.5,
                                    weight: FontWeight.w800,
                                    color: palette.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildUnitOption(
                                        label: s.package,
                                        isSelected: _selectedUnit == 'package',
                                        price: effectiveBasePrice,
                                        s: s,
                                        palette: palette,
                                        onTap: () => setState(
                                          () => _selectedUnit = 'package',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildUnitOption(
                                        label: s.strip,
                                        isSelected: _selectedUnit == 'strip',
                                        price: effectiveBasePrice / stripsCount,
                                        s: s,
                                        palette: palette,
                                        onTap: () => setState(
                                          () => _selectedUnit = 'strip',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Variants Section (max-height: 190px, 44x44 zoomed-out thumbnails, 20x20 check circle)
                              if (hasVariants) ...[
                                const SizedBox(height: 14),
                                Text(
                                  s.selectVariant,
                                  style: StoreDetailPalette.text(
                                    size: 13.5,
                                    weight: FontWeight.w800,
                                    color: palette.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 190,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: variants.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, idx) {
                                      final v = Map<String, dynamic>.from(
                                        variants[idx] as Map,
                                      );
                                      return _buildVariantRow(
                                        v: v,
                                        productMainImage: productMainImage,
                                        isAr: isAr,
                                        s: s,
                                        palette: palette,
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Option Groups Section
                              if (optionGroups.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                ...optionGroups.map(
                                  (group) => _buildOptionGroupCard(
                                    group: Map<String, dynamic>.from(
                                      group as Map,
                                    ),
                                    isAr: isAr,
                                    s: s,
                                    palette: palette,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Primary CTA Button (إضافة للسلة) or Quantity Stepper
                      _buildBottomCta(
                        context: context,
                        item: item,
                        s: s,
                        isAr: isAr,
                        palette: palette,
                        isOutOfStock: isOutOfStock,
                        atStockLimit: atStockLimit,
                        currentQty: currentQty,
                        currentCartItem: currentCartItem,
                        requiredMet: requiredMet,
                        optionGroups: optionGroups,
                        flatOptions: flatOptions,
                        formattedFlyUrl: formattedFlyUrl,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantRow({
    required Map<String, dynamic> v,
    required String? productMainImage,
    required bool isAr,
    required AppStrings s,
    required StoreDetailPalette palette,
  }) {
    final vName = (isAr &&
                v['nameAr'] != null &&
                v['nameAr'].toString().isNotEmpty
            ? v['nameAr']
            : (v['name'] ?? ''))
        .toString();
    final effectiveVPrice =
        double.tryParse((v['price'] ?? v['basePrice'])?.toString() ?? '0') ??
            0.0;
    final originalVPrice =
        double.tryParse((v['comparePrice'] ?? v['basePrice'])?.toString() ?? '') ??
            effectiveVPrice;
    final hasVDiscount = originalVPrice > effectiveVPrice;
    final vId = v['id']?.toString() ?? '';
    final isVSelected = _selectedVariant?['id']?.toString() == vId;

    // Per-variant image, falling back to product's main image.
    final rawVariantImg = (v['imageUrl'] ?? v['image'])?.toString().trim();
    final resolvedThumbRaw = (rawVariantImg != null && rawVariantImg.isNotEmpty)
        ? rawVariantImg
        : productMainImage;
    final formattedThumbUrl =
        (resolvedThumbRaw != null && resolvedThumbRaw.isNotEmpty)
            ? ImageUtils.thumbnailUrl(resolvedThumbRaw)
            : '';

    void selectVariant() {
      setState(() {
        _hasUserSelectedVariant = true;
        _selectedVariant = v;
        final productGroupIds =
            (widget.item['optionGroups'] as List<dynamic>? ?? const [])
                .map((g) => g['id']?.toString() ?? '')
                .toSet();
        _selectedOptions.removeWhere(
          (groupId, _) => !productGroupIds.contains(groupId),
        );
        final vOptionGroups = v['optionGroups'] as List<dynamic>? ?? const [];
        for (final g in vOptionGroups) {
          _initGroupSelection(g as Map);
        }
      });
    }

    return Material(
      color: isVSelected
          ? const Color.fromRGBO(229, 169, 60, 0.15)
          : palette.bgCard2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('variant_row_$vId'),
        onTap: selectVariant,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isVSelected ? palette.gold : palette.borderGold,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Per-Variant 44x44 Thumbnail (radius 10, zoomed-out BoxFit.contain)
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: palette.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isVSelected ? palette.gold : palette.borderGold,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: formattedThumbUrl.isNotEmpty
                      ? TransparentBgNetworkImage(
                          imageUrl: formattedThumbUrl,
                          mode: BackgroundRemovalMode.autoUniform,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          maxCacheDimension: 140,
                          placeholderBuilder: (_) =>
                              ColoredBox(color: palette.bgCard),
                          fallbackBuilder: (_) => Center(
                            child: Icon(
                              Icons.fastfood_rounded,
                              size: 18,
                              color: palette.textMuted,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.fastfood_rounded,
                            size: 18,
                            color: palette.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Variant Name (13.5px w800 truncate)
              Expanded(
                child: Text(
                  vName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StoreDetailPalette.text(
                    size: 13.5,
                    weight: FontWeight.w800,
                    color: isVSelected
                        ? palette.textPrimary
                        : palette.textMuted,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Variant Price (13.5px Inter w900 goldText)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasVDiscount) ...[
                    Text(
                      originalVPrice.toStringAsFixed(
                        originalVPrice % 1 == 0 ? 0 : 2,
                      ),
                      style: StoreDetailPalette.numeric(
                        size: 11,
                        weight: FontWeight.w600,
                        color: palette.textMuted,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: palette.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${effectiveVPrice.toStringAsFixed(effectiveVPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                    style: StoreDetailPalette.numeric(
                      size: 13.5,
                      weight: FontWeight.w900,
                      color: palette.goldText,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Selection Indicator (20x20 circle, 12px check when selected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isVSelected ? palette.gold : Colors.transparent,
                  border: Border.all(
                    color: isVSelected ? palette.gold : palette.borderGold,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: isVSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: palette.darkOnGold,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionGroupCard({
    required Map<String, dynamic> group,
    required bool isAr,
    required AppStrings s,
    required StoreDetailPalette palette,
  }) {
    final gName = (isAr &&
                group['nameAr'] != null &&
                group['nameAr'].toString().isNotEmpty
            ? group['nameAr']
            : (group['name'] ?? ''))
        .toString();
    final options = group['options'] as List<dynamic>? ?? const [];
    final isRequired = group['isRequired'] == true;
    final minSelect = group['minSelect'] is int
        ? group['minSelect'] as int
        : int.tryParse(
                group['minSelect']?.toString() ?? (isRequired ? '1' : '0'),
              ) ??
            (isRequired ? 1 : 0);
    final maxSelect = group['maxSelect'] is int
        ? group['maxSelect'] as int
        : int.tryParse(group['maxSelect']?.toString() ?? '1') ?? 1;
    final gId = group['id']?.toString() ?? '';
    final selectedCount = (_selectedOptions[gId] ?? const []).length;
    final effectiveMin = isRequired ? (minSelect > 0 ? minSelect : 1) : minSelect;
    final isGroupSatisfied =
        effectiveMin == 0 || selectedCount >= effectiveMin;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.bgCard2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !isGroupSatisfied
              ? Colors.redAccent.withValues(alpha: 0.5)
              : palette.borderGold,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gName,
                      style: StoreDetailPalette.text(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      maxSelect == 1
                          ? (isRequired
                              ? (isAr
                                  ? 'اختر 1 (إجباري)'
                                  : 'Choose 1 (Required)')
                              : (isAr
                                  ? 'اختر 1 (اختياري)'
                                  : 'Choose 1 (Optional)'))
                          : (effectiveMin > 0
                              ? (isAr
                                  ? 'اختر على الأقل $effectiveMin'
                                  : 'Choose at least $effectiveMin')
                              : (isAr
                                  ? 'اختر حتى $maxSelect (اختياري)'
                                  : 'Choose up to $maxSelect (Optional)')),
                      style: StoreDetailPalette.text(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: effectiveMin > 0
                      ? (isGroupSatisfied
                          ? palette.gold.withValues(alpha: 0.16)
                          : Colors.redAccent.withValues(alpha: 0.12))
                      : palette.bgCard,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: effectiveMin > 0
                        ? (isGroupSatisfied ? palette.gold : Colors.redAccent)
                        : palette.borderGold,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  effectiveMin > 0
                      ? (isGroupSatisfied
                          ? (isAr ? '✓ مكتمل' : '✓ Done')
                          : (isAr ? 'مطلوب' : 'Required'))
                      : (isAr ? 'اختياري' : 'Optional'),
                  style: StoreDetailPalette.text(
                    size: 10,
                    weight: FontWeight.w800,
                    color: effectiveMin > 0
                        ? (isGroupSatisfied
                            ? palette.goldText
                            : Colors.redAccent)
                        : palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...options.map((rawOpt) {
            final opt = Map<String, dynamic>.from(rawOpt as Map);
            final oName = (isAr &&
                        opt['nameAr'] != null &&
                        opt['nameAr'].toString().isNotEmpty
                    ? opt['nameAr']
                    : (opt['name'] ?? ''))
                .toString();
            final oPrice =
                double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0.0;
            final optId = opt['id']?.toString() ?? '';
            final isSelected = (_selectedOptions[gId] ?? const [])
                .any((o) => o['id']?.toString() == optId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: isSelected
                    ? const Color.fromRGBO(229, 169, 60, 0.15)
                    : palette.bgCard,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _toggleOption(group, opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? palette.gold : palette.borderGold,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: maxSelect == 1
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            borderRadius: maxSelect == 1
                                ? null
                                : BorderRadius.circular(4),
                            color:
                                isSelected ? palette.gold : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? palette.gold
                                  : palette.borderGold,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 9,
                                  color: palette.darkOnGold,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            oName,
                            style: StoreDetailPalette.text(
                              size: 12,
                              weight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? palette.textPrimary
                                  : palette.textMuted,
                            ),
                          ),
                        ),
                        if (oPrice > 0)
                          Text(
                            '+${oPrice.toStringAsFixed(oPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                            style: StoreDetailPalette.numeric(
                              size: 11.5,
                              weight: FontWeight.w800,
                              color: palette.goldText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomCta({
    required BuildContext context,
    required Map<String, dynamic> item,
    required AppStrings s,
    required bool isAr,
    required StoreDetailPalette palette,
    required bool isOutOfStock,
    required bool atStockLimit,
    required int currentQty,
    required CartItem? currentCartItem,
    required bool requiredMet,
    required List<dynamic> optionGroups,
    required List<Map<String, dynamic>> flatOptions,
    required String formattedFlyUrl,
  }) {
    if (isOutOfStock && currentQty == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.bgCard2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.borderGold),
        ),
        alignment: Alignment.center,
        child: Text(
          s.outOfStock,
          style: StoreDetailPalette.text(
            size: 14,
            weight: FontWeight.w900,
            color: palette.textMuted,
          ),
        ),
      );
    }

    if (currentQty == 0) {
      return Material(
        color: requiredMet ? palette.gold : palette.bgCard2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const ValueKey('product_sheet_add_to_cart_btn'),
          hoverColor: palette.goldHover,
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (!requiredMet) {
              String? missingGroupName;
              for (final g in optionGroups) {
                final minS = g['minSelect'] is int
                    ? g['minSelect'] as int
                    : int.tryParse(g['minSelect']?.toString() ?? '0') ?? 0;
                final effectiveMin = g['isRequired'] == true
                    ? (minS > 0 ? minS : 1)
                    : minS;
                if (effectiveMin > 0) {
                  final c =
                      (_selectedOptions[g['id']?.toString()] ?? const []).length;
                  if (c < effectiveMin) {
                    missingGroupName = (isAr &&
                                g['nameAr'] != null &&
                                g['nameAr'].toString().isNotEmpty
                            ? g['nameAr']
                            : g['name'])
                        ?.toString();
                    break;
                  }
                }
              }
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    missingGroupName != null
                        ? (isAr
                            ? 'برجاء تحديد: $missingGroupName'
                            : 'Please select: $missingGroupName')
                        : (isAr
                            ? 'برجاء تحديد الخيارات المطلوبة'
                            : 'Please select required options'),
                  ),
                  backgroundColor: Colors.redAccent,
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

            // CRITICAL Step 1: Capture the 160px preview image's global Rect
            // BEFORE closing/dismissing the bottom sheet.
            final srcRect = _capturePreviewRect();
            final cartNotifier = ref.read(cartProvider.notifier);
            final selectedUnit = _selectedUnit;
            final selectedVariant = _selectedVariant;
            final optionsCopy = List<Map<String, dynamic>>.from(flatOptions);

            // Close the sheet immediately and launch the flying image from srcRect.
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            widget.onFlyToCart?.call(srcRect, formattedFlyUrl);

            try {
              await cartNotifier.addItem(
                {
                  ...item,
                  'vendorId': widget.restaurant['id'],
                  'vendorName': widget.restaurant['name'],
                },
                unit: selectedUnit,
                variant: selectedVariant,
                options: optionsCopy,
              );
            } catch (e) {
              if (widget.onAddError != null) {
                widget.onAddError!(e);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ErrorUtils.translate(context, e)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            alignment: Alignment.center,
            child: Text(
              requiredMet
                  ? s.addToCart
                  : (isAr
                      ? 'تحديد الخيارات المطلوبة'
                      : 'Select Required Options'),
              textAlign: TextAlign.center,
              style: StoreDetailPalette.text(
                size: 15.5,
                weight: FontWeight.w900,
                color: requiredMet ? palette.darkOnGold : palette.textMuted,
                height: 1.2,
              ),
            ),
          ),
        ),
      );
    }

    // Item already in cart: stepper + Done button
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(229, 169, 60, 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.gold, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: palette.goldText,
                    size: 22,
                  ),
                  onPressed: () {
                    final authStatus = ref.read(authControllerProvider);
                    if (authStatus == AuthStatus.unauthenticated) {
                      AuthPromptDialog.show(context);
                      return;
                    }
                    ref
                        .read(cartProvider.notifier)
                        .updateQuantity(currentCartItem!, currentQty - 1);
                  },
                ),
                Text(
                  '$currentQty',
                  style: StoreDetailPalette.numeric(
                    size: 16,
                    weight: FontWeight.w900,
                    color: palette.goldText,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 22,
                    color: atStockLimit
                        ? palette.goldText.withValues(alpha: 0.35)
                        : palette.goldText,
                  ),
                  onPressed: () async {
                    final authStatus = ref.read(authControllerProvider);
                    if (authStatus == AuthStatus.unauthenticated) {
                      AuthPromptDialog.show(context);
                      return;
                    }
                    if (atStockLimit) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s.outOfStock),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    final srcRect = _capturePreviewRect();
                    widget.onFlyToCart?.call(srcRect, formattedFlyUrl);
                    try {
                      await ref
                          .read(cartProvider.notifier)
                          .updateQuantity(currentCartItem!, currentQty + 1);
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
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: palette.gold,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Text(
                  s.done,
                  style: StoreDetailPalette.text(
                    size: 14,
                    weight: FontWeight.w900,
                    color: palette.darkOnGold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int? _parseStock(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Widget _buildUnitOption({
    required String label,
    required bool isSelected,
    required double price,
    required AppStrings s,
    required StoreDetailPalette palette,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(229, 169, 60, 0.15)
              : palette.bgCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? palette.gold : palette.borderGold,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: StoreDetailPalette.text(
                size: 12,
                weight: FontWeight.w800,
                color: isSelected ? palette.textPrimary : palette.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} ${s.egp}',
              style: StoreDetailPalette.numeric(
                size: 11.5,
                weight: FontWeight.w900,
                color: palette.goldText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
