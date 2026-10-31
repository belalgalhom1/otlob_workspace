import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

import 'package:core/core.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';

class ProductBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> restaurant;
  final String initialUnit;
  final AppStrings s;
  final bool isDark;
  final bool isPharmacy;

  const ProductBottomSheet({
    super.key,
    required this.item,
    required this.restaurant,
    required this.initialUnit,
    required this.s,
    required this.isDark,
    required this.isPharmacy,
  });

  @override
  ConsumerState<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends ConsumerState<ProductBottomSheet> {
  late String _selectedUnit;
  Map<String, dynamic>? _selectedVariant;
  final Map<String, List<Map<String, dynamic>>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
    
    final variants = widget.item['variants'] as List<dynamic>? ?? [];
    final bool hasVariants = (widget.item['hasVariants'] == true || variants.isNotEmpty) && variants.isNotEmpty;
    if (hasVariants) {
      _selectedVariant = variants.first as Map<String, dynamic>;
    }
    
    final productOptionGroups = widget.item['optionGroups'] as List<dynamic>? ?? [];
    for (final group in productOptionGroups) {
      final gId = group['id']?.toString() ?? '';
      final isRequired = group['isRequired'] == true;
      final maxSelect = (group['maxSelect'] as num?)?.toInt() ?? int.tryParse(group['maxSelect']?.toString() ?? '1') ?? 1;
      final options = group['options'] as List<dynamic>? ?? [];
      if (isRequired && maxSelect == 1 && options.isNotEmpty) {
        _selectedOptions[gId] = [options.first as Map<String, dynamic>];
      } else {
        _selectedOptions[gId] = [];
      }
    }

    if (_selectedVariant != null) {
      final variantOptionGroups = _selectedVariant!['optionGroups'] as List<dynamic>? ?? [];
      for (final group in variantOptionGroups) {
        final gId = group['id']?.toString() ?? '';
        final isRequired = group['isRequired'] == true;
        final maxSelect = (group['maxSelect'] as num?)?.toInt() ?? int.tryParse(group['maxSelect']?.toString() ?? '1') ?? 1;
        final options = group['options'] as List<dynamic>? ?? [];
        if (isRequired && maxSelect == 1 && options.isNotEmpty) {
          _selectedOptions[gId] = [options.first as Map<String, dynamic>];
        } else {
          _selectedOptions[gId] = [];
        }
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
        int.tryParse(group['maxSelect']?.toString() ?? '1') ?? 1;
    final safeMax = maxSelect <= 0 ? 1 : maxSelect;
    final list = List<Map<String, dynamic>>.from(_selectedOptions[groupId] ?? []);
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
    final isDark = widget.isDark;

    final flatOptions = _selectedOptions.values.expand((list) => list).toList();

    final currentCartItem = ref.watch(cartProvider).allItems.where((ci) {
      return ci.product.id == item['id'] && 
             ci.selectedUnit == _selectedUnit &&
             ci.selectedVariant?.id == _selectedVariant?['id'] &&
             _areOptionsEqual(ci.selectedOptions, flatOptions);
    }).firstOrNull;
    
    final currentQty = currentCartItem?.quantity ?? 0;
    
    final bool productTracksStock = item['tracksStock'] == null ? true : (item['tracksStock'] == true);
    final int? productStock = _parseStock(item['stock']);
    final int? variantStock = _parseStock(_selectedVariant?['stock']);
    final bool variantTracksStock = _selectedVariant == null
        ? true
        : (_selectedVariant!['tracksStock'] == null
            ? productTracksStock
            : (_selectedVariant!['tracksStock'] == true));
    // Stock-aware cap: the menu snapshot is stale the moment the cart holds
    // units, so subtract what's already in the cart. Variant stock is shared
    // across option combinations; product stock across units (converted to
    // strips when a strip unit is selected, mirroring the backend).
    final cartAllItems = ref.watch(cartProvider).allItems;
    int stockPoolQty = 0;
    int? stockLimit;
    if (_selectedVariant != null) {
      if (variantTracksStock && variantStock != null) {
        stockLimit = variantStock;
        stockPoolQty = cartAllItems
            .where((ci) =>
                ci.selectedVariant?.id == _selectedVariant!['id'])
            .fold<int>(0, (sum, ci) => sum + ci.quantity);
      }
    } else if (productTracksStock && productStock != null) {
      final bool sellByStrip = item['sellByStrip'] == true;
      final int stripsPerPackage =
          int.tryParse(item['stripsPerPackage']?.toString() ?? '') ?? 1;
      final divider = (_selectedUnit == 'strip' &&
              sellByStrip &&
              stripsPerPackage > 0)
          ? stripsPerPackage
          : 1;
      stockLimit = productStock * divider;
      stockPoolQty = cartAllItems
          .where((ci) =>
              ci.product.id == item['id'] && ci.selectedVariant == null)
          .fold<int>(0, (sum, ci) {
        int lineQty = ci.quantity;
        if (sellByStrip && stripsPerPackage > 1) {
          if (_selectedUnit == 'strip' && ci.selectedUnit == 'package') {
            lineQty = ci.quantity * stripsPerPackage;
          } else if (_selectedUnit == 'package' && ci.selectedUnit == 'strip') {
            lineQty = (ci.quantity / stripsPerPackage).ceil();
          }
        }
        return sum + lineQty;
      });
    }
    final bool isOutOfStock = stockLimit != null
        ? stockPoolQty >= stockLimit
        : (_selectedVariant != null
            ? variantTracksStock && variantStock != null && variantStock <= 0
            : productTracksStock &&
                productStock != null &&
                productStock <= 0);
    final bool atStockLimit = stockLimit != null && stockPoolQty >= stockLimit;
    
    final bool supportsStrips = item['sellByStrip'] == true && item['stripsPerPackage'] != null;
    final int stripsCount = item['stripsPerPackage'] as int? ?? 1;

    double effectiveBasePrice = 0.0;
    double originalBasePrice = 0.0;

    if (_selectedVariant != null) {
      final effectiveP = _selectedVariant!['price'] ?? _selectedVariant!['basePrice'];
      effectiveBasePrice = double.tryParse(effectiveP?.toString() ?? '0') ?? 0.0;

      final compareP = _selectedVariant!['comparePrice'] ?? _selectedVariant!['basePrice'];
      originalBasePrice = double.tryParse(compareP?.toString() ?? '0') ?? effectiveBasePrice;
    } else {
      final effectiveP = item['price'] ?? item['basePrice'];
      effectiveBasePrice = double.tryParse(effectiveP?.toString() ?? '0') ?? 0.0;

      final compareP = item['comparePrice'] ?? effectiveBasePrice;
      originalBasePrice = double.tryParse(compareP?.toString() ?? '0') ?? effectiveBasePrice;
    }

    double optionsTotal = 0.0;
    for (final opt in flatOptions) {
      final op = opt['priceAdded'];
      optionsTotal += double.tryParse(op?.toString() ?? '0') ?? 0.0;
    }

    final double currentUnitPrice = (_selectedUnit == 'strip' ? (effectiveBasePrice / stripsCount) : effectiveBasePrice) + optionsTotal;
    final double originalUnitPrice = (_selectedUnit == 'strip' ? (originalBasePrice / stripsCount) : originalBasePrice) + optionsTotal;
    final bool hasDiscount = originalUnitPrice > currentUnitPrice;
    final int discountPercentage = hasDiscount 
        ? (((originalUnitPrice - currentUnitPrice) / originalUnitPrice) * 100).round()
        : 0;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final name = isAr && item['nameAr'] != null && item['nameAr'].toString().isNotEmpty
        ? item['nameAr'] as String
        : item['name'] as String;
    final description = isAr && item['descriptionAr'] != null && item['descriptionAr'].toString().isNotEmpty
        ? item['descriptionAr'] as String
        : item['description'] as String? ?? '';

    final variants = item['variants'] as List<dynamic>? ?? [];
    final bool hasVariants = (item['hasVariants'] == true || variants.isNotEmpty) && variants.isNotEmpty;
    final productOptionGroups = item['optionGroups'] as List<dynamic>? ?? [];
    final variantOptionGroups = _selectedVariant?['optionGroups'] as List<dynamic>? ?? [];
    final optionGroups = [...productOptionGroups, ...variantOptionGroups];

    // Check if required options are met
    bool requiredMet = true;
    if (hasVariants && _selectedVariant == null) {
      requiredMet = false;
    }
    for (final group in optionGroups) {
      if (group['isRequired'] == true) {
        final minSelect = (group['minSelect'] as num?)?.toInt() ?? 
            int.tryParse(group['minSelect']?.toString() ?? '1') ?? 1;
        final gId = group['id']?.toString() ?? '';
        final count = _selectedOptions[gId]?.length ?? 0;
        if (count < (minSelect > 0 ? minSelect : 1)) {
          requiredMet = false;
          break;
        }
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: (item['image']?.toString().isEmpty ?? true)
                            ? Container(
                                width: double.infinity,
                                height: 250,
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                child: Icon(Icons.fastfood_rounded, size: 80, color: Colors.grey.shade300),
                              )
                            : Container(
                                width: double.infinity,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: ImageUtils.formatImageUrl(item['image'] as String?),
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) => Icon(Icons.fastfood, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
                                  ),
                                ),
                              ),
                      ),
                      if (isOutOfStock)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.remove_shopping_cart_outlined, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  s.outOfStock,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${currentUnitPrice.toStringAsFixed(currentUnitPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${originalUnitPrice.toStringAsFixed(originalUnitPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.shade200, width: 0.5),
                                  ),
                                  child: Text(
                                    '-$discountPercentage%',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
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
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15, 
                        color: isDark ? Colors.white : Colors.grey.shade700, 
                        height: 1.6
                      ),
                    ),
                  ],

                  if (supportsStrips) ...[
                    const SizedBox(height: 24),
                    Text(
                      s.sellingUnit,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUnitOption(
                            label: s.package,
                            isSelected: _selectedUnit == 'package',
                            price: effectiveBasePrice,
                            s: s,
                            onTap: () {
                              setState(() => _selectedUnit = 'package');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildUnitOption(
                            label: s.strip,
                            isSelected: _selectedUnit == 'strip',
                            price: effectiveBasePrice / stripsCount,
                            s: s,
                            onTap: () {
                              setState(() => _selectedUnit = 'strip');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (hasVariants) ...[
                    const SizedBox(height: 24),
                    Text(
                      s.selectVariant,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...variants.map((v) {
                      final vName = isAr && v['nameAr'] != null && v['nameAr'].toString().isNotEmpty ? v['nameAr'] : v['name'];
                      final effectiveVPrice = double.tryParse((v['price'] ?? v['basePrice'])?.toString() ?? '0') ?? 0.0;
                      final originalVPrice = double.tryParse((v['comparePrice'] ?? v['basePrice'])?.toString() ?? '0') ?? effectiveVPrice;
                      final hasVDiscount = originalVPrice > effectiveVPrice;
                      final vDiscountPct = hasVDiscount 
                          ? (((originalVPrice - effectiveVPrice) / originalVPrice) * 100).round()
                          : 0;
                      final vId = v['id']?.toString() ?? '';
                      final isVSelected = _selectedVariant?['id']?.toString() == vId;

                      void selectVariant() {
                        setState(() {
                          _selectedVariant = v as Map<String, dynamic>;
                          // Keep product-level option group selections intact, only reset variant option groups
                          final productGroupIds = (widget.item['optionGroups'] as List<dynamic>? ?? [])
                              .map((g) => g['id']?.toString() ?? '')
                              .toSet();
                          _selectedOptions.removeWhere((groupId, _) => !productGroupIds.contains(groupId));
                          final vOptionGroups = v['optionGroups'] as List<dynamic>? ?? [];
                          for (final g in vOptionGroups) {
                            final gId = g['id']?.toString() ?? '';
                            final isRequired = g['isRequired'] == true;
                            final maxSelect = (g['maxSelect'] as num?)?.toInt() ?? int.tryParse(g['maxSelect']?.toString() ?? '1') ?? 1;
                            final options = g['options'] as List<dynamic>? ?? [];
                            if (isRequired && maxSelect == 1 && options.isNotEmpty) {
                              _selectedOptions[gId] = [options.first as Map<String, dynamic>];
                            } else {
                              _selectedOptions[gId] = [];
                            }
                          }
                        });
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isVSelected
                              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isVSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                            width: isVSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: selectVariant,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: vId,
                                  groupValue: _selectedVariant?['id']?.toString(),
                                  activeColor: AppColors.primary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (_) => selectVariant(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isVSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            '${effectiveVPrice.toStringAsFixed(effectiveVPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: hasVDiscount ? AppColors.primary : (isDark ? Colors.white70 : Colors.grey.shade700),
                                            ),
                                          ),
                                          if (hasVDiscount) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '${originalVPrice.toStringAsFixed(originalVPrice % 1 == 0 ? 0 : 2)} ${s.egp}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.red.shade200, width: 0.5),
                                              ),
                                              child: Text(
                                                '-$vDiscountPct%',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
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
                    }),
                  ],

                  if (optionGroups.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...optionGroups.map((group) {
                      final gName = isAr && group['nameAr'] != null && group['nameAr'].toString().isNotEmpty ? group['nameAr'] : group['name'];
                      final options = group['options'] as List<dynamic>? ?? [];
                      final isRequired = group['isRequired'] == true;
                      final minSelect = group['minSelect'] is int 
                          ? group['minSelect'] as int 
                          : int.tryParse(group['minSelect']?.toString() ?? (isRequired ? '1' : '0')) ?? (isRequired ? 1 : 0);
                      final maxSelect = group['maxSelect'] is int 
                          ? group['maxSelect'] as int 
                          : int.tryParse(group['maxSelect']?.toString() ?? '1') ?? 1;
                      final gId = group['id']?.toString() ?? '';
                      final selectedCount = (_selectedOptions[gId] ?? []).length;
                      final isGroupSatisfied = !isRequired || selectedCount >= (minSelect > 0 ? minSelect : 1);

                      return Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !isGroupSatisfied
                                ? Colors.redAccent.withValues(alpha: 0.4)
                                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                            width: !isGroupSatisfied ? 1.5 : 1,
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
                                        style: TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        maxSelect == 1
                                            ? (isRequired 
                                                ? (isAr ? 'اختر 1 (إجباري)' : 'Choose 1 (Required)') 
                                                : (isAr ? 'اختر 1 (اختياري)' : 'Choose 1 (Optional)'))
                                            : (isRequired
                                                ? (isAr ? 'اختر على الأقل $minSelect (إجباري)' : 'Choose at least $minSelect (Required)')
                                                : (isAr ? 'اختر حتى $maxSelect (اختياري)' : 'Choose up to $maxSelect (Optional)')),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isRequired
                                        ? (isGroupSatisfied 
                                            ? Colors.green.withValues(alpha: 0.1) 
                                            : Colors.red.withValues(alpha: 0.1))
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isRequired
                                          ? (isGroupSatisfied ? Colors.green : Colors.redAccent)
                                          : Colors.grey.shade400,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    isRequired
                                        ? (isGroupSatisfied
                                            ? (isAr ? '✓ مكتمل' : '✓ Completed')
                                            : (isAr ? '* مطلوب' : '* Required'))
                                        : (isAr ? 'اختياري' : 'Optional'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isRequired
                                          ? (isGroupSatisfied ? Colors.green : Colors.redAccent)
                                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            ...options.map((opt) {
                              final oName = isAr && opt['nameAr'] != null && opt['nameAr'].toString().isNotEmpty ? opt['nameAr'] : opt['name'];
                              final oPrice = double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0.0;
                              final optId = opt['id']?.toString() ?? '';
                              final isSelected = (_selectedOptions[gId] ?? []).any((o) => o['id']?.toString() == optId);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.6)
                                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _toggleOption(group as Map<String, dynamic>, opt as Map<String, dynamic>),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        if (maxSelect == 1)
                                          Radio<String>(
                                            value: optId,
                                            groupValue: (_selectedOptions[gId]?.isNotEmpty ?? false)
                                                ? _selectedOptions[gId]!.first['id']?.toString()
                                                : null,
                                            activeColor: AppColors.primary,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            onChanged: (_) => _toggleOption(group as Map<String, dynamic>, opt as Map<String, dynamic>),
                                          )
                                        else
                                          Checkbox(
                                            value: isSelected,
                                            activeColor: AppColors.primary,
                                            checkColor: Colors.black,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            onChanged: (_) => _toggleOption(group as Map<String, dynamic>, opt as Map<String, dynamic>),
                                          ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            oName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (oPrice > 0)
                                          Text(
                                            '+${oPrice.toStringAsFixed(2)} ${s.egp}',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: isOutOfStock
                ? Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.outOfStock,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : currentQty == 0
                ? ElevatedButton(
                    onPressed: () async {
                      if (!requiredMet) {
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        String? missingGroupName;
                        for (final g in optionGroups) {
                          if (g['isRequired'] == true) {
                            final minS = g['minSelect'] is int 
                                ? g['minSelect'] as int 
                                : int.tryParse(g['minSelect']?.toString() ?? '1') ?? 1;
                            final c = (_selectedOptions[g['id']?.toString()] ?? []).length;
                            if (c < (minS > 0 ? minS : 1)) {
                              missingGroupName = isAr && g['nameAr'] != null && g['nameAr'].toString().isNotEmpty
                                  ? g['nameAr']
                                  : g['name'];
                              break;
                            }
                          }
                        }
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              missingGroupName != null
                                  ? (isAr ? 'برجاء تحديد: $missingGroupName' : 'Please select: $missingGroupName')
                                  : (isAr ? 'برجاء تحديد الخيارات المطلوبة' : 'Please select required options'),
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
                      try {
                        await ref.read(cartProvider.notifier).addItem(
                          {
                            ...item,
                            'vendorId': widget.restaurant['id'],
                            'vendorName': widget.restaurant['name'],
                          }, 
                          unit: _selectedUnit,
                          variant: _selectedVariant,
                          options: flatOptions,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.addedToCart),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: requiredMet ? AppColors.primary : (isDark ? Colors.white24 : Colors.grey.shade400),
                      foregroundColor: requiredMet ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      requiredMet 
                          ? s.addToCart 
                          : (isAr ? 'تحديد الخيارات المطلوبة' : 'Select Required Options'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                                onPressed: () {
                                  final authStatus = ref.read(authControllerProvider);
                                  if (authStatus == AuthStatus.unauthenticated) {
                                    AuthPromptDialog.show(context);
                                    return;
                                  }
                                  ref.read(cartProvider.notifier).updateQuantity(currentCartItem!, currentQty - 1);
                                },
                              ),
                              Text(
                                '$currentQty',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
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
                                  try {
                                    await ref.read(cartProvider.notifier).updateQuantity(currentCartItem!, currentQty + 1);
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          child: Text(s.done, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? Colors.black 
                    : (widget.isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${price.toStringAsFixed(2)} ${s.egp}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Colors.black87 
                    : (widget.isDark ? Colors.white70 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
