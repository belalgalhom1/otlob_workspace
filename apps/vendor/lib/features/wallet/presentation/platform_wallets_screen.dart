import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
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
              Text('$err', style: const TextStyle(color: AppColors.error)),
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
                                      if (type.contains('VODAFONE')) return l10n.mobileWallet;
                                      if (type.contains('INSTAPAY')) return l10n.instaPay;
                                      return wallet['type']?.toString() ?? '';
                                    }(),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                                Text(
                                  wallet['number'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: 0.5,
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
                                content: Text('${l10n.walletFailed}: $e'),
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
    showDialog(
      context: context,
      builder: (c) {
        String selectedProvider = 'VODAFONE';
        final numberController = TextEditingController();
        String? error;
        bool submitting = false;
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
                  error = '${l10n.walletFailed}: $e';
                });
              }
            }

            return DialogScaffold(child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(LucideIcons.wallet, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.addPlatformWallet)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedProvider,
                    decoration: InputDecoration(
                      labelText: l10n.walletProvider,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(LucideIcons.building2),
                    ),
                    items: [
                      DropdownMenuItem(value: 'VODAFONE', child: Text(AppLocalizations.of(dialogContext)!.mobileWallet)),
                      DropdownMenuItem(value: 'INSTAPAY', child: Text(AppLocalizations.of(dialogContext)!.instaPay)),
                    ],
                    onChanged: (v) {
                      setState(() {
                        selectedProvider = v ?? 'VODAFONE';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.walletNumber,
                      hintText: l10n.walletNumberHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(LucideIcons.hash),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(c),
                  child: Text(l10n.cancelAction),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.plus, size: 16),
                  onPressed: submitting ? null : submit,
                  label: Text(l10n.addWallet),
                ),
              ],
            ));
          }
        );
      },
    );
  }
}
