import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'dart:io';

class TopUpBottomSheet extends ConsumerStatefulWidget {
  final List<dynamic> platformWallets;

  const TopUpBottomSheet({super.key, required this.platformWallets});

  @override
  ConsumerState<TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends ConsumerState<TopUpBottomSheet> {
  final _amountController = TextEditingController();
  String? _selectedWalletId;
  File? _receiptImage;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.platformWallets.isNotEmpty) {
      _selectedWalletId = widget.platformWallets.first['id'];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _error = l10n.pleaseEnterAmount;
      });
      return;
    }
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0 || amount % 1 != 0) {
      setState(() {
        _error = l10n.pleaseEnterValidAmount;
      });
      return;
    }

    if (_selectedWalletId == null) {
      setState(() {
        _error = l10n.pleaseSelectPlatformWallet;
      });
      return;
    }

    if (_receiptImage == null) {
      setState(() {
        _error = l10n.pleaseUploadReceipt;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(driverWalletProvider.notifier).requestTopUp(
        platformWalletId: _selectedWalletId!,
        amount: amount,
        imagePath: _receiptImage!.path,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.topUpRequestSubmitted)),
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
          Text(
            AppLocalizations.of(context)!.topUpWallet,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedWalletId,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.selectPlatformWallet,
              border: const OutlineInputBorder(),
            ),
            items: widget.platformWallets.map((wallet) {
              return DropdownMenuItem<String>(
                value: wallet['id'],
                child: Text('${wallet['type']} - ${wallet['number']}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedWalletId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.amount,
              border: const OutlineInputBorder(),
              suffixText: ref.watch(configurationProvider.notifier).currency,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _receiptImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_receiptImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, size: 32, color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!.uploadReceiptImage, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
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
                : Text(AppLocalizations.of(context)!.submitRequest),
          ),
        ],
      ),
    );
  }
}
