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
  bool _isDriverManager = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final authRepo = ref.read(sharedAuthRepositoryProvider);
    final role = await authRepo.getUserRole();
    if (role == 'DRIVER_MANAGER' && mounted) {
      setState(() {
        _isDriverManager = true;
        _type = 'PENALTY';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount % 1 != 0 || amount <= 0) {
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    String getTranslatedType(String type) {
      switch (type) {
        case 'PAYOUT': return l10n.payout;
        case 'REFUND': return l10n.refund;
        case 'TOP_UP': return l10n.topUp;
        case 'PENALTY': return isAr ? 'جزاء / عقوبة' : l10n.penalty;
        case 'CASH_COLLECTION': return l10n.cashCollection;
        default: return type;
      }
    }

    final availableTypes = _isDriverManager
        ? ['PENALTY']
        : [
            'PAYOUT',
            'REFUND',
            'TOP_UP',
            'PENALTY',
            'CASH_COLLECTION',
          ];

    final title = _isDriverManager
        ? (isAr ? 'تطبيق جزاء / عقوبة على السائق' : 'Apply Driver Penalty')
        : (widget.isVendor ? l10n.adjustWalletVendor : l10n.adjustWalletDriver);

    return AppDialog(
      maxWidth: 500,
      canPop: !_submitting,
      header: AppDialogHeader(
        icon: LucideIcons.wallet,
        accentColor: _type == 'PENALTY' ? AppColors.error : AppColors.primary,
        title: title,
        subtitle: _isDriverManager
            ? (isAr
                ? 'مسؤول السائقين مصرح له بخصم الجزاءات فقط'
                : 'Driver managers may only apply penalties')
            : null,
        isCloseDisabled: _submitting,
        onClose: () => Navigator.pop(context, false),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null && _error!.trim().isNotEmpty) ...[
            AppDialogErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          AppFieldLabel(label: l10n.transactionType, isRequired: true),
          DropdownButtonFormField<String>(
            initialValue: _type,
            isExpanded: true,
            dropdownColor: AppDialogStyles.dropdownColor(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            items: availableTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      getTranslatedType(t),
                      softWrap: true,
                    ),
                  ),
                )
                .toList(),
            onChanged: (_isDriverManager || _submitting)
                ? null
                : (v) => setState(() => _type = v!),
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: l10n.transactionType,
              icon: LucideIcons.arrowRightLeft,
              helperText: _isDriverManager
                  ? (isAr
                      ? 'مسؤول السائقين مصرح له بخصم الجزاءات فقط'
                      : 'Driver managers may only apply penalties')
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          AppFieldLabel(label: l10n.amount, isRequired: true),
          TextField(
            controller: _amountController,
            enabled: !_submitting,
            textDirection: TextDirection.ltr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: '0',
              icon: LucideIcons.banknote,
              suffixText: isAr ? 'ج.م' : 'EGP',
              helperText: _type == 'PENALTY'
                  ? (isAr
                      ? 'سيتم خصم هذا المبلغ من محفظة السائق'
                      : 'This amount will be deducted from driver wallet')
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          AppFieldLabel(label: l10n.descriptionOptional),
          TextField(
            controller: _descController,
            enabled: !_submitting,
            minLines: 2,
            maxLines: 3,
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: l10n.descriptionOptional,
              isMultiline: true,
            ),
          ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancelAction,
        onCancel: () => Navigator.pop(context, false),
        confirmLabel: l10n.processAction,
        confirmIcon: LucideIcons.checkCircle2,
        isDestructive: _type == 'PENALTY',
        isLoading: _submitting,
        onConfirm: _process,
      ),
    );
  }
}
