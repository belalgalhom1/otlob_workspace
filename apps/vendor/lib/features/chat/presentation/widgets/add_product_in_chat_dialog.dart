import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
  Uint8List? _imageFileBytes;
  String? _existingImageUrl;
  bool _isPickingImage = false;
  String? _validationError;

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
          _products = List<dynamic>.from(
            (results[1] as Map?)?['products'] ??
                (results[1] as Map?)?['items'] ??
                const [],
          );
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
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        XFile? finalImage;
        try {
          final cropped = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            compressQuality: 85,
            maxWidth: 1080,
            maxHeight: 1080,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Product Photo',
                toolbarColor: const Color(0xFFD4920E),
                toolbarWidgetColor: Colors.white,
                activeControlsWidgetColor: const Color(0xFFD4920E),
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: 'Crop Product Photo',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
              ),
            ],
          );
          if (cropped == null) {
            return;
          }
          finalImage = XFile(cropped.path);
        } catch (cropErr) {
          debugPrint('ImageCropper failed or not available, using original image: $cropErr');
          finalImage = image;
        }

        final bytes = await finalImage.readAsBytes();
        if (mounted) {
          setState(() {
            _imageFile = finalImage;
            _imageFileBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking product image: $e');
      MediaPermissionHelper.handlePickerError(
        e,
        context: mounted ? context : null,
      );
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
      _validationError = null;
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
    final l10n = AppLocalizations.of(context)!;

    return AppDialog(
      maxWidth: 580,
      header: AppDialogHeader(
        icon: LucideIcons.shoppingCart,
        title: l10n.createOrderOffer,
        subtitle: l10n.vendor(widget.vendorName),
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_validationError != null) ...[
              AppDialogErrorBanner(message: _validationError!),
              const SizedBox(height: 16),
            ],
            _buildSectionHeader(
              LucideIcons.search,
              l10n.searchExistingProduct,
            ),
            const SizedBox(height: 10),
            _buildProductAutocomplete(),
            const SizedBox(height: 18),

            // Category Selection
            _buildCategoryDropdown(),
            const SizedBox(height: 20),

            _buildSectionHeader(
              LucideIcons.image,
              l10n.productImage,
            ),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 22),

            _buildSectionHeader(
              LucideIcons.info,
              l10n.basicInfo,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: l10n.productNameEn,
              languageTag: 'EN',
              isRequired: true,
              hint: 'e.g. Classic Cheeseburger',
              icon: LucideIcons.type,
              textDirection: TextDirection.ltr,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameArController,
              label: l10n.productNameAr,
              languageTag: 'عربي',
              languageTagColor: AppColors.info,
              isRequired: true,
              hint: 'مثال: تشيز برجر كلاسيك',
              icon: LucideIcons.languages,
              textDirection: TextDirection.rtl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: l10n.descriptionEn,
              languageTag: 'EN',
              hint: l10n.detailedProductDescription,
              icon: LucideIcons.alignLeft,
              maxLines: 3,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionArController,
              label: l10n.descriptionAr,
              languageTag: 'عربي',
              languageTagColor: AppColors.info,
              hint: 'وصف المنتج بالتفصيل...',
              icon: LucideIcons.alignRight,
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 22),
            _buildSectionHeader(
              LucideIcons.dollarSign,
              l10n.pricingInventory,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: l10n.basePrice,
                    isRequired: true,
                    hint: '0.00',
                    icon: LucideIcons.dollarSign,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.fieldRequired
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _comparePriceController,
                    label: l10n.comparePrice,
                    hint: '0.00',
                    icon: LucideIcons.tag,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _skuController,
                    label: l10n.sku,
                    hint: l10n.stockUnit,
                    icon: LucideIcons.shoppingBag,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _stockController,
                    label: l10n.initialStock,
                    hint: '0',
                    icon: LucideIcons.box,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            _buildSectionHeader(
              LucideIcons.settings2,
              l10n.settings,
            ),
            const SizedBox(height: 12),
            AppDialogSectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: l10n.productActiveStatus,
                    subtitle: l10n.productVisibleToCustomers,
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    icon: LucideIcons.eye,
                  ),
                  Divider(
                    color: AppDialogStyles.borderColor(context),
                    height: 1,
                    indent: 48,
                  ),
                  _buildSwitchTile(
                    title: l10n.featuredProduct,
                    subtitle: l10n.showAtTopOfMenu,
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                    icon: LucideIcons.star,
                  ),
                  Divider(
                    color: AppDialogStyles.borderColor(context),
                    height: 1,
                    indent: 48,
                  ),
                  _buildSwitchTile(
                    title: l10n.pushToMenu,
                    subtitle: l10n.pushToMenuSubtitle,
                    value: _pushToMenu,
                    onChanged: (v) => setState(() => _pushToMenu = v),
                    icon: LucideIcons.listPlus,
                  ),
                  Divider(
                    color: AppDialogStyles.borderColor(context),
                    height: 1,
                    indent: 48,
                  ),
                  _buildSwitchTile(
                    title: l10n.createPendingOrderImmediately,
                    subtitle: l10n.createPendingOrderSubtitle,
                    value: _createPendingOrder,
                    onChanged: (v) => setState(() => _createPendingOrder = v),
                    icon: LucideIcons.zap,
                    activeColor: AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: l10n.sendOffer,
        confirmIcon: LucideIcons.send,
        onConfirm: _submit,
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProductAutocomplete() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
          decoration: AppDialogStyles.inputDecoration(
            context,
            hintText: l10n.searchVendorCatalog,
            icon: LucideIcons.search,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: AppDialogStyles.dropdownColor(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppDialogStyles.borderColor(context)),
              ),
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      BilingualHelper.getLocalizedText(
                        context,
                        enText: option['name'],
                        arText: option['nameAr'],
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${option['basePrice']} ${l10n.egp}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: l10n.menuCategory, isRequired: true),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          hint: Text(
            _isLoadingData ? l10n.loadingCategories : l10n.selectMenuCategory,
            style: TextStyle(
              fontSize: 13.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          isExpanded: true,
          dropdownColor: AppDialogStyles.dropdownColor(context),
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
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
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
          validator: (v) => v == null ? l10n.pleaseSelectCategory : null,
          decoration: AppDialogStyles.inputDecoration(
            context,
            icon: LucideIcons.list,
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
    TextDirection? textDirection,
    bool isRequired = false,
    String? languageTag,
    Color? languageTagColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(
          label: label,
          isRequired: isRequired,
          languageTag: languageTag,
          languageTagColor: languageTagColor,
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          textDirection: textDirection,
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
          decoration: AppDialogStyles.inputDecoration(
            context,
            hintText: hint,
            icon: icon,
            isMultiline: maxLines > 1,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasImage =
        _imageFile != null ||
        (_existingImageUrl != null && _existingImageUrl!.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppDialogStyles.subtleSurfaceColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppDialogStyles.borderColor(context),
                    width: 1.2,
                  ),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _imageFileBytes != null
                            ? Image.memory(
                                _imageFileBytes!,
                                fit: BoxFit.cover,
                              )
                            : kIsWeb
                                ? Image.network(
                                    _imageFile!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_imageFile!.path),
                                    fit: BoxFit.cover,
                                  ),
                      )
                    : (_existingImageUrl != null &&
                            _existingImageUrl!.trim().isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.network(
                              ImageUtils.formatImageUrl(_existingImageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(
                                  LucideIcons.imageOff,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.image,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.uploadProductImage,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.optionalForChatOffers,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            if (hasImage)
              PositionedDirectional(
                end: 10,
                top: 10,
                child: Row(
                  children: [
                    _buildImageActionButton(
                      icon: LucideIcons.camera,
                      onTap: _pickImage,
                      tooltip: l10n.changeImage,
                    ),
                    const SizedBox(width: 8),
                    _buildImageActionButton(
                      icon: LucideIcons.trash2,
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                          _imageFileBytes = null;
                          _existingImageUrl = null;
                        });
                      },
                      color: AppColors.error,
                      tooltip: l10n.removeImage,
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
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: color ?? Colors.white,
              size: 18,
            ),
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
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: value
            ? (activeColor ?? AppColors.primary)
            : theme.colorScheme.onSurfaceVariant,
        size: 19,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
      setState(() => _validationError = null);
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
        'sku': _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        'stock': double.tryParse(_stockController.text),
        'isActive': _isActive,
        'isFeatured': _isFeatured,
        'pushToMenu': _pushToMenu,
        'createPendingOrder': _createPendingOrder, // Returns toggle state
        'imageFile': _imageFile,
        'imageUrl': _existingImageUrl,
      });
    } else {
      setState(() {
        _validationError = AppLocalizations.of(context)!.pleaseFillRequiredFields;
      });
    }
  }
}

