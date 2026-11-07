import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/vendors/presentation/vendor_members_provider.dart';
import '../../../l10n/l10n_error_helper.dart';

class VendorMembersScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorMembersScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  ConsumerState<VendorMembersScreen> createState() =>
      _VendorMembersScreenState();
}

class _VendorMembersScreenState extends ConsumerState<VendorMembersScreen> {
  List<dynamic> _branches = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await ref
          .read(adminVendorsRepositoryProvider)
          .getBranches(widget.vendorId);
      if (mounted && branches is List) {
        setState(() {
          _branches = branches;
        });
      }
    } catch (_) {}
  }

  String? _resolveBranchName(dynamic member, bool isAr) {
    final branchObj = member['branch'] ?? member['vendorBranch'];
    if (branchObj is Map) {
      final name = isAr
          ? (branchObj['nameAr'] ?? branchObj['name'])
          : (branchObj['name'] ?? branchObj['nameAr']);
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    }
    final branchId = member['branchId']?.toString();
    if (branchId != null && branchId.isNotEmpty) {
      for (final b in _branches) {
        if (b is Map && b['id']?.toString() == branchId) {
          final name = isAr
              ? (b['nameAr'] ?? b['name'])
              : (b['name'] ?? b['nameAr']);
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
      return branchId;
    }
    return null;
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return const Color(0xFFD97706); // Amber
      case 'MANAGER':
        return const Color(0xFF8B5CF6); // Purple
      case 'STAFF':
      default:
        return AppColors.info; // Blue
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return LucideIcons.crown;
      case 'MANAGER':
        return LucideIcons.shieldCheck;
      case 'STAFF':
      default:
        return LucideIcons.userCheck;
    }
  }

  String _getRoleLabel(String role, AppLocalizations l10n, bool isAr) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return isAr ? 'مالك المتجر' : l10n.owner;
      case 'MANAGER':
        return isAr ? 'مدير' : l10n.manager;
      case 'STAFF':
      default:
        return isAr ? 'عضو طاقم' : l10n.staff;
    }
  }

  Future<void> _showAddMemberDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final identifierController = TextEditingController();
    String selectedRole = 'STAFF';
    String? selectedBranchId;
    String? errorMessage;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.userPlus,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'إضافة عضو جديد' : 'Add Team Member',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.vendorName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(LucideIcons.x, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: identifierController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'البريد الإلكتروني أو رقم الهاتف'
                          : 'Email or Phone Number',
                      hintText: isAr
                          ? 'user@example.com / 010...'
                          : 'user@example.com / +2010...',
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الدور الوظيفي' : 'Role',
                      prefixIcon: const Icon(LucideIcons.shield, size: 18),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'OWNER',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.crown, size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Text(isAr ? 'مالك المتجر' : l10n.owner),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'MANAGER',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 8),
                            Text(isAr ? 'مدير' : l10n.manager),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'STAFF',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.userCheck, size: 16, color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(isAr ? 'عضو طاقم' : l10n.staff),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedBranchId,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'الفرع المخصص (اختياري)'
                          : 'Assigned Branch (Optional)',
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(isAr ? 'جميع الفروع' : 'All Branches'),
                      ),
                      ..._branches.whereType<Map>().map((b) {
                        final id = b['id']?.toString();
                        final name = (isAr
                                ? (b['nameAr'] ?? b['name'])
                                : (b['name'] ?? b['nameAr']))
                            ?.toString() ??
                            '';
                        return DropdownMenuItem<String?>(
                          value: id,
                          child: Text(name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedBranchId = val);
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final identifier = identifierController.text.trim();
                                if (identifier.isEmpty) {
                                  setDialogState(() {
                                    errorMessage = l10n.requiredField;
                                  });
                                  return;
                                }
                                setDialogState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });
                                try {
                                  await ref
                                      .read(
                                        vendorMembersProvider(widget.vendorId).notifier,
                                      )
                                      .addMember(
                                        identifier: identifier,
                                        role: selectedRole,
                                        branchId: selectedBranchId,
                                      );
                                  if (dialogCtx.mounted) {
                                    Navigator.pop(dialogCtx);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.common_success_resource_created,
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (dialogCtx.mounted) {
                                    setDialogState(() {
                                      isSubmitting = false;
                                      errorMessage = L10nErrorHelper.translate(context, e);
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                isAr ? 'إضافة' : l10n.create,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditMemberDialog(dynamic member) async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final memberId = member['id']?.toString() ?? '';
    final user = member['user'] ?? {};
    final userName = (user['name'] ?? l10n.unknown).toString();
    final userEmail = (user['email'] ?? '').toString();
    String selectedRole = (member['role'] ?? 'STAFF').toString();
    final initialBranchId =
        (member['branchId'] ?? (member['branch'] is Map ? member['branch']['id'] : null))
            ?.toString();
    final hasMatchingBranch = initialBranchId != null &&
        _branches.any((b) => b is Map && b['id']?.toString() == initialBranchId);
    String? selectedBranchId = hasMatchingBranch ? initialBranchId : null;
    String? errorMessage;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.pencil,
                          color: AppColors.info,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'تعديل عضو الفريق' : 'Edit Team Member',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(LucideIcons.x, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mail, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userEmail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الدور الوظيفي' : 'Role',
                      prefixIcon: const Icon(LucideIcons.shield, size: 18),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'OWNER',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.crown, size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Text(isAr ? 'مالك المتجر' : l10n.owner),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'MANAGER',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 8),
                            Text(isAr ? 'مدير' : l10n.manager),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'STAFF',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.userCheck, size: 16, color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(isAr ? 'عضو طاقم' : l10n.staff),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedBranchId,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الفرع المخصص' : 'Assigned Branch',
                      prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(isAr ? 'جميع الفروع' : 'All Branches'),
                      ),
                      ..._branches.whereType<Map>().map((b) {
                        final id = b['id']?.toString();
                        final name = (isAr
                                ? (b['nameAr'] ?? b['name'])
                                : (b['name'] ?? b['nameAr']))
                            ?.toString() ??
                            '';
                        return DropdownMenuItem<String?>(
                          value: id,
                          child: Text(name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedBranchId = val);
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setDialogState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });
                                try {
                                  await ref
                                      .read(
                                        vendorMembersProvider(widget.vendorId).notifier,
                                      )
                                      .updateRole(
                                        memberId,
                                        selectedRole,
                                        branchId: selectedBranchId,
                                        updateBranch: true,
                                      );
                                  if (dialogCtx.mounted) {
                                    Navigator.pop(dialogCtx);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.roleUpdatedSuccessfully,
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (dialogCtx.mounted) {
                                    setDialogState(() {
                                      isSubmitting = false;
                                      errorMessage = L10nErrorHelper.translate(context, e);
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                l10n.update,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemoveMember(dynamic member) async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final memberId = member['id']?.toString() ?? '';
    final userName = (member['user']?['name'] ?? l10n.unknown).toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.userMinus, size: 20, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(isAr ? 'إزالة العضو' : 'Remove Member'),
            ),
          ],
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من إزالة "$userName" من طاقم عمل "${widget.vendorName}"؟'
              : 'Are you sure you want to remove "$userName" from the team of "${widget.vendorName}"?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(vendorMembersProvider(widget.vendorId).notifier)
          .removeMember(memberId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.common_success_resource_deleted),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10nErrorHelper.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(vendorMembersProvider(widget.vendorId));

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: isAr ? 'رجوع' : 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAr ? 'فريق العمل' : 'Team Members',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.store,
                  size: 13,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.vendorName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () {
              _loadBranches();
              ref
                  .read(vendorMembersProvider(widget.vendorId).notifier)
                  .fetchMembers();
            },
            icon: const Icon(LucideIcons.refreshCw, size: 18),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _showAddMemberDialog,
                icon: const Icon(LucideIcons.userPlus, size: 16),
                label: Text(isAr ? 'إضافة عضو جديد' : 'Add Team Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top action & stats bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Team members badge count
                  state.maybeWhen(
                    data: (members) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${members.length} ${isAr ? 'أعضاء في الفريق' : 'members'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const Spacer(),
                  if (isMobile) ...[
                    ElevatedButton.icon(
                      onPressed: _showAddMemberDialog,
                      icon: const Icon(LucideIcons.userPlus, size: 16),
                      label: Text(isAr ? 'إضافة عضو' : 'Add Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Members Content
            Expanded(
              child: state.when(
                data: (members) {
                  if (members.isEmpty) {
                    return EmptyStateWidget(
                      icon: LucideIcons.users,
                      title: isAr
                          ? 'لا يوجد أعضاء في الفريق حالياً'
                          : 'No Team Members Yet',
                      subtitle: isAr
                          ? 'قم بإضافة مدراء وموظفين للمساعدة في استلام وإدارة طلبات "${widget.vendorName}"'
                          : 'Add managers and staff to help operate and manage orders for "${widget.vendorName}"',
                      actionLabel: isAr ? 'إضافة عضو جديد' : 'Add First Member',
                      onActionPressed: _showAddMemberDialog,
                    );
                  }

                  // Filter members if search query exists
                  final filteredMembers = members.where((m) {
                    final role = (m['role'] ?? '').toString();
                    if (_selectedRoleFilter != 'ALL' &&
                        role.toUpperCase() != _selectedRoleFilter) {
                      return false;
                    }
                    if (_searchQuery.trim().isEmpty) return true;
                    final q = _searchQuery.trim().toLowerCase();
                    final user = m['user'];
                    final name = (user?['name'] ?? '').toString().toLowerCase();
                    final email = (user?['email'] ?? '').toString().toLowerCase();
                    final phone = (user?['phone'] ?? '').toString().toLowerCase();
                    final branchName = (_resolveBranchName(m, isAr) ?? '').toLowerCase();
                    return name.contains(q) ||
                        email.contains(q) ||
                        phone.contains(q) ||
                        branchName.contains(q);
                  }).toList();

                  return Column(
                    children: [
                      // Search field & Role filter bar
                      if (members.length > 2) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 24,
                            12,
                            isMobile ? 16 : 24,
                            8,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                            decoration: InputDecoration(
                              hintText: isAr
                                  ? 'البحث بالاسم أو البريد أو الهاتف...'
                                  : 'Search by name, email, or phone...',
                              prefixIcon: const Icon(LucideIcons.search, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(alpha: 0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Filter results
                      Expanded(
                        child: filteredMembers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.searchX,
                                        size: 48,
                                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isAr ? 'لم نجد أي عضو يطابق البحث' : 'No matching members found',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isAr
                                            ? 'جرّب البحث بكلمات أخرى أو امسح البحث'
                                            : 'Try searching with different keywords',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        child: Text(isAr ? 'مسح البحث' : 'Clear search'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(isMobile ? 16 : 24),
                                itemCount: filteredMembers.length,
                                itemBuilder: (context, index) {
                                  final member = filteredMembers[index];
                                  final user = member['user'];
                                  if (user == null) return const SizedBox.shrink();

                                  final memberId = member['id'];
                                  final currentRole = (member['role'] ?? 'STAFF').toString();
                                  final branchName = _resolveBranchName(member, isAr);
                                  final userName = (user['name'] ?? l10n.unknown).toString();
                                  final userEmail = (user['email'] ?? '').toString();
                                  final userPhone = (user['phone'] ?? '').toString();
                                  final roleColor = _getRoleColor(currentRole);
                                  final roleIcon = _getRoleIcon(currentRole);
                                  final roleLabel = _getRoleLabel(currentRole, l10n, isAr);
                                  final initial = userName.trim().isNotEmpty
                                      ? userName.trim()[0].toUpperCase()
                                      : 'U';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? theme.colorScheme.surface : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.dividerColor.withValues(alpha: 0.12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Avatar with role accent border
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: roleColor.withValues(alpha: 0.12),
                                                  border: Border.all(
                                                    color: roleColor.withValues(alpha: 0.3),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: (user['avatar'] != null &&
                                                        user['avatar'].toString().isNotEmpty)
                                                    ? ClipOval(
                                                        child: Image.network(
                                                          user['avatar'].toString(),
                                                          width: 44,
                                                          height: 44,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Text(
                                                            initial,
                                                            style: TextStyle(
                                                              color: roleColor,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Text(
                                                        initial,
                                                        style: TextStyle(
                                                          color: roleColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      userName,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                    if (userEmail.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            LucideIcons.mail,
                                                            size: 13,
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                          const SizedBox(width: 5),
                                                          Expanded(
                                                            child: Text(
                                                              userEmail,
                                                              style: theme.textTheme.bodySmall?.copyWith(
                                                                color: theme.colorScheme.onSurfaceVariant,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                    if (userPhone.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            LucideIcons.phone,
                                                            size: 13,
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                          const SizedBox(width: 5),
                                                          Expanded(
                                                            child: Text(
                                                              userPhone,
                                                              style: theme.textTheme.bodySmall?.copyWith(
                                                                color: theme.colorScheme.onSurfaceVariant,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              // Edit & Delete actions
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    tooltip: l10n.edit,
                                                    icon: const Icon(LucideIcons.pencil, size: 17),
                                                    onPressed: () => _showEditMemberDialog(member),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  IconButton(
                                                    tooltip: l10n.delete,
                                                    icon: const Icon(
                                                      LucideIcons.trash2,
                                                      size: 17,
                                                      color: AppColors.error,
                                                    ),
                                                    onPressed: () => _confirmRemoveMember(member),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Divider(
                                            height: 1,
                                            color: theme.dividerColor.withValues(alpha: 0.08),
                                          ),
                                          const SizedBox(height: 10),
                                          // Bottom chips: Role & Branch
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              // Role Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: roleColor.withValues(alpha: 0.25),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(roleIcon, size: 13, color: roleColor),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      roleLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: roleColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Branch Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                                                      : theme.scaffoldBackgroundColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: theme.dividerColor.withValues(alpha: 0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      branchName != null
                                                          ? LucideIcons.mapPin
                                                          : LucideIcons.store,
                                                      size: 13,
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      branchName ?? (isAr ? 'جميع الفروع' : 'All Branches'),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          L10nErrorHelper.translate(context, e),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(vendorMembersProvider(widget.vendorId).notifier)
                                .fetchMembers();
                          },
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: Text(l10n.retry),
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
    );
  }
}
