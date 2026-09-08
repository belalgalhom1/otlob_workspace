import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../dialog_scaffold.dart';

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

    return DialogScaffold(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title ?? (isAr ? 'حذف الحساب نهائياً' : 'Delete Account Permanently'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.error),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ],
            Text(
              widget.content ??
                  (isAr
                      ? 'هل أنت متأكد من رغبتك في حذف حسابك؟ سيتم إنهاء جميع الجلسات وحذف بياناتك الشخصية نهائياً ولا يمكن التراجع عن هذا الإجراء.'
                      : 'Are you sure you want to delete your account? All active sessions will be terminated and your personal details will be permanently removed. This action cannot be undone.'),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
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
            onPressed: _isLoading ? null : _handleDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(widget.deleteText ?? (isAr ? 'تأكيد الحذف' : 'Delete Account')),
          ),
        ],
      ),
    );
  }
}
