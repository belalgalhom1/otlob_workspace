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

typedef ProductSheetFlyAddCallback =
    void Function(
      Rect? previewSourceRect,
      String? flyImageUrl,
      Future<void> Function() commitAdd,
      String displayName,
    );

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class ProductBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> restaurant;
  final String initialUnit;
  final String? initialVariantId;
  final AppStrings s;
  final bool isDark;
  final bool isPharmacy;
  final ProductSheetFlyAddCallback? onRequestFlyAdd;

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

    final productOptionGroups =
        widget.item['optionGroups'] as List<dynamic>? ?? [];
    for (final group in productOptionGroups) {
      if (group is! Map) continue;
      final gId = group['id']?.toString() ?? '';
      final isRequired = group['isRequired'] == true;
      final maxSelect =
          (group['maxSelect'] as num?)?.toInt() ??
          int.tryParse(group['maxSelect']?.toString() ?? '1') ??
          1;
      final options = group['options'] as List<dynamic>? ?? [];
      if (isRequired && maxSelect == 1 && options.isNotEmpty) {
        _selectedOptions[gId] = [
          Map<String, dynamic>.from(options.first as Map),
        ];
      } else {
        _selectedOptions[gId] = [];
      }
    }

    if (_selectedVariant != null) {
      final variantOptionGroups =
          _selectedVariant!['optionGroups'] as List<dynamic>? ?? [];
      for (final group in variantOptionGroups) {
        if (group is! Map) continue;
        final gId = group['id']?.toString() ?? '';
        final isRequired = group['isRequired'] == true;
        final maxSelect =
            (group['maxSelect'] as num?)?.toInt() ??
            int.tryParse(group['maxSelect']?.toString() ?? '1') ??
            1;
        final options = group['options'] as List<dynamic>? ?? [];
        if (isRequired && maxSelect == 1 && options.isNotEmpty) {
          _selectedOptions[gId] = [
            Map<String, dynamic>.from(options.first as Map),
          ];
        } else {
          _selectedOptions[gId] = [];
        }
      }
    }
  }

  int? _parseStock(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Rect? _capturePreviewRect() {
    final renderBox =
        _previewImageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    return topLeft & renderBox.size;
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
    final maxSelect =
        (group['maxSelect'] as num?)?.toInt() ??
        int.tryParse(group['maxSelect']?.toString() ?? '1') ??
        1;
    final safeMax = maxSelect <= 0 ? 1 : maxSelect;
    final list = List<Map<String, dynamic>>.from(
      _selectedOptions[groupId] ?? [],
    );
    final optId = option['id']?.toString() ?? '';
    final isSelected = list.any((o) => o['id']?.toString() == optId);

    setState(() {
      if (isSelected) {
        if (safeMax == 1 && isRequired) return;
        list.removeWhere((o) => o['id']?.toString() == optId);
      } else {
        if (safeMax == 1) {
          list
            ..clear()
            ..add(option);
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

  void _selectVariant(Map<String, dynamic> variant) {
    setState(() {
      _hasUserSelectedVariant = true;
      _selectedVariant = variant;

      final productGroupIds =
          (widget.item['optionGroups'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map((g) => g['id']?.toString() ?? '')
              .toSet();
      _selectedOptions.removeWhere(
        (groupId, _) => !productGroupIds.contains(groupId),
      );

      final vOptionGroups = variant['optionGroups'] as List<dynamic>? ?? [];
      for (final g in vOptionGroups) {
        if (g is! Map) continue;
        final gId = g['id']?.toString() ?? '';
        final isRequired = g['isRequired'] == true;
        final maxSelect =
            (g['maxSelect'] as num?)?.toInt() ??
            int.tryParse(g['maxSelect']?.toString() ?? '1') ??
            1;
        final options = g['options'] as List<dynamic>? ?? [];
        if (isRequired && maxSelect == 1 && options.isNotEmpty) {
          _selectedOptions[gId] = [
            Map<String, dynamic>.from(options.first as Map),
          ];
        } else {
          _selectedOptions[gId] = [];
        }
      }
    });
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
      final effectiveMin = g['isRequired'] == true
          ? (minS > 0 ? minS : 1)
          : minS;
      if (effectiveMin > 0) {
        final c = (_selectedOptions[g['id']?.toString()] ?? []).length;
        if (c < effectiveMin) {
          missingGroupName =
              (isAr &&
                  g['nameAr'] != null &&
                  g['nameAr'].toString().trim().isNotEmpty)
              ? g['nameAr'].toString()
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final s = widget.s;
    final palette = StoreDetailsPalette.fromBrightness(widget.isDark);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final currency = s.egp.trim();

    final flatOptions = _selectedOptions.values
        .expand((list) => list)
        .toList(growable: false);
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
            .where(
              (ci) =>
                  ci.selectedVariant?.id == _selectedVariant!['id']?.toString(),
            )
            .fold<int>(0, (sum, ci) => sum + convertedLineQty(ci));
      }
    } else if (productTracksStock && productStock != null) {
      stockLimit = productStock * divider;
      stockPoolQty = cartAllItems
          .where(
            (ci) =>
                ci.product.id == item['id']?.toString() &&
                ci.selectedVariant == null,
          )
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
        widget.isPharmacy && sellByStrip && item['stripsPerPackage'] != null;
    final int rawStrips =
        (item['stripsPerPackage'] as num?)?.toInt() ??
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

    final String name =
        (isAr &&
            item['nameAr'] != null &&
            item['nameAr'].toString().trim().isNotEmpty)
        ? item['nameAr'].toString().trim()
        : (item['name']?.toString().trim() ?? '');
    final String description =
        (isAr &&
            item['descriptionAr'] != null &&
            item['descriptionAr'].toString().trim().isNotEmpty)
        ? item['descriptionAr'].toString().trim()
        : (item['description']?.toString().trim() ?? '');

    final variants = (item['variants'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((v) => Map<String, dynamic>.from(v))
        .toList(growable: false);
    final bool hasVariants =
        (item['hasVariants'] == true || variants.isNotEmpty) &&
        variants.isNotEmpty;

    final String? productMainImage = StoreDetailsTokens.cleanBackendImageUrl(
      item['imageUrl'] ?? item['image'],
    );
    final String? selectedVariantImage =
        StoreDetailsTokens.cleanBackendImageUrl(
          _selectedVariant?['imageUrl'] ?? _selectedVariant?['image'],
        );

    // Start with the product's own image on open; immediately swap to the
    // selected variant's own image once the customer selects a variant (or if
    // the product itself has no image).
    final String? heroImageUrl =
        (_hasUserSelectedVariant &&
            selectedVariantImage != null &&
            selectedVariantImage.isNotEmpty)
        ? selectedVariantImage
        : (productMainImage ?? selectedVariantImage);

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
      final minSelect =
          (group['minSelect'] as num?)?.toInt() ??
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
    final bottomSafeInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: maxSheetHeight),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafeInset),
            decoration: BoxDecoration(
              color: palette.bgCard,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: palette.sheetTopBorder, width: 1),
              ),
              boxShadow: [palette.cardShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle: 40px × 4px, rounded full, muted 40%
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

                // Scrollable body when option groups / strips are present
                Flexible(
                  child: ScrollConfiguration(
                    behavior: const _NoScrollbarBehavior(),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Large Preview Image: full width × 160px, radius 16, cover, border-gold
                          KeyedSubtree(
                            key: _previewImageKey,
                            child: Stack(
                              children: [
                                Container(
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child:
                                          (heroImageUrl == null ||
                                              heroImageUrl.isEmpty)
                                          ? SizedBox(
                                              key: const ValueKey(
                                                'empty_hero_image',
                                              ),
                                              width: double.infinity,
                                              height: 160,
                                              child: Center(
                                                child: Icon(
                                                  Icons.fastfood_rounded,
                                                  size: 44,
                                                  color: palette.textMuted
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            )
                                          : SizedBox(
                                              key: ValueKey(heroImageUrl),
                                              width: double.infinity,
                                              height: 160,
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    ImageUtils.formatImageUrl(
                                                      heroImageUrl,
                                                    ),
                                                width: double.infinity,
                                                height: 160,
                                                fit: BoxFit.cover,
                                                placeholder: (_, _) => Center(
                                                  child: Icon(
                                                    Icons.fastfood_rounded,
                                                    size: 44,
                                                    color: palette.textMuted
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                errorWidget: (_, _, _) =>
                                                    Center(
                                                      child: Icon(
                                                        Icons.fastfood_rounded,
                                                        size: 44,
                                                        color: palette.textMuted
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
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
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.75,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          9999,
                                        ),
                                      ),
                                      child: Text(
                                        s.outOfStock,
                                        style: StoreDetailsTokens.text(
                                          size: 11,
                                          weight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title & Dynamic Price Row (both 16px w900)
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
                                    '${StoreDetailsTokens.formatPrice(currentUnitPrice)} $currency',
                                    style: StoreDetailsTokens.numeric(
                                      size: 16,
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
                                          '${StoreDetailsTokens.formatPrice(originalUnitPrice)} $currency',
                                          style: StoreDetailsTokens.numeric(
                                            size: 11,
                                            weight: FontWeight.w600,
                                            color: palette.textMuted,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor: palette.textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Container(
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
                                                size: 8.5,
                                                weight: FontWeight.w900,
                                                color: StoreDetailsTokens
                                                    .darkOnGold,
                                              ),
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
                                size: 11,
                                weight: FontWeight.w500,
                                color: palette.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],

                          // Pharmacy Package / Strip selector (real backend sellByStrip)
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
                                  child: _buildUnitTile(
                                    palette: palette,
                                    label: s.package,
                                    priceText:
                                        '${StoreDetailsTokens.formatPrice(effectiveBasePrice)} $currency',
                                    isSelected: _selectedUnit == 'package',
                                    onTap: () => setState(
                                      () => _selectedUnit = 'package',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildUnitTile(
                                    palette: palette,
                                    label: s.strip,
                                    priceText:
                                        '${StoreDetailsTokens.formatPrice(effectiveBasePrice / stripsCount)} $currency',
                                    isSelected: _selectedUnit == 'strip',
                                    onTap: () =>
                                        setState(() => _selectedUnit = 'strip'),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Variants Section: label 12px w800 --text-muted, max-height 160px, gap 8px
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
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 160),
                              child: ScrollConfiguration(
                                behavior: const _NoScrollbarBehavior(),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (
                                        int i = 0;
                                        i < variants.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(height: 8),
                                        _buildVariantRow(
                                          variant: variants[i],
                                          productMainImage: productMainImage,
                                          palette: palette,
                                          isAr: isAr,
                                          currency: currency,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Real Backend Product / Variant Option Groups (when present)
                          if (optionGroups.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...optionGroups.whereType<Map>().map(
                              (group) => _buildOptionGroup(
                                group: Map<String, dynamic>.from(group),
                                palette: palette,
                                isAr: isAr,
                                currency: currency,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Primary CTA Button (إضافة للسلة)
                _buildBottomAction(
                  context: context,
                  item: item,
                  palette: palette,
                  s: s,
                  isAr: isAr,
                  displayProductName: name,
                  productMainImage: productMainImage,
                  selectedVariantImage: selectedVariantImage,
                  flatOptions: flatOptions,
                  optionGroups: optionGroups,
                  requiredMet: requiredMet,
                  isOutOfStock: isOutOfStock,
                  atStockLimit: atStockLimit,
                  currentCartItem: currentCartItem,
                  currentQty: currentQty,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantRow({
    required Map<String, dynamic> variant,
    required String? productMainImage,
    required StoreDetailsPalette palette,
    required bool isAr,
    required String currency,
  }) {
    final vId = variant['id']?.toString() ?? '';
    final isSelected = _selectedVariant?['id']?.toString() == vId;
    final vName =
        (isAr &&
            variant['nameAr'] != null &&
            variant['nameAr'].toString().trim().isNotEmpty)
        ? variant['nameAr'].toString().trim()
        : (variant['name']?.toString().trim() ?? '');

    final effectiveVPrice =
        double.tryParse(
          (variant['price'] ?? variant['basePrice'])?.toString() ?? '0',
        ) ??
        0.0;

    // Per-variant thumbnail displays that variant's own image from backend,
    // falling back to the product image.
    final thumbUrl =
        StoreDetailsTokens.cleanBackendImageUrl(
          variant['imageUrl'] ?? variant['image'],
        ) ??
        productMainImage;

    final vTracks = variant['tracksStock'] == null
        ? true
        : (variant['tracksStock'] == true);
    final vStock = _parseStock(variant['stock']);
    final bool vSoldOut = vTracks && vStock != null && vStock <= 0;

    return Material(
      color: isSelected
          ? const Color.fromRGBO(229, 169, 60, 0.15)
          : palette.bgCard2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectVariant(variant),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? StoreDetailsTokens.gold : palette.borderGold,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 36px × 36px per-variant thumbnail (radius 8, cover)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.borderGold, width: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: (thumbUrl != null && thumbUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: ImageUtils.thumbnailUrl(thumbUrl),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Center(
                            child: Icon(
                              Icons.fastfood_rounded,
                              size: 16,
                              color: palette.textMuted.withValues(alpha: 0.5),
                            ),
                          ),
                          errorWidget: (_, _, _) => Center(
                            child: Icon(
                              Icons.fastfood_rounded,
                              size: 16,
                              color: palette.textMuted.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.fastfood_rounded,
                            size: 16,
                            color: palette.textMuted.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // Variant Name (12px, weight 800, truncate)
              Expanded(
                child: Text(
                  vSoldOut ? '$vName (${isAr ? "نفد" : "Sold out"})' : vName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StoreDetailsTokens.text(
                    size: 12,
                    weight: FontWeight.w800,
                    color: isSelected ? palette.textPrimary : palette.textMuted,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Variant Price (12px, Inter, weight 900, --gold-text)
              Text(
                '${StoreDetailsTokens.formatPrice(effectiveVPrice)} $currency',
                style: StoreDetailsTokens.numeric(
                  size: 12,
                  weight: FontWeight.w900,
                  color: palette.goldText,
                ),
              ),
              const SizedBox(width: 8),

              // Selection Indicator: 16px × 16px circle (9px checkmark when selected)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? StoreDetailsTokens.gold
                      : Colors.transparent,
                  border: isSelected
                      ? null
                      : Border.all(color: palette.borderGold, width: 1.5),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: StoreDetailsTokens.darkOnGold,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitTile({
    required StoreDetailsPalette palette,
    required String label,
    required String priceText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? const Color.fromRGBO(229, 169, 60, 0.15)
          : palette.bgCard2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? StoreDetailsTokens.gold : palette.borderGold,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StoreDetailsTokens.text(
                  size: 12,
                  weight: FontWeight.w800,
                  color: isSelected ? palette.textPrimary : palette.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                priceText,
                style: StoreDetailsTokens.numeric(
                  size: 11.5,
                  weight: FontWeight.w900,
                  color: palette.goldText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionGroup({
    required Map<String, dynamic> group,
    required StoreDetailsPalette palette,
    required bool isAr,
    required String currency,
  }) {
    final gId = group['id']?.toString() ?? '';
    final gName =
        (isAr &&
            group['nameAr'] != null &&
            group['nameAr'].toString().trim().isNotEmpty)
        ? group['nameAr'].toString().trim()
        : (group['name']?.toString().trim() ?? '');
    final options = (group['options'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((o) => Map<String, dynamic>.from(o))
        .toList(growable: false);
    final isRequired = group['isRequired'] == true;
    final minSelect = group['minSelect'] is int
        ? group['minSelect'] as int
        : int.tryParse(group['minSelect']?.toString() ?? '0') ?? 0;
    final effectiveMin = isRequired
        ? (minSelect > 0 ? minSelect : 1)
        : minSelect;
    final selectedCount = (_selectedOptions[gId] ?? []).length;
    final isSatisfied = effectiveMin <= 0 || selectedCount >= effectiveMin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  gName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StoreDetailsTokens.text(
                    size: 12,
                    weight: FontWeight.w800,
                    color: palette.textMuted,
                  ),
                ),
              ),
              if (effectiveMin > 0)
                Text(
                  isSatisfied
                      ? (isAr ? '✓ مكتمل' : '✓ Done')
                      : (isAr
                            ? '* مطلوب ($effectiveMin)'
                            : '* Required ($effectiveMin)'),
                  style: StoreDetailsTokens.text(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: isSatisfied
                        ? StoreDetailsTokens.openGreen
                        : StoreDetailsTokens.errorRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ...options.map((opt) {
            final optId = opt['id']?.toString() ?? '';
            final isSelected = (_selectedOptions[gId] ?? []).any(
              (o) => o['id']?.toString() == optId,
            );
            final oName =
                (isAr &&
                    opt['nameAr'] != null &&
                    opt['nameAr'].toString().trim().isNotEmpty)
                ? opt['nameAr'].toString().trim()
                : (opt['name']?.toString().trim() ?? '');
            final oPrice =
                double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: isSelected
                    ? const Color.fromRGBO(229, 169, 60, 0.15)
                    : palette.bgCard2,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggleOption(group, opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? StoreDetailsTokens.gold
                            : palette.borderGold,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            oName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StoreDetailsTokens.text(
                              size: 12,
                              weight: FontWeight.w700,
                              color: isSelected
                                  ? palette.textPrimary
                                  : palette.textMuted,
                            ),
                          ),
                        ),
                        if (oPrice > 0) ...[
                          Text(
                            '+${StoreDetailsTokens.formatPrice(oPrice)} $currency',
                            style: StoreDetailsTokens.numeric(
                              size: 11.5,
                              weight: FontWeight.w900,
                              color: palette.goldText,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? StoreDetailsTokens.gold
                                : Colors.transparent,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: palette.borderGold,
                                    width: 1.5,
                                  ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 10,
                                    color: StoreDetailsTokens.darkOnGold,
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
          }),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required BuildContext context,
    required Map<String, dynamic> item,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isAr,
    required String displayProductName,
    required String? productMainImage,
    required String? selectedVariantImage,
    required List<Map<String, dynamic>> flatOptions,
    required List<dynamic> optionGroups,
    required bool requiredMet,
    required bool isOutOfStock,
    required bool atStockLimit,
    required CartItem? currentCartItem,
    required int currentQty,
  }) {
    if (isOutOfStock && currentQty == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.bgCard2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.borderGold, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          s.outOfStock,
          style: StoreDetailsTokens.text(
            size: 14,
            weight: FontWeight.w900,
            color: palette.textMuted,
          ),
        ),
      );
    }

    // Primary CTA Button (إضافة للسلة): full width, padding 12px, radius 16px,
    // background #E5A93C (hover/active #F6C667), text #14120E, 14px, w900.
    if (widget.onRequestFlyAdd != null || currentQty == 0) {
      final canAdd = requiredMet && !atStockLimit;
      return SizedBox(
        width: double.infinity,
        child: ButtonStyleButton.allOrNull(null) == null
            ? ElevatedButton(
                key: const Key('product_sheet_add_to_cart_button'),
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
                    'vendorName':
                        widget.restaurant['name'] ??
                        widget.restaurant['storeName'],
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
                    // CRITICAL: Measure the 160px preview bounding rect BEFORE closing
                    final previewRect = _capturePreviewRect();
                    final flyImg =
                        (selectedVariantImage != null &&
                            selectedVariantImage.isNotEmpty)
                        ? selectedVariantImage
                        : productMainImage;
                    final variantLabel = selectedVar != null
                        ? ((isAr &&
                                  selectedVar['nameAr'] != null &&
                                  selectedVar['nameAr']
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
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
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (!canAdd) return palette.bgCard2;
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.pressed)) {
                      return StoreDetailsTokens.goldHover;
                    }
                    return StoreDetailsTokens.gold;
                  }),
                  foregroundColor: WidgetStateProperty.all(
                    canAdd ? StoreDetailsTokens.darkOnGold : palette.textMuted,
                  ),
                  overlayColor: WidgetStateProperty.all(
                    StoreDetailsTokens.goldHover.withValues(alpha: 0.25),
                  ),
                  elevation: WidgetStateProperty.all(0),
                  minimumSize: WidgetStateProperty.all(
                    const Size(double.infinity, 44),
                  ),
                  padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: canAdd
                          ? BorderSide.none
                          : BorderSide(color: palette.borderGold, width: 1),
                    ),
                  ),
                ),
                child: Text(
                  !requiredMet
                      ? (isAr
                            ? 'تحديد الخيارات المطلوبة'
                            : 'Select Required Options')
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
              )
            : const SizedBox.shrink(),
      );
    }

    // Standalone fallback stepper when rendered outside VendorDetailScreen
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(229, 169, 60, 0.15),
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
                    size: 18,
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
                    size: 15,
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
                    size: 18,
                  ),
                  onPressed: () async {
                    final authStatus = ref.read(authControllerProvider);
                    if (authStatus == AuthStatus.unauthenticated) {
                      AuthPromptDialog.show(context);
                      return;
                    }
                    if (atStockLimit) return;
                    await ref
                        .read(cartProvider.notifier)
                        .updateQuantity(currentCartItem!, currentQty + 1);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: StoreDetailsTokens.gold,
              foregroundColor: StoreDetailsTokens.darkOnGold,
              minimumSize: const Size(double.infinity, 44),
              padding: const EdgeInsets.all(12),
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
}
