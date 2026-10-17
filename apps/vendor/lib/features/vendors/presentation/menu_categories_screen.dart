import 'dart:io';
import 'package:flutter/material.dart';
import 'package:api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:core/core.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:data/data.dart';

class MenuCategoriesScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final bool isAdmin;

  const MenuCategoriesScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.isAdmin = false,
  });

  @override
  ConsumerState<MenuCategoriesScreen> createState() =>
      _MenuCategoriesScreenState();
}

class _MenuCategoriesScreenState extends ConsumerState<MenuCategoriesScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _filteredCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final categories = await ref
        .read(adminVendorsRepositoryProvider)
        .getMenuCategories(widget.vendorId);
    if (mounted) {
      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories.where((cat) {
          final name = (cat['name'] ?? '').toString().toLowerCase();
          final nameAr = (cat['nameAr'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || nameAr.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.menuCategories,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            widget.vendorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCategoryDialog(),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(AppLocalizations.of(context)!.add),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Search Bar
                DashboardSearchBar(
                  controller: _searchController,
                  onChanged: _filterCategories,
                  onClear: () => _filterCategories(''),
                ),
                const SizedBox(height: 24),

                // List Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredCategories.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _filteredCategories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            return _buildCategoryCard(category);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: const Icon(
              LucideIcons.list,
              size: 48,
              
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noCategoriesFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.menuCategoriesDescription,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  (category['iconUrl'] ?? category['icon']) != null &&
                      (category['iconUrl'] ?? category['icon'])
                          .toString()
                          .isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ImageUtils.formatImageUrl(category['iconUrl'] ?? category['icon'])}?t=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              LucideIcons.layers,
                              color: AppColors.primary,
                              size: 20,
                            ),
                      ),
                    )
                  : const Icon(
                      LucideIcons.layers,
                      color: AppColors.primary,
                      size: 20,
                    ),
            ),
            title: Text(
              category['name'] ?? AppLocalizations.of(context)!.unnamedCategory,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                category['nameAr'] ?? '',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionItem(
                  context: context,
                  icon: LucideIcons.edit3,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                  label: AppLocalizations.of(context)!.edit,
                  onPressed: () => _showAddCategoryDialog(category: category),
                ),
                const SizedBox(width: 8),
                _buildActionItem(
                  context: context,
                  icon: LucideIcons.trash2,
                  color: AppColors.error,
                  label: AppLocalizations.of(context)!.delete,
                  onPressed: () => _confirmDelete(category),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog({dynamic category}) async {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final nameArController = TextEditingController(
      text: category?['nameAr'] ?? '',
    );
    PlatformFile? selectedIcon;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEdit ? LucideIcons.edit3 : LucideIcons.plusCircle,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit
                          ? AppLocalizations.of(context)!.editCategory
                          : AppLocalizations.of(context)!.newCategory,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                padding: const EdgeInsets.all(24),
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon Picker
                          GestureDetector(
                            onTap: () async {
                              try {
                                final result = await FilePicker.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  setDialogState(
                                    () => selectedIcon = result.files.first,
                                  );
                                }
                              } catch (e) {
                                debugPrint('Error picking icon: $e');
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: selectedIcon != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: selectedIcon!.bytes != null
                                          ? Image.memory(
                                              selectedIcon!.bytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(selectedIcon!.path!),
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : (category?['iconUrl'] ??
                                            category?['icon']) !=
                                        null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        '${ImageUtils.formatImageUrl(category?['iconUrl'] ?? category?['icon'])}?t=${DateTime.now().millisecondsSinceEpoch}',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      LucideIcons.imagePlus,
                                      color: AppColors.primary,
                                      size: 30,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.categoryIcon,
                            style: const TextStyle(
                              fontSize: 12,
                              
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDialogTextField(
                            controller: nameController,
                            label: AppLocalizations.of(context)!.nameEn,
                            hint: 'e.g. Main Dishes',
                            icon: LucideIcons.type,
                          ),
                          const SizedBox(height: 20),
                          _buildDialogTextField(
                            controller: nameArController,
                            label: AppLocalizations.of(context)!.nameAr,
                            hint: 'مثال: الأطباق الرئيسية',
                            icon: LucideIcons.languages,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
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
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          bool success;
                          String? categoryId = category?['id'];

                          if (isEdit) {
                            success = (await ref
                                .read(adminVendorsRepositoryProvider)
                                .updateMenuCategory(
                                  widget.vendorId,
                                  categoryId!,
                                  UpdateMenuCategoryDto((b) {
                                    b.name = nameController.text;
                                    b.nameAr = nameArController.text;
                                    b.isActive = category?['isActive'] ?? true;
                                    if (category?['description'] != null) b.description = category?['description'];
                                    if (category?['descriptionAr'] != null) b.descriptionAr = category?['descriptionAr'];
                                  }),
                                  isAdmin: widget.isAdmin,
                                )) != null;
                          } else {
                            success = (await ref
                                .read(adminVendorsRepositoryProvider)
                                .createMenuCategory(
                                  widget.vendorId, 
                                  CreateMenuCategoryDto((b) {
                                    b.name = nameController.text;
                                    b.nameAr = nameArController.text;
                                    b.isActive = true;
                                  }),
                                  isAdmin: widget.isAdmin,
                                )) != null;
                          }

                          if (success && selectedIcon != null) {
                            if (!isEdit) {
                              final categories = await ref
                                  .read(adminVendorsRepositoryProvider)
                                  .getMenuCategories(widget.vendorId);
                              final newCat = categories.firstWhere(
                                (c) => c['name'] == nameController.text,
                              );
                              categoryId = newCat['id'];
                            }

                            final iconBytes =
                                selectedIcon!.bytes ??
                                await File(selectedIcon!.path!).readAsBytes();

                            await ref
                                .read(adminVendorsRepositoryProvider)
                                .uploadMenuCategoryIcon(
                                  widget.vendorId,
                                  categoryId!,
                                  iconBytes.toList(),
                                  selectedIcon!.name,
                                  isAdmin: widget.isAdmin,
                                );
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context, success);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ErrorUtils.translate(
                                  context,
                                  isEdit
                                      ? 'common.success.resource_updated'
                                      : 'common.success.resource_created',
                                ),
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ErrorUtils.translate(context, e),
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit
                            ? AppLocalizations.of(context)!.update
                            : AppLocalizations.of(context)!.add,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) _fetchCategories();
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
        TextField(
          controller: controller,
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

  void _confirmDelete(dynamic category) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.deleteCategory,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.deleteCategoryConfirm(
                  category['name'] ??
                      AppLocalizations.of(context)!.unnamedCategory,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final response = await ref
                              .read(adminVendorsRepositoryProvider)
                              .deleteMenuCategory(
                                widget.vendorId,
                                category['id'],
                                isAdmin: widget.isAdmin,
                              );
                          final success = response != null;
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (success) {
                            _fetchCategories();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.common_success_resource_deleted,
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ErrorUtils.translate(context, e),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

