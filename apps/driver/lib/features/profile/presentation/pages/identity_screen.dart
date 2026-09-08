import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:data/data.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import '../../../../l10n/l10n_error_helper.dart';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showChangePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ChangePasswordDialog(
        onSubmit: (currentPassword, newPassword) async {
          final userRepo = ref.read(sharedUserRepositoryProvider);
          await userRepo.changePassword(currentPassword, newPassword);
          if (context.mounted) {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isAr ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteAccountDialog(
        onConfirm: () async {
          final userRepo = ref.read(sharedUserRepositoryProvider);
          await userRepo.deleteAccount();
          await ref.read(authProvider.notifier).logout();
        },
      ),
    );
  }

  void _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(driverProfileProvider.notifier).updateProfile(name: newName);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.common_success_resource_updated)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10nErrorHelper.translate(context, e.toString())), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final profileState = ref.watch(driverProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personalInformation),
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorLoadingProfile)),
        data: (profileData) {
          if (profileData == null) {
            return Center(child: Text(l10n.noDataAvailable));
          }

          final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
              ? profileData['data']
              : (profileData ?? {});
          final user = data['user'] ?? {};

          if (!_isEditing && _nameController.text.isEmpty) {
            _nameController.text = data['name'] ?? user['name'] ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(
                  l10n: l10n,
                  title: l10n.fullName,
                  child: _isEditing
                      ? TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.fullName,
                            border: const OutlineInputBorder(),
                          ),
                          enabled: !_isLoading,
                        )
                      : Text(_nameController.text, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                  action: _isEditing
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: _isLoading ? null : () {
                                setState(() {
                                  _isEditing = false;
                                  _nameController.text = data['name'] ?? user['name'] ?? '';
                                });
                              },
                              child: Text(l10n.cancelUpper),
                            ),
                            const SizedBox(width: 8),
                            PrimaryButton(
                              text: l10n.save,
                              onPressed: _isLoading ? null : _save,
                              isLoading: _isLoading,
                            ),
                          ],
                        )
                      : TextButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(LucideIcons.edit2, size: 16),
                          label: Text(l10n.edit),
                        ),
                ),
                const SizedBox(height: 16),
                _buildReadOnlyField(l10n.emailAddress, user['email'] ?? l10n.notProvided, LucideIcons.mail),
                const SizedBox(height: 16),
                _buildReadOnlyField(l10n.phone, user['phone'] ?? l10n.notProvided, LucideIcons.phone),
                const SizedBox(height: 16),
                // National ID explicitly read-only based on user request
                _buildReadOnlyField(l10n.nationalId, data['nationalId'] ?? l10n.notProvided, LucideIcons.creditCard),
                const SizedBox(height: 32),
                Text(
                  isAr ? 'الأمان والحساب' : 'Security & Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showChangePassword(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.keyRound, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isAr ? 'تغيير كلمة المرور' : 'Change Password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showDeleteAccount(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isAr ? 'حذف الحساب نهائياً' : 'Delete Account Permanently',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.error),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required AppLocalizations l10n,
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
          if (action != null) ...[
            const SizedBox(height: 16),
            Align(alignment: AlignmentDirectional.centerEnd, child: action),
          ]
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.lock, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
