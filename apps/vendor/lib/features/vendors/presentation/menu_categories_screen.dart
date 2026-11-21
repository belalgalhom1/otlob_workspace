import 'dart:io';
import 'package:flutter/material.dart';
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
  List<dynamic> _branches = [];
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
    try {
      final results = await Future.wait([
        ref.read(adminVendorsRepositoryProvider).getMenuCategories(widget.vendorId),
        ref.read(adminVendorsRepositoryProvider).getBranches(widget.vendorId),
      ]);
      final categoriesRaw = results[0];
      final branchesRaw = results[1];
      final branchesList = branchesRaw is List
          ? List<dynamic>.from(branchesRaw)
          : (branchesRaw is Map && branchesRaw['data'] is List
              ? List<dynamic>.from(branchesRaw['data'] as List)
              : const <dynamic>[]);
      final categoriesList = categoriesRaw is List
          ? List<dynamic>.from(categoriesRaw)
          : (categoriesRaw is Map && categoriesRaw['data'] is List
              ? List<dynamic>.from(categoriesRaw['data'] as List)
              : const <dynamic>[]);
      if (mounted) {
        setState(() {
          _categories = categoriesList;
          _filteredCategories = _categories;
          _branches = branchesList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? LucideIcons.arrowRight
                            : LucideIcons.arrowLeft,
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
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.04,
            ),
            blurRadius: 14,
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
                        ImageUtils.formatImageUrl(
                          category['iconUrl'] ?? category['icon'],
                        ),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category['nameAr'] != null && category['nameAr'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      category['nameAr'].toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (category['branchAvailabilityMode'] == 'SPECIFIC') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.gitBranch, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.specificBranches,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
    String branchAvailabilityMode = category?['branchAvailabilityMode']?.toString() ?? 'ALL';
    final Set<String> selectedBranchIds = {};
    if (category?['branchAvailability'] is List) {
      for (final row in category['branchAvailability']) {
        if (row is Map && row['branchId'] != null) {
          selectedBranchIds.add(row['branchId'].toString());
        }
      }
    }

    String? errorMessage;
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final l10n = AppLocalizations.of(ctx)!;
          final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
          final theme = Theme.of(ctx);

          return AppDialog(
            maxWidth: 500,
            canPop: !isSubmitting,
            header: AppDialogHeader(
              icon: isEdit ? LucideIcons.edit3 : LucideIcons.plusCircle,
              title: isEdit ? l10n.editCategory : l10n.newCategory,
              subtitle: widget.vendorName,
              isCloseDisabled: isSubmitting,
              onClose: () => Navigator.pop(dialogCtx),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: isSubmitting
                            ? null
                            : () async {
                                try {
                                  final picked = await FilePicker.pickFiles(
                                    type: FileType.image,
                                    allowMultiple: false,
                                  );
                                  if (picked != null &&
                                      picked.files.isNotEmpty) {
                                    setDialogState(
                                      () => selectedIcon = picked.files.first,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error picking icon: $e');
                                }
                              },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppDialogStyles.subtleSurfaceColor(ctx),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selectedIcon != null
                                  ? AppColors.primary
                                  : AppDialogStyles.borderColor(ctx),
                              width: selectedIcon != null ? 1.8 : 1.2,
                            ),
                          ),
                          child: selectedIcon != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
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
                              : (category?['iconUrl'] ?? category?['icon']) !=
                                      null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        '${ImageUtils.formatImageUrl(category?['iconUrl'] ?? category?['icon'])}?t=${DateTime.now().millisecondsSinceEpoch}',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          LucideIcons.imagePlus,
                                          color: AppColors.primary,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isAr ? 'اختيار' : 'Upload',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.categoryIcon,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppFieldLabel(
                  label: l10n.nameEn,
                  isRequired: true,
                  languageTag: 'EN',
                  languageTagColor: AppColors.info,
                ),
                TextField(
                  controller: nameController,
                  enabled: !isSubmitting,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: 'e.g. Main Dishes',
                    icon: LucideIcons.type,
                  ),
                ),
                const SizedBox(height: 16),
                AppFieldLabel(
                  label: l10n.nameAr,
                  languageTag: 'عربي',
                  languageTagColor: AppColors.success,
                ),
                TextField(
                  controller: nameArController,
                  enabled: !isSubmitting,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: 'مثال: الأطباق الرئيسية',
                    icon: LucideIcons.languages,
                  ),
                ),
                const SizedBox(height: 18),
                AppDialogSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.gitBranch,
                            size: 17,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.branchAvailability,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branchAvailabilityMode == 'ALL'
                            ? l10n.allBranchesHint
                            : l10n.specificBranchesHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment<String>(
                              value: 'ALL',
                              label: Text(
                                l10n.allBranches,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                            ButtonSegment<String>(
                              value: 'SPECIFIC',
                              label: Text(
                                l10n.specificBranches,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                          selected: {branchAvailabilityMode},
                          onSelectionChanged: isSubmitting
                              ? null
                              : (val) {
                                  setDialogState(() {
                                    errorMessage = null;
                                    branchAvailabilityMode = val.first;
                                    if (branchAvailabilityMode == 'SPECIFIC' &&
                                        selectedBranchIds.isEmpty &&
                                        _branches.isNotEmpty) {
                                      selectedBranchIds.addAll(
                                        _branches.map((b) => b['id'].toString()),
                                      );
                                    }
                                  });
                                },
                        ),
                      ),
                      if (branchAvailabilityMode == 'SPECIFIC') ...[
                        const SizedBox(height: 12),
                        if (_branches.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.noBranchesAvailable,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ..._branches.map((branch) {
                            final id = branch['id']?.toString() ?? '';
                            final bName = (isAr
                                    ? branch['nameAr']
                                    : branch['name']) ??
                                branch['name'] ??
                                id;
                            final isChecked = selectedBranchIds.contains(id);
                            return CheckboxListTile(
                              value: isChecked,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primary,
                              checkColor: AppColors.onPrimary,
                              title: Text(
                                bName.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          selectedBranchIds.add(id);
                                        } else {
                                          selectedBranchIds.remove(id);
                                        }
                                      });
                                    },
                            );
                          }),
                      ],
                    ],
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AppDialogErrorBanner(message: errorMessage!),
                ],
              ],
            ),
            footer: AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.pop(dialogCtx),
              confirmLabel: isEdit ? l10n.update : l10n.add,
              confirmIcon: isEdit ? LucideIcons.save : LucideIcons.plus,
              isLoading: isSubmitting,
              onConfirm: () async {
                if (branchAvailabilityMode == 'SPECIFIC' &&
                    selectedBranchIds.isEmpty) {
                  setDialogState(() {
                    errorMessage = l10n.branchAvailabilityRequired;
                  });
                  return;
                }

                setDialogState(() {
                  isSubmitting = true;
                  errorMessage = null;
                });

                try {
                  bool success;
                  String? categoryId = category?['id'];

                  if (isEdit) {
                    success = (await ref
                            .read(adminVendorsRepositoryProvider)
                            .updateMenuCategoryRaw(
                              widget.vendorId,
                              categoryId!,
                              name: nameController.text.trim(),
                              nameAr: nameArController.text.trim(),
                              branchAvailabilityMode: branchAvailabilityMode,
                              branchIds: branchAvailabilityMode == 'SPECIFIC'
                                  ? selectedBranchIds.toList()
                                  : [],
                              isAdmin: widget.isAdmin,
                            )) !=
                        null;
                  } else {
                    final res = await ref
                        .read(adminVendorsRepositoryProvider)
                        .createMenuCategoryRaw(
                          widget.vendorId,
                          name: nameController.text.trim(),
                          nameAr: nameArController.text.trim(),
                          branchAvailabilityMode: branchAvailabilityMode,
                          branchIds: branchAvailabilityMode == 'SPECIFIC'
                              ? selectedBranchIds.toList()
                              : [],
                          isAdmin: widget.isAdmin,
                        );
                    success = res != null;
                    if (res is Map && res['id'] != null) {
                      categoryId = res['id']?.toString();
                    }
                  }

                  if (success && selectedIcon != null) {
                    if (!isEdit && categoryId == null) {
                      final categoriesRaw = await ref
                          .read(adminVendorsRepositoryProvider)
                          .getMenuCategories(widget.vendorId);
                      final List<dynamic> categoriesList = categoriesRaw is List
                          ? categoriesRaw
                          : (categoriesRaw is Map &&
                                  categoriesRaw['data'] is List
                              ? categoriesRaw['data'] as List
                              : const []);
                      final newCat = categoriesList.firstWhere(
                        (c) =>
                            c is Map && c['name'] == nameController.text.trim(),
                        orElse: () => null,
                      );
                      if (newCat != null && newCat is Map) {
                        categoryId = newCat['id']?.toString();
                      }
                    }

                    if (categoryId != null) {
                      final iconBytes = selectedIcon!.bytes ??
                          await File(selectedIcon!.path!).readAsBytes();

                      await ref
                          .read(adminVendorsRepositoryProvider)
                          .uploadMenuCategoryIcon(
                            widget.vendorId,
                            categoryId,
                            iconBytes.toList(),
                            selectedIcon!.name,
                            isAdmin: widget.isAdmin,
                          );
                    }
                  }

                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx, success);
                  if (mounted) {
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
                  }
                } catch (e) {
                  if (!dialogCtx.mounted) return;
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = ErrorUtils.translate(ctx, e);
                  });
                }
              },
            ),
          );
        },
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        nameController.dispose();
        nameArController.dispose();
      });
    });

    if (result == true) _fetchCategories();
  }

  Future<void> _confirmDelete(dynamic category) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.deleteCategory,
      message: l10n.deleteCategoryConfirm(
        category['name'] ?? l10n.unnamedCategory,
      ),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await ref
          .read(adminVendorsRepositoryProvider)
          .deleteMenuCategory(
            widget.vendorId,
            category['id'],
            isAdmin: widget.isAdmin,
          );
      if (response != null && mounted) {
        _fetchCategories();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.common_success_resource_deleted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

