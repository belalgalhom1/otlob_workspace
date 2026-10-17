import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:intl/intl.dart';
import 'vendor_wallet_provider.dart';
import 'vendor_finance_statistics_screen.dart';

class VendorWalletScreen extends ConsumerWidget {
  const VendorWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(vendorWalletDataProvider);
    final theme = Theme.of(context);

    return state.when(
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
              onPressed: () => ref.invalidate(vendorWalletDataProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('No vendor selected or found.'));
        }
        
        final balanceData = data['balance'] is Map ? data['balance'] as Map<String, dynamic> : <String, dynamic>{};
        final balance = double.tryParse(
            (balanceData['walletBalance'] ?? balanceData['balance'] ?? '0').toString()
        ) ?? 0.0;
        
        final transactions = data['transactions'] as List<dynamic>;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vendorWalletDataProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildBalanceCard(context, balance, theme),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar' ? 'المعاملات' : 'Transactions',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (transactions.isNotEmpty)
                        TextButton.icon(
                          onPressed: () =>
                              _exportTransactions(context, balance, transactions),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(
                            Localizations.localeOf(context).languageCode == 'ar' ? 'تصدير' : 'Export',
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VendorFinanceStatisticsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.chartNoAxesCombined, size: 18),
                        label: Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'الإحصائيات' : 'Statistics',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(LucideIcons.receipt, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...transactions.map((tx) => _buildTransactionCard(context, tx, theme)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportTransactions(
    BuildContext context,
    double balance,
    List<dynamic> transactions,
  ) async {
    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final headers = [
      isArabic ? 'التاريخ' : 'Date',
      isArabic ? 'النوع' : 'Type',
      isArabic ? 'الوصف' : 'Description',
      isArabic ? 'المبلغ' : 'Amount',
      isArabic ? 'الرصيد بعد' : 'Balance After',
    ];
    final rows = [
      for (final tx in transactions)
        [
          tx['createdAt'] != null
              ? dateFormat.format(
                  DateTime.parse(tx['createdAt'].toString()).toLocal())
              : '',
          (tx['type']?.toString() ?? '').replaceAll('_', ' '),
          tx['description']?.toString() ?? '',
          '${(double.tryParse(tx['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)} EGP',
          tx['balanceAfter'] != null
              ? '${(double.tryParse(tx['balanceAfter'].toString()) ?? 0).toStringAsFixed(2)} EGP'
              : '',
        ],
    ];

    await DataExportService.showExportOptions(
      context,
      title: isArabic ? 'كشف حساب المعاملات المالية' : 'Financial Transactions',
      subtitle: isArabic
          ? 'الرصيد المتاح: ${balance.toStringAsFixed(2)} EGP'
          : 'Available balance: ${balance.toStringAsFixed(2)} EGP',
      headers: headers,
      rows: rows,
      filename: 'financial_transactions',
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.wallet, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${balance.toStringAsFixed(2)} EGP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, dynamic tx, ThemeData theme) {
    final type = tx['type'] ?? 'UNKNOWN';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final date = tx['createdAt'] != null
        ? DateTime.parse(tx['createdAt'].toString()).toLocal()
        : DateTime.now();
    final description = tx['description'] as String? ?? '';
    
    final isCredit = amount >= 0;
    final color = isCredit ? AppColors.success : AppColors.error;
    final icon = isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
    final sign = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${amount.abs().toStringAsFixed(2)} EGP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
