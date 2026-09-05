import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                _buildInfoRow(context, LucideIcons.phone, customer['phone'] ?? customer['user']?['phone'] ?? ''),
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
              
              // Vendor Details
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
              _buildInfoRow(context, LucideIcons.store, (order['type'] == 'CUSTOM_DELIVERY' || order['type'] == 'RIDE') ? (l10n.localeName == 'ar' ? 'العميل' : 'Customer') : (vendor['name'] ?? l10n.vendorFallback)),
              if (vendor['address'] != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(context, LucideIcons.map, vendor['address']),
              ],

              const SizedBox(height: 32),
              
              // Order Items
              Text(
                l10n.localeName == 'ar' ? 'عناصر الطلب' : 'Order Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Text(l10n.localeName == 'ar' ? 'لا توجد عناصر' : 'No items found')
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
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Financials
              _buildTotalRow(context, l10n.localeName == 'ar' ? 'المجموع الفرعي' : 'Subtotal', order['subtotal'], currency),
              const SizedBox(height: 8),
              _buildTotalRow(context, l10n.localeName == 'ar' ? 'رسوم التوصيل' : 'Delivery Fee', order['deliveryFee'], currency),
              if (order['tax'] != null && order['tax'] > 0) ...[
                const SizedBox(height: 8),
                _buildTotalRow(context, l10n.localeName == 'ar' ? 'الضريبة' : 'Tax', order['tax'], currency),
              ],
              const SizedBox(height: 16),
              _buildTotalRow(
                context, 
                l10n.localeName == 'ar' ? 'الإجمالي' : 'Total', 
                order['total'] ?? order['grandTotal'],
                currency,
                isTotal: true
              ),
              
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, dynamic value, String currency, {bool isTotal = false}) {
    final valNum = double.tryParse(value?.toString() ?? '0') ?? 0.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          '${valNum.toStringAsFixed(2)} $currency',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
