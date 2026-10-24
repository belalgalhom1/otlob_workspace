import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/widgets/custom_chat_icon.dart';
import '../widgets/product_bottom_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';
import '../providers/vendor_detail_controller.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';

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
  bool _isScheduleExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final closestBranch = widget.restaurant['_proximity']?['closestBranch'];
      final closestBranchId = closestBranch?['id']?.toString() ??
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

  void _showBranchSelector(BuildContext context, List<dynamic> branches, String vendorId, bool isAr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentSelected = ref.read(selectedBranchProvider)[vendorId]?.id;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'اختر الفرع المناسب' : 'Select Branch',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...branches.map((b) {
                if (b is! Map) return const SizedBox.shrink();
                final bId = b['id']?.toString() ?? '';
                final bName = (isAr ? (b['nameAr'] ?? b['name']) : b['name'])?.toString() ?? 'Branch';
                final bAddress = b['address']?.toString() ?? '';
                final isSelected = bId == currentSelected;
                return ListTile(
                  leading: Icon(LucideIcons.mapPin, color: isSelected ? AppColors.primary : Colors.grey),
                  title: Text(bName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  subtitle: bAddress.isNotEmpty ? Text(bAddress) : null,
                  trailing: isSelected ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
                  onTap: () {
                    ref.read(selectedBranchProvider.notifier).selectBranchById(
                      vendorId,
                      bId,
                      name: b['name']?.toString(),
                      nameAr: b['nameAr']?.toString(),
                      address: b['address']?.toString(),
                    );
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);
    
    final vendorId = widget.restaurant['id']?.toString() ?? '';
    final detailAsync = ref.watch(vendorDetailControllerProvider(vendorId));

    return detailAsync.when(
      data: (fullVendor) {
        final typeStr = fullVendor['type']?.toString().toLowerCase() ?? '';
        final vendorSlug = fullVendor['slug']?.toString().toLowerCase() ?? '';
        final vendorName = fullVendor['name']?.toString().toLowerCase() ?? '';
        final isPharmacy = typeStr.contains('pharmacy') || typeStr.contains('pharmacies-') || typeStr.contains('صيدلي') || typeStr.contains('صيدليات') || typeStr.contains('medical') || typeStr.contains('medicine') || typeStr.contains('pharma') ||
                           vendorSlug.contains('pharmacy') || vendorSlug.contains('صيدلي') || vendorSlug.contains('صيدليات') ||
                           vendorName.contains('pharmacy') || vendorName.contains('صيدلي') || vendorName.contains('صيدليات');
        final allMenu = (fullVendor['menu'] as List<dynamic>?) ?? [];
        final workingHours = (fullVendor['workingHours'] as List<dynamic>?) ?? [];
        final isOpen = _isCurrentlyOpen(workingHours);

        final initialProductId = widget.restaurant['productId'];
        if (!_initialProductShown && initialProductId != null && allMenu.isNotEmpty) {
          final item = allMenu.where((i) => i['id']?.toString() == initialProductId.toString()).firstOrNull;
          if (item != null) {
            _initialProductShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isOpen) {
                _showProductBottomSheet(context, ref, item as Map<String, dynamic>, ref.read(cartProvider), s, isDark, isPharmacy);
              }
            });
          }
        }
        
        final filteredMenu = allMenu.where((item) {
          final map = item as Map<String, dynamic>;
          final matchesCategory = _selectedCategory == 'all' || map['category'] == _selectedCategory;
          
          if (_searchQuery.isEmpty) return matchesCategory;

          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          final name = (isAr ? (map['nameAr'] ?? map['name'] ?? '') : (map['name'] ?? '')).toString().toLowerCase();
          final description = (isAr ? (map['descriptionAr'] ?? map['description'] ?? '') : (map['description'] ?? '')).toString().toLowerCase();
          final searchLower = _searchQuery.toLowerCase();
          
          return matchesCategory && (name.contains(searchLower) || description.contains(searchLower));
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 240,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          (() {
                            final coverUrl = fullVendor['coverImage'] ?? fullVendor['image'];
                            final fallbackFill = isDark ? const Color(0xFF252525) : Colors.grey.shade200;
                            return (coverUrl == null || coverUrl.toString().isEmpty)
                                ? Container(color: fallbackFill, child: const Icon(Icons.restaurant, size: 48, color: Colors.grey))
                                : Container(
                                    color: fallbackFill,
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: CachedNetworkImage(
                                      imageUrl: ImageUtils.formatImageUrl(coverUrl as String?),
                                      fit: BoxFit.contain,
                                      placeholder: (c, u) => Container(color: fallbackFill),
                                      errorWidget: (c, u, e) => Container(color: fallbackFill, child: const Icon(Icons.restaurant, size: 48, color: Colors.grey)),
                                    ),
                                  );
                          }()),
                          // Dynamic gradient for better text/icon visibility
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1),
                                  Theme.of(context).scaffoldBackgroundColor,
                                ],
                                stops: const [0.0, 0.3, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.all(20),
                      child: Builder(builder: (context) {
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        final name = (isAr && fullVendor['nameAr'] != null && fullVendor['nameAr'].toString().isNotEmpty
                            ? fullVendor['nameAr']
                            : (fullVendor['name'] ?? fullVendor['storeName'] ?? ''))?.toString() ?? '';
                        final description = (isAr && fullVendor['vendorAr'] != null && fullVendor['vendorAr'].toString().isNotEmpty
                            ? fullVendor['vendorAr']
                            : (fullVendor['vendor'] ?? fullVendor['description'] ?? ''))?.toString() ?? '';

                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(
                              child: Text(
                                name, 
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : Colors.black,
                                ), 
                                overflow: TextOverflow.ellipsis
                              )
                            ),
                            Row(children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text((fullVendor['rating'] as num? ?? 0).toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                              if (fullVendor['ratingCount'] != null && fullVendor['ratingCount'] > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${fullVendor['ratingCount']})',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ]),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            description, 
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87.withValues(alpha: 0.7), 
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              letterSpacing: 0.1,
                            ),
                          ),
                          Builder(builder: (context) {
                            final branches = (fullVendor['branches'] as List<dynamic>?) ?? [];
                            final activeBranchId = ref.watch(selectedBranchProvider)[fullVendor['id'].toString()]?.id;
                            final currentBranch = branches.where((b) => b['id']?.toString() == activeBranchId).firstOrNull ??
                                (fullVendor['closestBranch'] is Map ? fullVendor['closestBranch'] as Map : null) ??
                                (branches.isNotEmpty ? branches.first as Map : null);
                            if (currentBranch == null) return const SizedBox.shrink();
                            final bName = (isAr ? (currentBranch['nameAr'] ?? currentBranch['name']) : currentBranch['name'])?.toString() ?? '';
                            final bAddress = currentBranch['address']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${isAr ? "الفرع" : "Branch"}: $bName${bAddress.isNotEmpty ? " • $bAddress" : ""}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (branches.length > 1)
                                    InkWell(
                                      onTap: () => _showBranchSelector(context, branches, fullVendor['id'].toString(), isAr),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          isAr ? 'تغيير' : 'Change',
                                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          _buildWorkingHoursWidget(
                            (fullVendor['workingHours'] as List<dynamic>?) ?? [],
                            isAr,
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 46,
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final authState = ref.read(authControllerProvider);
                                if (authState != AuthStatus.authenticated) {
                                  AuthPromptDialog.show(context);
                                  return;
                                }
                                context.push('/chat/vendor/${fullVendor['id']}', extra: {'title': name});
                              },
                              icon: const CustomChatIcon(size: 18, color: AppColors.primary),
                              label: Text(
                                s.chatWithVendor,
                                style: const TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w900, 
                                  color: AppColors.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                s.chatWithVendorSubtext,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ]);
                      }),
                    ),
                  ),

                  if (fullVendor['categories'] != null && (fullVendor['categories'] as List).isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: _buildCategoryList(fullVendor['categories'] as List<dynamic>, allMenu, s, isDark),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPharmacy ? s.products : s.menu, 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), 
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: s.search,
                                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500),
                                prefixIcon: Icon(Icons.search, size: 20, color: isDark ? AppColors.primary : Colors.grey),
                                suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(
                                        icon: Icon(Icons.clear, size: 18, color: isDark ? Colors.white70 : Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (filteredMenu.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                s.noItemsInCategory,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildMenuItem(context, ref, filteredMenu[index] as Map<String, dynamic>, cartState, s, isDark, isOpen, isPharmacy),
                          childCount: filteredMenu.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              FloatingCartOverlay(),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${s.errorPrefix}${ErrorUtils.translate(context, err)}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(vendorDetailControllerProvider(vendorId)),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<dynamic> categories, List<dynamic> menuItems, AppStrings s, bool isDark) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    // Add "All" category at the beginning
    final allCategories = [
      {'id': 'all', 'name': s.catAll, 'nameAr': 'الكل', 'icon': Icons.grid_view_rounded},
      ...categories,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allCategories.map((cat) {
          final catId = cat['id']?.toString() ?? '';
          final isSelected = _selectedCategory == catId;
          final label = isAr ? (cat['nameAr'] ?? cat['name'] ?? '') : (cat['name'] ?? '');
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = catId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsetsDirectional.only(end: 12),
              width: 85,
              height: 115,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                  width: 1.5,
                ),
                boxShadow: isSelected 
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] 
                  : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: ClipOval(
                        child: catId == 'all' 
                          ? _buildAllCategoryIconCluster(categories, isSelected)
                          : (cat['iconUrl'] != null && cat['iconUrl'].toString().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ImageUtils.formatImageUrl(cat['iconUrl'] as String?),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Icon(
                                  Icons.category_rounded, 
                                  size: 32, 
                                  color: isSelected ? Colors.white : AppColors.primary
                                ),
                              )
                            : Icon(
                                (cat['icon'] as IconData?) ?? Icons.grid_view_rounded, 
                                size: 32, 
                                color: isSelected ? Colors.white : AppColors.primary
                              )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      label, 
                      style: TextStyle(
                        color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87), 
                        fontWeight: FontWeight.w900, 
                        fontSize: 9.5,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllCategoryIconCluster(List<dynamic> categories, bool isSelected) {
    final previewItems = categories.where((c) => (c['iconUrl'] != null && c['iconUrl'].toString().isNotEmpty) || c['icon'] != null).take(4).toList();
    final color = isSelected ? Colors.black : AppColors.primary;
    
    if (previewItems.isEmpty) {
      return Icon(Icons.grid_view_rounded, size: 28, color: color);
    }

    return SizedBox(
      width: 72,
      height: 72,
      child: Center(
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            children: List.generate(previewItems.length, (index) {
              final double radius = 16.0;
              final cat = previewItems[index] as Map<String, dynamic>;
              
              return Center(
                child: Transform.translate(
                  offset: Offset(
                    radius * (index == 0 || index == 1 ? 1 : -1),
                    radius * (index == 1 || index == 2 ? 1 : -1),
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                    ),
                    child: ClipOval(
                      child: (cat['iconUrl'] != null && cat['iconUrl'].toString().isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: ImageUtils.formatImageUrl(cat['iconUrl'] as String?),
                            fit: BoxFit.contain,
                            errorWidget: (c, u, e) => Icon((cat['icon'] as IconData?) ?? Icons.category_rounded, size: 14, color: color),
                          )
                        : Icon((cat['icon'] as IconData?) ?? Icons.grid_view_rounded, size: 16, color: color),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, Map<String, dynamic> item, CartState cartState, AppStrings s, bool isDark, bool isOpen, bool isPharmacy) {
    final totalCartQty = cartState.allItems
        .where((ci) => ci.product.id == item['id']?.toString())
        .fold<int>(0, (sum, ci) => sum + ci.quantity);

    final bool tracksStock = item['tracksStock'] == null ? true : (item['tracksStock'] == true);
    final int? itemStock = item['stock'] == null ? null : int.tryParse(item['stock'].toString());
    final List<dynamic> menuVariants = item['variants'] as List? ?? [];
    final bool hasMenuVariants = item['hasVariants'] == true && menuVariants.isNotEmpty;
    // Subtract what's already in the cart: the menu snapshot goes stale the
    // moment the first unit is added, and the backend rejects over-stock at
    // checkout. Per-variant lines are gated inside the bottom sheet.
    final int remainingSimpleStock = (tracksStock && itemStock != null)
        ? itemStock - totalCartQty
        : 1;
    final bool isItemOutOfStock = (hasMenuVariants
        ? menuVariants.every((v) {
            final vTracks = v['tracksStock'] == null ? true : (v['tracksStock'] == true);
            final int? vStock = v['stock'] == null ? null : int.tryParse(v['stock'].toString());
            return vTracks && vStock != null && vStock <= 0;
          })
        : (tracksStock && itemStock != null && remainingSimpleStock <= 0));

    return GestureDetector(
      onTap: () {
        final authStatus = ref.read(authControllerProvider);
        if (authStatus == AuthStatus.unauthenticated) {
          AuthPromptDialog.show(context);
          return;
        }

        if (!isOpen) {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';
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
        _showProductBottomSheet(context, ref, item, cartState, s, isDark, isPharmacy);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (context) {
                    final isAr = Localizations.localeOf(context).languageCode == 'ar';
                    final name = (isAr && item['nameAr'] != null && item['nameAr'].toString().isNotEmpty
                        ? item['nameAr']
                        : (item['name'] ?? ''))?.toString() ?? '';
                    final description = (isAr && item['descriptionAr'] != null && item['descriptionAr'].toString().isNotEmpty
                        ? item['descriptionAr']
                        : (item['description'] ?? ''))?.toString() ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name, 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 15, 
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ), 
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description, 
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600, 
                            fontSize: 12,
                            height: 1.3,
                          ), 
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  Builder(builder: (context) {
                    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                    final comparePrice = (item['comparePrice'] as num?)?.toDouble();
                    final hasDiscount = comparePrice != null && comparePrice > price;
                    final hasVariants = item['hasVariants'] == true && (item['variants'] as List?)?.isNotEmpty == true;
                    final prefix = hasVariants ? (s.isArabic ? 'يبدأ من ' : 'From ') : '';
                    final priceStr = price.toStringAsFixed(price % 1 == 0 ? 0 : 2);
                    final compareStr = hasDiscount
                        ? comparePrice.toStringAsFixed(comparePrice % 1 == 0 ? 0 : 2)
                        : '';

                    return Text.rich(
                      TextSpan(
                        children: [
                          if (prefix.isNotEmpty)
                            TextSpan(
                              text: prefix,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          TextSpan(
                            text: '$priceStr ${s.egp}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          if (hasDiscount)
                            TextSpan(
                              text: '  $compareStr ${s.egp}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                  if (isOpen) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                          onTap: () async {
                            if (isItemOutOfStock) return;

                            final authStatus = ref.read(authControllerProvider);
                            if (authStatus == AuthStatus.unauthenticated) {
                              AuthPromptDialog.show(context);
                              return;
                            }

                            final hasVariants = (item['hasVariants'] == true && (item['variants'] as List?)?.isNotEmpty == true);
                            final hasOptionGroups = (item['optionGroups'] as List?)?.isNotEmpty == true;
                            final hasVariantsWithOptions = (item['variants'] as List?)?.any((v) => (v['optionGroups'] as List?)?.isNotEmpty == true) ?? false;
                            final isPharmacyWithStrips = isPharmacy && item['sellByStrip'] == true && item['stripsPerPackage'] != null;
                            final hasCustomizations = hasVariants || hasOptionGroups || hasVariantsWithOptions || isPharmacyWithStrips;

                            if (hasCustomizations) {
                              setState(() => _selectedUnit = 'package');
                              _showProductBottomSheet(context, ref, item, cartState, s, isDark, isPharmacy);
                              return;
                            }
                            
                            try {
                              await ref.read(cartProvider.notifier).addItem({
                                ...item,
                                'vendorId': widget.restaurant['id'],
                                'vendorName': widget.restaurant['name'],
                              }, unit: 'package');
                              
                              if (context.mounted) {
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isItemOutOfStock
                                  ? (isDark ? Colors.white12 : Colors.grey.shade200)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: isItemOutOfStock ? AppColors.textHint : AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  isItemOutOfStock
                                      ? s.outOfStock
                                      : (totalCartQty > 0 ? '${s.addToCart} ($totalCartQty)' : s.addToCart),
                                  style: TextStyle(
                                    color: isItemOutOfStock ? AppColors.textHint : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ((item['imageUrl'] ?? item['image'])?.toString().isEmpty ?? true)
                        ? Icon(Icons.fastfood, color: Colors.grey.shade400, size: 36)
                        : CachedNetworkImage(
                            imageUrl: ImageUtils.formatImageUrl((item['imageUrl'] ?? item['image']) as String?),
                            fit: BoxFit.cover,
                            width: 110,
                            height: 110,
                          ),
                  ),
                ),
                if (item['comparePrice'] != null && (item['comparePrice'] as num) > (item['price'] as num))
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '-${((((item['comparePrice'] as num) - (item['price'] as num)) / (item['comparePrice'] as num)) * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }




  void _showProductBottomSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> item, CartState cartState, AppStrings s, bool isDark, bool isPharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProductBottomSheet(
          item: item,
          restaurant: widget.restaurant,
          initialUnit: _selectedUnit,
          s: s,
          isDark: isDark,
          isPharmacy: isPharmacy,
        );
      },
    );
  }

  bool _isCurrentlyOpen(List<dynamic> workingHours) {
    if (workingHours.isEmpty) return true;
    final now = DateTime.now();
    final todayDay = now.weekday % 7;
    final todaySchedule = workingHours.where((h) => int.tryParse(h['day'].toString()) == todayDay).firstOrNull;
    if (todaySchedule == null) return true;
    
    final isClosed = todaySchedule['isClosed'] == true || todaySchedule['isClosed'] == 'true';
    if (isClosed) return false;
    
    final openTimeStr = todaySchedule['openTime'] as String? ?? '09:00';
    final closeTimeStr = todaySchedule['closeTime'] as String? ?? '22:00';
    
    try {
      final openParts = openTimeStr.split(':');
      final closeParts = closeTimeStr.split(':');
      
      final openHour = int.parse(openParts[0]);
      final openMin = int.parse(openParts[1]);
      
      final closeHour = int.parse(closeParts[0]);
      final closeMin = int.parse(closeParts[1]);
      
      final currentHour = now.hour;
      final currentMin = now.minute;
      
      final openMinutes = openHour * 60 + openMin;
      final closeMinutes = closeHour * 60 + closeMin;
      final currentMinutes = currentHour * 60 + currentMin;
      
      if (closeMinutes < openMinutes) {
        return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
      }
      return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
    } catch (e) {
      return true;
    }
  }

  Widget _buildWorkingHoursWidget(List<dynamic> workingHours, bool isAr, bool isDark) {
    if (workingHours.isEmpty) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final todayDay = now.weekday % 7;
    final isOpen = _isCurrentlyOpen(workingHours);
    
    String getDayName(int day) {
      switch (day) {
        case 0: return isAr ? 'الأحد' : 'Sunday';
        case 1: return isAr ? 'الإثنين' : 'Monday';
        case 2: return isAr ? 'الثلاثاء' : 'Tuesday';
        case 3: return isAr ? 'الأربعاء' : 'Wednesday';
        case 4: return isAr ? 'الخميس' : 'Thursday';
        case 5: return isAr ? 'الجمعة' : 'Friday';
        case 6: return isAr ? 'السبت' : 'Saturday';
        default: return '';
      }
    }

    String formatTimeTo12Hour(String timeStr, bool isArabic) {
      try {
        final parts = timeStr.split(':');
        if (parts.length < 2) return timeStr;
        final hour = int.tryParse(parts[0]) ?? 0;
        final min = int.tryParse(parts[1]) ?? 0;
        
        final period = hour >= 12 ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');
        var displayHour = hour % 12;
        if (displayHour == 0) displayHour = 12;
        
        final minStr = min.toString().padLeft(2, '0');
        final hourStr = displayHour.toString().padLeft(2, '0');
        
        return '$hourStr:$minStr $period';
      } catch (e) {
        return timeStr;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isScheduleExpanded = !_isScheduleExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendarClock,
                    color: isOpen ? AppColors.primary : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'ساعات العمل الأسبوعية' : 'Weekly Working Hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOpen ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOpen 
                                  ? (isAr ? 'مفتوح الآن للطلبات' : 'Open Now for Orders')
                                  : (isAr ? 'مغلق الآن - لا يستقبل طلبات' : 'Closed Now - No Orders'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOpen ? Colors.green : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isScheduleExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: isDark ? Colors.white54 : Colors.black54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isScheduleExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Builder(
                builder: (context) {
                  final sortedHours = List<dynamic>.from(workingHours);
                  sortedHours.sort((a, b) {
                    final dayA = int.tryParse(a['day'].toString()) ?? 0;
                    final dayB = int.tryParse(b['day'].toString()) ?? 0;
                    int getSortVal(int d) => [6, 0, 1, 2, 3, 4, 5].indexOf(d);
                    return getSortVal(dayA).compareTo(getSortVal(dayB));
                  });
                  
                  return Column(
                    children: List.generate(sortedHours.length, (index) {
                      final item = sortedHours[index];
                      final day = int.tryParse(item['day'].toString()) ?? 0;
                      final isClosed = item['isClosed'] as bool? ?? false;
                      final openTime = item['openTime'] as String? ?? '09:00';
                      final closeTime = item['closeTime'] as String? ?? '22:00';
                      final isToday = day == todayDay;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              getDayName(day),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday 
                                    ? AppColors.primary 
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                            isClosed
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAr ? 'إجازة' : 'Closed',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${formatTimeTo12Hour(openTime, isAr)} - ${formatTimeTo12Hour(closeTime, isAr)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                      color: isToday 
                                          ? AppColors.primary 
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
