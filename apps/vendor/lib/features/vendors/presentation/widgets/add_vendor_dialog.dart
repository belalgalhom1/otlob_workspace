import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:core/core.dart';
import 'package:data/data.dart';

class AddVendorDialog extends ConsumerStatefulWidget {
  final dynamic vendor;
  final String? userRole;
  const AddVendorDialog({super.key, this.vendor, this.userRole});

  @override
  ConsumerState<AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends ConsumerState<AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameArController;

  late TextEditingController _descriptionController;
  late TextEditingController _descriptionArController;
  late TextEditingController _taxIdController;
  late TextEditingController _commissionController;
  late TextEditingController _phoneController;

  String? _selectedVerticalId;
  List<dynamic> _verticals = [];
  bool _isLoadingVerticals = true;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  XFile? _pickedLogo;
  Uint8List? _pickedLogoBytes;
  bool _isContracted = false;
  String? _errorMessage;

  /// Commission is a platform-level commercial term: only SUPER_ADMIN can
  /// change it. Everyone else (including vendor members and ADMINs) sees the
  /// current value read-only.
  bool get _canEditCommission => widget.userRole == 'SUPER_ADMIN';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.vendor?['storeName'] ?? '',
    );
    _nameArController = TextEditingController(
      text: widget.vendor?['storeNameAr'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.vendor?['description'] ?? '',
    );
    _descriptionArController = TextEditingController(
      text: widget.vendor?['descriptionAr'] ?? '',
    );
    _taxIdController = TextEditingController(
      text: widget.vendor?['taxId'] ?? '',
    );
    _commissionController = TextEditingController(
      text: widget.vendor?['commissionRate']?.toString() ?? '10',
    );
    _phoneController = TextEditingController(
      text: widget.vendor?['phone'] ?? '',
    );
    _selectedVerticalId =
        widget.vendor?['vertical']?['id'] ?? widget.vendor?['verticalId'];
    _isContracted = widget.vendor?['isContracted'] ?? false;
    _loadVerticals();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _taxIdController.dispose();
    _commissionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadVerticals() async {
    try {
      final verticals = await ref
          .read(adminVerticalsRepositoryProvider)
          .verticalsFindAll();
      if (mounted) {
        setState(() {
          _verticals = verticals;
          _isLoadingVerticals = false;
          if (_selectedVerticalId == null && _verticals.isNotEmpty) {
            _selectedVerticalId = _verticals.first['id'];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVerticals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isMobile = AppDialogStyles.isMobile(context);
    final isEdit = widget.vendor != null;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AppDialog(
      maxWidth: 640,
      header: AppDialogHeader(
        icon: isEdit ? LucideIcons.edit3 : LucideIcons.store,
        title: isEdit ? l10n.editVendor : l10n.addNewVendor,
        subtitle: isEdit ? l10n.updateVendorDetails : l10n.registerNewStore,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
              AppDialogErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            _buildSectionHeader(
              LucideIcons.info,
              l10n.generalInformation,
            ),
            const SizedBox(height: 14),
            if (isMobile) ...[
              _buildTextField(
                controller: _nameController,
                label: l10n.storeNameEn,
                languageTag: 'EN',
                isRequired: true,
                hint: 'Enter store name',
                icon: LucideIcons.type,
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameArController,
                label: l10n.storeNameAr,
                languageTag: 'عربي',
                languageTagColor: AppColors.info,
                hint: 'اسم المتجر',
                icon: LucideIcons.languages,
                textDirection: TextDirection.rtl,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _nameController,
                      label: l10n.storeNameEn,
                      languageTag: 'EN',
                      isRequired: true,
                      hint: 'Enter store name',
                      icon: LucideIcons.type,
                      textDirection: TextDirection.ltr,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.fieldRequired
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      controller: _nameArController,
                      label: l10n.storeNameAr,
                      languageTag: 'عربي',
                      languageTagColor: AppColors.info,
                      hint: 'اسم المتجر',
                      icon: LucideIcons.languages,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: l10n.descriptionEn,
              languageTag: 'EN',
              hint: 'Short description about the store',
              icon: LucideIcons.alignLeft,
              maxLines: 2,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionArController,
              label: l10n.descriptionAr,
              languageTag: 'عربي',
              languageTagColor: AppColors.info,
              hint: 'وصف المتجر',
              icon: LucideIcons.languages,
              maxLines: 2,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 22),
            _buildSectionHeader(
              LucideIcons.layers,
              l10n.businessCategory,
            ),
            const SizedBox(height: 12),
            _buildVerticalDropdown(),
            const SizedBox(height: 22),
            _buildSectionHeader(
              LucideIcons.fileText,
              l10n.financials,
            ),
            const SizedBox(height: 14),
            if (isMobile) ...[
              _buildTextField(
                controller: _taxIdController,
                label: l10n.taxId,
                hint: '123-456-789',
                icon: LucideIcons.hash,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _commissionController,
                label: l10n.commissionPercent,
                hint: '10',
                icon: LucideIcons.percent,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                enabled: _canEditCommission,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _taxIdController,
                      label: l10n.taxId,
                      hint: '123-456-789',
                      icon: LucideIcons.hash,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTextField(
                      controller: _commissionController,
                      label: l10n.commissionPercent,
                      hint: '10',
                      icon: LucideIcons.percent,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      enabled: _canEditCommission,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: l10n.phone,
              hint: '+201234567890',
              icon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 22),
            _buildSectionHeader(
              LucideIcons.shieldCheck,
              isAr ? 'حالة الشراكة' : 'Partnership Status',
            ),
            const SizedBox(height: 12),
            AppDialogSectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isAr ? 'متعاقد معنا' : 'Contracted with us',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    isAr
                        ? 'تحديد هذا المتجر كشريك رسمي على المنصة'
                        : 'Mark this vendor as officially contracted with our platform',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: _isContracted,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isContracted = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),
            _buildSectionHeader(
              LucideIcons.image,
              l10n.storeAppearance,
            ),
            const SizedBox(height: 12),
            _buildImagePicker(),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: isEdit ? l10n.updateVendor : l10n.registerStore,
        confirmIcon: LucideIcons.check,
        onConfirm: _submit,
      ),
    );
  }

  Widget _buildVerticalDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final isVendor = widget.userRole == 'VENDOR_MEMBER';
    return _isLoadingVerticals
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : _buildDropdownField(
            label: l10n.businessType,
            hint: l10n.selectCategory,
            icon: LucideIcons.layoutGrid,
            isRequired: true,
            value: _selectedVerticalId,
            items: _verticals
                .map(
                  (v) => DropdownMenuItem<String>(
                    value: v['id'] as String?,
                    child: Text(
                      v['name'] ?? l10n.unknown,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: isVendor
                ? null
                : (val) => setState(() {
                      _selectedVerticalId = val;
                      _errorMessage = null;
                    }),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    bool enabled = true,
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
          validator: validator,
          keyboardType: keyboardType,
          textDirection: textDirection,
          enabled: enabled,
          style: TextStyle(
            fontSize: 14,
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
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

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: label, isRequired: isRequired),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: AppDialogStyles.dropdownColor(context),
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
          decoration: AppDialogStyles.inputDecoration(
            context,
            hintText: hint,
            icon: icon,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final existingLogo = ImageUtils.firstNonEmptyString([
      widget.vendor?['logo'],
      widget.vendor?['logoUrl'],
    ]);
    final existingCover = ImageUtils.firstNonEmptyString([
      widget.vendor?['coverImage'],
      widget.vendor?['image'],
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: isArabic ? 'شعار المتجر (Logo)' : 'Store Logo'),
        Row(
          children: [
            Builder(
              builder: (logoCtx) => InkWell(
                onTap: () => _pickVendorMedia(logoCtx, isLogo: true),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppDialogStyles.subtleSurfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppDialogStyles.borderColor(context),
                      width: 1.2,
                    ),
                  ),
                  child: _pickedLogo != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: _buildLocalImagePreview(
                                file: _pickedLogo!,
                                bytes: _pickedLogoBytes,
                                height: 92,
                                width: 92,
                              ),
                            ),
                            PositionedDirectional(
                              end: 4,
                              top: 4,
                              child: _buildClearMediaButton(() {
                                setState(() {
                                  _pickedLogo = null;
                                  _pickedLogoBytes = null;
                                });
                              }),
                            ),
                          ],
                        )
                      : existingLogo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: AppNetworkAvatar(
                                key: ValueKey('dlg_logo_$existingLogo'),
                                imageUrl: ImageUtils.formatImageUrl(existingLogo),
                                size: 92,
                                borderRadius: 15,
                                fallbackIcon: LucideIcons.store,
                                fallbackIconSize: 28,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.store,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isArabic ? 'شعار' : 'Logo',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Builder(
                builder: (btnCtx) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'يظهر شعار المتجر بجانب الطلبات وفي قائمة المتاجر.'
                          : 'Appears next to store orders and in vendor cards.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickVendorMedia(btnCtx, isLogo: true),
                      icon: const Icon(LucideIcons.upload, size: 14),
                      label: Text(
                        existingLogo != null || _pickedLogo != null
                            ? (isArabic ? 'تغيير الشعار' : 'Change Logo')
                            : (isArabic ? 'رفع الشعار' : 'Upload Logo'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppFieldLabel(label: l10n.uploadCover),
        Builder(
          builder: (imgCtx) => InkWell(
            onTap: () => _pickVendorMedia(imgCtx, isLogo: false),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppDialogStyles.subtleSurfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppDialogStyles.borderColor(context),
                  width: 1.2,
                ),
              ),
              child: _pickedImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: _buildLocalImagePreview(
                            file: _pickedImage!,
                            bytes: _pickedImageBytes,
                            height: 150,
                            width: double.infinity,
                          ),
                        ),
                        PositionedDirectional(
                          end: 10,
                          top: 10,
                          child: _buildClearMediaButton(() {
                            setState(() {
                              _pickedImage = null;
                              _pickedImageBytes = null;
                            });
                          }),
                        ),
                      ],
                    )
                  : existingCover != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.network(
                                ImageUtils.formatImageUrl(existingCover),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _buildCoverPlaceholder(theme, l10n),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.camera,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.changeImage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildCoverPlaceholder(theme, l10n),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalImagePreview({
    required XFile file,
    required Uint8List? bytes,
    required double height,
    required double width,
  }) {
    if (bytes != null) {
      return Image.memory(bytes, height: height, width: width, fit: BoxFit.cover);
    }
    if (kIsWeb) {
      return Image.network(file.path, height: height, width: width, fit: BoxFit.cover);
    }
    return Image.file(File(file.path), height: height, width: width, fit: BoxFit.cover);
  }

  Widget _buildClearMediaButton(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 16),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.72),
        minimumSize: const Size(28, 28),
        padding: const EdgeInsets.all(4),
      ),
    );
  }

  Widget _buildCoverPlaceholder(ThemeData theme, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.imagePlus,
            size: 26,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.uploadCover,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _pickVendorMedia(BuildContext ctx, {required bool isLogo}) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      XFile? finalImage;

      // Safely attempt cropping with isolated error handling
      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: isLogo
              ? const CropAspectRatio(ratioX: 1, ratioY: 1)
              : const CropAspectRatio(ratioX: 16, ratioY: 8),
          compressQuality: 82,
          maxWidth: isLogo ? 1024 : 1440,
          maxHeight: isLogo ? 1024 : 720,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: isLogo ? 'Crop Store Logo' : 'Crop Store Cover',
              toolbarColor: const Color(0xFFD4920E),
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: const Color(0xFFD4920E),
              initAspectRatio: isLogo
                  ? CropAspectRatioPreset.square
                  : CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: isLogo ? 'Crop Store Logo' : 'Crop Store Cover',
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
        debugPrint('ImageCropper failed or not available, falling back to original image: $cropErr');
        finalImage = image;
      }

      final bytes = await finalImage.readAsBytes();
      if (mounted) {
        setState(() {
          if (isLogo) {
            _pickedLogo = finalImage;
            _pickedLogoBytes = bytes;
          } else {
            _pickedImage = finalImage;
            _pickedImageBytes = bytes;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking vendor image: $e');
      MediaPermissionHelper.handlePickerError(
        e,
        context: ctx.mounted ? ctx : (mounted ? context : null),
      );
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _errorMessage = l10n.pleaseFillRequiredFields);
      return;
    }

    if (_selectedVerticalId == null) {
      final msg = l10n.pleaseSelectBusinessType;
      setState(() => _errorMessage = msg);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _errorMessage = null);

    final data = {
      'storeName': _nameController.text,
      'storeNameAr': _nameArController.text,
      'description': _descriptionController.text,
      'descriptionAr': _descriptionArController.text,
      'taxId': _taxIdController.text,
      if (_canEditCommission)
        'commissionRate': double.tryParse(_commissionController.text) ?? 10.0,
      'verticalId': _selectedVerticalId,
      'phone': _phoneController.text,
      'logo': _pickedLogo,
      'coverImage': _pickedImage,
      'isContracted': _isContracted,
    };

    Navigator.pop(context, data);
  }
}

