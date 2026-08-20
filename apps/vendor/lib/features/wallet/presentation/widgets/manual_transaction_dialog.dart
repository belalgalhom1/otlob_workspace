import 'package:vendor/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';

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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancelAction),
        ),
        Builder(
          builder: (btnCtx) => ElevatedButton(
            onPressed: () async {
            final amount = double.tryParse(_amountController.text);
            if (amount == null) return;

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

              if (!btnCtx.mounted) return;
              Navigator.pop(context, true);
              ScaffoldMessenger.of(btnCtx).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(btnCtx)!.transactionProcessed),
                ),
              );
            } catch (e) {
              if (!btnCtx.mounted) return;
              ScaffoldMessenger.of(btnCtx).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(btnCtx)!.failedWithError(e.toString())),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: Text(AppLocalizations.of(btnCtx)!.processAction),
        ),
        ),
      ],
    ));
  }
}

