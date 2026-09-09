import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/providers.dart';
import 'package:ui_kit/ui_kit.dart';
import '../providers/orders_provider.dart';
import '../../../../core/l10n/app_strings.dart';

class CustomerApprovalBottomSheet extends ConsumerStatefulWidget {
  final String orderId;

  const CustomerApprovalBottomSheet({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<CustomerApprovalBottomSheet> createState() => _CustomerApprovalBottomSheetState();
}

class _CustomerApprovalBottomSheetState extends ConsumerState<CustomerApprovalBottomSheet> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _order;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    try {
      final repo = ref.read(customerOrderRepositoryProvider);
      final result = await repo.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(customerOrderRepositoryProvider);
      await repo.approveFee(widget.orderId);
      ref.read(ordersProvider.notifier).refresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).isArabic ? 'تمت الموافقة على رسوم التوصيل بنجاح' : 'Delivery fee approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).isArabic ? 'فشلت الموافقة على الرسوم: $e' : 'Failed to approve fee: $e')),
        );
      }
    }
  }

  Future<void> _decline() async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(customerOrderRepositoryProvider);
      await repo.cancelOrder(widget.orderId);
      ref.read(ordersProvider.notifier).refresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).isArabic ? 'تم إلغاء الطلب' : 'Order has been cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).isArabic ? 'فشل إلغاء الطلب: $e' : 'Failed to cancel order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(s.isArabic ? 'جاري جلب تفاصيل الرسوم...' : 'Fetching fee details...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _order == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(s.isArabic ? 'فشل تحميل الطلب: $_error' : 'Failed to load order: $_error', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final subtotal = _order!['subtotal'] ?? 0.0;
    final deliveryFee = _order!['deliveryFee'] ?? 0.0;
    final driverBonusFee = _order!['driverBonusFee'] ?? 0.0;
    final tax = _order!['tax'] ?? 0.0;
    final serviceFee = _order!['serviceFee'] ?? 0.0;
    final discount = _order!['discount'] ?? 0.0;
    final total = _order!['grandTotal'] ?? _order!['total'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              s.isArabic ? 'تم تحديث رسوم التوصيل' : 'Delivery Fee Updated',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              s.isArabic 
                  ? 'وافق المندوب على طلبك وتم حساب رسوم التوصيل النهائية بناءً على المسافة. يرجى مراجعة الرسوم والموافقة عليها للمتابعة.' 
                  : 'A driver has accepted your order and the final delivery fee has been calculated based on the distance. Please review and approve the fee to proceed.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildPriceRow(s.subtotal, subtotal, s),
                  if (serviceFee > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(s.isArabic ? 'رسوم الخدمة' : 'Service Fee', serviceFee, s),
                  ],
                  if (tax > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(s.isArabic ? 'الضريبة' : 'Tax', tax, s),
                  ],
                  if (driverBonusFee > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(s.isArabic ? 'مكافأة السائق' : 'Driver Bonus', driverBonusFee, s),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceRow(s.deliveryFee, deliveryFee, s, isHighlight: true),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(s.isArabic ? 'الخصم' : 'Discount', -discount, s),
                  ],
                  const Divider(height: 24),
                  _buildPriceRow(s.total, total, s, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _decline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.isArabic ? 'إلغاء الطلب' : 'Cancel Order', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isProcessing ? null : _approve,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(s.isArabic ? 'الموافقة على الرسوم' : 'Approve Fee', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, num amount, AppStrings s, {bool isHighlight = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? AppColors.primary : null,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} ${s.egp}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: (isTotal || isHighlight) ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}
