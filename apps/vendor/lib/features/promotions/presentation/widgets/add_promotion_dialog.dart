import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:core/core.dart';
import 'dart:io';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/date_utils.dart';
import 'package:data/data.dart';

class AddPromotionDialog extends ConsumerStatefulWidget {
  final dynamic promotion;

  const AddPromotionDialog({super.key, this.promotion});

  @override
  ConsumerState<AddPromotionDialog> createState() => _AddPromotionDialogState();
}

class _AddPromotionDialogState extends ConsumerState<AddPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _titleArController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionArController;
  late TextEditingController _urlController;
  late TextEditingController _sortOrderController;

  late String _type;
  late bool _isActive;
  String? _selectedVendorId;
  String? _selectedProductId;

  XFile? _imageFile;
  Uint8List? _imageFileBytes;
  String? _errorMessage;

  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _vendors = [];
  List<dynamic> _products = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _titleController = TextEditingController(text: p?['title'] ?? '');
    _titleArController = TextEditingController(text: p?['titleAr'] ?? '');
    _descriptionController = TextEditingController(
      text: p?['description'] ?? '',
    );
    _descriptionArController = TextEditingController(
      text: p?['descriptionAr'] ?? '',
    );
    _urlController = TextEditingController(text: p?['externalUrl'] ?? '');
    _sortOrderController = TextEditingController(
      text: p?['sortOrder']?.toString() ?? '0',
    );

    _type = p?['type'] ?? 'BANNER';
    _isActive = p?['isActive'] ?? true;
    _selectedVendorId = p?['vendorId'];
    _selectedProductId = p?['productId'];

    if (p?['startDate'] != null) {
      _startDate = DateTime.tryParse(p['startDate'].toString());
    }
    if (p?['endDate'] != null) {
      _endDate = DateTime.tryParse(p['endDate'].toString());
    }

    _fetchVendors();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _urlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _fetchVendors() async {
    try {
      final result = await ref.read(adminVendorsRepositoryProvider).getVendors();
      if (mounted) {
        setState(() {
          _vendors = (result is List)
              ? result
              : (result['items'] ??
                  result['vendors'] ??
                  result['data']?['vendors'] ??
                  []);
        });

        if (_selectedVendorId != null && _type == 'PRODUCT') {
          _fetchProducts(_selectedVendorId!);
        }
      }
    } catch (e) {
      debugPrint('AddPromotionDialog fetchVendors Error: $e');
    }
  }

  Future<void> _fetchProducts(String vendorId) async {
    setState(() {
      _isLoadingProducts = true;
      _products = [];
    });
    try {
      final result = await ref
          .read(adminVendorsRepositoryProvider)
          .getProducts(vendorId);
      if (mounted) {
        setState(() {
          _products = (result is List)
              ? result
              : (result['items'] ??
                  result['products'] ??
                  result['data']?['products'] ??
                  []);
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.promotion != null;

    return AppDialog(
      maxWidth: 680,
      maxHeight: 820,
      header: AppDialogHeader(
        icon: LucideIcons.megaphone,
        title: isEdit ? l10n.editPromotion : l10n.addPromotion,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              AppDialogErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            _buildSectionHeader(
              l10n.uploadBannerImage,
              LucideIcons.image,
            ),
            const SizedBox(height: 10),
            _buildImagePicker(l10n),
            const SizedBox(height: 24),

            _buildSectionHeader(
              l10n.promotionType,
              LucideIcons.tag,
            ),
            const SizedBox(height: 12),
            AppFieldLabel(label: l10n.promotionType, isRequired: true),
            _buildTypeDropdown(l10n),

            if (_type == 'VENDOR' || _type == 'PRODUCT') ...[
              const SizedBox(height: 16),
              AppFieldLabel(label: l10n.selectVendor, isRequired: true),
              _buildVendorDropdown(l10n),
              if (_type == 'PRODUCT' && _selectedVendorId != null) ...[
                const SizedBox(height: 16),
                AppFieldLabel(label: l10n.selectProduct, isRequired: true),
                _buildProductDropdown(l10n),
              ],
            ],

            if (_type == 'EXTERNAL_LINK') ...[
              const SizedBox(height: 16),
              AppFieldLabel(label: l10n.externalUrl, isRequired: true),
              _buildTextField(
                controller: _urlController,
                hint: 'https://...',
                icon: LucideIcons.link,
                textDirection: TextDirection.ltr,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n.fieldRequired;
                  }
                  if (!Uri.parse(v).isAbsolute) {
                    return l10n.invalidUrl;
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),
            _buildSectionHeader(
              l10n.generalInformation,
              LucideIcons.info,
            ),
            const SizedBox(height: 12),

            AppFieldLabel(label: l10n.titleEn, languageTag: 'EN'),
            _buildTextField(
              controller: _titleController,
              hint: 'Summer Sale',
              icon: LucideIcons.type,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            AppFieldLabel(
              label: l10n.titleAr,
              languageTag: 'عربي',
              languageTagColor: AppColors.info,
            ),
            _buildTextField(
              controller: _titleArController,
              hint: 'عروض الصيف',
              icon: LucideIcons.languages,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.descriptionEn, languageTag: 'EN'),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Optional...',
              icon: LucideIcons.alignLeft,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            AppFieldLabel(
              label: l10n.descriptionAr,
              languageTag: 'عربي',
              languageTagColor: AppColors.info,
            ),
            _buildTextField(
              controller: _descriptionArController,
              hint: 'اختياري...',
              icon: LucideIcons.languages,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            _buildDateSelectors(l10n),
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.sortOrder),
            _buildTextField(
              controller: _sortOrderController,
              hint: '0',
              icon: LucideIcons.listOrdered,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(l10n),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: isEdit ? l10n.update : l10n.create,
        confirmIcon: LucideIcons.check,
        onConfirm: _submit,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final hasImageError = _errorMessage != null &&
        _imageFile == null &&
        (widget.promotion?['imageUrl'] == null ||
            widget.promotion!['imageUrl'].toString().trim().isEmpty);

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 165,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppDialogStyles.subtleSurfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImageError
                ? AppColors.error
                : AppDialogStyles.borderColor(context),
            width: hasImageError ? 1.5 : 1.2,
          ),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _imageFileBytes != null
                    ? Image.memory(_imageFileBytes!, fit: BoxFit.cover)
                    : kIsWeb
                        ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
              )
            : (widget.promotion?['imageUrl'] != null &&
                    widget.promotion!['imageUrl'].toString().trim().isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      ImageUtils.formatImageUrl(widget.promotion!['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.uploadCloud,
                          size: 26,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.uploadBannerImage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      XFile? finalImage;
      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 8),
          compressQuality: 82,
          maxWidth: 1440,
          maxHeight: 720,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Banner',
              toolbarColor: const Color(0xFFD4920E),
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: const Color(0xFFD4920E),
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Banner',
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
        debugPrint(
          'ImageCropper failed or not available, using original image: $cropErr',
        );
        finalImage = image;
      }

      if (finalImage == null) return;

      final bytes = await finalImage.readAsBytes();
      if (mounted) {
        setState(() {
          _imageFile = finalImage;
          _imageFileBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking promotion banner image: $e');
      MediaPermissionHelper.handlePickerError(
        e,
        context: mounted ? context : null,
      );
    }
  }

  Widget _buildTypeDropdown(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: _type,
      isExpanded: true,
      dropdownColor: AppDialogStyles.dropdownColor(context),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: AppDialogStyles.inputDecoration(
        context,
        icon: LucideIcons.layers,
      ),
      items: [
        DropdownMenuItem(value: 'BANNER', child: Text(l10n.bannerType)),
        DropdownMenuItem(value: 'VENDOR', child: Text(l10n.vendorType)),
        DropdownMenuItem(value: 'PRODUCT', child: Text(l10n.productType)),
        DropdownMenuItem(value: 'EXTERNAL_LINK', child: Text(l10n.linkType)),
      ],
      onChanged: (v) => setState(() => _type = v!),
    );
  }

  Widget _buildVendorDropdown(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: _selectedVendorId,
      isExpanded: true,
      dropdownColor: AppDialogStyles.dropdownColor(context),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: AppDialogStyles.inputDecoration(
        context,
        hintText: l10n.selectVendor,
        icon: LucideIcons.store,
      ),
      items: _vendors
          .map(
            (v) => DropdownMenuItem<String>(
              value: v['id'],
              child: Text(
                v['storeName'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (v) => v == null ? l10n.fieldRequired : null,
      onChanged: (v) {
        setState(() {
          _selectedVendorId = v;
          _selectedProductId = null;
        });
        if (v != null && _type == 'PRODUCT') _fetchProducts(v);
      },
    );
  }

  Widget _buildProductDropdown(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_products.isEmpty) {
      return AppDialogErrorBanner(message: l10n.noProductsFound);
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedProductId,
      isExpanded: true,
      dropdownColor: AppDialogStyles.dropdownColor(context),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: AppDialogStyles.inputDecoration(
        context,
        hintText: l10n.selectProduct,
        icon: LucideIcons.package,
      ),
      items: _products
          .map(
            (p) => DropdownMenuItem<String>(
              value: p['id'],
              child: Text(p['name'] ?? '', overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      validator: (v) => v == null ? l10n.fieldRequired : null,
      onChanged: (v) => setState(() => _selectedProductId = v),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextDirection? textDirection,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: textDirection,
      decoration: AppDialogStyles.inputDecoration(
        context,
        hintText: hint,
        icon: icon,
      ),
    );
  }

  Widget _buildDateSelectors(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: l10n.startDate),
        _buildDatePicker(
          _startDate,
          (d) => setState(() => _startDate = d),
        ),
        const SizedBox(height: 16),
        AppFieldLabel(label: l10n.endDate),
        _buildDatePicker(
          _endDate,
          (d) => setState(() => _endDate = d),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    DateTime? date,
    Function(DateTime?) onSelect,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: AppDialogStyles.adaptivePickerTheme,
        );
        if (d != null) onSelect(d);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: AppDialogStyles.inputDecoration(
          context,
          icon: LucideIcons.calendar,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => onSelect(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
        ),
        child: Text(
          date != null ? DateFormat('MMM dd, yyyy').format(date) : l10n.noExpiry,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: date != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(AppLocalizations l10n) {
    return AppDialogSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SwitchListTile(
        title: Text(
          l10n.active,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        value: _isActive,
        onChanged: (v) => setState(() => _isActive = v),
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      if (_imageFile == null && widget.promotion?['imageUrl'] == null) {
        setState(() => _errorMessage = l10n.imageRequired);
        return;
      }
      Navigator.pop(context, {
        'title': _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        'titleAr': _titleArController.text.trim().isEmpty
            ? null
            : _titleArController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'descriptionAr': _descriptionArController.text.trim().isEmpty
            ? null
            : _descriptionArController.text.trim(),
        'type': _type,
        'vendorId':
            (_type == 'VENDOR' || _type == 'PRODUCT') ? _selectedVendorId : null,
        'productId': _type == 'PRODUCT' ? _selectedProductId : null,
        'externalUrl':
            _type == 'EXTERNAL_LINK' ? _urlController.text.trim() : null,
        'isActive': _isActive,
        'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
        'imageFile': _imageFile,
        'startDate': _startDate == null
            ? null
            : toOffsetIso8601String(_startDate!),
        'endDate': _endDate == null
            ? null
            : toOffsetIso8601String(_endDate!),
      });
    }
  }
}

