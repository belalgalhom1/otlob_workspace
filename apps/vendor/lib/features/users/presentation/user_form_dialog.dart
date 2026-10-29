import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/features/users/presentation/user_provider.dart';
import '../../../l10n/l10n_error_helper.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final dynamic user;
  final String? currentUserRole;
  final List<dynamic> vendors;

  const UserFormDialog({
    super.key,
    this.user,
    this.currentUserRole,
    required this.vendors,
  });

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController titleController;
  late TextEditingController titleArController;
  
  bool obscurePassword = true;
  late String selectedRole;
  String? selectedVendorId;
  String? initialVendorId;
  String? initialMemberId;
  String selectedVendorRole = 'STAFF';
  List<String> selectedPermissions = [];

  final List<String> availablePermissions = [
    'MANAGE_ORDERS',
    'MANAGE_PRODUCTS',
    'MANAGE_VENDORS',
    'MANAGE_DRIVERS',
    'MANAGE_CUSTOMERS',
    'MANAGE_TICKETS',
    'MANAGE_CONVERSATIONS',
    'VIEW_STATISTICS',
    'MANAGE_SETTINGS',
    'MANAGE_USERS',
    'VIEW_FINANCIALS',
    'MANAGE_FINANCE',
    'MANAGE_PROMOTIONS',
    'MANAGE_ANNOUNCEMENTS',
    'VIEW_AUDIT_LOGS'
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user?['name']);
    emailController = TextEditingController(text: widget.user?['email']);
    phoneController = TextEditingController(text: widget.user?['phone']);
    passwordController = TextEditingController();
    titleController = TextEditingController(text: widget.user?['title']?.toString() ?? '');
    titleArController = TextEditingController(text: widget.user?['titleAr']?.toString() ?? '');
    
    selectedRole = widget.user?['role'] ?? (widget.currentUserRole == 'ADMIN' ? 'DRIVER' : 'ADMIN');
    
    if (widget.user != null && widget.user['permissions'] != null) {
      selectedPermissions = List<String>.from(widget.user['permissions']);
    }

    if (widget.user != null && widget.user['vendorMemberships'] != null) {
      final memberships = widget.user['vendorMemberships'] as List;
      if (memberships.isNotEmpty) {
        final membership = memberships.first;
        selectedVendorId = (membership['vendorId'] ?? membership['vendor']?['id'])?.toString();
        initialVendorId = selectedVendorId;
        initialMemberId = membership['id']?.toString();
        selectedVendorRole = membership['role'] ?? 'STAFF';
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    titleController.dispose();
    titleArController.dispose();
    super.dispose();
  }

  String _getPermissionName(BuildContext context, String perm) {
    final l10n = AppLocalizations.of(context)!;
    switch (perm) {
      case 'MANAGE_ORDERS': return l10n.perm_manage_orders;
      case 'MANAGE_PRODUCTS': return l10n.perm_manage_products;
      case 'MANAGE_VENDORS': return l10n.perm_manage_vendors;
      case 'MANAGE_DRIVERS': return l10n.perm_manage_drivers;
      case 'MANAGE_CUSTOMERS': return l10n.perm_manage_customers;
      case 'MANAGE_TICKETS': return l10n.perm_manage_tickets;
      case 'MANAGE_CONVERSATIONS': return l10n.perm_manage_conversations;
      case 'VIEW_STATISTICS': return l10n.perm_view_statistics;
      case 'MANAGE_SETTINGS': return l10n.perm_manage_settings;
      case 'MANAGE_USERS': return l10n.perm_manage_users;
      case 'VIEW_FINANCIALS': return l10n.perm_view_financials;
      case 'MANAGE_FINANCE': return l10n.perm_manage_finance;
      case 'MANAGE_PROMOTIONS': return l10n.perm_manage_promotions;
      case 'MANAGE_ANNOUNCEMENTS': return l10n.perm_manage_announcements;
      case 'VIEW_AUDIT_LOGS': return l10n.perm_view_audit_logs;
      default: return perm;
    }
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, String hint, {bool obscure = false, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.user == null ? LucideIcons.userPlus : LucideIcons.user,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.user == null
                          ? AppLocalizations.of(context)!.createNewUser
                          : AppLocalizations.of(context)!.editUserProfile,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildField(
                AppLocalizations.of(context)!.fullName,
                LucideIcons.user,
                nameController,
                'e.g. Ahmed Ali',
              ),
              const SizedBox(height: 16),
              _buildField(
                AppLocalizations.of(context)!.emailAddress,
                LucideIcons.mail,
                emailController,
                'admin@otlob.com',
              ),
              const SizedBox(height: 16),
              _buildField(
                AppLocalizations.of(context)!.phone,
                LucideIcons.phone,
                phoneController,
                '+201100000000',
              ),
              const SizedBox(height: 16),
              _buildField(
                widget.user == null
                    ? AppLocalizations.of(context)!.password
                    : (Localizations.localeOf(context).languageCode == 'ar'
                          ? 'كلمة المرور الجديدة'
                          : 'New Password'),
                LucideIcons.lock,
                passwordController,
                widget.user == null
                    ? '********'
                    : (Localizations.localeOf(context).languageCode == 'ar'
                          ? 'اتركها فارغة للإبقاء على الحالية'
                          : 'Leave blank to keep current'),
                obscure: obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'المسمى الوظيفي (EN)'
                    : 'Job Title (EN)',
                LucideIcons.briefcase,
                titleController,
                'e.g. Sales Manager',
              ),
              const SizedBox(height: 16),
              _buildField(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'المسمى الوظيفي (AR)'
                    : 'Job Title (AR)',
                LucideIcons.briefcase,
                titleArController,
                'e.g. مدير المبيعات',
              ),
              if (widget.currentUserRole != 'ADMIN') ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.accountRole,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.shield, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'SUPER_ADMIN',
                      child: Text(AppLocalizations.of(context)!.superAdmin),
                    ),
                    DropdownMenuItem(
                      value: 'ADMIN',
                      child: Text(AppLocalizations.of(context)!.admin),
                    ),
                    DropdownMenuItem(
                      value: 'VENDOR_MEMBER',
                      child: Text(
                        AppLocalizations.of(context)!.vendorMember,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'DRIVER',
                      child: Text(AppLocalizations.of(context)!.driver),
                    ),
                    DropdownMenuItem(
                      value: 'DRIVER_MANAGER',
                      child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'مدير مناديب' : 'Driver Manager'),
                    ),
                    DropdownMenuItem(
                      value: 'CUSTOMER',
                      child: Text(AppLocalizations.of(context)!.customer),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedRole = v!;
                    });
                  },
                ),
              ],
              if (selectedRole == 'ADMIN' || selectedRole == 'DRIVER_MANAGER') ...[
                const SizedBox(height: 16),
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'الصلاحيات الإدارية'
                      : 'Global Permissions (Admin Only)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        return StatefulBuilder(
                          builder: (contextInner, setDialogStateInner) {
                            return DialogScaffold(child: AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              title: Text(
                                Localizations.localeOf(context).languageCode == 'ar'
                                    ? 'اختر الصلاحيات'
                                    : 'Select Permissions',
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: availablePermissions.map((perm) {
                                    return CheckboxListTile(
                                      title: Text(_getPermissionName(context, perm)),
                                      value: selectedPermissions.contains(perm),
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        setDialogStateInner(() {
                                          if (val == true) {
                                            selectedPermissions.add(perm);
                                          } else {
                                            selectedPermissions.remove(perm);
                                          }
                                        });
                                        setState(() {}); 
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(AppLocalizations.of(context)!.save),
                                )
                              ],
                            ));
                          }
                        );
                      }
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedPermissions.isEmpty 
                              ? (Localizations.localeOf(context).languageCode == 'ar' ? 'اختر الصلاحيات...' : 'Select Permissions...')
                              : '${selectedPermissions.length} ${Localizations.localeOf(context).languageCode == 'ar' ? 'محددة' : 'selected'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
              if (selectedRole == 'VENDOR_MEMBER') ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.assignToVendor,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedVendorId,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  hint: Text(AppLocalizations.of(context)!.selectVendor),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.store, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: widget.vendors
                      .map(
                        (v) => DropdownMenuItem<String>(
                          value: v['id'].toString(),
                          child: Text(
                            v['storeName'] ??
                                v['name'] ??
                                AppLocalizations.of(context)!.unknown,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedVendorId = v),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.vendorRole,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedVendorRole,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.userCheck, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'OWNER',
                      child: Text(AppLocalizations.of(context)!.owner),
                    ),
                    DropdownMenuItem(
                      value: 'MANAGER',
                      child: Text(AppLocalizations.of(context)!.manager),
                    ),
                    DropdownMenuItem(
                      value: 'STAFF',
                      child: Text(AppLocalizations.of(context)!.staff),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => selectedVendorRole = v!),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (btnCtx) => ElevatedButton(
                      onPressed: () async {
                        try {
                          if (widget.user == null) {
                            await ref
                                .read(userProvider.notifier)
                                .addUser(
                                  name: nameController.text,
                                  email: emailController.text,
                                  password: passwordController.text,
                                  role: selectedRole,
                                  phone: PhoneUtils.normalize(
                                    phoneController.text,
                                  ),
                                  vendorId: selectedVendorId,
                                  vendorRole: selectedVendorRole,
                                  title: titleController.text.isNotEmpty ? titleController.text : null,
                                  titleAr: titleArController.text.isNotEmpty ? titleArController.text : null,
                                  permissions: (selectedRole == 'ADMIN' || selectedRole == 'DRIVER_MANAGER') ? selectedPermissions : null,
                                );
                            if (btnCtx.mounted) {
                              ScaffoldMessenger.of(btnCtx).showSnackBar(SnackBar(content: Text(AppLocalizations.of(btnCtx)!.common_success_resource_created), backgroundColor: AppColors.success));
                            }
                          } else {
                            if (widget.user!['id'] != null) {
                              await ref
                                  .read(userProvider.notifier)
                                  .updateUser(
                                    id: widget.user!['id'],
                                    name: nameController.text,
                                    email: emailController.text,
                                    phone: PhoneUtils.normalize(
                                      phoneController.text,
                                    ),
                                    role: selectedRole,
                                    vendorId: selectedVendorId,
                                    oldVendorId: initialVendorId,
                                    oldMemberId: initialMemberId,
                                    vendorRole: selectedVendorRole,
                                    password:
                                        passwordController.text.isNotEmpty
                                        ? passwordController.text
                                        : null,
                                    title: titleController.text.isNotEmpty ? titleController.text : null,
                                    titleAr: titleArController.text.isNotEmpty ? titleArController.text : null,
                                    permissions: selectedRole == 'ADMIN' ? selectedPermissions : null,
                                  );
                              if (btnCtx.mounted) {
                                ScaffoldMessenger.of(btnCtx).showSnackBar(SnackBar(content: Text(AppLocalizations.of(btnCtx)!.common_success_resource_updated), backgroundColor: AppColors.success));
                              }
                            }
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (btnCtx.mounted) {
                            ScaffoldMessenger.of(btnCtx).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(btnCtx, e)), backgroundColor: AppColors.error));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.user == null
                            ? AppLocalizations.of(context)!.create
                            : AppLocalizations.of(context)!.update,
                      ),
                    ),
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
