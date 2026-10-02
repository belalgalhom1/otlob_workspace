import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';

class ManageWalletsBottomSheet extends ConsumerStatefulWidget {
  final List<dynamic> driverWallets;

  const ManageWalletsBottomSheet({super.key, required this.driverWallets});

  @override
  ConsumerState<ManageWalletsBottomSheet> createState() => _ManageWalletsBottomSheetState();
}

class _ManageWalletsBottomSheetState extends ConsumerState<ManageWalletsBottomSheet> {
  final _numberController = TextEditingController();
  String _selectedType = 'VODAFONE';
  bool _isLoading = false;
  bool _isAddingNew = false;
  String? _error;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      setState(() {
        _error = l10n.pleaseEnterWalletNumber;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(driverWalletProvider.notifier).addDriverWallet(
        number,
        _selectedType,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.walletAddedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorUtils.translate(context, e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getWalletTypeName(String type, AppLocalizations l10n) {
    final normalizedType = type.toUpperCase();
    if (normalizedType.contains('VODAFONE')) return l10n.mobileWallet;
    if (normalizedType.contains('INSTAPAY')) return l10n.instaPay;
    return type;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isAddingNew ? AppLocalizations.of(context)!.addNewWallet : AppLocalizations.of(context)!.myWalletsForWithdrawals,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              if (_isAddingNew)
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    setState(() {
                      _isAddingNew = false;
                    });
                  },
                )
            ],
          ),
          const SizedBox(height: 16),
          
          if (!_isAddingNew) ...[
            if (widget.driverWallets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.noWalletsYet,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              )
            else
              ...widget.driverWallets.map((wallet) => ListTile(
                leading: Icon(LucideIcons.wallet, color: AppColors.primary),
                title: Text(_getWalletTypeName('${wallet['type']}', AppLocalizations.of(context)!), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                subtitle: Text('${wallet['number']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                contentPadding: EdgeInsets.zero,
              )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingNew = true;
                  _error = null;
                });
              },
              icon: const Icon(LucideIcons.plus),
              label: Text(AppLocalizations.of(context)!.addWallet),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.walletType,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'VODAFONE', child: Text(AppLocalizations.of(context)!.mobileWallet)),
                DropdownMenuItem(value: 'INSTAPAY', child: Text(AppLocalizations.of(context)!.instaPay)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.walletNumber,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            if (_error != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.alertCircle, size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context)!.saveWallet),
            ),
          ]
        ],
      ),
    );
  }
}
