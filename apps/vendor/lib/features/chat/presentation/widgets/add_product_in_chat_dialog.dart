import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';

class AddProductInChatDialog extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;

  const AddProductInChatDialog({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  ConsumerState<AddProductInChatDialog> createState() =>
      _AddProductInChatDialogState();
}

class _AddProductInChatDialogState
    extends ConsumerState<AddProductInChatDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionArController;
  late TextEditingController _priceController;
  late TextEditingController _comparePriceController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;

  bool _isActive = true;
  bool _isFeatured = false;
  bool _pushToMenu = false;
  bool _createPendingOrder = false;


  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  String? _selectedCategoryId;
  String? _selectedProductId;
  bool _isLoadingData = true;
  XFile? _imageFile;
  String? _existingImageUrl;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameArController = TextEditingController();
    _descriptionController = TextEditingController();
    _descriptionArController = TextEditingController();
    _priceController = TextEditingController();
    _comparePriceController = TextEditingController();
    _skuController = TextEditingController();
    _stockController = TextEditingController();

    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final repo = ref.read(adminVendorsRepositoryProvider);
      final categoriesFuture = repo.getMenuCategories(widget.vendorId);
      final productsFuture = repo.getProducts(widget.vendorId);

      final results = await Future.wait([categoriesFuture, productsFuture]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<dynamic>;
          _products = (results[1] as dynamic)['items'];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
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
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _onProductSelected(dynamic product) {
    setState(() {
      _selectedProductId = product['id']?.toString();
      _selectedCategoryId =
          product['categoryId']?.toString() ?? _selectedCategoryId;
      _nameController.text = product['name'] ?? '';
      _nameArController.text = product['nameAr'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _descriptionArController.text = product['descriptionAr'] ?? '';
      _priceController.text = product['basePrice']?.toString() ?? '';
      _comparePriceController.text = product['comparePrice']?.toString() ?? '';
      _skuController.text = product['sku'] ?? '';
      _stockController.text = product['stock']?.toString() ?? '';
      _isActive = product['isActive'] ?? true;
      _isFeatured = product['isFeatured'] ?? false;
      _pushToMenu = false; // Existing product, no need to push
      _existingImageUrl = product['imageUrl'] ?? product['image'];
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
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
                        LucideIcons.shoppingCart,
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
                            AppLocalizations.of(context)!.createOrderOffer,
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

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 20 : 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          AppLocalizations.of(context)!.searchExistingProduct,
                        ),
                        const SizedBox(height: 12),
                        _buildProductAutocomplete(),
                        const SizedBox(height: 24),

                        // Category Selection
                        _buildCategoryDropdown(),
                        const SizedBox(height: 24),

                        _buildSectionHeader(
                          AppLocalizations.of(context)!.productImage,
                        ),
                        const SizedBox(height: 12),
                        _buildImagePicker(),
                        const SizedBox(height: 24),

                        _buildSectionHeader(
                          AppLocalizations.of(context)!.basicInfo,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _nameController,
                          label:
                              AppLocalizations.of(context)!.productNameEn,
                          hint: 'e.g. Classic Cheeseburger',
                          icon: LucideIcons.type,
                          validator: (v) => v?.isEmpty ?? true
                              ? AppLocalizations.of(context)!.fieldRequired
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameArController,
                          label:
                              AppLocalizations.of(context)!.productNameAr,
                          hint: 'مثال: تشيز برجر كلاسيك',
                          icon: LucideIcons.languages,
                          textAlign: TextAlign.right,
                          validator: (v) => v?.isEmpty ?? true
                              ? AppLocalizations.of(context)!.fieldRequired
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label:
                              AppLocalizations.of(context)!.descriptionEn,
                          hint: AppLocalizations.of(context)!.detailedProductDescription,
                          icon: LucideIcons.alignLeft,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionArController,
                          label:
                              AppLocalizations.of(context)!.descriptionAr,
                          hint: 'وصف المنتج بالتفصيل...',
                          icon: LucideIcons.alignRight,
                          maxLines: 3,
                          textAlign: TextAlign.right,
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          AppLocalizations.of(context)!.pricingInventory,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label:
                                    AppLocalizations.of(context)!.basePrice,
                                hint: '0.00',
                                icon: LucideIcons.dollarSign,
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.isEmpty ?? true
                                    ? AppLocalizations.of(
                                        context,
                                      )!.fieldRequired
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _comparePriceController,
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )!.comparePrice,
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
                                label:
                                    AppLocalizations.of(context)!.sku,
                                hint: AppLocalizations.of(context)!.stockUnit,
                                icon: LucideIcons.shoppingBag,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _stockController,
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )!.initialStock,
                                hint: '0',
                                icon: LucideIcons.box,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          AppLocalizations.of(context)!.settings,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildSwitchTile(
                                title:
                                    AppLocalizations.of(
                                      context,
                                    )!.productActiveStatus,
                                subtitle:
                                    AppLocalizations.of(
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
                                title:
                                    AppLocalizations.of(
                                      context,
                                    )!.featuredProduct,
                                subtitle:
                                    AppLocalizations.of(
                                      context,
                                    )!.showAtTopOfMenu,
                                value: _isFeatured,
                                onChanged: (v) =>
                                    setState(() => _isFeatured = v),
                                icon: LucideIcons.star,
                              ),
                              Divider(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                height: 1,
                                indent: 48,
                              ),
                              _buildSwitchTile(
                                title:
                                    AppLocalizations.of(context)!.pushToMenu,
                                subtitle:
                                    AppLocalizations.of(
                                      context,
                                    )!.pushToMenuSubtitle,
                                value: _pushToMenu,
                                onChanged: (v) =>
                                    setState(() => _pushToMenu = v),
                                icon: LucideIcons.listPlus,
                              ),
                              Divider(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                height: 1,
                                indent: 48,
                              ),
                              _buildSwitchTile(
                                title: AppLocalizations.of(context)!.createPendingOrderImmediately,
                                subtitle:
                                    AppLocalizations.of(context)!.createPendingOrderSubtitle,
                                value: _createPendingOrder,
                                onChanged: (v) =>
                                    setState(() => _createPendingOrder = v),
                                icon: LucideIcons.zap,
                                activeColor: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                              AppLocalizations.of(context)!.sendOffer,
                            ),
                    ),
                  ],
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

  Widget _buildProductAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (option) => BilingualHelper.getLocalizedText(
        context,
        enText: option['name'],
        arText: option['nameAr'],
      ),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return _products.cast<Map<String, dynamic>>().where((product) {
          final enName = product['name']?.toString().toLowerCase() ?? '';
          final arName = product['nameAr']?.toString().toLowerCase() ?? '';
          final query = textEditingValue.text.toLowerCase();
          return enName.contains(query) || arName.contains(query);
        });
      },
      onSelected: _onProductSelected,
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchVendorCatalog,
            prefixIcon: const Icon(
              LucideIcons.search,
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
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      BilingualHelper.getLocalizedText(
                        context,
                        enText: option['name'],
                        arText: option['nameAr'],
                      ),
                    ),
                    subtitle: Text('${option['basePrice']} EGP'),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
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
            _isLoadingData
                ? (AppLocalizations.of(context)!.loadingCategories)
                : (AppLocalizations.of(context)!.selectMenuCategory),
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
              child: Text(
                BilingualHelper.getLocalizedText(
                  context,
                  enText: cat['name'],
                  arText: cat['nameAr'],
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
          validator: (v) => v == null
              ? AppLocalizations.of(context)!.pleaseSelectCategory
              : null,
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
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _imageFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _pickImage,
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
                            AppLocalizations.of(context)!.optionalForChatOffers,
                            style: TextStyle(
                              
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
                      onTap: _pickImage,
                      tooltip:
                          AppLocalizations.of(context)!.changeImage,
                    ),
                    const SizedBox(width: 8),
                    _buildImageActionButton(
                      icon: LucideIcons.trash2,
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      color: AppColors.error,
                      tooltip:
                          AppLocalizations.of(context)!.removeImage,
                    ),
                  ],
                ),
              ),
          ],
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
      color: Colors.black.withValues(alpha: 0.5),
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
    Color? activeColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: value ? (activeColor ?? AppColors.primary) : AppColors.textMuted,
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
        activeThumbColor: activeColor ?? AppColors.primary,
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, {
        'vendorId': widget.vendorId,
        'categoryId': _selectedCategoryId,
        'productId':
            _selectedProductId, // Passes the selected product ID if any
        'name': _nameController.text,
        'nameAr': _nameArController.text,
        'description': _descriptionController.text,
        'descriptionAr': _descriptionArController.text,
        'basePrice': double.tryParse(_priceController.text),
        'comparePrice': double.tryParse(_comparePriceController.text),
        'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        'stock': double.tryParse(_stockController.text),
        'isActive': _isActive,
        'isFeatured': _isFeatured,
        'pushToMenu': _pushToMenu,
        'createPendingOrder': _createPendingOrder, // Returns toggle state
        'imageFile': _imageFile,
        'imageUrl': _existingImageUrl,
      });
    }
  }
}

