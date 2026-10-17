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

  /// Export dialog: scope (this tab / all tabs) × language (Arabic /
  /// English) × format (Excel CSV / PDF). "All tabs" lands every section in
  /// one file (one PDF page per tab).
  Future<void> _exportCurrentTab(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final isUiArabic =
        Localizations.localeOf(context).languageCode == 'ar';
    var allTabs = false;
    var arabic = isUiArabic;
    var format = 'excel'; // excel | pdf
    var rangeMode = 'all'; // all | today | 7 | 30 | month | custom
    DateTimeRange? customRange;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedColor = AppColors.primary;
          final unselectedColor =
              Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7);

          Widget chip(
            String label,
            bool selected,
            VoidCallback onTap, {
            IconData? icon,
          }) {
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: selected ? selectedColor : unselectedColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(label),
                ],
              ),
              selected: selected,
              onSelected: (_) => onTap(),
              selectedColor: selectedColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? selectedColor : unselectedColor,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              side: BorderSide(
                color: selected
                    ? selectedColor
                    : Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.15),
              ),
            );
          }

          final loc = (String en, String ar) => arabic ? ar : en;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(isUiArabic ? 'تصدير التحليلات' : 'Export Analytics'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUiArabic ? 'النطاق' : 'Scope',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      chip(
                        isUiArabic ? 'هذا التبويب' : 'This tab',
                        !allTabs,
                        () => setDialogState(() => allTabs = false),
                      ),
                      chip(
                        isUiArabic ? 'كل التبويبات' : 'All tabs',
                        allTabs,
                        () => setDialogState(() => allTabs = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUiArabic ? 'اللغة' : 'Language',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      chip(
                        'العربية',
                        arabic,
                        () => setDialogState(() => arabic = true),
                      ),
                      chip(
                        'English',
                        !arabic,
                        () => setDialogState(() => arabic = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc('Excel and PDF will use the selected language.',
                        'سيتم استخدام اللغة المحددة في Excel و PDF.'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUiArabic ? 'المدة' : 'Date range',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip(
                        isUiArabic ? 'كل الوقت' : 'All time',
                        rangeMode == 'all',
                        () => setDialogState(() => rangeMode = 'all'),
                      ),
                      chip(
                        isUiArabic ? 'اليوم' : 'Today',
                        rangeMode == 'today',
                        () => setDialogState(() => rangeMode = 'today'),
                      ),
                      chip(
                        isUiArabic ? 'آخر ٧ أيام' : 'Last 7 days',
                        rangeMode == '7',
                        () => setDialogState(() => rangeMode = '7'),
                      ),
                      chip(
                        isUiArabic ? 'آخر ٣٠ يوم' : 'Last 30 days',
                        rangeMode == '30',
                        () => setDialogState(() => rangeMode = '30'),
                      ),
                      chip(
                        isUiArabic ? 'هذا الشهر' : 'This month',
                        rangeMode == 'month',
                        () => setDialogState(() => rangeMode = 'month'),
                      ),
                      chip(
                        rangeMode == 'custom' && customRange != null
                            ? '${_fmtDate(customRange!.start)} – ${_fmtDate(customRange!.end)}'
                            : (isUiArabic ? 'مخصص' : 'Custom'),
                        rangeMode == 'custom',
                        () async {
                          final picked = await showDateRangePicker(
                            context: ctx,
                            firstDate: DateTime(DateTime.now().year - 2),
                            lastDate: DateTime.now(),
                            initialDateRange: customRange,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              rangeMode = 'custom';
                              customRange = picked;
                            });
                          }
                        },
                        icon: LucideIcons.calendarRange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUiArabic ? 'الصيغة' : 'Format',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      chip(
                        'Excel',
                        format == 'excel',
                        () => setDialogState(() => format = 'excel'),
                        icon: LucideIcons.fileSpreadsheet,
                      ),
                      chip(
                        'PDF',
                        format == 'pdf',
                        () => setDialogState(() => format = 'pdf'),
                        icon: LucideIcons.fileText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isUiArabic ? 'إلغاء' : 'Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  format == 'excel'
                      ? LucideIcons.fileSpreadsheet
                      : LucideIcons.fileText,
                  size: 16,
                ),
                label: Text(isUiArabic ? 'تصدير' : 'Export'),
                onPressed: () => Navigator.pop(
                      ctx,
                      '$format:$allTabs:$arabic:$rangeMode:'
                      '${customRange?.start.millisecondsSinceEpoch ?? ''}:'
                      '${customRange?.end.millisecondsSinceEpoch ?? ''}',
                    ),
              ),
            ],
          );
        },
      ),
    );
    if (choice == null || !context.mounted) return;

    final parts = choice.split(':');
    final wantAll = parts[1] == 'true';
    final ar = parts[2] == 'true';
    final mode = parts.length > 3 ? parts[3] : 'all';
    final fromMs = parts.length > 4 && parts[4].isNotEmpty
        ? int.tryParse(parts[4])
        : null;
    final toMs = parts.length > 5 && parts[5].isNotEmpty
        ? int.tryParse(parts[5])
        : null;

    // Resolve the chosen period into concrete from/to instants. "All time"
    // leaves them null so the report matches the on-screen data.
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    switch (mode) {
      case 'today':
        from = DateTime(now.year, now.month, now.day);
        to = now;
        break;
      case '7':
        from = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        to = now;
        break;
      case '30':
        from = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        to = now;
        break;
      case 'month':
        from = DateTime(now.year, now.month, 1);
        to = now;
        break;
      case 'custom':
        if (fromMs != null && toMs != null) {
          final s = DateTime.fromMillisecondsSinceEpoch(fromMs);
          final e = DateTime.fromMillisecondsSinceEpoch(toMs);
          from = DateTime(s.year, s.month, s.day);
          to = DateTime(e.year, e.month, e.day, 23, 59, 59);
        }
        break;
      default:
        from = null;
        to = null;
    }

    final query = _searchQuery.trim().toLowerCase();
    // Single-tab mode keeps the on-screen sort; all-tabs uses each
    // section's default (orders) sort.
    final sortBy = _sortBy;
    final tab = _tabController.index;

    final rangeSuffix = (from != null && to != null)
        ? '_${_fmtFileDate(from)}_${_fmtFileDate(to)}'
        : '';

    List<ExportSection> sections;
    String filename;
    if (wantAll) {
      sections = await Future.wait([
        _driversSection(ref, query, null, ar, from, to),
        _customersSection(ref, query, null, ar, from, to),
        _vendorsSection(ref, query, null, ar, from, to),
        _productsSection(ref, query, ar, from, to),
      ]);
      filename = 'analytics_report$rangeSuffix';
    } else {
      switch (tab) {
        case 0:
          sections = [
            await _driversSection(ref, query, sortBy, ar, from, to)
          ];
          filename = 'top_drivers$rangeSuffix';
          break;
        case 1:
          sections = [
            await _customersSection(ref, query, sortBy, ar, from, to)
          ];
          filename = 'top_customers$rangeSuffix';
          break;
        case 2:
          sections = [
            await _vendorsSection(ref, query, sortBy, ar, from, to)
          ];
          filename = 'top_vendors$rangeSuffix';
          break;
        default:
          sections = [await _productsSection(ref, query, ar, from, to)];
          filename = 'top_products$rangeSuffix';
          break;
      }
    }

    final rangeText = (from != null && to != null)
        ? ' (${_fmtDate(from)} – ${_fmtDate(to)})'
        : '';
    final reportTitle =
        (ar ? 'تقرير التحليلات' : 'Analytics Report') + rangeText;
    if (!context.mounted) return;
    try {
      if (parts[0] == 'excel') {
        await DataExportService.exportSectionsCsv(
          context: context,
          title: reportTitle,
          sections: sections,
          filename: filename,
        );
      } else {
        await DataExportService.exportSectionsPdf(
          context: context,
          title: reportTitle,
          sections: sections,
          filename: filename,
          isRtl: ar,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isUiArabic ? 'فشل التصدير' : 'Export failed'}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _tierLabel(String tier, bool ar) {
    switch (tier.toUpperCase()) {
      case 'GOLD':
        return ar ? 'ذهبي' : 'Gold';
      case 'SILVER':
        return ar ? 'فضي' : 'Silver';
      case 'BRONZE':
        return ar ? 'برونزي' : 'Bronze';
      default:
        return tier;
    }
  }

  String _driverStatusLabel(String status, bool ar) {
    switch (status.toUpperCase()) {
      case 'ONLINE':
        return ar ? 'متصل' : 'Online';
      case 'OFFLINE':
        return ar ? 'غير متصل' : 'Offline';
      case 'ON_DELIVERY':
        return ar ? 'في توصيلة' : 'On delivery';
      case 'ON_BREAK':
        return ar ? 'في استراحة' : 'On break';
      case 'SUSPENDED':
        return ar ? 'موقوف' : 'Suspended';
      case 'BUSY':
        return ar ? 'مشغول' : 'Busy';
      default:
        return status;
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _fmtFileDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<ExportSection> _driversSection(
    WidgetRef ref,
    String query,
    String? sortBy,
    bool ar,
    DateTime? from,
    DateTime? to,
  ) async {
    final all = (from == null && to == null)
        ? (ref.read(topDriversProvider).value ?? const <AnalyticsDriver>[])
        : await ref
            .read(analyticsRepositoryProvider)
            .getTopDrivers(limit: 20, from: from, to: to);
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
    return ExportSection(
      title: ar ? 'أفضل السائقين' : 'Top Drivers',
      headers: ar
          ? const ['الترتيب', 'الاسم', 'الهاتف', 'المستوى', 'الحالة', 'الطلبات', 'رصيد المحفظة']
          : const ['Rank', 'Name', 'Phone', 'Tier', 'Status', 'Orders', 'Wallet Balance'],
      rows: [
        for (var i = 0; i < drivers.length; i++)
          [
            '${i + 1}',
            drivers[i].name,
            drivers[i].phone ?? '',
            _tierLabel(drivers[i].tier, ar),
            _driverStatusLabel(drivers[i].status, ar),
            '${drivers[i].totalOrders}',
            drivers[i].walletBalance.toStringAsFixed(2),
          ],
      ],
    );
  }

  Future<ExportSection> _customersSection(
    WidgetRef ref,
    String query,
    String? sortBy,
    bool ar,
    DateTime? from,
    DateTime? to,
  ) async {
    final all = (from == null && to == null)
        ? (ref.read(topCustomersProvider).value ?? const <AnalyticsCustomer>[])
        : await ref
            .read(analyticsRepositoryProvider)
            .getTopCustomers(limit: 20, from: from, to: to);
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
    return ExportSection(
      title: ar ? 'أفضل العملاء' : 'Top Customers',
      headers: ar
          ? const ['الترتيب', 'الاسم', 'الهاتف', 'الطلبات', 'إجمالي الإنفاق', 'العملات']
          : const ['Rank', 'Name', 'Phone', 'Orders', 'Total Spent', 'Coins'],
      rows: [
        for (var i = 0; i < customers.length; i++)
          [
            '${i + 1}',
            customers[i].name,
            customers[i].phone ?? '',
            '${customers[i].totalOrders}',
            customers[i].totalSpent.toStringAsFixed(2),
            customers[i].coinBalance.toStringAsFixed(2),
          ],
      ],
    );
  }

  Future<ExportSection> _vendorsSection(
    WidgetRef ref,
    String query,
    String? sortBy,
    bool ar,
    DateTime? from,
    DateTime? to,
  ) async {
    final all = (from == null && to == null)
        ? (ref.read(topVendorsProvider).value ?? const <AnalyticsVendor>[])
        : await ref
            .read(analyticsRepositoryProvider)
            .getTopVendors(limit: 20, from: from, to: to);
    var vendors = all.where((v) {
      if (query.isEmpty) return true;
      final name = ar ? (v.storeNameAr ?? v.storeName) : v.storeName;
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
    return ExportSection(
      title: ar ? 'أفضل المتاجر' : 'Top Vendors',
      headers: ar
          ? const ['الترتيب', 'المتجر', 'الطلبات', 'الإيرادات', 'رصيد المحفظة', 'أفضل منتج', 'طلبات أفضل منتج']
          : const ['Rank', 'Store', 'Orders', 'Revenue', 'Wallet Balance', 'Top Product', 'Top Product Orders'],
      rows: [
        for (var i = 0; i < vendors.length; i++)
          [
            '${i + 1}',
            ar
                ? (vendors[i].storeNameAr ?? vendors[i].storeName)
                : vendors[i].storeName,
            '${vendors[i].totalOrders}',
            vendors[i].totalRevenue.toStringAsFixed(2),
            vendors[i].walletBalance.toStringAsFixed(2),
            vendors[i].topProduct != null
                ? (ar
                    ? (vendors[i].topProduct!.nameAr ??
                        vendors[i].topProduct!.name)
                    : vendors[i].topProduct!.name)
                : '',
            vendors[i].topProduct != null
                ? '${vendors[i].topProduct!.totalOrders}'
                : '',
          ],
      ],
    );
  }

  Future<ExportSection> _productsSection(
    WidgetRef ref,
    String query,
    bool ar,
    DateTime? from,
    DateTime? to,
  ) async {
    final all = (from == null && to == null)
        ? (ref.read(topProductsProvider).value ??
            const <AnalyticsTopProduct>[])
        : await ref
            .read(analyticsRepositoryProvider)
            .getTopProducts(limit: 20, from: from, to: to);
    var products = all.where((p) {
      if (query.isEmpty) return true;
      final name = ar ? (p.nameAr ?? p.name) : p.name;
      return name.toLowerCase().contains(query);
    }).toList();
    products.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
    return ExportSection(
      title: ar ? 'أفضل المنتجات' : 'Top Products',
      headers: ar
          ? const ['الترتيب', 'المنتج', 'الطلبات']
          : const ['Rank', 'Product', 'Orders'],
      rows: [
        for (var i = 0; i < products.length; i++)
          [
            '${i + 1}',
            ar
                ? (products[i].nameAr ?? products[i].name)
                : products[i].name,
            '${products[i].totalOrders}',
          ],
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
