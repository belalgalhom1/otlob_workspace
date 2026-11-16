import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import '../data/wallet_providers.dart';

class PlatformWalletsScreen extends ConsumerWidget {
  const PlatformWalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(platformWalletsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createWallet(context, ref, l10n),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(l10n.addWallet, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(ErrorUtils.translate(context, err), style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(platformWalletsProvider),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(l10n.refresh),
              ),
            ],
          ),
        ),
        data: (wallets) {
          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.wallet,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPlatformWallets,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.platformWalletsSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isActive = wallet['isActive'] ?? false;
              final activeColor = isActive ? AppColors.success : AppColors.error;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.25)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.wallet,
                          color: activeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    () {
                                      final type = (wallet['type'] ?? '').toString().toUpperCase();
                                      if (type.contains('VODAFONE') || type.contains('MOBILE')) {
                                        return l10n.mobileWallet;
                                      }
                                      if (type.contains('INSTAPAY')) return l10n.instaPay;
                                      return wallet['type']?.toString() ?? '';
                                    }(),
                                    softWrap: true,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: activeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isActive ? l10n.walletActive : l10n.walletInactive,
                                    style: TextStyle(
                                      color: activeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.hash,
                                  size: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    wallet['number'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) async {
                          try {
                            await ref
                                .read(platformWalletsProvider.notifier)
                                .toggleWallet(wallet['id'], val);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${l10n.walletFailed}: ${ErrorUtils.translate(context, e)}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _createWallet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final numberController = TextEditingController();
    String selectedProvider = 'VODAFONE';
    String? error;
    bool submitting = false;

    showDialog<void>(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> submit() async {
              setState(() {
                submitting = true;
                error = null;
              });
              try {
                await ref
                    .read(platformWalletsProvider.notifier)
                    .createWallet(selectedProvider, numberController.text);
                if (!c.mounted) return;
                Navigator.pop(c);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.walletAddedSuccessfully),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!c.mounted) return;
                setState(() {
                  submitting = false;
                  error =
                      '${l10n.walletFailed}: ${ErrorUtils.translate(context, e)}';
                });
              }
            }

            return AppDialog(
              maxWidth: 460,
              canPop: !submitting,
              header: AppDialogHeader(
                icon: LucideIcons.wallet,
                title: l10n.addPlatformWallet,
                isCloseDisabled: submitting,
                onClose: () => Navigator.pop(c),
              ),
              body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFieldLabel(
                    label: l10n.walletProvider,
                    isRequired: true,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProvider,
                    dropdownColor: AppDialogStyles.dropdownColor(dialogContext),
                    isExpanded: true,
                    decoration: AppDialogStyles.inputDecoration(
                      dialogContext,
                      icon: LucideIcons.building2,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'VODAFONE',
                        child: Text(AppLocalizations.of(dialogContext)!.mobileWallet),
                      ),
                      DropdownMenuItem(
                        value: 'INSTAPAY',
                        child: Text(AppLocalizations.of(dialogContext)!.instaPay),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (v) {
                            setState(() {
                              selectedProvider = v ?? 'VODAFONE';
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  AppFieldLabel(
                    label: l10n.walletNumber,
                    isRequired: true,
                  ),
                  TextField(
                    controller: numberController,
                    enabled: !submitting,
                    keyboardType: TextInputType.phone,
                    decoration: AppDialogStyles.inputDecoration(
                      dialogContext,
                      hintText: l10n.walletNumberHint,
                      icon: LucideIcons.hash,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    AppDialogErrorBanner(message: error!),
                  ],
                ],
              ),
              footer: AppDialogFooter(
                cancelLabel: l10n.cancelAction,
                onCancel: () => Navigator.pop(c),
                confirmLabel: l10n.addWallet,
                confirmIcon: LucideIcons.plus,
                isLoading: submitting,
                onConfirm: submit,
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        numberController.dispose,
      );
    });
  }
}
