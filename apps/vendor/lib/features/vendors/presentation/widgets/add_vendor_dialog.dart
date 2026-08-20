import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
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
  bool _isContracted = false;
  bool _isScheduleActive = true;
  bool _is24Hours = false;
  List<Map<String, dynamic>> _workingHours = [];

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
    _selectedVerticalId = widget.vendor?['vertical']?['id'] ?? widget.vendor?['verticalId'];
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
      final verticals = await ref.read(adminVerticalsRepositoryProvider).verticalsFindAll();
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isEdit = widget.vendor != null;

    return DialogScaffold(child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? size.width : 600),
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
                padding: const EdgeInsets.all(24),
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? LucideIcons.edit3 : LucideIcons.store,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? AppLocalizations.of(context)!.editVendor
                                : AppLocalizations.of(context)!.addNewVendor,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            isEdit
                                ? AppLocalizations.of(
                                    context,
                                  )!.updateVendorDetails
                                : AppLocalizations.of(
                                    context,
                                  )!.registerNewStore,
                            style: const TextStyle(
                              fontSize: 13,
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.x,
                        
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          LucideIcons.info,
                          AppLocalizations.of(context)!.generalInformation,
                        ),
                        const SizedBox(height: 16),
                        if (isMobile) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: AppLocalizations.of(context)!.storeNameEn,
                            hint: 'Enter store name',
                            icon: LucideIcons.type,
                            validator: (v) => v?.isEmpty ?? true
                                ? AppLocalizations.of(context)!.fieldRequired
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameArController,
                            label: AppLocalizations.of(context)!.storeNameAr,
                            hint: 'اسم المتجر',
                            icon: LucideIcons.languages,
                            textAlign: TextAlign.right,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _nameController,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.storeNameEn,
                                  hint: 'Enter store name',
                                  icon: LucideIcons.type,
                                  validator: (v) => v?.isEmpty ?? true
                                      ? AppLocalizations.of(context)!.unknown
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _nameArController,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.storeNameAr,
                                  hint: 'اسم المتجر',
                                  icon: LucideIcons.languages,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: AppLocalizations.of(context)!.descriptionEn,
                          hint: 'Short description about the store',
                          icon: LucideIcons.alignLeft,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionArController,
                          label: AppLocalizations.of(context)!.descriptionAr,
                          hint: 'وصف المتجر',
                          icon: LucideIcons.languages,
                          maxLines: 2,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          LucideIcons.layers,
                          AppLocalizations.of(context)!.businessCategory,
                        ),
                        const SizedBox(height: 12),
                        _buildVerticalDropdown(),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          LucideIcons.fileText,
                          AppLocalizations.of(context)!.financials,
                        ),
                        const SizedBox(height: 16),
                        if (isMobile) ...[
                          _buildTextField(
                            controller: _taxIdController,
                            label: AppLocalizations.of(context)!.taxId,
                            hint: '123-456-789',
                            icon: LucideIcons.hash,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _commissionController,
                            label: AppLocalizations.of(
                              context,
                            )!.commissionPercent,
                            hint: '10',
                            icon: LucideIcons.percent,
                            keyboardType: TextInputType.number,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _taxIdController,
                                  label: AppLocalizations.of(context)!.taxId,
                                  hint: '123-456-789',
                                  icon: LucideIcons.hash,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _commissionController,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.commissionPercent,
                                  hint: '10',
                                  icon: LucideIcons.percent,
                                  keyboardType: TextInputType.number,
                                  enabled: widget.userRole != 'VENDOR_MEMBER',
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: AppLocalizations.of(context)!.phone,
                          hint: '+201234567890',
                          icon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          LucideIcons.shieldCheck,
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'حالة الشراكة'
                              : 'Partnership Status',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'متعاقد معنا'
                                  : 'Contracted with us',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'تحديد هذا المتجر كشريك رسمي على المنصة'
                                  : 'Mark this vendor as officially contracted with our platform',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface,
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
                        const SizedBox(height: 24),
                        _buildWorkingHoursSection(
                          Localizations.localeOf(context).languageCode == 'ar',
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          LucideIcons.image,
                          AppLocalizations.of(context)!.storeAppearance,
                        ),
                        const SizedBox(height: 12),
                        _buildImagePicker(),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(24),
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
                    Builder(
                      builder: (btnCtx) => ElevatedButton(
                        onPressed: () => _submit(btnCtx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEdit
                            ? AppLocalizations.of(context)!.updateVendor
                            : AppLocalizations.of(context)!.registerStore,
                      ),
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

  Widget _buildVerticalDropdown() {
    final isVendor = widget.userRole == 'VENDOR_MEMBER';
    return _isLoadingVerticals
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : _buildDropdownField(
            label: AppLocalizations.of(context)!.businessType,
            hint: AppLocalizations.of(context)!.selectCategory,
            icon: LucideIcons.layoutGrid,
            value: _selectedVerticalId,
            items: _verticals
                .map(
                  (v) => DropdownMenuItem<String>(
                    value: v['id'] as String?,
                    child: Text(v['name'] ?? 'Unknown'),
                  ),
                )
                .toList(),
            onChanged: isVendor
                ? null
                : (val) => setState(() => _selectedVerticalId = val),
          );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              
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
    TextAlign textAlign = TextAlign.start,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          keyboardType: keyboardType,
          textAlign: textAlign,
          enabled: enabled,
          style: TextStyle(
            fontSize: 14,
            color: enabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(
                    context,
                  ).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.all(16),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.uploadCover,
          style: const TextStyle(
            fontSize: 13,
            
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (imgCtx) => InkWell(
            onTap: () => _pickImage(imgCtx),
            borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: _pickedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedImage!.path),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      PositionedDirectional(
                        end: 8,
                        top: 8,
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            color: AppColors.error,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _pickedImage = null),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black26,
                          ),
                        ),
                      ),
                    ],
                  )
                : (widget.vendor?['coverImage'] ?? widget.vendor?['image']) !=
                      null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ImageUtils.formatImageUrl(
                            widget.vendor?['coverImage'] ??
                                widget.vendor?['image'],
                          ),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.imagePlus,
                                size: 32,
                                
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.uploadCover,
                                style: const TextStyle(
                                  fontSize: 12,
                                  
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.changeImage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.imagePlus,
                        size: 32,
                        
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.uploadCover,
                        style: const TextStyle(
                          fontSize: 12,
                          
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext ctx) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _pickedImage = XFile(result.files.single.path!));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
        (a, b) => _getDaySortValue(a['day'] as int).compareTo(_getDaySortValue(b['day'] as int)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 250),
              child: _buildSectionHeader(
                LucideIcons.calendarClock,
                isArabic ? 'ساعات العمل الأسبوعية' : 'Weekly Working Hours',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? '24 ساعة' : '24 Hours',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: _is24Hours,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _is24Hours = val),
                    ),
                  ),
                ],
              ),
            ),
            if (!_is24Hours)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic ? 'تلقائي' : 'Auto-Sync',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      width: 40,
                      child: Switch(
                        value: _isScheduleActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isScheduleActive = val),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_is24Hours && _workingHours.isNotEmpty)
              TextButton.icon(
                onPressed: _applyFirstDayToAll,
                icon: const Icon(LucideIcons.copy, size: 14),
                label: Text(
                  isArabic ? 'تطبيق الأول على الكل' : 'Apply First to All',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: const BorderSide(color: AppColors.primary, width: 1),
                  label: Text(
                    _getDayName(i, isArabic),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                        (a, b) => _getDaySortValue(a['day'] as int).compareTo(_getDaySortValue(b['day'] as int)),
                      );
                      _isScheduleActive = true;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          ...List.generate(_workingHours.length, (index) {
          final schedule = _workingHours[index];
          final dayNum = schedule['day'] as int;
          final isClosed = schedule['isClosed'] as bool? ?? false;
          final openTime = schedule['openTime'] as String? ?? '09:00';
          final closeTime = schedule['closeTime'] as String? ?? '22:00';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isClosed
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.01)
                  : AppColors.primary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isClosed
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04)
                    : AppColors.primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Header (Day Name, Switch, Delete Button)
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: isClosed
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDayName(dayNum, isArabic),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isClosed
                            ? AppColors.textSecondary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isClosed
                          ? (isArabic ? 'إجازة' : 'Day Off')
                          : (isArabic ? 'مفتوح' : 'Open'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isClosed
                            ? Colors.red.shade300
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 4),
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
                        color: Colors.redAccent,
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

                // Row 2: Time Settings / Closed Indicator
                if (!isClosed) ...[
                  const SizedBox(height: 8),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      
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
    return InkWell(
      onTap: () async {
        final parts = timeStr.split(':');
        final currentHour = int.tryParse(parts[0]) ?? 9;
        final currentMin = int.tryParse(parts[1]) ?? 0;

        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: currentHour, minute: currentMin),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedTime != null) {
          final hh = selectedTime.hour.toString().padLeft(2, '0');
          final mm = selectedTime.minute.toString().padLeft(2, '0');
          onTimeSelected('$hh:$mm');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 11,
                
              ),
            ),
            Text(
              _formatTimeTo12Hour(
                timeStr,
                Localizations.localeOf(context).languageCode == 'ar',
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext ctx) {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedVerticalId == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(ctx)!.pleaseSelectBusinessType,
            ),
          ),
        );
        return;
      }

      if (!_is24Hours && _workingHours.isEmpty) {
        final isArabic = Localizations.localeOf(ctx).languageCode == 'ar';
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'برجاء تحديد مواعيد العمل الأسبوعية للمتجر!'
                  : 'Please set weekly working hours for the store!',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final data = {
        'storeName': _nameController.text,
        'storeNameAr': _nameArController.text,
        'description': _descriptionController.text,
        'descriptionAr': _descriptionArController.text,
        'taxId': _taxIdController.text,
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
}

