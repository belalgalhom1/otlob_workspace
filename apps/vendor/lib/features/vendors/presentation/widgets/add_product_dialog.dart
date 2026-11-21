import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
  late bool _tracksStock;
  final bool _isLoading = false;

  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;
  List<dynamic> _branches = [];
  bool _isLoadingBranches = true;
  String _branchAvailabilityMode = 'ALL';
  final Set<String> _selectedBranchIds = {};
  XFile? _imageFile;
  Uint8List? _imageFileBytes;
  bool _isPickingImage = false;

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
    _tracksStock = p?['tracksStock'] ?? true;
    _stripsCountController = TextEditingController(
      text: p?['stripsPerPackage']?.toString() ?? '',
    );
    _stripPriceController = TextEditingController();
    _selectedCategoryId = p?['categoryId']?.toString();
    _branchAvailabilityMode =
        (p?['branchAvailabilityMode'] ?? 'ALL').toString();
    _selectedBranchIds.addAll(_branchIdsFromProduct(p));

    _updateStripPrice();
    _priceController.addListener(_updateStripPrice);
    _stripsCountController.addListener(_updateStripPrice);

    _fetchCategories();
    _fetchBranches();
    if (isEdit) {
      _fetchProductDetails();
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
          final detailMode = product['branchAvailabilityMode']?.toString();
          if (detailMode == 'ALL' || detailMode == 'SPECIFIC') {
            _branchAvailabilityMode = detailMode!;
          }
          final detailBranchIds = _branchIdsFromProduct(product);
          if (detailBranchIds.isNotEmpty || detailMode == 'ALL') {
            _selectedBranchIds
              ..clear()
              ..addAll(detailBranchIds);
          }
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  List<String> _branchIdsFromProduct(dynamic product) {
    final direct = product?['branchIds'];
    if (direct is List) {
      return direct
          .map((id) => id?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
    }

    final rows = product?['branchAvailability'];
    if (rows is! List) return const [];
    return rows
        .map((row) {
          if (row is String) return row;
          if (row is Map) {
            final directId = row['branchId'];
            if (directId != null) return directId.toString();
            final branch = row['branch'];
            if (branch is Map && branch['id'] != null) {
              return branch['id'].toString();
            }
          }
          return null;
        })
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> _fetchBranches() async {
    try {
      final branches = await ref
          .read(adminVendorsRepositoryProvider)
          .getBranches(widget.vendorId);
      if (!mounted) return;
      final list = branches is List
          ? List<dynamic>.from(branches)
          : List<dynamic>.from(branches?['data'] as List? ?? const []);
      setState(() {
        _branches = list;
        _isLoadingBranches = false;
        final validIds = _branches
            .map((branch) => branch['id']?.toString())
            .whereType<String>()
            .toSet();
        _selectedBranchIds.removeWhere((id) => !validIds.contains(id));
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingBranches = false);
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

        if (finalImage == null) return;

        final bytes = await finalImage.readAsBytes();
        if (mounted) {
          setState(() {
            _imageFile = finalImage;
            _imageFileBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      if (MediaPermissionHelper.isAccessDeniedError(e)) {
        MediaPermissionHelper.handlePickerError(e, context: context);
      } else {
        _showNotice(
          AppLocalizations.of(context)!.failedToPickImage,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.product != null;
    final accentTextColor =
        isDark ? Colors.amber.shade300 : const Color(0xFFB45309);

    return AppDialog(
      maxWidth: 640,
      maxHeight: 780,
      scrollableBody: false,
      expandBody: true,
      bodyPadding: EdgeInsets.zero,
      header: AppDialogHeader(
        icon: isEdit ? LucideIcons.edit3 : LucideIcons.package,
        title: isEdit ? l10n.editProduct : l10n.addProduct,
        subtitle: l10n.vendor(widget.vendorName),
        onClose: () => Navigator.pop(context),
      ),
      body: DefaultTabController(
        length: 3,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppDialogStyles.subtleSurfaceColor(context),
                  child: TabBar(
                    tabs: [
                      Tab(text: l10n.general),
                      Tab(text: l10n.variants),
                      Tab(text: l10n.options),
                    ],
                    labelColor: isDark ? AppColors.primary : accentTextColor,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                    unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                    ),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    dividerColor: Colors.transparent,
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppDialogStyles.borderColor(context),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildGeneralTab(),
                      _buildVariantsTab(),
                      _buildOptionsTab(),
                    ],
                  ),
                ),
              ],
            ),
            if (_noticeMessage != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: IgnorePointer(
                  child: Material(
                    color: _noticeIsError ? AppColors.error : AppColors.success,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _noticeIsError
                                ? LucideIcons.alertCircle
                                : LucideIcons.checkCircle2,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _noticeMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: isEdit ? l10n.updateProduct : l10n.addProduct,
        confirmIcon: LucideIcons.check,
        isLoading: _isLoading,
        onConfirm: _isLoading ? null : _submit,
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

  Widget _buildCategoryDropdown() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: l10n.menuCategory),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          hint: Text(
            _isLoadingCategories
                ? l10n.loadingCategories
                : l10n.selectMenuCategory,
            style: theme.textTheme.bodyMedium?.copyWith(
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
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
          ),
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['id'].toString(),
              child: Text(
                cat['name'] ?? 'Unnamed',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
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
    bool readOnly = false,
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
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
            fontSize: 14,
          ),
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

  Widget _buildGeneralTab() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final horizontalPad = AppDialogStyles.isMobile(context) ? 16.0 : 24.0;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Selection
            _buildCategoryDropdown(),
            const SizedBox(height: 22),

            _buildSectionHeader(LucideIcons.image, l10n.productImage),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 22),

            _buildSectionHeader(LucideIcons.info, l10n.basicInfo),
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
              hint: 'مثال: تشيز برجر كلاسيك',
              icon: LucideIcons.languages,
              textDirection: TextDirection.rtl,
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
            _buildSectionHeader(LucideIcons.dollarSign, l10n.pricingInventory),
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

            const SizedBox(height: 16),
            AppDialogSectionCard(
              backgroundColor: AppColors.primary.withValues(alpha: 0.06),
              borderColor: AppColors.primary.withValues(alpha: 0.22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.layers,
                        size: 19,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.sellByStrip,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
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
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stripsCountController,
                            label: l10n.stripsPerPackage,
                            hint: '0',
                            icon: LucideIcons.hash,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            controller: _stripPriceController,
                            label: l10n.stripPrice,
                            hint: '0.00',
                            icon: LucideIcons.tag,
                            readOnly: true,
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),
            _buildSectionHeader(LucideIcons.settings2, l10n.settings),
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
                    title: l10n.trackStock,
                    subtitle: l10n.trackStockSubtitle,
                    value: _tracksStock,
                    onChanged: (v) => setState(() => _tracksStock = v),
                    icon: LucideIcons.boxes,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            _buildSectionHeader(
              LucideIcons.gitBranch,
              l10n.branchAvailability,
            ),
            const SizedBox(height: 12),
            _buildBranchAvailabilitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchAvailabilitySection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSpecific = _branchAvailabilityMode == 'SPECIFIC';
    final allSelected =
        _branches.isNotEmpty && _selectedBranchIds.length == _branches.length;

    return AppDialogSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: !isSpecific,
                onSelected: (_) =>
                    setState(() => _branchAvailabilityMode = 'ALL'),
                avatar: const Icon(LucideIcons.globe, size: 16),
                label: Text(l10n.allBranches),
              ),
              ChoiceChip(
                selected: isSpecific,
                onSelected: (_) =>
                    setState(() => _branchAvailabilityMode = 'SPECIFIC'),
                avatar: const Icon(LucideIcons.gitBranch, size: 16),
                label: Text(l10n.specificBranches),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingBranches)
            const LinearProgressIndicator(minHeight: 2)
          else if (!isSpecific)
            Text(
              l10n.allBranchesHint,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else if (_branches.isEmpty)
            Text(
              l10n.noBranchesAvailable,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: AppColors.error,
              ),
            )
          else ...[
            Text(
              l10n.specificBranchesHint,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedBranchIds.isEmpty
                        ? l10n.noBranchesSelected
                        : _selectedBranchIds.length == 1
                        ? l10n.oneBranchSelected
                        : l10n.branchesSelected(_selectedBranchIds.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (allSelected) {
                        _selectedBranchIds.clear();
                      } else {
                        _selectedBranchIds
                          ..clear()
                          ..addAll(
                            _branches
                                .map((branch) => branch['id']?.toString())
                                .whereType<String>()
                                .where((id) => id.isNotEmpty),
                          );
                      }
                    });
                  },
                  child: Text(
                    allSelected ? l10n.clearAll : l10n.selectAll,
                  ),
                ),
              ],
            ),
            ..._branches.map((branch) {
              final id = branch['id']?.toString() ?? '';
              final name =
                  branch['name']?.toString().trim().isNotEmpty == true
                  ? branch['name'].toString()
                  : l10n.unnamedBranch;
              final address = branch['address']?.toString();
              return CheckboxListTile(
                value: _selectedBranchIds.contains(id),
                onChanged: id.isEmpty
                    ? null
                    : (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedBranchIds.add(id);
                          } else {
                            _selectedBranchIds.remove(id);
                          }
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
                subtitle: address == null || address.isEmpty
                    ? null
                    : Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantsTab() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddVariantDialog(),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                l10n.addVariant,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _variants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.layers,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noVariantsYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _variants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    final hasCompare = variant['comparePrice'] != null &&
                        (variant['comparePrice'] as num) >
                            (variant['basePrice'] as num);
                    final stockText = variant['tracksStock'] == false
                        ? l10n.notTracked
                        : '${variant['stock'] ?? 0}';
                    return AppDialogSectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          variant['name'] ?? l10n.unknown,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          hasCompare
                              ? '${variant['basePrice']} ${l10n.egp} (${variant['comparePrice']}) • ${l10n.stock}: $stockText'
                              : '${variant['basePrice']} ${l10n.egp} • ${l10n.stock}: $stockText',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.edit2, size: 17),
                              onPressed: () =>
                                  _showAddVariantDialog(variant: variant),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 17,
                                color: AppColors.error,
                              ),
                              onPressed: () => _deleteVariant(variant['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOptionsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final accentTextColor =
        isDark ? AppColors.primary : const Color(0xFFB45309);
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddOptionGroupDialog(),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                l10n.addOptionGroup,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _optionGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.listChecks,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noOptionGroupsYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _optionGroups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final group = _optionGroups[index];
                    final options = group['options'] as List? ?? [];
                    return AppDialogSectionCard(
                      padding: EdgeInsets.zero,
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          group['name'] ?? l10n.unknown,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${options.length} ${l10n.options} • ${l10n.min}: ${group['minSelect']} • ${l10n.max}: ${group['maxSelect']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          Divider(
                            height: 1,
                            color: AppDialogStyles.borderColor(context),
                          ),
                          ...options.map(
                            (opt) => ListTile(
                              dense: true,
                              title: Text(opt['name'] ?? l10n.unknown),
                              subtitle: Text(
                                '+${opt['priceAdded']} ${l10n.egp}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.edit2, size: 15),
                                    onPressed: () => _showAddOptionDialog(
                                      group['id'],
                                      option: opt,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      size: 15,
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
                            dense: true,
                            onTap: () => _showAddOptionDialog(group['id']),
                            leading: Icon(
                              LucideIcons.plus,
                              size: 16,
                              color: accentTextColor,
                            ),
                            title: Text(
                              l10n.addOption,
                              style: TextStyle(
                                color: accentTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                                    l10n.editOptionGroup,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () =>
                                      _deleteOptionGroup(group['id']),
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  label: Text(
                                    l10n.deleteOptionGroup,
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddVariantDialog({dynamic variant}) async {
    var tracksStock = variant?['tracksStock'] ?? true;
    var isSaving = false;
    final nameController = TextEditingController(text: variant?['name'] ?? '');
    final nameArController = TextEditingController(
      text: variant?['nameAr'] ?? '',
    );
    final priceController = TextEditingController(
      text: variant?['basePrice']?.toString() ?? '',
    );
    final comparePriceController = TextEditingController(
      text: variant?['comparePrice']?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: variant?['stock']?.toString() ?? '',
    );
    final skuController = TextEditingController(text: variant?['sku'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final l10n = AppLocalizations.of(dialogCtx)!;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AppDialog(
            maxWidth: 520,
            canPop: !isSaving,
            header: AppDialogHeader(
              icon: LucideIcons.layers,
              title: variant == null ? l10n.addVariant : l10n.editVariant,
              isCloseDisabled: isSaving,
              onClose: () => Navigator.pop(dialogCtx),
            ),
            body: Form(
              key: _variantFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: l10n.nameEn,
                    languageTag: 'EN',
                    isRequired: true,
                    hint: 'e.g. Cheese Pizza, Tuna Pizza',
                    icon: LucideIcons.type,
                    textDirection: TextDirection.ltr,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: nameArController,
                    label: l10n.nameAr,
                    languageTag: 'عربي',
                    languageTagColor: AppColors.info,
                    hint: 'مثال: بيتزا جبنة، بيتزا تونة',
                    icon: LucideIcons.languages,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: priceController,
                          label: l10n.price,
                          isRequired: true,
                          hint: '0.00',
                          icon: LucideIcons.dollarSign,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          validator: (v) {
                            final p = double.tryParse(v ?? '');
                            if (p == null || p <= 0) {
                              return l10n.fieldRequired;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: comparePriceController,
                          label: l10n.comparePrice,
                          hint: '0.00',
                          icon: LucideIcons.tag,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: stockController,
                          label: l10n.stock,
                          hint: '0',
                          icon: LucideIcons.box,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: skuController,
                          label: l10n.sku,
                          hint: l10n.optional,
                          icon: LucideIcons.hash,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppDialogSectionCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: _buildSwitchTile(
                      title: l10n.trackStock,
                      subtitle: l10n.trackStockSubtitle,
                      value: tracksStock,
                      onChanged: (v) => setDialogState(() => tracksStock = v),
                      icon: LucideIcons.boxes,
                    ),
                  ),
                ],
              ),
            ),
            footer: AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.pop(dialogCtx),
              confirmLabel: variant == null ? l10n.add : l10n.save,
              confirmIcon:
                  variant == null ? LucideIcons.plus : LucideIcons.check,
              isLoading: isSaving,
              onConfirm: isSaving
                  ? null
                  : () async {
                      if (!(_variantFormKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final comparePriceVal =
                          comparePriceController.text.trim().isNotEmpty
                              ? double.tryParse(
                                  comparePriceController.text.trim(),
                                )
                              : null;
                      final data = {
                        'name': nameController.text,
                        'nameAr': nameArController.text,
                        'basePrice':
                            double.tryParse(priceController.text) ?? 0.0,
                        'comparePrice': comparePriceVal,
                        'stock': int.tryParse(stockController.text),
                        'sku': skuController.text.trim().isEmpty
                            ? null
                            : skuController.text.trim(),
                        'tracksStock': tracksStock,
                      };
                      bool success = false;
                      if (variant == null) {
                        if (widget.product == null) {
                          setState(() {
                            _variants.add({
                              'id':
                                  'temp_${DateTime.now().millisecondsSinceEpoch}',
                              'name': data['name'],
                              'nameAr': data['nameAr'],
                              'basePrice': data['basePrice'],
                              'comparePrice': data['comparePrice'],
                              'stock': data['stock'],
                              'sku': data['sku'],
                              'tracksStock': data['tracksStock'],
                              'optionGroups': [],
                            });
                          });
                          success = true;
                        } else {
                          try {
                            await ref
                                .read(adminVendorsRepositoryProvider)
                                .addVariant(
                                  widget.vendorId,
                                  widget.product['id'],
                                  CreateProductVariantDto((b) {
                                    b.name = data['name'] as String;
                                    b.nameAr = data['nameAr'] as String;
                                    b.basePrice = data['basePrice'] as num;
                                    if (data['comparePrice'] != null) {
                                      b.comparePrice =
                                          data['comparePrice'] as num;
                                    }
                                    b.stock = data['stock'] as num?;
                                    if (data['tracksStock'] != null) {
                                      b.tracksStock =
                                          data['tracksStock'] as bool;
                                    }
                                    if (data['sku'] != null &&
                                        (data['sku'] as String).isNotEmpty) {
                                      b.sku = data['sku'] as String;
                                    }
                                  }),
                                );
                            success = true;
                          } catch (e) {
                            success = false;
                            debugPrint(e.toString());
                          }
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
                                'comparePrice': data['comparePrice'],
                                'stock': data['stock'],
                                'sku': data['sku'],
                                'tracksStock': data['tracksStock'],
                              };
                            }
                          });
                          success = true;
                        } else {
                          try {
                            await ref
                                .read(adminVendorsRepositoryProvider)
                                .updateVariant(
                                  widget.vendorId,
                                  widget.product['id'],
                                  variant['id'],
                                  UpdateProductVariantDto((b) {
                                    b.name = data['name'] as String;
                                    b.nameAr = data['nameAr'] as String;
                                    b.basePrice = data['basePrice'] as num;
                                    if (data['comparePrice'] != null) {
                                      b.comparePrice =
                                          data['comparePrice'] as num;
                                    }
                                    b.stock = data['stock'] as num?;
                                    if (data['tracksStock'] != null) {
                                      b.tracksStock =
                                          data['tracksStock'] as bool;
                                    }
                                    if (data['sku'] != null &&
                                        (data['sku'] as String).isNotEmpty) {
                                      b.sku = data['sku'] as String;
                                    }
                                  }),
                                );
                            success = true;
                          } catch (e) {
                            success = false;
                            debugPrint(e.toString());
                          }
                        }
                      }
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx, success);
                    },
            ),
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await AppConfirmDialog.show(
      context,
      title: l10n.deleteVariant,
      message: l10n.deleteConfirmVariant,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirm == true) {
      bool success = false;
      if (widget.product == null) {
        setState(() {
          _variants.removeWhere((v) => v['id'] == variantId);
        });
        success = true;
      } else {
        try {
          await ref
              .read(adminVendorsRepositoryProvider)
              .deleteVariant(widget.vendorId, widget.product['id'], variantId);
          success = true;
        } catch (e) {
          success = false;
          debugPrint(e.toString());
        }
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
    bool isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final l10n = AppLocalizations.of(dialogCtx)!;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AppDialog(
            maxWidth: 500,
            canPop: !isSaving,
            header: AppDialogHeader(
              icon: LucideIcons.listPlus,
              title: group == null ? l10n.addOptionGroup : l10n.editOptionGroup,
              isCloseDisabled: isSaving,
              onClose: () => Navigator.pop(dialogCtx),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: l10n.groupNameEn,
                  languageTag: 'EN',
                  hint: 'e.g. Size, Extras',
                  icon: LucideIcons.type,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: nameArController,
                  label: l10n.groupNameAr,
                  languageTag: 'عربي',
                  languageTagColor: AppColors.info,
                  hint: 'مثال: الحجم، الإضافات',
                  icon: LucideIcons.languages,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: minController,
                        label: l10n.min,
                        hint: '0',
                        icon: LucideIcons.minus,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: maxController,
                        label: l10n.max,
                        hint: '1',
                        icon: LucideIcons.plus,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppDialogSectionCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      l10n.isRequired,
                      style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                    ),
                    value: isRequired,
                    activeColor: AppColors.primary,
                    checkColor: AppColors.onPrimary,
                    controlAffinity: ListTileControlAffinity.trailing,
                    onChanged: (v) =>
                        setDialogState(() => isRequired = v ?? false),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
            footer: AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.pop(dialogCtx),
              confirmLabel: group == null ? l10n.add : l10n.save,
              confirmIcon:
                  group == null ? LucideIcons.plus : LucideIcons.check,
              isLoading: isSaving,
              onConfirm: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
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
                              'id':
                                  'temp_${DateTime.now().millisecondsSinceEpoch}',
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
                          try {
                            await ref
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
                                );
                            success = true;
                          } catch (e) {
                            success = false;
                            debugPrint(e.toString());
                          }
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
                          try {
                            await ref
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
                                );
                            success = true;
                          } catch (e) {
                            success = false;
                            debugPrint(e.toString());
                          }
                        }
                      }
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx, success);
                    },
            ),
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await AppConfirmDialog.show(
      context,
      title: l10n.deleteOptionGroup,
      message: l10n.deleteConfirmOptionGroup,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirm == true) {
      bool success = false;
      if (widget.product == null) {
        setState(() {
          _optionGroups.removeWhere((g) => g['id'] == groupId);
        });
        success = true;
      } else {
        try {
          await ref
              .read(adminVendorsRepositoryProvider)
              .deleteOptionGroup(
                widget.vendorId,
                widget.product['id'],
                groupId,
              );
          success = true;
        } catch (e) {
          success = false;
          debugPrint(e.toString());
        }
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
    bool isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final l10n = AppLocalizations.of(dialogCtx)!;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AppDialog(
            maxWidth: 480,
            canPop: !isSaving,
            header: AppDialogHeader(
              icon: LucideIcons.listChecks,
              title: option == null ? l10n.addOption : l10n.editOption,
              isCloseDisabled: isSaving,
              onClose: () => Navigator.pop(dialogCtx),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: l10n.optionNameEn,
                  languageTag: 'EN',
                  hint: 'e.g. Medium, Extra Mozzarella',
                  icon: LucideIcons.type,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: nameArController,
                  label: l10n.optionNameAr,
                  languageTag: 'عربي',
                  languageTagColor: AppColors.info,
                  hint: 'مثال: وسط، جبنة موزاريلا إضافية',
                  icon: LucideIcons.languages,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: priceController,
                  label: l10n.additionalPrice,
                  hint: '0.00',
                  icon: LucideIcons.dollarSign,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
            footer: AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.pop(dialogCtx),
              confirmLabel: option == null ? l10n.add : l10n.save,
              confirmIcon:
                  option == null ? LucideIcons.plus : LucideIcons.check,
              isLoading: isSaving,
              onConfirm: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final data = {
                        'name': nameController.text,
                        'nameAr': nameArController.text,
                        'priceAdded':
                            double.tryParse(priceController.text) ?? 0.0,
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
                          try {
                            await ref
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
                                );
                            success = true;
                          } catch (e) {
                            success = false;
                            debugPrint(e.toString());
                          }
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
                          try {
                            await ref
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
                                );
                            success = true;
                          } catch (e) {
                            success = false;
                            debugPrint(e.toString());
                          }
                        }
                      }
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(dialogCtx, success);
                    },
            ),
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await AppConfirmDialog.show(
      context,
      title: l10n.deleteOption,
      message: l10n.deleteConfirmOption,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
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
        try {
          await ref
              .read(adminVendorsRepositoryProvider)
              .deleteOption(
                widget.vendorId,
                widget.product['id'],
                groupId,
                optionId,
              );
          success = true;
        } catch (e) {
          success = false;
          debugPrint(e.toString());
        }
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasImage = _imageFile != null || widget.product?['imageUrl'] != null;

    return Builder(
      builder: (imgCtx) => Stack(
        children: [
          GestureDetector(
            onTap: _isPickingImage ? null : () => _pickImage(),
            child: Container(
              height: 164,
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
                          ? Image.memory(_imageFileBytes!, fit: BoxFit.cover)
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
                  : widget.product?['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(
                            _formatImageUrl(widget.product!['imageUrl']),
                            fit: BoxFit.cover,
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
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.25),
                                ),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.imageFormatSupport,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
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
                    onTap: () => _pickImage(),
                    tooltip: l10n.changeImage,
                  ),
                  const SizedBox(width: 8),
                  _buildImageActionButton(
                    icon: LucideIcons.trash2,
                    onTap: () {
                      setState(() {
                        _imageFile = null;
                        _imageFileBytes = null;
                        if (widget.product != null) {
                          widget.product['imageUrl'] = null;
                        }
                      });
                    },
                    backgroundColor: AppColors.error.withValues(alpha: 0.9),
                    tooltip: l10n.removeImage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    String? tooltip,
  }) {
    final button = Material(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: value ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
        size: 19,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
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

    if (_branchAvailabilityMode == 'SPECIFIC' &&
        _selectedBranchIds.isEmpty) {
      _showNotice(
        AppLocalizations.of(context)!.branchAvailabilityRequired,
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
      'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      'stock': double.tryParse(_stockController.text),
      'isActive': _isActive,
      'isFeatured': _isFeatured,
      'sellByStrip': _sellByStrip,
      'stripsPerPackage': int.tryParse(_stripsCountController.text),
      'tracksStock': _tracksStock,
      'imageFile': _imageFile,
      'hasVariants': _variants.isNotEmpty,
      'variants': _variants,
      'optionGroups': _optionGroups,
      'branchAvailabilityMode': _branchAvailabilityMode,
      'branchIds': _branchAvailabilityMode == 'SPECIFIC'
          ? _selectedBranchIds.toList()
          : <String>[],
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

