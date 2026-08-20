import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/coin_history_provider.dart';

class CoinHistoryScreen extends ConsumerWidget {
  const CoinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinState = ref.watch(coinHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'سجل العملات' : 'Coin History', style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(coinHistoryProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _buildBalanceHeader(context, coinState.currentBalance),
            ),
            if (coinState.isLoading && coinState.transactions.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (coinState.error != null && coinState.transactions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'فشل تحميل السجل' : 'Failed to load history',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(coinHistoryProvider.notifier).refresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (coinState.transactions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.grey.withValues(alpha: 0.3), size: 100),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'لا توجد معاملات بعد' : 'No transactions yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = coinState.transactions[index];
                      return _buildTransactionItem(context, tx);
                    },
                    childCount: coinState.transactions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, int balance) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'الرصيد المتاح' : 'Available Balance',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final type = tx['type'] as String? ?? '';
    final amount = tx['amount'] as int? ?? 0;
    final balanceAfter = tx['balanceAfter'] as int? ?? 0;
    final dateStr = tx['createdAt'] as String?;
    final desc = tx['description'] as String? ?? (isAr ? 'معاملة عملات' : 'Coin transaction');

    IconData icon;
    Color iconBg;
    Color iconColor;
    String sign;
    Color amountColor;

    if (type == 'EARNED' || type == 'REFUNDED') {
      icon = Icons.arrow_downward_rounded;
      iconBg = Colors.green.withValues(alpha: 0.15);
      iconColor = Colors.green;
      sign = '+';
      amountColor = Colors.green;
    } else {
      icon = Icons.arrow_upward_rounded;
      iconBg = Colors.red.withValues(alpha: 0.15);
      iconColor = Colors.red;
      sign = '-';
      amountColor = Colors.red;
    }

    String formattedDate = '';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr).toLocal();
        formattedDate = DateFormat('MMM d, y, h:mm a').format(date);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (formattedDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign$amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isAr ? 'الرصيد: ' : 'Bal: '}$balanceAfter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
