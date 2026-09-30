import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

import 'package:data/data.dart';
import '../../providers/analytics_provider.dart';
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
              // Search bar + Export
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Export',
                    child: IconButton(
                      icon: Icon(LucideIcons.download, color: textColor),
                      onPressed: () => _exportCurrentTab(context, ref),
                    ),
                  ),
                ],
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

  Future<void> _exportCurrentTab(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final query = _searchQuery.trim().toLowerCase();
    final sortBy = _sortBy;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final tab = _tabController.index;
    final l10n = AppLocalizations.of(context)!;

    switch (tab) {
      case 0: // Drivers
        final all =
            ref.read(topDriversProvider).value ?? const <AnalyticsDriver>[];
        var drivers = all.where((d) {
          if (query.isEmpty) return true;
          return d.name.toLowerCase().contains(query) ||
              (d.phone ?? '').contains(query);
        }).toList();
        if (sortBy == 'wallet') {
          drivers.sort((a, b) => b.walletBalance.compareTo(a.walletBalance));
        } else {
          drivers.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        }
        const headers = ['Rank', 'Name', 'Phone', 'Tier', 'Status', 'Orders', 'Wallet Balance'];
        final rows = [
          for (var i = 0; i < drivers.length; i++)
            [
              '${i + 1}',
              drivers[i].name,
              drivers[i].phone ?? '',
              drivers[i].tier,
              drivers[i].status,
              '${drivers[i].totalOrders}',
              drivers[i].walletBalance.toStringAsFixed(2),
            ],
        ];
        await DataExportService.showExportOptions(
          context,
          title: l10n.topDrivers,
          headers: headers,
          rows: rows,
          filename: 'top_drivers',
        );
      case 1: // Customers
        final all = ref.read(topCustomersProvider).value ??
            const <AnalyticsCustomer>[];
        var customers = all.where((c) {
          if (query.isEmpty) return true;
          return c.name.toLowerCase().contains(query) ||
              (c.phone ?? '').contains(query);
        }).toList();
        switch (sortBy) {
          case 'spent':
            customers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
            break;
          case 'coins':
            customers.sort((a, b) => b.coinBalance.compareTo(a.coinBalance));
            break;
          default:
            customers.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        }
        const headers = ['Rank', 'Name', 'Phone', 'Orders', 'Total Spent', 'Coins'];
        final rows = [
          for (var i = 0; i < customers.length; i++)
            [
              '${i + 1}',
              customers[i].name,
              customers[i].phone ?? '',
              '${customers[i].totalOrders}',
              customers[i].totalSpent.toStringAsFixed(2),
              customers[i].coinBalance.toStringAsFixed(2),
            ],
        ];
        await DataExportService.showExportOptions(
          context,
          title: l10n.topCustomers,
          headers: headers,
          rows: rows,
          filename: 'top_customers',
        );
      case 2: // Vendors
        final all =
            ref.read(topVendorsProvider).value ?? const <AnalyticsVendor>[];
        var vendors = all.where((v) {
          if (query.isEmpty) return true;
          final name = isArabic ? (v.storeNameAr ?? v.storeName) : v.storeName;
          return name.toLowerCase().contains(query);
        }).toList();
        switch (sortBy) {
          case 'revenue':
            vendors.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
            break;
          case 'wallet':
            vendors.sort((a, b) => b.walletBalance.compareTo(a.walletBalance));
            break;
          default:
            vendors.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        }
        const headers = [
          'Rank',
          'Store',
          'Orders',
          'Revenue',
          'Wallet Balance',
          'Top Product',
          'Top Product Orders',
        ];
        final rows = [
          for (var i = 0; i < vendors.length; i++)
            [
              '${i + 1}',
              isArabic
                  ? (vendors[i].storeNameAr ?? vendors[i].storeName)
                  : vendors[i].storeName,
              '${vendors[i].totalOrders}',
              vendors[i].totalRevenue.toStringAsFixed(2),
              vendors[i].walletBalance.toStringAsFixed(2),
              vendors[i].topProduct != null
                  ? (isArabic
                      ? (vendors[i].topProduct!.nameAr ??
                          vendors[i].topProduct!.name)
                      : vendors[i].topProduct!.name)
                  : '',
              vendors[i].topProduct != null
                  ? '${vendors[i].topProduct!.totalOrders}'
                  : '',
            ],
        ];
        await DataExportService.showExportOptions(
          context,
          title: l10n.topVendors,
          headers: headers,
          rows: rows,
          filename: 'top_vendors',
        );
      case 3: // Products
        final all = ref.read(topProductsProvider).value ??
            const <AnalyticsTopProduct>[];
        var products = all.where((p) {
          if (query.isEmpty) return true;
          final name = isArabic ? (p.nameAr ?? p.name) : p.name;
          return name.toLowerCase().contains(query);
        }).toList();
        products.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        const headers = ['Rank', 'Product', 'Orders'];
        final rows = [
          for (var i = 0; i < products.length; i++)
            [
              '${i + 1}',
              isArabic
                  ? (products[i].nameAr ?? products[i].name)
                  : products[i].name,
              '${products[i].totalOrders}',
            ],
        ];
        await DataExportService.showExportOptions(
          context,
          title: l10n.topProduct,
          headers: headers,
          rows: rows,
          filename: 'top_products',
        );
    }
  }
}

class _SortOption {
  final String value;
  final String label;
  final IconData icon;
  const _SortOption(this.value, this.label, this.icon);
}
