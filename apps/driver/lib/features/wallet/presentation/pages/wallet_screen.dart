import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/features/wallet/presentation/widgets/top_up_bottom_sheet.dart';
import 'package:driver/features/wallet/presentation/widgets/manage_wallets_bottom_sheet.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final walletState = ref.watch(driverWalletProvider);
    final currency = ref.watch(configurationProvider.notifier).currency;

    return walletState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(child: Text(AppLocalizations.of(context)!.errorOccurred(error.toString()))),
      data: (data) {
        final balance = data['balance'] ?? 0.0;
        final transactions = data['transactions'] as List<dynamic>? ?? [];
        final topUpRequests = data['topUpRequests'] as List<dynamic>? ?? [];
        final pendingTopUps = topUpRequests.where((e) => e['status'] == 'PENDING').toList();

        return RefreshIndicator(
          onRefresh: () async {
            // ref.read(driverWalletProvider.notifier)._fetchWalletData()
            // using the provider invalidation is better:
            ref.invalidate(driverWalletProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBalanceCard(context, ref, balance, currency, l10n),
                      const SizedBox(height: 32),
                      if (pendingTopUps.isNotEmpty) ...[
                        Text(
                          l10n.pendingApproval,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        ...pendingTopUps.map((tx) {
                          final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.clock, color: AppColors.warning),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.pendingApproval,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                                Text(
                                  '+${amount.toStringAsFixed(2)} $currency',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.warning),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        l10n.recentTransactions,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (transactions.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: LucideIcons.banknote,
                    title: l10n.noTransactions,
                    subtitle: l10n.noTransactionsSubtitle,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = transactions[index];
                      return _buildTransactionItem(context, tx, l10n);
                    },
                    childCount: transactions.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, num balance, String currency, AppLocalizations l10n) {
    final bool isNegative = balance < 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.availableBalance,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$balance $currency',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (isNegative)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.negativeBalanceWarning,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  icon: const Icon(LucideIcons.arrowUpCircle),
                  label: Text(l10n.topUp),
                  onPressed: () {
                    final platformWallets = ref.read(driverWalletProvider).value?['platformWallets'] as List<dynamic>? ?? [];
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TopUpBottomSheet(platformWallets: platformWallets),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.arrowDownCircle),
                  label: Text(l10n.manageWallets),
                  onPressed: () {
                    final driverWallets = ref.read(driverWalletProvider).value?['driverWallets'] as List<dynamic>? ?? [];
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ManageWalletsBottomSheet(driverWallets: driverWallets),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> tx, AppLocalizations l10n) {
    final type = tx['type'] ?? 'UNKNOWN';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final isCredit = amount >= 0;
    final dateStr = tx['createdAt']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCredit ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
          color: isCredit ? AppColors.success : AppColors.error,
        ),
      ),
      title: Text(
        type.toString().replaceAll('_', ' '),
        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy - hh:mm a').format(date),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}${amount.abs().toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isCredit ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
