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

  @override
  void initState() {
    super.initState();
    _loadBranches();
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

  Future<void> _showAddMemberDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
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
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.userPlus, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAr ? 'إضافة عضو جديد' : 'Add Team Member',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: identifierController,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'البريد الإلكتروني أو رقم الهاتف'
                          : 'Email or Phone Number',
                      hintText: isAr
                          ? 'user@example.com / 010...'
                          : 'user@example.com / +2010...',
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الدور الوظيفي' : 'Role',
                      prefixIcon: const Icon(LucideIcons.shield, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'OWNER', child: Text(l10n.owner)),
                      DropdownMenuItem(
                        value: 'MANAGER',
                        child: Text(l10n.manager),
                      ),
                      DropdownMenuItem(value: 'STAFF', child: Text(l10n.staff)),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          isAr ? 'جميع الفروع' : 'All Branches',
                        ),
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
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(dialogCtx),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final identifier =
                                    identifierController.text.trim();
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
                                        vendorMembersProvider(
                                          widget.vendorId,
                                        ).notifier,
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
                                      errorMessage = L10nErrorHelper.translate(
                                        context,
                                        e,
                                      );
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.create),
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
    final memberId = member['id']?.toString() ?? '';
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
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.edit3, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'تعديل الدور والفرع'
                              : 'Edit Member Role & Branch',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الدور الوظيفي' : 'Role',
                      prefixIcon: const Icon(LucideIcons.shield, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'OWNER', child: Text(l10n.owner)),
                      DropdownMenuItem(
                        value: 'MANAGER',
                        child: Text(l10n.manager),
                      ),
                      DropdownMenuItem(value: 'STAFF', child: Text(l10n.staff)),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          isAr ? 'جميع الفروع' : 'All Branches',
                        ),
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
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(dialogCtx),
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
                                        vendorMembersProvider(
                                          widget.vendorId,
                                        ).notifier,
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
                                      errorMessage = L10nErrorHelper.translate(
                                        context,
                                        e,
                                      );
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.update),
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
        title: Text(isAr ? 'إزالة العضو' : 'Remove Member'),
        content: Text(
          isAr
              ? 'هل أنت متأكد من إزالة "$userName" من طاقم العمل؟'
              : 'Are you sure you want to remove "$userName" from the team?',
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
    final state = ref.watch(vendorMembersProvider(widget.vendorId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppColors.info.withValues(alpha: 0.05),
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.users,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.staffMembership,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.vendorName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddMemberDialog,
                      icon: const Icon(LucideIcons.userPlus, size: 18),
                      label: Text(isAr ? 'إضافة عضو' : 'Add Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.refresh,
                      onPressed: () {
                        _loadBranches();
                        ref
                            .read(
                              vendorMembersProvider(widget.vendorId).notifier,
                            )
                            .fetchMembers();
                      },
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: state.when(
                    data: (members) {
                      if (members.isEmpty) {
                        return Center(
                          child: Text(l10n.noStaffFound),
                        );
                      }
                      return ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final user = member['user'];
                          if (user == null) return const SizedBox.shrink();

                          final memberId = member['id'];
                          final currentRole = member['role'];
                          final branchName = _resolveBranchName(member, isAr);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    backgroundImage: user['avatar'] != null
                                        ? NetworkImage(user['avatar'])
                                        : null,
                                    child: user['avatar'] == null
                                        ? Text(
                                            (user['name'] ?? l10n.unknown)[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'] ?? l10n.unknown,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if ((user['email'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Text(
                                            user['email'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        if (branchName != null) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.info.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  LucideIcons.mapPin,
                                                  size: 12,
                                                  color: AppColors.info,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    branchName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.info,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentRole,
                                        icon: const Icon(
                                          LucideIcons.chevronDown,
                                          size: 16,
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            value: 'OWNER',
                                            child: Text(l10n.owner),
                                          ),
                                          DropdownMenuItem(
                                            value: 'MANAGER',
                                            child: Text(l10n.manager),
                                          ),
                                          DropdownMenuItem(
                                            value: 'STAFF',
                                            child: Text(l10n.staff),
                                          ),
                                        ],
                                        onChanged: (newRole) async {
                                          if (newRole != null &&
                                              newRole != currentRole) {
                                            try {
                                              await ref
                                                  .read(
                                                    vendorMembersProvider(
                                                      widget.vendorId,
                                                    ).notifier,
                                                  )
                                                  .updateRole(
                                                    memberId,
                                                    newRole,
                                                    branchId: member['branchId']
                                                        ?.toString(),
                                                  );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n.roleUpdatedSuccessfully,
                                                    ),
                                                    backgroundColor:
                                                        AppColors.success,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      L10nErrorHelper.translate(
                                                        context,
                                                        e,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        AppColors.error,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: l10n.edit,
                                    onPressed: () =>
                                        _showEditMemberDialog(member),
                                    icon: const Icon(
                                      LucideIcons.edit3,
                                      size: 18,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.delete,
                                    onPressed: () =>
                                        _confirmRemoveMember(member),
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(
                      child: Text(L10nErrorHelper.translate(context, e)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
