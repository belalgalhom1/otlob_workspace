import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:api/api.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final String? vendorType;
  final dynamic product; // Null for add, not null for edit
  final bool isAdmin;

  const AddProductDialog({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.vendorType,
    this.product,
    this.isAdmin = false,
  });

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  bool get isEdit => widget.product != null;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionArController;
  late TextEditingController _priceController;
  late TextEditingController _comparePriceController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  late TextEditingController _stripsCountController;
  late TextEditingController _stripPriceController;

  late bool _isActive;
  late bool _isFeatured;
  late bool _sellByStrip;
  final bool _isLoading = false;

  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;
  XFile? _imageFile;
  bool _isPickingImage = false;

  // Vendor state
  bool _isLoadingVendor = true;
  dynamic _vendor;
  bool _isRestaurant = false;

  // Variants and Options state
  List<dynamic> _variants = [];
  List<dynamic> _optionGroups = [];
  bool _isLoadingDetails = false;

  final _variantFormKey = GlobalKey<FormState>();

  // Inline notice (visible inside the dialog, unlike SnackBars which render
  // behind the dialog's modal barrier).
  String? _noticeMessage;
  bool _noticeIsError = false;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _nameArController = TextEditingController(text: p?['nameAr'] ?? '');
    _descriptionController = TextEditingController(
      text: p?['description'] ?? '',
    );
    _descriptionArController = TextEditingController(
      text: p?['descriptionAr'] ?? '',
    );
    _priceController = TextEditingController(
      text: p?['basePrice']?.toString() ?? '',
    );
    _comparePriceController = TextEditingController(
      text: p?['comparePrice']?.toString() ?? '',
    );
    _skuController = TextEditingController(text: p?['sku'] ?? '');
    _stockController = TextEditingController(
      text: p?['stock']?.toString() ?? '',
    );
    _isActive = p?['isActive'] ?? true;
    _isFeatured = p?['isFeatured'] ?? false;
    _sellByStrip = p?['sellByStrip'] ?? false;
    _stripsCountController = TextEditingController(
      text: p?['stripsPerPackage']?.toString() ?? '',
    );
    _stripPriceController = TextEditingController();
    _selectedCategoryId = p?['categoryId']?.toString();

    // Synchronously set _isRestaurant if vendorType is provided
    final type = widget.vendorType?.toLowerCase() ?? '';
    _isRestaurant =
        type == 'restaurant' ||
        type == 'restaurants' ||
        type.startsWith('restaurant');

    _updateStripPrice();
    _priceController.addListener(_updateStripPrice);
    _stripsCountController.addListener(_updateStripPrice);

    _fetchCategories();
    if (widget.vendorType == null) {
      _fetchVendor();
    } else {
      _isLoadingVendor = false;
    }
    if (isEdit) {
      _fetchProductDetails();
    }
  }

  Future<void> _fetchVendor() async {
    setState(() => _isLoadingVendor = true);
    try {
      final vendor = await ref
          .read(adminVendorsRepositoryProvider)
          .getVendor(widget.vendorId);
      if (mounted && vendor != null) {
        setState(() {
          _vendor = vendor;
          final slug = (vendor['vertical']?['slug'] ?? vendor['type'])
              ?.toString()
              .toLowerCase();
          _isRestaurant =
              slug == 'restaurant' ||
              slug == 'restaurants' ||
              slug?.startsWith('restaurant') == true;
          _isLoadingVendor = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingVendor = false);
      }
    } catch (e) {
      debugPrint('AddProductDialog fetchVendor Error: $e');
      if (mounted) setState(() => _isLoadingVendor = false);
    }
  }

  Future<void> _fetchProductDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final product = await ref
          .read(adminVendorsRepositoryProvider)
          .getVendorProduct(widget.vendorId, widget.product['id']);
      if (mounted && product != null) {
        setState(() {
          _variants = List<dynamic>.from(product['variants'] ?? []);
          _optionGroups = List<dynamic>.from(product['optionGroups'] ?? []);
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  void _updateStripPrice() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final strips = int.tryParse(_stripsCountController.text) ?? 0;
    if (strips > 0) {
      final stripPrice = price / strips;
      _stripPriceController.text = stripPrice.toStringAsFixed(2);
    } else {
      _stripPriceController.text = '';
    }
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _priceController.removeListener(_updateStripPrice);
    _stripsCountController.removeListener(_updateStripPrice);
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _stripsCountController.dispose();
    _stripPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ref
          .read(adminVendorsRepositoryProvider)
          .getMenuCategories(widget.vendorId);
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _imageFile = XFile(result.files.single.path!));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      _showNotice(
        AppLocalizations.of(context)!.failedToPickImage,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isEdit = widget.product != null;

    return DialogScaffold(child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? size.width : 550),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.4
                    : 0.1,
              ),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: DefaultTabController(
          length: 3,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? LucideIcons.edit3 : LucideIcons.package,
                        color: AppColors.primary,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? AppLocalizations.of(context)!.editProduct
                                : AppLocalizations.of(context)!.addProduct,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.vendor(widget.vendorName),
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),

              TabBar(
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.general),
                  Tab(text: AppLocalizations.of(context)!.variants),
                  Tab(text: AppLocalizations.of(context)!.options),
                ],
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
              ),

              Flexible(
                child: TabBarView(
                  children: [
                    _buildGeneralTab(isMobile),
                    _buildVariantsTab(isMobile),
                    _buildOptionsTab(isMobile),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                      ),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _submit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            )
                          : Text(
                              isEdit
                                  ? AppLocalizations.of(context)!.updateProduct
                                  : AppLocalizations.of(context)!.addProduct,
                            ),
                    ),
                  ],
                ),
              ),
            ],
              ),
              if (_noticeMessage != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: IgnorePointer(
                    child: Material(
                      color: _noticeIsError
                          ? AppColors.error
                          : AppColors.success,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          _noticeMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.primary.withValues(alpha: 0.8),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.menuCategory,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          hint: Text(
            _isLoadingCategories
                ? AppLocalizations.of(context)!.loadingCategories
                : AppLocalizations.of(context)!.selectMenuCategory,
            style: const TextStyle( fontSize: 14),
          ),
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          icon: const Icon(
            LucideIcons.chevronDown,
            size: 16,
            
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
          ),
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['id'].toString(),
              child: Text(cat['name'] ?? 'Unnamed'),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              LucideIcons.list,
              size: 18,
              
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextAlign textAlign = TextAlign.start,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          textAlign: textAlign,
          readOnly: readOnly,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: readOnly 
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02) 
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            _buildCategoryDropdown(),
            const SizedBox(height: 24),

            _buildSectionHeader(AppLocalizations.of(context)!.productImage),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 24),

            _buildSectionHeader(AppLocalizations.of(context)!.basicInfo),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: AppLocalizations.of(context)!.productNameEn,
              hint: 'e.g. Classic Cheeseburger',
              icon: LucideIcons.type,
              validator: (v) => v?.isEmpty ?? true
                  ? AppLocalizations.of(context)!.fieldRequired
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameArController,
              label: AppLocalizations.of(context)!.productNameAr,
              hint: 'مثال: تشيز برجر كلاسيك',
              icon: LucideIcons.languages,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: AppLocalizations.of(context)!.descriptionEn,
              hint: 'Detailed product description...',
              icon: LucideIcons.alignLeft,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionArController,
              label: AppLocalizations.of(context)!.descriptionAr,
              hint: 'وصف المنتج بالتفصيل...',
              icon: LucideIcons.alignRight,
              maxLines: 3,
              textAlign: TextAlign.right,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.pricingInventory),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: AppLocalizations.of(context)!.basePrice,
                    hint: '0.00',
                    icon: LucideIcons.dollarSign,
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true
                        ? AppLocalizations.of(context)!.fieldRequired
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _comparePriceController,
                    label: AppLocalizations.of(context)!.comparePrice,
                    hint: '0.00',
                    icon: LucideIcons.tag,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _skuController,
                    label: AppLocalizations.of(context)!.sku,
                    hint: 'Stock unit',
                    icon: LucideIcons.shoppingBag,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _stockController,
                    label: AppLocalizations.of(context)!.initialStock,
                    hint: '0',
                    icon: LucideIcons.box,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.layers,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.sellByStrip,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Switch(
                        value: _sellByStrip,
                        onChanged: (v) => setState(() => _sellByStrip = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_sellByStrip) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stripsCountController,
                            label: AppLocalizations.of(
                              context,
                            )!.stripsPerPackage,
                            hint: '0',
                            icon: LucideIcons.hash,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stripPriceController,
                            label: AppLocalizations.of(context)!.stripPrice,
                            hint: '0.00',
                            icon: LucideIcons.tag,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.settings),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: AppLocalizations.of(context)!.productActiveStatus,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.productVisibleToCustomers,
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    icon: LucideIcons.eye,
                  ),
                  Divider(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    height: 1,
                    indent: 48,
                  ),
                  _buildSwitchTile(
                    title: AppLocalizations.of(context)!.featuredProduct,
                    subtitle: AppLocalizations.of(context)!.showAtTopOfMenu,
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                    icon: LucideIcons.star,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsTab(bool isMobile) {
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddVariantDialog(),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(AppLocalizations.of(context)!.addVariant),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        Expanded(
          child: _variants.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noVariantsYet,
                    style: const TextStyle(),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _variants.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    return ListTile(
                      title: Text(variant['name'] ?? 'Unnamed'),
                      subtitle: Text(
                        '\$${variant['basePrice']} • Stock: ${variant['stock']}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit2, size: 18),
                            onPressed: () =>
                                _showAddVariantDialog(variant: variant),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: AppColors.error,
                            ),
                            onPressed: () => _deleteVariant(variant['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOptionsTab(bool isMobile) {
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddOptionGroupDialog(),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(AppLocalizations.of(context)!.addOptionGroup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
        Expanded(
          child: _optionGroups.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noOptionGroupsYet,
                    style: const TextStyle(),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _optionGroups.length,
                  itemBuilder: (context, index) {
                    final group = _optionGroups[index];
                    final options = group['options'] as List? ?? [];
                    return ExpansionTile(
                      title: Text(group['name'] ?? 'Unnamed Group'),
                      subtitle: Text(
                        '${options.length} options • Min: ${group['minSelect']} Max: ${group['maxSelect']}',
                      ),
                      children: [
                        ...options.map(
                          (opt) => ListTile(
                            dense: true,
                            title: Text(opt['name'] ?? 'Unnamed Option'),
                            subtitle: Text('+\$${opt['priceAdded']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.edit2, size: 14),
                                  onPressed: () => _showAddOptionDialog(
                                    group['id'],
                                    option: opt,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () =>
                                      _deleteOption(group['id'], opt['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListTile(
                          onTap: () => _showAddOptionDialog(group['id']),
                          leading: const Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            AppLocalizations.of(context)!.addOption,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    _showAddOptionGroupDialog(group: group),
                                icon: const Icon(LucideIcons.edit2, size: 14),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.editOptionGroup,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    _deleteOptionGroup(group['id']),
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.deleteOptionGroup,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddVariantDialog({dynamic variant}) async {
    final nameController = TextEditingController(text: variant?['name'] ?? '');
    final nameArController = TextEditingController(
      text: variant?['nameAr'] ?? '',
    );
    final priceController = TextEditingController(
      text: variant?['basePrice']?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: variant?['stock']?.toString() ?? '',
    );
    final skuController = TextEditingController(text: variant?['sku'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          variant == null
              ? AppLocalizations.of(context)!.addVariant
              : AppLocalizations.of(context)!.editVariant,
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _variantFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: AppLocalizations.of(context)!.nameEn,
                  hint: 'e.g. Small',
                  icon: LucideIcons.type,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? AppLocalizations.of(context)!.fieldRequired
                          : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: nameArController,
                  label: AppLocalizations.of(context)!.nameAr,
                  hint: 'مثال: صغير',
                  icon: LucideIcons.languages,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: priceController,
                        label: AppLocalizations.of(context)!.price,
                        hint: '0.00',
                        icon: LucideIcons.dollarSign,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final p = double.tryParse(v ?? '');
                          if (p == null || p <= 0) {
                            return AppLocalizations.of(context)!.fieldRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: stockController,
                        label: AppLocalizations.of(context)!.stock,
                        hint: '0',
                        icon: LucideIcons.box,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: skuController,
                  label: AppLocalizations.of(context)!.sku,
                  hint: AppLocalizations.of(context)!.optional,
                  icon: LucideIcons.hash,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(_variantFormKey.currentState?.validate() ?? false)) {
                return;
              }
              final data = {
                'name': nameController.text,
                'nameAr': nameArController.text,
                'basePrice': double.tryParse(priceController.text) ?? 0.0,
                'stock': int.tryParse(stockController.text),
                'sku': skuController.text,
              };
              bool success = false;
              if (variant == null) {
                if (widget.product == null) {
                  setState(() {
                    _variants.add({
                      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                      'name': data['name'],
                      'nameAr': data['nameAr'],
                      'basePrice': data['basePrice'],
                      'stock': data['stock'],
                      'sku': data['sku'],
                      'optionGroups': [],
                    });
                  });
                  success = true;
                } else {
                  try { await ref
                      .read(adminVendorsRepositoryProvider)
                      .addVariant(widget.vendorId, widget.product['id'], CreateProductVariantDto((b) {
                        b.name = data['name'] as String;
                        b.nameAr = data['nameAr'] as String;
                        b.basePrice = data['basePrice'] as num;
                        b.stock = data['stock'] as num?;
                        if (data['sku'] != null && (data['sku'] as String).isNotEmpty) b.sku = data['sku'] as String;
                      })); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
                }
              } else {
                if (widget.product == null) {
                  setState(() {
                    final idx = _variants.indexWhere(
                      (v) => v['id'] == variant['id'],
                    );
                    if (idx != -1) {
                      _variants[idx] = {
                        ..._variants[idx],
                        'name': data['name'],
                        'nameAr': data['nameAr'],
                        'basePrice': data['basePrice'],
                        'stock': data['stock'],
                        'sku': data['sku'],
                      };
                    }
                  });
                  success = true;
                } else {
                  try { await ref
                      .read(adminVendorsRepositoryProvider)
                      .updateVariant(
                        widget.vendorId,
                        widget.product['id'],
                        variant['id'],
                        UpdateProductVariantDto((b) {
                          b.name = data['name'] as String;
                          b.nameAr = data['nameAr'] as String;
                          b.basePrice = data['basePrice'] as num;
                          b.stock = data['stock'] as num?;
                          if (data['sku'] != null && (data['sku'] as String).isNotEmpty) b.sku = data['sku'] as String;
                        }),
                      ); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
                }
              }
              if (!context.mounted) return;
              Navigator.pop(context, success);
            },
            child: Text(
              variant == null
                  ? AppLocalizations.of(context)!.add
                  : AppLocalizations.of(context)!.save,
            ),
          ),
        ],
      ),
    );

    if (result == true && widget.product != null) _fetchProductDetails();
    if (result != null && mounted) {
      _showNotice(
        result
            ? (variant == null
                ? AppLocalizations.of(context)!.variantAdded
                : AppLocalizations.of(context)!.variantUpdated)
            : AppLocalizations.of(context)!.variantActionFailed,
        isError: !result,
      );
    }
  }

  void _deleteVariant(String variantId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteVariant),
        content: Text(AppLocalizations.of(context)!.deleteConfirmVariant),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = false;
      if (widget.product == null) {
        setState(() {
          _variants.removeWhere((v) => v['id'] == variantId);
        });
        success = true;
      } else {
        try { await ref
            .read(adminVendorsRepositoryProvider)
            .deleteVariant(widget.vendorId, widget.product['id'], variantId); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
      }
      if (success && widget.product != null) _fetchProductDetails();
      if (mounted) {
        _showNotice(
          success
              ? AppLocalizations.of(context)!.variantDeleted
              : AppLocalizations.of(context)!.variantActionFailed,
          isError: !success,
        );
      }
    }
  }

  void _showAddOptionGroupDialog({dynamic group}) async {
    final nameController = TextEditingController(text: group?['name'] ?? '');
    final nameArController = TextEditingController(
      text: group?['nameAr'] ?? '',
    );
    final minController = TextEditingController(
      text: group?['minSelect']?.toString() ?? '0',
    );
    final maxController = TextEditingController(
      text: group?['maxSelect']?.toString() ?? '1',
    );
    bool isRequired = group?['isRequired'] ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            group == null
                ? AppLocalizations.of(context)!.addOptionGroup
                : AppLocalizations.of(context)!.editOptionGroup,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: AppLocalizations.of(context)!.groupNameEn,
                  hint: 'e.g. Extras',
                  icon: LucideIcons.type,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: nameArController,
                  label: AppLocalizations.of(context)!.groupNameAr,
                  hint: 'مثال: إضافات',
                  icon: LucideIcons.languages,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: minController,
                        label: AppLocalizations.of(context)!.min,
                        hint: '0',
                        icon: LucideIcons.minus,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: maxController,
                        label: AppLocalizations.of(context)!.max,
                        hint: '1',
                        icon: LucideIcons.plus,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.isRequired),
                  value: isRequired,
                  onChanged: (v) => setState(() => isRequired = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'nameAr': nameArController.text,
                  'minSelect': int.tryParse(minController.text) ?? 0,
                  'maxSelect': int.tryParse(maxController.text) ?? 1,
                  'isRequired': isRequired,
                };
                bool success = false;
                if (group == null) {
                  if (widget.product == null) {
                    setState(() {
                      _optionGroups.add({
                        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                        'name': data['name'],
                        'nameAr': data['nameAr'],
                        'minSelect': data['minSelect'],
                        'maxSelect': data['maxSelect'],
                        'isRequired': data['isRequired'],
                        'options': [],
                      });
                    });
                    success = true;
                  } else {
                    try { await ref
                        .read(adminVendorsRepositoryProvider)
                        .addOptionGroup(
                          widget.vendorId,
                          widget.product['id'],
                          CreateOptionGroupDto((b) {
                            b.name = data['name'] as String;
                            b.nameAr = data['nameAr'] as String;
                            b.minSelect = data['minSelect'] as num;
                            b.maxSelect = data['maxSelect'] as num;
                            b.isRequired = data['isRequired'] as bool;
                          }),
                        ); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
                  }
                } else {
                  if (widget.product == null) {
                    setState(() {
                      final idx = _optionGroups.indexWhere(
                        (g) => g['id'] == group['id'],
                      );
                      if (idx != -1) {
                        _optionGroups[idx] = {
                          ..._optionGroups[idx],
                          'name': data['name'],
                          'nameAr': data['nameAr'],
                          'minSelect': data['minSelect'],
                          'maxSelect': data['maxSelect'],
                          'isRequired': data['isRequired'],
                        };
                      }
                    });
                    success = true;
                  } else {
                    try { await ref
                        .read(adminVendorsRepositoryProvider)
                        .updateOptionGroup(
                          widget.vendorId,
                          widget.product['id'],
                          group['id'],
                          UpdateOptionGroupDto((b) {
                            b.name = data['name'] as String;
                            b.nameAr = data['nameAr'] as String;
                            b.minSelect = data['minSelect'] as num;
                            b.maxSelect = data['maxSelect'] as num;
                            b.isRequired = data['isRequired'] as bool;
                          }),
                        ); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
                  }
                }
                if (!context.mounted) return;
                Navigator.pop(context, success);
              },
              child: Text(
                group == null
                    ? AppLocalizations.of(context)!.add
                    : AppLocalizations.of(context)!.save,
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && widget.product != null) _fetchProductDetails();
    if (result != null && mounted) {
      _showNotice(
        result
            ? (group == null
                ? AppLocalizations.of(context)!.optionGroupAdded
                : AppLocalizations.of(context)!.optionGroupUpdated)
            : AppLocalizations.of(context)!.optionGroupActionFailed,
        isError: !result,
      );
    }
  }

  void _deleteOptionGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteOptionGroup),
        content: Text(AppLocalizations.of(context)!.deleteConfirmOptionGroup),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = false;
      if (widget.product == null) {
        setState(() {
          _optionGroups.removeWhere((g) => g['id'] == groupId);
        });
        success = true;
      } else {
        try { await ref
            .read(adminVendorsRepositoryProvider)
            .deleteOptionGroup(widget.vendorId, widget.product['id'], groupId); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
      }
      if (success && widget.product != null) _fetchProductDetails();
      if (mounted) {
        _showNotice(
          success
              ? AppLocalizations.of(context)!.optionGroupDeleted
              : AppLocalizations.of(context)!.optionGroupActionFailed,
          isError: !success,
        );
      }
    }
  }

  void _showAddOptionDialog(String groupId, {dynamic option}) async {
    final nameController = TextEditingController(text: option?['name'] ?? '');
    final nameArController = TextEditingController(
      text: option?['nameAr'] ?? '',
    );
    final priceController = TextEditingController(
      text: option?['priceAdded']?.toString() ?? '0',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          option == null
              ? AppLocalizations.of(context)!.addOption
              : AppLocalizations.of(context)!.editOption,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: nameController,
                label: AppLocalizations.of(context)!.optionNameEn,
                hint: 'e.g. Cheese',
                icon: LucideIcons.type,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: nameArController,
                label: AppLocalizations.of(context)!.optionNameAr,
                hint: 'مثال: جبنة',
                icon: LucideIcons.languages,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: priceController,
                label: AppLocalizations.of(context)!.additionalPrice,
                hint: '0.00',
                icon: LucideIcons.dollarSign,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameController.text,
                'nameAr': nameArController.text,
                'priceAdded': double.tryParse(priceController.text) ?? 0.0,
              };
              bool success = false;
              if (option == null) {
                if (widget.product == null) {
                  setState(() {
                    final idx = _optionGroups.indexWhere(
                      (g) => g['id'] == groupId,
                    );
                    if (idx != -1) {
                      final options = List<dynamic>.from(
                        _optionGroups[idx]['options'] ?? [],
                      );
                      options.add({
                        'id':
                            'temp_opt_${DateTime.now().millisecondsSinceEpoch}',
                        'name': data['name'],
                        'nameAr': data['nameAr'],
                        'priceAdded': data['priceAdded'],
                      });
                      _optionGroups[idx]['options'] = options;
                    }
                  });
                  success = true;
                } else {
                  try { await ref
                      .read(adminVendorsRepositoryProvider)
                      .addOption(
                        widget.vendorId,
                        widget.product['id'],
                        groupId,
                        CreateProductOptionDto((b) {
                          b.name = data['name'] as String;
                          b.nameAr = data['nameAr'] as String;
                          b.priceAdded = data['priceAdded'] as num;
                        }),
                      ); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
                }
              } else {
                if (widget.product == null) {
                  setState(() {
                    final idx = _optionGroups.indexWhere(
                      (g) => g['id'] == groupId,
                    );
                    if (idx != -1) {
                      final options = List<dynamic>.from(
                        _optionGroups[idx]['options'] ?? [],
                      );
                      final optIdx = options.indexWhere(
                        (o) => o['id'] == option['id'],
                      );
                      if (optIdx != -1) {
                        options[optIdx] = {
                          ...options[optIdx],
                          'name': data['name'],
                          'nameAr': data['nameAr'],
                          'priceAdded': data['priceAdded'],
                        };
                      }
                      _optionGroups[idx]['options'] = options;
                    }
                  });
                  success = true;
                } else {
                  try { await ref
                      .read(adminVendorsRepositoryProvider)
                      .updateOption(
                        widget.vendorId,
                        widget.product['id'],
                        groupId,
                        option['id'],
                        UpdateProductOptionDto((b) {
                          b.name = data['name'] as String;
                          b.nameAr = data['nameAr'] as String;
                          b.priceAdded = data['priceAdded'] as num;
                        }),
                      ); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
                }
              }
              if (!context.mounted) return;
              Navigator.pop(context, success);
            },
            child: Text(
              option == null
                  ? AppLocalizations.of(context)!.add
                  : AppLocalizations.of(context)!.save,
            ),
          ),
        ],
      ),
    );

    if (result == true && widget.product != null) _fetchProductDetails();
    if (result != null && mounted) {
      _showNotice(
        result
            ? (option == null
                ? AppLocalizations.of(context)!.optionAdded
                : AppLocalizations.of(context)!.optionUpdated)
            : AppLocalizations.of(context)!.optionActionFailed,
        isError: !result,
      );
    }
  }

  void _deleteOption(String groupId, String optionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteOption),
        content: Text(AppLocalizations.of(context)!.deleteConfirmOption),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = false;
      if (widget.product == null) {
        setState(() {
          final idx = _optionGroups.indexWhere((g) => g['id'] == groupId);
          if (idx != -1) {
            final options = List<dynamic>.from(
              _optionGroups[idx]['options'] ?? [],
            );
            options.removeWhere((o) => o['id'] == optionId);
            _optionGroups[idx]['options'] = options;
          }
        });
        success = true;
      } else {
        try { await ref
            .read(adminVendorsRepositoryProvider)
            .deleteOption(
              widget.vendorId,
              widget.product['id'],
              groupId,
              optionId,
            ); success = true; } catch (e) { success = false; debugPrint(e.toString()); }
      }
      if (success && widget.product != null) _fetchProductDetails();
      if (mounted) {
        _showNotice(
          success
              ? AppLocalizations.of(context)!.optionDeleted
              : AppLocalizations.of(context)!.optionActionFailed,
          isError: !success,
        );
      }
    }
  }

  Widget _buildImagePicker() {
    final hasImage = _imageFile != null || widget.product?['imageUrl'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (imgCtx) => Stack(
            children: [
              GestureDetector(
                onTap: () => _pickImage(),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_imageFile!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.product?['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _formatImageUrl(widget.product!['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.image,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.uploadProductImage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.imageFormatSupport,
                            style: const TextStyle(
                              
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (hasImage)
              PositionedDirectional(
                end: 12,
                top: 12,
                child: Row(
                  children: [
                    _buildImageActionButton(
                      icon: LucideIcons.camera,
                      onTap: () => _pickImage(),
                      tooltip: AppLocalizations.of(context)!.changeImage,
                    ),
                    const SizedBox(width: 8),
                    _buildImageActionButton(
                      icon: LucideIcons.trash2,
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                          if (widget.product != null) {
                            widget.product['imageUrl'] = null;
                          }
                        });
                      },
                      color: AppColors.error,
                      tooltip: AppLocalizations.of(context)!.removeImage,
                    ),
                  ],
                ),
              ),
          ],
        ),
        ),
      ],
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    String? tooltip,
  }) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: color ?? Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: value ? AppColors.primary : AppColors.textMuted,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  void _submit() {
    // The Form with the validators lives inside the General tab, which
    // TabBarView disposes when another tab is visible, making
    // `_formKey.currentState` null. So also check the truly-required fields
    // directly and treat a missing FormState as "no field errors".
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasPrice = _priceController.text.trim().isNotEmpty;
    final formValid = _formKey.currentState?.validate() ?? true;
    if (!hasName || !hasPrice || !formValid) {
      _showNotice(
        AppLocalizations.of(context)!.pleaseFillRequiredFields,
        isError: true,
      );
      return;
    }

    Navigator.pop(context, {
      'vendorId': widget.vendorId,
      'productId': widget.product?['id'],
      'categoryId': _selectedCategoryId,
      'name': _nameController.text,
      'nameAr': _nameArController.text,
      'description': _descriptionController.text,
      'descriptionAr': _descriptionArController.text,
      'basePrice': double.tryParse(_priceController.text),
      'comparePrice': double.tryParse(_comparePriceController.text),
      'sku': _skuController.text,
      'stock': double.tryParse(_stockController.text),
      'isActive': _isActive,
      'isFeatured': _isFeatured,
      'sellByStrip': _sellByStrip,
      'stripsPerPackage': int.tryParse(_stripsCountController.text),
      'imageFile': _imageFile,
      'hasVariants': _variants.isNotEmpty,
      'variants': _variants,
      'optionGroups': _optionGroups,
    });
  }

  void _showNotice(String message, {bool isError = false}) {
    if (!mounted) return;
    _noticeTimer?.cancel();
    setState(() {
      _noticeMessage = message;
      _noticeIsError = isError;
    });
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _noticeMessage = null);
    });
  }

  String _formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://api.otlob-egy.online$url';
  }
}

