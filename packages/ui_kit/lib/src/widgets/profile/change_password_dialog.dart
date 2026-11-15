import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../dialogs/app_dialog.dart';

class ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function(String currentPassword, String newPassword) onSubmit;
  final String? title;
  final String? currentPasswordLabel;
  final String? newPasswordLabel;
  final String? confirmPasswordLabel;
  final String? cancelText;
  final String? confirmText;
  final String? passwordMismatchError;
  final String? passwordTooShortError;
  final String? passwordSameAsOldError;

  const ChangePasswordDialog({
    super.key,
    required this.onSubmit,
    this.title,
    this.currentPasswordLabel,
    this.newPasswordLabel,
    this.confirmPasswordLabel,
    this.cancelText,
    this.confirmText,
    this.passwordMismatchError,
    this.passwordTooShortError,
    this.passwordSameAsOldError,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;

    if (currentPass == newPass) {
      setState(() {
        _errorMessage = widget.passwordSameAsOldError ??
            (isAr
                ? 'كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية'
                : 'New password must be different from current password');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(currentPass, newPass);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final currentLabel =
        widget.currentPasswordLabel ?? (isAr ? 'كلمة المرور الحالية' : 'Current Password');
    final newLabel =
        widget.newPasswordLabel ?? (isAr ? 'كلمة المرور الجديدة' : 'New Password');
    final confirmLabel = widget.confirmPasswordLabel ??
        (isAr ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password');

    return AppDialog(
      maxWidth: 480,
      canPop: !_isLoading,
      header: AppDialogHeader(
        icon: LucideIcons.keyRound,
        title: widget.title ?? (isAr ? 'تغيير كلمة المرور' : 'Change Password'),
        subtitle: isAr
            ? 'أدخل كلمة المرور الحالية واختر كلمة مرور جديدة قوية'
            : 'Enter your current password and choose a strong new password',
        isCloseDisabled: _isLoading,
        onClose: () => Navigator.of(context).pop(false),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
              AppDialogErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            AppFieldLabel(label: currentLabel, isRequired: true),
            TextFormField(
              controller: _currentPasswordController,
              enabled: !_isLoading,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: currentLabel,
                icon: LucideIcons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return isAr
                      ? 'يرجى إدخال كلمة المرور الحالية'
                      : 'Please enter current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: newLabel, isRequired: true),
            TextFormField(
              controller: _newPasswordController,
              enabled: !_isLoading,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: newLabel,
                icon: LucideIcons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return widget.passwordTooShortError ??
                      (isAr
                          ? 'يجب أن لا تقل كلمة المرور عن 6 أحرف'
                          : 'Password must be at least 6 characters');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: confirmLabel, isRequired: true),
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSubmit(),
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: confirmLabel,
                icon: LucideIcons.shieldCheck,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _newPasswordController.text) {
                  return widget.passwordMismatchError ??
                      (isAr
                          ? 'كلمتا المرور غير متطابقتين'
                          : 'Passwords do not match');
                }
                return null;
              },
            ),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: widget.cancelText ?? (isAr ? 'إلغاء' : 'Cancel'),
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: widget.confirmText ?? (isAr ? 'تحديث كلمة المرور' : 'Update'),
        confirmIcon: LucideIcons.save,
        isLoading: _isLoading,
        loadingLabel: isAr ? 'جارٍ التحديث...' : 'Updating...',
        onConfirm: _handleSubmit,
      ),
    );
  }
}
