import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:data/data.dart';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
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
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorLoadingProfile),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(driverProfileProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (profileData) {
          if (profileData == null) {
            return Center(child: Text(l10n.noDataAvailable));
          }

          final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
              ? profileData['data']
              : (profileData ?? {});
          final user = data['user'] ?? {};
          // Full name is read-only: drivers cannot edit it (managed by admin).
          final fullName = (data['name'] ?? user['name'] ?? '').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildReadOnlyField(
                  l10n.fullName,
                  fullName.isEmpty ? l10n.notProvided : fullName,
                  LucideIcons.user,
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
                // NOTE: no self-delete — drivers cannot delete their own
                // account. (Admins manage driver accounts.)
              ],
            ),
          );
        },
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
