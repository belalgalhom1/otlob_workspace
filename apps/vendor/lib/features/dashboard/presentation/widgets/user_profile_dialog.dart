import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
    final XFile? image;
    try {
      image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (e) {
      MediaPermissionHelper.handlePickerError(
        e,
        context: mounted ? context : null,
      );
      return;
    }
    if (image == null) return;

    XFile? finalFile;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: const Color(0xFFD4920E),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFD4920E),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
          ),
        ],
      );
      if (cropped == null) {
        return;
      }
      finalFile = XFile(cropped.path);
    } catch (cropErr) {
      debugPrint('ImageCropper failed or not available, using original image: $cropErr');
      finalFile = image;
    }

    if (finalFile == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _errorMessage = null;
    });

    try {
      final bytes = await finalFile.readAsBytes();
      final multipartFile = dio.MultipartFile.fromBytes(bytes, filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
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
    final busy = _isSaving || _isUploadingAvatar;

    return AppDialog(
      maxWidth: 520,
      canPop: !busy,
      header: AppDialogHeader(
        icon: LucideIcons.user,
        title: l10n.editUserProfile,
        subtitleWidget: _role != null
            ? Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppBadgePill(
                    text: _role!.replaceAll('_', ' '),
                    accentColor: AppColors.primary,
                  ),
                ],
              )
            : null,
        isCloseDisabled: busy,
        onClose: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null &&
                      _errorMessage!.trim().isNotEmpty) ...[
                    AppDialogErrorBanner(
                      message: ErrorUtils.translate(context, _errorMessage),
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
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          // Backend returns a relative path — resolve it
                          // or the image silently fails to load even
                          // though the upload reported success.
                          backgroundImage:
                              _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      ImageUtils.formatImageUrl(_avatarUrl),
                                    )
                                  : null,
                          child: _avatarUrl == null || _avatarUrl!.isEmpty
                              ? const Icon(
                                  LucideIcons.user,
                                  size: 46,
                                  color: AppColors.primary,
                                )
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
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        PositionedDirectional(
                          bottom: 0,
                          end: 0,
                          child: InkWell(
                            onTap: busy ? null : _pickAndUploadAvatar,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppDialogStyles.backgroundColor(context),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                size: 15,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  AppFieldLabel(label: l10n.name, isRequired: true),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.next,
                    decoration: AppDialogStyles.inputDecoration(
                      context,
                      hintText: l10n.name,
                      icon: LucideIcons.user,
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? l10n.requiredField
                        : null,
                  ),
                  const SizedBox(height: 16),

                  AppFieldLabel(label: l10n.emailAddress),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isSaving,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AppDialogStyles.inputDecoration(
                      context,
                      hintText: l10n.emailAddress,
                      icon: LucideIcons.mail,
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppFieldLabel(label: l10n.phone),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_isSaving,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.phone,
                    decoration: AppDialogStyles.inputDecoration(
                      context,
                      hintText: l10n.phone,
                      icon: LucideIcons.phone,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Security Section
                  // NOTE: no self-delete here — users cannot delete their
                  // own account. Admins remove other users from the
                  // Users page (which already blocks self-deletion).
                  AppDialogSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isAr ? 'الأمان والحساب' : 'Security & Account',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _showChangePassword,
                          icon: const Icon(LucideIcons.keyRound, size: 16),
                          label: Text(
                            isAr ? 'تغيير كلمة المرور' : 'Change Password',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(
                              color: AppDialogStyles.borderColor(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      footer: _isLoading
          ? null
          : AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.of(context).pop(),
              confirmLabel: l10n.save,
              confirmIcon: LucideIcons.save,
              isLoading: _isSaving,
              onConfirm: _isSaving ? null : _saveProfile,
            ),
    );
  }
}
