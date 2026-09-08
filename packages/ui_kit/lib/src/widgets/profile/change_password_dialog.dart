import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../dialog_scaffold.dart';

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
            (isAr ? 'كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية' : 'New password must be different from current password');
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
    final theme = Theme.of(context);

    return DialogScaffold(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title ?? (isAr ? 'تغيير كلمة المرور' : 'Change Password'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: widget.currentPasswordLabel ?? (isAr ? 'كلمة المرور الحالية' : 'Current Password'),
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return isAr ? 'يرجى إدخال كلمة المرور الحالية' : 'Please enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: widget.newPasswordLabel ?? (isAr ? 'كلمة المرور الجديدة' : 'New Password'),
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return widget.passwordTooShortError ??
                          (isAr ? 'يجب أن لا تقل كلمة المرور عن 6 أحرف' : 'Password must be at least 6 characters');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: widget.confirmPasswordLabel ?? (isAr ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password'),
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _newPasswordController.text) {
                      return widget.passwordMismatchError ??
                          (isAr ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
            child: Text(
              widget.cancelText ?? (isAr ? 'إلغاء' : 'Cancel'),
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(widget.confirmText ?? (isAr ? 'تغيير' : 'Update')),
          ),
        ],
      ),
    );
  }
}
