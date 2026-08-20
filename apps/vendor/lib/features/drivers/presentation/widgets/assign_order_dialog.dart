import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../data/driver_models.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:vendor/core/providers.dart';

class AssignOrderDialog extends ConsumerStatefulWidget {
  final DriverProfile driver;

  const AssignOrderDialog({super.key, required this.driver});

  @override
  ConsumerState<AssignOrderDialog> createState() => _AssignOrderDialogState();
}

class _AssignOrderDialogState extends ConsumerState<AssignOrderDialog> {
  String _selectedOrderId = '';
  bool _isLoading = false;

  Future<void> _assign(BuildContext ctx) async {
    final orderId = _selectedOrderId.trim();
    if (orderId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.ordersAdminForceAssignDriver(
        orderId: orderId,
        adminAssignDriverDto: AdminAssignDriverDto((b) => b..driverId = widget.driver.id),
      );

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(ctx)!.driverAssignedSuccess)),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(ctx)!.failedWithError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogScaffold(child: AlertDialog(
      title: Text(AppLocalizations.of(context)!.assignOrderToDriver(widget.driver.name)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.enterOrderIdToAssign),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.orderIdLabel,
                border: const OutlineInputBorder(),
                hintText: 'UUID',
              ),
              onChanged: (val) {
                setState(() {
                  _selectedOrderId = val;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelAction),
        ),
        Builder(
          builder: (btnCtx) => ElevatedButton(
          onPressed: (_isLoading || _selectedOrderId.trim().isEmpty) ? null : () => _assign(btnCtx),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.assignAction),
        ),
        ),
      ],
    ));
  }
}
