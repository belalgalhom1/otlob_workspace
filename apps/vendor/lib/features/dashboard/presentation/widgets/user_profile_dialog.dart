import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:core/core.dart';

class UserProfileDialog extends ConsumerStatefulWidget {
  final VoidCallback? onProfileUpdated;

  const UserProfileDialog({
    super.key,
    this.onProfileUpdated,
  });

  @override
  ConsumerState<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends ConsumerState<UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  String? _role;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final userRepo = ref.read(sharedUserRepositoryProvider);
      final response = await userRepo.getUser();
      final data = response is Map && response.containsKey('data') && response['data'] is Map
          ? response['data']
          : (response is Map ? response : {});

      if (mounted) {
        setState(() {
          _nameController.text = data['name']?.toString() ?? '';
          _emailController.text = data['email']?.toString() ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _avatarUrl = data['avatar']?.toString();
          _role = data['role']?.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiErrorMapper.fromError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final multipartFile = dio.MultipartFile.fromBytes(bytes, filename: image.name);
      final userRepo = ref.read(sharedUserRepositoryProvider);
      final response = await userRepo.uploadAvatar(multipartFile);

      final data = response is Map && response.containsKey('data') && response['data'] is Map
          ? response['data']
          : (response is Map ? response : {});

      final newAvatar = data['avatar']?.toString() ?? data['url']?.toString();

      if (mounted) {
        setState(() {
          if (newAvatar != null && newAvatar.isNotEmpty) {
            _avatarUrl = newAvatar;
          }
          _isUploadingAvatar = false;
        });
        widget.onProfileUpdated?.call();
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم تحديث الصورة الشخصية بنجاح' : 'Avatar updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _errorMessage = ApiErrorMapper.fromError(e);
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userRepo = ref.read(sharedUserRepositoryProvider);
      final dto = UpdateUserDto((b) {
        b.name = _nameController.text.trim();
        if (_emailController.text.trim().isNotEmpty) {
          b.email = _emailController.text.trim();
        }
        if (_phoneController.text.trim().isNotEmpty) {
          b.phone = _phoneController.text.trim();
        }
      });

      await userRepo.updateUser(dto);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        widget.onProfileUpdated?.call();
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حفظ البيانات بنجاح' : 'Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = ApiErrorMapper.fromError(e);
        });
      }
    }
  }

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (dialogCtx) => ChangePasswordDialog(
        onSubmit: (currentPassword, newPassword) async {
          final userRepo = ref.read(sharedUserRepositoryProvider);
          await userRepo.changePassword(currentPassword, newPassword);
          if (dialogCtx.mounted) {
            final isAr = Localizations.localeOf(dialogCtx).languageCode == 'ar';
            ScaffoldMessenger.of(dialogCtx).showSnackBar(
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
    final theme = Theme.of(context);

    return DialogScaffold(
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          // Shrink on small screens: a fixed 500px width overflowed phones
          // and clipped the Security buttons.
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.user, color: theme.colorScheme.primary, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.editUserProfile,
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              ErrorUtils.translate(context, _errorMessage),
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Avatar Section
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                // Backend returns a relative path — resolve it
                                // or the image silently fails to load even
                                // though the upload reported success.
                                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        ImageUtils.formatImageUrl(_avatarUrl))
                                    : null,
                                child: _avatarUrl == null || _avatarUrl!.isEmpty
                                    ? Icon(LucideIcons.user, size: 48, color: theme.colorScheme.primary)
                                    : null,
                              ),
                              if (_isUploadingAvatar)
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_role != null) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _role!.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Form Fields
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.name,
                            prefixIcon: const Icon(LucideIcons.user, size: 18),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? l10n.requiredField : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: l10n.emailAddress,
                            prefixIcon: const Icon(LucideIcons.mail, size: 18),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: l10n.phone,
                            prefixIcon: const Icon(LucideIcons.phone, size: 18),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),

                        // Security Section
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'الأمان والحساب' : 'Security & Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // NOTE: no self-delete here — users cannot delete their
                        // own account. Admins remove other users from the
                        // Users page (which already blocks self-deletion).
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showChangePassword,
                            icon: const Icon(LucideIcons.keyRound, size: 16),
                            label: Text(isAr ? 'تغيير كلمة المرور' : 'Change Password'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Dialog Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                              child: Text(l10n.cancel),
                            ),
                            const SizedBox(width: 12),
                            PrimaryButton(
                              text: l10n.save,
                              isLoading: _isSaving,
                              onPressed: _isSaving ? null : _saveProfile,
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
}
