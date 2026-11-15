import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
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
  bool _isContracted = false;
  bool _isScheduleActive = true;
  bool _is24Hours = false;
  List<Map<String, dynamic>> _workingHours = [];
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
    _isScheduleActive = widget.vendor?['isScheduleActive'] ?? true;
    _is24Hours = widget.vendor?['is24Hours'] ?? false;
    _initWorkingHours();
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
            _buildWorkingHoursSection(isAr),
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
          style: TextStyle(
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
    final existingCover =
        widget.vendor?['coverImage'] ?? widget.vendor?['image'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: l10n.uploadCover),
        Builder(
          builder: (imgCtx) => InkWell(
            onTap: () => _pickImage(imgCtx),
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
                          child: _pickedImageBytes != null
                              ? Image.memory(
                                  _pickedImageBytes!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : kIsWeb
                                  ? Image.network(
                                      _pickedImage!.path,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_pickedImage!.path),
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                        ),
                        PositionedDirectional(
                          end: 10,
                          top: 10,
                          child: IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              color: AppColors.error,
                              size: 18,
                            ),
                            onPressed: () => setState(() {
                              _pickedImage = null;
                              _pickedImageBytes = null;
                            }),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.72),
                            ),
                          ),
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

  Future<void> _pickImage(BuildContext ctx) async {
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
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 8),
          compressQuality: 82,
          maxWidth: 1440,
          maxHeight: 720,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Store Cover',
              toolbarColor: const Color(0xFFD4920E),
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: const Color(0xFFD4920E),
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Store Cover',
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

      if (finalImage == null) return;

      final bytes = await finalImage.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedImage = finalImage;
          _pickedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking cover image: $e');
      MediaPermissionHelper.handlePickerError(
        e,
        context: ctx.mounted ? ctx : (mounted ? context : null),
      );
    }
  }

  static const List<int> _orderedDays = [6, 0, 1, 2, 3, 4, 5];

  int _getDaySortValue(int day) {
    return _orderedDays.indexOf(day);
  }

  void _initWorkingHours() {
    var rawHours = widget.vendor?['workingHours'];
    if (rawHours is String) {
      try {
        rawHours = jsonDecode(rawHours);
      } catch (e) {
        rawHours = null;
      }
    }

    if (rawHours != null && rawHours is List && rawHours.isNotEmpty) {
      _workingHours = List<Map<String, dynamic>>.from(
        rawHours.map((h) => Map<String, dynamic>.from(h as Map)),
      );
      _workingHours.sort(
        (a, b) => _getDaySortValue(a['day'] as int)
            .compareTo(_getDaySortValue(b['day'] as int)),
      );
    } else {
      _workingHours = [];
    }
  }

  String _getDayName(int day, bool isArabic) {
    switch (day) {
      case 0:
        return isArabic ? 'الأحد' : 'Sunday';
      case 1:
        return isArabic ? 'الإثنين' : 'Monday';
      case 2:
        return isArabic ? 'الثلاثاء' : 'Tuesday';
      case 3:
        return isArabic ? 'الأربعاء' : 'Wednesday';
      case 4:
        return isArabic ? 'الخميس' : 'Thursday';
      case 5:
        return isArabic ? 'الجمعة' : 'Friday';
      case 6:
        return isArabic ? 'السبت' : 'Saturday';
      default:
        return '';
    }
  }

  String _formatTimeTo12Hour(String timeStr, bool isArabic) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      final hour = int.tryParse(parts[0]) ?? 0;
      final min = int.tryParse(parts[1]) ?? 0;

      final period = hour >= 12
          ? (isArabic ? 'م' : 'PM')
          : (isArabic ? 'ص' : 'AM');
      var displayHour = hour % 12;
      if (displayHour == 0) displayHour = 12;

      final minStr = min.toString().padLeft(2, '0');
      final hourStr = displayHour.toString().padLeft(2, '0');

      return '$hourStr:$minStr $period';
    } catch (e) {
      return timeStr;
    }
  }

  void _applyFirstDayToAll() {
    if (_workingHours.isEmpty) return;
    final first = _workingHours.first;
    setState(() {
      for (var i = 1; i < _workingHours.length; i++) {
        _workingHours[i]['openTime'] = first['openTime'];
        _workingHours[i]['closeTime'] = first['closeTime'];
        _workingHours[i]['isClosed'] = first['isClosed'];
      }
      _isScheduleActive = true;
    });
  }

  Widget _buildWorkingHoursSection(bool isArabic) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentTextColor =
        isDark ? Colors.amber.shade300 : const Color(0xFFB45309);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          LucideIcons.calendarClock,
          isArabic ? 'ساعات العمل الأسبوعية' : 'Weekly Working Hours',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppDialogStyles.subtleSurfaceColor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppDialogStyles.borderColor(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? '24 ساعة' : '24 Hours',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 26,
                    width: 42,
                    child: Switch(
                      value: _is24Hours,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() {
                        _is24Hours = val;
                        _errorMessage = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            if (!_is24Hours)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppDialogStyles.subtleSurfaceColor(context),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppDialogStyles.borderColor(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic ? 'تلقائي' : 'Auto-Sync',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 26,
                      width: 42,
                      child: Switch(
                        value: _isScheduleActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _isScheduleActive = val),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_is24Hours && _workingHours.isNotEmpty)
              TextButton.icon(
                onPressed: _applyFirstDayToAll,
                icon: Icon(LucideIcons.copy, size: 14, color: accentTextColor),
                label: Text(
                  isArabic ? 'تطبيق الأول على الكل' : 'Apply First to All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentTextColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: accentTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_is24Hours) ...[
          if (_workingHours.length < 7) ...[
            Text(
              isArabic
                  ? 'اضغط على اليوم لإضافته لمواعيد العمل:'
                  : 'Tap a day to add to working hours:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _orderedDays.map((i) {
                final isAdded = _workingHours.any((h) => h['day'] == i);
                if (isAdded) return const SizedBox.shrink();
                return ActionChip(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    width: 1,
                  ),
                  label: Text(
                    _getDayName(i, isArabic),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accentTextColor,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _workingHours.add({
                        'day': i,
                        'openTime': '09:00',
                        'closeTime': '22:00',
                        'isClosed': false,
                      });
                      _workingHours.sort(
                        (a, b) => _getDaySortValue(a['day'] as int)
                            .compareTo(_getDaySortValue(b['day'] as int)),
                      );
                      _isScheduleActive = true;
                      _errorMessage = null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          ...List.generate(_workingHours.length, (index) {
            final schedule = _workingHours[index];
            final dayNum = schedule['day'] as int;
            final isClosed = schedule['isClosed'] as bool? ?? false;
            final openTime = schedule['openTime'] as String? ?? '09:00';
            final closeTime = schedule['closeTime'] as String? ?? '22:00';

            return AppDialogSectionCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: isClosed
                  ? AppDialogStyles.subtleSurfaceColor(context)
                  : AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.05),
              borderColor: isClosed
                  ? AppDialogStyles.borderColor(context)
                  : AppColors.primary.withValues(alpha: 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: isClosed
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDayName(dayNum, isArabic),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isClosed
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      AppBadgePill(
                        text: isClosed
                            ? (isArabic ? 'إجازة' : 'Day Off')
                            : (isArabic ? 'مفتوح' : 'Open'),
                        accentColor:
                            isClosed ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: !isClosed,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            schedule['isClosed'] = !val;
                            _isScheduleActive = true;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: AppColors.error,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _workingHours.removeAt(index);
                            _isScheduleActive = true;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!isClosed) ...[
                    const SizedBox(height: 8),
                    Divider(
                      color: AppDialogStyles.borderColor(context),
                      height: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _timePickerButton(
                            context,
                            timeStr: openTime,
                            label: isArabic ? 'من' : 'From',
                            onTimeSelected: (newTime) {
                              setState(() {
                                schedule['openTime'] = newTime;
                                _isScheduleActive = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isArabic
                              ? LucideIcons.arrowLeft
                              : LucideIcons.arrowRight,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _timePickerButton(
                            context,
                            timeStr: closeTime,
                            label: isArabic ? 'إلى' : 'To',
                            onTimeSelected: (newTime) {
                              setState(() {
                                schedule['closeTime'] = newTime;
                                _isScheduleActive = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      isArabic ? 'مغلق طوال اليوم' : 'Closed all day',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _timePickerButton(
    BuildContext context, {
    required String timeStr,
    required String label,
    required ValueChanged<String> onTimeSelected,
  }) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final parts = timeStr.split(':');
        final currentHour = int.tryParse(parts[0]) ?? 9;
        final currentMin = int.tryParse(parts[1]) ?? 0;

        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: currentHour, minute: currentMin),
          builder: AppDialogStyles.adaptivePickerTheme,
        );

        if (selectedTime != null) {
          final hh = selectedTime.hour.toString().padLeft(2, '0');
          final mm = selectedTime.minute.toString().padLeft(2, '0');
          onTimeSelected('$hh:$mm');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppDialogStyles.backgroundColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppDialogStyles.borderColor(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              _formatTimeTo12Hour(timeStr, isAr),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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

    if (!_is24Hours && _workingHours.isEmpty) {
      final msg = isArabic
          ? 'برجاء تحديد مواعيد العمل الأسبوعية للمتجر!'
          : 'Please set weekly working hours for the store!';
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
      'coverImage': _pickedImage,
      'isContracted': _isContracted,
      'isScheduleActive': _isScheduleActive,
      'is24Hours': _is24Hours,
      'workingHours': _is24Hours ? [] : _workingHours,
    };

    Navigator.pop(context, data);
  }
}

