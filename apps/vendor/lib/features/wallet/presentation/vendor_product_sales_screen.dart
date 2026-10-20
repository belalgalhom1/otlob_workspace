import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'vendor_product_sales_provider.dart';

class VendorProductSalesScreen extends ConsumerStatefulWidget {
  final String? vendorId;
  final String? vendorName;

  const VendorProductSalesScreen({super.key, this.vendorId, this.vendorName});

  @override
  ConsumerState<VendorProductSalesScreen> createState() =>
      _VendorProductSalesScreenState();
}

class _VendorProductSalesScreenState
    extends ConsumerState<VendorProductSalesScreen> {
  static const _sortOptions = <String>[
    'revenue',
    'quantity',
    'orders',
    'net',
    'name',
  ];

  final _searchController = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  static const int _pageSize = 20;
  int _page = 1;
  bool _exporting = false;
  String? _search;
  String _sortBy = 'revenue';
  String _sortOrder = 'desc';

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '0') ?? 0;
    return '${n.toStringAsFixed(2)} EGP';
  }

  int _int(dynamic value) {
    return int.tryParse(value?.toString().split('.').first ?? '0') ?? 0;
  }

  String _sortLabel(String key) {
    switch (key) {
      case 'quantity':
        return _isArabic ? 'الكمية' : 'Quantity';
      case 'orders':
        return _isArabic ? 'الطلبات' : 'Orders';
      case 'net':
        return _isArabic ? 'صافي الربح' : 'Net profit';
      case 'name':
        return _isArabic ? 'الاسم' : 'Name';
      case 'revenue':
      default:
        return _isArabic ? 'الإيرادات' : 'Revenue';
    }
  }

  String _productName(dynamic product) {
    final ar = product['productNameAr']?.toString();
    if (_isArabic && ar != null && ar.isNotEmpty) return ar;
    return product['productName']?.toString() ??
        (_isArabic ? 'منتج' : 'Product');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vendorId = widget.vendorId ?? ref.watch(activeVendorProvider);

    if (vendorId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isArabic ? 'المنتجات المباعة' : 'Products Sold'),
        ),
        body: Center(
          child: Text(
            _isArabic ? 'لم يتم اختيار متجر' : 'No vendor selected.',
          ),
        ),
      );
    }

    final args = (
      vendorId: vendorId,
      from: _from,
      to: _to,
      page: _page,
      limit: _pageSize,
      search: _search,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    final async = ref.watch(vendorProductSalesProvider(args));
    final data = async.asData?.value;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_isArabic ? 'المنتجات المباعة' : 'Products Sold'}'
              '${widget.vendorName != null ? ' - ${widget.vendorName}' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          if (data != null && data['products'] is List)
            IconButton(
              tooltip: _isArabic ? 'تصدير' : 'Export',
              onPressed: _exporting
                  ? null
                  : () => _export(
                        data['totals'] is Map
                            ? data['totals'] as Map<String, dynamic>
                            : const <String, dynamic>{},
                      ),
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                _isArabic
                    ? 'تعذر تحميل تقرير المبيعات'
                    : 'Could not load the sales report',
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(vendorProductSalesProvider(args)),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final products = data['products'] is List
              ? data['products'] as List<dynamic>
              : const <dynamic>[];
          final totals = data['totals'] is Map
              ? data['totals'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final totalPages = (data['totalPages'] as num?)?.toInt() ?? 0;
          final currentPage = (data['page'] as num?)?.toInt() ?? _page;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(vendorProductSalesProvider(args)),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _filters(context, theme),
                const SizedBox(height: 16),
                _summary(theme, totals),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isArabic ? 'المنتجات' : 'Products',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isArabic
                          ? '${_int(totals['productCount'])} منتج'
                          : '${_int(totals['productCount'])} products',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.packageSearch,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isArabic
                                ? 'لا توجد مبيعات في هذه الفترة'
                                : 'No sales in this period',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ...products.map((p) => _productCard(theme, p)),
                  _pager(theme, currentPage, totalPages),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pager(ThemeData theme, int currentPage, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              onPressed:
                  currentPage > 1 ? () => setState(() => _page--) : null,
              tooltip: _isArabic ? 'السابق' : 'Previous',
              icon: const Icon(LucideIcons.chevronLeft, size: 18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isArabic
                    ? 'صفحة $currentPage من $totalPages'
                    : 'Page $currentPage of $totalPages',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            IconButton.outlined(
              onPressed:
                  currentPage < totalPages ? () => setState(() => _page++) : null,
              tooltip: _isArabic ? 'التالي' : 'Next',
              icon: const Icon(LucideIcons.chevronRight, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(BuildContext context, ThemeData theme) {
    final dateLabel = _from == null && _to == null
        ? (_isArabic ? 'كل التواريخ' : 'All dates')
        : '${_from != null ? DateFormat('yyyy-MM-dd').format(_from!) : '...'}'
            ' - '
            '${_to != null ? DateFormat('yyyy-MM-dd').format(_to!) : '...'}';

    final hasFilters = _from != null ||
        _to != null ||
        _search != null ||
        _sortBy != 'revenue' ||
        _sortOrder != 'desc';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: _isArabic ? 'بحث عن منتج' : 'Search products',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _search != null
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _search = null;
                            _page = 1;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (value) {
                final trimmed = value.trim();
                setState(() {
                  _search = trimmed.isEmpty ? null : trimmed;
                  _page = 1;
                });
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _from != null && _to != null
                    ? DateTimeRange(start: _from!, end: _to!)
                    : null,
              );
              if (range != null) {
                setState(() {
                  _from = range.start;
                  _to = range.end;
                  _page = 1;
                });
              }
            },
            icon: const Icon(LucideIcons.calendar, size: 18),
            label: Text(dateLabel),
          ),
          SizedBox(
            width: 170,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _isArabic ? 'ترتيب حسب' : 'Sort by',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  isDense: true,
                  items: _sortOptions
                      .map(
                        (key) => DropdownMenuItem<String>(
                          value: key,
                          child: Text(_sortLabel(key)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _sortBy = value;
                      _page = 1;
                    });
                  },
                ),
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: _sortOrder == 'desc'
                ? (_isArabic ? 'تنازلي' : 'Descending')
                : (_isArabic ? 'تصاعدي' : 'Ascending'),
            onPressed: () => setState(() {
              _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
              _page = 1;
            }),
            icon: Icon(
              _sortOrder == 'desc'
                  ? LucideIcons.arrowDownWideNarrow
                  : LucideIcons.arrowUpWideNarrow,
              size: 18,
            ),
          ),
          if (hasFilters)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _from = null;
                  _to = null;
                  _search = null;
                  _sortBy = 'revenue';
                  _sortOrder = 'desc';
                  _page = 1;
                });
              },
              icon: const Icon(LucideIcons.x, size: 18),
              label: Text(_isArabic ? 'مسح الفلاتر' : 'Clear filters'),
            ),
        ],
      ),
    );
  }

  Widget _summary(ThemeData theme, Map<String, dynamic> totals) {
    final cards = <Widget>[
      _statCard(
        theme,
        label: _isArabic ? 'المنتجات' : 'Products',
        value: '${_int(totals['productCount'])}',
        color: AppColors.primary,
      ),
      _statCard(
        theme,
        label: _isArabic ? 'الوحدات المباعة' : 'Units sold',
        value: '${_int(totals['quantitySold'])}',
        color: AppColors.info,
      ),
      _statCard(
        theme,
        label: _isArabic ? 'الطلبات' : 'Orders',
        value: '${_int(totals['ordersCount'])}',
        color: AppColors.warning,
      ),
      _statCard(
        theme,
        label: _isArabic ? 'إجمالي الإيرادات' : 'Gross revenue',
        value: _money(totals['grossRevenue']),
        color: AppColors.success,
      ),
      _statCard(
        theme,
        label: _isArabic ? 'العمولة' : 'Commission',
        value: _money(totals['commission']),
        color: AppColors.error,
      ),
      _statCard(
        theme,
        label: _isArabic ? 'صافي الربح' : 'Net profit',
        value: _money(totals['netRevenue']),
        color: AppColors.success,
      ),
    ];

    return Wrap(spacing: 12, runSpacing: 12, children: cards);
  }

  Widget _statCard(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(ThemeData theme, dynamic product) {
    final name = _productName(product);
    final image = product['productImage']?.toString();
    final quantity = _int(product['quantitySold']);
    final orders = _int(product['ordersCount']);
    final gross = _money(product['grossRevenue']);
    final commission = _money(product['commission']);
    final net = _money(product['netRevenue']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image != null && image.isNotEmpty
                ? Image.network(
                    image,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imagePlaceholder(theme),
                  )
                : _imagePlaceholder(theme),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? '$quantity وحدة • $orders طلب'
                      : '$quantity sold • $orders orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _metric(
                      _isArabic ? 'إجمالي' : 'Gross',
                      gross,
                      theme.colorScheme.onSurface,
                    ),
                    _metric(
                      _isArabic ? 'عمولة' : 'Commission',
                      '-$commission',
                      AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isArabic ? 'صافي الربح' : 'Net profit',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                net,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      child: Icon(
        LucideIcons.package,
        size: 22,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  Future<void> _export(Map<String, dynamic> totals) async {
    final vendorId = widget.vendorId ?? ref.read(activeVendorProvider);
    if (vendorId == null) return;

    setState(() => _exporting = true);
    try {
      final repo = ref.read(vendorStatisticsRepositoryProvider);
      final products = <dynamic>[];
      var page = 1;
      var totalPages = 1;
      var exportTotals = totals;

      // Export the full filtered report, not just the visible page. Cap the
      // walk defensively so a bad response can never loop forever.
      do {
        final result = await repo.getVendorProductSales(
          vendorId,
          from: _from,
          to: _to,
          page: page,
          limit: 100,
          search: _search,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
        if (result is! Map) break;

        final batch = result['products'];
        if (batch is List) products.addAll(batch);
        if (result['totals'] is Map) {
          exportTotals = Map<String, dynamic>.from(result['totals'] as Map);
        }
        totalPages = (result['totalPages'] as num?)?.toInt() ?? 1;
        page++;
      } while (page <= totalPages && page <= 50);

      if (!mounted) return;
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? 'لا توجد بيانات للتصدير' : 'No data to export',
            ),
          ),
        );
        return;
      }

      final headers = [
        _isArabic ? 'المنتج' : 'Product',
        _isArabic ? 'الكمية المباعة' : 'Units sold',
        _isArabic ? 'الطلبات' : 'Orders',
        _isArabic ? 'إجمالي الإيرادات' : 'Gross revenue',
        _isArabic ? 'العمولة' : 'Commission',
        _isArabic ? 'صافي الربح' : 'Net profit',
      ];

      final rows = [
        for (final product in products)
          [
            _productName(product),
            '${_int(product['quantitySold'])}',
            '${_int(product['ordersCount'])}',
            _money(product['grossRevenue']),
            _money(product['commission']),
            _money(product['netRevenue']),
          ],
      ];

      await DataExportService.showExportOptions(
        context,
        title: _isArabic ? 'تقرير المبيعات والأرباح' : 'Sales & Profit Report',
        subtitle: _isArabic
            ? 'صافي الربح: ${_money(exportTotals['netRevenue'])}'
            : 'Net profit: ${_money(exportTotals['netRevenue'])}',
        headers: headers,
        rows: rows,
        filename: 'vendor_product_sales',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic ? 'تعذر تصدير التقرير' : 'Could not export the report',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
