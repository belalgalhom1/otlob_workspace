import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../data/driver_models.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';

class AssignOrderDialog extends ConsumerStatefulWidget {
  final DriverProfile driver;

  const AssignOrderDialog({super.key, required this.driver});

  @override
  ConsumerState<AssignOrderDialog> createState() => _AssignOrderDialogState();
}

class _AssignOrderDialogState extends ConsumerState<AssignOrderDialog> {
  String _selectedOrderId = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _assign() async {
    final orderId = _selectedOrderId.trim();
    if (orderId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(adminOrdersRepositoryProvider);
      await repo.assignDriver(
        orderId: orderId,
        driverId: widget.driver.id,
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final msg = AppLocalizations.of(context)!.driverAssignedSuccess;
        Navigator.pop(context, true);
        messenger?.showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorUtils.translate(context, e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppDialog(
      maxWidth: 480,
      canPop: !_isLoading,
      header: AppDialogHeader(
        icon: LucideIcons.packageCheck,
        title: l10n.assignOrderToDriver(widget.driver.name),
        subtitle: widget.driver.phone,
        isCloseDisabled: _isLoading,
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
          Text(
            l10n.enterOrderIdToAssign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          AppFieldLabel(label: l10n.orderIdLabel, isRequired: true),
          TextFormField(
            enabled: !_isLoading,
            textDirection: TextDirection.ltr,
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: 'UUID',
              icon: LucideIcons.hash,
            ),
            onChanged: (val) {
              setState(() {
                _selectedOrderId = val;
              });
            },
          ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancelAction,
        onCancel: () => Navigator.pop(context),
        confirmLabel: l10n.assignAction,
        confirmIcon: LucideIcons.checkCircle2,
        isLoading: _isLoading,
        onConfirm:
            (_isLoading || _selectedOrderId.trim().isEmpty) ? null : _assign,
      ),
    );
  }
}
