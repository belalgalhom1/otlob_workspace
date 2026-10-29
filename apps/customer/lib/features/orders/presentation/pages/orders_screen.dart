import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';
import '../../../../core/utils/image_utils.dart';
import '../widgets/rate_order_bottom_sheet.dart';
import '../../../../core/services/socket_service.dart';
import '../providers/orders_provider.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

String _translateStatus(String status, bool isArabic) {
  switch (status) {
    case 'PENDING': return isArabic ? 'قيد الانتظار' : 'Pending';
    case 'ACCEPTED': return isArabic ? 'مقبول' : 'Accepted';
    case 'PREPARING': return isArabic ? 'قيد التحضير' : 'Preparing';
    case 'LOOKING_FOR_DRIVER': return isArabic ? 'جاري البحث عن مندوب' : 'Looking for Driver';
    case 'DRIVER_ASSIGNED': return isArabic ? 'تم تعيين المندوب' : 'Driver Assigned';
    case 'PENDING_PAYMENT': return isArabic ? 'في انتظار الدفع' : 'Pending Payment';
    case 'READY_FOR_PICKUP': return isArabic ? 'جاهز للاستلام' : 'Ready for Pickup';
    case 'PICKED_UP': return isArabic ? 'تم الاستلام من المتجر' : 'Picked Up';
    case 'IN_TRANSIT':
    case 'ARRIVING': return isArabic ? 'في الطريق' : 'On the Way';
    case 'DELIVERED': return isArabic ? 'تم التوصيل' : 'Delivered';
    case 'CANCELLED': return isArabic ? 'ملغي' : 'Cancelled';
    default:
      return status.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
  }
}

/// Wallet label using existing translations only: InstaPay wallets show
/// InstaPay, everything else shows Mobile Wallet. No custom names added.
String _walletProviderName(Map<dynamic, dynamic> wallet, AppStrings s) {
  if (_isInstaPayWallet(wallet)) return s.instapay;
  return s.mobileWallet;
}

bool _isInstaPayWallet(Map<dynamic, dynamic> wallet) {
  return (wallet['type'] ?? wallet['provider'] ?? '')
      .toString()
      .toUpperCase()
      .contains('INSTAPAY');
}

/// For a mobile-wallet payment the customer must see the mobile-money
/// wallets (Vodafone etc.) — not InstaPay. InstaPay entries are only shown
/// when the driver has no mobile-money wallet at all (fallback).
List<dynamic> _visibleDriverWallets(List<dynamic> wallets) {
  final mobile = wallets.where((w) {
    final m = w is Map ? Map<dynamic, dynamic>.from(w) : <dynamic, dynamic>{};
    return !_isInstaPayWallet(m);
  }).toList();
  return mobile.isNotEmpty ? mobile : wallets;
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _activeScrollController = ScrollController();
  final ScrollController _pastScrollController = ScrollController();
  late final void Function(dynamic) _socketHandler;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _updatedSub;
  final Map<String, XFile?> _receiptFiles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _socketHandler = (data) {
      // Fast local flip only — the global order listener owns the throttled
      // list refresh, so one socket event no longer triggers duplicate GETs.
      if (data != null && data['orderId'] != null) {
        final newStatus = data['newStatus'] ?? data['status'];
        if (newStatus != null) {
          ref.read(ordersProvider.notifier).updateOrderStatusFast(data['orderId'], newStatus);
        }
      }
    };

    _activeScrollController.addListener(() {
      if (_activeScrollController.position.pixels >= _activeScrollController.position.maxScrollExtent - 200) {
        ref.read(ordersProvider.notifier).loadMoreActive();
      }
    });

    _pastScrollController.addListener(() {
      if (_pastScrollController.position.pixels >= _pastScrollController.position.maxScrollExtent - 200) {
        ref.read(ordersProvider.notifier).loadMorePast();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSockets();
    });
  }

  void _setupSockets() {
    final socket = ref.read(socketServiceProvider);
    _statusSub?.cancel();
    _updatedSub?.cancel();
    _statusSub = socket.onEvent('order.status').listen(_socketHandler);
    _updatedSub = socket.onEvent('order.updated').listen(_socketHandler);
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _updatedSub?.cancel();

    _tabController.dispose();
    _activeScrollController.dispose();
    _pastScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final ordersState = ref.watch(ordersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          s.navOrders,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: s.isArabic ? 'الطلبات الحالية' : 'Active Orders'),
            Tab(text: s.isArabic ? 'الطلبات السابقة' : 'Past Orders'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildList(
                ordersState.activeOrders,
                ordersState.isLoading,
                ordersState.isLoadingMoreActive,
                _activeScrollController,
                s,
              ),
              _buildList(
                ordersState.pastOrders,
                ordersState.isLoading,
                ordersState.isLoadingMorePast,
                _pastScrollController,
                s,
              ),
            ],
          ),
          const FloatingCartOverlay(),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> orders, bool isInitialLoading, bool isLoadingMore, ScrollController controller, AppStrings s) {
    if (isInitialLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              s.noResults,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: orders.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: AppColors.primary),
          ));
        }
        final order = orders[index];
        return _buildOrderCard(context, ref, order, s);
      },
    );
  }

  Widget _buildStatusTimeline(String status, bool isDark, AppStrings s) {
    if (status == 'CANCELLED') return const SizedBox.shrink();

    int currentStep = 0;
    if (status == 'ACCEPTED' || 
        status == 'PREPARING' || 
        status == 'LOOKING_FOR_DRIVER' || 
        status == 'DRIVER_ASSIGNED' || 
        status == 'PENDING_PAYMENT' ||
        status == 'READY_FOR_PICKUP') {
      currentStep = 1;
    } else if (status == 'PICKED_UP' || 
               status == 'IN_TRANSIT' || 
               status == 'ARRIVING') {
      currentStep = 2;
    } else if (status == 'DELIVERED') {
      currentStep = 3;
    }

    final steps = s.isArabic
        ? ['تم الطلب', 'التحضير', 'في الطريق', 'تم التوصيل']
        : ['Placed', 'Preparing', 'On Way', 'Delivered'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
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
                        height: 2.5,
                        color: index == 0
                            ? Colors.transparent
                            : (isActive ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade200)),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.primary
                            : (isActive ? Colors.white : (isDark ? const Color(0xFF262626) : Colors.grey.shade100)),
                        border: Border.all(
                          color: isActive ? AppColors.primary : (isDark ? Colors.white24 : Colors.grey.shade300),
                          width: 2.5,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? AppColors.primary : Colors.transparent,
                                ),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: index == 3
                            ? Colors.transparent
                            : (index < currentStep
                                ? AppColors.primary
                                : (isDark ? Colors.white10 : Colors.grey.shade200)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                    color: isActive
                        ? AppColors.primary
                        : (isDark ? Colors.white30 : Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _pickUpfrontReceipt(String orderId) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 80,
    );
    if (file != null && mounted) {
      setState(() => _receiptFiles[orderId] = file);
    }
  }

  List<Widget> _buildUpfrontSection(
    Map<String, dynamic> order,
    AppStrings s,
  ) {
    final orderId = order['id']?.toString() ?? '';
    final upfront =
        double.tryParse(order['upfrontAmount']?.toString() ?? '0') ?? 0.0;
    final total =
        double.tryParse((order['grandTotal'] ?? order['total'])?.toString() ?? '0') ?? 0.0;
    // Cash on delivery with an upfront requirement: the customer pays the
    // upfront first. Mobile wallet / InstaPay: always the whole amount.
    final isUpfront =
        (order['paymentMethod']?.toString() ?? '') == 'CASH_ON_DELIVERY' &&
            upfront > 0;
    final amountDue = isUpfront ? upfront : total;
    final paidClaimed = (order['paymentStatus']?.toString() ?? '') == 'PAID';
    final receiptFile = _receiptFiles[orderId];
    return [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                isUpfront
                    ? (s.isArabic
                        ? 'المبلغ المقدم المطلوب دفعه أولاً: ${amountDue.toStringAsFixed(0)} ${s.egp}'
                        : 'Upfront amount to pay first: ${amountDue.toStringAsFixed(0)} ${s.egp}')
                    : (s.isArabic
                        ? 'المبلغ المطلوب تحويله: ${amountDue.toStringAsFixed(0)} ${s.egp}'
                        : 'Amount to transfer: ${amountDue.toStringAsFixed(0)} ${s.egp}'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paidClaimed
                        ? (s.isArabic
                            ? 'تم إرسال تأكيدك. بانتظار أن يؤكد الكابتن استلام المبلغ.'
                            : 'Your confirmation was sent. Waiting for the driver to confirm receipt.')
                        : (s.isArabic
                            ? 'يرجى تحويل مبلغ الطلب إلى إحدى محافظ المندوب التالية، ثم اضغط تأكيد'
                            : 'Please transfer the total amount to one of the driver\'s wallets below, then confirm.'),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._visibleDriverWallets(
                    order['driver']['mobileWallets'] as List)
                .map((wallet) {
              final walletMap = wallet is Map
                  ? Map<dynamic, dynamic>.from(wallet)
                  : <dynamic, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _walletProviderName(walletMap, s),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          (wallet['number'] ?? wallet['walletNumber'] ?? '')
                              .toString(),
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        final walletNum =
                            (wallet['number'] ?? wallet['walletNumber'] ?? '')
                                .toString();
                        Clipboard.setData(ClipboardData(text: walletNum));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(s.isArabic
                              ? 'تم نسخ الرقم: $walletNum'
                              : 'Number copied: $walletNum'),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(s.isArabic ? 'نسخ' : 'Copy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      if (!paidClaimed) ...[
        OutlinedButton.icon(
          onPressed: () => _pickUpfrontReceipt(orderId),
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text(
            receiptFile != null
                ? (receiptFile.name.isNotEmpty
                    ? receiptFile.name
                    : (s.isArabic ? 'تم إرفاق الإيصال' : 'Receipt attached'))
                : (s.isArabic
                    ? 'إرفاق لقطة شاشة من التحويل (إجباري)'
                    : 'Attach transfer screenshot (required)'),
          ),
        ),
        if (receiptFile != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(receiptFile.path),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            if (receiptFile == null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(s.isArabic
                      ? 'يرجى إرفاق لقطة الشاشة أولاً'
                      : 'Please attach the screenshot first')));
              return;
            }
            // Show confirmation dialog before marking as paid
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title:
                    Text(s.isArabic ? 'تأكيد الدفع' : 'Confirm Payment'),
                content: Text(s.isArabic
                    ? 'هل أنت متأكد من تحويل المبلغ المطلوب إلى المندوب؟'
                    : 'Are you sure you transferred the required amount to the driver?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(s.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: Text(s.isArabic ? 'نعم، حولت' : 'Yes, I paid',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );

                    if (confirm == true) {
                      final res = await ref
                          .read(ordersProvider.notifier)
                          .markPaymentPaid(
                            order['id'],
                            receiptPath: receiptFile.path,
                          );
                      if (res) {
                        setState(() => _receiptFiles.remove(orderId));
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res
                                ? (s.isArabic
                                    ? 'تم تأكيد الدفع وجاري مراجعة المندوب'
                                    : 'Payment confirmed, waiting for driver to verify')
                                : (s.isArabic
                                    ? 'فشل التأكيد. حاول مرة أخرى.'
                                    : 'Confirmation failed. Try again.')),
                            backgroundColor:
                                res ? null : Colors.red));
                      }
                    }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 45),
          ),
          child: Text(s.isArabic
              ? 'لقد قمت بتحويل المبلغ'
              : 'I transferred the amount'),
        ),
      ],
    ];
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Map<String, dynamic> order, AppStrings s) {
    final isCustom = order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final vendor = order['vendor'] as Map<String, dynamic>?;
    final vendorBranch = order['vendorBranch'] as Map<String, dynamic>?;
    final fulfillments = (order['vendorFulfillments'] as List<dynamic>?) ?? [];

    String baseVendorName;
    String? vendorLogoUrl = vendor?['logo'] as String?;

    if (vendor != null && (vendor['storeName'] != null || vendor['storeNameAr'] != null)) {
      baseVendorName = s.isArabic
          ? (vendor['storeNameAr'] ?? vendor['storeName'] ?? s.vendor)
          : (vendor['storeName'] ?? vendor['storeNameAr'] ?? s.vendor);
    } else if (fulfillments.isNotEmpty) {
      final names = <String>[];
      for (final f in fulfillments) {
        if (f is Map) {
          final v = f['vendor'] as Map<String, dynamic>?;
          if (v != null) {
            final name = s.isArabic
                ? (v['storeNameAr'] ?? v['storeName'])
                : (v['storeName'] ?? v['storeNameAr']);
            if (name != null && name.toString().trim().isNotEmpty && !names.contains(name.toString().trim())) {
              names.add(name.toString().trim());
            }
            vendorLogoUrl ??= v['logo'] as String?;
          }
        }
      }
      baseVendorName = names.isNotEmpty ? names.join(' + ') : s.vendor;
    } else {
      baseVendorName = s.vendor;
    }

    final branchName = vendorBranch != null
        ? (s.isArabic ? (vendorBranch['nameAr'] ?? vendorBranch['name']) : (vendorBranch['name'] ?? vendorBranch['nameAr']))?.toString()
        : null;
    final vendorName = (branchName != null && branchName.isNotEmpty && fulfillments.length <= 1)
        ? '$baseVendorName • $branchName'
        : baseVendorName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final status = order['status'] as String? ?? 'PENDING';
    final bool isCancelled = status == 'CANCELLED';
    final bool areFeesFinalized = !isCancelled;

    final subtotal = _parseDouble(order['subtotal']);
    
    final rawDeliveryFee = order['deliveryFee'];
    final deliveryFee = _parseDouble(rawDeliveryFee);
    
    final rawServiceFee = order['serviceFee'];
    final serviceFee = _parseDouble(rawServiceFee);
    
    final rawTax = order['tax'];
    final tax = _parseDouble(rawTax);

    final discount = _parseDouble(order['discount']);

    // Total is calculated directly by the backend
    final rawTotal = order['total'] ?? order['totalFee'] ?? order['grandTotal'];
    final total = _parseDouble(rawTotal);

    Color statusColor = AppColors.primary;
    Color statusBgColor = AppColors.primary.withValues(alpha: 0.1);

    if (status == 'DELIVERED') {
      statusColor = AppColors.success;
      statusBgColor = AppColors.success.withValues(alpha: 0.1);
    } else if (status == 'CANCELLED') {
      statusColor = Colors.red;
      statusBgColor = Colors.red.withValues(alpha: 0.1);
    } else if (status == 'PENDING_PAYMENT') {
      statusColor = Colors.purple;
      statusBgColor = Colors.purple.withValues(alpha: 0.1);
    } else if (status != 'PENDING') {
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: isCancelled ? null : () {
        context.push('/order-tracking/${order['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                child: (vendorLogoUrl == null || vendorLogoUrl.isEmpty)
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: AppColors.primary, size: 20),
                      )
                    : CachedNetworkImage(
                        imageUrl: ImageUtils.formatImageUrl(vendorLogoUrl),
                        height: 42,
                        width: 42,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCustom
                          ? s.customDeliveryTitle
                          : '${s.orderNo}${order['orderNumber'] ?? order['id'].toString().split('-').last.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _translateStatus(status, s.isArabic),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          if (!isCustom) _buildStatusTimeline(status, isDark, s),

          const Divider(height: 20),

          if (isCustom) ...[
            Row(
              children: [
                const Icon(Icons.circle, size: 10, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.pickupLocation}: ${order['pickup'] ?? order['pickupAddress'] ?? ''}',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.dropoffLocation}: ${order['dropoff'] ?? order['deliveryAddress'] ?? ''}',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ] else
            ...items.map((i) {
              final product = i['product'] as Map<String, dynamic>?;
              final productImgUrl = product?['imageUrl'] as String?;
              final productName = i['productName'] ?? i['name'] ?? '';
              final bool isRejected = i['rejectedAt'] != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (productImgUrl == null || productImgUrl.isEmpty)
                          ? Container(
                              height: 32,
                              width: 32,
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade100,
                              child: const Icon(Icons.fastfood,
                                  size: 16, color: Colors.grey),
                            )
                          : CachedNetworkImage(
                              imageUrl:
                                  ImageUtils.formatImageUrl(productImgUrl),
                              height: 32,
                              width: 32,
                              fit: BoxFit.cover,
                            ),
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
                                  '${i['quantity']}x $productName',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isRejected
                                        ? Colors.grey
                                        : (isDark ? Colors.white70 : Colors.black87),
                                    decoration: isRejected ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              if (isRejected) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.isArabic ? 'ملغي / مسترجع' : 'Cancelled',
                                    style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          for (final opt in ((i['selectedOptions'] as List?) ?? []))
                            if ((opt is Map) && (opt['optionName']?.toString().isNotEmpty ?? false))
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '+ ${opt['optionName']}${(double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0) > 0 ? ' (+${opt['priceAdded']} ${s.egp})' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                    Text(
                      '${_parseDouble(i['price'] ?? i['unitPrice']).toStringAsFixed(0)} ${s.egp}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isRejected ? Colors.grey : (isDark ? Colors.white60 : Colors.grey.shade700),
                        decoration: isRejected ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const Divider(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.subtotal,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${subtotal.toStringAsFixed(2)} ${s.egp}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (!isCancelled) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.deliveryFee,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rawDeliveryFee == null 
                            ? (s.isArabic ? 'تحدد بعد قبول الكابتن' : 'Determined after driver match')
                            : (deliveryFee == 0
                                ? (s.isArabic ? 'مجاني' : 'Free')
                                : '${deliveryFee.toStringAsFixed(2)} ${s.egp}'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: rawDeliveryFee == null 
                              ? AppColors.primary 
                              : (deliveryFee == 0 ? AppColors.success : (isDark ? Colors.white70 : Colors.black87)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (serviceFee > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.isArabic ? 'رسوم الخدمة' : 'Service Fee',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${serviceFee.toStringAsFixed(2)} ${s.egp}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                if (tax > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.isArabic ? 'الضرائب والرسوم' : 'Taxes & Fees',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tax.toStringAsFixed(2)} ${s.egp}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.isArabic ? 'الخصم' : 'Discount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '-${discount.toStringAsFixed(0)} ${s.egp}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    areFeesFinalized ? s.total : (s.isArabic ? 'المجموع المستحق حالياً' : 'Current Subtotal'),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (!areFeesFinalized)
                    Text(
                      s.isArabic ? '(غير شامل التوصيل)' : '(Excl. delivery)',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
              Text(
                rawTotal == null 
                    ? '---' 
                    : '${total.toStringAsFixed(0)} ${s.egp}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          if (!isCustom) ...[
            const SizedBox(height: 16),
            if (status == 'PENDING') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelBottomSheet(context, ref, order['id'], s, isDark),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        s.isArabic ? 'إلغاء الطلب' : 'Cancel Order',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'PENDING_PAYMENT') ...[
              if (order['driver'] != null && order['driver']['mobileWallets'] != null && (order['driver']['mobileWallets'] as List).isNotEmpty)
                ..._buildUpfrontSection(order, s),
            ],
          ] else if (status == 'DELIVERED' && order['review'] == null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  RateOrderBottomSheet.show(context, order['id']);
                },
                icon: const Icon(Icons.star_rate_rounded, size: 20),
                label: Text(s.isArabic ? 'تقييم الطلب' : 'Rate Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          // Direct shortcut into live tracking for active orders — no need
          // to tap the whole card.
          if (!isCancelled && status != 'DELIVERED') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/order-tracking/${order['id']}'),
                icon: const Icon(Icons.location_searching_rounded, size: 20),
                label: Text(s.isArabic ? 'تتبع الطلب' : 'Track Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  void _showCancelBottomSheet(BuildContext context, WidgetRef ref, String orderId, AppStrings s, bool isDark) {
    String selectedReason = s.isArabic ? 'غيرت رأيي' : 'Change of mind';
    final customController = TextEditingController();
    bool showCustomField = false;
    bool isCancelling = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final reasons = s.isArabic
                ? ['غيرت رأيي', 'نسيت إضافة منتج', 'عنوان التوصيل خاطئ', 'وقت التحضير طويل جداً', 'أخرى']
                : ['Change of mind', 'Forgot to add item', 'Wrong delivery address', 'Prep time too long', 'Other'];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.isArabic ? 'إلغاء الطلب' : 'Cancel Order',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.isArabic
                        ? 'يرجى اختيار سبب إلغاء طلبك لمساعدتنا على التحسن:'
                        : 'Please select a reason for cancelling your order:',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...reasons.map((r) {
                    final isSelected = selectedReason == r;
                    return RadioListTile<String>(
                      title: Text(r, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal)),
                      value: r,
                      groupValue: selectedReason,
                      activeColor: Colors.red,
                      contentPadding: EdgeInsets.zero,
                      onChanged: isCancelling ? null : (val) {
                        setModalState(() {
                          selectedReason = val!;
                          showCustomField = val == (s.isArabic ? 'أخرى' : 'Other');
                        });
                      },
                    );
                  }),
                  if (showCustomField) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customController,
                      enabled: !isCancelling,
                      decoration: InputDecoration(
                        hintText: s.isArabic ? 'اكتب سبب الإلغاء هنا...' : 'Enter cancellation reason here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCancelling ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(s.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCancelling
                              ? null
                              : () async {
                                  final finalReason = showCustomField ? customController.text : selectedReason;
                                  
                                  setModalState(() {
                                    isCancelling = true;
                                  });

                                  final success = await ref.read(ordersProvider.notifier).cancelOrder(orderId, finalReason);

                                  if (context.mounted) {
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? (s.isArabic ? 'تم إلغاء الطلب بنجاح!' : 'Order cancelled successfully!')
                                            : (s.isArabic ? 'فشل إلغاء الطلب!' : 'Failed to cancel order!')),
                                        backgroundColor: success ? Colors.green : Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: isCancelling
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(s.isArabic ? 'تأكيد الإلغاء' : 'Confirm Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
