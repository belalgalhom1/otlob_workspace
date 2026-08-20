import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

import '../widgets/driver_rank_table.dart';
import '../widgets/customer_rank_table.dart';
import '../widgets/vendor_rank_table.dart';
import 'package:vendor/features/analytics/presentation/widgets/product_rank_table.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigate;
  const AnalyticsScreen({super.key, this.onNavigate});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'orders'; // orders | rating | price | trips

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_SortOption> get _sortOptions {
    final l10n = AppLocalizations.of(context)!;
    final tab = _tabController.index;
    switch (tab) {
      case 0: // Drivers
        return [
          _SortOption('orders', l10n.ordersCount, LucideIcons.shoppingBag),
          _SortOption('trips', l10n.analyticsTrips, LucideIcons.truck),
          _SortOption('wallet', l10n.analyticsBal, LucideIcons.wallet),
        ];
      case 1: // Customers
        return [
          _SortOption('orders', l10n.ordersCount, LucideIcons.shoppingBag),
          _SortOption('spent', l10n.analyticsTotalSpent, LucideIcons.banknote),
          _SortOption('coins', l10n.analyticsCoins, LucideIcons.coins),
        ];
      case 2: // Vendors
        return [
          _SortOption('orders', l10n.ordersCount, LucideIcons.shoppingBag),
          _SortOption('revenue', l10n.analyticsRevenue, LucideIcons.trendingUp),
          _SortOption('wallet', l10n.analyticsBal, LucideIcons.wallet),
        ];
      case 3: // Products
        return [
          _SortOption('orders', l10n.ordersCount, LucideIcons.shoppingBag),
        ];
      default:
        return [
          _SortOption('orders', l10n.ordersCount, LucideIcons.shoppingBag),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    // Reset sort to first option when switching tabs
    final sortOptions = _sortOptions;
    final validSort = sortOptions.any((o) => o.value == _sortBy)
        ? _sortBy
        : sortOptions.first.value;

    return Column(
      children: [
        // ── Tab Bar ──────────────────────────────────────────────────
        Container(
          color: surfaceColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (_) {
              setState(() {
                _sortBy = 'orders';
              });
            },
            tabs: [
              Tab(text: l10n.topDrivers),
              Tab(text: l10n.topCustomers),
              Tab(text: l10n.topVendors),
              Tab(text: l10n.topProduct),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
          ),
        ),

        // ── Search + Sort ─────────────────────────────────────────────
        Container(
          color: surfaceColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.black38,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black38,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(LucideIcons.x,
                                size: 16, color: textColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 4),
                  ),
                ),
              ),

              // Sort chips
              if (sortOptions.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sortOptions.length,
                    separatorBuilder: (_, x) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final opt = sortOptions[i];
                      final isSelected = opt.value == validSort;
                      return GestureDetector(
                        onTap: () => setState(() => _sortBy = opt.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                opt.icon,
                                size: 13,
                                color: isSelected
                                    ? Colors.white
                                    : textColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Divider ───────────────────────────────────────────────────
        Divider(height: 1, color: borderColor),

        // ── Tab Views ─────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              DriverRankTable(
                searchQuery: _searchQuery,
                sortBy: validSort,
                onDriverTap: widget.onNavigate != null
                    ? (_) => widget.onNavigate!(3)
                    : null,
              ),
              CustomerRankTable(
                searchQuery: _searchQuery,
                sortBy: validSort,
              ),
              VendorRankTable(
                searchQuery: _searchQuery,
                sortBy: validSort,
                onVendorTap: widget.onNavigate != null
                    ? (vendorId) => widget.onNavigate!(2)
                    : null,
              ),
              ProductRankTable(
                searchQuery: _searchQuery,
                sortBy: validSort,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortOption {
  final String value;
  final String label;
  final IconData icon;
  const _SortOption(this.value, this.label, this.icon);
}
