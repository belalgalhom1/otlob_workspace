import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:core/core.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsBottomSheet extends ConsumerWidget {
  final Map<String, dynamic> order;

  const OrderDetailsBottomSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, Map<String, dynamic> order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsBottomSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(configurationProvider.notifier).currency;

    final customer = order['customer'] is Map ? order['customer'] : {};
    final vendor = order['vendor'] is Map ? order['vendor'] : {};
    
    final addressRaw = order['deliveryAddress'];
    final String addressString = addressRaw is String ? addressRaw : (addressRaw is Map ? (addressRaw['address'] ?? '') : '');
    final Map addressMap = addressRaw is Map ? addressRaw : {};

    final items = (order['items'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.localeName == 'ar' ? 'تفاصيل الطلب' : 'Order Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      order['orderNumber']?.toString() ?? '#${(order['id'] ?? '').toString().substring(0, 8)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Customer Details
              Text(
                l10n.localeName == 'ar' ? 'العميل والتوصيل' : 'Customer (Dropoff)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(context, LucideIcons.user, customer['name'] ?? customer['user']?['name'] ?? l10n.customerFallback),
              if (customer['phone'] != null || customer['user']?['phone'] != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  LucideIcons.phone,
                  customer['phone'] ?? customer['user']?['phone'] ?? '',
                  onTap: () => _callPhone(context, (customer['phone'] ?? customer['user']?['phone'])?.toString()),
                ),
              ],
              
              const SizedBox(height: 12),
              _buildInfoRow(context, LucideIcons.mapPin, addressString.isNotEmpty ? addressString : 'No address provided'),
              
              if (addressMap.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(LucideIcons.home, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        [
                          if (addressMap['building'] != null) '${l10n.localeName == 'ar' ? 'مبنى' : 'Building'} ${addressMap['building']}',
                          if (addressMap['floor'] != null) '${l10n.localeName == 'ar' ? 'طابق' : 'Floor'} ${addressMap['floor']}',
                          if (addressMap['apartment'] != null) '${l10n.localeName == 'ar' ? 'شقة' : 'Apt'} ${addressMap['apartment']}',
                        ].where((e) => e.isNotEmpty).join(' • '),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ],
              
              if (addressMap['instructions'] != null && addressMap['instructions'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.info, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addressMap['instructions'],
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              
              // Vendor Details / Pickup Details
              Text(
                (order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE') 
                    ? (l10n.localeName == 'ar' ? 'موقع الاستلام' : 'Pickup Location') 
                    : (l10n.localeName == 'ar' ? 'المتجر (الاستلام)' : 'Store (Pickup)'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE') ...[
                _buildInfoRow(
                  context, 
                  LucideIcons.mapPin, 
                  (order['pickupAddress'] != null && order['pickupAddress'].toString().isNotEmpty)
                      ? order['pickupAddress'].toString()
                      : (l10n.localeName == 'ar' ? 'موقع الاستلام' : 'Pickup Location'),
                ),
              ] else ...[
                _buildInfoRow(context, LucideIcons.store, vendor['storeName'] ?? vendor['name'] ?? l10n.vendorFallback),
                () {
                  final Map? branch = order['vendorBranch'] is Map ? (order['vendorBranch'] as Map) : null;
                  final String? branchName = branch == null
                      ? null
                      : (l10n.localeName == 'ar'
                          ? (branch['nameAr']?.toString() ?? branch['name']?.toString())
                          : (branch['name']?.toString() ?? branch['nameAr']?.toString()));
                  final dynamic branchAddress = branch != null ? branch['address'] : order['pickupAddress'];
                  return Column(
                    children: [
                      if (branchName != null && branchName.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(context, LucideIcons.mapPin, branchName),
                      ],
                      if (branchAddress != null && branchAddress.toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(context, LucideIcons.map, branchAddress.toString()),
                      ],
                    ],
                  );
                }(),
              ],

              const SizedBox(height: 24),

              // Pickup proof photo
              if (order['pickupImageUrl'] != null &&
                  order['pickupImageUrl'].toString().isNotEmpty) ...[
                Text(
                  l10n.pickupPhoto,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () =>
                      _viewPhoto(context, ref, order['pickupImageUrl'].toString()),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _resolveMediaUrl(ref, order['pickupImageUrl'].toString()),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 56,
                              height: 56,
                              color: Theme.of(context).dividerColor,
                              child: const Icon(
                                LucideIcons.imageOff,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.localeName == 'ar'
                                ? 'اضغط لعرض صورة الاستلام'
                                : 'Tap to view pickup photo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              
              // Order Items or Package Details
              Text(
                (order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE')
                    ? (order['type'] == 'RIDE' 
                        ? (l10n.localeName == 'ar' ? 'تفاصيل الرحلة' : 'Ride Details')
                        : (l10n.localeName == 'ar' ? 'تفاصيل الشحنة' : 'Package Details'))
                    : (l10n.localeName == 'ar' ? 'عناصر الطلب' : 'Order Items'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty) ...[
                if (order['itemDetails'] != null && order['itemDetails'].toString().isNotEmpty)
                  _buildInfoRow(context, LucideIcons.package, order['itemDetails'].toString())
                else if (order['specialRequest'] != null && order['specialRequest'].toString().isNotEmpty)
                  _buildInfoRow(context, LucideIcons.fileText, order['specialRequest'].toString())
                else
                  Text(l10n.localeName == 'ar' ? 'لا توجد تفاصيل إضافية' : 'No additional details')
              ]
              else
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item['quantity'] ?? 1}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['productName'] ?? item['product']?['name'] ?? item['menuItem']?['name'] ?? 'Item',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            if (item['customizations'] != null)
                              Text(
                                item['customizations'].toString(),
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            for (final opt in ((item['selectedOptions'] as List?) ?? []))
                              if ((opt['optionName']?.toString().isNotEmpty ?? false))
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '+ ${opt['optionName']}${(double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0) > 0 ? ' (+${opt['priceAdded']} $currency)' : ''}',
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Operational Financial Cards for Driver
              Builder(builder: (context) {
                final financials = order['financials'] is Map ? order['financials'] as Map : null;

                final isPrepaid = financials?['isPrepaid'] == true ||
                    (order['paymentMethod'] != 'CASH_ON_DELIVERY' && order['paymentMethod'] != 'MOBILE_WALLET');
                final double cashToCollect = financials?['cashToCollect'] != null
                    ? (double.tryParse(financials!['cashToCollect'].toString()) ?? 0.0)
                    : (isPrepaid
                        ? 0.0
                        : ((double.tryParse((order['total'] ?? order['grandTotal']).toString()) ?? 0.0) - (double.tryParse(order['upfrontAmount']?.toString() ?? '0') ?? 0.0)));

                final bool isStorePrepaid = financials?['isStorePrepaid'] ??
                    (order['vendorBranch']?['isContracted'] ?? order['vendor']?['isContracted'] ?? false);
                final double cashToPayStore = financials?['cashToPayStore'] != null
                    ? (double.tryParse(financials!['cashToPayStore'].toString()) ?? 0.0)
                    : (isStorePrepaid ? 0.0 : (double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0));

                final double driverEarnings = financials?['driverEarnings'] != null
                    ? (double.tryParse(financials!['driverEarnings'].toString()) ?? 0.0)
                    : (double.tryParse(order['deliveryFee']?.toString() ?? '0') ?? 0.0);

                final isAr = l10n.localeName == 'ar';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Customer Cash Collection Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (isPrepaid || cashToCollect <= 0)
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isPrepaid || cashToCollect <= 0)
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.success.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (isPrepaid || cashToCollect <= 0) ? LucideIcons.creditCard : LucideIcons.banknote,
                            color: (isPrepaid || cashToCollect <= 0) ? AppColors.primary : AppColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (isPrepaid || cashToCollect <= 0)
                                      ? (isAr ? 'الطلب مدفوع إلكترونياً' : 'Order Paid Online')
                                      : (isAr ? 'المطلوب تحصيله كاش من العميل' : 'Cash to Collect from Customer'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (isPrepaid || cashToCollect <= 0)
                                      ? (isAr ? 'لا تحصل كاش (0 $currency)' : 'Do Not Collect Cash (0 $currency)')
                                      : '${cashToCollect.toStringAsFixed(2)} $currency',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: (isPrepaid || cashToCollect <= 0) ? AppColors.primary : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Store Pickup Payment Instruction Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isStorePrepaid
                            ? Colors.grey.withValues(alpha: 0.08)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isStorePrepaid
                              ? Colors.grey.withValues(alpha: 0.2)
                              : AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isStorePrepaid ? LucideIcons.store : LucideIcons.badgeDollarSign,
                            color: isStorePrepaid ? Colors.grey : AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isStorePrepaid
                                      ? (isAr ? 'متجر شريك معتمد: لا تدفع كاش في المتجر (0 $currency)' : 'Partner Store: Pay 0 $currency at store')
                                      : (isAr ? 'متجر غير متعاقد: ادفع للمتجر كاش: ${cashToPayStore.toStringAsFixed(2)} $currency' : 'Uncontracted: Pay store in cash: ${cashToPayStore.toStringAsFixed(2)} $currency'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isStorePrepaid
                                        ? Theme.of(context).colorScheme.onSurface
                                        : AppColors.warning,
                                  ),
                                ),
                                if (!isStorePrepaid && isPrepaid) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr
                                        ? 'الطلب مدفوع إلكترونياً — سيتم استرداد المبلغ لمحفظتك فور التسليم'
                                        : 'Paid online — Cash will be reimbursed to your wallet upon delivery',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Driver Delivery Earnings Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.bike, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'أرباحك من هذا التوصيل' : 'Your Delivery Earnings',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            '${driverEarnings.toStringAsFixed(2)} $currency',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Payment Method Detail
                    _buildInfoRow(
                      context,
                      LucideIcons.wallet,
                      _paymentMethodLabel(
                        order['paymentMethod']?.toString() ?? '',
                        isAr,
                      ),
                    ),
                  ],
                );
              }),
              
              const SizedBox(height: 24),
              PrimaryButton(
                text: l10n.localeName == 'ar' ? 'إغلاق' : 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _paymentMethodLabel(String rawMethod, bool isArabic) {
    switch (rawMethod.toUpperCase().trim()) {
      case 'CASH_ON_DELIVERY':
      case 'CASH':
        return isArabic ? 'الدفع عند الاستلام' : 'Cash on Delivery';
      case 'MOBILE_WALLET':
      case 'MOBILE_WALLET_VODAFONE':
        return isArabic ? 'المحفظة الإلكترونية' : 'Mobile Wallet';
      case 'MOBILE_WALLET_INSTAPAY':
      case 'INSTAPAY':
        return isArabic ? 'إنستا باي' : 'InstaPay';
      default:
        return isArabic ? 'طريقة الدفع: $rawMethod' : 'Payment: $rawMethod';
    }
  }

  String _resolveMediaUrl(WidgetRef ref, String path) {
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$cleanBaseUrl$path';
  }

  void _viewPhoto(BuildContext context, WidgetRef ref, String url) {
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
                  child: Image.network(
                    _resolveMediaUrl(ref, url),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: onTap != null ? const EdgeInsets.symmetric(vertical: 4) : EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: onTap != null ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: onTap != null ? FontWeight.w600 : null,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(LucideIcons.phoneCall, size: 20, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String? phone) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (digits.isEmpty) {
      _showSnack(
        context,
        isArabic ? 'رقم الهاتف غير متاح' : 'Phone number not available',
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      _showSnack(
        context,
        isArabic ? 'تعذر بدء الاتصال' : 'Could not start the call',
      );
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

}
