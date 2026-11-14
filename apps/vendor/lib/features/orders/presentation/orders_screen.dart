import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:data/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../chat/presentation/pages/admin_chat_screen.dart';
import '../presentation/orders_provider.dart';
import 'widgets/assign_driver_sheet.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final String? initialOrderId;

  const OrdersScreen({super.key, this.initialOrderId});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _userRole = '';
  bool _canManageDrivers = false;
  bool _canManageVendors = false;
  bool _canManageOrders = false;
  final Map<String, bool> _expandedOrders = {};
  Map<String, dynamic>? _pinnedOrder;
  bool _pinnedLoading = false;

  /// Server-side status filter (null = all). Text / payment / date filters
  /// below are client-side over the loaded orders.
  String? _statusFilter;
  String? _paymentFilter;
  String _query = '';
  int? _dateDays;
  DateTimeRange? _customRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).fetchOrders();
    });
    final targetId = widget.initialOrderId;
    if (targetId != null && targetId.isNotEmpty) {
      _expandedOrders[targetId] = true;
      _fetchPinnedOrder(targetId);
    }
    _loadUserRole();
    _checkPermissions();
    // Real-time updates (order.new / order.status / order.cancelled),
    // foreground FCM fallback and app-resume refreshes are handled by the
    // global listener at the app root so they work from any tab.
  }

  Future<void> _checkPermissions() async {
    final repo = ref.read(sharedAuthRepositoryProvider);
    final role = await repo.getUserRole();
    final permissions = await repo.getUserPermissions();
    if (mounted) {
      setState(() {
        _userRole = role ?? '';
        _canManageDrivers = role == 'SUPER_ADMIN' || role == 'DRIVER_MANAGER' || permissions.contains('MANAGE_DRIVERS');
        _canManageVendors = role == 'SUPER_ADMIN' || role == 'ADMIN' || permissions.contains('MANAGE_VENDORS');
        _canManageOrders = role == 'SUPER_ADMIN' || role == 'ADMIN' || permissions.contains('MANAGE_ORDERS');
      });
    }
  }

  Future<void> _loadUserRole() async {
    const storage = FlutterSecureStorage();
    final role = await storage.read(key: 'user_role');
    if (mounted) {
      setState(() {
        _userRole = role ?? '';
      });
    }
  }

  void _loadOrders() {
    ref.read(ordersProvider.notifier).fetchOrders();
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day, 23, 59),
      initialDateRange: _customRange,
    );
    if (picked != null && mounted) {
      // Custom range replaces the preset window and vice versa.
      setState(() {
        _customRange = picked;
        _dateDays = null;
      });
    }
  }

  String _customRangeLabel(bool isArabic) {
    if (_customRange == null) return isArabic ? 'مخصص' : 'Custom';
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
    return '${fmt(_customRange!.start)} – ${fmt(_customRange!.end)}';
  }

  Widget _buildDateChip(BuildContext context, int? days, String label) {
    final selected = _dateDays == days && _customRange == null;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _dateDays = days;
        _customRange = null;
      }),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: selected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
      ),
    );
  }

  /// Fetches a single order opened from a notification deep link so it is
  /// visible (expanded) even when it is not on the currently loaded page.
  Future<void> _fetchPinnedOrder(String orderId) async {
    setState(() => _pinnedLoading = true);
    try {
      final result = await ref
          .read(adminOrdersRepositoryProvider)
          .getOrderById(orderId);
      Map<String, dynamic>? order;
      if (result is Map) {
        final map = Map<String, dynamic>.from(result);
        final inner = map['data'];
        order = inner is Map ? Map<String, dynamic>.from(inner) : map;
      }
      if (mounted && order != null && order.isNotEmpty) {
        setState(() {
          _pinnedOrder = order;
          _expandedOrders[orderId] = true;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _pinnedLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const _filterStatuses = [
    'PENDING',
    'ACCEPTED',
    'PREPARING',
    'READY_FOR_PICKUP',
    'LOOKING_FOR_DRIVER',
    'DRIVER_ASSIGNED',
    'PENDING_PAYMENT',
    'PICKED_UP',
    'DELIVERED',
    'CANCELLED',
  ];

  String _statusFilterLabel(String status, bool isArabic) {
    switch (status) {
      case 'PENDING':
        return isArabic ? 'جديد' : 'New';
      case 'ACCEPTED':
        return isArabic ? 'مقبول' : 'Accepted';
      case 'PREPARING':
        return isArabic ? 'قيد التحضير' : 'Preparing';
      case 'READY_FOR_PICKUP':
        return isArabic ? 'جاهز للاستلام' : 'Ready for Pickup';
      case 'LOOKING_FOR_DRIVER':
        return isArabic ? 'جاري البحث عن سائق' : 'Looking for Driver';
      case 'DRIVER_ASSIGNED':
        return isArabic ? 'تم تعيين السائق' : 'Driver Assigned';
      case 'PENDING_PAYMENT':
        return isArabic ? 'في انتظار الدفع' : 'Pending Payment';
      case 'PICKED_UP':
        return isArabic ? 'تم الاستلام' : 'Picked Up';
      case 'IN_TRANSIT':
      case 'ARRIVING':
        return isArabic ? 'في الطريق' : 'On the Way';
      case 'DELIVERED':
        return isArabic ? 'تم التوصيل' : 'Delivered';
      case 'CANCELLED':
        return isArabic ? 'ملغي' : 'Cancelled';
      default:
        return status;
    }
  }

  void _onStatusFilterChanged(String? value) {
    setState(() => _statusFilter = value);
    ref.read(ordersProvider.notifier).fetchOrders(
      params: value == null ? const {} : {'status': value},
    );
  }

  /// Client-side text + payment + date filtering over loaded orders.
  List<dynamic> _applyLocalFilters(List<dynamic> orders) {
    final q = _query.trim().toLowerCase();
    final now = DateTime.now();
    return orders.where((o) {
      if (o is! Map) return false;
      final order = Map<String, dynamic>.from(o);
      if (_paymentFilter != null &&
          (order['paymentMethod']?.toString() ?? '') != _paymentFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final customer = order['customer'];
        final customerUser = customer is Map ? customer['user'] : null;
        final vendor = order['vendor'];
        final driver = order['driver'];
        final driverUser = driver is Map ? driver['user'] : null;
        final haystackList = <dynamic>[
          order['orderNumber'],
          order['id'],
          order['status'],
          order['paymentMethod'],
          order['total'],
          order['grandTotal'],
          order['deliveryAddress'],
          customer is Map ? customer['name'] : null,
          customer is Map ? customer['phone'] : null,
          customerUser is Map ? customerUser['name'] : null,
          customerUser is Map ? customerUser['phone'] : null,
          vendor is Map ? vendor['storeName'] : null,
          vendor is Map ? vendor['storeNameAr'] : null,
          vendor is Map ? vendor['name'] : null,
          driver is Map ? driver['name'] : null,
          driverUser is Map ? driverUser['phone'] : null,
        ];
        final fulfillments = (order['vendorFulfillments'] as List?) ?? [];
        for (final f in fulfillments) {
          if (f is Map && f['vendor'] is Map) {
            final fv = f['vendor'] as Map;
            haystackList.add(fv['storeName']);
            haystackList.add(fv['storeNameAr']);
            haystackList.add(fv['name']);
            haystackList.add(fv['phone']);
          }
          if (f is Map && f['vendorBranch'] is Map) {
            final fb = f['vendorBranch'] as Map;
            haystackList.add(fb['name']);
            haystackList.add(fb['nameAr']);
            haystackList.add(fb['address']);
            haystackList.add(fb['phone']);
          }
          if (f is Map && f['items'] is List) {
            for (final it in (f['items'] as List)) {
              if (it is Map) {
                haystackList.add(it['productName']);
                haystackList.add(it['variantName']);
              }
            }
          }
        }
        final haystack = haystackList
            .where((e) => e != null)
            .map((e) => e.toString().toLowerCase())
            .join(' ');
        if (!haystack.contains(q)) return false;
      }
      if (_customRange != null || _dateDays != null) {
        try {
          final raw = order['createdAt']?.toString() ?? '';
          if (raw.isEmpty) return false;
          final d = DateTime.parse(raw).toLocal();
          if (_customRange != null) {
            final dayStart =
                DateTime(d.year, d.month, d.day);
            final rangeStart = DateTime(
              _customRange!.start.year,
              _customRange!.start.month,
              _customRange!.start.day,
            );
            final rangeEnd = DateTime(
              _customRange!.end.year,
              _customRange!.end.month,
              _customRange!.end.day,
            );
            if (dayStart.isBefore(rangeStart) ||
                dayStart.isAfter(rangeEnd)) {
              return false;
            }
          } else if (now.difference(d).inDays > _dateDays!) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }
      return true;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(ordersRefreshErrorProvider, (previous, next) {
      if (next != null && next != previous && mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic
                ? 'تعذر تحديث الطلبات. يتم عرض آخر بيانات محملة.'
                : 'Could not refresh orders. Showing latest loaded data.'),
            action: SnackBarAction(
              label: isArabic ? 'إعادة المحاولة' : 'Retry',
              onPressed: () =>
                  ref.read(ordersProvider.notifier).fetchOrders(),
            ),
          ),
        );
      }
    });

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Title with Live Pulsing Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'إدارة الطلبات' : 'Order Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic
                        ? 'إدارة ومتابعة تحديثات وتجهيز الطلبات'
                        : 'Monitor and manage live order logistics',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildLiveBadge(isArabic),
          ],
        ),
        const SizedBox(height: 24),

        // Stat Cards header
        Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(ordersProvider);
            int newOrders = 0;
            int preparing = 0;
            int ready = 0;
            int cancelled = 0;

            if (state.hasValue) {
              for (var order in state.value!.orders) {
                final status = order['status']?.toString();
                if (status == 'PENDING') newOrders++;
                if (status == 'ACCEPTED' || status == 'PREPARING') preparing++;
                if (status == 'READY_FOR_PICKUP') ready++;
                if (status == 'CANCELLED') cancelled++;
              }
            }

            return GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width < 600
                  ? 2
                  : (MediaQuery.of(context).size.width < 1100 ? 2 : 4),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width < 600
                  ? 2.0
                  : 2.4,
              children: [
                _buildScenicStatCard(
                  title: isArabic ? 'جديد' : 'New Orders',
                  value: newOrders.toString(),
                  icon: LucideIcons.bell,
                  color: AppColors.warning,
                  gradientColors: [
                    const Color(0xFFF59E0B),
                    const Color(0xFFD97706),
                  ],
                ),
                _buildScenicStatCard(
                  title: isArabic ? 'جاري التحضير' : 'Preparing',
                  value: preparing.toString(),
                  icon: LucideIcons.chefHat,
                  color: AppColors.primary,
                  gradientColors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                _buildScenicStatCard(
                  title: isArabic ? 'جاهز للتوصيل' : 'Ready to Ship',
                  value: ready.toString(),
                  icon: LucideIcons.package,
                  color: AppColors.success,
                  gradientColors: [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
                ),
                _buildScenicStatCard(
                  title: isArabic ? 'الملغية' : 'Cancelled',
                  value: cancelled.toString(),
                  icon: LucideIcons.xCircle,
                  color: AppColors.error,
                  gradientColors: [
                    const Color(0xFFEF4444),
                    const Color(0xFFDC2626),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Filters: status is server-side, text / payment / date are
        // client-side over the loaded orders.
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'بحث برقم الطلب أو الاسم...'
                        : 'Search order no. or name...',
                    prefixIcon:
                        const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _statusFilter,
                        decoration: InputDecoration(
                          labelText:
                              isArabic ? 'الحالة' : 'Status',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                                AppLocalizations.of(context)!.filterAll),
                          ),
                          ..._filterStatuses.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s,
                              child: Text(
                                _statusFilterLabel(s, isArabic),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: _onStatusFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _paymentFilter,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الدفع' : 'Payment',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                                AppLocalizations.of(context)!.filterAll),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'CASH_ON_DELIVERY',
                            child: Text(isArabic ? 'كاش' : 'Cash',
                                overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'MOBILE_WALLET',
                            child: Text(
                                isArabic ? 'محفظة' : 'Wallet',
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _paymentFilter = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                          children: [
                            _buildDateChip(context, null,
                                isArabic ? 'الكل' : 'All'),
                            const SizedBox(width: 8),
                            _buildDateChip(context, 0,
                                isArabic ? 'اليوم' : 'Today'),
                            const SizedBox(width: 8),
                            _buildDateChip(context, 7,
                                isArabic ? '٧ أيام' : '7 days'),
                            const SizedBox(width: 8),
                            _buildDateChip(context, 30,
                                isArabic ? '٣٠ يوم' : '30 days'),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.calendarDays,
                                      size: 14),
                                  const SizedBox(width: 4),
                                  Text(_customRangeLabel(isArabic)),
                                  if (_customRange != null) ...[
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => setState(() =>
                                          _customRange = null),
                                      child: const Icon(
                                          LucideIcons.x,
                                          size: 14),
                                    ),
                                  ],
                                ],
                              ),
                              selected: _customRange != null,
                              onSelected: (_) =>
                                  _pickCustomRange(context),
                              selectedColor: AppColors.primary
                                  .withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _customRange != null
                                    ? AppColors.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(20)),
                              side: BorderSide(
                                color: _customRange != null
                                    ? AppColors.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.15),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Orders List View
        Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(ordersProvider);
            if (state.isLoading && !state.hasValue) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (state.hasError && !state.hasValue) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ErrorUtils.translate(context, state.error),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadOrders,
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.hasValue) {
              final allOrders = state.value!.orders;
              final orders = _applyLocalFilters(allOrders);

              if (orders.isEmpty) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.packageSearch,
                          size: 56,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.noOrdersFound,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'لا توجد أي طلبات في النظام حالياً.'
                            : 'There are no orders in the system at the moment.',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final pinned = _pinnedOrder;
              final showPinned = pinned != null &&
                  !allOrders.any(
                    (o) => o is Map && o['id']?.toString() == pinned['id']?.toString(),
                  );
              return Column(
                children: [
                  if (_pinnedLoading && !showPinned) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                  ],
                  if (showPinned) ...[
                    _buildSleekOrderCard(context, pinned, isArabic),
                    const SizedBox(height: 4),
                  ],
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildSleekOrderCard(context, order, isArabic);
                    },
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildLiveBadge(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LivePulseDot(),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'مباشر' : 'LIVE',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenicStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background soft glowing circle
          PositionedDirectional(
            end: -20,
            bottom: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleekOrderCard(
    BuildContext context,
    dynamic order,
    bool isArabic,
  ) {
    final orderId = order['id']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'PENDING';
    final driver = order['driver'] ?? {};
    final driverName = driver['name']?.toString() ?? '';
    final driverPhone = driver['user']?['phone']?.toString() ?? '';
    final Map? branch = order['vendorBranch'] is Map ? (order['vendorBranch'] as Map) : null;
    final String? branchName = branch == null
        ? null
        : (isArabic
            ? (branch['nameAr']?.toString() ?? branch['name']?.toString())
            : (branch['name']?.toString() ?? branch['nameAr']?.toString()));

    final fulfillments = (order['vendorFulfillments'] as List<dynamic>?) ?? [];
    final bool isMultiVendor = order['isMultiVendor'] == true ||
        fulfillments.length > 1 ||
        (order['vendor'] == null && fulfillments.isNotEmpty) ||
        (order['deliveryGroups'] is List && (order['deliveryGroups'] as List).length > 1) ||
        order['myFulfillmentStatus'] != null;
    String? multiVendorStoresText;
    if (isMultiVendor) {
      final names = <String>[];
      for (final f in fulfillments) {
        if (f is Map) {
          final v = f['vendor'] as Map<String, dynamic>?;
          if (v != null) {
            final sName = isArabic
                ? (v['storeNameAr'] ?? v['storeName'])
                : (v['storeName'] ?? v['storeNameAr']);
            if (sName != null && sName.toString().trim().isNotEmpty && !names.contains(sName.toString().trim())) {
              names.add(sName.toString().trim());
            }
          }
        }
      }
      multiVendorStoresText = names.isNotEmpty ? names.join(' + ') : null;
    }
    final isCancelled = status.contains('CANCEL') || status.contains('REJECT');
    final areFeesFinalized = !isCancelled;
    final orderNumber = order['orderNumber']?.toString() ?? 'N/A';
    
    final grandTotal = double.tryParse(
      order['grandTotal']?.toString() ?? 
      order['totalFee']?.toString() ?? 
      order['total']?.toString() ?? '0'
    );
    final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
    final total = areFeesFinalized ? (grandTotal ?? subtotal) : subtotal;

    // Formatting date
    String dateStr = '';
    try {
      final createdAt =
          DateTime.tryParse(order['createdAt']?.toString() ?? '')?.toLocal();
      if (createdAt != null) {
        dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(createdAt);
      }
    } catch (_) {}

    final customer = order['customer'] ?? {};
    final customerUser = customer['user'] ?? {};
    final customerName =
        customerUser['name']?.toString() ??
        (isArabic ? 'عميل غير معروف' : 'Unknown Customer');
    final customerPhone = customerUser['phone']?.toString() ?? '';
    final address = order['deliveryAddress']?.toString() ?? '';
    final paymentMethod = order['paymentMethod']?.toString() ?? '';

    // driver and driverName extracted above
    final vehicleType = driver['vehicleType']?.toString() ?? '';
    final vehiclePlate = driver['vehiclePlate']?.toString() ?? '';

    final items = (order['items'] as List<dynamic>?) ?? [];
    final isExpanded = _expandedOrders[orderId] ?? false;

    // Set colorful status highlight
    Color statusColor;
    switch (status) {
      case 'PENDING':
        statusColor = AppColors.warning;
        break;
      case 'ACCEPTED':
        statusColor = AppColors.primary;
        break;
      case 'PREPARING':
        statusColor = Colors.blue;
        break;
      case 'READY_FOR_PICKUP':
        statusColor = AppColors.success;
        break;
      case 'DELIVERED':
      case 'PICKED_UP':
        statusColor = Colors.green;
        break;
      case 'CANCELLED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.grey;
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? statusColor.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: isExpanded ? 0.06 : 0.02),
            blurRadius: isExpanded ? 16 : 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Dynamic RTL/LTR status bar (Positioned to fit full card height perfectly)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 6, color: statusColor),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Column(
              children: [
                // Collapsed / Header section
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedOrders[orderId] = !isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Order Number & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onLongPress: () {
                                      Clipboard.setData(ClipboardData(text: orderNumber));
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isArabic ? 'تم نسخ رقم الطلب' : 'Order number copied')));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#$orderNumber',
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: _buildStatusChip(
                                      context,
                                      status,
                                      isArabic,
                                    ),
                                  ),
                                  if (isMultiVendor && multiVendorStoresText != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.store, size: 11, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              multiVendorStoresText,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (branchName != null && branchName.toString().isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.mapPin, size: 11, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              branchName.toString(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Collapsed Item specifications (Multi-Vendor stops or single store items)
                        if (isMultiVendor && fulfillments.length > 1) ...[
                          _buildCollapsedMultiVendorRow(context, fulfillments, items, isArabic),
                          const SizedBox(height: 12),
                        ] else if (items.isNotEmpty) ...[
                          _buildCollapsedItemRow(context, items, isArabic),
                          const SizedBox(height: 12),
                        ],

                        // Bottom row: Customer info & Valuation Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${total.toStringAsFixed(2)} EGP',
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
                  ),
                ),

                // Expanded Details section
                if (isExpanded) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Step Progress Timeline (Customer App parity!)
                        _buildStatusTimeline(status, isArabic),
                        const SizedBox(height: 16),

                        // Info rows (Delivery details, payment method, etc.)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPremiumDetailRow(
                                    icon: LucideIcons.hash,
                                    title: isArabic ? 'معرف الطلب' : 'Order ID',
                                    value: orderId,
                                    iconColor: statusColor,
                                    trailing: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: orderId));
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isArabic ? 'تم نسخ معرف الطلب' : 'Order ID copied')));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(LucideIcons.copy, color: AppColors.primary, size: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPremiumDetailRow(
                                    icon: LucideIcons.mapPin,
                                    title: isArabic
                                        ? 'عنوان التوصيل'
                                        : 'Delivery Address',
                                    value: address,
                                    iconColor: statusColor,
                                  ),
                                  if (customerPhone.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildPremiumDetailRow(
                                      icon: LucideIcons.phone,
                                      title: isArabic
                                          ? 'رقم الهاتف'
                                          : 'Phone Number',
                                      value: customerPhone,
                                      iconColor: statusColor,
                                      trailing: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          onTap: () =>
                                              _callCustomer(context, customerPhone, isArabic),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              LucideIcons.phoneCall,
                                              color: AppColors.primary,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildPremiumDetailRow(
                                    icon:
                                        (paymentMethod == 'CASH_ON_DELIVERY' ||
                                            paymentMethod == 'CASH')
                                        ? LucideIcons.banknote
                                        : (paymentMethod ==
                                                  'MOBILE_WALLET_VODAFONE' ||
                                              paymentMethod == 'VODAFONE' ||
                                              paymentMethod == 'MOBILE_WALLET')
                                        ? LucideIcons.wallet
                                        : (paymentMethod ==
                                                  'MOBILE_WALLET_INSTAPAY' ||
                                              paymentMethod == 'INSTAPAY')
                                        ? LucideIcons.landmark
                                        : LucideIcons.helpCircle,
                                    title: isArabic
                                        ? 'طريقة الدفع'
                                        : 'Payment Method',
                                    value:
                                        (paymentMethod == 'CASH_ON_DELIVERY' ||
                                            paymentMethod == 'CASH')
                                        ? (isArabic
                                              ? 'نقدي عند الاستلام'
                                              : 'Cash on Delivery')
                                        : (paymentMethod == 'MOBILE_WALLET')
                                        ? (isArabic
                                              ? 'محفظة إلكترونية'
                                              : 'Mobile Wallet')
                                        : (paymentMethod ==
                                                  'MOBILE_WALLET_VODAFONE' ||
                                              paymentMethod == 'VODAFONE')
                                        ? (isArabic
                                              ? 'فودافون كاش'
                                              : 'Mobile Wallet')
                                        : (paymentMethod ==
                                                  'MOBILE_WALLET_INSTAPAY' ||
                                              paymentMethod == 'INSTAPAY')
                                        ? (isArabic ? 'إنستاباي' : 'InstaPay')
                                        : (isArabic
                                              ? 'غير محدد'
                                              : 'Not Specified'),
                                    iconColor: statusColor,
                                  ),
                                  if (driverName.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildPremiumDetailRow(
                                      icon: LucideIcons.truck,
                                      title: isArabic
                                          ? 'السائق المسؤول'
                                          : 'Assigned Driver',
                                      value: [
                                        driverName,
                                        if (vehicleType.isNotEmpty ||
                                            vehiclePlate.isNotEmpty)
                                          '(${vehicleType.toUpperCase()}${vehiclePlate.isNotEmpty ? ' - $vehiclePlate' : ''})',
                                        if (driverPhone.isNotEmpty) driverPhone,
                                      ].join(' '),
                                      iconColor: statusColor,
                                      trailing: _canManageDrivers &&
                                              driver['id'] != null &&
                                              driver['id'].toString().isNotEmpty
                                          ? Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                onTap: () => _locateDriverFromOrder(
                                                  context,
                                                  order,
                                                  isArabic,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    LucideIcons.navigation,
                                                    color: AppColors.primary,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                  if (order['paymentReceiptUrl'] != null &&
                                      order['paymentReceiptUrl']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildProofPhotoRow(
                                      context,
                                      order,
                                      isArabic,
                                      field: 'paymentReceiptUrl',
                                      title: 'Payment receipt',
                                      titleAr: 'إيصال التحويل (العميل)',
                                    ),
                                  ],
                                  if (_resolveOrderProofUrl(order, 'pickupImageUrl').isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildProofPhotoRow(
                                      context,
                                      order,
                                      isArabic,
                                      field: 'pickupImageUrl',
                                      title: 'Pickup photo',
                                      titleAr: 'صورة الاستلام',
                                    ),
                                  ],
                                  if (_resolveOrderProofUrl(order, 'deliveryImageUrl').isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildProofPhotoRow(
                                      context,
                                      order,
                                      isArabic,
                                      field: 'deliveryImageUrl',
                                      title: 'Delivery photo',
                                      titleAr: 'صورة التوصيل',
                                    ),
                                  ],
                                  if (_canManageDrivers && ['ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'LOOKING_FOR_DRIVER'].contains(order['status'])) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (ctx) => AssignDriverSheet(
                                              orderId: order['id'],
                                              orderCode: order['orderCode'] ?? order['id'].substring(0, 8),
                                            ),
                                          );
                                        },
                                        icon: const Icon(LucideIcons.userPlus, size: 16),
                                        label: Text(isArabic ? 'تعيين سائق يدوياً' : 'Assign Driver Manually'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openOrderChat(context, order, isArabic),
                                      icon: const Icon(LucideIcons.messageSquare, size: 16, color: AppColors.primary),
                                      label: Text(
                                        isArabic ? 'محادثة الطلب (العميل والسائق)' : 'Order Chat (Customer & Driver)',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Order items / Multi-vendor stops section
                        if ((isMultiVendor && fulfillments.isNotEmpty) ||
                            fulfillments.length > 1)
                          _buildMultiVendorFulfillments(
                            context,
                            order,
                            fulfillments,
                            items,
                            isArabic,
                            statusColor,
                          )
                        else
                          _buildSingleVendorItems(
                            context,
                            order,
                            items,
                            statusColor,
                            isArabic,
                          ),
                        const SizedBox(height: 16),

                        // Pricing breakdown
                        _buildPricingBreakdown(order, isArabic),

                        // Delivery Success Banner
                        if (status == 'DELIVERED' && driverName.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.checkCircle,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isArabic
                                        ? 'تم التوصيل بنجاح بواسطة السائق: $driverName'
                                        : 'Successfully delivered by driver: $driverName',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Action buttons
                        _buildActionButtons(context, order, status, isArabic),
                      ],
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

  Widget _buildCollapsedMultiVendorRow(
    BuildContext context,
    List<dynamic> fulfillments,
    List<dynamic> allItems,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (var i = 0; i < fulfillments.length; i++) ...[
          () {
            final f = fulfillments[i] is Map ? fulfillments[i] as Map : {};
            final fId = f['id']?.toString() ?? '';
            final fVendor = f['vendor'] is Map ? f['vendor'] as Map : {};
            final fBranch = f['vendorBranch'] is Map ? f['vendorBranch'] as Map : {};
            final sName = isArabic
                ? (fVendor['storeNameAr'] ?? fVendor['storeName'] ?? fVendor['name'] ?? 'متجر')
                : (fVendor['storeName'] ?? fVendor['storeNameAr'] ?? fVendor['name'] ?? 'Store');
            final bName = isArabic ? (fBranch['nameAr'] ?? fBranch['name'] ?? '') : (fBranch['name'] ?? fBranch['nameAr'] ?? '');
            final rawFItems = f['items'];
            final portionItems = (rawFItems is List && rawFItems.isNotEmpty)
                ? rawFItems
                : allItems.where((it) => it is Map && it['fulfillmentId'] == fId).toList();
            final itemsCount = portionItems.isNotEmpty ? portionItems.length : 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    bName.toString().isNotEmpty ? '$sName (${bName.toString()})' : sName.toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$itemsCount ${isArabic ? "أصناف" : "items"}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildCollapsedItemRow(
    BuildContext context,
    List<dynamic> items,
    bool isArabic,
  ) {
    final firstItem = items.first;
    final product = firstItem['product'] ?? {};
    final productImgUrl = product['imageUrl']?.toString() ?? firstItem['imageUrl']?.toString() ?? '';
    final productName = firstItem['productName']?.toString() ??
        (isArabic
            ? (product['nameAr'] ?? product['name'] ?? '')
            : (product['name'] ?? ''));
    final quantity = firstItem['quantity'] ?? 1;

    final additionalItemsCount = items.length - 1;

    return Row(
      children: [
        // Rounded Product Image with border
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: productImgUrl.isEmpty
              ? Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.03),
                  child: Icon(
                    LucideIcons.package,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: ImageUtils.formatImageUrl(productImgUrl),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.03),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.03),
                    child: Icon(
                      LucideIcons.package,
                      size: 20,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        // Item Name & Additional Items Count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${quantity}x $productName',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (additionalItemsCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  isArabic
                      ? '+ $additionalItemsCount صنف آخر'
                      : '+ $additionalItemsCount more item${additionalItemsCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 2),
                Text(
                  isArabic ? 'طلب صنف واحد' : 'Single item order',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(String status, bool isArabic) {
    if (status == 'CANCELLED') return const SizedBox.shrink();

    int currentStep = 0;
    if (status == 'PREPARING' || status == 'COOKING' || status == 'ACCEPTED' || status == 'LOOKING_FOR_DRIVER' || status == 'DRIVER_ASSIGNED' || status == 'PENDING_PAYMENT') {
      currentStep = 1;
    } else if (status == 'READY_FOR_PICKUP' || status == 'PICKED_UP' || status == 'PARTIALLY_PICKED_UP') {
      currentStep = 2;
    } else if (status == 'DELIVERED') {
      currentStep = 3;
    }

    final steps = isArabic
        ? ['تم الطلب', 'التحضير', 'في الطريق', 'تم التوصيل']
        : ['Placed', 'Preparing', 'On Way', 'Delivered'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isActive = index <= currentStep;
          final isCompleted = index < currentStep;
          final label = steps[index];

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : (isActive
                                  ? AppColors.primary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.08)),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.primary
                            : (isActive
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.surface),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          : Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? AppColors.primary
                                      : Theme.of(context).colorScheme.onSurface
                                            .withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 3
                            ? Colors.transparent
                            : (index < currentStep
                                  ? AppColors.primary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.08)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSingleVendorItems(
    BuildContext context,
    dynamic order,
    List<dynamic> items,
    Color statusColor,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    final vendor = order['vendor'] is Map ? (order['vendor'] as Map) : null;
    final branch = order['vendorBranch'] is Map ? (order['vendorBranch'] as Map) : null;

    final storeName = isArabic
        ? (vendor?['storeNameAr'] ?? vendor?['storeName'] ?? vendor?['name'] ?? '')
        : (vendor?['storeName'] ?? vendor?['storeNameAr'] ?? vendor?['name'] ?? '');

    final branchName = isArabic
        ? (branch?['nameAr'] ?? branch?['name'] ?? '')
        : (branch?['name'] ?? branch?['nameAr'] ?? '');

    final branchAddress = branch?['address']?.toString() ?? '';
    final branchPhone = branch?['phone']?.toString() ?? vendor?['phone']?.toString() ?? '';
    final isContracted = branch?['isContracted'] ?? vendor?['isContracted'] ?? false;
    final storeLogo = vendor?['logo']?.toString() ?? '';

    final specialRequest = order['specialRequest']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store & Branch Header (if available)
          if (storeName.toString().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: storeLogo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ImageUtils.formatImageUrl(storeLogo),
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Icon(LucideIcons.store, size: 20, color: AppColors.primary),
                        )
                      : const Icon(LucideIcons.store, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              storeName.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isContracted
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isContracted
                                  ? (isArabic ? 'شريك معتمد' : 'Contracted')
                                  : (isArabic ? 'دفع بالاستلام' : 'Cash at pickup'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isContracted ? AppColors.primary : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (branchName.toString().isNotEmpty || branchAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                branchName.toString().isNotEmpty && branchAddress.isNotEmpty
                                    ? '$branchName - $branchAddress'
                                    : (branchName.toString().isNotEmpty ? branchName.toString() : branchAddress),
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (branchPhone.isNotEmpty) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _callCustomer(context, branchPhone, isArabic),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.phoneCall, color: AppColors.primary, size: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
          ],

          Row(
            children: [
              Icon(LucideIcons.shoppingBag, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'تفاصيل الأصناف' : 'Items Specification',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${items.length} ${isArabic ? "أصناف" : "items"}',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final productName = item['productName']?.toString() ?? item['name']?.toString() ?? '';
              final variantName = item['variantName']?.toString();
              final selectedUnit = item['selectedUnit']?.toString();
              final quantity = item['quantity'] ?? 1;
              final price = double.tryParse(item['unitPrice']?.toString() ?? item['price']?.toString() ?? '0') ?? 0.0;
              final product = item['product'] is Map ? item['product'] as Map : null;
              final imgUrl = product?['imageUrl']?.toString() ?? item['imageUrl']?.toString() ?? '';
              final itemNotes = item['specialRequest']?.toString();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imgUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ImageUtils.formatImageUrl(imgUrl),
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const Icon(LucideIcons.package, size: 18, color: Colors.grey),
                            )
                          : const Icon(LucideIcons.package, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${quantity}x',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if ((variantName != null && variantName.isNotEmpty) || (selectedUnit != null && selectedUnit.isNotEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                [if (variantName != null && variantName.isNotEmpty) variantName, if (selectedUnit != null && selectedUnit.isNotEmpty) selectedUnit].join(' • '),
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ),
                          if (itemNotes != null && itemNotes.trim().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.messageSquare, size: 10, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      itemNotes,
                                      style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          for (final opt in ((item['selectedOptions'] as List?) ?? []))
                            if (opt is Map && (opt['optionName']?.toString().isNotEmpty ?? false))
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '+ ${opt['optionName']}${(double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0) > 0 ? ' (+${opt['priceAdded']} EGP)' : ''}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ),
                        ],
                      ),
                    ),
                    Text(
                      '${(price * quantity).toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),

          if (specialRequest != null && specialRequest.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.messageSquare, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${isArabic ? "ملاحظات العميل: " : "Customer Notes: "}$specialRequest',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortionStatusBadge(String status, bool isArabic) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'PENDING':
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        label = isArabic ? 'بانتظار القرار' : 'Pending Decision';
        break;
      case 'ACCEPTED':
        bg = AppColors.info.withValues(alpha: 0.12);
        fg = AppColors.info;
        label = isArabic ? 'تم القبول' : 'Accepted';
        break;
      case 'PREPARING':
        bg = Colors.purple.withValues(alpha: 0.12);
        fg = Colors.purple;
        label = isArabic ? 'قيد التحضير' : 'Preparing';
        break;
      case 'READY_FOR_PICKUP':
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = isArabic ? 'جاهز للاستلام' : 'Ready for Pickup';
        break;
      case 'PICKED_UP':
        bg = Colors.teal.withValues(alpha: 0.12);
        fg = Colors.teal;
        label = isArabic ? 'تم الاستلام' : 'Picked Up';
        break;
      case 'DELIVERED':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        label = isArabic ? 'تم التوصيل' : 'Delivered';
        break;
      case 'REJECTED':
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        label = isArabic ? 'مرفوض' : 'Rejected';
        break;
      case 'CANCELLED':
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey;
        label = isArabic ? 'ملغي' : 'Cancelled';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildMultiVendorFulfillments(
    BuildContext context,
    dynamic order,
    List<dynamic> fulfillments,
    List<dynamic> allItems,
    bool isArabic,
    Color statusColor,
  ) {
    final theme = Theme.of(context);
    final canManagePortions = _userRole == 'SUPER_ADMIN' ||
        _userRole == 'ADMIN' ||
        _userRole == 'VENDOR_MEMBER' ||
        _canManageVendors ||
        _canManageOrders;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.store, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fulfillments.length == 1
                          ? (isArabic ? 'تفاصيل المتجر والفرع والأصناف' : 'Store, Branch & Items Details')
                          : (isArabic
                              ? 'محطات وأصناف المتاجر (${fulfillments.length} متاجر)'
                              : 'Store Stops & Items (${fulfillments.length} Stores)'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isArabic
                          ? 'تفاصيل كل متجر والفرع والأصناف المستقلة وحالة التحضير'
                          : 'Each store has a distinct branch stop, status, items, and settlement',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  isArabic ? 'متعدد المتاجر' : 'Multi-Vendor',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < fulfillments.length; i++) ...[
            () {
              final f = fulfillments[i] is Map ? fulfillments[i] as Map : {};
              final fId = f['id']?.toString() ?? '';
              final fStatus = f['status']?.toString() ?? 'PENDING';
              final fVendor = f['vendor'] is Map ? f['vendor'] as Map : {};
              final fBranch = f['vendorBranch'] is Map ? f['vendorBranch'] as Map : {};

              final storeName = isArabic
                  ? (fVendor['storeNameAr'] ?? fVendor['storeName'] ?? fVendor['name'] ?? 'متجر')
                  : (fVendor['storeName'] ?? fVendor['storeNameAr'] ?? fVendor['name'] ?? 'Store');

              final branchName = isArabic
                  ? (fBranch['nameAr'] ?? fBranch['name'] ?? '')
                  : (fBranch['name'] ?? fBranch['nameAr'] ?? '');

              final branchAddress = fBranch['address']?.toString() ?? '';
              final storePhone = fBranch['phone']?.toString() ?? fVendor['phone']?.toString() ?? '';
              final isContracted = fBranch['isContracted'] ?? fVendor['isContracted'] ?? false;
              final storeLogo = fVendor['logo']?.toString() ?? '';

              final fSubtotal = double.tryParse(f['subtotal']?.toString() ?? '0') ?? 0.0;
              final commRate = double.tryParse(f['commissionRate']?.toString() ?? '10') ?? 10.0;
              final commAmount = isContracted ? (fSubtotal * commRate / 100).roundToDouble() : 0.0;
              final netPayout = isContracted ? (fSubtotal - commAmount) : fSubtotal;

              final rawFItems = f['items'];
              List<dynamic> portionItems = (rawFItems is List && rawFItems.isNotEmpty)
                  ? rawFItems
                  : allItems.where((it) => it is Map && it['fulfillmentId'] == fId).toList();

              if (portionItems.isEmpty && (fulfillments.length == 1 || (f['vendorId'] != null && order['vendorId'] == f['vendorId']))) {
                portionItems = allItems;
              }

              final isRejected = fStatus == 'REJECTED' || fStatus == 'CANCELLED';
              final rejectionReason = isArabic
                  ? (f['rejectionReasonAr'] ?? f['rejectionReason'])
                  : (f['rejectionReason'] ?? f['rejectionReasonAr']);
              final rejectionCode = f['rejectionCode']?.toString();

              final pickupPhoto = f['pickupImageUrl']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isRejected
                      ? AppColors.error.withValues(alpha: 0.04)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isRejected
                        ? AppColors.error.withValues(alpha: 0.25)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.09),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store portion header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stop number pill
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Store Logo
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: storeLogo.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: ImageUtils.formatImageUrl(storeLogo),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const Icon(LucideIcons.store, size: 18, color: AppColors.primary),
                                )
                              : const Icon(LucideIcons.store, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),

                        // Store Name & Branch Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      storeName.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: isRejected ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isContracted
                                          ? AppColors.primary.withValues(alpha: 0.08)
                                          : AppColors.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isContracted
                                          ? (isArabic ? 'شريك معتمد' : 'Contracted')
                                          : (isArabic ? 'دفع بالاستلام' : 'Cash at pickup'),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isContracted ? AppColors.primary : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (branchName.toString().isNotEmpty || branchAddress.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        LucideIcons.mapPin,
                                        size: 12,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        branchName.toString().isNotEmpty && branchAddress.isNotEmpty
                                            ? '$branchName - $branchAddress'
                                            : (branchName.toString().isNotEmpty ? branchName.toString() : branchAddress),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Badge
                        _buildPortionStatusBadge(fStatus, isArabic),

                        // Store call button
                        if (storePhone.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _callCustomer(context, storePhone, isArabic),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(LucideIcons.phoneCall, color: AppColors.primary, size: 15),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Stage timestamps / progress pills
                    if (f['preparingAt'] != null || f['readyAt'] != null || f['pickedUpAt'] != null || pickupPhoto != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (f['preparingAt'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isArabic ? "بدء التحضير: " : "Preparing: "}${DateFormat("hh:mm a").format(DateTime.parse(f["preparingAt"].toString()).toLocal())}',
                                style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (f['readyAt'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isArabic ? "جاهز للاستلام: " : "Ready: "}${DateFormat("hh:mm a").format(DateTime.parse(f["readyAt"].toString()).toLocal())}',
                                style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (f['pickedUpAt'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isArabic ? "استلم السائق: " : "Picked up: "}${DateFormat("hh:mm a").format(DateTime.parse(f["pickedUpAt"].toString()).toLocal())}',
                                style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (pickupPhoto != null && pickupPhoto.isNotEmpty)
                            InkWell(
                              onTap: () => _viewFullPhoto(context, pickupPhoto),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.camera, size: 10, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      isArabic ? 'صورة استلام السائق' : 'Driver pickup photo',
                                      style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    // Rejection alert
                    if (isRejected && rejectionReason != null && rejectionReason.toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, size: 14, color: AppColors.error),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${isArabic ? "سبب الرفض: " : "Rejection Reason: "}$rejectionReason${rejectionCode != null ? " ($rejectionCode)" : ""}',
                                style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),

                    // Items in this store portion
                    if (portionItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          isArabic ? 'لا توجد أصناف مسجلة لهذا المتجر' : 'No items listed for this store',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    else
                      for (final item in portionItems) ...[
                        () {
                          final pName = item['productName']?.toString() ??
                              item['name']?.toString() ??
                              (isArabic ? 'صنف' : 'Item');
                          final variant = item['variantName']?.toString();
                          final unit = item['selectedUnit']?.toString();
                          final pQty = item['quantity'] ?? 1;
                          final pPrice = double.tryParse(
                                item['unitPrice']?.toString() ?? item['price']?.toString() ?? '0',
                              ) ??
                              0.0;
                          final pTotalPrice = double.tryParse(item['totalPrice']?.toString() ?? '0') ?? (pPrice * (pQty as num));
                          final product = item['product'] is Map ? item['product'] as Map : null;
                          final pImgUrl = product?['imageUrl']?.toString() ?? item['imageUrl']?.toString() ?? '';
                          final pNotes = item['specialRequest']?.toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: pImgUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: ImageUtils.formatImageUrl(pImgUrl),
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => const Icon(LucideIcons.package, size: 16, color: Colors.grey),
                                        )
                                      : const Icon(LucideIcons.package, size: 16, color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${pQty}x',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pName,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      if ((variant != null && variant.isNotEmpty) || (unit != null && unit.isNotEmpty))
                                        Padding(
                                          padding: const EdgeInsets.only(top: 1),
                                          child: Text(
                                            [if (variant != null && variant.isNotEmpty) variant, if (unit != null && unit.isNotEmpty) unit].join(' • '),
                                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                          ),
                                        ),
                                      if (pNotes != null && pNotes.trim().isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 3),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.messageSquare, size: 10, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  pNotes,
                                                  style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      for (final opt in ((item['selectedOptions'] as List?) ?? []))
                                        if (opt is Map &&
                                            (opt['optionName']?.toString().isNotEmpty ?? false))
                                          Padding(
                                            padding: const EdgeInsets.only(top: 1),
                                            child: Text(
                                              '+ ${opt['optionName']}${(double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0) > 0 ? ' (+${opt['priceAdded']} EGP)' : ''}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${pTotalPrice.toStringAsFixed(2)} EGP',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }(),
                      ],

                    // Portion footer: Subtotal & net payout
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArabic ? 'إجمالي أصناف المتجر:' : 'Store Subtotal:',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${fSubtotal.toStringAsFixed(2)} EGP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (isContracted) ...[
                            Text(
                              isArabic
                                  ? 'الصافي (${(100 - commRate).toInt()}٪): ${netPayout.toStringAsFixed(2)} EGP'
                                  : 'Net (${(100 - commRate).toInt()}%): ${netPayout.toStringAsFixed(2)} EGP',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Quick portion actions for Super Admin / Admin (or multi-branch Vendor Owner/Manager)
                    if (canManagePortions &&
                        (_userRole != 'VENDOR_MEMBER' || fulfillments.length > 1) &&
                        !isRejected &&
                        fStatus != 'DELIVERED') ...[
                      const SizedBox(height: 10),
                      if (fStatus == 'PENDING') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(ordersProvider.notifier).acceptFulfillment(fId);
                                },
                                icon: const Icon(LucideIcons.checkCheck, size: 14),
                                label: Text(
                                  isArabic ? 'قبول هذا المتجر' : 'Accept Store',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showRejectFulfillmentDialog(context, fId, storeName.toString(), isArabic);
                                },
                                icon: const Icon(LucideIcons.xCircle, size: 14),
                                label: Text(
                                  isArabic ? 'رفض' : 'Reject',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (fStatus == 'ACCEPTED' &&
                          !(((order['status'] == 'PENDING_PAYMENT' ||
                                      order['paymentMethod'] == 'MOBILE_WALLET' ||
                                      (double.tryParse(order['upfrontAmount']?.toString() ?? '0') ?? 0.0) > 0) &&
                                  order['paymentStatus'] != 'COMPLETED')) &&
                          (order['status'] == 'DRIVER_ASSIGNED' ||
                              order['status'] == 'PREPARING' ||
                              order['status'] == 'READY_FOR_PICKUP' ||
                              ((order['deliveryGroups'] as List?) ?? []).any((g) =>
                                  g is Map &&
                                  (g['status'] == 'DRIVER_ASSIGNED' ||
                                      g['status'] == 'READY_FOR_PICKUP') &&
                                  ((g['items'] as List?) ?? []).any((it) =>
                                      it is Map && it['fulfillmentId'] == fId)))) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showPrepTimeDialog(
                                context,
                                order['id'],
                                fulfillmentId: fId,
                              );
                            },
                            icon: const Icon(LucideIcons.chefHat, size: 14),
                            label: Text(
                              isArabic ? 'بدء تحضير أصناف هذا المتجر' : 'Start Preparing This Store Items',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ] else if (fStatus == 'PREPARING') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref.read(ordersProvider.notifier).updateOrderStatus(
                                order['id'],
                                'READY_FOR_PICKUP',
                                fulfillmentId: fId,
                              );
                            },
                            icon: const Icon(LucideIcons.packageCheck, size: 14),
                            label: Text(
                              isArabic ? 'تأكيد جاهزية أصناف المتجر للاستلام' : 'Mark Store Ready for Pickup',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }

  void _showRejectFulfillmentDialog(
    BuildContext context,
    String fulfillmentId,
    String storeName,
    bool isArabic,
  ) {
    final controller = TextEditingController();
    String selectedReason = isArabic ? 'نفاد الكمية' : 'Out of stock';
    String selectedCode = 'OUT_OF_STOCK';

    final reasons = [
      {'code': 'OUT_OF_STOCK', 'ar': 'نفاد الكمية', 'en': 'Out of stock'},
      {'code': 'TOO_BUSY', 'ar': 'المتجر مشغول جداً', 'en': 'Too busy'},
      {'code': 'ITEM_UNAVAILABLE', 'ar': 'أصناف غير متوفرة', 'en': 'Item unavailable'},
      {'code': 'ORDER_TOO_LARGE', 'ar': 'الطلب كبير جداً', 'en': 'Order too large'},
      {'code': 'OTHER', 'ar': 'سبب آخر', 'en': 'Other reason'},
    ];

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic ? 'رفض محطة متجر: $storeName' : 'Reject Store Stop: $storeName',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? 'سيتم إلغاء هذا المتجر من الطلب وإعادة قيمة أصنافه للعميل، ولن تتأثر باقي المتاجر.'
                        : 'This store portion will be cancelled and refunded to the customer. Other stores remain unaffected.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: reasons.map((r) {
                      final isSelected = selectedCode == r['code'];
                      final rText = isArabic ? r['ar']! : r['en']!;
                      return ChoiceChip(
                        label: Text(rText, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                        selected: isSelected,
                        selectedColor: AppColors.error,
                        onSelected: (val) {
                          if (val) {
                            setDialogState(() {
                              selectedCode = r['code']!;
                              selectedReason = rText;
                              controller.text = rText;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: isArabic ? 'اكتب سبب الرفض بالتفصيل...' : 'Enter rejection reason...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(isArabic ? 'تراجع' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final reason = controller.text.trim().isNotEmpty ? controller.text.trim() : selectedReason;
                    Navigator.pop(dialogCtx);
                    ref.read(ordersProvider.notifier).rejectFulfillment(fulfillmentId, reason, code: selectedCode);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isArabic ? 'تأكيد الرفض' : 'Confirm Rejection'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPricingBreakdown(dynamic order, bool isArabic) {
    final fulfillments = (order['vendorFulfillments'] as List<dynamic>?) ?? [];
    final bool isMultiVendor = order['isMultiVendor'] == true ||
        fulfillments.length > 1 ||
        (order['vendor'] == null && fulfillments.isNotEmpty);

    final financials = order['financials'] is Map ? order['financials'] as Map : null;
    final storePayments = (financials?['storePayments'] as List<dynamic>?) ?? [];

    if (isMultiVendor && (fulfillments.length > 1 || storePayments.length > 1)) {
      final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
      final deliveryFee = double.tryParse(order['deliveryFee']?.toString() ?? '0') ?? 0.0;
      final grandTotal = double.tryParse(
            order['grandTotal']?.toString() ?? order['total']?.toString() ?? '0',
          ) ??
          (subtotal + deliveryFee);
      final totalNetPayout = double.tryParse(financials?['cashToPayStore']?.toString() ?? '0') ?? 0.0;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.receipt, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'تفاصيل مستحقات المتاجر والماليات' : 'Stores & Financials Breakdown',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (storePayments.isNotEmpty)
              for (final sp in storePayments) ...[
                () {
                  final sMap = sp is Map ? sp : {};
                  final sName = isArabic
                      ? (sMap['vendorName'] ?? 'متجر')
                      : (sMap['vendorNameEn'] ?? sMap['vendorName'] ?? 'Store');
                  final bName = sMap['branchName']?.toString() ?? '';
                  final sSub = double.tryParse(sMap['subtotal']?.toString() ?? '0') ?? 0.0;
                  final sPay = double.tryParse(sMap['cashToPay']?.toString() ?? '0') ?? 0.0;
                  final isCont = sMap['isContracted'] == true;
                  final label = bName.isNotEmpty ? '$sName ($bName)' : sName.toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${sSub.toStringAsFixed(2)} EGP',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (isCont)
                              Text(
                                isArabic ? 'صافي: ${sPay.toStringAsFixed(2)} EGP' : 'Net: ${sPay.toStringAsFixed(2)} EGP',
                                style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }(),
              ]
            else
              for (final f in fulfillments) ...[
                () {
                  final fMap = f is Map ? f : {};
                  final vMap = fMap['vendor'] is Map ? fMap['vendor'] as Map : {};
                  final bMap = fMap['vendorBranch'] is Map ? fMap['vendorBranch'] as Map : {};
                  final sName = isArabic
                      ? (vMap['storeNameAr'] ?? vMap['storeName'] ?? 'متجر')
                      : (vMap['storeName'] ?? vMap['storeNameAr'] ?? 'Store');
                  final bName = isArabic ? (bMap['nameAr'] ?? bMap['name'] ?? '') : (bMap['name'] ?? bMap['nameAr'] ?? '');
                  final sSub = double.tryParse(fMap['subtotal']?.toString() ?? '0') ?? 0.0;
                  final label = bName.toString().isNotEmpty ? '$sName ($bName)' : sName.toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Text(
                          '${sSub.toStringAsFixed(2)} EGP',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }(),
              ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1),
            ),
            _buildPriceRow(isArabic ? 'إجمالي أصناف المتاجر' : 'Stores Food Subtotal', subtotal),
            const SizedBox(height: 4),
            _buildPriceRow(isArabic ? 'رسوم التوصيل' : 'Delivery Fee', deliveryFee),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'إجمالي الطلب' : 'Grand Total',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${grandTotal.toStringAsFixed(2)} EGP',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'إجمالي مستحقات المتاجر' : 'Total Stores Payout',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${totalNetPayout.toStringAsFixed(2)} EGP',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final subtotal = financials?['storeSubtotal'] != null
        ? (double.tryParse(financials!['storeSubtotal'].toString()) ?? 0.0)
        : (double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0);
    final commissionRate = financials?['commissionRate'] != null
        ? (double.tryParse(financials!['commissionRate'].toString()) ?? 0.0)
        : null;
    final commissionAmount = financials?['commissionAmount'] != null
        ? (double.tryParse(financials!['commissionAmount'].toString()) ?? 0.0)
        : null;
    final netPayout = financials?['netPayout'] != null
        ? (double.tryParse(financials!['netPayout'].toString()) ?? 0.0)
        : subtotal;
    final isContracted = financials?['isContracted'] ??
        (order['vendorBranch']?['isContracted'] ?? order['vendor']?['isContracted'] ?? false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow(isArabic ? 'إجمالي منتجات المتجر' : 'Store Food Subtotal', subtotal),
          if (commissionAmount != null && commissionAmount > 0) ...[
            const SizedBox(height: 6),
            _buildPriceRow(
              isArabic ? 'عمولة المنصة (${commissionRate?.toInt() ?? 10}٪)' : 'Platform Commission (${commissionRate?.toInt() ?? 10}%)',
              -commissionAmount,
              isDiscount: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'صافي مستحقات المتجر' : 'Net Store Payout',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${netPayout.toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isContracted
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isContracted ? LucideIcons.wallet : LucideIcons.banknote,
                  size: 14,
                  color: isContracted ? AppColors.primary : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  isContracted
                      ? (isArabic ? 'تتم التسوية في محفظة المتجر الرقمية' : 'Settled to store digital wallet')
                      : (isArabic ? 'تحصيل نقدي من الكابتن عند الاستلام' : 'Collect cash from driver upon pickup'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isContracted ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double? value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface,
          ),
        ),
        Text(
          value == null 
              ? '---' 
              : '${value > 0 && isDiscount ? '-' : ''}${value.abs().toStringAsFixed(2)} EGP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color:
                isDiscount
                    ? AppColors.error
                    : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  String _resolveOrderProofUrl(dynamic order, String field) {
    final direct = order[field]?.toString() ?? '';
    if (direct.isNotEmpty) return direct;
    final myFulfillmentId = order['myFulfillmentId']?.toString();
    if (order['vendorFulfillments'] is List) {
      for (final f in (order['vendorFulfillments'] as List)) {
        if (f is Map &&
            (myFulfillmentId == null || f['id']?.toString() == myFulfillmentId)) {
          final fUrl = f[field]?.toString() ?? '';
          if (fUrl.isNotEmpty) return fUrl;
        }
      }
    }
    if (order['deliveryGroups'] is List) {
      for (final grp in (order['deliveryGroups'] as List)) {
        if (grp is Map) {
          final gUrl = grp[field]?.toString() ?? '';
          if (gUrl.isNotEmpty) return gUrl;
        }
      }
    }
    return '';
  }

  Widget _buildProofPhotoRow(
    BuildContext context,
    dynamic order,
    bool isArabic, {
    required String field,
    required String title,
    required String titleAr,
  }) {
    final rawUrl = _resolveOrderProofUrl(order, field);
    if (rawUrl.isEmpty) return const SizedBox.shrink();
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final fullUrl = (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
        ? rawUrl
        : '$cleanBaseUrl${rawUrl.startsWith('/') ? rawUrl : '/$rawUrl'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _viewFullPhoto(context, fullUrl),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: fullUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).dividerColor,
                    child: const Icon(LucideIcons.imageOff, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? titleAr : title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic ? 'اضغط لعرض الصورة' : 'Tap to view',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const AppAdaptiveChevron(size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callCustomer(
    BuildContext context,
    String phone,
    bool isArabic,
  ) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!context.mounted) return;
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'رقم الهاتف غير متاح' : 'Phone number not available',
          ),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تعذر بدء الاتصال' : 'Could not start the call',
          ),
        ),
      );
    }
  }

  Future<void> _locateDriverFromOrder(
    BuildContext context,
    dynamic order,
    bool isArabic,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final driverId = order['driver']?['id']?.toString() ?? '';
    if (driverId.isEmpty) return;
    try {
      final result = await ref
          .read(adminDriversRepositoryProvider)
          .getDriverLocation(driverId: driverId);
      final data = (result is Map) ? result : null;
      final lat = (data?['latitude'] as num?)?.toDouble();
      final lng = (data?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null || !mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.driverNoLocation)),
        );
        return;
      }
      final isLive = data?['isLive'] == true;

      final deliveryLoc = order['deliveryLocation'];
      double? deliveryLat;
      double? deliveryLng;
      if (deliveryLoc is List && deliveryLoc.length >= 2) {
        final possibleLng = (deliveryLoc[0] as num?)?.toDouble();
        final possibleLat = (deliveryLoc[1] as num?)?.toDouble();
        if (possibleLat != null && possibleLng != null) {
          deliveryLat = possibleLat;
          deliveryLng = possibleLng;
        }
      }

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          final markers = <Marker>[
            Marker(
              point: LatLng(lat, lng),
              width: 44,
              height: 44,
              child: const Icon(
                LucideIcons.navigation,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            if (deliveryLat != null && deliveryLng != null)
              Marker(
                point: LatLng(deliveryLat, deliveryLng),
                width: 32,
                height: 32,
                child: const Icon(
                  LucideIcons.mapPin,
                  size: 28,
                  color: AppColors.error,
                ),
              ),
          ];

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          isArabic ? 'موقع السائق' : 'Driver location',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(LucideIcons.x),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lng),
                          initialZoom: 15,
                        ),
                        children: [
                          const AppMapTileLayer(userAgentPackageName: 'com.otlob.admin'),
                          MarkerLayer(markers: markers),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          isLive
                              ? LucideIcons.radio
                              : LucideIcons.clock,
                          size: 16,
                          color: isLive
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isLive
                                ? l10n.driverLiveLocation
                                : l10n.driverLastKnownLocation,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (err) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(ErrorUtils.translate(context, err)), backgroundColor: AppColors.error),
      );
    }
  }

  void _viewFullPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => const Icon(
                      LucideIcons.imageOff,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(LucideIcons.x, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status, bool isArabic) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'PENDING':
        color = AppColors.warning;
        label = isArabic ? 'جديد' : 'New';
        icon = LucideIcons.clock;
        break;
      case 'DRIVER_ASSIGNED':
        color = Colors.orange;
        label = isArabic ? 'تم تعيين السائق' : 'Driver Assigned';
        icon = LucideIcons.userCheck;
        break;
      case 'PARTIALLY_PICKED_UP':
        color = Colors.indigo;
        label = isArabic ? 'جاري الاستلام من المتاجر' : 'Partially Picked Up';
        icon = LucideIcons.truck;
        break;
      case 'ACCEPTED':
        color = AppColors.primary;
        label = isArabic ? 'مقبول' : 'Accepted';
        icon = LucideIcons.thumbsUp;
        break;
      case 'PREPARING':
        color = Colors.blue;
        label = isArabic ? 'تحضير' : 'Preparing';
        icon = LucideIcons.chefHat;
        break;
      case 'READY_FOR_PICKUP':
        color = AppColors.success;
        label = isArabic ? 'جاهز' : 'Ready';
        icon = LucideIcons.package;
        break;
      case 'DELIVERED':
      case 'PICKED_UP':
        color = Colors.green;
        label = isArabic ? 'مكتمل' : 'Completed';
        icon = LucideIcons.checkCircle2;
        break;
      case 'CANCELLED':
        color = AppColors.error;
        label = isArabic ? 'ملغي' : 'Cancelled';
        icon = LucideIcons.xCircle;
        break;
      case 'LOOKING_FOR_DRIVER':
        color = Colors.blueAccent;
        label = isArabic ? 'جاري البحث عن سائق' : 'Looking for Driver';
        icon = LucideIcons.search;
        break;
      case 'PENDING_PAYMENT':
        color = Colors.purple;
        label = isArabic ? 'في انتظار الدفع' : 'Pending Payment';
        icon = LucideIcons.creditCard;
        break;
      case 'IN_TRANSIT':
      case 'ARRIVING':
        color = Colors.indigo;
        label = isArabic ? 'في الطريق' : 'On the Way';
        icon = LucideIcons.truck;
        break;
      default:
        color = Colors.grey;
        // Capitalize first letter of each word
        label = status.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
        icon = LucideIcons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    dynamic order,
    String status,
    bool isArabic,
  ) {
    if (_userRole != 'VENDOR_MEMBER' &&
        _userRole != 'ADMIN' &&
        _userRole != 'SUPER_ADMIN') {
      return const SizedBox();
    }
    if (status == 'DELIVERED' || status == 'CANCELLED') {
      return const SizedBox();
    }

    // A multi-vendor portion is decided once (accepted or rejected). After that
    // the only remaining vendor action is production, so the Cancel button must
    // not offer a rejection the backend will refuse.
    final isMultiVendorPortion = order['myFulfillmentStatus'] != null;
    final myFulfillmentId = order['myFulfillmentId']?.toString();
    final canCancelPortion = !isMultiVendorPortion || status == 'PENDING' || status == 'ACCEPTED' || status == 'DRIVER_ASSIGNED' || status == 'PENDING_PAYMENT' || status == 'PREPARING' || status == 'READY_FOR_PICKUP';

    String mainButtonText = '';
    String nextStatus = '';
    IconData icon = LucideIcons.check;

    if (status == 'PENDING') {
      mainButtonText = isArabic ? 'قبول الطلب' : 'Accept Order';
      nextStatus = 'ACCEPTED';
      icon = LucideIcons.checkCheck;
    } else if (status == 'DRIVER_ASSIGNED' || status == 'PENDING_PAYMENT') {
      // Mobile-wallet and upfront-payment orders must be paid first: the button stays disabled
      // until payment is completed (paymentStatus == COMPLETED).
      final isMobileWallet =
          (order['paymentMethod']?.toString() ?? '') == 'MOBILE_WALLET';
      final upfrontAmount =
          double.tryParse(order['upfrontAmount']?.toString() ?? '0') ?? 0.0;
      final isPaymentCompleted =
          (order['paymentStatus']?.toString() ?? '') == 'COMPLETED';
      if ((status == 'PENDING_PAYMENT' || isMobileWallet || upfrontAmount > 0) &&
          !isPaymentCompleted) {
        mainButtonText = isArabic ? 'بانتظار الدفع' : 'Waiting for Payment';
        icon = LucideIcons.clock;
      } else {
        // Driver accepted (and, when required, customer approved the fee) —
        // vendor can now start preparing.
        mainButtonText = isArabic ? 'بدء التحضير' : 'Start Preparing';
        nextStatus = 'PREPARING';
        icon = LucideIcons.chefHat;
      }
    } else if (status == 'ACCEPTED' || status == 'LOOKING_FOR_DRIVER') {
      // Disabled: must wait until a driver accepts the order.
      mainButtonText = isArabic ? 'بانتظار السائق' : 'Waiting for Driver';
      icon = LucideIcons.clock;
    } else if (status == 'PREPARING') {
      mainButtonText = isArabic ? 'تأكيد جاهزية الطلب' : 'Mark as Ready';
      nextStatus = 'READY_FOR_PICKUP';
      icon = LucideIcons.packageCheck;
    }

    return Row(
      children: [
        if (mainButtonText.isNotEmpty) ...[
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: nextStatus.isEmpty ? null : AppColors.primaryGradient,
                color: nextStatus.isEmpty ? Colors.grey.shade400 : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: nextStatus.isEmpty ? null : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: nextStatus.isEmpty ? null : () {
                  if (nextStatus == 'PREPARING') {
                    // Beautiful dialog prompt for Prep Time
                    _showPrepTimeDialog(
                      context,
                      order['id'],
                      fulfillmentId: myFulfillmentId,
                    );
                  } else {
                    ref
                        .read(ordersProvider.notifier)
                        .updateOrderStatus(
                          order['id'],
                          nextStatus,
                          fulfillmentId: myFulfillmentId,
                        );
                  }
                },
                icon: Icon(icon, size: 16, color: Colors.white),
                label: Text(mainButtonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (canCancelPortion)
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(
                context,
                order['id'],
                isArabic,
                fulfillmentId: myFulfillmentId,
              ),
              icon: const Icon(LucideIcons.xCircle, size: 16),
              label: Text(isArabic ? 'إلغاء' : 'Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openOrderChat(BuildContext context, dynamic order, bool isArabic) async {
    final orderId = order['id']?.toString();
    final orderCode = order['orderNumber']?.toString() ?? (orderId != null && orderId.length >= 8 ? orderId.substring(0, 8) : orderId ?? '');
    if (orderId == null) return;

    try {
      final chatRepo = ref.read(sharedChatRepositoryProvider);
      final conversation = await chatRepo.createOrderConversation(orderId);
      final convoData = conversation is Map && conversation.containsKey('data')
          ? conversation['data']
          : conversation;
      final convoId = convoData?['id']?.toString() ?? orderId;

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => AdminChatScreen(
            conversationId: convoId,
            title: isArabic ? 'محادثة الطلب #$orderCode' : 'Order Chat #$orderCode',
            type: 'ORDER',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }

  void _showPrepTimeDialog(
    BuildContext context,
    String orderId, {
    String? fulfillmentId,
  }) {
    int prepTime = 20; // Default
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DialogScaffold(child: AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isArabic ? 'تحديد وقت التحضير' : 'Set Preparation Time',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic
                        ? 'كم دقيقة سيستغرق تحضير هذا الطلب؟'
                        : 'How many minutes will it take to prepare this order?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          LucideIcons.minusCircle,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        onPressed: () {
                          if (prepTime > 5) {
                            setDialogState(() => prepTime -= 5);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          '$prepTime ${isArabic ? 'دقيقة' : 'mins'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          LucideIcons.plusCircle,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        onPressed: () {
                          if (prepTime < 120) {
                            setDialogState(() => prepTime += 5);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    isArabic ? 'إلغاء' : 'Cancel',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    ref
                        .read(ordersProvider.notifier)
                        .updateOrderStatus(
                          orderId,
                          'PREPARING',
                          estimatedPrepTime: prepTime,
                          fulfillmentId: fulfillmentId,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isArabic ? 'بدء التحضير' : 'Start'),
                ),
              ],
            ));
          },
        );
      },
    );
  }

  void _showCancelDialog(
    BuildContext context,
    String orderId,
    bool isArabic, {
    String? fulfillmentId,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return DialogScaffold(child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isArabic ? 'إلغاء الطلب' : 'Cancel Order',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'برجاء كتابة سبب إلغاء هذا الطلب:'
                    : 'Please specify the reason for cancelling this order:',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'مثال: المنتج غير متوفر'
                      : 'e.g., Out of stock',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                isArabic ? 'تراجع' : 'Back',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                Navigator.pop(dialogCtx);
                ref
                    .read(ordersProvider.notifier)
                    .cancelOrder(
                      orderId,
                      reason.isNotEmpty ? reason : 'Cancelled by vendor/admin',
                      fulfillmentId: fulfillmentId,
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isArabic ? 'إلغاء الطلب' : 'Cancel Order'),
            ),
          ],
        ));
      },
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(
                  alpha: 0.8 * (1 - _controller.value),
                ),
                blurRadius: 10 * _controller.value,
                spreadRadius: 6 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

