import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'pending_topups_screen.dart';
import 'platform_wallets_screen.dart';
import 'vendor_wallet_screen.dart';
import 'platform_statistics_screen.dart';

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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final showAdminTabs =
        (userRole ?? '') != 'VENDOR_MEMBER' && canManageFinance == true;

    return DefaultTabController(
      length: showAdminTabs ? 2 : 1,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section matching PromotionsScreen
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
                child: Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: isMobile ? 0 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.walletAndFinancials,
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.financialsSubtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                dividerColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: showAdminTabs
                    ? [
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
                      ]
                    : [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.wallet, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.walletAndFinancials), // Just "My Wallet" basically
                            ],
                          ),
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 16),
            // Platform statistics shortcut (admin only)
            if (showAdminTabs && canViewStatistics == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PlatformStatisticsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.chartNoAxesCombined,
                          size: 18),
                      label: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'إحصائيات المنصة'
                            : 'Platform Statistics',
                      ),
                    ),
                  ],
                ),
              ),
            // Tab content
            Expanded(
              child: TabBarView(
                children: showAdminTabs
                    ? [const PendingTopUpsScreen(), const PlatformWalletsScreen()]
                    : [const VendorWalletScreen()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
