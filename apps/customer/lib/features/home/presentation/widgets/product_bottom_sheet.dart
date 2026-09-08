import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';

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
    if (widget.item['hasVariants'] == true && variants.isNotEmpty) {
      _selectedVariant = variants.first as Map<String, dynamic>;
    }
    
    final productOptionGroups = widget.item['optionGroups'] as List<dynamic>? ?? [];
    for (final group in productOptionGroups) {
      final gId = group['id']?.toString() ?? '';
      _selectedOptions[gId] = [];
    }

    if (_selectedVariant != null) {
      final variantOptionGroups = _selectedVariant!['optionGroups'] as List<dynamic>? ?? [];
      for (final group in variantOptionGroups) {
        final gId = group['id']?.toString() ?? '';
        _selectedOptions[gId] = [];
      }
    }
  }

  bool _areOptionsEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((o) => o['id']?.toString() ?? '').toSet();
    final bIds = b.map((o) => o['id']?.toString() ?? '').toSet();
    return aIds.containsAll(bIds);
  }

  void _toggleOption(Map<String, dynamic> group, Map<String, dynamic> option) {
    final groupId = group['id']?.toString() ?? '';
    final maxSelect = group['maxSelect'] is int 
        ? group['maxSelect'] as int 
        : int.tryParse(group['maxSelect']?.toString() ?? '1') ?? 1;
    final list = List<Map<String, dynamic>>.from(_selectedOptions[groupId] ?? []);
    final optId = option['id']?.toString() ?? '';
    
    final isSelected = list.any((o) => o['id']?.toString() == optId);
    
    setState(() {
      if (isSelected) {
        final isRequired = group['isRequired'] == true;
        if (maxSelect == 1 && isRequired) {
          return;
        }
        list.removeWhere((o) => o['id']?.toString() == optId);
      } else {
        if (maxSelect == 1) {
          list.clear();
          list.add(option);
        } else {
          if (list.length < maxSelect) {
            list.add(option);
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAr 
                    ? 'الحد الأقصى للاختيار هو $maxSelect' 
                    : 'Maximum selection is $maxSelect',
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
      return ci.product['id'] == item['id'] && 
             ci.selectedUnit == _selectedUnit &&
             ci.selectedVariant?['id'] == _selectedVariant?['id'] &&
             _areOptionsEqual(ci.selectedOptions, flatOptions);
    }).firstOrNull;
    
    final currentQty = currentCartItem?.quantity ?? 0;
    
    final bool supportsStrips = item['sellByStrip'] == true && item['stripsPerPackage'] != null;
    final int stripsCount = item['stripsPerPackage'] as int? ?? 1;

    double basePrice = 0.0;
    if (_selectedVariant != null) {
      final vp = _selectedVariant!['basePrice'];
      basePrice = double.tryParse(vp?.toString() ?? '0') ?? 0.0;
    } else {
      final p = item['price'] ?? item['basePrice'];
      basePrice = double.tryParse(p?.toString() ?? '0') ?? 0.0;
    }

    double currentUnitPrice = _selectedUnit == 'strip' ? (basePrice / stripsCount) : basePrice;
    
    for (final opt in flatOptions) {
      final op = opt['priceAdded'];
      currentUnitPrice += double.tryParse(op?.toString() ?? '0') ?? 0.0;
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final name = isAr && item['nameAr'] != null && item['nameAr'].toString().isNotEmpty
        ? item['nameAr'] as String
        : item['name'] as String;
    final description = isAr && item['descriptionAr'] != null && item['descriptionAr'].toString().isNotEmpty
        ? item['descriptionAr'] as String
        : item['description'] as String? ?? '';

    final variants = item['variants'] as List<dynamic>? ?? [];
    final productOptionGroups = item['optionGroups'] as List<dynamic>? ?? [];
    final variantOptionGroups = _selectedVariant?['optionGroups'] as List<dynamic>? ?? [];
    final optionGroups = [...productOptionGroups, ...variantOptionGroups];

    // Check if required options are met
    bool requiredMet = true;
    for (final group in optionGroups) {
      if (group['isRequired'] == true) {
        final minSelect = group['minSelect'] is int 
            ? group['minSelect'] as int 
            : int.tryParse(group['minSelect']?.toString() ?? '1') ?? 1;
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
                          if (item['comparePrice'] != null && (item['comparePrice'] as num) > currentUnitPrice) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(item['comparePrice'] as num).toStringAsFixed((item['comparePrice'] as num) % 1 == 0 ? 0 : 2)} ${s.egp}',
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
                                    '-${((((item['comparePrice'] as num) - currentUnitPrice) / (item['comparePrice'] as num)) * 100).round()}%',
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
                            price: basePrice,
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
                            price: basePrice / stripsCount,
                            s: s,
                            onTap: () {
                              setState(() => _selectedUnit = 'strip');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (item['hasVariants'] == true && variants.isNotEmpty) ...[
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
                      final vPrice = double.tryParse(v['basePrice']?.toString() ?? '0') ?? 0.0;
                      return RadioListTile<String>(
                        title: Text(vName),
                        subtitle: Text('${vPrice.toStringAsFixed(2)} ${s.egp}'),
                        value: v['id'],
                        groupValue: _selectedVariant?['id'],
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _selectedVariant = v as Map<String, dynamic>;
                            // Reset selected options so selections made for a
                            // previous variant don't leak into this one.
                            _selectedOptions.clear();
                            final productGroups = widget.item['optionGroups'] as List<dynamic>? ?? [];
                            for (final g in productGroups) {
                              final gId = g['id']?.toString() ?? '';
                              _selectedOptions[gId] = [];
                            }
                            final vOptionGroups = v['optionGroups'] as List<dynamic>? ?? [];
                            for (final g in vOptionGroups) {
                              final gId = g['id']?.toString() ?? '';
                              _selectedOptions[gId] = [];
                            }
                          });
                        },
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
                              
                              if (maxSelect == 1) {
                                return RadioListTile<String>(
                                  title: Text(oName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  subtitle: oPrice > 0 ? Text('+${oPrice.toStringAsFixed(2)} ${s.egp}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)) : null,
                                  value: optId,
                                  groupValue: (_selectedOptions[gId]?.isNotEmpty ?? false)
                                      ? _selectedOptions[gId]!.first['id']?.toString()
                                      : null,
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (_) => _toggleOption(group as Map<String, dynamic>, opt as Map<String, dynamic>),
                                );
                              }

                              return CheckboxListTile(
                                title: Text(oName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                subtitle: oPrice > 0 ? Text('+${oPrice.toStringAsFixed(2)} ${s.egp}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)) : null,
                                value: isSelected,
                                activeColor: AppColors.primary,
                                checkColor: Colors.black,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: (val) => _toggleOption(group as Map<String, dynamic>, opt as Map<String, dynamic>),
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
            child: currentQty == 0
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
                              content: Text(ApiErrorMapper.fromError(e).tr()),
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
                                  try {
                                    await ref.read(cartProvider.notifier).updateQuantity(currentCartItem!, currentQty + 1);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ApiErrorMapper.fromError(e).tr()),
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
