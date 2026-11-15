import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../dialogs/app_dialog.dart';

class DeleteAccountDialog extends StatefulWidget {
  final Future<void> Function() onConfirm;
  final String? title;
  final String? content;
  final String? cancelText;
  final String? deleteText;

  const DeleteAccountDialog({
    super.key,
    required this.onConfirm,
    this.title,
    this.content,
    this.cancelText,
    this.deleteText,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm();
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

    return AppDialog(
      maxWidth: 460,
      canPop: !_isLoading,
      header: AppDialogHeader(
        icon: LucideIcons.alertTriangle,
        accentColor: AppColors.error,
        title: widget.title ??
            (isAr ? 'حذف الحساب نهائياً' : 'Delete Account Permanently'),
        titleColor: AppColors.error,
        isCloseDisabled: _isLoading,
        onClose: () => Navigator.of(context).pop(false),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
            AppDialogErrorBanner(message: _errorMessage!),
            const SizedBox(height: 14),
          ],
          AppDialogSectionCard(
            backgroundColor: AppColors.error.withValues(alpha: 0.06),
            borderColor: AppColors.error.withValues(alpha: 0.2),
            child: Text(
              widget.content ??
                  (isAr
                      ? 'هل أنت متأكد من رغبتك في حذف حسابك؟ سيتم إنهاء جميع الجلسات وحذف بياناتك الشخصية نهائياً ولا يمكن التراجع عن هذا الإجراء.'
                      : 'Are you sure you want to delete your account? All active sessions will be terminated and your personal details will be permanently removed. This action cannot be undone.'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: widget.cancelText ?? (isAr ? 'إلغاء' : 'Cancel'),
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel:
            widget.deleteText ?? (isAr ? 'تأكيد الحذف' : 'Delete Account'),
        confirmIcon: LucideIcons.trash2,
        isDestructive: true,
        isLoading: _isLoading,
        loadingLabel: isAr ? 'جارٍ الحذف...' : 'Deleting...',
        onConfirm: _handleDelete,
      ),
    );
  }
}
