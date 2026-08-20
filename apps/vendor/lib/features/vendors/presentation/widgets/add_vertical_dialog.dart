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

  Future<void> _pickIcon(BuildContext ctx) async {
    try {
      // Small delay to ensure dialog animations don't interfere with picker
      await Future.delayed(const Duration(milliseconds: 200));

      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _selectedIcon = XFile(result.files.single.path!));
      }
    } catch (e) {
      debugPrint('AddVerticalDialog _pickIcon Error: $e');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(ctx)!.failedToPickImage),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isEdit = widget.vertical != null;

    return DialogScaffold(child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? size.width : 420),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEdit ? LucideIcons.edit3 : LucideIcons.layers,
                        color: AppColors.primary,
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? AppLocalizations.of(context)!.editBusinessType
                                : AppLocalizations.of(context)!.addBusinessType,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.x,
                        
                        size: 16,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Picker
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.businessTypeIcon,
                              style: const TextStyle(
                                fontSize: 13,
                                
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Stack(
                            children: [
                              Builder(
                                builder: (imgCtx) => GestureDetector(
                                  onTap: () => _pickIcon(imgCtx),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: _selectedIcon != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: _buildImage(
                                            widget.vertical!['iconUrl'],
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              LucideIcons.image,
                                              size: 32,
                                              color: AppColors.textMuted
                                                  .withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.uploadIcon,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                              if (_selectedIcon != null ||
                                  widget.vertical?['iconUrl'] != null)
                                PositionedDirectional(
                                  end: -4,
                                  top: -4,
                                  child: IconButton(
                                    onPressed: () =>
                                        setState(() => _selectedIcon = null),
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
                        const SizedBox(height: 24),

                        _buildTextField(
                          controller: _nameController,
                          label: AppLocalizations.of(context)!.nameEn,
                          hint: 'e.g. Restaurants',
                          icon: LucideIcons.type,
                          validator: (v) => v?.isEmpty ?? true
                              ? AppLocalizations.of(context)!.fieldRequired
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _nameArController,
                          label: AppLocalizations.of(context)!.nameAr,
                          hint: 'مثال: مطاعم',
                          icon: LucideIcons.languages,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _sortOrderController,
                          label: AppLocalizations.of(context)!.sortOrder,
                          hint: '0',
                          icon: LucideIcons.listOrdered,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildSwitchTile(
                          label: AppLocalizations.of(context)!.activeStatus,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.visibilityForVendors,
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.01),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (btnCtx) => ElevatedButton(
                        onPressed: _isSaving ? null : () => _submit(btnCtx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        minimumSize: const Size(80, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEdit
                            ? AppLocalizations.of(context)!.update
                            : AppLocalizations.of(context)!.save,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
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
          validator: validator,
          keyboardType: keyboardType,
          textAlign: textAlign,
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
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

    // Prepend base URL for relative media paths from the server
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

  void _submit(BuildContext ctx) {
    if (_formKey.currentState?.validate() ?? false) {
      // Check if icon is provided (required)
      final bool hasExistingIcon = widget.vertical?['iconUrl'] != null;
      if (_selectedIcon == null && !hasExistingIcon) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(ctx)!.fieldRequired),
            backgroundColor: AppColors.error,
          ),
        );
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

