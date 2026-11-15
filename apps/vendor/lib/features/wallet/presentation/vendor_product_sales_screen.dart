import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';
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
  static final _moneyFmt = NumberFormat('#,##0.00', 'en_US');
  static final _intFmt = NumberFormat('#,##0', 'en_US');

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

  Color _borderColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.borderDark
      : AppColors.borderLight;

  Color _positiveTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? AppColors.success
      : const Color(0xFF047857);

  Color _negativeTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? AppColors.error
      : const Color(0xFFB91C1C);

  Color _amberTextColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.primary
      : const Color(0xFF92400E);

  Color _infoTextColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.info
      : const Color(0xFF1D4ED8);

  Widget _scaledFigure(
    String text,
    TextStyle style, {
    AlignmentDirectional alignment = AlignmentDirectional.centerStart,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          text,
          maxLines: 1,
          style: style.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '0') ?? 0;
    return '${n < 0 ? '-' : ''}${_moneyFmt.format(n.abs())} EGP';
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final vendorId = widget.vendorId ?? ref.watch(activeVendorProvider);

    if (vendorId == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _isArabic ? 'المنتجات المباعة' : 'Products Sold',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _isArabic ? 'لم يتم اختيار متجر' : 'No vendor selected.',
              textAlign: TextAlign.center,
            ),
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
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${_isArabic ? 'المنتجات المباعة' : 'Products Sold'}'
          '${widget.vendorName != null ? ' - ${widget.vendorName}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isArabic
                        ? 'تعذر تحميل تقرير المبيعات'
                        : 'Could not load the sales report',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _negativeTextColor(theme),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ErrorUtils.translate(context, err),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(vendorProductSalesProvider(args)),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
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
                padding: EdgeInsets.all(isMobile ? 16 : 24),
              children: [
                _filters(context, theme),
                const SizedBox(height: 16),
                _summary(theme, totals),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isArabic ? 'المنتجات' : 'Products',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isArabic
                          ? '${_intFmt.format(_int(totals['productCount']))} منتج'
                          : '${_intFmt.format(_int(totals['productCount']))} products',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor(theme)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.packageSearch,
                          size: 46,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isArabic
                              ? 'لا توجد مبيعات في هذه الفترة'
                              : 'No sales in this period',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
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
      ),
    );
  }

  Widget _pager(ThemeData theme, int currentPage, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              onPressed: currentPage > 1 ? () => setState(() => _page--) : null,
              tooltip: _isArabic ? 'السابق' : 'Previous',
              icon: Icon(
                isRtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                size: 18,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isArabic
                    ? 'صفحة $currentPage من $totalPages'
                    : 'Page $currentPage of $totalPages',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton.outlined(
              onPressed: currentPage < totalPages
                  ? () => setState(() => _page++)
                  : null,
              tooltip: _isArabic ? 'التالي' : 'Next',
              icon: AppAdaptiveChevron(
                size: 18,
                color: currentPage < totalPages
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
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

    final hasFilters =
        _from != null ||
        _to != null ||
        _search != null ||
        _sortBy != 'revenue' ||
        _sortOrder != 'desc';

    final searchField = TextField(
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      onSubmitted: (value) {
        final trimmed = value.trim();
        setState(() {
          _search = trimmed.isEmpty ? null : trimmed;
          _page = 1;
        });
      },
    );

    final sortDropdown = InputDecorator(
      decoration: InputDecoration(
        labelText: _isArabic ? 'ترتيب حسب' : 'Sort by',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  child: Text(
                    _sortLabel(key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
    );

    final sortOrderButton = IconButton.outlined(
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
    );

    final dateButton = OutlinedButton.icon(
      onPressed: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: AppDialogStyles.adaptivePickerTheme,
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
      icon: const Icon(LucideIcons.calendar, size: 17),
      label: Directionality(
        textDirection: (_from != null || _to != null)
            ? TextDirection.ltr
            : Directionality.of(context),
        child: Text(dateLabel),
      ),
    );

    final clearButton = hasFilters
        ? TextButton.icon(
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
            icon: const Icon(LucideIcons.x, size: 17),
            label: Text(_isArabic ? 'مسح الفلاتر' : 'Clear filters'),
            style: TextButton.styleFrom(
              foregroundColor: _negativeTextColor(theme),
            ),
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(theme)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: sortDropdown),
                    const SizedBox(width: 8),
                    sortOrderButton,
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [dateButton, if (clearButton != null) clearButton],
                ),
              ],
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(width: 240, child: searchField),
              dateButton,
              SizedBox(width: 175, child: sortDropdown),
              sortOrderButton,
              if (clearButton != null) clearButton,
            ],
          );
        },
      ),
    );
  }

  Widget _summary(ThemeData theme, Map<String, dynamic> totals) {
    Widget card(
      IconData icon,
      String label,
      String value,
      Color accentColor,
      Color valueColor,
    ) {
      return Expanded(
        child: _statCard(
          theme,
          icon: icon,
          label: label,
          value: value,
          accentColor: accentColor,
          valueColor: valueColor,
        ),
      );
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                LucideIcons.package,
                _isArabic ? 'المنتجات' : 'Products',
                _intFmt.format(_int(totals['productCount'])),
                AppColors.primary,
                _amberTextColor(theme),
              ),
              const SizedBox(width: 12),
              card(
                LucideIcons.shoppingBag,
                _isArabic ? 'الوحدات المباعة' : 'Units sold',
                _intFmt.format(_int(totals['quantitySold'])),
                AppColors.info,
                _infoTextColor(theme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                LucideIcons.shoppingCart,
                _isArabic ? 'الطلبات' : 'Orders',
                _intFmt.format(_int(totals['ordersCount'])),
                AppColors.warning,
                _amberTextColor(theme),
              ),
              const SizedBox(width: 12),
              card(
                LucideIcons.dollarSign,
                _isArabic ? 'إجمالي الإيرادات' : 'Gross revenue',
                _money(totals['grossRevenue']),
                AppColors.success,
                _positiveTextColor(theme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(
                LucideIcons.percent,
                _isArabic ? 'العمولة' : 'Commission',
                _money(totals['commission']),
                AppColors.error,
                _negativeTextColor(theme),
              ),
              const SizedBox(width: 12),
              card(
                LucideIcons.trendingUp,
                _isArabic ? 'صافي الربح' : 'Net profit',
                _money(totals['netRevenue']),
                AppColors.success,
                _positiveTextColor(theme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(theme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: valueColor),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _scaledFigure(
              value,
              TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
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
    final commissionVal =
        double.tryParse(product['commission']?.toString() ?? '0') ?? 0;
    final commission = '${_moneyFmt.format(commissionVal.abs())} EGP';
    final net = _money(product['netRevenue']);
    final netVal =
        double.tryParse(product['netRevenue']?.toString() ?? '0') ?? 0;
    final borderColor = _borderColor(theme);

    Widget metricCol(
      String label,
      String value,
      Color valueColor, {
      double? maxWidth,
    }) {
      final figure = _scaledFigure(
        value,
        TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 3),
          if (maxWidth != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: figure,
            )
          else
            SizedBox(
              width: double.infinity,
              child: figure,
            ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isArabic
                          ? '${_intFmt.format(quantity)} وحدة • ${_intFmt.format(orders)} طلب'
                          : '${_intFmt.format(quantity)} sold • ${_intFmt.format(orders)} orders',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 20, color: borderColor),
          LayoutBuilder(
            builder: (context, constraints) {
              final grossLabel = _isArabic ? 'الإجمالي' : 'Gross';
              final commissionLabel = _isArabic ? 'العمولة' : 'Commission';
              final netLabel = _isArabic ? 'صافي الربح' : 'Net profit';
              final netColor = netVal < 0
                  ? _negativeTextColor(theme)
                  : _positiveTextColor(theme);

              if (constraints.maxWidth < 260) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    metricCol(
                      grossLabel,
                      gross,
                      theme.colorScheme.onSurface,
                      maxWidth: constraints.maxWidth,
                    ),
                    metricCol(
                      commissionLabel,
                      '-$commission',
                      _negativeTextColor(theme),
                      maxWidth: constraints.maxWidth,
                    ),
                    metricCol(
                      netLabel,
                      net,
                      netColor,
                      maxWidth: constraints.maxWidth,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: metricCol(
                      grossLabel,
                      gross,
                      theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: metricCol(
                      commissionLabel,
                      '-$commission',
                      _negativeTextColor(theme),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: metricCol(netLabel, net, netColor),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      child: Icon(
        LucideIcons.package,
        size: 22,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
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
