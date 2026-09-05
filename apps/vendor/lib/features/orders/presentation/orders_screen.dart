import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:vendor/core/providers.dart';
import '../presentation/orders_provider.dart';
import 'widgets/assign_driver_sheet.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _userRole = '';
  Timer? _refreshTimer;
  StreamSubscription? _orderStatusSub;
  final Map<String, bool> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).fetchOrders();
      _setupSocketListener();
    });
    _loadUserRole();

    // Fallback safety-net poll every 60 seconds in case socket misses an event
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _loadOrders();
      }
    });
  }

  void _setupSocketListener() {
    final socket = ref.read(socketServiceProvider);
    
    void handleSocketEvent(dynamic data) {
      if (data != null && data is Map && data['orderId'] != null) {
        final newStatus = data['newStatus'] ?? data['status'];
        if (newStatus != null) {
          ref.read(ordersProvider.notifier).updateOrderStatusFast(data['orderId'], newStatus);
        }
      }
      _loadOrders();
    }

    // Listen to order.status events for instant updates
    _orderStatusSub = socket.onEvent(SocketEvent.orderStatus).listen((data) {
      if (mounted) {
        handleSocketEvent(data);
      }
    });
    // Also listen to notificationNew which fires for every order change
    socket.onEvent(SocketEvent.notificationNew).listen((data) {
      if (mounted) {
        // Sometimes notification doesn't have orderId at root level, but we can pass it to handleSocketEvent safely
        handleSocketEvent(data);
      }
    });
    // Listen to new orders and cancelled orders
    socket.onEvent(SocketEvent.orderNew).listen((data) {
      if (mounted) {
        _loadOrders();
      }
    });
    socket.onEvent(SocketEvent.orderCancelled).listen((data) {
      if (mounted) {
        handleSocketEvent(data);
      }
    });
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _orderStatusSub?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
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
                        state.error.toString(),
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
              final orders = state.value!.orders;

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

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildSleekOrderCard(context, order, isArabic);
                },
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
    final hasDriver = driverName.isNotEmpty || order['driverId'] != null;
    final isCancelled = status.contains('CANCEL') || status.contains('REJECT');
    final areFeesFinalized = hasDriver && !isCancelled && status != 'DRIVER_ASSIGNED' && status != 'PENDING_CUSTOMER_APPROVAL';
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
      final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
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

    return Container(
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

                        // Collapsed Item specifications (Item Name and Image)
                        if (items.isNotEmpty) ...[
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
                                    maxLines: 1,
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
                                          onTap: () {
                                            // Call actions
                                          },
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
                                      value:
                                          '$driverName (${vehicleType.toUpperCase()} - $vehiclePlate)',
                                      iconColor: statusColor,
                                    ),
                                  ],
                                  if (_userRole == 'ADMIN' && ['ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'LOOKING_FOR_DRIVER'].contains(order['status'])) ...[
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
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Order items Section with sleek layout
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.shoppingBag,
                                    size: 16,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isArabic
                                        ? 'تفاصيل الأصناف'
                                        : 'Items Specification',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, i) {
                                  final item = items[i];
                                  final productName =
                                      item['productName']?.toString() ?? '';
                                  final quantity = item['quantity'] ?? 1;
                                  final price =
                                      double.tryParse(
                                        item['unitPrice']?.toString() ?? '0',
                                      ) ??
                                      0.0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${quantity}x',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            productName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${(price * quantity).toStringAsFixed(2)} EGP',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildCollapsedItemRow(
    BuildContext context,
    List<dynamic> items,
    bool isArabic,
  ) {
    final firstItem = items.first;
    final product = firstItem['product'] ?? {};
    final productImgUrl = product['imageUrl']?.toString() ?? '';
    final productName = isArabic
        ? (product['nameAr'] ?? product['name'] ?? '')
        : (product['name'] ?? '');
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
                maxLines: 1,
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
    if (status == 'PREPARING' || status == 'COOKING' || status == 'ACCEPTED' || status == 'LOOKING_FOR_DRIVER') {
      currentStep = 1;
    } else if (status == 'READY_FOR_PICKUP' || status == 'PICKED_UP') {
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

  Widget _buildPricingBreakdown(dynamic order, bool isArabic) {
    final status = order['status'] as String? ?? 'PENDING';
    final driver = order['driver'];
    final driverName = (driver is Map) ? (driver['name']?.toString() ?? '') : '';
    final hasDriver = driverName.isNotEmpty || order['driverId'] != null;
    final isCancelled = status.contains('CANCEL') || status.contains('REJECT');
    final areFeesFinalized = hasDriver && !isCancelled && status != 'DRIVER_ASSIGNED' && status != 'PENDING_CUSTOMER_APPROVAL';

    final subtotal =
        double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
    final deliveryFee = areFeesFinalized ? (double.tryParse(order['deliveryFee']?.toString() ?? '0') ?? 0.0) : null;
    final serviceFee = areFeesFinalized ? (double.tryParse(order['serviceFee']?.toString() ?? '0') ?? 0.0) : null;
    final tax = areFeesFinalized ? (double.tryParse(order['tax']?.toString() ?? '0') ?? 0.0) : null;
    final discount =
        double.tryParse(order['discount']?.toString() ?? '0') ?? 0.0;
    final grandTotal = areFeesFinalized ? (double.tryParse(order['grandTotal']?.toString() ?? '0') ?? 0.0) : subtotal;

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
          _buildPriceRow(isArabic ? 'المجموع الفرعي' : 'Subtotal', subtotal),
          const SizedBox(height: 6),
          _buildPriceRow(
            isArabic ? 'رسوم التوصيل' : 'Delivery Fee',
            deliveryFee,
          ),
          const SizedBox(height: 6),
          _buildPriceRow(isArabic ? 'رسوم الخدمة' : 'Service Fee', serviceFee),
          const SizedBox(height: 6),
          _buildPriceRow(isArabic ? 'الضريبة' : 'Tax', tax),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _buildPriceRow(
              isArabic ? 'الخصم' : 'Discount',
              -discount,
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
                isArabic ? 'الإجمالي النهائي' : 'Grand Total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${grandTotal.toStringAsFixed(2)} EGP',
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
      case 'PENDING_CUSTOMER_APPROVAL':
        color = Colors.orange;
        label = isArabic ? 'بانتظار موافقة العميل' : 'Pending Approval';
        icon = LucideIcons.clock;
        break;
      case 'DRIVER_ASSIGNED':
        color = Colors.orange;
        label = isArabic ? 'بانتظار موافقة العميل' : 'Pending Approval';
        icon = LucideIcons.userCheck;
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
      case 'CHANGES_REQUESTED':
        color = Colors.orange;
        label = isArabic ? 'تعديلات مطلوبة' : 'Changes Requested';
        icon = LucideIcons.edit3;
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
    if (_userRole == 'ADMIN') {
      return const SizedBox(); // Read-only for Admin!
    }
    if (status == 'DELIVERED' || status == 'CANCELLED') {
      return const SizedBox();
    }

    String mainButtonText = '';
    String nextStatus = '';
    IconData icon = LucideIcons.check;

    if (status == 'PENDING') {
      mainButtonText = isArabic ? 'قبول الطلب' : 'Accept Order';
      nextStatus = 'ACCEPTED';
      icon = LucideIcons.checkCheck;
    } else if (status == 'ACCEPTED' || status == 'LOOKING_FOR_DRIVER' || status == 'PENDING_CUSTOMER_APPROVAL') {
      mainButtonText = isArabic ? 'بدء التحضير' : 'Start Preparing';
      nextStatus = 'PREPARING';
      icon = LucideIcons.chefHat;
    } else if (status == 'DRIVER_ASSIGNED' || status == 'PENDING_PAYMENT') {
      mainButtonText = isArabic ? 'بدء التحضير' : 'Start Preparing';
      nextStatus = 'PREPARING';
      icon = LucideIcons.chefHat;
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
                    _showPrepTimeDialog(context, order['id']);
                  } else {
                    ref
                        .read(ordersProvider.notifier)
                        .updateOrderStatus(order['id'], nextStatus);
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
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: () => _showCancelDialog(context, order['id'], isArabic),
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

  void _showPrepTimeDialog(BuildContext context, String orderId) {
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

  void _showCancelDialog(BuildContext context, String orderId, bool isArabic) {
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

