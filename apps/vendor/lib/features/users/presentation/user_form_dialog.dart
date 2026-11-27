import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/features/users/presentation/user_provider.dart';
import 'package:vendor/core/utils/error_utils.dart';

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
  bool _isSaving = false;
  String? _errorMessage;
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

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    Widget? suffixIcon,
    bool isRequired = false,
    TextDirection? textDirection,
    TextInputType? keyboardType,
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
        TextField(
          controller: controller,
          enabled: !_isSaving,
          obscureText: obscure,
          textDirection: textDirection,
          keyboardType: keyboardType,
          decoration: AppDialogStyles.inputDecoration(
            context,
            hintText: hint,
            icon: icon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Future<void> _openPermissionsDialog() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (contextInner, setDialogStateInner) {
            return AppDialog(
              maxWidth: 480,
              maxHeight: 620,
              header: AppDialogHeader(
                icon: LucideIcons.shieldCheck,
                title: isAr ? 'اختر الصلاحيات' : 'Select Permissions',
                subtitle: isAr
                    ? '${selectedPermissions.length} صلاحيات محددة'
                    : '${selectedPermissions.length} selected',
                onClose: () => Navigator.pop(ctx),
              ),
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: availablePermissions.map((perm) {
                  final checked = selectedPermissions.contains(perm);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AppDialogSectionCard(
                      padding: EdgeInsets.zero,
                      backgroundColor: checked
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                      borderColor: checked
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : null,
                      child: CheckboxListTile(
                        title: Text(
                          _getPermissionName(context, perm),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: checked,
                        activeColor: AppColors.primary,
                        checkColor: AppColors.onPrimary,
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
                      ),
                    ),
                  );
                }).toList(),
              ),
              footer: AppDialogFooter(
                confirmLabel: l10n.save,
                confirmIcon: LucideIcons.check,
                onConfirm: () => Navigator.pop(ctx),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? successMsg;
      if (widget.user == null) {
        await ref.read(userProvider.notifier).addUser(
              name: nameController.text,
              email: emailController.text,
              password: passwordController.text,
              role: selectedRole,
              phone: PhoneUtils.normalize(phoneController.text),
              vendorId: selectedRole == 'VENDOR_MEMBER' ? selectedVendorId : null,
              vendorRole:
                  selectedRole == 'VENDOR_MEMBER' ? selectedVendorRole : null,
              title: titleController.text.isNotEmpty ? titleController.text : null,
              titleAr: titleArController.text.isNotEmpty ? titleArController.text : null,
              permissions: (selectedRole == 'ADMIN' || selectedRole == 'DRIVER_MANAGER')
                  ? selectedPermissions
                  : null,
            );
        successMsg = l10n.common_success_resource_created;
      } else if (widget.user!['id'] != null) {
        await ref.read(userProvider.notifier).updateUser(
              id: widget.user!['id'],
              name: nameController.text,
              email: emailController.text,
              phone: PhoneUtils.normalize(phoneController.text),
              role: selectedRole,
              vendorId: selectedRole == 'VENDOR_MEMBER' ? selectedVendorId : null,
              oldVendorId: initialVendorId,
              oldMemberId: initialMemberId,
              vendorRole:
                  selectedRole == 'VENDOR_MEMBER' ? selectedVendorRole : null,
              password: passwordController.text.isNotEmpty
                  ? passwordController.text
                  : null,
              title: titleController.text.isNotEmpty ? titleController.text : null,
              titleAr: titleArController.text.isNotEmpty ? titleArController.text : null,
              permissions: (selectedRole == 'ADMIN' || selectedRole == 'DRIVER_MANAGER')
                  ? selectedPermissions
                  : null,
            );
        successMsg = l10n.common_success_resource_updated;
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.pop(context);
        if (successMsg != null) {
          messenger?.showSnackBar(
            SnackBar(content: Text(successMsg), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = ErrorUtils.translate(context, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isNew = widget.user == null;

    return AppDialog(
      maxWidth: 540,
      canPop: !_isSaving,
      header: AppDialogHeader(
        icon: isNew ? LucideIcons.userPlus : LucideIcons.user,
        title: isNew ? l10n.createNewUser : l10n.editUserProfile,
        isCloseDisabled: _isSaving,
        onClose: () => Navigator.pop(context),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
            AppDialogErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],
          _buildField(
            l10n.fullName,
            LucideIcons.user,
            nameController,
            'e.g. Ahmed Ali',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildField(
            l10n.emailAddress,
            LucideIcons.mail,
            emailController,
            'admin@otlob.com',
            isRequired: true,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildField(
            l10n.phone,
            LucideIcons.phone,
            phoneController,
            '+201100000000',
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildField(
            isNew
                ? l10n.password
                : (isAr ? 'كلمة المرور الجديدة' : 'New Password'),
            LucideIcons.lock,
            passwordController,
            isNew
                ? '********'
                : (isAr
                    ? 'اتركها فارغة للإبقاء على الحالية'
                    : 'Leave blank to keep current'),
            isRequired: isNew,
            obscure: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            isAr ? 'المسمى الوظيفي' : 'Job Title',
            LucideIcons.briefcase,
            titleController,
            'e.g. Sales Manager',
            languageTag: 'EN',
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          _buildField(
            isAr ? 'المسمى الوظيفي' : 'Job Title',
            LucideIcons.briefcase,
            titleArController,
            'مثال: مدير المبيعات',
            languageTag: 'عربي',
            textDirection: TextDirection.rtl,
          ),
          if (widget.currentUserRole != 'ADMIN') ...[
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.accountRole, isRequired: true),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              isExpanded: true,
              dropdownColor: AppDialogStyles.dropdownColor(context),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: AppDialogStyles.inputDecoration(
                context,
                icon: LucideIcons.shield,
              ),
              items: [
                DropdownMenuItem(
                  value: 'SUPER_ADMIN',
                  child: Text(l10n.superAdmin, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'ADMIN',
                  child: Text(l10n.admin, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'VENDOR_MEMBER',
                  child: Text(l10n.vendorMember, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'DRIVER',
                  child: Text(l10n.driver, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'DRIVER_MANAGER',
                  child: Text(
                    isAr ? 'مسؤول سائقين' : 'Driver Manager',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'CUSTOMER',
                  child: Text(l10n.customer, overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (v) {
                      setState(() {
                        selectedRole = v!;
                      });
                    },
            ),
          ],
          if (selectedRole == 'ADMIN' || selectedRole == 'DRIVER_MANAGER') ...[
            const SizedBox(height: 16),
            AppFieldLabel(
              label: isAr
                  ? 'الصلاحيات الإدارية'
                  : 'Global Permissions (Admin Only)',
            ),
            InkWell(
              onTap: _isSaving ? null : _openPermissionsDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppDialogStyles.subtleSurfaceColor(context),
                  border: Border.all(
                    color: AppDialogStyles.borderColor(context),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 17,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedPermissions.isEmpty
                            ? (isAr ? 'اختر الصلاحيات...' : 'Select Permissions...')
                            : '${selectedPermissions.length} ${isAr ? 'محددة' : 'selected'}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (selectedRole == 'VENDOR_MEMBER') ...[
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.assignToVendor),
            DropdownButtonFormField<String>(
              initialValue: widget.vendors.any(
                (v) => v['id']?.toString() == selectedVendorId,
              )
                  ? selectedVendorId
                  : null,
              isExpanded: true,
              dropdownColor: AppDialogStyles.dropdownColor(context),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              hint: Text(l10n.selectVendor),
              decoration: AppDialogStyles.inputDecoration(
                context,
                icon: LucideIcons.store,
              ),
              items: widget.vendors
                  .map(
                    (v) => DropdownMenuItem<String>(
                      value: v['id'].toString(),
                      child: Text(
                        v['storeName'] ?? v['name'] ?? l10n.unknown,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() => selectedVendorId = v),
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.vendorRole),
            DropdownButtonFormField<String>(
              initialValue: selectedVendorRole,
              isExpanded: true,
              dropdownColor: AppDialogStyles.dropdownColor(context),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: AppDialogStyles.inputDecoration(
                context,
                icon: LucideIcons.userCheck,
              ),
              items: [
                DropdownMenuItem(
                  value: 'OWNER',
                  child: Text(l10n.owner, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'MANAGER',
                  child: Text(l10n.manager, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'STAFF',
                  child: Text(l10n.staff, overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (v) => setState(() => selectedVendorRole = v!),
            ),
          ],
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: isNew ? l10n.create : l10n.update,
        confirmIcon: isNew ? LucideIcons.userPlus : LucideIcons.save,
        isLoading: _isSaving,
        onConfirm: _submit,
      ),
    );
  }
}
