import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class AddVerticalDialog extends StatefulWidget {
  final dynamic vertical;
  const AddVerticalDialog({super.key, this.vertical});

  @override
  State<AddVerticalDialog> createState() => _AddVerticalDialogState();
}

class _AddVerticalDialogState extends State<AddVerticalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _sortOrderController;
  bool _isActive = true;
  final bool _isSaving = false;
  XFile? _selectedIcon;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.vertical?['name'] ?? '',
    );
    _nameArController = TextEditingController(
      text: widget.vertical?['nameAr'] ?? '',
    );
    _sortOrderController = TextEditingController(
      text: widget.vertical?['sortOrder']?.toString() ?? '0',
    );
    _isActive = widget.vertical?['isActive'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null && mounted) {
        setState(() {
          _selectedIcon = XFile(result.files.single.path!);
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('AddVerticalDialog _pickIcon Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.failedToPickImage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEdit = widget.vertical != null;

    return AppDialog(
      maxWidth: 480,
      canPop: !_isSaving,
      header: AppDialogHeader(
        icon: isEdit ? LucideIcons.edit3 : LucideIcons.layers,
        title: isEdit ? l10n.editBusinessType : l10n.addBusinessType,
        isCloseDisabled: _isSaving,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
              AppDialogErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            AppFieldLabel(label: l10n.businessTypeIcon, isRequired: true),
            const SizedBox(height: 4),
            Center(
              child: Stack(
                children: [
                  InkWell(
                    onTap: _pickIcon,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppDialogStyles.subtleSurfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppDialogStyles.borderColor(context),
                          width: 1.2,
                        ),
                      ),
                      child: _selectedIcon != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: kIsWeb
                                  ? Image.network(
                                      _selectedIcon!.path,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selectedIcon!.path),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : widget.vertical?['iconUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: _buildImage(
                                    widget.vertical!['iconUrl'],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.image,
                                      size: 28,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.uploadIcon,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  if (_selectedIcon != null ||
                      widget.vertical?['iconUrl'] != null)
                    PositionedDirectional(
                      end: -4,
                      top: -4,
                      child: IconButton(
                        onPressed: () => setState(() => _selectedIcon = null),
                        icon: const Icon(
                          LucideIcons.minusCircle,
                          color: AppColors.error,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: l10n.nameEn,
              languageTag: 'EN',
              isRequired: true,
              hint: 'e.g. Restaurants',
              icon: LucideIcons.type,
              textDirection: TextDirection.ltr,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameArController,
              label: l10n.nameAr,
              languageTag: 'عربي',
              hint: 'مثال: مطاعم',
              icon: LucideIcons.languages,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _sortOrderController,
              label: l10n.sortOrder,
              hint: '0',
              icon: LucideIcons.listOrdered,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            AppDialogSectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.activeStatus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  l10n.visibilityForVendors,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: isEdit ? l10n.update : l10n.save,
        confirmIcon: LucideIcons.save,
        isLoading: _isSaving,
        onConfirm: _submit,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    bool isRequired = false,
    String? languageTag,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(
          label: label,
          isRequired: isRequired,
          languageTag: languageTag,
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textDirection: textDirection,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return const Icon(LucideIcons.image);
    }

    if (url.startsWith('file://') ||
        url.startsWith('/data/user/') ||
        url.startsWith('/storage/')) {
      final path = url.replaceFirst('file://', '');
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(LucideIcons.image),
      );
    }

    final fullUrl = url.startsWith('/media/')
        ? 'https://api.otlob-egy.online$url'
        : url;

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(LucideIcons.image),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final bool hasExistingIcon = widget.vertical?['iconUrl'] != null;
      if (_selectedIcon == null && !hasExistingIcon) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.fieldRequired;
        });
        return;
      }

      Navigator.pop(context, {
        'name': _nameController.text,
        'nameAr': _nameArController.text.isNotEmpty
            ? _nameArController.text
            : null,
        'isActive': _isActive,
        'sortOrder': num.tryParse(_sortOrderController.text) ?? 0,
        'iconFile': _selectedIcon,
      });
    }
  }
}

