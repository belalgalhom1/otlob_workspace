import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import 'store_details_tokens.dart';

typedef ProductFlyAddCallback = void Function(
  Rect? previewRect,
  String? imageUrl,
  Future<void> Function() commitAdd,
  String displayName,
);

class ProductBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> restaurant;
  final String initialUnit;
  final String? initialVariantId;
  final AppStrings s;
  final bool isDark;
  final bool isPharmacy;
  final ProductFlyAddCallback? onRequestFlyAdd;

  const ProductBottomSheet({
    super.key,
    required this.item,
    required this.restaurant,
    required this.initialUnit,
    this.initialVariantId,
    required this.s,
    required this.isDark,
    required this.isPharmacy,
    this.onRequestFlyAdd,
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

    final variants = widget.item['variants'] as List<dynamic>? ?? [];
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
            final vTracks = v['tracksStock'] == null
                ? true
                : (v['tracksStock'] == true);
            final vStock = _parseStock(v['stock']);
            return !(vTracks && vStock != null && vStock <= 0);
          })
          .firstOrNull;
      _selectedVariant =
          initialSelected ?? Map<String, dynamic>.from(variants.first as Map);
    }

    _initOptionGroupDefaults(widget.item['optionGroups'] as List<dynamic>?);
    if (_selectedVariant != null) {
      _initOptionGroupDefaults(
        _selectedVariant!['optionGroups'] as List<dynamic>?,
      );
    }
  }

  void _initOptionGroupDefaults(List<dynamic>? groups) {
    if (groups == null) return;
    for (final group in groups) {
      if (group is! Map) continue;
      final gId = group['id']?.toString() ?? '';
      final isRequired = group['isRequired'] == true;
      final maxSelect = (group['maxSelect'] as num?)?.toInt() ??
          int.tryParse(group['maxSelect']?.toString() ?? '1') ??
          1;
      final options = group['options'] as List<dynamic>? ?? [];
      if (isRequired && maxSelect == 1 && options.isNotEmpty) {
        _selectedOptions[gId] = [Map<String, dynamic>.from(options.first as Map)];
      } else {
        _selectedOptions[gId] = [];
      }
    }
  }

  bool _areOptionsEqual(List<CartOptionRef> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((o) => o.id).toSet();
    final bIds = b.map((o) => o['id']?.toString() ?? '').toSet();
    return aIds.containsAll(bIds);
  }

  void _toggleOption(Map<String, dynamic> group, Map<String, dynamic> option) {
    final groupId = group['id']?.toString() ?? '';
    final isRequired = group['isRequired'] == true;
    final maxSelect = (group['maxSelect'] as num?)?.toInt() ??
        int.tryParse(group['maxSelect']?.toString() ?? '1') ??
        1;
    final safeMax = maxSelect <= 0 ? 1 : maxSelect;
    final list =
        List<Map<String, dynamic>>.from(_selectedOptions[groupId] ?? []);
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
        } else if (list.length < safeMax) {
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
      _selectedOptions[groupId] = list;
    });
  }

  void _selectVariant(Map<String, dynamic> v) {
    setState(() {
      _hasUserSelectedVariant = true;
      _selectedVariant = v;
      final productGroupIds =
          (widget.item['optionGroups'] as List<dynamic>? ?? [])
              .map((g) => g['id']?.toString() ?? '')
              .toSet();
      _selectedOptions
          .removeWhere((groupId, _) => !productGroupIds.contains(groupId));
      _initOptionGroupDefaults(v['optionGroups'] as List<dynamic>?);
    });
  }

  Rect? _capturePreviewRect() {
    final renderBox =
        _previewImageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    return topLeft & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final s = widget.s;
    final palette = StoreDetailsPalette.fromBrightness(widget.isDark);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final flatOptions =
        _selectedOptions.values.expand((list) => list).toList();
    final cartAllItems = ref.watch(cartProvider).allItems;

    final currentCartItem = cartAllItems.where((ci) {
      return ci.product.id == item['id']?.toString() &&
          ci.selectedUnit == _selectedUnit &&
          ci.selectedVariant?.id == _selectedVariant?['id']?.toString() &&
          _areOptionsEqual(ci.selectedOptions, flatOptions);
    }).firstOrNull;
    final currentQty = currentCartItem?.quantity ?? 0;

    final bool productTracksStock = item['tracksStock'] == null
        ? true
        : (item['tracksStock'] == true);
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
            .where((ci) =>
                ci.selectedVariant?.id == _selectedVariant!['id']?.toString())
            .fold<int>(0, (sum, ci) => sum + convertedLineQty(ci));
      }
    } else if (productTracksStock && productStock != null) {
      stockLimit = productStock * divider;
      stockPoolQty = cartAllItems
          .where((ci) =>
              ci.product.id == item['id']?.toString() &&
              ci.selectedVariant == null)
          .fold<int>(0, (sum, ci) => sum + convertedLineQty(ci));
    }

    final bool isOutOfStock = stockLimit != null
        ? stockPoolQty >= stockLimit
        : (_selectedVariant != null
            ? variantTracksStock && variantStock != null && variantStock <= 0
            : productTracksStock &&
                productStock != null &&
                productStock <= 0);
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
      effectiveBasePrice =
          double.tryParse(effectiveP?.toString() ?? '0') ?? 0.0;

      final compareP =
          _selectedVariant!['comparePrice'] ?? _selectedVariant!['basePrice'];
      originalBasePrice =
          double.tryParse(compareP?.toString() ?? '0') ?? effectiveBasePrice;
    } else {
      final effectiveP = item['price'] ?? item['basePrice'];
      effectiveBasePrice =
          double.tryParse(effectiveP?.toString() ?? '0') ?? 0.0;

      final compareP = item['comparePrice'] ?? effectiveBasePrice;
      originalBasePrice =
          double.tryParse(compareP?.toString() ?? '0') ?? effectiveBasePrice;
    }

    double optionsTotal = 0.0;
    for (final opt in flatOptions) {
      optionsTotal +=
          double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0.0;
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

    final name = isAr &&
            item['nameAr'] != null &&
            item['nameAr'].toString().trim().isNotEmpty
        ? item['nameAr'].toString().trim()
        : (item['name']?.toString().trim() ?? '');
    final description = isAr &&
            item['descriptionAr'] != null &&
            item['descriptionAr'].toString().trim().isNotEmpty
        ? item['descriptionAr'].toString().trim()
        : (item['description']?.toString().trim() ?? '');

    final variants = (item['variants'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
    final bool hasVariants =
        (item['hasVariants'] == true || variants.isNotEmpty) &&
            variants.isNotEmpty;

    final productMainImage =
        (item['imageUrl'] ?? item['image'])?.toString().trim();
    final selectedVariantImage =
        (_selectedVariant?['imageUrl'] ?? _selectedVariant?['image'])
            ?.toString()
            .trim();
    // Start with product image on open; swap hero image when user selects a
    // variant that has its own image (preserving variant image contract).
    final heroImageUrl = (_hasUserSelectedVariant &&
            selectedVariantImage != null &&
            selectedVariantImage.isNotEmpty)
        ? selectedVariantImage
        : productMainImage;

    final productOptionGroups = item['optionGroups'] as List<dynamic>? ?? [];
    final variantOptionGroups =
        _selectedVariant?['optionGroups'] as List<dynamic>? ?? [];
    final optionGroups = [...productOptionGroups, ...variantOptionGroups];

    bool requiredMet = true;
    if (hasVariants && _selectedVariant == null) {
      requiredMet = false;
    }
    for (final group in optionGroups) {
      if (group is! Map) continue;
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

    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: maxSheetHeight,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.bgCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: palette.sheetTopBorder, width: 1),
              left: BorderSide(color: palette.sheetTopBorder, width: 1),
              right: BorderSide(color: palette.sheetTopBorder, width: 1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.55),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle (40x4)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),

                // Scrollable Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 160px Preview Image
                        Stack(
                          children: [
                            Container(
                              key: _previewImageKey,
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: palette.bgCard2,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: palette.borderGold,
                                  width: 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: (heroImageUrl == null ||
                                        heroImageUrl.isEmpty)
                                    ? SizedBox.expand(
                                        key: const ValueKey('empty_hero_image'),
                                        child: Center(
                                          child: Icon(
                                            Icons.fastfood_rounded,
                                            size: 52,
                                            color: palette.textMuted
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      )
                                    : SizedBox.expand(
                                        key: ValueKey(heroImageUrl),
                                        child: CachedNetworkImage(
                                          imageUrl: ImageUtils.formatImageUrl(
                                            heroImageUrl,
                                          ),
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: StoreDetailsTokens.gold
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (_, _, _) => Center(
                                            child: Icon(
                                              Icons.fastfood_rounded,
                                              size: 48,
                                              color: palette.textMuted
                                                  .withValues(alpha: 0.45),
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
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.remove_shopping_cart_outlined,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        s.outOfStock,
                                        style: StoreDetailsTokens.text(
                                          size: 11,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Product Title (16px w900) & Dynamic Price (16px Inter w900)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: StoreDetailsTokens.text(
                                  size: 16,
                                  weight: FontWeight.w900,
                                  color: palette.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${StoreDetailsTokens.formatPrice(currentUnitPrice)} ${s.egp}',
                                  style: StoreDetailsTokens.numeric(
                                    size: 16,
                                    weight: FontWeight.w900,
                                    color: palette.goldText,
                                  ),
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${StoreDetailsTokens.formatPrice(originalUnitPrice)} ${s.egp}',
                                        style: StoreDetailsTokens.numeric(
                                          size: 11,
                                          weight: FontWeight.w600,
                                          color: palette.textMuted,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: palette.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: StoreDetailsTokens.gold,
                                          borderRadius:
                                              BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          '-$discountPercentage%',
                                          style: StoreDetailsTokens.numeric(
                                            size: 9,
                                            weight: FontWeight.w900,
                                            color:
                                                StoreDetailsTokens.darkOnGold,
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

                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: StoreDetailsTokens.text(
                              size: 11.5,
                              weight: FontWeight.w500,
                              color: palette.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],

                        // Pharmacy Selling Unit (Package / Strip)
                        if (supportsStrips) ...[
                          const SizedBox(height: 12),
                          Text(
                            s.sellingUnit,
                            style: StoreDetailsTokens.text(
                              size: 12,
                              weight: FontWeight.w800,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildUnitOption(
                                  palette: palette,
                                  label: s.package,
                                  isSelected: _selectedUnit == 'package',
                                  price: effectiveBasePrice,
                                  s: s,
                                  onTap: () => setState(
                                    () => _selectedUnit = 'package',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildUnitOption(
                                  palette: palette,
                                  label: s.strip,
                                  isSelected: _selectedUnit == 'strip',
                                  price: effectiveBasePrice / stripsCount,
                                  s: s,
                                  onTap: () => setState(
                                    () => _selectedUnit = 'strip',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Variants Selector (with 36x36 thumbnail & 16x16 gold check)
                        if (hasVariants) ...[
                          const SizedBox(height: 12),
                          Text(
                            s.selectVariant,
                            style: StoreDetailsTokens.text(
                              size: 12,
                              weight: FontWeight.w800,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildVariantsSection(
                            variants: variants,
                            palette: palette,
                            isAr: isAr,
                            s: s,
                            productMainImage: productMainImage,
                            constrainHeight:
                                optionGroups.isEmpty && !supportsStrips,
                          ),
                        ],

                        // Option Groups (preserved real backend modifiers)
                        if (optionGroups.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...optionGroups.whereType<Map>().map(
                                (g) => _buildOptionGroupCard(
                                  group: Map<String, dynamic>.from(g),
                                  palette: palette,
                                  isAr: isAr,
                                  s: s,
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Action Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: _buildFooterCta(
                    context: context,
                    palette: palette,
                    s: s,
                    isAr: isAr,
                    isOutOfStock: isOutOfStock,
                    atStockLimit: atStockLimit,
                    requiredMet: requiredMet,
                    currentQty: currentQty,
                    currentCartItem: currentCartItem,
                    optionGroups: optionGroups,
                    flatOptions: flatOptions,
                    item: item,
                    displayProductName: name,
                    selectedVariantImage: selectedVariantImage,
                    productMainImage: productMainImage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantsSection({
    required List<Map<String, dynamic>> variants,
    required StoreDetailsPalette palette,
    required bool isAr,
    required AppStrings s,
    required String? productMainImage,
    required bool constrainHeight,
  }) {
    final rows = List<Widget>.generate(variants.length, (index) {
      final v = variants[index];
      final vId = v['id']?.toString() ?? '';
      final isSelected = _selectedVariant?['id']?.toString() == vId;
      final vName = (isAr &&
              v['nameAr'] != null &&
              v['nameAr'].toString().trim().isNotEmpty)
          ? v['nameAr'].toString().trim()
          : (v['name']?.toString().trim() ?? '');
      final effectiveVPrice =
          double.tryParse((v['price'] ?? v['basePrice'])?.toString() ?? '0') ??
              0.0;
      final originalVPrice = double.tryParse(
              (v['comparePrice'] ?? v['basePrice'])?.toString() ?? '0') ??
          effectiveVPrice;
      final hasVDiscount = originalVPrice > effectiveVPrice;
      final vImageRaw = (v['imageUrl'] ?? v['image'])?.toString().trim() ?? '';
      final thumbUrl =
          vImageRaw.isNotEmpty ? vImageRaw : (productMainImage ?? '');

      final vTracks = v['tracksStock'] == null
          ? (widget.item['tracksStock'] == null
              ? true
              : widget.item['tracksStock'] == true)
          : v['tracksStock'] == true;
      final vStock = _parseStock(v['stock']);
      final vSoldOut = vTracks && vStock != null && vStock <= 0;

      return Padding(
        padding: EdgeInsets.only(bottom: index == variants.length - 1 ? 0 : 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectVariant(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? StoreDetailsTokens.gold.withValues(alpha: 0.15)
                    : palette.bgCard2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? StoreDetailsTokens.gold
                      : palette.borderGold,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 36x36 Per-Variant Thumbnail
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? StoreDetailsTokens.gold
                            : palette.borderGold,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: thumbUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ImageUtils.thumbnailUrl(thumbUrl),
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Icon(
                              Icons.fastfood_rounded,
                              size: 16,
                              color: palette.textMuted.withValues(alpha: 0.5),
                            ),
                          )
                        : Icon(
                            Icons.fastfood_rounded,
                            size: 16,
                            color: palette.textMuted.withValues(alpha: 0.5),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StoreDetailsTokens.text(
                            size: 12,
                            weight: FontWeight.w800,
                            color: isSelected
                                ? palette.textPrimary
                                : palette.textPrimary.withValues(
                                    alpha: vSoldOut ? 0.5 : 0.88,
                                  ),
                          ),
                        ),
                        if (vSoldOut)
                          Text(
                            s.outOfStock,
                            style: StoreDetailsTokens.text(
                              size: 9.5,
                              weight: FontWeight.w700,
                              color: StoreDetailsTokens.errorRed,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${StoreDetailsTokens.formatPrice(effectiveVPrice)} ${s.egp}',
                        style: StoreDetailsTokens.numeric(
                          size: 12,
                          weight: FontWeight.w900,
                          color: palette.goldText,
                        ),
                      ),
                      if (hasVDiscount)
                        Text(
                          '${StoreDetailsTokens.formatPrice(originalVPrice)} ${s.egp}',
                          style: StoreDetailsTokens.numeric(
                            size: 10,
                            weight: FontWeight.w600,
                            color: palette.textMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: palette.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // 16x16 Circular Gold Checkmark
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? StoreDetailsTokens.gold
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? StoreDetailsTokens.gold
                            : palette.textMuted,
                        width: 1.3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: StoreDetailsTokens.darkOnGold,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    if (constrainHeight) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 176),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _buildOptionGroupCard({
    required Map<String, dynamic> group,
    required StoreDetailsPalette palette,
    required bool isAr,
    required AppStrings s,
  }) {
    final gName = (isAr &&
            group['nameAr'] != null &&
            group['nameAr'].toString().trim().isNotEmpty)
        ? group['nameAr'].toString().trim()
        : (group['name']?.toString().trim() ?? '');
    final options = (group['options'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((o) => Map<String, dynamic>.from(o))
        .toList();
    final isRequired = group['isRequired'] == true;
    final minSelect = group['minSelect'] is int
        ? group['minSelect'] as int
        : int.tryParse(
                group['minSelect']?.toString() ?? (isRequired ? '1' : '0')) ??
            (isRequired ? 1 : 0);
    final maxSelect = group['maxSelect'] is int
        ? group['maxSelect'] as int
        : int.tryParse(group['maxSelect']?.toString() ?? '1') ?? 1;
    final gId = group['id']?.toString() ?? '';
    final selectedCount = (_selectedOptions[gId] ?? []).length;
    final effectiveMin =
        isRequired ? (minSelect > 0 ? minSelect : 1) : minSelect;
    final isGroupSatisfied = effectiveMin <= 0 || selectedCount >= effectiveMin;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.bgCard2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !isGroupSatisfied
              ? StoreDetailsTokens.errorRed.withValues(alpha: 0.55)
              : palette.borderGold,
          width: !isGroupSatisfied ? 1.3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gName,
                      style: StoreDetailsTokens.text(
                        size: 13,
                        weight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                      style: StoreDetailsTokens.text(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: effectiveMin > 0
                      ? (isGroupSatisfied
                          ? StoreDetailsTokens.successGreen
                              .withValues(alpha: 0.14)
                          : StoreDetailsTokens.errorRed.withValues(alpha: 0.14))
                      : palette.bgCard,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: effectiveMin > 0
                        ? (isGroupSatisfied
                            ? StoreDetailsTokens.successGreen
                            : StoreDetailsTokens.errorRed)
                        : palette.borderGold,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  effectiveMin > 0
                      ? (isGroupSatisfied
                          ? (isAr ? '✓ مكتمل' : '✓ Completed')
                          : (isAr ? '* مطلوب' : '* Required'))
                      : (isAr ? 'اختياري' : 'Optional'),
                  style: StoreDetailsTokens.text(
                    size: 10,
                    weight: FontWeight.w800,
                    color: effectiveMin > 0
                        ? (isGroupSatisfied
                            ? StoreDetailsTokens.successGreen
                            : StoreDetailsTokens.errorRed)
                        : palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...options.map((opt) {
            final oName = (isAr &&
                    opt['nameAr'] != null &&
                    opt['nameAr'].toString().trim().isNotEmpty)
                ? opt['nameAr'].toString().trim()
                : (opt['name']?.toString().trim() ?? '');
            final oPrice =
                double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0.0;
            final optId = opt['id']?.toString() ?? '';
            final isSelected = (_selectedOptions[gId] ?? [])
                .any((o) => o['id']?.toString() == optId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _toggleOption(group, opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? StoreDetailsTokens.gold.withValues(alpha: 0.14)
                          : palette.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? StoreDetailsTokens.gold
                            : palette.borderGold,
                        width: isSelected ? 1.3 : 0.8,
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
                            color: isSelected
                                ? StoreDetailsTokens.gold
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? StoreDetailsTokens.gold
                                  : palette.textMuted,
                              width: 1.3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 11,
                                  color: StoreDetailsTokens.darkOnGold,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            oName,
                            style: StoreDetailsTokens.text(
                              size: 12,
                              weight:
                                  isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (oPrice > 0)
                          Text(
                            '+${StoreDetailsTokens.formatPrice(oPrice)} ${s.egp}',
                            style: StoreDetailsTokens.numeric(
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

  Widget _buildFooterCta({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isAr,
    required bool isOutOfStock,
    required bool atStockLimit,
    required bool requiredMet,
    required int currentQty,
    required CartItem? currentCartItem,
    required List<dynamic> optionGroups,
    required List<Map<String, dynamic>> flatOptions,
    required Map<String, dynamic> item,
    required String displayProductName,
    required String? selectedVariantImage,
    required String? productMainImage,
  }) {
    if (isOutOfStock && currentQty == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.bgCard2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.borderGold),
        ),
        child: Text(
          s.outOfStock,
          style: StoreDetailsTokens.text(
            size: 13.5,
            weight: FontWeight.w800,
            color: palette.textMuted,
          ),
        ),
      );
    }

    // When embedded inside Store Details with fly-to-cart callback, always
    // present the primary golden "إضافة للسلة" CTA so every addition triggers
    // the parabolic fly-to-cart animation cleanly (while still respecting stock).
    if (widget.onRequestFlyAdd != null || currentQty == 0) {
      final canAdd = requiredMet && !atStockLimit;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            if (!requiredMet) {
              _showMissingRequiredOptionSnack(
                context: context,
                optionGroups: optionGroups,
                isAr: isAr,
              );
              return;
            }
            if (atStockLimit) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.outOfStock),
                  backgroundColor: StoreDetailsTokens.errorRed,
                ),
              );
              return;
            }

            final authStatus = ref.read(authControllerProvider);
            if (authStatus == AuthStatus.unauthenticated) {
              AuthPromptDialog.show(context);
              return;
            }

            final payload = <String, dynamic>{
              ...item,
              'vendorId': widget.restaurant['id'],
              'vendorName': widget.restaurant['name'],
            };
            final selectedVar = _selectedVariant;
            final unit = _selectedUnit;
            final opts = List<Map<String, dynamic>>.from(flatOptions);
            final cartNotifier = ref.read(cartProvider.notifier);

            Future<void> commitAdd() async {
              await cartNotifier.addItem(
                payload,
                unit: unit,
                variant: selectedVar,
                options: opts,
              );
            }

            if (widget.onRequestFlyAdd != null) {
              final previewRect = _capturePreviewRect();
              final flyImg = (selectedVariantImage != null &&
                      selectedVariantImage.isNotEmpty)
                  ? selectedVariantImage
                  : productMainImage;
              final variantLabel = selectedVar != null
                  ? ((isAr &&
                          selectedVar['nameAr'] != null &&
                          selectedVar['nameAr'].toString().trim().isNotEmpty)
                      ? selectedVar['nameAr'].toString().trim()
                      : (selectedVar['name']?.toString().trim() ?? ''))
                  : '';
              final fullDisplayName = variantLabel.isNotEmpty
                  ? '$displayProductName ($variantLabel)'
                  : displayProductName;

              if (context.mounted) {
                Navigator.of(context).pop();
              }
              widget.onRequestFlyAdd!(
                previewRect,
                flyImg,
                commitAdd,
                fullDisplayName,
              );
              return;
            }

            try {
              await commitAdd();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.addedToCart),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ErrorUtils.translate(context, e)),
                    backgroundColor: StoreDetailsTokens.errorRed,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canAdd ? StoreDetailsTokens.gold : palette.bgCard2,
            foregroundColor: canAdd
                ? StoreDetailsTokens.darkOnGold
                : palette.textMuted,
            minimumSize: const Size(double.infinity, 46),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: canAdd ? 2 : 0,
            shadowColor: StoreDetailsTokens.gold.withValues(alpha: 0.35),
          ),
          child: Text(
            !requiredMet
                ? (isAr ? 'تحديد الخيارات المطلوبة' : 'Select Required Options')
                : atStockLimit
                    ? s.outOfStock
                    : s.addToCart,
            textAlign: TextAlign.center,
            style: StoreDetailsTokens.text(
              size: 14,
              weight: FontWeight.w900,
              color: canAdd
                  ? StoreDetailsTokens.darkOnGold
                  : palette.textMuted,
            ),
          ),
        ),
      );
    }

    // Standalone stepper fallback when already in cart
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: StoreDetailsTokens.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StoreDetailsTokens.gold),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_rounded,
                    color: StoreDetailsTokens.gold,
                    size: 20,
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
                  style: StoreDetailsTokens.numeric(
                    size: 16,
                    weight: FontWeight.w900,
                    color: palette.goldText,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    color: atStockLimit
                        ? StoreDetailsTokens.gold.withValues(alpha: 0.35)
                        : StoreDetailsTokens.gold,
                    size: 20,
                  ),
                  onPressed: () async {
                    final authStatus = ref.read(authControllerProvider);
                    if (authStatus == AuthStatus.unauthenticated) {
                      AuthPromptDialog.show(context);
                      return;
                    }
                    if (atStockLimit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(s.outOfStock),
                          backgroundColor: StoreDetailsTokens.errorRed,
                        ),
                      );
                      return;
                    }
                    try {
                      await ref
                          .read(cartProvider.notifier)
                          .updateQuantity(currentCartItem!, currentQty + 1);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ErrorUtils.translate(context, e)),
                            backgroundColor: StoreDetailsTokens.errorRed,
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
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: StoreDetailsTokens.gold,
              foregroundColor: StoreDetailsTokens.darkOnGold,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              s.done,
              style: StoreDetailsTokens.text(
                size: 14,
                weight: FontWeight.w900,
                color: StoreDetailsTokens.darkOnGold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMissingRequiredOptionSnack({
    required BuildContext context,
    required List<dynamic> optionGroups,
    required bool isAr,
  }) {
    String? missingGroupName;
    for (final g in optionGroups) {
      if (g is! Map) continue;
      final minS = g['minSelect'] is int
          ? g['minSelect'] as int
          : int.tryParse(g['minSelect']?.toString() ?? '0') ?? 0;
      final effectiveMin =
          g['isRequired'] == true ? (minS > 0 ? minS : 1) : minS;
      if (effectiveMin > 0) {
        final c = (_selectedOptions[g['id']?.toString()] ?? []).length;
        if (c < effectiveMin) {
          missingGroupName = (isAr &&
                  g['nameAr'] != null &&
                  g['nameAr'].toString().trim().isNotEmpty)
              ? g['nameAr'].toString().trim()
              : g['name']?.toString();
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
        backgroundColor: StoreDetailsTokens.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int? _parseStock(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Widget _buildUnitOption({
    required StoreDetailsPalette palette,
    required String label,
    required bool isSelected,
    required double price,
    required AppStrings s,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? StoreDetailsTokens.gold : palette.bgCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? StoreDetailsTokens.gold : palette.borderGold,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: StoreDetailsTokens.text(
                size: 12,
                weight: FontWeight.w800,
                color: isSelected
                    ? StoreDetailsTokens.darkOnGold
                    : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${StoreDetailsTokens.formatPrice(price)} ${s.egp}',
              style: StoreDetailsTokens.numeric(
                size: 11,
                weight: FontWeight.w800,
                color: isSelected
                    ? StoreDetailsTokens.darkOnGold.withValues(alpha: 0.85)
                    : palette.goldText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
