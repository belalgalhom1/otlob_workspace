import 'package:vendor/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:vendor/core/utils/error_utils.dart';

class ManualTransactionDialog extends ConsumerStatefulWidget {
  final String entityId;
  final bool isVendor;

  const ManualTransactionDialog({
    super.key,
    required this.entityId,
    required this.isVendor,
  });

  @override
  ConsumerState<ManualTransactionDialog> createState() =>
      _ManualTransactionDialogState();
}

class _ManualTransactionDialogState
    extends ConsumerState<ManualTransactionDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'PAYOUT';
  bool _submitting = false;
  String? _error;

  Future<void> _process() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount % 1 != 0) {
      setState(() {
        _submitting = false;
        _error = l10n.failedWithError(l10n.invalidAmount);
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final repo = ref.read(adminWalletRepositoryProvider);
    try {
      final dto = ProcessManualTransactionDto((b) => b
        ..type = _type
        ..amount = amount
        ..description = _descController.text
      );

      if (widget.isVendor) {
        await repo.walletProcessVendorTransaction(vendorId: widget.entityId, processManualTransactionDto: dto);
      } else {
        await repo.walletProcessDriverTransaction(driverId: widget.entityId, processManualTransactionDto: dto);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transactionProcessed),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = ErrorUtils.translate(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    String getTranslatedType(String type) {
      switch (type) {
        case 'PAYOUT': return l10n.payout;
        case 'REFUND': return l10n.refund;
        case 'TOP_UP': return l10n.topUp;
        case 'PENALTY': return l10n.penalty;
        case 'CASH_COLLECTION': return l10n.cashCollection;
        default: return type;
      }
    }

    return DialogScaffold(child: AlertDialog(
      title: Text(widget.isVendor ? l10n.adjustWalletVendor : l10n.adjustWalletDriver),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            isExpanded: true,
            items: [
              'PAYOUT',
              'REFUND',
              'TOP_UP',
              'PENALTY',
              'CASH_COLLECTION',
            ].map((t) => DropdownMenuItem(
              value: t, 
              child: Text(
                getTranslatedType(t),
                overflow: TextOverflow.ellipsis,
              )
            )).toList(),
            onChanged: (v) => setState(() => _type = v!),
            decoration: InputDecoration(labelText: l10n.transactionType),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: l10n.amount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: l10n.descriptionOptional,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancelAction),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _process,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.processAction),
        ),
      ],
    ));
  }
}

