import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'pending_topups_screen.dart';
import 'platform_wallets_screen.dart';
import 'vendor_wallet_screen.dart';
import 'platform_statistics_screen.dart';
import 'driver_manager_wallet_screen.dart';

class WalletDashboardScreen extends ConsumerWidget {
  final String? userRole;
  final bool? canManageFinance;
  final bool? canViewStatistics;
  const WalletDashboardScreen({
    super.key,
    this.userRole,
    this.canManageFinance,
    this.canViewStatistics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final isDriverManager = (userRole ?? '') == 'DRIVER_MANAGER';
    final isVendor = (userRole ?? '') == 'VENDOR_MEMBER';
    final showAdminTabs =
        !isVendor && !isDriverManager && canManageFinance == true;

    final subtitleText = isVendor
        ? (isArabic
              ? 'تابع رصيد متجرك والمعاملات المالية ومبيعات المنتجات والإحصائيات'
              : 'Track your store balance, financial transactions, product sales, and statistics')
        : isDriverManager
        ? (isArabic
              ? 'تابع أرباح عمولات منطقتك وسجل المعاملات المالية'
              : 'Track your zone commission earnings and wallet transaction history')
        : l10n.financialsSubtitle;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 12 : 20,
        isMobile ? 16 : 24,
        showAdminTabs ? 12 : 8,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 22),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.walletAndFinancials,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: isArabic ? null : -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitleText,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    if (!showAdminTabs) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Expanded(
              child: isDriverManager
                  ? const DriverManagerWalletScreen()
                  : const VendorWalletScreen(),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              child: TabBar(
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                dividerColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.1,
                ),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clock, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.pendingTopUps),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.wallet, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.platformWallets),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (canViewStatistics == true)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlatformStatisticsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          LucideIcons.chartNoAxesCombined,
                          size: 18,
                        ),
                        label: Text(
                          isArabic ? 'إحصائيات المنصة' : 'Platform Statistics',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Expanded(
              child: TabBarView(
                children: [PendingTopUpsScreen(), PlatformWalletsScreen()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
