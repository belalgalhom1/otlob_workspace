import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/l10n/app_strings.dart';
import '../providers/orders_provider.dart';

class RateOrderBottomSheet extends ConsumerStatefulWidget {
  final String orderId;

  const RateOrderBottomSheet({super.key, required this.orderId});

  @override
  ConsumerState<RateOrderBottomSheet> createState() => _RateOrderBottomSheetState();

  static Future<void> show(BuildContext context, String orderId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: RateOrderBottomSheet(orderId: orderId),
      ),
    );
  }
}

class _RateOrderBottomSheetState extends ConsumerState<RateOrderBottomSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    final s = AppStrings.of(context);
    setState(() => _isSubmitting = true);
    
    try {
      final success = await ref.read(ordersProvider.notifier).rateOrder(
        widget.orderId,
        _rating,
        _commentController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.isArabic ? 'تم إرسال التقييم بنجاح' : 'Rating submitted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.isArabic ? 'حدث خطأ أثناء التقييم' : 'Failed to submit rating')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.isArabic ? 'تقييم الطلب' : 'Rate Order',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.isArabic ? 'أضف تعليقاً (اختياري)' : 'Add a comment (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      s.isArabic ? 'إرسال التقييم' : 'Submit Rating',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
