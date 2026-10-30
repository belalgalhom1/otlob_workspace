import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/features/wallet/presentation/widgets/top_up_bottom_sheet.dart';
import 'package:driver/features/wallet/presentation/widgets/manage_wallets_bottom_sheet.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:intl/intl.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final walletState = ref.watch(driverWalletProvider);
    final currency = ref.watch(configurationProvider.notifier).currency;

    final body = walletState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(child: Text(ErrorUtils.translate(context, error))),
      data: (data) {
        final balance = data['balance'] ?? 0.0;
        final transactions = data['transactions'] as List<dynamic>? ?? [];
        final topUpRequests = data['topUpRequests'] as List<dynamic>? ?? [];
        final pendingTopUps = topUpRequests.where((e) => e['status'] == 'PENDING').toList();
        final profileValue = ref.watch(driverProfileProvider).value;
        final profileData = (profileValue is Map && profileValue['data'] is Map)
            ? profileValue['data'] as Map
            : (profileValue is Map ? profileValue : <String, dynamic>{});
        final settlementRequired = profileData['hasUnpaidCommission'] == true && balance < 0;

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
                      if (settlementRequired) ...[
                        _buildSettlementBanner(context, l10n),
                        const SizedBox(height: 24),
                      ],
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

    if (Navigator.canPop(context)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.wallet),
        ),
        body: body,
      );
    }
    return body;
  }

  Widget _buildSettlementBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.handCoins, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.settlementRequiredBanner,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, num balance, String currency, AppLocalizations l10n) {
    final bool isNegative = balance < 0;
    final bool isAr = l10n.localeName == 'ar';

    final cardTitle = isNegative
        ? (isAr ? 'مستحقات المنصة في عهدتك' : 'Cash Due to Platform')
        : (isAr ? 'أرباحك المتاحة للسحب' : 'Available Earnings');

    final displayAmount = isNegative
        ? '${balance.abs().toStringAsFixed(0)} $currency'
        : '+${balance.toStringAsFixed(0)} $currency';

    final settleLabel = isNegative
        ? (isAr ? 'سداد وتوريد النقدية' : 'Settle Dues')
        : l10n.topUp;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isNegative
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        border: isNegative
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isNegative
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNegative ? LucideIcons.handCoins : LucideIcons.wallet,
                size: 16,
                color: isNegative ? Colors.amberAccent : const Color(0xFF0F172A),
              ),
              const SizedBox(width: 8),
              Text(
                cardTitle,
                style: TextStyle(
                  color: isNegative ? Colors.amberAccent : const Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayAmount,
            style: TextStyle(
              color: isNegative ? Colors.white : const Color(0xFF0F172A),
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          if (isNegative) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                isAr
                    ? 'نقدية محصلة من العملاء ومستحقة للمنصة بعد أرباحك'
                    : 'Customer cash collected awaiting remittance net of earnings',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNegative ? AppColors.primary : Theme.of(context).colorScheme.surface,
                    foregroundColor: isNegative ? Colors.black : Theme.of(context).colorScheme.onSurface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(isNegative ? LucideIcons.arrowUpRight : LucideIcons.arrowUpCircle, size: 18),
                  label: Text(settleLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    backgroundColor: isNegative ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF0F172A).withValues(alpha: 0.12),
                    foregroundColor: isNegative ? Colors.white : const Color(0xFF0F172A),
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

  String _transactionTypeLabel(String rawType, AppLocalizations l10n) {
    final isAr = l10n.localeName == 'ar';
    switch (rawType.toUpperCase().trim()) {
      case 'DELIVERY_FEE':
        return isAr ? 'رسوم التوصيل' : 'Delivery fee';
      case 'CASH_COLLECTED':
        return isAr ? 'نقدية محصلة' : 'Cash collected';
      case 'CASH_HANDED_TO_VENDOR':
        return isAr ? 'نقدية مسلمة للمتجر' : 'Cash handed to vendor';
      case 'PAYOUT':
        return isAr ? 'مدفوعات' : 'Payout';
      case 'PENALTY':
        return isAr ? 'غرامة' : 'Penalty';
      case 'BONUS':
        return isAr ? 'مكافأة' : 'Bonus';
      case 'ADJUSTMENT':
        return isAr ? 'تسوية' : 'Adjustment';
      case 'TOP_UP':
      case 'TOPUP':
      case 'TOPUP_REQUEST':
        return isAr ? 'شحن' : 'Top up';
      case 'REFUND':
        return isAr ? 'استرداد' : 'Refund';
      case 'COMMISSION':
      case 'COMMISSION_DEDUCTION':
        return isAr ? 'عمولة' : 'Commission';
      default:
        final pretty = rawType.replaceAll('_', ' ').trim().toLowerCase();
        if (pretty.isEmpty) return isAr ? 'معاملة' : 'Transaction';
        return pretty[0].toUpperCase() + pretty.substring(1);
    }
  }

  String _formatTxDate(DateTime date, AppLocalizations l10n) {
    // `ar` date symbols need initializeDateFormatting (not called in main),
    // so fall back to the default locale pattern instead of crashing.
    try {
      return DateFormat('dd MMM yyyy - hh:mm a', l10n.localeName).format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy - hh:mm a').format(date);
    }
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> tx, AppLocalizations l10n) {
    final type = (tx['type'] ?? 'UNKNOWN').toString().toUpperCase().trim();
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final isCredit = amount >= 0;
    final dateStr = tx['createdAt']?.toString();
    final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
    final note = tx['note']?.toString();

    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'DELIVERY_FEE':
        icon = LucideIcons.bike;
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        break;
      case 'CASH_HANDED_TO_VENDOR':
        icon = LucideIcons.store;
        iconColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.15);
        break;
      case 'CASH_COLLECTED':
        icon = LucideIcons.handCoins;
        iconColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        break;
      case 'PENALTY':
        icon = LucideIcons.alertTriangle;
        iconColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.15);
        break;
      case 'BONUS':
        icon = LucideIcons.gift;
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        break;
      default:
        icon = isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
        iconColor = isCredit ? AppColors.success : AppColors.error;
        bgColor = (isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.12);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            _transactionTypeLabel(type, l10n),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                _formatTxDate(date, l10n),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: Text(
            '${isCredit ? '+' : '-'}${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isCredit ? AppColors.success : (type == 'CASH_COLLECTED' ? const Color(0xFFF59E0B) : AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}
