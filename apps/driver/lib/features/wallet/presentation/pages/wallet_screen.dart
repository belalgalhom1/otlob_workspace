import 'dart:ui' as ui show TextDirection;

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
    final rawCurrency =
        ref.watch(configurationProvider).value?['currency']?.toString() ?? 'EGP';
    final currency =
        (l10n.localeName == 'ar' && rawCurrency == 'EGP') ? 'ج.م' : rawCurrency;

    final body = walletState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(child: Text(ErrorUtils.translate(context, error))),
      data: (data) {
        final balance = data['balance'] ?? 0.0;
        final transactions = data['transactions'] as List<dynamic>? ?? [];
        final topUpRequests = (data['topUpRequests'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
              SliverSafeArea(
                bottom: false,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (settlementRequired) ...[
                          _buildSettlementBanner(context, l10n),
                          const SizedBox(height: 24),
                        ],
                        _buildBalanceCard(context, ref, balance, currency, l10n),
                        const SizedBox(height: 28),
                        Text(
                          l10n.recentTransactions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
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
              if (topUpRequests.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: _buildTopUpRequestsSection(
                      context,
                      topUpRequests,
                      currency,
                      l10n,
                    ),
                  ),
                ),
              const SliverSafeArea(
                top: false,
                sliver: SliverToBoxAdapter(
                  child: SizedBox(height: 16),
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
              Flexible(
                child: Text(
                  cardTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isNegative ? Colors.amberAccent : const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                displayAmount,
                maxLines: 1,
                style: TextStyle(
                  color: isNegative ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: isAr ? null : 0.5,
                ),
              ),
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNegative ? AppColors.primary : Theme.of(context).colorScheme.surface,
                    foregroundColor: isNegative ? Colors.black : Theme.of(context).colorScheme.onSurface,
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  onPressed: () {
                    final platformWallets = ref.read(driverWalletProvider).value?['platformWallets'] as List<dynamic>? ?? [];
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TopUpBottomSheet(platformWallets: platformWallets),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isNegative ? LucideIcons.arrowUpRight : LucideIcons.arrowUpCircle, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          settleLabel,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNegative ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF0F172A).withValues(alpha: 0.12),
                    foregroundColor: isNegative ? Colors.white : const Color(0xFF0F172A),
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  onPressed: () {
                    final driverWallets = ref.read(driverWalletProvider).value?['driverWallets'] as List<dynamic>? ?? [];
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ManageWalletsBottomSheet(driverWallets: driverWallets),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.arrowDownCircle, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.manageWallets,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
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
      case 'ORDER_EARNING':
      case 'DELIVERY_EARNING':
      case 'RIDE_EARNING':
        return isAr ? 'أرباح التوصيل' : 'Order earning';
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
      case 'GOLD_BONUS':
        return isAr ? 'مكافأة الشارة الذهبية' : 'Gold badge bonus';
      case 'BRONZE_DEDUCTION':
      case 'BRONZE_SUPERVISOR_DEDUCTION':
        return isAr ? 'خصم الشارة البرونزية' : 'Bronze badge deduction';
      case 'ADJUSTMENT':
      case 'WALLET_ADJUSTMENT':
        return isAr ? 'تسوية المحفظة' : 'Wallet adjustment';
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

  String _formatPlatformWalletLabel(
    Map<String, dynamic> tx,
    bool isArabic,
  ) {
    final walletMap =
        tx['platformWallet'] is Map ? tx['platformWallet'] as Map : null;
    final rawType =
        (walletMap?['type'] ?? tx['platformWalletType'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
    final rawNumber =
        (walletMap?['number'] ?? tx['platformWalletNumber'] ?? '')
            .toString()
            .trim();
    if (rawType.isEmpty && rawNumber.isEmpty) return '';

    final baseLabel = rawType == 'INSTAPAY'
        ? (isArabic ? 'إنستا باي' : 'InstaPay')
        : (isArabic ? 'محفظة إلكترونية' : 'Mobile Wallet');
    if (rawNumber.isEmpty) return baseLabel;
    return isArabic ? '$baseLabel - \u2066$rawNumber\u2069' : '$baseLabel - $rawNumber';
  }

  Widget _buildTopUpRequestsSection(
    BuildContext context,
    List<Map<String, dynamic>> topUpRequests,
    String currency,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final warnAccent = isDark ? AppColors.warning : const Color(0xFF92400E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.fileText,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.topUpRequestsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...topUpRequests.map((tx) {
          final status =
              (tx['status'] ?? 'PENDING').toString().trim().toUpperCase();
          final amount =
              double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
          final createdAtStr = tx['createdAt']?.toString();
          final createdAt = (createdAtStr != null
                  ? DateTime.tryParse(createdAtStr)
                  : null)
              ?.toLocal();
          final reviewedAtStr = tx['reviewedAt']?.toString();
          final reviewedAt = (reviewedAtStr != null
                  ? DateTime.tryParse(reviewedAtStr)
                  : null)
              ?.toLocal();
          final rawNotes = (tx['notes'] ?? '').toString().trim();
          final walletLabel = _formatPlatformWalletLabel(tx, isArabic);

          late final Color accent;
          late final IconData statusIcon;
          late final String statusLabel;
          if (status == 'APPROVED') {
            accent = AppColors.success;
            statusIcon = LucideIcons.checkCircle2;
            statusLabel = l10n.approved;
          } else if (status == 'REJECTED') {
            accent = AppColors.error;
            statusIcon = LucideIcons.circleAlert;
            statusLabel = l10n.rejected;
          } else {
            accent = warnAccent;
            statusIcon = LucideIcons.clock;
            statusLabel = l10n.pendingApproval;
          }

          final isRejected = status == 'REJECTED';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: accent),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        '+${amount.toStringAsFixed(2)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (walletLabel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.banknote,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          walletLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatTxDate(createdAt, l10n),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
                if (reviewedAt != null && status != 'PENDING') ...[
                  const SizedBox(height: 3),
                  Text(
                    '${l10n.reviewedAtLabel}: ${_formatTxDate(reviewedAt, l10n)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
                if (rawNotes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? AppColors.error.withValues(alpha: 0.08)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRejected
                            ? AppColors.error.withValues(alpha: 0.25)
                            : theme.dividerColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRejected
                              ? l10n.rejectionReasonLabel
                              : l10n.adminNoteLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isRejected
                                ? AppColors.error
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rawNotes,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  (IconData, Color) _transactionVisuals(String type, bool isCredit) {
    switch (type) {
      case 'DELIVERY_FEE':
        return (LucideIcons.bike, AppColors.primary);
      case 'CASH_HANDED_TO_VENDOR':
        return (LucideIcons.store, AppColors.success);
      case 'CASH_COLLECTED':
        return (LucideIcons.handCoins, const Color(0xFFF59E0B));
      case 'PENALTY':
        return (LucideIcons.alertTriangle, AppColors.error);
      case 'BONUS':
        return (LucideIcons.gift, AppColors.primary);
      case 'ADJUSTMENT':
        return (
          LucideIcons.slidersHorizontal,
          isCredit ? AppColors.success : AppColors.error,
        );
      default:
        return (
          isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
          isCredit ? AppColors.success : AppColors.error,
        );
    }
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> tx, AppLocalizations l10n) {
    final type = (tx['type'] ?? 'UNKNOWN').toString().toUpperCase().trim();
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final isCredit = amount >= 0;
    final dateStr = tx['createdAt']?.toString();
    final date = (dateStr != null ? DateTime.tryParse(dateStr) : null)?.toLocal() ?? DateTime.now();
    final rawNote = tx['note']?.toString().trim();
    final hasNote = rawNote != null && rawNote.isNotEmpty;

    final (icon, iconColor) = _transactionVisuals(type, isCredit);
    final bgColor = iconColor.withValues(alpha: 0.14);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _transactionTypeLabel(type, l10n),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Text(
                          '${isCredit ? '+' : '-'}${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isCredit
                                ? AppColors.success
                                : (type == 'CASH_COLLECTED'
                                    ? const Color(0xFFF59E0B)
                                    : AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTxDate(date, l10n),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 6),
                    Text(
                      rawNote,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
