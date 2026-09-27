import 'package:flutter/material.dart';
import 'package:api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/vendors/presentation/widgets/add_product_dialog.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:core/core.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:data/data.dart';
import 'package:built_value/json_object.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final String? vendorType;
  final bool isAdmin;

  const ProductsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.vendorType,
    this.isAdmin = false,
  });

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  int _total = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts({String? search}) async {
    setState(() => _isLoading = true);
    final result = await ref
        .read(adminVendorsRepositoryProvider)
        .getProducts(widget.vendorId, search: search);
    if (mounted) {
      setState(() {
        _products = result['products'] ?? result['items'] ?? [];
        _total = result['total'] ?? 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.products,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '${widget.vendorName} • ${AppLocalizations.of(context)!.itemsCount(_total)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddProductDialog(),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(AppLocalizations.of(context)!.addProduct),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: isMobile ? 14 : 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Search Bar
                DashboardSearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    _fetchProducts(search: value);
                  },
                  onClear: () {
                    _fetchProducts();
                  },
                ),
                const SizedBox(height: 24),

                // Products List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _products.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _products.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: const Icon(
              LucideIcons.package,
              size: 48,
              
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noProductsFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noProductsDescription,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final bool isActive = product['isActive'] ?? true;
    final double price =
        double.tryParse(product['basePrice']?.toString() ?? '') ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product['imageUrl'] != null
                    ? CachedNetworkImage(
                        imageUrl: ImageUtils.formatImageUrl(
                          product['imageUrl'],
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          LucideIcons.image,
                          
                          size: 20,
                        ),
                      )
                    : const Icon(
                        LucideIcons.package,
                        color: AppColors.primary,
                        size: 24,
                      ),
              ),
            ),
            title: Text(
              product['name'] ?? AppLocalizations.of(context)!.unnamedProduct,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product['sellByStrip'] == true &&
                        product['stripsPerPackage'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(price / (product['stripsPerPackage'] as int)).toStringAsFixed(2)} / ${AppLocalizations.of(context)!.sellByStrip}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive
                            ? AppLocalizations.of(context)!.activeStatus
                            : AppLocalizations.of(context)!.inactiveStatus,
                        style: TextStyle(
                          color: isActive ? AppColors.success : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (product['stock'] != null)
                      Text(
                        product['tracksStock'] == false
                            ? '${AppLocalizations.of(context)!.stock}: ${AppLocalizations.of(context)!.notTracked}'
                            : '${AppLocalizations.of(context)!.stock}: ${product['stock']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: product['tracksStock'] != false &&
                                  (num.tryParse(product['stock'].toString()) ?? 0) <= 0
                              ? AppColors.error
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionItem(
                  context: context,
                  icon: LucideIcons.edit3,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                  label: AppLocalizations.of(context)!.edit,
                  onPressed: () => _showAddProductDialog(product: product),
                ),
                const SizedBox(width: 8),
                _buildActionItem(
                  context: context,
                  icon: LucideIcons.trash2,
                  color: AppColors.error,
                  label: AppLocalizations.of(context)!.delete,
                  onPressed: () => _confirmDelete(product),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog({dynamic product}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddProductDialog(
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        vendorType: widget.vendorType,
        product: product,
        isAdmin: widget.isAdmin,
      ),
    );

    if (result != null && mounted) {
      bool success = false;
      String? productId;

      try {
        if (product != null) {
          final updateResult = await ref
              .read(adminVendorsRepositoryProvider)
              .updateProduct(
                widget.vendorId,
                product['id'],
                UpdateProductDto((b) {
                  if (result['name'] != null) b.name = result['name'];
                  if (result['nameAr'] != null) b.nameAr = result['nameAr'];
                  if (result['description'] != null) b.description = result['description'];
                  if (result['descriptionAr'] != null) b.descriptionAr = result['descriptionAr'];
                  if (result['basePrice'] != null) b.basePrice = num.tryParse(result['basePrice'].toString());
                  if (result['comparePrice'] != null) b.comparePrice = num.tryParse(result['comparePrice'].toString());
                  if (result['stock'] != null) b.stock = num.tryParse(result['stock'].toString());
                  if (result['sku'] != null && result['sku'].toString().trim().isNotEmpty) {
                    b.sku = result['sku'].toString().trim();
                  }
                  if (result['isActive'] != null) b.isActive = result['isActive'];
                  if (result['sellByStrip'] != null) b.sellByStrip = result['sellByStrip'];
                  if (result['tracksStock'] != null) b.tracksStock = result['tracksStock'];
                  if (result['stripsPerPackage'] != null) b.stripsPerPackage = num.tryParse(result['stripsPerPackage'].toString());
                  if (result['categoryId'] != null) b.categoryId = JsonObject(result['categoryId']);
                }),
                isAdmin: widget.isAdmin,
              );
          success = updateResult != null;
          productId = product['id'];
        } else {
          final createdProduct = await ref
              .read(adminVendorsRepositoryProvider)
              .createProduct(
                widget.vendorId,
                CreateProductDto((b) {
                  b.name = result['name'] ?? '';
                  b.nameAr = result['nameAr'] ?? '';
                  b.basePrice = num.tryParse(result['basePrice']?.toString() ?? '0') ?? 0;
                  if (result['comparePrice'] != null) b.comparePrice = num.tryParse(result['comparePrice'].toString());
                  if (result['description'] != null) b.description = result['description'];
                  if (result['descriptionAr'] != null) b.descriptionAr = result['descriptionAr'];
                  if (result['stock'] != null) b.stock = num.tryParse(result['stock'].toString());
                  if (result['sku'] != null && result['sku'].toString().trim().isNotEmpty) {
                    b.sku = result['sku'].toString().trim();
                  }
                  b.isActive = result['isActive'] ?? true;
                  if (result['sellByStrip'] != null) b.sellByStrip = result['sellByStrip'];
                  if (result['tracksStock'] != null) b.tracksStock = result['tracksStock'];
                  if (result['stripsPerPackage'] != null) b.stripsPerPackage = num.tryParse(result['stripsPerPackage'].toString());
                  b.categoryId = result['categoryId'] ?? '';
                  final variants = (result['variants'] as List? ?? []);
                  if (variants.isNotEmpty) {
                    b.hasVariants = true;
                    b.variants.replace(_buildVariantDtos(variants));
                  } else {
                    b.hasVariants = false;
                    final optionGroups = (result['optionGroups'] as List? ?? []);
                    if (optionGroups.isNotEmpty) {
                      b.optionGroups.replace(_buildOptionGroupDtos(optionGroups));
                    }
                  }
                }),
                isAdmin: widget.isAdmin,
              );
          productId = createdProduct?['id'];
          success = productId != null;
        }

        if (success &&
            productId != null &&
            productId != 'success' &&
            result['imageFile'] != null) {
          final imageFile = result['imageFile'] as XFile;
          final multipartFile = await dio.MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.name,
          );
          await ref
              .read(adminVendorsRepositoryProvider)
              .uploadProductImage(widget.vendorId, productId, multipartFile);
        }

        if (success) {
          _fetchProducts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ErrorUtils.translate(
                    context,
                    product != null
                        ? 'common.success.resource_updated'
                        : 'common.success.resource_created',
                  ),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorUtils.translate(context, e.toString())),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<CreateProductVariantDto> _buildVariantDtos(List<dynamic> variants) {
    return variants.map((v) {
      return CreateProductVariantDto((b) {
        b.name = (v['name'] ?? '').toString();
        if (v['nameAr']?.toString().isNotEmpty == true) {
          b.nameAr = v['nameAr'].toString();
        }
        b.basePrice = num.tryParse(v['basePrice']?.toString() ?? '') ?? 0;
        if (v['comparePrice'] != null) {
          b.comparePrice = num.tryParse(v['comparePrice'].toString());
        }
        if (v['sku']?.toString().isNotEmpty == true) {
          b.sku = v['sku'].toString();
        }
        if (v['stock'] != null) b.stock = num.tryParse(v['stock'].toString());
        if (v['tracksStock'] != null) b.tracksStock = v['tracksStock'] == true;
        final variantGroups = (v['optionGroups'] as List? ?? []);
        if (variantGroups.isNotEmpty) {
          b.optionGroups.replace(_buildOptionGroupDtos(variantGroups));
        }
      });
    }).toList();
  }

  List<CreateOptionGroupDto> _buildOptionGroupDtos(List<dynamic> groups) {
    return groups.map((g) {
      return CreateOptionGroupDto((b) {
        b.name = (g['name'] ?? '').toString();
        if (g['nameAr']?.toString().isNotEmpty == true) {
          b.nameAr = g['nameAr'].toString();
        }
        if (g['minSelect'] != null) {
          b.minSelect = num.tryParse(g['minSelect'].toString());
        }
        if (g['maxSelect'] != null) {
          b.maxSelect = num.tryParse(g['maxSelect'].toString());
        }
        if (g['isRequired'] != null) b.isRequired = g['isRequired'] == true;
        final opts = (g['options'] as List? ?? []);
        if (opts.isNotEmpty) {
          b.options.replace(opts.map((o) {
            return CreateProductOptionDto((b) {
              b.name = (o['name'] ?? '').toString();
              if (o['nameAr']?.toString().isNotEmpty == true) {
                b.nameAr = o['nameAr'].toString();
              }
              if (o['priceAdded'] != null) {
                b.priceAdded = num.tryParse(o['priceAdded'].toString());
              }
            });
          }).toList());
        }
      });
    }).toList();
  }

  void _confirmDelete(dynamic product) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.deleteProduct,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.deleteProductConfirm(
                  product['name'] ??
                      AppLocalizations.of(context)!.unnamedProduct,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final success = await ref
                              .read(adminVendorsRepositoryProvider)
                              .deleteProduct(widget.vendorId, product['id'], isAdmin: widget.isAdmin);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (success != null && success != false) {
                            _fetchProducts();
                            if (mounted) {
                              messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ErrorUtils.translate(
                                    context,
                                    'common.success.resource_deleted',
                                  ),
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            }
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ErrorUtils.translate(context, e.toString()),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

